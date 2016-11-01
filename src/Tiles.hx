class Tiles {
    static inline var tilesetWidth = 16;
    static function tilenum(x: Int, y: Int): Int {
        return y * tilesetWidth + x;
    }

    public static inline var GroundRight = tilenum(0, 0);
    public static inline var GroundDown = tilenum(1, 0);
    public static inline var GroundLeft = tilenum(2, 0);
    public static inline var GroundUp = tilenum(3, 0);
    public static inline var GroundUpRight = tilenum(0, 1);
    public static inline var GroundRightDown = tilenum(1, 1);
    public static inline var GroundDownLeft = tilenum(2, 1);
    public static inline var GroundLeftUp = tilenum(3, 1);
    public static inline var GroundLeftUpRight = tilenum(0, 2);
    public static inline var GroundUpRightDown = tilenum(1, 2);
    public static inline var GroundRightDownLeft = tilenum(2, 2);
    public static inline var GroundDownLeftUp = tilenum(3, 2);
    public static inline var GroundLeftRight = tilenum(0, 3);
    public static inline var GroundUpDown = tilenum(1, 3);
    public static inline var Fog = tilenum(0, 4);
    public static inline var GroundOpen = tilenum(1, 4);
    public static inline var GroundClosed = tilenum(2, 4);
    public static inline var GroundSpace = tilenum(3, 4);

    public static inline var SporeOff = tilenum(4, 0);
    public static inline var SporeOn = tilenum(5, 0);
    public static inline var Mineral = tilenum(6, 0);

    public static inline var GeneratorStart = tilenum(0, 14);
    public static inline var GeneratorEnd = tilenum(12, 14);

    public static inline var SpawnerStart = tilenum(0, 15);
    public static inline var SpawnerEnd = tilenum(6, 15);

    public static inline var FlowerRightStart = tilenum(0, 6);
    public static inline var FlowerDownStart = tilenum(0, 7);
    public static inline var FlowerLeftStart = tilenum(0, 8);
    public static inline var FlowerUpStart = tilenum(0, 9);
    public static inline var FlowerRightEnd = tilenum(5, 6);
    public static inline var FlowerDownEnd = tilenum(5, 7);
    public static inline var FlowerLeftEnd = tilenum(5, 8);
    public static inline var FlowerUpEnd = tilenum(5, 9);

    public static inline var MinerRightStart = tilenum(0, 10);
    public static inline var MinerDownStart = tilenum(0, 11);
    public static inline var MinerLeftStart = tilenum(0, 12);
    public static inline var MinerUpStart = tilenum(0, 13);
    public static inline var MinerRightEnd = tilenum(12, 10);
    public static inline var MinerDownEnd = tilenum(12, 11);
    public static inline var MinerLeftEnd = tilenum(12, 12);
    public static inline var MinerUpEnd = tilenum(12, 13);

    public static inline var PusherOffLeft = tilenum(4, 1);
    public static inline var PusherOffDown = tilenum(5, 1);
    public static inline var PusherOffRight = tilenum(6, 1);
    public static inline var PusherOffUp = tilenum(7, 1);
    public static inline var PusherOnLeft = tilenum(4, 2);
    public static inline var PusherOnDown = tilenum(5, 2);
    public static inline var PusherOnRight = tilenum(6, 2);
    public static inline var PusherOnUp = tilenum(7, 2);
    public static inline var PusherWaveLeft = tilenum(8, 0);
    public static inline var PusherWaveDown = tilenum(9, 0);
    public static inline var PusherWaveRight = tilenum(10, 0);
    public static inline var PusherWaveUp = tilenum(11, 0);

    public static inline var PullerOffLeft = tilenum(4, 3);
    public static inline var PullerOffDown = tilenum(5, 3);
    public static inline var PullerOffRight = tilenum(6, 3);
    public static inline var PullerOffUp = tilenum(7, 3);
    public static inline var PullerOnLeft = tilenum(4, 4);
    public static inline var PullerOnDown = tilenum(5, 4);
    public static inline var PullerOnRight = tilenum(6, 4);
    public static inline var PullerOnUp = tilenum(7, 4);
    public static inline var PullerWaveLeft = tilenum(8, 1);
    public static inline var PullerWaveDown = tilenum(9, 1);
    public static inline var PullerWaveRight = tilenum(10, 1);
    public static inline var PullerWaveUp = tilenum(11, 1);
}