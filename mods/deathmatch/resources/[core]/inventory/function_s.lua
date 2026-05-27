-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
-- USE FUNCTION
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------

addEvent("onPlayerUseItem", true)
addEventHandler("onPlayerUseItem", root, function(itemName)
    local player = client 
    if not itemName then
        message(player, "Invalid item name or amount!", "error")
        return
    end
--FOOD ITEMS
    -- NORMAL DRINK
    if itemName == "water" or itemName == "coffee" or itemName == "fanta" or itemName == "LemonSoda" or itemName == "tea" then 
        local thirst = tonumber(getElementData(player, thirstElementData)) or 0
        if (NormalDrinkAmount + thirst) <= 100 then
            if takeItem(player, itemName, 1) then
                message(player, "You drank " .. itemName, "success")
                setElementData(player, thirstElementData, NormalDrinkAmount + thirst)
                setPedAnimation(player, "VENDING", "VEND_Drink_P", 3000, false, false, false, false) -- Drinking animation
            else
                message(player, "You can't drink " .. itemName, "error")
            end
        else 
            if takeItem(player, itemName, 1) then
                message(player, "You drank " .. itemName, "success")
                setElementData(player, thirstElementData, 100)
                setPedAnimation(player, "VENDING", "VEND_Drink_P", 3000, false, false, false, false) -- Drinking animation
            else
                message(player, "You can't drink " .. itemName, "error")
            end
        end

    -- NORMAL FOOD
    elseif itemName == "Chocolate" or itemName == "lays" then
        local hunger = tonumber(getElementData(player, hungerElementData)) or 0
        if (NormalFoodAmount + hunger) <= 100 then
            if takeItem(player, itemName, 1) then
                message(player, "You ate " .. itemName, "success")
                setElementData(player, hungerElementData, NormalFoodAmount + hunger)
                setPedAnimation(player, "FOOD", "EAT_Burger", 3000, false, false, false, false) -- Eating animation
            else
                message(player, "You can't eat " .. itemName, "error")
            end
        else
            if takeItem(player, itemName, 1) then
                message(player, "You ate " .. itemName, "success")
                setElementData(player, hungerElementData, 100)
                setPedAnimation(player, "FOOD", "EAT_Burger", 3000, false, false, false, false) -- Eating animation
            else
                message(player, "You can't eat " .. itemName, "error")
            end
        end

    -- SPECIAL FOOD
    elseif itemName == "Pizza" or itemName == "burger" or itemName == "salad" or itemName == "biriyani" or itemName == "chickenCurry" or itemName == "fishCurry" or itemName == "friedRice" or itemName == "prawn" or itemName == "rice" or itemName == "sambar" or itemName == "vada" then
        local hunger = tonumber(getElementData(player, hungerElementData)) or 0
        if (SpecialFoodAmount + hunger) <= 100 then
            if takeItem(player, itemName, 1) then
                message(player, "You ate " .. itemName, "success")
                setElementData(player, hungerElementData, SpecialFoodAmount + hunger)
                setPedAnimation(player, "FOOD", "EAT_Burger", 3000, false, false, false, false) -- Eating animation
            else
                message(player, "You can't eat " .. itemName, "error")
            end
        else
            if takeItem(player, itemName, 1) then
                message(player, "You ate " .. itemName, "success")
                setElementData(player, hungerElementData, 100)
                setPedAnimation(player, "FOOD", "EAT_Burger", 3000, false, false, false, false) -- Eating animation
            else
                message(player, "You can't eat " .. itemName, "error")
            end
        end

    -- SPECIAL DRINK
    elseif itemName == "wine" or itemName == "beer" or itemName == "oldMonk" or itemName == "Tequila" or itemName == "Vodka" or itemName == "Whisky" then 
        local thirst = tonumber(getElementData(player, thirstElementData)) or 0
        if (SpecialDrinkAmount + thirst) <= 100 then
            if takeItem(player, itemName, 1) then
                message(player, "You drank " .. itemName, "success")
                setElementData(player, thirstElementData, SpecialDrinkAmount + thirst)
                setPedAnimation(player, "VENDING", "VEND_Drink_P", 3000, false, false, false, false) -- Drinking animation
            else
                message(player, "You can't drink " .. itemName, "error")
                
            end
        else
            if takeItem(player, itemName, 1) then
                message(player, "You drank " .. itemName, "success")
                setElementData(player, thirstElementData, 100)
                setPedAnimation(player, "VENDING", "VEND_Drink_P", 3000, false, false, false, false) -- Drinking animation
            else
                message(player, "You don't have a that drink", "error")
            end
        end
--phone and radio
    elseif itemName == "Phone" then 
        if getItem(player, itemName) then
            exports.n3xt_celular:onCelular(player)
        else
            message(player, "You don't have a Phone!", "error")
        end
    elseif itemName == "Radio" then 
        if getItem(player, itemName) then
            exports.RadioComunicador:openRadio(player)
            message(player, "[PRESS] Backspace - close radio", "info")
        else
            message(player, "You don't have a radio!", "error")
        end
    
--VEHICLE SYSTEM
    elseif itemName == "repairkit" then 
        if takeItem(player, itemName, 1) then
            exports.vehicles:RepairVehicle(player)
        else
            message(player, "You don't have a repairKit!", "error")
        end
    elseif itemName == "fuelcan" then 
        if takeItem(player, itemName, 1) then
            exports.vehicles:FuelVehicle(player, 20)
        else
            message(player, "You don't have a Fuel can!", "error")
        end

    --DRUG SYSTEM
    elseif itemName == "Pot" then 
        if getItem(player, itemName) then
            exports.drugProduction:placePot(player)
        else
            message(player, "Error occured", "error")
        end
    elseif itemName == "Nokia" then 
        if getItem(player, itemName) then
            exports.drugProduction:openDealerPhone(player)
        else
            message(player, "You don't have a Nokia", "error")
        end
    elseif itemName == "Cocaine" then 
        if takeItem(player, itemName, 1) then
            -- trigger client-side cocaine effect from oDrugs
            triggerClientEvent(player, "oDrugs:useDrug", player, "cocaine")
        else
            message(player, "You don't have a cocaine", "error")
        end
    elseif itemName == "Joint" then
        if takeItem(player, itemName, 1) then
            -- oDrugs joint effect
            triggerClientEvent(player, "oDrugs:useDrug", player, "joint")
        else
            message(player, "You don't have a joint", "error")
        end
    elseif itemName == "Marijuana" then
        if takeItem(player, itemName, 1) then
            -- oDrugs marihuana effect (note: internal id is "marihuana")
            triggerClientEvent(player, "oDrugs:useDrug", player, "marihuana")
        else
            message(player, "You don't have marijuana", "error")
        end
    elseif itemName == "Cigarette" then
        if takeItem(player, itemName, 1) then
            -- reuse the joint visual effect for cigarettes
            triggerClientEvent(player, "oDrugs:useDrug", player, "joint")
        else
            message(player, "You don't have a cigarette", "error")
        end
    end
end) 

-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--GIVE FUNCTION
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
addEvent("onPlayerGiveItem", true)
addEventHandler("onPlayerGiveItem", root, function(itemName, amount)
    local giver = client
    amount = tonumber(amount) or 1
    if not itemName or amount <= 0 then
        message(player,"Invalid item name or amount!", "error")
        return
    end

    -- Find the nearest player (receiver)
    local giverX, giverY, giverZ = getElementPosition(giver)
    local nearestPlayer = nil
    local nearestDistance = 3 -- Max distance to consider as "nearby"

    for _, player in ipairs(getElementsByType("player")) do
        if player ~= giver then
            local playerX, playerY, playerZ = getElementPosition(player)
            local distance = getDistanceBetweenPoints3D(giverX, giverY, giverZ, playerX, playerY, playerZ)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
            end
        end
    end

    if not nearestPlayer then
        message(player,"No nearby player to give the item!", "error")
        return
    end

    -- Try to take the item from the giver and give it to the receiver
    if takeItem(giver, itemName, amount) then
        local given = giveItem(nearestPlayer, itemName, amount)
        if given then
            message(giver,"You gave " .. amount .. "x " .. itemName .. " to " .. getPlayerName(nearestPlayer) .. ".", "success")
            message(nearestPlayer, getPlayerName(giver) .. " gave you " .. amount .. "x " .. itemName .. ".", "success")
            return
        else
            -- If giving fails, return the item to the giver
            giveItem(giver, itemName, amount)
            message(player,"Error: Could not give the item. Item returned to you.", "error")
        end
    else
        message(player,"Error: You don't have enough " .. itemName .. " to give.", "error")
    end
end)


-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
-- DROP FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
local droppedItems = {} -- Stores dropped items {marker, object, location, items = {itemName, amount}}

addEvent("onPlayerDropItem", true)
addEventHandler("onPlayerDropItem", root, function(itemName, amount)
    if not itemName or not amount or amount <= 0 then return end

    local player = client
    if not takeItem(player, itemName, amount) then
        message(player,"Error: You don't have enough " .. itemName, "error")
        return
    end

    local x, y, z = getElementPosition(player)
    local nearestMarker = nil

    -- Find nearby marker within 2 units
    for _, data in ipairs(droppedItems) do
        local dist = getDistanceBetweenPoints3D(x, y, z, data.x, data.y, data.z)
        if dist < 2 then
            nearestMarker = data
            break
        end
    end

    if nearestMarker then
        -- Check if the same item already exists in the marker
        local itemFound = false
        for _, item in ipairs(nearestMarker.items) do
            if item.itemName == itemName then
                item.amount = item.amount + amount -- Add to existing amount
                itemFound = true
                break
            end
        end

        -- If item was not found, add a new entry
        if not itemFound then
            table.insert(nearestMarker.items, { itemName = itemName, amount = amount })
        end
    else
        -- Create new drop marker & object box
        local marker = createMarker(x, y, z - 1, "cylinder", 1.2, 255, 255, 0, 10)
        local objectBox = createObject(1271, x, y, z - 0.66) -- Small crate object
        setElementCollisionsEnabled(objectBox, false)

        local dropData = {
            marker = marker,
            object = objectBox,
            x = x, y = y, z = z,
            items = { { itemName = itemName, amount = amount } }
        }
        table.insert(droppedItems, dropData)

        -- Marker hit event
        addEventHandler("onMarkerHit", marker, function(hitPlayer)
            if getElementType(hitPlayer) == "player" then
                triggerClientEvent(hitPlayer, "onPlayerNearDrop", hitPlayer, dropData)
            end
        end)

        -- Destroy drop after 10 seconds if not picked up
        setTimer(function()
            for index, data in ipairs(droppedItems) do
                if data.marker == marker then
                    destroyElement(data.marker)
                    destroyElement(data.object)
                    table.remove(droppedItems, index)
                    break
                end
            end
        end, dropDestroyTime, 1)
    end
    message(player,"Dropped " .. amount .. " " .. itemName, "success")
    
end)

addEvent("onPlayerPickupItem", true)
addEventHandler("onPlayerPickupItem", root, function(marker, itemName)
    local player = client
    for index, data in ipairs(droppedItems) do
        if data.marker == marker then
            for i, item in ipairs(data.items) do
                if item.itemName == itemName then
                    local given = giveItem(player, itemName, item.amount)

                    -- Ensure the item is given, otherwise return the item back
                    if given then
                        table.remove(data.items, i)

                        -- If no more items, remove marker and object
                        if #data.items == 0 then
                            destroyElement(data.marker)
                            destroyElement(data.object)
                            table.remove(droppedItems, index)
                        end
                        return
                    else
                        message(player,"Error: Could not pick up " .. itemName, "error")
                        return
                    end
                end
            end
        end
    end
end)
-------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------

