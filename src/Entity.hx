import haxegon.*;

enum EntityType {
    None;
    Spore;
    Mineral;
    Flower;
    Generator;
    Miner;
    Pusher;
    Puller;
    Spawner;
}

enum EntityDirection {
    None;
    Left;
    Right;
    Down;
    Up;
}

class Entity {
    public static var allEntities = new Array<Entity>();
    static var sortedEntities = {
        var array = new Array();
        for (type in Type.allEnums(EntityType)) {
            array.push(new Array<Entity>());
        }
        array;
    }

    public static inline var flowerCharge = 10;
    public static inline var minerCharge = 20;
    public static inline var minerChargeGain = 3;
    public static inline var minerChargeGainMineral = 20;
    public static inline var generatorCharge = 40;
    public static inline var spawnerCharge = 7;
    public static inline var pushDistance = 5;
    public static inline var pullDistance = 6;
    public static inline var pushPullMax = 60;
    static var lastGeneratorNumber = 0;

    public var x: Int;
    public var y: Int;
    public var type: EntityType;
    public var direction: EntityDirection;
    public var directionVector = {x: 0, y: 0};
    public var counter: Int;
    public var energized: Bool;
    public var explored = false;
    public var generatorNumber = 0;

    public function new(x: Int, y: Int) {
    	this.x = x;
        this.y = y;
        type = EntityType.None;
        clear();
    }

    public function clear() {
        removeFromGroups();
        // remove before erasing type~!
        type = EntityType.None;
        direction = EntityDirection.None;
        directionVector.x = 0;
        directionVector.y = 0;
        counter = 0;
        energized = false;
        generatorNumber = 0;
    }

    public static function entitiesByType(type: EntityType): Array<Entity> {
        return sortedEntities[type.getIndex()];
    }

    public function removeFromGroups() {
        sortedEntities[type.getIndex()].remove(this);
        allEntities.remove(this);
    }

    public function addToGroups() {
        sortedEntities[type.getIndex()].push(this);
        allEntities.push(this);
    }

    public function copy(entity: Entity) {
        clear();
        type = entity.type;
        direction = entity.direction;
        counter = entity.counter;
        energized = entity.energized;
        calculateDirectionVector();
        addToGroups();
    }
    
    public function copyInactive(entity: Entity) {
        type = entity.type;
        direction = entity.direction;
        counter = entity.counter;
        energized = entity.energized;
        calculateDirectionVector();
    }

    public function constructType(type: EntityType) {
        switch (type) {
            case EntityType.Generator: Generator();
            case EntityType.Flower: Flower(EntityDirection.Right);
            case EntityType.Miner: Miner(EntityDirection.Right);
            case EntityType.Pusher: Pusher(EntityDirection.Right);
            case EntityType.Puller: Puller(EntityDirection.Right);
            case EntityType.Spore: Spore();
            case EntityType.Mineral: Mineral();
            case EntityType.Spawner: Spawner();
            default:
        }
    }

    public function Flower(direction: EntityDirection) {
        clear();
        type = EntityType.Flower;
        this.direction = direction;
        calculateDirectionVector();
        addToGroups();
    }

    public function Spore() {
        clear();
        type = EntityType.Spore;
        addToGroups();
    }

    public function Generator() {
        clear();
        type = EntityType.Generator;
        counter = generatorCharge;
        generatorNumber = lastGeneratorNumber + 1;
        lastGeneratorNumber++;
        addToGroups();
    }

    public function Miner(direction: EntityDirection) {
        clear();
        type = EntityType.Miner;
        this.direction = direction;
        calculateDirectionVector();
        addToGroups();
    }

    public function Pusher(direction: EntityDirection) {
        clear();
        type = EntityType.Pusher;
        this.direction = direction;
        calculateDirectionVector();
        addToGroups();
    }

    public function Puller(direction: EntityDirection) {
        clear();
        type = EntityType.Puller;
        this.direction = direction;
        calculateDirectionVector();
        addToGroups();
    }

    public function Mineral() {
        clear();
        type = EntityType.Mineral;
        addToGroups();
    }

    public function Spawner() {
        clear();
        type = EntityType.Spawner;
        addToGroups();
    }

    public function getTile(): Int {
        switch (type) {
            case EntityType.Flower: {
                var offset = Convert.toInt((Tiles.FlowerRightEnd - Tiles.FlowerRightStart) * counter / flowerCharge);
                switch(direction) {
                    case EntityDirection.Right: return Tiles.FlowerRightStart + offset;
                    case EntityDirection.Down: return Tiles.FlowerDownStart + offset;
                    case EntityDirection.Left: return Tiles.FlowerLeftStart + offset;
                    case EntityDirection.Up: return Tiles.FlowerUpStart + offset;
                    default:
                }
            }
            case EntityType.Spore: {
                if (energized) {
                    return Tiles.SporeOn;
                } else {
                    return Tiles.SporeOff;
                }
            }
            case EntityType.Generator: {
                var offset = Convert.toInt((Tiles.GeneratorEnd - Tiles.GeneratorStart) * (1 - counter / generatorCharge));
                return Tiles.GeneratorStart + offset;
            }
            case EntityType.Miner: {
                var offset = Convert.toInt((Tiles.MinerRightEnd - Tiles.MinerRightStart) * (1 - counter / minerCharge));
                switch(direction) {
                    case EntityDirection.Left: return Tiles.MinerLeftStart + offset;
                    case EntityDirection.Down: return Tiles.MinerDownStart + offset;
                    case EntityDirection.Right: return Tiles.MinerRightStart + offset;
                    case EntityDirection.Up: return Tiles.MinerUpStart + offset;
                    default:
                }
            }
            case EntityType.Pusher: {
                if (energized) {
                    switch(direction) {
                        case EntityDirection.Left: return Tiles.PusherOnLeft;
                        case EntityDirection.Down: return Tiles.PusherOnDown;
                        case EntityDirection.Right: return Tiles.PusherOnRight;
                        case EntityDirection.Up: return Tiles.PusherOnUp;
                        default:
                    }
                } else {
                    switch(direction) {
                        case EntityDirection.Left: return Tiles.PusherOffLeft;
                        case EntityDirection.Down: return Tiles.PusherOffDown;
                        case EntityDirection.Right: return Tiles.PusherOffRight;
                        case EntityDirection.Up: return Tiles.PusherOffUp;
                        default:
                    }
                }
            }
            case EntityType.Puller: {
                if (energized) {
                    switch(direction) {
                        case EntityDirection.Left: return Tiles.PullerOnLeft;
                        case EntityDirection.Down: return Tiles.PullerOnDown;
                        case EntityDirection.Right: return Tiles.PullerOnRight;
                        case EntityDirection.Up: return Tiles.PullerOnUp;
                        default:
                    }
                } else {
                    switch(direction) {
                        case EntityDirection.Left: return Tiles.PullerOffLeft;
                        case EntityDirection.Down: return Tiles.PullerOffDown;
                        case EntityDirection.Right: return Tiles.PullerOffRight;
                        case EntityDirection.Up: return Tiles.PullerOffUp;
                        default:
                    }
                }
            }
            case EntityType.Mineral: {
                return Tiles.Mineral;
            }
            case EntityType.Spawner: {
                var offset = Convert.toInt((Tiles.SpawnerEnd - Tiles.SpawnerStart) * (1 - counter / spawnerCharge));
                return Tiles.SpawnerStart + offset;
            }
            default:
        }
        return 0;
    }

    public function calculateDirectionVector() {
        switch (direction) {
            case EntityDirection.Left : {
                directionVector.x = -1;
                directionVector.y = 0;
            }
            case EntityDirection.Right : {
                directionVector.x = 1;
                directionVector.y = 0;
            }
            case EntityDirection.Up : {
                directionVector.x = 0;
                directionVector.y = -1;
            }
            case EntityDirection.Down : {
                directionVector.x = 0;
                directionVector.y = 1;
            }
            default:
        }
    }

    public function hasEnergy(): Bool {
        for (dx in -1...2) {
            for (dy in -1...2) {
                if (dx * dy != 0 || Main.outOfMapBound(x + dx, y + dy)) {
                    continue;
                }
                var otherEntity = Main.entityMap[x + dx][y + dy];
                if (otherEntity.type == EntityType.Generator || (otherEntity.type == EntityType.Spore && otherEntity.energized)) {
                    return true;
                }
            }
        }
        return false;
    }

    public function hasSporeEnergy(): Bool {
        for (dx in -1...2) {
            for (dy in -1...2) {
                if (dx * dy != 0 || Main.outOfMapBound(x + dx, y + dy)) {
                    continue;
                }
                var otherEntity = Main.entityMap[x + dx][y + dy];
                if (otherEntity.type == EntityType.Spore && otherEntity.energized) {
                    return true;
                }
            }
        }
        return false;
    }

    public function consumeEnergy() {
        var amount: Int;
        switch (type) {
            default: amount = 1;
        }
        for (dx in -1...2) {
            for (dy in -1...2) {
                if (dx * dy != 0 || Main.outOfMapBound(x + dx, y + dy)) {
                    continue;
                }
                var otherEntity = Main.entityMap[x + dx][y + dy];
                if (otherEntity.type == EntityType.Generator && otherEntity.counter > 0) {
                    otherEntity.counter -= amount;
                    if (otherEntity.counter < 0) {
                        otherEntity.counter = 0;
                    }
                    return;
                } else if (otherEntity.type == EntityType.Spore && otherEntity.energized) {
                    var generators = Entity.entitiesByType(EntityType.Generator);
                    for (generator in generators) {
                        if (generator.generatorNumber == otherEntity.generatorNumber) {
                            generator.counter -= amount;
                            if (generator.counter < 0) {
                                generator.counter = 0;
                            }
                            return;
                        }
                    }
                }
            }
        }
    }
}