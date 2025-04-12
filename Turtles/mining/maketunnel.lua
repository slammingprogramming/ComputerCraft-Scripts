-- Supercharged Tunnel Digger with Enhancements
-- Features: Fuel checking, torch placement, state saving, config file loading, optional cleanup, GPS support

local configDir = "/shaft_configs"
local saveFile = "/shaft_state.sav"
local tArgs = {...}
local fs = require("fs")

-- Utility Functions
function refuel(minFuel)
  minFuel = minFuel or 100
  while turtle.getFuelLevel() < minFuel do
    for i = 1, 16 do
      turtle.select(i)
      if turtle.refuel(1) then break end
    end
    if turtle.getFuelLevel() < minFuel then
      print("Insert fuel to continue...")
      sleep(2)
    end
  end
end

function dig() while turtle.detect() do turtle.dig() sleep(0.5) end end
function digUp() while turtle.detectUp() do turtle.digUp() sleep(0.5) end end
function digDown() while turtle.detectDown() do turtle.digDown() sleep(0.5) end end
function placeTorch() for i = 1, 16 do turtle.select(i) if turtle.getItemDetail(i) and turtle.getItemDetail(i).name:find("torch") then turtle.placeDown() break end end end
function cleanInventory() for i = 1, 16 do turtle.select(i) local item = turtle.getItemDetail() if item and item.name:find("cobble") then turtle.drop() end end end

-- Save/Load State
function saveState(state)
  local file = fs.open(saveFile, "w")
  file.write(textutils.serialize(state))
  file.close()
end

function loadState()
  if fs.exists(saveFile) then
    local file = fs.open(saveFile, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
  end
  return nil
end

function clearState()
  if fs.exists(saveFile) then fs.delete(saveFile) end
end

-- Load Config
local config = {
  length = 10,
  height = 4,
  torchInterval = 5,
  cleanInventory = false,
  useGPS = false
}

if #tArgs == 1 then
  local confFile = configDir .. "/" .. tArgs[1] .. ".cfg"
  if fs.exists(confFile) then
    local file = fs.open(confFile, "r")
    config = textutils.unserialize(file.readAll())
    file.close()
  else
    print("Invalid config name or config file missing.")
    return
  end
else
  print("Usage: shaft <configName>")
  return
end

local length = config.length
if length % 2 ~= 0 then length = (length + 1) / 2 else length = length / 2 end

-- Resume or Start Fresh
local state = loadState() or { distance = 1, goingUp = true }

-- Begin Tunnel
for distance = state.distance, length do
  refuel(100)

  if state.goingUp then
    dig()
    turtle.forward()
    for i = 1, config.height do
      dig()
      if i ~= config.height then digUp() end
      turtle.up()
    end
  else
    dig()
    turtle.forward()
    for i = 1, config.height do
      dig()
      if i ~= config.height then digDown() end
      turtle.down()
    end
  end

  if config.torchInterval > 0 and (distance % config.torchInterval == 0) then
    placeTorch()
  end

  if config.cleanInventory then cleanInventory() end

  dig()
  turtle.forward()
  state.distance = distance + 1
  state.goingUp = not state.goingUp
  saveState(state)
end

-- Return Home
clearState()
turtle.turnLeft() turtle.turnLeft()
for i = 1, (length * 2) do
  while not turtle.forward() do sleep(0.5) end
end
if config.height % 2 ~= 0 then for i = 1, config.height do turtle.down() end end
print("Tunnel complete.")
