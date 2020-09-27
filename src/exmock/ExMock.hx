package exmock;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Expr;
import extools.EqualsTools;

using haxe.macro.TypeTools;
using StringTools;
using Lambda;
#end

class ExMock {
    #if macro
    @:persistent static var counter:Int = 0;
    #end

    public static macro function mock<T>(expr:ExprOf<Class<T>>):Expr {
        final mockPack = ["exmock", "_tmp"];
        final mockClass = 'Mock${counter++}';
        final mockCalls = '${mockClass}Calls';

        final targetType = getClassType(expr);
        final targetClass = targetType.followWithAbstracts().getClass();

        final fields = targetClass.fields.get();
        final props = fields.filter(f -> switch (f.kind) {
            case FVar(_, _): true;
            case _: false;
        });
        final methods = fields.filter(f -> switch (f.kind) {
            case FMethod(_): true;
            case FVar(_, _): false;
        });
        final missingAccessors = findMissingAccessors(props, methods);

        final mockBodyType = makeMockBodyType(fields, missingAccessors);
        final mockCallsType = makeMockCallsType(methods, missingAccessors);

        final mockCallsInitExpr = macro () -> (${{
            expr: EObjectDecl(methods.map(f -> ({field: f.name, expr: macro []} : ObjectField))),
            pos: Context.currentPos()
        }} : $mockCallsType);

        final propsInitExpr = macro $b{
            props.filter(f -> switch (f.kind) {
                case FVar(_, AccNormal | AccNo | AccCtor): true;
                case _: false;
            })
            .map(p -> macro $i{p.name} = ${{expr: EField(macro body, p.name), pos: Context.currentPos()}})
        };

        Context.defineType({
            pack: mockPack,
            name: mockClass,
            kind: TDClass(null, [toTypePath(targetClass)]),
            pos: expr.pos,
            fields: [
                {
                    name: "__body",
                    access: [APrivate, AFinal],
                    kind: FVar(macro :Null<$mockBodyType>),
                    pos: Context.currentPos()
                },
                {
                    name: "__callsHolder",
                    access: [APrivate],
                    kind: FVar(macro :exmock.ExMock.ExMockCallsHolder<$mockCallsType>),
                    pos: Context.currentPos()
                },
                {
                    name: "new",
                    access: [APublic],
                    kind: FieldType.FFun({
                        args: [
                            {name: "body", type: macro :Null<$mockBodyType>},
                            {name: "callsHolder", type: macro :exmock.ExMock.ExMockCallsHolder<$mockCallsType>}
                        ],
                        ret: null,
                        expr: macro {
                            this.__body = body;
                            this.__callsHolder = callsHolder;
                            $propsInitExpr;
                        }
                    }),
                    pos: Context.currentPos()
                }
            ]
            .concat(methods.map(f -> switch (f.type) {
                case TFun(args, ret):
                    final ebody = {
                        expr: EField(macro __body, f.name),
                        pos: Context.currentPos()
                    };
                    final eargs = {
                        expr: EObjectDecl(args.map(a ->
                            ({field: a.name, expr: {expr: EConst(CIdent(a.name)), pos: Context.currentPos()}} : ObjectField)
                        )),
                        pos: Context.currentPos()
                    };

                    final ecall = {
                        expr: ECall(ebody, args.map(a -> {expr: EConst(CIdent(a.name)), pos: Context.currentPos()})),
                        pos: Context.currentPos()
                    };

                    ({
                        name: f.name,
                        access: [f.isPublic ? APublic : APrivate],
                        kind: FFun({
                            args: args.map(a -> ({
                                name: a.name,
                                opt: a.opt,
                                type: a.t.toComplexType()
                            } : FunctionArg)),
                            ret: ret.toComplexType(),
                            params: f.params.map(p -> ({
                                name: p.name,
                                // ?constraints:Array<ComplexType>;
                                // ?params:Array<TypeParamDecl>;
                                // ?meta:Metadata;
                            } : TypeParamDecl)),
                            expr: macro {
                                ${{expr: EField(macro __callsHolder.calls, f.name), pos: Context.currentPos()}}.push(${eargs});
                                return if (__body != null && ${ebody} != null) {
                                    ${ecall};
                                } else {
                                    throw "not implemented";
                                };
                            },
                        }),
                        pos: Context.currentPos()
                    } : Field);
                case _:
                    Context.error("invalid expr", f.pos);
            }))
            .concat(props.map(f -> switch (f.kind) {
                case FVar(_, AccCtor):
                    {
                        name: f.name,
                        access: [AFinal, f.isPublic ? APublic : APrivate],
                        kind: FVar(f.type.toComplexType()),
                        pos: Context.currentPos()
                    };
                case FVar(r, w):
                    {
                        name: f.name,
                        access: [f.isPublic ? APublic : APrivate],
                        kind: FProp(toAccessorString(r), toAccessorString(w), f.type.toComplexType()),
                        pos: Context.currentPos()
                    };
                case _:
                    {
                        name: f.name,
                        access: [f.isPublic ? APublic : APrivate],
                        kind: FVar(f.type.toComplexType()),
                        pos: Context.currentPos()
                    };
            }))
        });

        final tp:TypePath = {pack: mockPack, name: mockClass};
        return macro {
            setup: (?body:$mockBodyType) -> {
                final callsHolder = new exmock.ExMock.ExMockCallsHolder($mockCallsInitExpr);
                new exmock.ExMock.ExMockObject(${{
                    expr: EParenthesis({
                        expr: ECheckType(macro new $tp(body, callsHolder), targetType.toComplexType()),
                        pos: Context.currentPos()
                    }),
                    pos: Context.currentPos()
                }}, callsHolder);
            }
        };
    }

    #if macro
    static function getClassType(expr:Expr):Type {
        return Context.getType(switch (expr.expr) {
            case EField(_, _):
                ExprTools.toString(expr);
            case EConst(CIdent(name)):
                name;
            case _:
                Context.error("unsupported expr", expr.pos);
        });
    }

    static function toTypePath(cls:ClassType):TypePath {
        final modulePath = cls.module.split(".");
        final moduleName = modulePath[modulePath.length - 1];

        return if (moduleName == cls.name) {
            {pack: cls.pack, name: moduleName, params: []};
        } else {
            {pack: cls.pack, name: moduleName, sub: cls.name, params: []};
        }
    }

    static function findMissingAccessors(props:Array<ClassField>, methods:Array<ClassField>):Array<Accessor> {
        return props.flatMap(p -> {
            final getter = 'get_${p.name}';
            final setter = 'set_${p.name}';

            (switch (p.kind) {
                case FVar(AccCall, _) if (!methods.exists(m -> m.name == getter)):
                    [Getter(p.name, p.type.toComplexType())];
                case _:
                    [];
            }).concat(switch (p.kind) {
                case FVar(_, AccCall) if (!methods.exists(m -> m.name == setter)):
                    [Setter(p.name, p.type.toComplexType())];
                case _:
                    [];
            });
        });
    }

    static function makeMockBodyType(fields:Array<ClassField>, missingAccessors:Array<Accessor>):ComplexType {
        return TAnonymous(
            fields.filter(f -> {
                switch (f.kind) {
                    case FVar(AccCall, AccNormal | AccNo | AccCtor): true;
                    case FVar(AccCall, _) | FVar(_, AccCall): false;
                    case _: true;
                };
            })
            .map(f -> ({
                name: f.name,
                kind: switch (f.type) {
                    case TFun(args, ret):
                        FFun({
                            args: args.map(a -> ({
                                name: a.name,
                                opt: a.opt,
                                type: a.t.toComplexType()
                            } : FunctionArg)),
                            ret: ret.toComplexType(),
                            expr: null,
                            params: f.params.map(p -> ({
                                name: p.name,
                                // constraints: null
                                // ?constraints:Array<ComplexType>;
                                // ?params:Array<TypeParamDecl>;
                                // ?meta:Metadata;
                            } : TypeParamDecl))
                        });
                    case _:
                        FVar(f.type.toComplexType());
                },
                meta: [{name: ":optional", pos: Context.currentPos()}],
                pos: Context.currentPos()
            } : Field))
            .concat(missingAccessors.map(x -> (switch (x) {
                case Getter(name, type):
                    {
                        name: 'get_$name',
                        kind: FVar(TFunction([], type)),
                        meta: [{name: ":optional", pos: Context.currentPos()}],
                        pos: Context.currentPos()
                    }
                case Setter(name, type):
                    {
                        name: 'set_$name',
                        kind: FVar(TFunction([type], type)),
                        meta: [{name: ":optional", pos: Context.currentPos()}],
                        pos: Context.currentPos()
                    }
            } : Field)))
        );
    }

    static function makeMockCallsType(fields:Array<ClassField>, missingAccessors:Array<Accessor>):ComplexType {
        return TAnonymous(
            fields.map(f -> {
                final typeParams = f.params.map(p -> p.t.toComplexType());
                ({
                    name: f.name,
                    access: [AFinal],
                    kind: FVar(switch (f.type) {
                        case TFun(args, ret):
                            final fields = args.map(a -> ({
                                name: a.name,
                                //function fn<T>(x:T):Void の`x:T`ような、Mock生成時では特定不能な型はDynamicにするしかない
                                //TODO function fn<Map<T>>(x:Map<T>):Void;のような定義のインスタンスメソッドに対応できていない
                                kind: if (typeParams.exists(tp -> EqualsTools.deepEqual(tp, a.t.toComplexType()))) {
                                    FVar(macro :Dynamic);
                                } else {
                                    FVar(a.t.toComplexType());
                                },
                                access: [AFinal],
                                pos: Context.currentPos()
                            } : Field));
                            TPath({pack: [], name: "Array", params: [TPType(TAnonymous(fields))]});
                        case _:
                            Context.error("invalid expr", f.pos);
                    }),
                    pos: Context.currentPos(),
                } : Field);
            })
        );
    }

    static function toAccessorString(x:VarAccess):String {
        return switch (x) {
            case AccNormal: "default";
            case AccNo: "null";
            case AccNever: "never";
            case AccCall: "dynamic";
            case _: "default";
        }
    }
    #end
}

class ExMockObject<TType, TCalls> {
    final callsHolder:ExMockCallsHolder<TCalls>;
    public final object:TType;

    public var calls(get, never):TCalls;
    function get_calls() {
        return callsHolder.calls;
    }

    public function new(object:TType, callsHolder:ExMockCallsHolder<TCalls>) {
        this.object = object;
        this.callsHolder = callsHolder;
    }

    public function reset():Void {
        callsHolder.reset();
    }
}

class ExMockCallsHolder<TCalls> {
    final factory:()->TCalls;
    public var calls(default, null):TCalls;

    public function new(factory:()->TCalls) {
        this.factory = factory;
        reset();
    }

    public function reset():Void {
        calls = factory();
    }
}

#if macro
private enum Accessor {
    Getter(name:String, type:ComplexType);
    Setter(name:String, type:ComplexType);
}
#end