package haxegon;

class Extensions {
    @generic
    public static function last<T>(array: Array<T>): T {
        return array[array.length - 1];
    }
}
