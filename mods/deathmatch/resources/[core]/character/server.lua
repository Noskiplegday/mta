function getDB()

    local mysql =
        getResourceFromName("mysql")

    if mysql and
       getResourceState(mysql) == "running" then

        return exports.mysql:getConnection()

    end

    return false
end

addEventHandler(
    "onResourceStart",
    resourceRoot,
    function()

        local db = getDB()

        if not db then
            return
        end

        dbExec(db,[[
            CREATE TABLE IF NOT EXISTS characters (

                id INT AUTO_INCREMENT PRIMARY KEY,

                account_id INT NOT NULL UNIQUE,

                char_name VARCHAR(64),

                pos_x FLOAT DEFAULT 1715.28,
                pos_y FLOAT DEFAULT 1299.01,
                pos_z FLOAT DEFAULT 10.8279,

                rot FLOAT DEFAULT 271.935,

                skin INT DEFAULT 0,

                cash INT DEFAULT 5000,

                interior INT DEFAULT 0,
                dimension INT DEFAULT 0

            )
        ]])

        outputDebugString(
            "[CHARACTER] System loaded."
        )
    end
)

function loadPlayerCharacter(player, accountID, charName)

    local db = getDB()

    if not db then
        return false
    end

    fadeCamera(player,false)

    dbQuery(
        function(qh)

            local result =
                dbPoll(qh,0)

            if not result or #result == 0 then

                dbExec(
                    db,
                    [[
                    INSERT INTO characters
                    (account_id,char_name)
                    VALUES (?,?)
                    ]],
                    accountID,
                    charName
                )

                local q =
                    dbQuery(
                        db,
                        "SELECT * FROM characters WHERE account_id=? LIMIT 1",
                        accountID
                    )

                local data =
                    dbPoll(q,-1)

                if not data or #data == 0 then
                    return
                end

                local char =
                    data[1]

                setElementData(
                    player,
                    "char:id",
                    char.id
                )

                setElementData(
                    player,
                    "account:id",
                    accountID
                )

                spawnPlayer(
                    player,
                    1715.28,
                    1299.01,
                    10.8279,
                    271.935,
                    0
                )

                setPlayerMoney(player,5000)

                outputChatBox(
                    "#00FF00[VanCanhCity] Tạo nhân vật thành công!",
                    player,
                    255,255,255,true
                )

            else

                local char =
                    result[1]

                setElementData(
                    player,
                    "char:id",
                    char.id
                )

                setElementData(
                    player,
                    "account:id",
                    accountID
                )

                spawnPlayer(
                    player,
                    char.pos_x,
                    char.pos_y,
                    char.pos_z,
                    char.rot,
                    char.skin,
                    char.interior,
                    char.dimension
                )

                setPlayerMoney(
                    player,
                    char.cash
                )

                outputChatBox(
                    "#00FF00[VanCanhCity] Chào mừng quay trở lại!",
                    player,
                    255,255,255,true
                )
            end

            setCameraTarget(player,player)

            fadeCamera(player,true)

        end,
        db,
        "SELECT * FROM characters WHERE account_id=? LIMIT 1",
        accountID
    )

    return true
end

function saveCharacter(player)

    local accountID =
        getElementData(player,"account:id")

    if not accountID then
        return
    end

    local db = getDB()

    if not db then
        return
    end

    local x,y,z =
        getElementPosition(player)

    local _,_,rot =
        getElementRotation(player)

    dbExec(
        db,
        [[
        UPDATE characters
        SET
            pos_x=?,
            pos_y=?,
            pos_z=?,
            rot=?,
            skin=?,
            cash=?,
            interior=?,
            dimension=?
        WHERE account_id=?
        ]],
        x,y,z,
        rot,
        getElementModel(player),
        getPlayerMoney(player),
        getElementInterior(player),
        getElementDimension(player),
        accountID
    )
end

addEventHandler(
    "onPlayerQuit",
    root,
    function()

        saveCharacter(source)

    end
)

addEventHandler(
    "onResourceStop",
    resourceRoot,
    function()

        for _,player in ipairs(
            getElementsByType("player")
        ) do

            saveCharacter(player)

        end
    end
)
