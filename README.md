# exmock

mocking library for Haxe

**WORK IN PROGRESS**

## install

```
haxelib git exmock https://github.com/DenkiYagi/exmock.git
```

## usage

```haxe
final mock = ExMock.mock(YourInterface).setup({
    sayHello: name -> "Hello " + name;
});

mock.object.sayHello("Taro");
mock.object.doSomething(); //thrown "not implemented"

mock.calls.sayHello; // [{name:"Taro"}]
```

```haxe
interface YourInterface {
    function sayHello(name:String):String;
    function doSomething():Void;
}
