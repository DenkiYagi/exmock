package testdata;

interface NoFieldInterface {
}

interface OneFieldInterface {
    function field1():Void;
}

interface TwoFieldInterface {
    function field1():Void;
    function field2():Void;
}

interface PrivateFieldInterface {
    function field1():Void;
    private function field2():Void;
}