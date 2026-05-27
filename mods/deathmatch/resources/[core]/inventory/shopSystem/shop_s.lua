-- Database Connection
local db = dbConnect("sqlite", "shops.db")

-- Create Shops Table in DB if Not Exists
if db then
    dbExec(db, [[
        CREATE TABLE IF NOT EXISTS shops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            shopname TEXT,
            owner TEXT,
            x REAL,
            y REAL,
            z REAL,
            interior INTEGER,
            dimension INTEGER,
            items TEXT
        )
    ]])
end


local shops = {}

-- Function to Load Shops from Database
local function loadShopsFromDB()
    -- Get all shop IDs from the database
    local result = dbPoll(dbQuery(db, "SELECT id FROM shops"), -1)
    local dbShopIDs = {}

    if result and #result > 0 then
        for _, row in ipairs(result) do
            dbShopIDs[tonumber(row.id)] = true -- Store database shop IDs in a table
        end
    end

    -- Iterate over predefinedShops
    for _, shop in ipairs(predefinedShops) do
        local shopID = shop.id
        local query = dbPoll(dbQuery(db, "SELECT * FROM shops WHERE id = ?", shopID), -1)

        if query and #query > 0 then
            -- Shop exists in the database
            local dbShop = query[1]
            local dbItems = fromJSON(dbShop.items) or {}

            -- Remove items that are not in predefinedShops
            for item in pairs(dbItems) do
                if not shop.items[item] then
                    dbItems[item] = nil -- Remove item from table
                end
            end

            -- Add missing items from predefinedShops to the database list
            for item, details in pairs(shop.items) do
                if not dbItems[item] then
                    dbItems[item] = details
                end
            end

            -- Update the shop's location and items in the database
            dbExec(db, "UPDATE shops SET shopname = ?, x=?, y=?, z=?, interior=?, dimension=?, items=? WHERE id=?",
                shop.name, shop.x, shop.y, shop.z, shop.interior, shop.dimension, toJSON(dbItems), shopID)

            -- Update shop in `shops` table
            shops[shopID] = {
                id = shopID,
                name = shop.name,
                owner = dbShop.owner,
                x = shop.x, y = shop.y, z = shop.z,
                interior = shop.interior, dimension = shop.dimension,
                items = dbItems
            }
        else
            -- Shop does not exist, insert into database
            dbExec(db, "INSERT INTO shops (id, shopname, owner, x, y, z, interior, dimension, items) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                shop.id, shop.name, shop.owner, shop.x, shop.y, shop.z, shop.interior, shop.dimension, toJSON(shop.items))

            -- Add shop to `shops` table
            shops[shopID] = shop
        end

        -- Mark shop as existing in predefinedShops
        dbShopIDs[shopID] = nil
    end

    -- Remove shops from the database that are not in predefinedShops
    for shopID in pairs(dbShopIDs) do
        dbExec(db, "DELETE FROM shops WHERE id = ?", shopID)
        shops[shopID] = nil -- Remove from shops table
    end

    -- Create Markers for All Shops
    for _, shop in pairs(shops) do
        local marker = createMarker(shop.x, shop.y, shop.z - 1, "cylinder", 1.5, 255, 255, 0, 50)
        local col = createColSphere(shop.x, shop.y, shop.z, 2)
        setElementData(col, "shopID", shop.id)
    end
end



-- Load Shops from Database on Resource Start
addEventHandler("onResourceStart", resourceRoot, function()
    loadShopsFromDB()
end)

-- Save Shops to Database on Resource Stop (Efficient Update)
addEventHandler("onResourceStop", resourceRoot, function()
    for _, shop in ipairs(shops) do
        dbExec(db, "UPDATE shops SET shopname = ?, owner = ?, x = ?, y = ?, z = ?, interior = ?, dimension = ?, items = ? WHERE id = ?",
            shop.name, shop.owner, shop.x, shop.y, shop.z, shop.interior, shop.dimension, toJSON(shop.items), shop.id)
    end
end)

-- Player Requests Shop Data (when pressing 'E' near a shop)
addEvent("requestShopItems", true)
addEventHandler("requestShopItems", root, function()
    local player = client
    local playerX, playerY, playerZ = getElementPosition(client)
    for _, shop in pairs(shops) do
        local distance = getDistanceBetweenPoints3D(playerX, playerY, playerZ, shop.x, shop.y, shop.z)
        if distance <= 3 then -- Ensure Player is Near Shop
            triggerClientEvent(client, "openShopGUI", client, shop.id, shop)
            return
        end
    end
    message(player,"You are not near any shop!", "error")
end)

--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- Handle Player Purchases
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
-- Check if a player is the shop owner
function isShopOwner(player, shop)
    local account = getPlayerAccount(player)
    if account and not isGuestAccount(account) then
        return shop.owner == getAccountName(account) or isObjectInACLGroup("user." .. getAccountName(account), aclGetGroup("Admin"))
    end
    return false
end

-- Create shop logs table (Ensure timestamp format)
dbExec(db, [[
    CREATE TABLE IF NOT EXISTS shop_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_id INTEGER,
        buyer TEXT,
        item TEXT,
        quantity INTEGER,
        price INTEGER,
        timestamp TEXT DEFAULT (strftime('%d/%m/%Y - %H:%M:%S', 'now', 'localtime'))
    )
]])

addEvent("buyItem", true)
addEventHandler("buyItem", root, function(shopID, cart)
    local player = client
    local account = getPlayerAccount(client)
    if not account or isGuestAccount(account) then return end
    local balance = exports.money:getMoney(account)
    local shopID = tonumber(shopID)
    local shop = shops[shopID]
    if not shop then return end
    local totalCost = 0
    for item, qty in pairs(cart) do
        if shop.items[item] and shop.items[item].quantity >= qty then
            totalCost = totalCost + (shop.items[item].price * qty)
        else
            message(player, "Not enough stock for " .. item .. "!", "error")
            triggerClientEvent(player, "shop:message", player, "Not enough stock for " .. item .. "!", "error")
            return
        end
    end
    if balance >= totalCost then
        for item, qty in pairs(cart) do
            if giveItem(client, item, qty) then
                shop.items[item].quantity = shop.items[item].quantity - qty
                local itemCost = shop.items[item].price * qty
                exports.money:takeMoney(account, itemCost)
                if shop.owner then
                    local ownerAccount = getAccount(shop.owner)
                    if ownerAccount then
                        exports.money:giveMoney(ownerAccount, itemCost)
                    end
                end
                dbExec(db, "INSERT INTO shop_logs (shop_id, buyer, item, quantity, price) VALUES (?, ?, ?, ?, ?)",
                    shopID, getAccountName(account), item, qty, itemCost
                )
                shopDiscordWebhookSend("SHOP ID: " ..shopID.." | " ..getAccountName(account).." bought "..qty.." "..item.." for " ..itemCost .."$")
                message(player, "Item Bought: " .. item, "success")
                triggerClientEvent(player, "shop:message", player, "Item Bought: " .. item, "success")
            else
                message(player, "Purchase failed for item " .. item, "error")
                triggerClientEvent(player, "shop:message", player, "Purchase failed for item " .. item, "error")
                return
            end
        end
        message(player, "You bought items for $" .. totalCost, "success")
        triggerClientEvent(player, "shop:message", player, "You bought items for $" .. totalCost, "success")
        dbExec(db, "UPDATE shops SET items = ? WHERE id = ?", toJSON(shop.items), shopID)
        triggerClientEvent(player, "shop:closeUI", player)
    else
        message(player, "INSUFFICIENT BALANCE", "error")
        triggerClientEvent(player, "shop:message", player, "INSUFFICIENT BALANCE", "error")
    end
end)

-- Command to view shop logs
addCommandHandler("shoplogs", function(player)
    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then return end

    local playerX, playerY, playerZ = getElementPosition(player)
    local shopID = nil

    -- Find the shop near the player
    for id, shop in pairs(shops) do
        local distance = getDistanceBetweenPoints3D(playerX, playerY, playerZ, shop.x, shop.y, shop.z)
        if distance <= 3 and isShopOwner(player, shop) then
            shopID = id
            break
        end
    end

    if not shopID then
        message(player, "You are not near your shop or do not own this shop.", "error")
        return
    end

    -- Fetch logs only for this shop, including timestamp
    local logs = dbPoll(dbQuery(db, "SELECT id, buyer, item, quantity, price, timestamp FROM shop_logs WHERE shop_id = ?", shopID), -1)

    if logs and #logs > 0 then
        triggerClientEvent(player, "showShopLogsGUI", player, logs)
    else
        message(player, "No transactions found for this shop!", "error")
    end
end)


--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

--Refill item to shop
-- Refill item to shop
addEvent("refillItem", true)
addEventHandler("refillItem", root, function(shopID, itemName)
    local player = client
    local shop = shops[shopID]

    if not shop or not isShopOwner(player, shop) then
        message(player, "You are not the owner of this shop!", "error")
        return
    end

    if shop.items[itemName] then
        local availableAmount = getItem(player, itemName) -- Get available item quantity

        if availableAmount and availableAmount > 0 then
            if takeItem(player, itemName, availableAmount) then -- Take all available items
                local previousAmount = shop.items[itemName].quantity or 0
                shop.items[itemName].quantity = previousAmount + availableAmount -- Add to existing quantity
                
                -- Save to database
                dbExec(db, "UPDATE shops SET items = ? WHERE id = ?", toJSON(shop.items), shopID)

                -- Log the refill in shop_logs table
                local ownerAccount = getPlayerAccount(player)
                if ownerAccount then
                    dbExec(db, "INSERT INTO shop_logs (shop_id, buyer, item, quantity, price) VALUES (?, ?, ?, ?, ?)",
                        shopID, "Item Refill", itemName, availableAmount, "Current qty: " .. shop.items[itemName].quantity
                    )
                end
                shopDiscordWebhookSend("SHOP ID: " ..shopID.." | " ..getAccountName(ownerAccount).." REFILLED "..itemName.." TO " ..shop.items[itemName].quantity)

                message(player, "You refilled " .. itemName .. " by " .. availableAmount .. "! Total: " .. shop.items[itemName].quantity, "success")
            else
                message(player, "Failed to remove items from your inventory!", "error")
            end
        else
            message(player, "You do not have this item in your inventory to refill!", "error")
        end
    else
        message(player, "This item does not exist in the shop!", "error")
    end
end)



-- Command: /shopmanage (Shop owner accesses the shop management GUI)
addCommandHandler("shopmanage", function(player)
    local playerX, playerY, playerZ = getElementPosition(player)
    
    for _, shop in ipairs(shops) do
        local distance = getDistanceBetweenPoints3D(playerX, playerY, playerZ, shop.x, shop.y, shop.z)
        if distance <= 3 then
            if isShopOwner(player, shop) then
                triggerClientEvent(player, "openShopManagementGUI", player, shop)
                return
            else
                message(player,"You are not the owner of this shop!", "error")
                return
            end
        end
    end
    
    message(player,"You are not near any shop!", "error")
end)

-- Admin Command: /refillshop <shopID> (Refill all items in a shop)
addCommandHandler("shoprefill", function(player, cmd, shopID)
    if not shopID then
        message(player,"Usage: /shoprefill <shopID>", "warn")
        return
    end

    shopID = tonumber(shopID)
    if not shopID then
        message(player,"Invalid shop ID!", "error")
        return
    end

    if not isObjectInACLGroup("user." .. getAccountName(getPlayerAccount(player)), aclGetGroup("Admin")) then
        message(player,"You don't have permission to use this command!", "error")
        return
    end

    for _, shop in ipairs(shops) do
        if shop.id == shopID then
            for item, data in pairs(shop.items) do
                data.quantity = 10 -- Default refill
            end

            dbExec(db, "UPDATE shops SET items = ? WHERE id = ?", toJSON(shop.items), shop.id)
            message(player,"Shop ID " .. shopID .. " has been refilled!", "success")
            shopDiscordWebhookSend("[COMPLETE REFILL] - SHOP ID: " ..shopID.." | by " ..getAccountName(getPlayerAccount(player)))
            return
        end
    end

    message(player,"Shop ID not found!", "error")
end)


-- Command to get the shop ID where the player is standing
addCommandHandler("shopid", function(player)
    local playerX, playerY, playerZ = getElementPosition(player)
    for _, shop in pairs(shops) do
        local distance = getDistanceBetweenPoints3D(playerX, playerY, playerZ, shop.x, shop.y, shop.z)
        if distance <= 3 then
            message(player,"Shop ID: " .. shop.id, "success")
            return
        end
    end
    message(player,"You are not near any shop!", "error")
end)

-- Command to set a shop owner by admin
addCommandHandler("shopsetowner", function(player, cmd, shopID, ownerName)
    if not isObjectInACLGroup("user." .. getAccountName(getPlayerAccount(player)), aclGetGroup("Admin")) then
        message(player,"You don't have permission to use this command!", "error")
        return
    end

    if not shopID or not ownerName then
        message(player,"Usage: /shopsetowner [shopID] [ownerName]", "warn")
        return
    end

    local shopID = tonumber(shopID)
    if not shops[shopID] then
        message(player,"Invalid shop ID!", "error")
        return
    end

    shops[shopID].owner = ownerName
    dbExec(db, "UPDATE shops SET owner = ? WHERE id = ?", ownerName, shopID)

    message(player,"Shop ID " .. shopID .. " is now owned by " .. ownerName, "success")
    shopDiscordWebhookSend("[SHOP OWNER CHANGED]: Shop ID " .. shopID .. " is now owned by " .. ownerName)
end)

addCommandHandler("shophelp", function(player)
    triggerClientEvent(player, "openShopHelpGUI", player)
end)

----------------------------------------------------------------
--WEBHOOKS
----------------------------------------------------------------

local shopWebhookURL = "https://discord.com/api/webhooks/1354879610617205007/9WVLFwuOiOBTaiFqWtONLzMggwJ0FCP06eRTyKXEmpl4unXjRJef_7ACxjxynN6rvSRd"

function shopDiscordWebhookSend(message)
    sendOptions = {
        formFields = {
            content="```"..message.."```"
        },
    }
    fetchRemote ( shopWebhookURL, sendOptions, WebhookCallback )
    -- Save to .txt file
    local logFile = fileOpen("logs/shopLogs.txt") or fileCreate("logs/shopLogs.txt") -- Open or create file
    if logFile then
        fileSetPos(logFile, fileGetSize(logFile)) -- Move to end of file
        fileWrite(logFile, message .. "\n") -- Write message with new line
        fileFlush(logFile) -- Save changes
        fileClose(logFile) -- Close file
    end
end

-- 2 arguments (responseData gives back the response or "ERROR" )
function WebhookCallback(responseData) 
    return
end




--------------------------------------------------------------------------------------------------------------------------------

function sendShopLocationsToClient(player)
    if isElement(player) then
        triggerClientEvent(player, "receiveShopLocations", player, predefinedShops)
    end
end

addEventHandler("onPlayerJoin", root, function()
    sendShopLocationsToClient(source)
end)

