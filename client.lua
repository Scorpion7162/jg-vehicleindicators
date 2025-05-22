local vehicleIndicators = {}
local brakeLightsOn = false
local previousSpeed = 0
local lastBrakeCheck = 0

local function toggleIndicator(direction)
    if not cache.vehicle or cache.seat ~= -1 then return false end
    
    local vehicleId = VehToNet(cache.vehicle)
    if not vehicleId or vehicleId == 0 then return false end
    
    local currentState = vehicleIndicators[vehicleId] or {false, false}
    local newState
    
    if direction == 'left' then
        newState = (currentState[2] or not currentState[1]) and {true, false} or {false, false}
    elseif direction == 'right' then
        newState = (currentState[1] or not currentState[2]) and {false, true} or {false, false}
    elseif direction == 'hazards' then
        newState = (currentState[1] and currentState[2]) and {false, false} or {true, true}
    else
        return false
    end
    
    lib.callback.await('jg-vehicleindicators:server:set-state', 3000, vehicleId, newState)
    return true
end

local function updateBrakeLights()
    local currentTime = GetGameTimer()
    if currentTime - lastBrakeCheck < 50 then return end
    lastBrakeCheck = currentTime
    
    local currentSpeed = GetEntitySpeed(cache.vehicle) * 2.237
    local shouldShowBrakes = (currentSpeed - previousSpeed) < -1.5 or currentSpeed < 0.2
    
    if shouldShowBrakes ~= brakeLightsOn then
        SetVehicleBrakeLights(cache.vehicle, shouldShowBrakes)
        brakeLightsOn = shouldShowBrakes
    end
    previousSpeed = currentSpeed
end

AddStateBagChangeHandler('indicate', nil, function(bagName, key, data)
    if type(data) ~= 'table' or #data ~= 2 then return end
    
    local vehicle = GetEntityFromStateBagName(bagName)
    if not vehicle or vehicle == 0 then return end
    
    local vehicleId = VehToNet(vehicle)
    if vehicleId and vehicleId ~= 0 then
        vehicleIndicators[vehicleId] = data
        SetVehicleIndicatorLights(vehicle, 0, data[1])
        SetVehicleIndicatorLights(vehicle, 1, data[2])
    end
end)

CreateThread(function()
    while true do
        if cache.vehicle and cache.seat == -1 then
            updateBrakeLights()
        end
        Wait(0)
    end
end)

lib.onCache('vehicle', function(vehicle)
    if vehicle then
        previousSpeed = 0
        brakeLightsOn = false
        lastBrakeCheck = 0
    end
end)
lib.addKeybind({
  name = 'indicate_left',
  description = 'Vehicle indicate left',
  defaultKey = 'LEFT',
  defaultMapper = 'keyboard',
  onPressed = function(self)
      toggleIndicator('left')
  end
})
lib.addKeybind({
  name = 'indicate_right', 
  description = 'Vehicle indicate right',
  defaultKey = 'RIGHT',
  defaultMapper = 'keyboard',
  onPressed = function(self)
      toggleIndicator('right')
  end
})
lib.addKeybind({
  name = 'hazards',
  description = 'Vehicle hazards',
  defaultKey = 'UP',
  defaultMapper = 'keyboard',
  onPressed = function(self)
      toggleIndicator('hazards')
  end
})

lib.callback.register('jg-vehicleindicators:client:toggle-all', function(enable)
    if not cache.vehicle or cache.seat ~= -1 then return false end
    
    local vehicleId = VehToNet(cache.vehicle)
    if not vehicleId or vehicleId == 0 then return false end
    
    lib.callback.await('jg-vehicleindicators:server:set-state', 3000, vehicleId, enable and {true, true} or {false, false})
    return true
end)

lib.callback.register('jg-vehicleindicators:client:toggle-indicator', function(direction)
  return toggleIndicator(direction)
end)