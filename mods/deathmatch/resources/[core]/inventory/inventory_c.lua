-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
-- GUI PROPERTIES AND CALCULATIONS
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------

-- Grid properties
local screenW, screenH = guiGetScreenSize()
--send screen resolution
triggerServerEvent("onServerReceiveScreenSize", resourceRoot, screenW, screenH)
local rx = screenW/1920
local ry = screenH/1080

local gridSize = 5
local slotSize = 100/1920 * screenW
local startX, startY = 350/1920 * screenW, 200/1080 * screenH

local SlotgapX = 5/1920 * screenW
local SlotgapY = 5/1080 * screenH
--main slot
local slots = {}

--alt slot
local altSlots = {}

-- List of boxes
local boxes = {}

-- Alt boxes
local altBoxes = {}

local altSlotsOpened = false

--ALT INV ID
local altID = "type_id"

-- name shown for generic view inventories (e.g. other players)
local viewInventoryName = "Player Inventory"

-- name for house storage inventory (will include unique ID)
local houseStorageName = "House Storage"

-- Inventory properties
local maxWeight = 100 -- Maximum weight capacity

local altMaxWeight = 1000

local currentWeight = 0 -- Current weight of the inventory

local altCurrentWeight = 0 -- current weight of the alternate inventory
    
-- Initialize the grid slots
for i = 0, gridSize - 1 do
    for j = 0, gridSize - 1 do
        local x = (startX + (j * slotSize))
        local y = startY + (i * slotSize)
        table.insert(slots, {x = x, y = y, occupied = false})
    end
end

-- Initialize the grid altslots
for i = 0, gridSize - 1 do
    for j = 0, gridSize - 1 do
        local x = startX + (j * slotSize) + (slotSize * 7)
        local y = startY + (i * slotSize)
        table.insert(altSlots, {x = x, y = y, occupied = false})
    end
end


-- Use box properties
local useBoxX, useBoxY, useBoxWidth, useBoxHeight = startX +  (slotSize * 5.5 ), startY, slotSize, slotSize

local inventoryOpened = false
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
-- ITEMS ADD TO TABLE | | Function to add a new box or increase amount in the existing box
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------

-- Add item to inventory locally
function addItemToInventory(name, amount)
    local item = items[name]
    if inventoryOpened then
        local newWeight = currentWeight + (item.weight * amount)
        if newWeight > maxWeight then
            message("Error: Inventory exceeds max weight!", "info")
            return
        end

        for _, box in ipairs(boxes) do
            if box.name == name then
                box.amount = box.amount + amount
                currentWeight = newWeight
                return
            end
        end

        for i, slot in ipairs(slots) do
            if not slot.occupied then
                table.insert(boxes, {
                    x = slot.x,
                    y = slot.y,
                    size = slotSize,
                    name = item.name,
                    weight = item.weight,
                    image = item.image,
                    dragging = false,
                    offsetX = 0,
                    offsetY = 0,
                    slot = slot,
                    slotNum = i,
                    amount = amount,
                    originalX = slot.x,
                    originalY = slot.y
                })
                slot.occupied = true
                currentWeight = newWeight
                return
            end
        end
    end
end


-- Remove item from inventory locally
function removeItemFromInventory(name, amount)
    local item = items[name]
    if not item then 
        message("Error: Item not found!", "info")
        return 
    end

    if inventoryOpened then
        local newWeight = currentWeight - (item.weight * amount)
        for index, box in ipairs(boxes) do
            if box.name == name then
                if box.amount > amount then
                    box.amount = box.amount - amount
                    currentWeight = newWeight
                else
                    table.remove(boxes, index)
                    currentWeight = newWeight
                end
            return
            end
        end
    end
end

-- Request item amount from server
function getItemAmount(itemName)
    if inventoryOpened then
        inventoryOpen()
        triggerServerEvent("onServerRequestItemAmount", resourceRoot, itemName)
        inventoryOpen()
    end
end

-- Request to remove all items from inventory
function removeAllBox()
    if inventoryOpened then
        inventoryOpen()
        triggerServerEvent("onServerRequestRemoveAllItems", resourceRoot, itemName)
        inventoryOpen()
        return
    else
        triggerServerEvent("onServerRequestRemoveAllItems", resourceRoot, itemName)
    end
end


-- Client-side event handlers
addEvent("onClientAddItem", true)
addEventHandler("onClientAddItem", root, function(name, amount)
    addItemToInventory(name, amount)
end)

-- helper events for inventory see feature
addEvent("setInventoryViewName", true)
addEventHandler("setInventoryViewName", root, function(targetName)
    if type(targetName) == "string" and targetName ~= "" then
        viewInventoryName = targetName
    else
        viewInventoryName = "Player Inventory"
    end
end)

addEvent("inventoryViewCursor", true)
addEventHandler("inventoryViewCursor", root, function()
    showCursor(true)
end)
addEvent("onClientRemoveItem", true)
addEventHandler("onClientRemoveItem", root, function(name, amount)
    removeItemFromInventory(name, amount)
end)
addEvent("onClientRemoveAllItems", true)
addEventHandler("onClientRemoveAllItems", root, function(name, amount)
    removeAllBox()
end)
addEvent("onClientGetItem", true)
addEventHandler("onClientGetItem", root, function(name)
    getItemAmount(name)
end)

-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--OPEN THEE INVENTORY FUNTION
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
local MainResolutionSet = false
local AltResolutionSet = false

function DrawInventory()
    -- Draw the inventory weight
    dxDrawText("    Inventory (".. currentWeight .. "kg/" .. maxWeight .. "kg)", (startX + slotSize*1.40), startY - (35/1080 * screenH), startX + (gridSize * slotSize), startY - (10/1080 * screenH), tocolor(255, 255, 255, 255), 1.3*rx, "default-bold", "left", "top")
    
    --DRAWING GREEN BAR LOGIC
    local maxWidth = 495/1920 * screenW
    local Currentwidth
    if currentWeight >= maxWeight then
        width = maxWidth
    else
        widthReduction = maxWidth * (1 - currentWeight / maxWeight)
        width = maxWidth - widthReduction
    end

    dxDrawRectangle(startX, useBoxY - 7, width , 3, tocolor(0, 200, 0, 200))

    -- Draw the give box
    dxDrawRectangle(useBoxX, useBoxY, useBoxWidth -SlotgapX, useBoxHeight - SlotgapY, tocolor(0, 0, 0, 100))
    dxDrawText("Give", useBoxX, useBoxY, useBoxX + useBoxWidth -SlotgapX, useBoxY + useBoxHeight -SlotgapY, tocolor(255, 255, 255, 255), 1 *rx, "default-bold", "center", "center")

    -- Draw the use box
    dxDrawRectangle(useBoxX, useBoxY + useBoxHeight, useBoxWidth -SlotgapX, useBoxHeight - SlotgapY, tocolor(0, 0, 0, 100))
    dxDrawText("Use", useBoxX, useBoxY + (useBoxHeight * 2) , useBoxX + useBoxWidth -SlotgapX, useBoxY + useBoxHeight -SlotgapY, tocolor(255, 255, 255, 255), 1 * rx, "default-bold", "center", "center")

    -- Draw the drop box
    dxDrawRectangle(useBoxX, useBoxY + (useBoxHeight * 2), useBoxWidth -SlotgapX, useBoxHeight - SlotgapY, tocolor(0, 0, 0, 100))
    dxDrawText("Drop", useBoxX, useBoxY + (useBoxHeight * 4), useBoxX + useBoxWidth -SlotgapX, useBoxY + useBoxHeight -SlotgapY, tocolor(255, 255, 255, 255), 1 * rx, "default-bold", "center", "center")

    -- Draw the quantity edit box
    dxDrawRectangle(useBoxX, useBoxY + (useBoxHeight*3), useBoxWidth -SlotgapX, useBoxHeight - SlotgapY, tocolor(0, 0, 0, 100))
    dxDrawText("Quantity", useBoxX, useBoxY + (useBoxHeight*6), useBoxX + useBoxWidth, useBoxY + useBoxHeight + 40/1080 * screenH, tocolor(255, 255, 255, 255), 1 * rx, "default-bold", "center", "center")

    -- Draw grid slots for player inventory
    for _, Playerslot in ipairs(slots) do
        dxDrawRectangle(Playerslot.x, Playerslot.y, slotSize -SlotgapX, slotSize -SlotgapY , tocolor(0, 0, 0, 80))
    end

    -- [ITEMS] Draw boxes with images, amount and text in the center
    local imageSize = 50 * rx

    for _, box in ipairs(boxes) do
        dxDrawRectangle(box.x, box.y, box.size -SlotgapX , box.size -SlotgapY, tocolor(0, 0, 0, 50))
        dxDrawImage(box.x + (slotSize - imageSize) / 2, box.y + (slotSize - imageSize) / 2, imageSize, imageSize, box.image)
        dxDrawText(box.name .. " - " .. box.weight .. "kg", box.x, box.y + box.size - (25/1080 * screenH), box.x + box.size, box.y + box.size, tocolor(255, 255, 255, 255), 1 *rx, "default", "center", "center")
        dxDrawText(box.amount .. "x", box.x, box.y, box.x + box.size, box.y + (20/1080 * screenH), tocolor(255, 255, 255, 255), 1 *rx, "default", "center", "center")
    end
        
end

--DRAW ALTERNATE INVENTORY

function DrawAltInventory(invname, totalCapacity)

    altSlotsOpened = true

    altMaxWeight = totalCapacity
    -- Draw the inventory weight
    dxDrawText("       "..invname .." (".. altCurrentWeight .. "kg/" .. totalCapacity .. "kg)",(startX + slotSize*1.35) + (slotSize * 7), startY - (30/1080*screenH), startX + (gridSize * slotSize), startY - (10/1080*screenH), tocolor(255, 255, 255, 255), 1.3 *rx, "default-bold", "left", "top")
    
    local maxWidth = 495/1920 * screenW
    local Currentwidth
    if altCurrentWeight >= totalCapacity then
        width = maxWidth
    else
        widthReduction = maxWidth * (1 - altCurrentWeight / totalCapacity)
        width = maxWidth - widthReduction
    end

    dxDrawRectangle(startX + (slotSize * 7), useBoxY - 7, width , 3, tocolor(0, 200, 0, 200))

    -- Draw grid slots for ALTERNATE inventory
    for _, altSlot in ipairs(altSlots) do
        dxDrawRectangle(altSlot.x, altSlot.y, slotSize -SlotgapX, slotSize -SlotgapY , tocolor(0, 0, 0, 80))
    end

    -- [ITEMS] Draw boxes with images, amount and text in the center
    local imageSize = 50 * rx
    for _, box in ipairs(altBoxes) do
        dxDrawRectangle(box.x, box.y, box.size - SlotgapX, box.size -5, tocolor(0, 0, 0, 50))
        dxDrawImage(box.x + (slotSize - imageSize) / 2, box.y + (slotSize - imageSize) / 2, imageSize, imageSize, box.image)
        dxDrawText(box.name .. " - " .. box.weight .. "kg", box.x, box.y + box.size - 25, box.x + box.size, box.y + box.size, tocolor(255, 255, 255, 255), 1 * rx, "default", "center", "center")
        dxDrawText(box.amount .. "x", box.x, box.y, box.x + box.size, box.y + 20, tocolor(255, 255, 255, 255), 1 * rx, "default", "center", "center")
    end

end
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
-- OPEN INVENTORY FUNCTION
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------

local quantityEditBox = nil
local inventorySize = nil
-----------------------------------------------------------------------------------------

local drawTrunkHandler = function()
    DrawAltInventory("Trunk", inventorySize)
end

local drawGlowboxHandler = function()
    DrawAltInventory("Glove Box", inventorySize)
end

local drawHouseStorageHandler = function()
    DrawAltInventory(houseStorageName, inventorySize or altMaxWeight)
end

local drawViewInventoryHandler = function()
    DrawAltInventory(viewInventoryName, inventorySize or altMaxWeight)
end

-----------------------------------------------------------------------------------------
function inventoryOpen()
    if inventoryOpened then
        showCursor(false)
        --UPDATING SERVER TABLE
        triggerServerEvent("onInventoryClose", resourceRoot, boxes, altBoxes, altID)

        if isElement(quantityEditBox) then
            destroyElement(quantityEditBox)
            quantityEditBox = nil
        end
        removeEventHandler("onClientRender", root, DrawInventory)
        removeEventHandler("onClientRender", root, drawTrunkHandler)
        removeEventHandler("onClientRender", root, drawGlowboxHandler)
        removeEventHandler("onClientRender", root, drawHouseStorageHandler)
        removeEventHandler("onClientRender", root, drawViewInventoryHandler)

        altSlotsOpened = false

        for _, slot in ipairs(slots) do
            slot.occupied = false
        end

        for _, slot in ipairs(altSlots) do
            slot.occupied = false
        end

        inventoryOpened = false
    else
        showCursor(true)
        -- Create an edit box for the quantity
        MainResolutionSet = false
        AltResolutionSet = false
        
        triggerServerEvent("onInventoryOpen", resourceRoot)
    end
end

--LOAD INVENTORY
addEvent("onInventoryLoad", true)
addEventHandler("onInventoryLoad", root, function(inventoryData)
    boxes = {}
    currentWeight = 0
    for i, item in ipairs(inventoryData) do
        local itemWeight = item.weight * item.amount
        currentWeight = currentWeight + itemWeight
        table.insert(boxes, {
            x = item.x,
            y = item.y,
            size = slotSize,
            name = item.item_name,
            weight = item.weight,
            image = items[item.item_name].image,
            dragging = false,
            offsetX = 0,
            offsetY = 0,
            slot = slots[item.slot],
            slotNum = item.slot,
            amount = item.amount,
            originalX = item.x,
            originalY = item.y
        })
        slots[item.slot].occupied = true
    end
    --FUNCTION TO OPEN PLAYER INVENTORY
    quantityEditBox = guiCreateEdit(useBoxX + (10/1920 * screenW), (useBoxY) + (useBoxHeight * 3) + SlotgapY *3, useBoxWidth - (25/1920 * screenW), 30/1080 * screenH, "1", false)

    -- Function to filter input
    function filterPositiveNumbers()
        local text = guiGetText(quantityEditBox)
        local filteredText = text:gsub("[^0-9]", "")  -- Remove any non-digit characters
    
        -- Ensure the text starts with a positive number if not empty
        if filteredText ~= "" and not filteredText:match("^[1-9]%d*$") then
            filteredText = filteredText:match("^[1-9]%d*")
        end
    
        guiSetText(quantityEditBox, filteredText or "")
    end
    
    if not MainResolutionSet then 
        MainResolutionSet = true
        for i, box in ipairs(boxes) do
            box.x = slots[box.slotNum].x
            box.y = slots[box.slotNum].y
            box.size = slotSize
        end
        triggerServerEvent("onInventoryClose", resourceRoot, boxes, altBoxes, altID)
    end

    -- Add event handler to the edit box
    addEventHandler("onClientGUIChanged", quantityEditBox, filterPositiveNumbers)
    
    
    -- Function to render the grid, boxes, and the use box
    addEventHandler("onClientRender", root, DrawInventory)
    inventoryOpened = true
end)


--LOAD ALTERNATE INVENTORY
addEvent("onAltInventoryLoad", true)
addEventHandler("onAltInventoryLoad", root, function(altInventoryData, vehID, invTYPE, invSize)
    
    altBoxes = {}
    altCurrentWeight = 0

    altID = invTYPE .. "_" .. vehID
    
    for _, item in ipairs(altInventoryData) do
        local itemWeight = item.weight * item.amount
        altCurrentWeight = altCurrentWeight + itemWeight
        table.insert(altBoxes, {
            x = item.x,
            y = item.y,
            size = slotSize,
            name = item.item_name,
            weight = item.weight,
            image = items[item.item_name].image,
            dragging = false,
            offsetX = 0,
            offsetY = 0,
            slot = slots[item.slot],
            slotNum = item.slot,
            amount = item.amount,
            originalX = item.x,
            originalY = item.y,
            id = item.invID
        })
        altSlots[item.slot].occupied = true
    end

    if not AltResolutionSet then 
        AltResolutionSet = true
        for j, altbox in ipairs(altBoxes) do
            altbox.x = altSlots[altbox.slotNum].x
            altbox.y = altSlots[altbox.slotNum].y
            altbox.size = slotSize
        end
        triggerServerEvent("onInventoryClose", resourceRoot, boxes, altBoxes, altID)
    end
    inventorySize = tonumber(invSize)
	-- set names for specific inventory types
	if invTYPE == "house" then
		local idText = tostring(vehID or "?")
		houseStorageName = "House Storage ID " .. idText
	end

    -- Add the event handler for onClientRender
    if invTYPE == "glovebox" then
        addEventHandler("onClientRender", root, drawGlowboxHandler)
    elseif invTYPE == "trunk" then
        addEventHandler("onClientRender", root, drawTrunkHandler)
    elseif invTYPE == "view" then
        addEventHandler("onClientRender", root, drawViewInventoryHandler)
	elseif invTYPE == "house" then
		addEventHandler("onClientRender", root, drawHouseStorageHandler)
    else    
        return 
    end    
end)



-- Add key binding for inventory
function toggleInventory()
    if isChatBoxInputActive() then
        return 
    end
    if not getElementData(localPlayer, "playerFallen") then -- Don't open inventory if player is knocked
        inventoryOpen()
    end
end

-- Bind the 'b' key when resource starts
addEventHandler("onClientResourceStart", resourceRoot, function()
    bindKey("b", "down", toggleInventory)
end)

-- Unbind when resource stops
addEventHandler("onClientResourceStop", resourceRoot, function()
    unbindKey("b", "down", toggleInventory)
end)

-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
-- Function to handle mouse clicks for dragging and dropping the boxes and using the use box
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------


-- Event handler for clicking
addEventHandler("onClientClick", root, function(button, state, absX, absY)
    if button == "left" then
        if state == "down" then
            -- Check if any box is clicked
            for _, box in ipairs(boxes) do
                if absX >= box.x and absX <= box.x + box.size and absY >= box.y and absY <= box.y + box.size then
                    box.dragging = true
                    box.offsetX = absX - box.x
                    box.offsetY = absY - box.y
                end
            end

            for _, box in ipairs(altBoxes) do
                if absX >= box.x and absX <= box.x + box.size and absY >= box.y and absY <= box.y + box.size then
                    box.dragging = true
                    box.offsetX = absX - box.x
                    box.offsetY = absY - box.y
                end
            end

        elseif state == "up" then
            for j, box in ipairs(boxes) do
                if box.dragging then
                    box.dragging = false
                    local snapped = false
                    
                    -- Snap to nearest slot
                    for i, slot in ipairs(slots) do
                        if absX >= slot.x and absX <= slot.x + slotSize and absY >= slot.y and absY <= slot.y + slotSize then
                            if not slot.occupied then
                                box.slot.occupied = false
                                -- make the previous slot free
                                if box.slotNum then
                                    slots[box.slotNum].occupied = false
                                end
                                box.originalX = slot.x
                                box.originalY = slot.y
                                box.x = slot.x
                                box.y = slot.y
                                box.slot = slot
                                box.slotNum = i
                                slot.occupied = true
                                snapped = true
                                
                            end
                        end
                    end

                    -- Check if the box is dropped in the give box
                    if not snapped and absX >= useBoxX and absX <= useBoxX + useBoxWidth and absY >= useBoxY and absY <= useBoxY + useBoxHeight then
                        local quantity = tonumber(guiGetText(quantityEditBox)) or 1
                        quantity = math.min(quantity, box.amount)
                        --event to give the box to the player
                        triggerServerEvent("onPlayerGiveItem", resourceRoot, box.name, quantity) 
                    end

                    -- Check if the box is dropped in the use box
                    if not snapped and absX >= useBoxX and absX <= useBoxX + useBoxWidth and absY >= useBoxY + useBoxHeight and absY <= useBoxY + useBoxHeight + useBoxHeight then
                        --event to use the box to the player
                        triggerServerEvent("onPlayerUseItem", resourceRoot, box.name) 
                    end

                    -- Check if the box is dropped in the drop box
                    if not snapped and absX >= useBoxX and absX <= useBoxX + useBoxWidth and absY >=  useBoxY + (useBoxHeight * 2) and absY <=  useBoxY + (useBoxHeight * 2) + useBoxHeight then
                        local quantity = tonumber(guiGetText(quantityEditBox)) or 1
                        quantity = math.min(quantity, box.amount)
                        triggerServerEvent("onPlayerDropItem", resourceRoot, box.name, quantity)
                    end

                    -- Snap to alternate slot
                    if not snapped and altSlotsOpened then
                        for i, altSlot in ipairs(altSlots) do
                            if absX >= altSlot.x and absX <= altSlot.x + slotSize and absY >= altSlot.y and absY <= altSlot.y + slotSize then
                                local quantity = tonumber(guiGetText(quantityEditBox)) or 1
                                quantity = math.min(quantity, box.amount)
                                local itemWeight = box.weight * quantity
                                newAltWeight = altCurrentWeight + itemWeight

                                if newAltWeight > altMaxWeight then
                                    message("Error: Inventory exceeds maximum weight capacity!", "info")
                                    box.x = box.slot.x
                                    box.y = box.slot.y
                                    snapped = true
                                end

                                local foundAltBox = false
                                for _, altBox in ipairs(altBoxes) do
                                    if altBox.name == box.name then
                                        foundAltBox = true
                                        altBox.amount = altBox.amount + quantity
                                        box.amount = box.amount - quantity
                                        if box.amount <= 0 then
                                            box.slot.occupied = false
                                            -- make the previous slot free
                                            if box.slotNum then
                                                slots[box.slotNum].occupied = false
                                            end
                                            table.remove(boxes, j)
                                        else
                                            box.x = box.originalX
                                            box.y = box.originalY
                                        end
                                        altCurrentWeight = newAltWeight
                                        currentWeight = currentWeight - (box.weight * quantity)
                                        sendInventoryMessage("MOVED "..quantity.. " "..box.name.." to inventory ID: ".. altID .." From player's inventory with account: ")
                                        snapped = true
                                        
                                        
                                    end
                                end

                                if not foundAltBox then
                                    if not altSlot.occupied then
                                        table.insert(altBoxes, {
                                            x = altSlot.x,
                                            y = altSlot.y,
                                            size = slotSize,
                                            name = box.name,
                                            weight = box.weight,
                                            image = box.image,
                                            dragging = false,
                                            offsetX = 0,
                                            offsetY = 0,
                                            slot = altSlot,
                                            slotNum = i,
                                            amount = quantity,
                                            originalX = altSlot.x,
                                            originalY = altSlot.y
                                        })
                                        altSlot.occupied = true
                                        box.amount = box.amount - quantity
                                        if box.amount <= 0 then
                                            box.slot.occupied = false
                                            -- make the previous slot free
                                            if box.slotNum then
                                                slots[box.slotNum].occupied = false
                                            end
                                            table.remove(boxes, j)
                                        else
                                            box.x = box.originalX
                                            box.y = box.originalY
                                        end
                                        altCurrentWeight = newAltWeight
                                        currentWeight = currentWeight - (box.weight * quantity)
                                        sendInventoryMessage("MOVED "..quantity.. " "..box.name.." to inventory ID: ".. altID .." From player's inventory with account: ")
                                        
                                    else
                                        message("[ERROR] : slot is occupied.", "info")
                                        box.x = box.originalX
                                        box.y = box.originalY
                                        snapped = true
                                        
                                    end
                                end
                                
                                snapped = true
                                
                            end
                        end
                    end

                    if not snapped then
                        box.x = box.slot.x
                        box.y = box.slot.y
                    end
                    triggerServerEvent("onInventoryClose", resourceRoot, boxes, altBoxes, altID)
                end
            end
            for j, box in ipairs(altBoxes) do
                if box.dragging then
                    box.dragging = false
                    local snapped = false

                    -- Snap to nearest slot in altSlots
                    for j, slot in ipairs(altSlots) do
                        if absX >= slot.x and absX <= slot.x + slotSize and absY >= slot.y and absY <= slot.y + slotSize then
                            if not slot.occupied then
                                -- make the previous slot free
                                if box.slotNum then
                                    altSlots[box.slotNum].occupied = false
                                end
                                box.slot.occupied = false
                                box.originalX = slot.x
                                box.originalY = slot.y
                                box.x = slot.x
                                box.y = slot.y
                                box.slot = slot
                                box.slotNum = j
                                slot.occupied = true
                                snapped = true
                                
                                triggerServerEvent("onInventoryClose", resourceRoot, boxes, altBoxes, altID)
                            end
                        end
                    end

                    -- snap to main inventory slot
                    if not snapped then
                        for i, slot in ipairs(slots) do
                            if absX >= slot.x and absX <= slot.x + slotSize and absY >= slot.y and absY <= slot.y + slotSize then
                                local quantity = tonumber(guiGetText(quantityEditBox)) or 1
                                quantity = math.min(quantity, box.amount)
                                local itemWeight = box.weight * quantity
                                newWeight = currentWeight + itemWeight

                                if newWeight > maxWeight then
                                    message("Error: Inventory exceeds maximum weight capacity!", "info")
                                    box.x = box.slot.x
                                    box.y = box.slot.y
                                    snapped = true
                                    
                                end

                                local foundBox = false
                                for k, mainBox in ipairs(boxes) do
                                    if mainBox.name == box.name then
                                        mainBox.amount = mainBox.amount + quantity
                                        foundBox = true
                                        box.amount = box.amount - quantity
                                        if box.amount <= 0 then
                                            box.slot.occupied = false 
                                            -- make the previous slot free
                                            if box.slotNum then
                                                altSlots[box.slotNum].occupied = false
                                            end
                                            table.remove(altBoxes, j)
                                        else
                                            box.x = box.originalX
                                            box.y = box.originalY
                                        end
                                        altCurrentWeight = altCurrentWeight - (box.weight * quantity)
                                        currentWeight = newWeight
                                        sendInventoryMessage("MOVED "..quantity.. " "..box.name.." from inventory with ID: "..altID.." to Player's inventory account: ")
                                        snapped = true

                                    end
                                end

                                if not foundBox then
                                    if not slot.occupied then
                                        table.insert(boxes, {
                                            x = slot.x,
                                            y = slot.y,
                                            size = slotSize,
                                            name = box.name,
                                            weight = box.weight,
                                            image = box.image,
                                            dragging = false,
                                            offsetX = 0,
                                            offsetY = 0,
                                            slot = slot,
                                            slotNum = i,
                                            amount = quantity,
                                            originalX = slot.x,
                                            originalY = slot.y
                                        })
                                        slot.occupied = true
                                        box.amount = box.amount - quantity
                                        if box.amount <= 0 then
                                            box.slot.occupied = false
                                            table.remove(altBoxes, j)
                                        else
                                            box.x = box.originalX
                                            box.y = box.originalY
                                        end
                                        altCurrentWeight = altCurrentWeight - (box.weight * quantity)
                                        currentWeight = newWeight
                                        sendInventoryMessage("MOVED "..quantity.. " "..box.name.." from inventory with ID: "..altID.." to Player inventory account: ")
                                        
                                    else
                                        message("[ERROR] : slot is occupied.", "info")
                                        box.x = box.originalX
                                        box.y = box.originalY
                                        snapped = true
                                        
                                    end
                                end
                                snapped = true
                                
                            end
                        end
                    end

                    if not snapped then
                        box.x = box.originalX
                        box.y = box.originalY
                    end
                end
                triggerServerEvent("onInventoryClose", resourceRoot, boxes, altBoxes, altID)
            end
        end
    end
end)

-- Function to handle cursor movement for dragging the boxes
addEventHandler("onClientCursorMove", root, function(_, _, absX, absY)
    for _, box in ipairs(boxes) do
        if box.dragging then
            box.x = absX - box.offsetX
            box.y = absY - box.offsetY
        end
    end

    for _, box in ipairs(altBoxes) do
        if box.dragging then
            box.x = absX - box.offsetX
            box.y = absY - box.offsetY
        end
    end

end)

--ON CLIENT RESOURCE STOP
function onResourceStop()
    
end

addEventHandler("onClientResourceStop", resourceRoot, onResourceStop)
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------

function sendInventoryMessage(message)
    triggerServerEvent("sendInventoryWebhook", localPlayer, message, localPlayer)
end
