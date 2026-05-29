function getDB()
    local mysql = getResourceFromName("mysql")
    if mysql and getResourceState(mysql) == "running" then
        return exports.mysql:getConnection()
    end
    return false
end

addEventHandler("onResourceStart", resourceRoot, function()
    local db = getDB()
    if db then
        dbExec(db, [[
            CREATE TABLE IF NOT EXISTS character_pets (
                char_id INT PRIMARY KEY,
                pet_name VARCHAR(32) DEFAULT 'Cún Con',
                pet_model INT DEFAULT 312
            )
        ]])
    end
end)

-- Gọi Pet ra
function spawnPet(player)
    local charID = getElementData(player, "char:id")
    if not charID then return end

    -- Xóa Pet cũ nếu đang có trên map
    local oldPet = getElementData(player, "char:petElement")
    if isElement(oldPet) then destroyElement(oldPet) end

    local db = getDB()
    dbQuery(function(qh)
        local result = dbPoll(qh, 0)
        local petName = "Pet"
        local petModel = 312

        if result and #result > 0 then
            petName = result[1].pet_name
            petModel = result[1].pet_model
        else
            dbExec(db, "INSERT INTO character_pets (char_id) VALUES (?)", charID)
        end

        local x, y, z = getElementPosition(player)
        local pet = createPed(petModel, x + 1, y + 1, z)
        
        if pet then
            setElementData(pet, "pet:owner", player)
            setElementData(pet, "pet:name", petName)
            setElementData(player, "char:petElement", pet)
            
            -- Hiển thị tên Pet (có thể dùng label hoặc 3D text ở script khác)
            outputChatBox("#00FF00[Pet] #FFFFFF" .. petName .. " đã xuất hiện!", player, 255, 255, 255, true)
        end
    end, db, "SELECT * FROM character_pets WHERE char_id = ?", charID)
end
addCommandHandler("callpet", spawnPet)

-- Lệnh điều khiển Pet
function petCommand(player, cmd, action, ...)
    local pet = getElementData(player, "char:petElement")
    if not isElement(pet) then 
        outputChatBox("#FF4444[Pet] Bạn chưa gọi Pet ra. Dùng /callpet", player, 255, 255, 255, true)
        return 
    end

    if action == "name" then
        local newName = table.concat({...}, " ")
        if #newName > 0 and #newName < 20 then
            local charID = getElementData(player, "char:id")
            setElementData(pet, "pet:name", newName)
            dbExec(getDB(), "UPDATE character_pets SET pet_name = ? WHERE char_id = ?", newName, charID)
            outputChatBox("#00FF00[Pet] Đã đổi tên thú cưng thành: " .. newName, player, 255, 255, 255, true)
        end
    elseif action == "sit" then
        setElementData(pet, "pet:sitting", true)
        outputChatBox("#00FF00[Pet] Bạn bảo Pet ngồi xuống.", player, 255, 255, 255, true)
    elseif action == "follow" then
        setElementData(pet, "pet:sitting", false)
        outputChatBox("#00FF00[Pet] Bạn bảo Pet đi theo.", player, 255, 255, 255, true)
    else
        outputChatBox("Sử dụng: /pet [name/sit/follow]", player, 255, 200, 0)
    end
end
addCommandHandler("pet", petCommand)

-- Tự động cất pet khi thoát
addEventHandler("onPlayerQuit", root, function()
    local pet = getElementData(source, "char:petElement")
    if isElement(pet) then destroyElement(pet) end
end)