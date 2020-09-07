package exmock;

import testdata.Interface1;
import testdata.Interface2;
import testdata.Interface3;
import testdata.Interface4;

class ExMockSuite extends BuddySuite {
    public function new() {
        describe("ExMock", {
            describe("inferface mock", {
                it("should read a main type", {
                    ExMock.mock(Interface1);
                    ExMock.mock(testdata.Interface1);
                });

                it("should read a sub type", {
                    ExMock.mock(Interface1Sub);
                    ExMock.mock(testdata.Interface1.Interface1Sub);
                });

                it("should setup no field", {
                    final mock1 = ExMock.mock(NoFieldInterface).setup();
                    mock1.object.should.beType(NoFieldInterface);

                    final mock2 = ExMock.mock(NoFieldInterface).setup({});
                    mock2.object.should.beType(NoFieldInterface);
                });

                it("should setup one mothod", {
                    final mock1 = ExMock.mock(OneFieldInterface).setup();
                    mock1.object.should.beType(OneFieldInterface);
                    mock1.calls.field1.length.should.be(0);

                    final mock2 = ExMock.mock(OneFieldInterface).setup({});
                    mock2.object.should.beType(OneFieldInterface);
                    mock2.calls.field1.length.should.be(0);

                    var called = false;
                    final mock3 = ExMock.mock(OneFieldInterface).setup({
                        field1: () -> called = true
                    });
                    mock3.object.should.beType(OneFieldInterface);
                    mock3.object.field1();
                    mock3.calls.field1.length.should.be(1);
                    called.should.be(true);
                });

                it("should setup two mothods", {
                    final mock1 = ExMock.mock(TwoFieldInterface).setup();
                    mock1.object.should.beType(TwoFieldInterface);
                    mock1.calls.field1.length.should.be(0);
                    mock1.calls.field2.length.should.be(0);

                    final mock2 = ExMock.mock(TwoFieldInterface).setup({});
                    mock2.object.should.beType(TwoFieldInterface);
                    mock2.calls.field1.length.should.be(0);
                    mock2.calls.field2.length.should.be(0);

                    var called = false;
                    final mock3 = ExMock.mock(TwoFieldInterface).setup({
                        field2: () -> called = true
                    });
                    mock3.object.should.beType(TwoFieldInterface);
                    mock3.object.field2();
                    mock3.calls.field1.length.should.be(0);
                    mock3.calls.field2.length.should.be(1);
                    called.should.be(true);
                });

                it("should setup a private mothod", {
                    var called = false;
                    final mock = ExMock.mock(PrivateFieldInterface).setup({
                        field2: () -> called = true
                    });

                    #if !target.static
                    (mock.object : Dynamic).field2();
                    mock.calls.field1.length.should.be(0);
                    mock.calls.field2.length.should.be(1);
                    called.should.be(true);
                    #end
                });

                it("should setup some arguments", {
                    final mock = ExMock.mock(Interface3).setup({
                        foo: a -> a * 2,
                        bar: (a, b, c) -> "hello",
                        baz: (a, ?b) -> "world"
                    });

                    mock.object.foo(10).should.be(20);
                    mock.calls.foo.length.should.be(1);
                    mock.calls.foo[0].a.should.be(10);

                    mock.object.bar(1, "a", "b").should.be("hello");
                    mock.calls.bar.length.should.be(1);
                    mock.calls.bar[0].a.should.be(1);
                    mock.calls.bar[0].b.should.be("a");
                    mock.calls.bar[0].c.should.be("b");

                    mock.object.baz(5, true).should.be("world");
                    mock.calls.baz.length.should.be(1);
                    mock.calls.baz[0].a.should.be(5);
                    mock.calls.baz[0].b.should.be(true);
                });

                it("should captor n-times calls", {
                    final mock = ExMock.mock(Interface3).setup({
                        foo: a -> a * 2
                    });

                    mock.object.foo(10);
                    mock.object.foo(20);
                    mock.object.foo(30);
                    mock.object.foo(40);

                    mock.calls.foo.length.should.be(4);
                    mock.calls.bar.length.should.be(0);
                    mock.calls.baz.length.should.be(0);

                    mock.calls.foo[0].a.should.be(10);
                    mock.calls.foo[1].a.should.be(20);
                    mock.calls.foo[2].a.should.be(30);
                    mock.calls.foo[3].a.should.be(40);
                });

                it("プロパティ", {
                    final mock = ExMock.mock(Interface4).setup({
                        get_field31: () -> 10,
                    });

                });

                // プロパティ
                // 型パラメータ付き
            });

            // 構造体

            // クラス
        });
    }
}