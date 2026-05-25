-- vcc_inventory/server.lua
-- Inventory system with item use effects

local playerInventory = {}

-- Item effects khi sử dụng
local ITEM_EFFECTS = {
    ga_ran      = {hunger=30, thirst=0,  hp=0},
    banh_mi     = {hunger=20, thirst=0,  hp=0},
    nuoc_suoi   = {hunger=0,  thirst=40, hp=0},
    nuoc_ngot   = {hunger=5,  thirst=25, hp=0},
    com_hop     = {hunger=40, thirst=15, hp=0},
    thuoc_bong  = {hunger=0,  thirst=0,  hp=20},
    kit_cuu_thuong={hunger=0, thirst=0,  hp=60},
    adrenaline  = {hunger=0,  thirst=0,  hp=100},
}

-- Default test inventory
local DEFAULT_ITEMS = {
    {id="ga_ran",     qty=3},
    {id="banh_mi",    qty=2},
    {id="nuoc_suoi",  qty=5},
    {id="nuoc_ngot",  qty=1},
    {id="com_hop",    qty=1},
    {id="thuoc_bong", qty=4},
    {id:"kit_cuu_thuong",qty=1},
    {id="dao_kiem",   qty=1},
    {id="sung_luc",   qty=1},
    {id="ban_do",     qty=1},
    {id="dien_thoai", qty=1},
}

local function getInventory(player)
    if not playerInventory[player] then
        -- Deep copy default
        local inv = {}
        for _, v in ipairs(DEFAULT_ITEMS) do
            table.insert(inv, {id=v.id, qty=v.qty})
        end
        playerInventory[player] = inv
    end
    return playerInventory[player]
end

local function invToJson(inv)
    local parts = {}
    for _, item in ipairs(inv) do
        table.insert(parts, '{"id":"'..item.id..'","qty":'..item.qty..'}')
    end
    return '['..table.concat(parts, ',')..']'
end

local function findItem(inv, id)
    for i, item in ipairs(inv) do
        if item.id == id then return i, item end
    end
    return nil, nil
end

addEventHandler("onPlayerQuit", root, function()
    playerInventory[source] = nil
end)

-- Request inventory
addEvent("vcc:requestInventory", true)
addEventHandler("vcc:requestInventory", root, function()
    local player = client
    local inv = getInventory(player)
    local money = getPlayerMoney(player)
    triggerClientEvent(player, "vcc:sendInventory", player, invToJson(inv), money)
end)

-- Use item
addEvent("vcc:useItem", true)
addEventHandler("vcc:useItem", root, function(itemId, qty)
    local player = client
    local inv = getInventory(player)
    local idx, item = findItem(inv, itemId)
    if not idx then
        triggerClientEvent(player, "vcc:itemUsed", player, itemId, false, "Không tìm thấy vật phẩm!")
        return
    end

    local eff = ITEM_EFFECTS[itemId]
    if eff then
        -- Apply HP
        if eff.hp and eff.hp > 0 then
            local hp = getElementHealth(player)
            setElementHealth(player, math.min(100, hp + eff.hp))
        end
        -- Apply hunger/thirst via HUD resource
        if eff.hunger and eff.hunger > 0 then
            if exports.vcc_hud then
                exports.vcc_hud:vcc_setHunger(player, 
                    (exports.vcc_hud:vcc_getHunger and exports.vcc_hud:vcc_getHunger(player) or 50) + eff.hunger)
            end
        end
        if eff.thirst and eff.thirst > 0 then
            if exports.vcc_hud then
                exports.vcc_hud:vcc_setThirst(player,
                    (exports.vcc_hud:vcc_getThirst and exports.vcc_hud:vcc_getThirst(player) or 50) + eff.thirst)
            end
        end
    end

    -- Remove item
    item.qty = item.qty - (qty or 1)
    if item.qty <= 0 then
        table.remove(inv, idx)
    end

    triggerClientEvent(player, "vcc:itemUsed", player, itemId, true, "Đã sử dụng vật phẩm!")
    -- Refresh
    triggerClientEvent(player, "vcc:sendInventory", player, invToJson(inv), getPlayerMoney(player))
end)

-- Drop item
addEvent("vcc:dropItem", true)
addEventHandler("vcc:dropItem", root, function(itemId, qty)
    local player = client
    local inv = getInventory(player)
    local idx, item = findItem(inv, itemId)
    if not idx then return end
    item.qty = item.qty - (qty or 1)
    if item.qty <= 0 then table.remove(inv, idx) end
    outputChatBox("🗑 "..getPlayerName(player).." đã vứt bỏ "..itemId, root, 192, 57, 43)
end)

-- Public: give item to player
function vcc_giveItem(player, itemId, qty)
    local inv = getInventory(player)
    local idx, item = findItem(inv, itemId)
    if idx then
        item.qty = item.qty + (qty or 1)
    else
        table.insert(inv, {id=itemId, qty=(qty or 1)})
    end
    triggerClientEvent(player, "vcc:itemAdded", player, itemId)
    triggerClientEvent(player, "vcc:sendInventory", player, invToJson(inv), getPlayerMoney(player))
end
