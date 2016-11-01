package haxegon;

class Convert {
    public static function toString(?value: Dynamic): String {
        return Std.string(value);
    }

    public static function toInt(?value: Dynamic): Int {
        return Std.parseInt(Std.string(value));
    }

    public static function toFloat(?value: Dynamic): Float {
        return Std.parseFloat(value);
    }
}