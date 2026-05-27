local MAX_INVENTORY_SLOTS = 25

-- Database connection (SQLite)
local db = dbConnect("sqlite", "inventory.db")

if not db then
    outputDebugString("Failed to connect to the database.")
    return
end

-- Create the inventory table if it doesn't exist
dbExec(db, [[
    CREATE TABLE IF NOT EXISTS inventory (
        player_id INTEGER NOT NULL,
        account_name TEXT NOT NULL,
        slot INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        amount INTEGER NOT NULL,
        weight INTEGER NOT NULL,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL
    )
]])

-- Create the alternate inventory table if it doesn't exist
dbExec(db, [[
    CREATE TABLE IF NOT EXISTS altInventory (
        invID TEXT NOT NULL,
        slot INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        amount INTEGER NOT NULL,
        weight INTEGER NOT NULL,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL
    )
]])

-- Create the house storage table if it doesn't exist
dbExec(db, [[
    CREATE TABLE IF NOT EXISTS houseStorage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x REAL NOT NULL,
        y REAL NOT NULL,
        z REAL NOT NULL,
        interior INTEGER NOT NULL,
        dimension INTEGER NOT NULL,
        capacity INTEGER NOT NULL
    )
]])

-- Table to manage inventory status , inventories and alternate inventories
local inventoryStatus = {}

local inventories = {}

local alternateInventories = {}

-- house storage definitions loaded from DB
local houseStorages = {}

-- Function to check if an alternate inventory is accessible
function isAltInventoryAccessible(invID)
    if inventoryStatus[invID] == nil then
        inventoryStatus[invID] = true
    end
    return inventoryStatus[invID]
end

-- Function to set the accessibility of an alternate inventory
function setAltInventoryAccessibility(invID, accessible)
    inventoryStatus[invID] = accessible
end

-- Function to load inventory from element data
function loadInventory(player)
    local account = getPlayerAccount(player)
    if isGuestAccount(account) then return end

-- MAIN INVENTORY
    local playerID = getElementData(player, "id")
    local result = {}

    local result = inventories[playerID] or {}
    triggerClientEvent(player, "onInventoryLoad", player, result)

-- ALTERNATE INVENTORY
    -- CHECK AND OPEN VEHICLE GLOVEBOX
    local vehicle = getPedOccupiedVehicle(player)
    if vehicle then
        local vehID = getElementData(vehicle, "id")
        local invTYPE = "glovebox"
        if vehID then
            local formattedInvID = invTYPE .. "_" .. vehID
            if isAltInventoryAccessible(formattedInvID) then
                setAltInventoryAccessibility(formattedInvID, false)
                local altresult = alternateInventories[formattedInvID] or {}
                local invSize = getElementData(vehicle, "glovebox") or 300
                triggerClientEvent(player, "onAltInventoryLoad", player, altresult, vehID, invTYPE, invSize)
                return
            else
                message(player, "This inventory is currently being accessed by another player", "error")
                return
            end
        end
    end

    -- CHECK AND OPEN VEHICLE TRUNK
    local x, y, z = getElementPosition(player) -- Get player's position
    local vehicles = getElementsByType("vehicle") -- Get all vehicle elements
    local nearestDist = 3 -- Set initial distance to a very high value
    local nearestVehicle = nil -- Variable to store the nearest vehicle

    for _, vehicle in ipairs(vehicles) do
        local vx, vy, vz = getElementPosition(vehicle) -- Get vehicle's position
        local distance = getDistanceBetweenPoints3D(x, y, z, vx, vy, vz) -- Calculate distance

        if distance < nearestDist then
            nearestDist = distance -- Update nearest distance
            nearestVehicle = vehicle -- Set nearest vehicle
        end
    end

    if nearestVehicle then
        local vehID = getElementData(nearestVehicle, "id")
        local invTYPE = "trunk"
        if vehID then
            local formattedInvID = invTYPE .. "_" .. vehID
            if isAltInventoryAccessible(formattedInvID) then
                if isVehicleLocked(nearestVehicle) then
                    return
                else
                    setAltInventoryAccessibility(formattedInvID, false)
                    local altresult = alternateInventories[formattedInvID] or {}
                    local invSize = getElementData(nearestVehicle, "trunk") or 1000
                    triggerClientEvent(player, "onAltInventoryLoad", player, altresult, vehID, invTYPE, invSize)
                    setVehicleDoorOpenRatio(nearestVehicle, 1, 1, 1000) -- Open driver door smoothly
                    setPedAnimation(player, "BD_FIRE", "wash_up", 1, true, true, true, true)
                    setTimer(function()
                        if isElement(nearestVehicle) then
                            setPedAnimation(player, "BD_FIRE", "wash_up", 1, false, false, false, false)
                            setVehicleDoorOpenRatio(nearestVehicle, 1, 0, 1000) -- Close door smoothly
                        end
                    end, 4000, 1) -- 5-second delay

                    return
                end
            else
                message(player, "This inventory is currently being accessed by another player", "error")
                return
            end
        end
    end

    -- CHECK AND OPEN HOUSE STORAGE
    local px, py, pz = getElementPosition(player)
    local foundHouseID = nil
    for _, col in ipairs(getElementsByType("colshape")) do
        local id = getElementData(col, "houseStorageID")
        if id then
            local cx, cy, cz = getElementPosition(col)
            local dist = getDistanceBetweenPoints3D(px, py, pz, cx, cy, cz)
            if dist <= 3 then
                foundHouseID = tonumber(id)
                break
            end
        end
    end

    if foundHouseID and houseStorages[foundHouseID] then
        local invTYPE = "house"
        local formattedInvID = invTYPE .. "_" .. tostring(foundHouseID)
        if isAltInventoryAccessible(formattedInvID) then
            setAltInventoryAccessibility(formattedInvID, false)
            local altresult = alternateInventories[formattedInvID] or {}
            local invSize = houseStorages[foundHouseID].capacity or (houseStorageDefaultCapacity or 10000)
            triggerClientEvent(player, "onAltInventoryLoad", player, altresult, foundHouseID, invTYPE, invSize)
            return
        else
            message(player, "This inventory is currently being accessed by another player", "error")
            return
        end
    end
end

-- Function to save player inventory to database
function savePlayerInventory(player)
    local account = getPlayerAccount(player)
    if isGuestAccount(account) then return end
    local accountName = getAccountName(account)
    local playerID = getElementData(player, "id")

    dbExec(db, "DELETE FROM inventory WHERE player_id = ?", playerID)

    local inventory = inventories[playerID] or {}
    for i, itemData in ipairs(inventory) do
        dbExec(db, "INSERT INTO inventory (player_id, account_name, slot, item_name, amount, weight, x, y) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            playerID, accountName, itemData.slot, itemData.item_name, itemData.amount, itemData.weight, itemData.x, itemData.y)
    end
end

-- Function to save alternate inventory to database
function saveAlternateInventory(invID)
    dbExec(db, "DELETE FROM altInventory WHERE invID = ?", invID)

    local altInventory = alternateInventories[invID] or {}
    for i, itemData in ipairs(altInventory) do
        dbExec(db, "INSERT INTO altInventory (invID, slot, item_name, amount, weight, x, y) VALUES (?, ?, ?, ?, ?, ?, ?)",
            invID, itemData.slot, itemData.item_name, itemData.amount, itemData.weight, itemData.x, itemData.y)
    end
end

-- Event handlers
addEvent("onInventoryOpen", true)
addEventHandler("onInventoryOpen", root, function()
    local player = client
    loadInventory(player)
end)

addEvent("onInventoryClose", true)
addEventHandler("onInventoryClose", root, function(clientBoxes, clientAltBoxes, altInvID)
    local player = client
    local account = getPlayerAccount(player)
    if isGuestAccount(account) then return end
    local accountName = getAccountName(account)
    local playerID = getElementData(player, "id")

    setAltInventoryAccessibility(altInvID, true)

    -- Save inventory to local table
    inventories[playerID] = {}
    for i, box in ipairs(clientBoxes) do
        inventories[playerID][i] = {
            item_name = box.name,
            amount = box.amount,
            weight = box.weight,
            x = box.x,
            y = box.y,
            slot = box.slotNum,
        }
    end

    -- Save alternate inventory to local table
    alternateInventories[altInvID] = {}
    for i, altBox in ipairs(clientAltBoxes) do
        alternateInventories[altInvID][i] = {
            item_name = altBox.name,
            amount = altBox.amount,
            weight = altBox.weight,
            x = altBox.x,
            y = altBox.y,
            slot = altBox.slotNum,
            invID = altInvID
        }
    end
end)

-- Save to database when resource stops
addEventHandler("onResourceStop", resourceRoot, function()
    outputServerLog("[ INVENTORY ] : Saved inventory to database")
    for _, player in ipairs(getElementsByType("player")) do
        savePlayerInventory(player)
    end
    for invID, _ in pairs(alternateInventories) do
        saveAlternateInventory(invID)
    end
end)

-- Save to database when resource starts

addEventHandler("onResourceStart", resourceRoot, function()
    -- Load player inventory
    local query = dbQuery(db, "SELECT * FROM inventory")
    local result = dbPoll(query, -1)
    if result then
        for i, item in ipairs(result) do
            local playerID = item.player_id
            if playerID then
                if not inventories[playerID] then
                    inventories[playerID] = {}
                end
                table.insert(inventories[playerID], {
                    item_name = item.item_name,
                    amount = item.amount,
                    weight = item.weight,
                    x = item.x,
                    y = item.y,
                    slot = item.slot
                })
            end
        end
    end

    -- Load alternate inventories
    local query = dbQuery(db, "SELECT * FROM altInventory")
    local altresult = dbPoll(query, -1)
    if altresult then
        for _, item in ipairs(altresult) do
            local invID = item.invID
            if invID then
                if not alternateInventories[invID] then
                    alternateInventories[invID] = {}
                end
                table.insert(alternateInventories[invID], {
                    item_name = item.item_name,
                    amount = item.amount,
                    weight = item.weight,
                    x = item.x,
                    y = item.y,
                    slot = item.slot
                })
            end
        end
    end

    -- Load house storage definitions
    local hsQuery = dbQuery(db, "SELECT * FROM houseStorage")
    local hsResult = dbPoll(hsQuery, -1)
    if hsResult then
        for _, row in ipairs(hsResult) do
            local id = tonumber(row.id)
            if id then
                houseStorages[id] = {
                    id = id,
                    x = tonumber(row.x),
                    y = tonumber(row.y),
                    z = tonumber(row.z),
                    interior = tonumber(row.interior) or 0,
                    dimension = tonumber(row.dimension) or 0,
                    capacity = tonumber(row.capacity) or (houseStorageDefaultCapacity or 10000),
                }

                local marker = createMarker(houseStorages[id].x, houseStorages[id].y, houseStorages[id].z - 1, "cylinder", 1.5, 0, 150, 255, 80)
                setElementInterior(marker, houseStorages[id].interior)
                setElementDimension(marker, houseStorages[id].dimension)
                local col = createColSphere(houseStorages[id].x, houseStorages[id].y, houseStorages[id].z, 2)
                setElementInterior(col, houseStorages[id].interior)
                setElementDimension(col, houseStorages[id].dimension)
                setElementData(col, "houseStorageID", id)

                addEventHandler("onMarkerHit", marker, function(hitElement)
                    if getElementType(hitElement) == "player" then
                        message(hitElement, "Press 'B' to open house storage.", "info")
                    end
                end)
            end
        end
    end

    -- Debugging message
    outputDebugString("Inventory loading complete.")
end)

-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY ADD AND REMOVE FUNCTIONALITES
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
local screenW, screenH = 1920, 1080  
local rx = screenW/1920
local ry = screenH/1080

addEvent("onServerReceiveScreenSize", true)
addEventHandler("onServerReceiveScreenSize", root, function(sx, sy)
    screenW = sx
    screenH = sy
    rx = screenW/1920
    ry = screenH/1080
end)

-------------------------------------------------------------------------------------------------------------------------------
-- Add item to inventory
function addItemToInventory(player, name, amount)
    local playerID = getElementData(player, "id")
    if not playerID then return false end

    local item = items[name]
    if not item then return false end

    -- Ensure inventory table exists for the player
    inventories[playerID] = inventories[playerID] or {}
    
    local gridSize = 5
    local slotSize = 100 / 1920 * screenW
    local startX, startY = 350 / 1920 * screenW, 200 / 1080 * screenH
    -- Get slot position
    local function getSlotPosition(slotNum)
        local row = math.floor((slotNum - 1) / gridSize)
        local col = (slotNum - 1) % gridSize
        return (startX + (col * slotSize)), startY + (row * slotSize)
    end

    -- Calculate inventory weight
    local currentWeight = 0
    for _, itemData in ipairs(inventories[playerID]) do
        currentWeight = currentWeight + (itemData.weight * itemData.amount)
    end

    local newWeight = currentWeight + (item.weight * amount)
    local maxWeight = 100

    if newWeight > maxWeight then
        message(player, "Error: Inventory exceeds max weight!", "error")
        return false
    end

    -- If item already exists, increase amount
    for _, itemData in ipairs(inventories[playerID]) do
        if itemData.item_name == name then
            itemData.amount = itemData.amount + amount
            local accountName = getAccountName(getPlayerAccount(player))
            inventoryDiscordWebhookSend("[ADDED] "..amount.." "..name.." to "..accountName)
            return true
        end
    end

    -- Find an empty slot (max = 25)
    local occupiedSlots = {}
    for _, itemData in ipairs(inventories[playerID]) do
        occupiedSlots[itemData.slot] = true
    end

    for i = 1, 25 do
        if not occupiedSlots[i] then
            local x, y = getSlotPosition(i)
            table.insert(inventories[playerID], {
                slot = i,
                item_name = name,
                amount = amount,
                weight = item.weight,
                x = x,
                y = y
            })
            local accountName = getAccountName(getPlayerAccount(player))
            inventoryDiscordWebhookSend("[ADDED] "..amount.." "..name.." to "..accountName)
            return true
        end
    end
    message(player, "Error: no free slot found", "error")
    return false
end

-- Remove item from inventory
function removeItemFromInventory(player, name, amount)
    local playerID = getElementData(player, "id")
    if not playerID then return false end

    if not inventories[playerID] then return false end

    for index, itemData in ipairs(inventories[playerID]) do
        if itemData.item_name == name then
            if itemData.amount > amount then
                itemData.amount = itemData.amount - amount
            else
                table.remove(inventories[playerID], index)
            end
            local accountName = getAccountName(getPlayerAccount(player))
            inventoryDiscordWebhookSend("[REMOVED] "..amount.." "..name.." from "..accountName)
            return true
        end
    end
    message(player, "Error: no item found", "error")
    return false
end

-- Get the amount of a specific item in the player's inventory
function getItemFromInventory(player, itemName)
    local playerID = getElementData(player, "id")
    if not playerID or not inventories[playerID] then return 0 end

    for _, itemData in ipairs(inventories[playerID]) do
        if itemData.item_name == itemName then
            return itemData.amount
        end
    end
    return 0
end

-- Remove all items from the player's inventory
function removeAllItemsFromInventory(player)
    local playerID = getElementData(player, "id")
    if not playerID then 
        message(player, "player id not found", "error")
        return false
    end

    inventories[playerID] = {} -- Clear the inventory table
    local accountName = getAccountName(getPlayerAccount(player))
    inventoryDiscordWebhookSend("[INVENTORY CLEARED !] for player " ..accountName)
    return true
end

-------------------------------------------------------------------------------------------------------------------------------
-- Server-side event handlers
addEvent("onServerAddItem", true)
addEventHandler("onServerAddItem", root, function(name, amount)
    addItemToInventory(client, name, amount)
end)

addEvent("onServerRemoveItem", true)
addEventHandler("onServerRemoveItem", root, function(name, amount)
    removeItemFromInventory(client, name, amount)
end)

-- Event to send item amount to client
addEvent("onServerRequestItemAmount", true)
addEventHandler("onServerRequestItemAmount", root, function(itemName)
    local amount = getItemFromInventory(client, itemName)
end)

-- Event to remove all items from the inventory
addEvent("onServerRequestRemoveAllItems", true)
addEventHandler("onServerRequestRemoveAllItems", root, function()
    removeAllItemsFromInventory(client)
end)


-------------------------------------------------------------------------------------------------------------------------------
-- Function to give an item to a player
function giveItem(player, itemName, amount)
    if not isElement(player) or not itemName or not amount then return false end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end

    triggerClientEvent(player, "onClientAddItem", player, itemName, amount)
    return addItemToInventory(player, itemName, amount)
end

-- Function to take an item from a player
function takeItem(player, itemName, amount)
    if not isElement(player) or not itemName or not amount then return false end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end
    triggerClientEvent(player, "onClientRemoveItem", player, itemName, amount)
    return removeItemFromInventory(player, itemName, amount)
end

-- Function to get the amount of a specific item from a player
function getItem(player, itemName)
    if not isElement(player) or not itemName then return false end

    local amount = getItemFromInventory(player, itemName)

    return getItemFromInventory(player, itemName)
end

-- Function to remove all items from a player's inventory
function clearInventory(player)
    if not isElement(player) then return false end

    triggerClientEvent(player, "onClientRemoveAllItems", player)
    return true
end

-------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY SEE (VIEW OTHER PLAYER'S INVENTORY VIA ALTERNATE INVENTORY UI)
-------------------------------------------------------------------------------------------------------------------------------

local function canUseInventorySee(player)
	if not isElement(player) then return false end
	local account = getPlayerAccount(player)
	if not account or isGuestAccount(account) then return false end
	local name = getAccountName(account)
	if not name then return false end
	if type(inventorySeeACLGroups) ~= "table" then return false end
	for _, groupName in ipairs(inventorySeeACLGroups) do
		local group = aclGetGroup(groupName)
		if group and isObjectInACLGroup("user." .. name, group) then
			return true
		end
	end
	return false
end

function inventorySee(viewer, target)
	if not isElement(viewer) or getElementType(viewer) ~= "player" then return false end
	if not isElement(target) or getElementType(target) ~= "player" then return false end
	if not canUseInventorySee(viewer) then
		message(viewer, "You don't have permission to use inventory view.", "error")
		return false
	end

	local viewerID = getElementData(viewer, "id")
	local targetID = getElementData(target, "id")
	if not viewerID or not targetID then
		message(viewer, "Player ID not found.", "error")
		return false
	end

	local viewerInv = inventories[viewerID] or {}
	local targetInv = inventories[targetID] or {}

	local altID = "view_" .. tostring(targetID)
	if not isAltInventoryAccessible(altID) then
		message(viewer, "This inventory is currently being accessed by another player", "error")
		return false
	end

	setAltInventoryAccessibility(altID, false)

	local altData = {}
	for _, item in ipairs(targetInv) do
		table.insert(altData, {
			item_name = item.item_name,
			amount = item.amount,
			weight = item.weight,
			x = item.x,
			y = item.y,
			slot = item.slot,
			invID = altID,
		})
	end

	alternateInventories[altID] = altData

	-- open viewer's own inventory on the left
	triggerClientEvent(viewer, "onInventoryLoad", viewer, viewerInv)
	-- set the right inventory name to target player's name
	local targetName = getPlayerName(target) or "Player Inventory"
	triggerClientEvent(viewer, "setInventoryViewName", viewer, targetName)
	-- open alternate inventory on the right using existing alt inventory logic
	triggerClientEvent(viewer, "onAltInventoryLoad", viewer, altData, targetID, "view", 1000)
	-- ensure cursor is visible for this custom open path
	triggerClientEvent(viewer, "inventoryViewCursor", viewer)

	return true
end

--------------------------------------
-- Command Handlers (For Testing)
--------------------------------------

-- Command to give an item and take item
addCommandHandler("giveitem", function(player, command, itemName, amount)
    amount = tonumber(amount) or 1 -- Default to 1 if amount is nil or invalid
    if not giveItem(player, itemName, amount) then
        message(player, "Function returned false", "error")
    end
end)

addCommandHandler("takeitem", function(player, command, itemName, amount)
    amount = tonumber(amount) or 1 -- Default to 1 if amount is nil or invalid
    if not takeItem(player, itemName, amount) then
        message(player, "Function returned false", "error")
    end
end)


-- Command to get item amount (/getitem [itemName])
addCommandHandler("getitem", function(player, command, itemName)
    if not getItem(player, itemName) then
        message(player, "Function returned false", "error")
    end
end)

-- Command to remove all items (/removeallitems)
addCommandHandler("removeallitems", function(player, command)
    if not clearInventory(player) then
        message(player, "Function returned false", "error")
    else
        message(player, "All items removed from your inventory!", "warn")
    end
end)

-- Command to view another player's inventory (/invsee [accountName])
addCommandHandler("invsee", function(player, command, accountName)
    if not accountName or accountName == "" then
        message(player, "Usage: /invsee [accountName]", "warn")
        return
    end

    if not inventorySee then
        message(player, "inventorySee function is not available.", "error")
        return
    end

    local target = nil
    for _, p in ipairs(getElementsByType("player")) do
        local acc = getPlayerAccount(p)
        if acc and not isGuestAccount(acc) and getAccountName(acc) == accountName then
            target = p
            break
        end
    end

    if not isElement(target) then
        message(player, "Player with that account not found.", "error")
        return
    end

    if not inventorySee(player, target) then
        -- inventorySee already sends a reason message (permission, etc.)
        return
    end
end)

-------------------------------------------------------------------------------------------------------------------------------
-- HOUSE STORAGE ADMIN COMMAND
-------------------------------------------------------------------------------------------------------------------------------

local function canCreateHouseStorage(player)
    if type(houseStorageACLGroups) ~= "table" then return false end
    local acc = getPlayerAccount(player)
    if not acc or isGuestAccount(acc) then return false end
    local name = getAccountName(acc)
    if not name then return false end
    for _, groupName in ipairs(houseStorageACLGroups) do
        local group = aclGetGroup(groupName)
        if group and isObjectInACLGroup("user." .. name, group) then
            return true
        end
    end
    return false
end

-- /hstorage [capacity] - create a house storage marker at current position
addCommandHandler("hstorage", function(player, cmd, capacity)
    if not canCreateHouseStorage(player) then
        message(player, "You don't have permission to create house storage.", "error")
        return
    end

    local cap = tonumber(capacity) or (houseStorageDefaultCapacity or 10000)
    local x, y, z = getElementPosition(player)
    local interior = getElementInterior(player)
    local dimension = getElementDimension(player)

    dbExec(db, "INSERT INTO houseStorage (x, y, z, interior, dimension, capacity) VALUES (?, ?, ?, ?, ?, ?)", x, y, z, interior, dimension, cap)
    local q = dbQuery(db, "SELECT last_insert_rowid() AS id")
    local r = dbPoll(q, -1)
    local id = r and r[1] and tonumber(r[1].id) or nil
    if not id then
        message(player, "Failed to create house storage.", "error")
        return
    end

    houseStorages[id] = {
        id = id,
        x = x,
        y = y,
        z = z,
        interior = interior,
        dimension = dimension,
        capacity = cap,
    }

    local marker = createMarker(x, y, z - 1, "cylinder", 1.5, 0, 150, 255, 80)
    setElementInterior(marker, interior)
    setElementDimension(marker, dimension)
    local col = createColSphere(x, y, z, 2)
    setElementInterior(col, interior)
    setElementDimension(col, dimension)
    setElementData(col, "houseStorageID", id)

    addEventHandler("onMarkerHit", marker, function(hitElement)
        if getElementType(hitElement) == "player" then
            message(hitElement, "Press 'B' to open house storage.", "info")
        end
    end)

    message(player, "House storage created with ID " .. id .. " and capacity " .. cap .. ".", "success")
end)

-- /delhstorage [id] - delete an existing house storage
addCommandHandler("delhstorage", function(player, cmd, idStr)
	if not canCreateHouseStorage(player) then
		message(player, "You don't have permission to delete house storage.", "error")
		return
	end

	local id = tonumber(idStr)
	if not id then
		message(player, "Usage: /delhstorage [id]", "warn")
		return
	end

	if not houseStorages[id] then
		message(player, "House storage ID not found.", "error")
		return
	end

	-- remove definition from DB
	dbExec(db, "DELETE FROM houseStorage WHERE id = ?", id)

	-- clear its stored items from altInventory table and runtime table
	local invID = "house_" .. tostring(id)
	alternateInventories[invID] = nil
	dbExec(db, "DELETE FROM altInventory WHERE invID = ?", invID)

	-- destroy colshapes and markers associated with this house storage ID
	for _, col in ipairs(getElementsByType("colshape")) do
		if getElementData(col, "houseStorageID") == id then
			local cx, cy, cz = getElementPosition(col)
			local dim = getElementDimension(col)
			local int = getElementInterior(col)
			destroyElement(col)
			for _, marker in ipairs(getElementsByType("marker")) do
				if getElementDimension(marker) == dim and getElementInterior(marker) == int then
					local mx, my, mz = getElementPosition(marker)
					if getDistanceBetweenPoints3D(cx, cy, cz, mx, my, mz) < 2.1 then
						destroyElement(marker)
					end
				end
			end
		end
	end

	houseStorages[id] = nil
	message(player, "House storage ID " .. id .. " has been deleted.", "success")
end)

----------------------------------------------------------------
--WEBHOOKS
----------------------------------------------------------------

local inventoryWebhookURL = "https://discord.com/api/webhooks/1354881258991390760/tfgR--JtaeU1u_7TE9JKDnln4g0x4EdKI9kbpuAtYfkK3kOLlQr6ei4Pm8DSRF8it34b"

function inventoryDiscordWebhookSend(message)
    -- ... (rest of the code remains the same)
    local time = getRealTime()
    local timestamp = string.format("[%02d-%02d-%04d %02d:%02d:%02d]", 
        time.monthday, time.month + 1, time.year + 1900, 
        time.hour, time.minute, time.second)

    -- Append timestamp to message
    local finalMessage = timestamp .. " " .. message

    -- Send to Discord Webhook
    local sendOptions = {
        formFields = {
            content = "```" .. finalMessage .. "```"
        },
    }
    fetchRemote(inventoryWebhookURL, sendOptions, WebhookCallback)

    -- Save to inventoryLogs.txt file with error handling
    local logFile = fileOpen("logs/inventoryLogs.txt") or fileCreate("logs/inventoryLogs.txt") -- Open or create file
    if not logFile then
        outputDebugString("[ERROR] Failed to open or create inventoryLogs.txt", 1) -- Output an error
        return
    end

    fileSetPos(logFile, fileGetSize(logFile)) -- Move to end of file
    fileWrite(logFile, finalMessage .. "\n") -- Write message with timestamp
    fileFlush(logFile) -- Save changes
    fileClose(logFile) -- Close file
end


-- 2 arguments (responseData gives back the response or "ERROR" )
function WebhookCallback(responseData) 
    return
end

addEvent("sendInventoryWebhook", true) -- Create event
addEventHandler("sendInventoryWebhook", root, function(message, player)
    if source and type(message) == "string" then
        local accountName = getAccountName(getPlayerAccount(player))
        local finalMessage = message .. " " .. accountName
        inventoryDiscordWebhookSend(finalMessage)
    end
end)