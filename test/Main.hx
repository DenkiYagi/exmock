class Main implements Buddy<[
    exmock.ExMockSuite
]> {}


// class Main {
//     public static function main() {
//         final mock = exmock.ExMock.mock(Foo).setup({
//             get_field31: () -> 10,

//         });
//     }
// }

// interface Foo {
//     var field31(dynamic, dynamic):Int;
//     var field32(dynamic, default):Int;
// }


// class Main {
//     static function main() {
//         var foo = new Foo();
//     }
// }

// interface IFoo {
//     var id(default, set):Int;
// }

// class Foo implements IFoo {
//     public var id(default, set):Int;

//     function get_id() return 1;
//     function set_id(x) return x;

//     public function new() {

//     }
// }