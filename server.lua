local lastPlayerRequest = {}
local turningVehicles = {}

lib.callback.register('jg-vehicleindicators:server:set-state', function(playerId, vehicleId, indicatorState)
    local now = GetGameTimer()
    local lastTime = lastPlayerRequest[playerId] or 0
    if now - lastTime < 200 then return false end
    lastPlayerRequest[playerId] = now
    
    local car = NetworkGetEntityFromNetworkId(vehicleId)
    if not car or GetPedInVehicleSeat(car, -1) ~= GetPlayerPed(playerId) then return false end
    
    Entity(car).state.indicate = indicatorState
    
    if (indicatorState[1] and not indicatorState[2]) or (not indicatorState[1] and indicatorState[2]) then
        turningVehicles[vehicleId] = {GetEntityHeading(car), now, 0}
    else
        turningVehicles[vehicleId] = nil
    end
    
    return true
end)

CreateThread(function()
    while true do
        Wait(1000)
        for vehicleId, data in pairs(turningVehicles) do
            local car = NetworkGetEntityFromNetworkId(vehicleId)
            if not car then
                turningVehicles[vehicleId] = nil
            else
                local currentHeading = GetEntityHeading(car)
                local turnAmount = math.abs(currentHeading - data[1])
                if turnAmount > 180 then turnAmount = 360 - turnAmount end
                
                data[3] = data[3] + turnAmount
                data[1] = currentHeading
                
                if data[3] >= 30 or GetGameTimer() - data[2] > 15000 then
                    Entity(car).state.indicate = {false, false}
                    turningVehicles[vehicleId] = nil
                end
            end
        end
    end
end)

lib.addCommand('indicate_left', {
  help = 'Toggle left vehicle indicator',
  restricted = false
}, function(source, args, raw)
  TriggerClientEvent('vehicle:toggleIndicator', source, 'left')
end) 
lib.addCommand('indicate_right', {
  help = 'Toggle right vehicle indicator',
  restricted = false
}, function(source, args, raw)
  TriggerClientEvent('vehicle:toggleIndicator', source, 'right')
end)
lib.addCommand('hazards', {
  help = 'Toggle vehicle hazard lights',
  restricted = false
}, function(source, args, raw)
  TriggerClientEvent('vehicle:toggleIndicator', source, 'hazards')
end)