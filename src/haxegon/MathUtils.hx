package haxegon;

class MathUtils {

    public static function dst(x1: Float, y1: Float, x2: Float, y2: Float): Float {
        return Math.sqrt(dst2(x1, y1, x2, y2));
    }

    public static function dst2(x1: Float, y1: Float, x2: Float, y2: Float): Float {
        return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
    }

    public static function radToDeg(angleInRads: Float): Float {
        return angleInRads * 57.2958;
    }

    public static function degToRad(angleInDeg: Float): Float {
        return angleInDeg / 57.2958;
    }

    public static function sign(x: Float): Int {
        if (x >= 0.0) {
            return 1;
        } else {
            return -1;
        }
    }

    public static function lerp(x1: Float, x2: Float, a: Float): Float {
        return x1 + (x2 - x1) * a;
    }
}
