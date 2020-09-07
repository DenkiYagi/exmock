package testdata;

interface Interface4 {
    final field01:Int;
    var field02:Int;
    var field03(default, default):Int;

    var field11(default, null):Int;
    var field12(default, never):Int;
    var field13(null, default):Int;
    var field14(never, default):Int;

    var field21(get, set):Int;
    var field22(get, default):Int;
    var field23(get, null):Int;
    var field24(get, never):Int;
    var field25(default, set):Int;
    var field26(null, set):Int;
    var field27(never, set):Int;

    var field31(dynamic, dynamic):Int;
    var field32(dynamic, default):Int;
    var field33(dynamic, null):Int;
    var field34(dynamic, never):Int;
    var field35(default, dynamic):Int;
    var field36(null, dynamic):Int;
    var field37(never, dynamic):Int;
}