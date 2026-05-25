-- vcc_hud/server.lua
-- Hunger & Thirst decay system

local playerData = {}

local HUNGER_DECAY = 0.5   -- mỗi phút giảm bao nhiêu
local THIRST_DECAY = 0.8   -- khát giảm nhanh hơn

local function initPlayer(player)
    playerData[player] = {
        hunger = 100,
        thirst = 100,
        money  = 0,
    }
    local name = getPlayerName(player)
    triggerClientEvent(player, "vcc:updateHUD", player, {
        hunger = 100, thirst = 100, money = 0, name = name
    })
end

addEventHandler("onPlayerJoin", root, function()
    initPlayer(source)
end)

addEventHandler("onPlayerQuit", root, function()
    playerData[source] = nil
end)

-- Decay timer (every 60 seconds)
setTimer(function()
    for player, data in pairs(playerData) do
        if isElement(player) and getElementType(player) == "player" then
            data.hunger = math.max(0, data.hunger - HUNGER_DECAY)
            data.thirst = math.max(0, data.thirst - THIRST_DECAY)

            -- Damage if starving/dehydrated
            if data.hunger <= 0 or data.thirst <= 0 then
                local hp = getElementHealth(player)
                if hp > 10 then
                    setElementHealth(player, hp - 2)
                end
            end

            triggerClientEvent(player, "vcc:updateHUD", player, {
                hunger = data.hunger,
                thirst = data.thirst,
                money  = getPlayerMoney(player),
                name   = getPlayerName(player),
            })
        end
    end
end, 60000, 0)

-- Commands để ăn/uống
addCommandHandler("an", function(player, cmd, ...)
    if playerData[player] then
        playerData[player].hunger = math.min(100, playerData[player].hunger + 30)
        triggerClientEvent(player, "vcc:updateHUD", player, {hunger = playerData[player].hunger})
        outputChatBox("🍖 Bạn đã ăn. Đói: "..math.floor(playerData[player].hunger).."%", player, 39, 174, 96)
    end
end)

addCommandHandler("uong", function(player, cmd, ...)
    if playerData[player] then
        playerData[player].thirst = math.min(100, playerData[player].thirst + 40)
        triggerClientEvent(player, "vcc:updateHUD", player, {thirst = playerData[player].thirst})
        outputChatBox("💧 Bạn đã uống. Khát: "..math.floor(playerData[player].thirst).."%", player, 52, 152, 219)
    end
end)

-- Public: server-side set hunger/thirst
function vcc_setHunger(player, val)
    if playerData[player] then
        playerData[player].hunger = math.max(0, math.min(100, val))
        triggerClientEvent(player, "vcc:updateHUD", player, {hunger = playerData[player].hunger})
    end
end

function vcc_setThirst(player, val)
    if playerData[player] then
        playerData[player].thirst = math.max(0, math.min(100, val))
        triggerClientEvent(player, "vcc:updateHUD", player, {thirst = playerData[player].thirst})
    end
end

function vcc_getHunger(player)
    if playerData[player] then return playerData[player].hunger end
    return 100
end

function vcc_getThirst(player)
    if playerData[player] then return playerData[player].thirst end
    return 100
end
