-- peds/client.lua
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- [QUAN TRỌNG]: Đặt mật độ người đi bộ tối đa ở phía máy người chơi (Mức 3)
    setPlayerPedDensity(localPlayer, 3)
end)

-- Logic Pet đi theo chủ (Chạy mỗi 500ms để tiết kiệm hiệu năng)
setTimer(function()
    for _, pet in ipairs(getElementsByType("ped")) do
        local owner = getElementData(pet, "pet:owner")
        
        -- Chỉ xử lý nếu Pet này thuộc về người chơi hiện tại
        if owner == localPlayer then
            local isSitting = getElementData(pet, "pet:sitting")
            if not isSitting then
                local px, py, pz = getElementPosition(owner)
                local ex, ey, ez = getElementPosition(pet)
                local dist = getDistanceBetweenPoints3D(px, py, pz, ex, ey, ez)

                if dist > 15 then 
                    -- Nếu quá xa (vùng load), teleport lại gần
                    setElementPosition(pet, px + 1, py + 1, pz)
                elseif dist > 3 then 
                    -- Tính toán góc xoay mặt về phía chủ
                    local rot = math.atan2(py - ey, px - ex) * 180 / math.pi
                    setPedRotation(pet, rot - 90)
                    
                    -- Bắt đầu đi chuyển
                    setPedControlState(pet, "forwards", true)
                    -- Nếu khoảng cách vừa phải thì đi bộ, xa thì chạy
                    setPedControlState(pet, "walk", dist < 6)
                else 
                    -- Đã đủ gần, dừng lại
                    setPedControlState(pet, "forwards", false)
                end
            else
                -- Đang ở chế độ "Sit", không di chuyển
                setPedControlState(pet, "forwards", false)
            end
        end
    end
end, 500, 0)