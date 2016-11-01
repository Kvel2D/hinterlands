import Entity.EntityDirection;
import Entity.EntityType;
import haxegon.*;

typedef Vector2 = {
    x: Int,
    y: Int,
}

class Main {
    static inline var mapWidth = 96;
    static inline var mapHeight = 96;
    static inline var screenWidth = 30;
    static inline var screenHeight = 20;
    public static inline var tileSize = 16;
    static inline var minimapWidth = mapWidth / tileSize;
    static inline var minimapHeight = mapHeight / tileSize;

    public static var entityMap = [for (x in 0...mapWidth) [for (y in 0...mapHeight) new Entity(x, y)]];
    var entityMapOld = [for (x in 0...screenWidth) [for (y in 0...screenHeight) new Entity(x, y)]];
    var groundMap = [for (i in 0...mapWidth) [for (i in 0...mapHeight) false]];
    var groundMapOld = [for (i in 0...mapWidth) [for (i in 0...mapHeight) false]];
    var groundTiles = [for (i in 0...mapWidth) [for (i in 0...mapHeight) Tiles.GroundSpace]];
    var explorationMap = [for (i in 0...mapWidth) [for (i in 0...mapHeight) false]];
    var explorationMapOld = [for (i in 0...screenWidth) [for (i in 0...screenHeight) true]];
    var screenMap = [for (i in 0...screenWidth) [for (i in 0...screenHeight) Tiles.GroundSpace]];
    var screenMapOld = [for (i in 0...screenWidth) [for (i in 0...screenHeight) 1000]];

    var updateTimer = 0;
    static inline var updateTimerMax = 5;
    var draggedEntity: Entity = new Entity(0, 0);
    var dragging = false;
    var scrollingSkip = false;
    var lastDrag = {x: -10, y: -10};
    var lastCamera = {x: 0, y: 0};
    var camera = {x: 0, y: 0};
    var cameraMoved = false;
    var blueColor = Col.rgb(34, 96, 173);
    var spaceColor = Col.rgb(129, 124, 169);
    var groundColor = Col.rgb(157, 150, 128);
    var entityColor = Col.rgb(237, 65, 61);

    function new() {
        Gfx.clearScreenEachFrame = false;
        #if flash
        Gfx.resizeScreen(screenWidth * tileSize, screenHeight * tileSize, 2);
        #else 
        Gfx.resizeScreen(screenWidth * tileSize, screenHeight * tileSize);
        #end
        
        Gfx.loadTiles("tiles", tileSize, tileSize);
        Gfx.loadImage("map");

        // Generate ground map
        var initialChance = 0.5;
        var deathLimit = 4;
        var birthLimit = 3;
        var iterations = 6;
        for (x in 0...mapWidth) {
            for (y in 0...mapHeight) {
                if (Math.random() < initialChance) {
                    groundMap[x][y] = true;
                } else {
                    groundMap[x][y] = false;
                }
            }
        }
        for (i in 0...iterations) {
            for (x in 0...mapWidth) {
                for (y in 0...mapHeight) {
                    groundMapOld[x][y] = groundMap[x][y];
                }
            }
            for (x in 0...mapWidth) {
                for (y in 0...mapHeight) {
                    var count = countNeighbours(groundMapOld, x, y);

                    if (groundMapOld[x][y]) {
                        if (count < deathLimit) {
                            groundMap[x][y] = false;
                        } else {
                            groundMap[x][y] = true;
                        }
                    } else {
                        if (count > birthLimit) {
                            groundMap[x][y] = true;
                        } else {
                            groundMap[x][y] = false;
                        }
                    }
                }
            }
        }

        // Starting zone entities
        entityMap[13][4].Generator();
        entityMap[14][3].Spore();
        entityMap[15][4].Spore();
        entityMap[16][4].Spore();
        entityMap[17][4].Spore();
        entityMap[18][4].Spore();
        entityMap[19][4].Miner(EntityDirection.Right);

        for (entity in Entity.allEntities) {
            for (dx in -2...3) {
                for (dy in -2...3) {
                    explorationMap[entity.x + dx][entity.y + dy] = true;
                }
            }
        }

        // Entities after this point are "undiscovered"
        entityMap[24][6].Spore();
        entityMap[25][6].Flower(EntityDirection.Right);

        entityMap[24][15].Spore();
        entityMap[24][16].Spore();
        entityMap[25][16].Pusher(EntityDirection.Right);
        entityMap[4][18].Spawner();

        var hiddenUnitChance = 20;
        for (x in 1...15) {
            for (y in 1...15) {
                // skip starting area
                if (x < 6 && y < 6) {
                    continue;
                }
                if (Random.chance(hiddenUnitChance)) {
                    var startX = Convert.toInt(x * mapWidth / 16);
                    var startY = Convert.toInt(y * mapHeight / 16);
                    var endX = Convert.toInt(startX + mapWidth / 16);
                    var endY = Convert.toInt(startY + mapHeight / 16);
                    var spawned = false;
                    for (x2 in startX...endX) {
                        if (spawned) {
                            break;
                        }
                        for (y2 in startY...endY) {
                            if (spawned) {
                                break;
                            }
                            if (freeCell(x2, y2)) {
                                var count = countNeighbours(groundMap, x2, y2);
                                if (count >= 3 && Random.chance(40)) {
                                    spawnSpecialEntity(x2, y2);
                                    spawned = true;
                                }
                            }
                        }
                    }
                }

            }
        }

        for (entity in Entity.allEntities) {
            for (dx in -1...2) {
                for (dy in -1...2) {
                    if (!outOfMapBound(entity.x + dx, entity.y + dy)) {
                        groundMap[entity.x + dx][entity.y + dy] = false;
                    }
                }
            }
        }

        for (x in 0...mapWidth) {
            for (y in 0...mapHeight) {
                updateGroundTile(x, y);
            }
        }

        var mineralChance = 2;
        for (x in 1...mapWidth) {
            for (y in 1...mapHeight) {
                if (groundMap[x][y] && Random.chance(mineralChance)) {
                    entityMap[x][y].Mineral();
                    if (Random.chance(10)) {
                        var totalCrystals = Random.int(2, 8);
                        for (dx in -1...2) {
                            if (totalCrystals < 0) {
                                break;
                            }
                            for (dy in -1...2) {
                                if (totalCrystals < 0) {
                                    break;
                                }
                                if (!outOfMapBound(x + dx, y + dy)) {
                                    entityMap[x + dx][y + dy].Mineral();
                                    totalCrystals--;
                                }
                            }
                        }
                    }
                }
            }
        }


        Gfx.drawToImage("map");
        for (x in 0...mapWidth) {
            for (y in 0...mapHeight) {
                if (groundMap[x][y]) {
                    Gfx.fillBox(x, y, 1, 1, groundColor);
                } else {
                    Gfx.fillBox(x, y, 1, 1, spaceColor);
                }
            }
        }
        for (x in 0...mapWidth) {
            for (y in 0...mapHeight) {
                var entity = entityMap[x][y];
                if (entity.type == EntityType.None) {
                    if (groundMap[x][y]) {
                        Gfx.fillBox(x, y, 1, 1, groundColor);
                    } else {
                        Gfx.fillBox(x, y, 1, 1, spaceColor);
                    }
                } else if (entity.type == EntityType.Mineral) {
                    Gfx.fillBox(x, y, 1, 1, blueColor);
                } else {
                    Gfx.fillBox(x, y, 1, 1, entityColor);
                }
            }
        }
        Gfx.drawToScreen();
    }

    function countNeighbours(map: Array<Array<Bool>>, x: Int, y: Int): Int {
        var count = 0;
        for (dx in -1...2) {
            for (dy in -1...2) {
                var neighbourX = x + dx;
                var neighbourY = y + dy;
                if (dx == 0 && dy == 0) {
                    continue;
                } else if (outOfMapBound(neighbourX, neighbourY)){
                    count++;
                } else if (map[neighbourX][neighbourY]) {
                    count++;
                }
            }
        }
        return count;
    }

    var specialEntitiesSpawned = [for (i in 0...6) 0];
    function spawnSpecialEntity(x: Int, y: Int) {
        var entity = Random.int(0, 6);
        while (specialEntitiesSpawned[entity] >= 2) {
            entity = Random.int(0, 6);
        }
        specialEntitiesSpawned[entity]++;
        switch (entity) {
            case 0: { // 1miner combo
                entityMap[x - 3][y - 1].Spore();
                entityMap[x - 3][y + 1].Spore();
                entityMap[x - 2][y + 1].Spore();
                entityMap[x - 2][y - 1].Spore();
                entityMap[x - 2][y].Pusher(EntityDirection.Right);
                entityMap[x - 1][y - 1].Flower(EntityDirection.Down);
                entityMap[x - 1][y].Spore();
                entityMap[x - 1][y + 1].Spore();
                entityMap[x][y].Miner(EntityDirection.Right);
            }
            case 1: { // roundabout
                entityMap[x][y - 1].Spore();
                entityMap[x - 1][y].Spore();
                entityMap[x - 1][y + 1].Spore();
                entityMap[x + 1][y + 2].Spore();
                entityMap[x + 2][y + 2].Spore();
                entityMap[x + 2][y].Spore();
                entityMap[x + 2][y + 1].Spore();
                entityMap[x + 1][y - 1].Generator();
                entityMap[x][y + 2].Generator();
                entityMap[x - 2][y - 1].Pusher(EntityDirection.Right);
                entityMap[x - 1][y + 3].Pusher(EntityDirection.Up);
                entityMap[x + 2][y - 2].Pusher(EntityDirection.Down);
                entityMap[x + 3][y + 2].Pusher(EntityDirection.Left);
            }
            case 2: {  // 3miner combo
                entityMap[x - 1][y].Pusher(EntityDirection.Down);
                entityMap[x][y].Pusher(EntityDirection.Down);
                entityMap[x + 1][y].Pusher(EntityDirection.Down);
                entityMap[x + 2][y].Pusher(EntityDirection.Down);
                entityMap[x - 3][y + 1].Pusher(EntityDirection.Right);
                entityMap[x - 2][y].Flower(EntityDirection.Down);
                entityMap[x - 3][y].Spore();
                entityMap[x - 3][y - 1].Spore();
                entityMap[x - 2][y - 1].Spore();
                entityMap[x - 1][y - 1].Spore();
                entityMap[x][y - 1].Spore();
                entityMap[x + 1][y - 1].Spore();
                entityMap[x + 2][y - 1].Spore();
                entityMap[x + 2][y].Spore();
                entityMap[x + 2][y + 1].Spore();
                entityMap[x + 1][y + 1].Spore();
                entityMap[x][y + 1].Spore();
                entityMap[x - 1][y + 1].Spore();
                entityMap[x - 1][y + 2].Miner(EntityDirection.Down);
                entityMap[x][y + 2].Miner(EntityDirection.Down);
                entityMap[x + 1][y + 2].Miner(EntityDirection.Down);
            }
            case 3: { // mega flower 
                entityMap[x][y + 1].Flower(EntityDirection.Down);
                entityMap[x][y - 1].Flower(EntityDirection.Up);
                entityMap[x - 1][y].Flower(EntityDirection.Left);
                entityMap[x + 1][y].Flower(EntityDirection.Right);
            }
            case 4: { // mega flower 
                entityMap[x][y + 1].Flower(EntityDirection.Down);
                entityMap[x][y - 1].Flower(EntityDirection.Up);
                entityMap[x - 1][y].Flower(EntityDirection.Left);
                entityMap[x + 1][y].Flower(EntityDirection.Right);
            }
            case 5: { // spawner station 
                entityMap[x - 1][y - 1].Flower(EntityDirection.Right);
                entityMap[x + 1][y + 1].Flower(EntityDirection.Up);
                entityMap[x - 1][y].Spore();
                entityMap[x][y + 1].Spore();
                entityMap[x + 1][y - 1].Spawner();
            }
            case 6: { // train
                entityMap[x][y - 1].Spore();
                entityMap[x - 1][y - 1].Spore();
                entityMap[x - 2][y - 1].Spore();
                entityMap[x + 1][y - 1].Spore();
                entityMap[x + 2][y - 1].Spore();
                entityMap[x + 3][y - 1].Spore();
                entityMap[x + 4][y - 1].Spore();
                entityMap[x - 2][y].Pusher(EntityDirection.Right);
                entityMap[x - 1][y].Puller(EntityDirection.Left);
            }
            default:
        }
    }

    function updateGroundTile(x: Int, y: Int) {
        var left = false;
        var right = false;
        var up = false;
        var down = false;
        var sum = 0;
        if (!groundMap[x][y]) {
            groundTiles[x][y] = Tiles.GroundSpace;
        } else if (x == 0 || y == 0 || x == (mapWidth - 1) || y == (mapHeight - 1)) {
            groundTiles[x][y] = Tiles.GroundOpen;
        } else {
            left = groundMap[x - 1][y];
            right = groundMap[x + 1][y];
            up = groundMap[x][y - 1];
            down = groundMap[x][y + 1];
            sum = 0;
            if (left) {
                sum++;
            }
            if (right) {
                sum++;
            }
            if (up) {
                sum++;
            }
            if (down) {
                sum++;
            }
            if (sum == 0) {
                groundTiles[x][y] = Tiles.GroundClosed;
            } else if (sum == 4) {
                groundTiles[x][y] = Tiles.GroundOpen;
            } else if (sum == 3) {
                if (!left) {
                    groundTiles[x][y] = Tiles.GroundLeft;
                } else if (!right) {
                    groundTiles[x][y] = Tiles.GroundRight;
                } else if (!up) {
                    groundTiles[x][y] = Tiles.GroundUp;
                } else if (!down) {
                    groundTiles[x][y] = Tiles.GroundDown;
                }
            } else if (sum == 2) {
                if (!left && !up) {
                    groundTiles[x][y] = Tiles.GroundLeftUp;
                } else if (!up && !right) {
                    groundTiles[x][y] = Tiles.GroundUpRight;
                } else if (!right && !down) {
                    groundTiles[x][y] = Tiles.GroundRightDown;
                } else if (!down && !left) {
                    groundTiles[x][y] = Tiles.GroundDownLeft;
                } else if (!left && !right) {
                    groundTiles[x][y] = Tiles.GroundLeftRight;
                } else if (!up && !down) {
                    groundTiles[x][y] = Tiles.GroundUpDown;
                }
            } else if (sum == 1) {
                if (left) {
                    groundTiles[x][y] = Tiles.GroundUpRightDown;
                } else if (right) {
                    groundTiles[x][y] = Tiles.GroundDownLeftUp;
                } else if (up) {
                    groundTiles[x][y] = Tiles.GroundRightDownLeft;
                } else if (down) {
                    groundTiles[x][y] = Tiles.GroundLeftUpRight;
                }
            }
        }
    }

    function freeCell(x: Int, y: Int): Bool {
        return !groundMap[x][y] && entityMap[x][y].type == EntityType.None;
    }

    function energize(x: Int, y: Int, generatorNumber: Int) {
        for (dx in -1...2) {
            for (dy in -1...2) {
                if (dx * dy != 0) {
                    continue;
                }
                var entity = entityMap[x + dx][y + dy];
                if (entity.type == EntityType.Spore && !entity.energized) {
                    entity.energized = true;
                    entity.generatorNumber = generatorNumber;
                    energize(entity.x, entity.y, generatorNumber);
                }
            }
        }
    }

    public static function outOfMapBound(x: Int, y: Int): Bool {
        return x < 0 || x >= mapWidth || y < 0 || y >= mapHeight;
    }

    function oppositeDirections(e1: Entity, e2: Entity): Bool {
        return (e1.directionVector.x + e1.directionVector.y) == -(e2.directionVector.x + e2.directionVector.y);
    }

    function push(pusher: Entity): Bool {
        var pushX = 0;
        var pushY = 0;
        var pushingAgainstPusher = false;
        var t1 = 1;
        while (t1 < Entity.pushDistance) {
            pushX = pusher.x + t1 * pusher.directionVector.x;
            pushY = pusher.y + t1 * pusher.directionVector.y;
            if (!freeCell(pushX, pushY)) {
                var t2 = t1 + 1;
                while (t2 < 50) {
                    pushX = pusher.x + t2 * pusher.directionVector.x;
                    pushY = pusher.y + t2 * pusher.directionVector.y;
                    if (outOfMapBound(pushX, pushY) || groundMap[pushX][pushY]) {
                        return false;
                    } else if (freeCell(pushX, pushY)) {
                        // check for push conflict
                        var t3 = t2 - 1;
                        while (t3 < Entity.pushDistance + t1 + 1) {
                            pushX = pusher.x + t3 * pusher.directionVector.x;
                            pushY = pusher.y + t3 * pusher.directionVector.y;
                            if (outOfMapBound(pushX, pushY) || groundMap[pushX][pushY]) {
                                break;
                            }
                            var pushingAgainstPusher = (entityMap[pushX][pushY].type == EntityType.Pusher) 
                            && entityMap[pushX][pushY].energized 
                            && oppositeDirections(entityMap[pushX][pushY], pusher);
                            if (pushingAgainstPusher) {
                                return false;
                            }
                            t3++;
                        }

                        while (t2 > 1) {
                            pushX = pusher.x + t2 * pusher.directionVector.x;
                            pushY = pusher.y + t2 * pusher.directionVector.y;
                            entityMap[pushX][pushY].copy(entityMap[pushX - pusher.directionVector.x][pushY - pusher.directionVector.y]);
                            entityMap[pushX][pushY].energized = false;
                            t2--;
                        }
                        pushX = pusher.x + pusher.directionVector.x;
                        pushY = pusher.y + pusher.directionVector.y;
                        entityMap[pushX][pushY].clear();
                        return true;
                    }
                    t2++;
                }
                return false;
            }
            t1++;
        }
        return false;
    }

    function pull(puller: Entity): Bool {
        var pullX = 0;
        var pullY = 0;
        var t1 = 1;
        while (t1 < Entity.pullDistance) {
            pullX = puller.x + t1 * puller.directionVector.x;
            pullY = puller.y + t1 * puller.directionVector.y;
            if (!freeCell(pullX, pullY)) {
                // can't pull if no free space or pulling against a puller
                if (!freeCell(pullX - puller.directionVector.x, pullY - puller.directionVector.y)) {
                    return false;
                } else {
                    var t2 = t1;
                    while (t2 - t1 < Entity.pullDistance) {
                        pullX = puller.x + t2 * puller.directionVector.x;
                        pullY = puller.y + t2 * puller.directionVector.y;
                        if (outOfMapBound(pullX, pullY) || groundMap[pullX][pullY]) {
                            break;
                        }

                        var pullingAgainstPuller = (entityMap[pullX][pullY].type == EntityType.Puller) 
                        && entityMap[pullX][pullY].energized 
                        && oppositeDirections(entityMap[pullX][pullY], puller);
                        if (pullingAgainstPuller) {
                            return false;
                        }
                        t2++;
                    }
                    pullX = puller.x + (t1 - 1) * puller.directionVector.x;
                    pullY = puller.y + (t1 - 1) * puller.directionVector.y;
                    entityMap[pullX][pullY].copy(entityMap[pullX + puller.directionVector.x][pullY + puller.directionVector.y]);
                    entityMap[pullX][pullY].energized = false;
                    entityMap[pullX + puller.directionVector.x][pullY + puller.directionVector.y].clear();
                    return true;
                }
                return false;
            }
            t1++;
        }
        return false;
    }

    function spawn(spawner: Entity) {
        for (dx in -1...2) {
            for (dy in -1...2) {
                if (freeCell(spawner.x + dx, spawner.y + dy)) {
                    var entityTypes = Type.allEnums(EntityType);
                    var randomType = Random.int(3, entityTypes.length - 1);
                    entityMap[spawner.x + dx][spawner.y + dy].constructType(entityTypes[randomType]);
                    spawner.counter = 0;
                    return;
                }
            }
        }
    }

    function drawPosition(x: Int, y: Int) {
        if (x < 0 || x >= screenWidth || y < 0 || y >= screenHeight || (x >= screenWidth - minimapWidth && y < minimapHeight)) {
            return;
        }
        var entity = entityMap[x - camera.x][y - camera.y];
        if (entity.type != EntityType.None) {
            if (entity.type == EntityType.Mineral) {
                Gfx.drawTile(x * tileSize, y * tileSize, groundTiles[x - camera.x][y - camera.y]);
            } else {
                Gfx.drawTile(x * tileSize, y * tileSize, Tiles.GroundSpace);
            }
        }
        Gfx.drawTile(x * tileSize, y * tileSize, screenMap[x][y]);
        if (!explorationMap[x - camera.x][y - camera.y]) {
            Gfx.imagealpha(0.5);
            Gfx.drawTile(x * tileSize, y * tileSize, Tiles.Fog);
            Gfx.imagealpha(1);
        }
    }

    function update() {
        // 
        // EDITING
        // construct entity type using number keys in the order of the EntityType enum
        // var entityTypes = Type.allEnums(EntityType);
        // var keys = Type.allEnums(Key);
        // var oneIndex = Type.enumIndex(Key.ONE);
        // var i = 0;
        // while (i < entityTypes.length - 1) {
        //     if (Input.pressed(keys[oneIndex + i])) {
        //         var x = Convert.toInt(Mouse.x / tileSize - camera.x);
        //         var y = Convert.toInt(Mouse.y / tileSize - camera.y);
        //         entityMap[x][y].constructType(entityTypes[i + 1]);
        //         break;
        //     }
        //     i++;
        // }
        // if (Input.pressed(Key.E) && Mouse.leftClick()) {
        //     var x = Convert.toInt(Mouse.x / tileSize - camera.x);
        //     var y = Convert.toInt(Mouse.y / tileSize - camera.y);
        //     if (!groundMap[x][y]) {
        //         groundMap[x][y] = true;
        //     } else {
        //         groundMap[x][y] = false;
        //     }
        //     for (dx in -1...2) {
        //         for (dy in -1...2) {
        //             updateGroundTile(x + dx, y + dy);
        //         }
        //     }
        // }

        //
        // MOVE CAMERA
        //
        cameraMoved = false;
        if (scrollingSkip) {
            scrollingSkip = false;
        } else {
            scrollingSkip = true;
            if (Input.pressed(Key.A) && !Input.pressed(Key.D)) {
                if (camera.x < 0) {
                    camera.x++;
                    cameraMoved = true;
                }            
            } else if (Input.pressed(Key.D) && !Input.pressed(Key.A)) {
                if (camera.x > -mapWidth + screenWidth) {
                    camera.x--;
                    cameraMoved = true;
                }
            }
            if (Input.pressed(Key.S) && !Input.pressed(Key.W)) {
                if (camera.y > -mapHeight + screenHeight) {
                    camera.y--;
                    cameraMoved = true;
                }
            } else if (Input.pressed(Key.W) && !Input.pressed(Key.S)) {
                if (camera.y < 0) {
                    camera.y++;
                    cameraMoved = true;
                }
            }
        }

        //
        // DRAGGING
        //
        if (Mouse.leftClick()) {
            var x = Convert.toInt(Mouse.x / tileSize - camera.x);
            var y = Convert.toInt(Mouse.y / tileSize - camera.y);
            if (!dragging) {
                if (!outOfMapBound(x, y) && entityMap[x][y].type != EntityType.None && entityMap[x][y].type != EntityType.Mineral && explorationMap[x][y]) {
                    dragging = true;
                    draggedEntity.copy(entityMap[x][y]);
                    draggedEntity.removeFromGroups();
                    draggedEntity.energized = false;
                    entityMap[x][y].clear();
                }
            } else {
                if (!outOfMapBound(x, y) && freeCell(x, y) && explorationMap[x][y]) {
                    dragging = false;
                    entityMap[x][y].copy(draggedEntity);
                    draggedEntity.clear();
                    for (dx in -2...3) {
                        for (dy in -2...3) {
                            explorationMap[x + dx][y + dy] = true;
                        }
                    }
                    for (dx in -1...2) {
                        for (dy in -1...2) {
                            drawPosition(lastDrag.x + dx, lastDrag.y + dy);
                        }
                    }
                    for (dx in -1...2) {
                        for (dy in -1...2) {
                            drawPosition(x + dx, y + dy);
                        }
                    }
                }
            }
        }


        //
        // ROTATING
        //
        if (dragging && Mouse.mousewheel != 0) {
            if (Mouse.mousewheel > 0) {
                switch (draggedEntity.direction) {
                    case EntityDirection.Left : {
                        draggedEntity.direction = EntityDirection.Up;
                    }
                    case EntityDirection.Up : {
                        draggedEntity.direction = EntityDirection.Right;
                    }
                    case EntityDirection.Right : {
                        draggedEntity.direction = EntityDirection.Down;
                    }
                    case EntityDirection.Down : {
                        draggedEntity.direction = EntityDirection.Left;
                    }
                    default:
                }
            } else {
                switch (draggedEntity.direction) {
                    case EntityDirection.Left : {
                        draggedEntity.direction = EntityDirection.Down;
                    }
                    case EntityDirection.Up : {
                        draggedEntity.direction = EntityDirection.Left;
                    }
                    case EntityDirection.Right : {
                        draggedEntity.direction = EntityDirection.Up;
                    }
                    case EntityDirection.Down : {
                        draggedEntity.direction = EntityDirection.Right;
                    }
                    default:
                }
            }
            draggedEntity.calculateDirectionVector();
        }

        //
        // UPDATE ENTITIES
        //
        updateTimer++;
        if (updateTimer > updateTimerMax) {
            updateTimer = 0;

            var spores = Entity.entitiesByType(EntityType.Spore);
            for (spore in spores) {
                spore.energized = false;
            }

            var generators = Entity.entitiesByType(EntityType.Generator);
            for (generator in generators) {
                if (generator.counter != 0) {
                    for (dx in -1...2) {
                        for (dy in -1...2) {
                            if (dx * dy != 0) {
                                continue;
                            }
                            var otherEntity = entityMap[generator.x + dx][generator.y + dy];
                            if (otherEntity.type == EntityType.Spore) {
                                otherEntity.energized = true;
                                energize(otherEntity.x, otherEntity.y, generator.generatorNumber);
                            }
                        }
                    }
                }
            }

            var flowers = Entity.entitiesByType(EntityType.Flower);
            for (flower in flowers) {
                if (flower.hasEnergy() && freeCell(flower.x + flower.directionVector.x, flower.y + flower.directionVector.y)) {
                    if (flower.counter < Entity.flowerCharge) {
                        flower.counter++;
                    } else if (flower.counter >= Entity.flowerCharge) {
                        flower.counter = 0;
                        entityMap[flower.x + flower.directionVector.x][flower.y + flower.directionVector.y].Spore();
                        flower.consumeEnergy();
                    }
                }
            }

            var movedMiners = new Array<Entity>();
            var mineX = 0;
            var mineY = 0;
            var miners = Entity.entitiesByType(EntityType.Miner);
            for (miner in miners) {
                mineX = miner.x + miner.directionVector.x;
                mineY = miner.y + miner.directionVector.y;
                if (outOfMapBound(mineX, mineY)) {
                    continue;
                } else if (miner.hasSporeEnergy() && groundMap[mineX][mineY]) {
                    miner.consumeEnergy();
                    // consume spore
                    for (dx in -1...2) {
                        for (dy in -1...2) {
                            if (dx * dy != 0) {
                                continue;
                            }
                            var otherEntity = Main.entityMap[miner.x + dx][miner.y + dy];
                            if (otherEntity.type == EntityType.Spore && otherEntity.energized) {
                                otherEntity.clear();
                                break;
                            }
                        }
                    }
                    groundMap[mineX][mineY] = false;

                    if (entityMap[mineX][mineY].type == EntityType.Mineral) {
                        miner.counter += Entity.minerChargeGainMineral;
                    } else {
                        miner.counter += Entity.minerChargeGain;
                    }
                    if (miner.counter > Entity.minerCharge) {
                        miner.counter = Entity.minerCharge;
                    }

                    movedMiners.push(miner);
                    for (dx in -1...2) {
                        for (dy in -1...2) {
                            if (!outOfMapBound(mineX + dx, mineY + dy)) {
                                updateGroundTile(mineX + dx, mineY + dy);
                            }
                        }
                    }
                } else if (miner.counter > 0 && entityMap[mineX][mineY].type == EntityType.Generator) {
                    if (entityMap[mineX][mineY].counter < Entity.generatorCharge) {
                        entityMap[mineX][mineY].counter++;
                        miner.counter--;
                    }
                }
            }
            for (miner in movedMiners) {
                entityMap[miner.x + miner.directionVector.x][miner.y + miner.directionVector.y].copy(miner);
                miner.clear();
            }
            movedMiners.splice(0, movedMiners.length - 1);

            for (spawner in Entity.entitiesByType(EntityType.Spawner)) {
                for (dx in -1...2) {
                    for (dy in -1...2) {
                        var entity = entityMap[spawner.x + dx][spawner.y + dy];
                        if (entity.type == EntityType.Spore) {
                            entity.clear();
                            spawner.counter++;
                        }
                    }
                }
                if (spawner.counter >= Entity.spawnerCharge) {
                    spawn(spawner);
                }
            }

            var pushers = Entity.entitiesByType(EntityType.Pusher);
            for (pusher in pushers) {
                pusher.energized = pusher.hasEnergy();
            }
            var pullers = Entity.entitiesByType(EntityType.Puller);
            for (puller in pullers) {
                puller.energized = puller.hasEnergy();
            }

            for (pusher in pushers) {
                if (pusher.energized) {
                    if (push(pusher)) {
                        pusher.counter++;
                    }
                    if (pusher.counter > Entity.pushPullMax) {
                        pusher.counter = 0;
                        pusher.consumeEnergy();
                    }
                }
            }
            for (puller in pullers) {
                if (puller.energized) {
                    if (pull(puller)) {
                        puller.counter++;
                    }
                    if (puller.counter > Entity.pushPullMax) {
                        puller.counter = 0;
                        puller.consumeEnergy();
                    }
                }
            }

            for (entity in Entity.allEntities) {
                if (!entity.explored && explorationMap[entity.x][entity.y]) {
                    for (dx in -2...3) {
                        for (dy in -2...3) {
                            if (!outOfMapBound(entity.x + dx, entity.y + dy)) {
                                explorationMap[entity.x + dx][entity.y + dy] = true;
                            }
                        }
                    }
                    entity.explored = true;
                }
            }
        }

        //
        // UPDATE SCREEN STATE
        //
        var entity: Entity;
        for (x in 0...screenWidth) {
            for (y in 0...screenHeight) {
                if (entityMap[x - camera.x][y - camera.y].type == EntityType.None) {
                    screenMap[x][y] = groundTiles[x - camera.x][y - camera.y];
                } else {
                    screenMap[x][y] = entityMap[x - camera.x][y - camera.y].getTile();
                }
            }
        }

        //
        // ADD PUSH WAVES
        //
        var pushers = Entity.entitiesByType(EntityType.Pusher);
        var waveX = 0;
        var waveY = 0;
        var waveNotInFrustum = false;
        for (pusher in pushers) {
            if (pusher.energized) {
                var t = 1;
                while (t < Entity.pushDistance) {
                    waveX = pusher.x + t * pusher.directionVector.x;
                    waveY = pusher.y + t * pusher.directionVector.y;
                    waveNotInFrustum = waveX < -camera.x || waveX >= -camera.x + screenWidth || waveY < -camera.y || waveY >= -camera.y + screenHeight;
                    if (waveNotInFrustum || !freeCell(waveX, waveY)) {
                        break;
                    } else {
                        switch (pusher.direction) {
                            case EntityDirection.Left: screenMap[waveX + camera.x][waveY + camera.y] = Tiles.PusherWaveLeft;
                            case EntityDirection.Down: screenMap[waveX + camera.x][waveY + camera.y] = Tiles.PusherWaveDown;
                            case EntityDirection.Right: screenMap[waveX + camera.x][waveY + camera.y] = Tiles.PusherWaveRight;
                            case EntityDirection.Up: screenMap[waveX + camera.x][waveY + camera.y] = Tiles.PusherWaveUp;
                            default:
                        }
                    }
                    t++;
                }
            }
        }
        //
        // ADD PULL WAVES
        //
        var pullers = Entity.entitiesByType(EntityType.Puller);
        for (puller in pullers) {
            if (puller.energized) {
                var t = 1;
                while (t < Entity.pushDistance) {
                    waveX = puller.x + t * puller.directionVector.x;
                    waveY = puller.y + t * puller.directionVector.y;
                    waveNotInFrustum = waveX < -camera.x || waveX >= -camera.x + screenWidth || waveY < -camera.y || waveY >= -camera.y + screenHeight;
                    if (waveNotInFrustum || !freeCell(waveX, waveY)) {
                        break;
                    } else {
                        switch (puller.direction) {
                            case EntityDirection.Left: screenMap[waveX + camera.x][waveY + camera.y] = Tiles.PullerWaveLeft;
                            case EntityDirection.Down: screenMap[waveX + camera.x][waveY + camera.y] = Tiles.PullerWaveDown;
                            case EntityDirection.Right: screenMap[waveX + camera.x][waveY + camera.y] = Tiles.PullerWaveRight;
                            case EntityDirection.Up: screenMap[waveX + camera.x][waveY + camera.y] = Tiles.PullerWaveUp;
                            default:
                        }
                    }
                    t++;
                }
            }
        }


        //
        // DRAW SCREEN CHANGES
        //
        Gfx.changeTileset("tiles");
        var flowerTile = 0;
        for (x in 0...screenWidth) {
            for (y in 0...screenHeight) {
                if (screenMapOld[x][y] != screenMap[x][y] || explorationMapOld[x][y] != explorationMap[x - camera.x][y - camera.y]) {
                    drawPosition(x, y);
                }
            }
        }

        //
        // DRAW MINIMAP
        //
        Gfx.drawToImage("map");
        var minimapChanged = false;
        for (x in 0...mapWidth) {
            for (y in 0...mapHeight) {
                if (groundMap[x][y] != groundMapOld[x][y] && entityMap[x][y].type != EntityType.None) {
                    minimapChanged = true;
                    if (groundMap[x][y]) {
                        Gfx.fillBox(x, y, 1, 1, groundColor);
                    } else {
                        Gfx.fillBox(x, y, 1, 1, spaceColor);
                    }
                }
            }
        }
        for (x in 0...screenWidth) {
            for (y in 0...screenHeight) {
                var entity = entityMap[x - lastCamera.x][y - lastCamera.y];
                if (entity.type != entityMapOld[x][y].type) {
                    minimapChanged = true;
                    if (entity.type == EntityType.None) {
                        if (groundMap[x - lastCamera.x][y - lastCamera.y]) {
                            Gfx.fillBox(x - lastCamera.x, y - lastCamera.y, 1, 1, groundColor);
                        } else {
                            Gfx.fillBox(x - lastCamera.x, y - lastCamera.y, 1, 1, spaceColor);
                        }
                    } else if (entity.type == EntityType.Mineral) {
                        Gfx.fillBox(x - lastCamera.x, y - lastCamera.y, 1, 1, blueColor);
                    } else {
                        Gfx.fillBox(x - lastCamera.x, y - lastCamera.y, 1, 1, entityColor);
                    }
                }
            }
        }
        Gfx.drawToScreen();
        var mouseOverMinimap = lastDrag.x >= screenWidth - minimapWidth - 1 && lastDrag.y <= minimapHeight + 1;
        if (minimapChanged || mouseOverMinimap || cameraMoved) {
            Gfx.drawImage(screenWidth * tileSize - mapWidth, 0, "map");
            Gfx.drawBox(screenWidth * tileSize - mapWidth - camera.x, -camera.y, 30, 20, Col.GRAY);
        }

        //
        // DRAW DRAGGED ENTITY AND 3x3 AREA AROUND
        //
        if (dragging) {
            for (dx in -1...2) {
                for (dy in -1...2) {
                    drawPosition(lastDrag.x + dx, lastDrag.y + dy);
                }
            }

            Gfx.drawTile(Convert.toInt(Mouse.x - tileSize / 2), Convert.toInt(Mouse.y - tileSize / 2), draggedEntity.getTile());
            lastDrag.x = Convert.toInt(Mouse.x / tileSize);
            lastDrag.y = Convert.toInt(Mouse.y / tileSize);
        }

        //
        // SAVE STATES
        //
        lastCamera.x = camera.x;
        lastCamera.y = camera.y;
        for (x in 0...screenWidth) {
            for (y in 0...screenHeight) {
                entityMapOld[x][y].copyInactive(entityMap[x - camera.x][y - camera.y]);
            }
        }
        for (x in 0...screenWidth) {
            for (y in 0...screenHeight) {
                explorationMapOld[x][y] = explorationMap[x - camera.x][y - camera.y];
            }
        }
        for (x in 0...screenWidth) {
            for (y in 0...screenHeight) {
                screenMapOld[x][y] = screenMap[x][y];
            }
        }
        for (x in 0...mapWidth) {
            for (y in 0...mapHeight) {
                groundMapOld[x][y] = groundMap[x][y];
            }
        }
    }
}