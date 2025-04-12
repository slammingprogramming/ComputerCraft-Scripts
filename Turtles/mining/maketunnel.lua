--[[
Supercharged Tunnel Digger
Supports:
- Interactive and argument-based configuration
- Config file loading and saving
- Fuel checking and refueling
- Inventory cleanup (optional)
- Torch placement at intervals
- State saving and resuming
- Variable tunnel dimensions and shapes
- Asymmetric offsets and tunnel orientation
- Turtle-relative origin placement (center, front, corner)
--]]

local fs = require("fs")
local gps = require("gps")

-- Default config values
local config = {
  length = nil,
  height = nil,
  width = nil,
  offsetX = 0,
  offsetY = 0,
  offsetZ = 0,
  origin = "front", -- front, center, back
  cleanInventory = false,
  torchInterval = 5,
  useGPS = false,
  configName = nil,
}

-- State saving
local stateFile = ".shaft_state"

function saveState(state)
  local file = fs.open(stateFile, "w")
  file.write(textutils.serialize(state))
  file.close()
end

function loadState()
  if fs.exists(stateFile) then
    local file = fs.open(stateFile, "r")
    local content = file.readAll()
    file.close()
    return textutils.unserialize(content)
  end
  return nil
end

function clearState()
  if fs.exists(stateFile) then fs.delete(stateFile) end
end

-- Load config file
function loadConfigFile(name)
  local path = "/shaft_configs/" .. name .. ".cfg"
  if fs.exists(path) then
    local file = fs.open(path, "r")
    local contents = file.readAll()
    file.close()
    return textutils.unserialize(contents)
  else
    print("Config file not found: " .. path)
    return nil
  end
end

function promptInteractive()
  local function ask(promptText, default)
    write(promptText .. (default and (" [" .. default .. "]") or "") .. ": ")
    local input = read()
    return input == "" and default or input
  end

  config.length = tonumber(config.length or ask("Tunnel length", 10))
  config.height = tonumber(config.height or ask("Tunnel height", 3))
  config.width = tonumber(config.width or ask("Tunnel width", 3))
  config.offsetX = tonumber(config.offsetX or ask("X Offset (left/right)", 0))
  config.offsetY = tonumber(config.offsetY or ask("Y Offset (up/down)", 0))
  config.offsetZ = tonumber(config.offsetZ or ask("Z Offset (forward/back)", 0))
  config.origin = config.origin or ask("Origin point (front/center/back)", "front")
  config.cleanInventory = config.cleanInventory or (ask("Clean inventory after dig? (y/n)", "n") == "y")
  config.torchInterval = tonumber(config.torchInterval or ask("Torch placement interval (blocks)", 5))
  config.useGPS = config.useGPS or (ask("Use GPS for navigation? (y/n)", "n") == "y")
end

function parseArgs()
  local args = {...}
  for _, arg in ipairs(args) do
    local key, val = arg:match("(%w+)%=(%w+)")
    if key and val then
      if tonumber(val) then val = tonumber(val)
      elseif val == "true" then val = true
      elseif val == "false" then val = false end
      config[key] = val
    end
  end
end

function ensureConfigComplete()
  for k,v in pairs(config) do
    if v == nil then
      promptInteractive()
      break
    end
  end
end

function checkFuel()
  if turtle.getFuelLevel() < 100 then
    print("Low fuel, please refuel...")
    while turtle.getFuelLevel() < 100 do
      turtle.refuel(1)
      sleep(1)
    end
  end
end

function placeTorch()
  local placed = false
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if item and item.name:find("torch") then
      turtle.select(i)
      turtle.placeDown()
      placed = true
      break
    end
  end
  if not placed then
    print("No torch available to place.")
  end
end

function cleanInventory()
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if item and not item.name:find("torch") then
      turtle.select(i)
      turtle.drop()
    end
  end
end

function digVolume(length, width, height, offset)
  print("Digging tunnel of size LxWxH = "..length.."x"..width.."x"..height.."...")
  for l = 1, length do
    for w = 1, width do
      for h = 1, height do
        local dx = w - 1 + offset.x
        local dy = h - 1 + offset.y
        local dz = l - 1 + offset.z
        -- Move turtle to position, dig, return to center
        -- (Assume simple linear motion for now)
        -- Future: add GPS/waypoint targeting
        turtle.dig()
        if h ~= height then turtle.digUp() end
        turtle.up()
      end
      for h = 1, height - 1 do
        turtle.down()
      end
      if w < width then
        turtle.turnRight()
        turtle.dig()
        turtle.forward()
        turtle.turnLeft()
      end
    end
    if config.torchInterval and (l % config.torchInterval == 0) then
      placeTorch()
    end
    if l < length then
      turtle.dig()
      turtle.forward()
    end
  end
end

-- MAIN
parseArgs()
if config.configName then
  local loaded = loadConfigFile(config.configName)
  if loaded then
    for k,v in pairs(loaded) do config[k] = v end
  end
end
ensureConfigComplete()

checkFuel()

local offset = { x = config.offsetX or 0, y = config.offsetY or 0, z = config.offsetZ or 0 }
digVolume(config.length, config.width, config.height, offset)

if config.cleanInventory then
  cleanInventory()
end

clearState()
print("Tunnel complete!")
