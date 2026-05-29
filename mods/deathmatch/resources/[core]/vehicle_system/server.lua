local pets = {}

function createPlayerPet(player)
    -- Nếu đã có pet thì xóa cái cũ
    if pets[player] and isElement(pets[player]) then
        destroyElement(pets[player])
    end

    local x, y, z = getElementPosition(player)
    local pet = createPed(312, x + 1, y, z) -- Model 312: Cún con

    if pet then
        pets[player] = pet
        setElementData(pet, "pet:name", getPlayerName(player).."'s Pet")
        outputChatBox("#00FF00[Pet] Chú cún của bạn đã xuất hiện! Gõ /pet để gọi lại nếu bị lạc.", player, 255, 255, 255, true)
    end
end
addCommandHandler("pet", createPlayerPet)

-- Vòng lặp follow siêu nhẹ (500ms)
setTimer(function()
    for player, pet in pairs(pets) do
        if isElement(player) and isElement(pet) then
            local px, py, pz = getElementPosition(player)
            local vx, vy, vz = getElementPosition(pet)
            local dist = getDistanceBetweenPoints3D(px, py, pz, vx, vy, vz)

            if dist > 30 then
                -- Quá xa thì teleport lại
                setElementPosition(pet, px + 1, py, pz)
            elseif dist > 3 then
                -- Xoay mặt về phía chủ
                local angle = math.atan2(py - vy, px - vx)
                setPedRotation(pet, -math.deg(angle) + 90)
                
                -- Di chuyển tới
                setPedControlState(pet, "forwards", true)
                
                -- Chạy nếu khoảng cách lớn
                if dist > 7 then
                    setPedControlState(pet, "run", true)
                else
                    setPedControlState(pet, "run", false)
                end
            else
                -- Đứng lại khi đã gần
                setPedControlState(pet, "forwards", false)
                setPedControlState(pet, "run", false)
            end

            -- Đồng bộ chiều không gian và nội thất
            if getElementDimension(pet) ~= getElementDimension(player) then
                setElementDimension(pet, getElementDimension(player))
            end
            if getElementInterior(pet) ~= getElementInterior(player) then
                setElementInterior(pet, getElementInterior(player))
            end
        end
    end
end, 500, 0)

addEventHandler("onPlayerQuit", root, function()
    if pets[source] then
        if isElement(pets[source]) then destroyElement(pets[source]) end
        pets[source] = nil
    end
end)