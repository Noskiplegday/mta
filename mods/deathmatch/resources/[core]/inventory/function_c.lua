-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
-- DROP FUNCTION
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
addCommandHandler("drop", function(_, itemName, amount)
    if not itemName or not amount then
        message("Usage: /drop [itemName] [amount]", "info")
        return
    end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    triggerServerEvent("onPlayerDropItem", resourceRoot, itemName, amount)
end)

local currentDrop = nil

addEvent("onPlayerNearDrop", true)
addEventHandler("onPlayerNearDrop", root, function(dropData)
    currentDrop = dropData
    message("Press 'E' to interact with dropped items", "info")
end)

bindKey("e", "down", function()
    if currentDrop and currentDrop.marker then
        local playerX, playerY, playerZ = getElementPosition(localPlayer)
        local markerX, markerY, markerZ = currentDrop.x, currentDrop.y, currentDrop.z
        local distance = getDistanceBetweenPoints3D(playerX, playerY, playerZ, markerX, markerY, markerZ)

        if distance <= 2 then -- Only open if within 2 units
            local items = currentDrop.items
            triggerEvent("onShowDropMenu", root, currentDrop.marker, items)
            currentDrop = nil
        end
    end
end)


local window = nil

addEvent("onShowDropMenu", true)
addEventHandler("onShowDropMenu", root, function(marker, items)
    showDropGUI(marker, items)
end)

function showDropGUI(marker, items)
    if window then 
        destroyElement(window)
        window = nil
        showCursor(false)
    else
        showCursor(true)
        local screenW, screenH = guiGetScreenSize()
        local windowW, windowH = 250, 300
        local windowX, windowY = (screenW - windowW) / 2, (screenH - windowH) / 2
        
        window = guiCreateWindow(windowX, windowY, windowW, windowH, "Dropped Items", false)
        
        -- Create Scrollable List
        local list = guiCreateGridList(10, 30, 230, 180, false, window)
        guiGridListAddColumn(list, "Items", 0.8)

        for _, item in ipairs(items) do
            local row = guiGridListAddRow(list)
            guiGridListSetItemText(list, row, 1, item.itemName .. " (" .. item.amount .. ")", false, false)
        end

        local btnPickup = guiCreateButton(10, 220, 110, 30, "Pickup", false, window)
        local btnClose = guiCreateButton(130, 220, 110, 30, "Close", false, window)

        -- Pickup Item
        addEventHandler("onClientGUIClick", btnPickup, function()
            local selectedRow = guiGridListGetSelectedItem(list)
            if selectedRow >= 0 then
                local selectedItem = guiGridListGetItemText(list, selectedRow, 1)
                local itemName = selectedItem:match("(.+) %(") -- Extract name
                triggerServerEvent("onPlayerPickupItem", resourceRoot, marker, itemName)
            end
            destroyElement(window)
            window = nil
            showCursor(false)
        end, false)

        -- Close Button
        addEventHandler("onClientGUIClick", btnClose, function()
            destroyElement(window)
            window = nil
            showCursor(false)
        end, false)
    end
end
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------