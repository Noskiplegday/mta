local trafficVehicles = {}

function spawnTraffic()
    local veh = createVehicle(420, 0,0,5)

    if veh then
        setVehicleEngineState(veh, true)
        table.insert(trafficVehicles, veh)
    end
end

addCommandHandler("traffic", function(player)
    spawnTraffic()
    outputChatBox("Spawned traffic vehicle.", player)
end)