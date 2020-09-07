# exmock

mocking library for Haxe

**WORKING IN PROGRESS**

## install

```
haxelib install https://github.com/DenkiYagi/exmock.git
```

## usage

```haxe
ExMock.mock(YourInterface).setup({
    toString: () -> "Hello World"
});
```

```haxe
interface YourInterface {
    function toString():String;
    function doSomething():Void;
}
