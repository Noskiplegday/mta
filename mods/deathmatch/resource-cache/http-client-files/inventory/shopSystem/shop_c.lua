local screenW, screenH = guiGetScreenSize()
local rx = screenW/1920
local ry = screenH/1080
local shopItems = {}  -- Items in the shop
local cart = {}        -- Player's cart
local isShopOpen = false
local scrollOffset = 0  
local shopName = ""
local nearShopMarker = false
local currentShopID = nil  

-- Local config for shop markers/blips (independent from other resources)
local configPontos = {
	corImagem = {255, 255, 255}, -- default white image color
}

-- UI Layout
local uiX, uiY, uiW, uiH = 384, 194.4, 1152, 648
local rowHeight = 230
local itemsPerRow = 6
local colSpacing = 30-- Spacing between columns for better visibility

--animation
local buyButtonColor = tocolor(0, 0, 0, 255)  -- Default color: black

-- Handle Pressing "E" to Open Shop
-- Handle Pressing "E" to Open Shop
bindKey("e", "down", function()
    if not isShopOpen then
        if nearShopMarker and currentShopID then
            triggerServerEvent("requestShopItems", localPlayer, currentShopID)
            showCursor(true)
        end
    else
        isShopOpen = false
        removeEventHandler("onClientRender", root, drawShopGUI)
        showCursor(false)
        
    end
end)

-- Modern HTML Shop UI integration
local shopBrowser = nil
local shopBrowserShowing = false

function showShopHTML(shopID, shop)
    if shopBrowserShowing then return end
    local screenW, screenH = guiGetScreenSize()
    shopBrowser = guiCreateBrowser(0, 0, screenW, screenH, true, true, false)
    local theBrowser = guiGetBrowser(shopBrowser)
    addEventHandler("onClientBrowserCreated", theBrowser, function()
        loadBrowserURL(theBrowser, "http://mta/local/shopSystem/html/shop.html")
    end, false)
    addEventHandler("onClientBrowserDocumentReady", theBrowser, function()
        -- Manually build a JS array string from the shop.items table
        local jsArray = "["
        if type(shop.items) == "table" then
            local i = 0
            for itemName, data in pairs(shop.items) do
                i = i + 1
                if i > 1 then jsArray = jsArray .. "," end
                -- Always use the image path from the items table in config.lua
                local imagePath = "images/shop/default.png"
                if items[itemName] and items[itemName].image then
                    imagePath = items[itemName].image:gsub("%[images%]/", "images/")
                    imagePath = imagePath:gsub("shopSystem/html/", "")
                end
                jsArray = jsArray .. string.format("{\"name\":%q,\"price\":%s,\"quantity\":%s,\"image\":%q}",
                    tostring(itemName),
                    tostring(data.price or 0),
                    tostring(data.quantity or 0),
                    imagePath
                )
            end
        end
        jsArray = jsArray .. "]"
        local shopName = shop.name or "Shop"
        executeBrowserJavascript(theBrowser, "window.setShopData('" .. tostring(shopID) .. "', '" .. shopName:gsub("'", "\\'") .. "', " .. jsArray .. ");")
    end, false)
    showCursor(true)
    --guiSetInputMode("no_binds")
    shopBrowserShowing = true
end

function hideShopHTML()
    if shopBrowser and isElement(shopBrowser) then
        destroyElement(shopBrowser)
        shopBrowser = nil
        shopBrowserShowing = false
        showCursor(false)
        guiSetInputMode("allow_binds")
    end
end

addEvent("openShopGUI", true)
addEventHandler("openShopGUI", root, function(shopID, shop)
    showShopHTML(shopID, shop)
end)

addEvent("shop:close", true)
addEventHandler("shop:close", root, function()
    hideShopHTML()
end)

addEvent("shop:buyItems", true)
addEventHandler("shop:buyItems", root, function(shopID, cart)
    local cartTable = {}
    if type(cart) == "string" then
        local status, result = pcall(function() return fromJSON(cart) end)
        if status and type(result) == "table" then
            cartTable = result
        end
    elseif type(cart) == "table" then
        cartTable = cart
    end
    triggerServerEvent("buyItem", localPlayer, shopID, cartTable)
    hideShopHTML()
end)

-- Detect Nearby Shop Marker
addEventHandler("onClientColShapeHit", root, function(element)
    if element == localPlayer then
        local shopID = getElementData(source, "shopID")
        if shopID then
            nearShopMarker = true
            currentShopID = shopID
            message("Press 'E' to access the shop.", "info")
        end
    end
end)

addEventHandler("onClientColShapeLeave", root, function(element)
    if element == localPlayer then
        nearShopMarker = false
        currentShopID = nil
    end
end)


--ANIMATION

addEventHandler("onClientCursorMove", root, function(_, _, x, y)
    -- Check if the cursor is within the specified bounds
    if x >= 1287 * rx and x <= 1535 *ry and y >= 875 *rx and y <= 938 *ry then
        -- Change the color to white if the cursor is inside the bounds
        buyButtonColor = tocolor(200, 255, 200, 255)
    else
        -- Change the color to black if the cursor is outside the bounds
        buyButtonColor = tocolor(255, 255, 255, 255)
    end
end)








local shopData = {}

addEvent("openShopManagementGUI", true)
addEventHandler("openShopManagementGUI", root, function(shop)
    if isElement(shopGUI) then destroyElement(shopGUI) end

    shopData = shop
    showCursor(true)
    shopGUI = guiCreateWindow(0.35, 0.3, 0.3, 0.5, "Shop Management - [DOUBLE CLICK ON TO REFILL] ", true)
    itemList = guiCreateGridList(0.05, 0.1, 0.9, 0.7, true, shopGUI)
    guiGridListAddColumn(itemList, "Item", 0.5)
    guiGridListAddColumn(itemList, "Quantity", 0.4)

    for item, data in pairs(shop.items) do
        local row = guiGridListAddRow(itemList)
        guiGridListSetItemText(itemList, row, 1, item, false, false)
        guiGridListSetItemText(itemList, row, 2, tostring(data.quantity), false, false)
    end

    -- Double-click event to refill item
    addEventHandler("onClientGUIDoubleClick", itemList, function()
        local row, col = guiGridListGetSelectedItem(itemList)
        if row ~= -1 and col == 1 then  -- Ensure an item name is selected
            local itemName = guiGridListGetItemText(itemList, row, 1)
            triggerServerEvent("refillItem", resourceRoot, shop.id, itemName)
            destroyElement(shopGUI)
            showCursor(false)
        end
    end, false)

    closeButton = guiCreateButton(0.3, 0.85, 0.4, 0.1, "Close", true, shopGUI)
    addEventHandler("onClientGUIClick", closeButton, function()
        destroyElement(shopGUI)
        showCursor(false)
    end, false)
end)



local shopHelpWindow = nil

addEvent("openShopHelpGUI", true)
addEventHandler("openShopHelpGUI", root, function()
    if isElement(shopHelpWindow) then
        return -- Prevent opening multiple windows
    end

    -- Create GUI Window
    local screenW, screenH = guiGetScreenSize()
    shopHelpWindow = guiCreateWindow((screenW - 400) / 2, (screenH - 300) / 2, 400, 300, "Shop Help", false)
    
    -- Instructions & Commands
    local helpText = [[
    --- Player Commands ---
    Press 'E' near a shop to open it.
    /shophelp - Show this help menu.

    --- Owner Commands ---
    /shopmanage - To manage and refill the shop

    --- Admin Commands ---
    /shopid - Get the shop ID of the nearest shop.
    /shopsetowner [shopID] [ownerName] - Set the owner of a shop.
    /shoprefill [shopID] - Refill all items in a shop.
    ]]
    
    local helpLabel = guiCreateLabel(10, 30, 380, 200, helpText, false, shopHelpWindow)
    guiLabelSetHorizontalAlign(helpLabel, "left", true)

    -- Close Button
    local closeButton = guiCreateButton(150, 250, 100, 30, "Close", false, shopHelpWindow)
    addEventHandler("onClientGUIClick", closeButton, function()
        if isElement(shopHelpWindow) then
            destroyElement(shopHelpWindow)
            showCursor(false)
        end
    end, false)

    -- Show Cursor
    showCursor(true)
end)


-- SHOP LOGS
local shopLogGUI = {}

addEvent("showShopLogsGUI", true)
addEventHandler("showShopLogsGUI", root, function(logs)
    if shopLogGUI.window then destroyElement(shopLogGUI.window) end

    showCursor(true)

    -- Create GUI
    shopLogGUI.window = guiCreateWindow(0.3, 0.25, 0.4, 0.5, "Shop Transaction Logs", true)
    shopLogGUI.gridlist = guiCreateGridList(0.05, 0.1, 0.9, 0.7, true, shopLogGUI.window)

    -- Add columns
    local colID = guiGridListAddColumn(shopLogGUI.gridlist, "ID", 0.08)
    local colBuyer = guiGridListAddColumn(shopLogGUI.gridlist, "Buyer", 0.15)
    local colItem = guiGridListAddColumn(shopLogGUI.gridlist, "Item", 0.2)
    local colQty = guiGridListAddColumn(shopLogGUI.gridlist, "Qty", 0.08)
    local colPrice = guiGridListAddColumn(shopLogGUI.gridlist, "Price", 0.15)
    local colTime = guiGridListAddColumn(shopLogGUI.gridlist, "Timestamp", 0.25) -- New column for timestamp

    -- Populate gridlist
    for _, log in ipairs(logs) do
        local row = guiGridListAddRow(shopLogGUI.gridlist)
        guiGridListSetItemText(shopLogGUI.gridlist, row, colID, tostring(log.id), false, false)
        guiGridListSetItemText(shopLogGUI.gridlist, row, colBuyer, log.buyer, false, false)
        guiGridListSetItemText(shopLogGUI.gridlist, row, colItem, log.item, false, false)
        guiGridListSetItemText(shopLogGUI.gridlist, row, colQty, tostring(log.quantity), false, false)
        guiGridListSetItemText(shopLogGUI.gridlist, row, colPrice, "$" .. tostring(log.price), false, false)
        guiGridListSetItemText(shopLogGUI.gridlist, row, colTime, log.timestamp, false, false) -- Show timestamp
    end

    -- Close Button
    shopLogGUI.close = guiCreateButton(0.35, 0.85, 0.3, 0.1, "Close", true, shopLogGUI.window)
    addEventHandler("onClientGUIClick", shopLogGUI.close, function()
        if shopLogGUI.window then destroyElement(shopLogGUI.window) end
        shopLogGUI = {}
        showCursor(false)
    end, false)
end)



-------------------------------------------------------------------------------------------------------
--IMAGE IN BLIP
-------------------------------------------------------------------------------------------------------
ShopLocations = {}

addEvent("receiveShopLocations", true)
addEventHandler("receiveShopLocations", root, function(data)
    if type(data) == "table" then
        ShopLocations = data
    end
end)



local garagemTxd = dxCreateTexture("[images]/shop/shop.png")

tick9 = getTickCount()
addEventHandler('onClientRender', root, 
function()
    local Op1, Op2 = interpolateBetween(0.4, 1.4, 0, 0.7, 1.7, 0, ((getTickCount() - tick9) / 1500), "SineCurve")
    local x, y, z = getCameraMatrix()
    
    for _, marker in ipairs(ShopLocations) do
        local markerX, markerY, markerZ = marker.x, marker.y, marker.z
        local distance_1 = getDistanceBetweenPoints3D(x, y, z, markerX, markerY, markerZ)

        if distance_1 <= 30 then
            local r, g, b = 255, 255, 255
            if configPontos and configPontos.corImagem then
                r = configPontos.corImagem[1] or r
                g = configPontos.corImagem[2] or g
                b = configPontos.corImagem[3] or b
            end
            dxDrawMaterialLine3D(markerX, markerY, markerZ + Op1, markerX, markerY, markerZ + Op2, garagemTxd, 1, tocolor(r, g, b, 255))
        end
    end
end)

-- Add a new event to close the shop UI from the server when purchase is successful
addEvent("shop:closeUI", true)
addEventHandler("shop:closeUI", root, function()
    hideShopHTML()
end)

addEvent("shop:message", true)
addEventHandler("shop:message", root, function(msg, msgType)
    outputChatBox("[SHOP:MESSAGE] " .. tostring(msg) .. " (" .. tostring(msgType) .. ")", 255, 200, 0)
    if shopBrowser and isElement(shopBrowser) then
        local theBrowser = guiGetBrowser(shopBrowser)
        local safeMsg = tostring(msg):gsub("'", "\'")
        local safeType = tostring(msgType or "info")
        executeBrowserJavascript(theBrowser, "window.showShopMessage('" .. safeMsg .. "', '" .. safeType .. "')")
    end
end)


