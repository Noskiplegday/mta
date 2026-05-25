-- Khoảng cách giới hạn để nghe thấy tiếng chat (20 mét)
local chatRadius = 20 

-- 1. XỬ LÝ CHAT THƯỜNG (LOCAL CHAT)
addEventHandler("onPlayerChat", root, function(message, messageType)
    -- Nếu là chat thường (messageType = 0)
    if messageType == 0 then
        cancelEvent() -- Chặn dòng chat mặc định của MTA lại

        local posX, posY, posZ = getElementPosition(source)
        local playerName = getPlayerName(source)
        
        -- Duyệt qua tất cả người chơi trên server
        for _, player in ipairs(getElementsByType("player")) do
            local tx, ty, tz = getElementPosition(player)
            -- Tính khoảng cách giữa người chat và người nhận
            local distance = getDistanceBetweenPoints3D(posX, posY, posZ, tx, ty, tz)
            
            if distance <= chatRadius then
                -- Định dạng chat chuẩn Roleplay: Tên_Nhânvật nói: Nội dung
                outputChatBox(playerName .. " nói: " .. message, player, 230, 230, 230)
            end
        end
    end
end)

-- 2. LỆNH HÀNH ĐỘNG /ME (Màu tím đặc trưng RP)
addCommandHandler("me", function(player, cmd, ...)
    local message = table.concat({...}, " ")
    if message == "" then 
        outputChatBox("Cú pháp: /me [hành động]", player, 255, 0, 0)
        return 
    end
    
    local posX, posY, posZ = getElementPosition(player)
    local playerName = getPlayerName(player)
    
    for _, p in ipairs(getElementsByType("player")) do
        local tx, ty, tz = getElementPosition(p)
        if getDistanceBetweenPoints3D(posX, posY, posZ, tx, ty, tz) <= chatRadius then
            outputChatBox("* " .. playerName .. " " .. message, p, 155, 89, 182)
        end
    end
end)

-- 3. LỆNH THÔNG BÁO MÔ TẢ /DO (Màu xanh lam đậm RP)
addCommandHandler("do", function(player, cmd, ...)
    local message = table.concat({...}, " ")
    if message == "" then 
        outputChatBox("Cú pháp: /do [mô tả môi trường]", player, 255, 0, 0)
        return 
    end
    
    local posX, posY, posZ = getElementPosition(player)
    local playerName = getPlayerName(player)
    
    for _, p in ipairs(getElementsByType("player")) do
        local tx, ty, tz = getElementPosition(p)
        if getDistanceBetweenPoints3D(posX, posY, posZ, tx, ty, tz) <= chatRadius then
            outputChatBox("* " .. message .. " (( " .. playerName .. " ))", p, 41, 128, 185)
        end
    end
end)

-- 4. LỆNH ADMIN: DỊCH CHUYỂN ĐẾN TỌA ĐỘ (/gotopos X Y Z)
addCommandHandler("gotopos", function(player, cmd, x, y, z)
    -- Tạm thời chưa check quyền admin, cho bạn toàn quyền dùng để test map
    if x and y and z then
        setElementPosition(player, tonumber(x), tonumber(y), tonumber(z))
        outputChatBox("[Admin] Bạn đã dịch chuyển đến tọa độ: " .. x .. ", " .. y .. ", " .. z, player, 0, 255, 0)
    else
        outputChatBox("Cú pháp: /gotopos [X] [Y] [Z]", player, 255, 0, 0)
    end
end)