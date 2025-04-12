-- Supercharged Tunnel Digger with Configuration, Offsets, and Interactive Fallback

-- Utility Functions
local function prompt(msg)
  io.write(msg .. ": ")
  return read()
end

local function toNumberOrDefault(str, default)
  local num = tonumber(str)
  return num or default
end

local function ensureFuel(minFuel)
  if turtle.getFuelLevel() < minFuel then
    print("Refueling...")
    turtle.refuel()
  end
end

local function digAndMove()
  while turtle.detect() do turtle.dig(); sleep(0.2) end
  while not turtle.forward() do turtle.dig(); sleep(0.2) end
end

local function digColumn(height)
  for i = 1, height - 1 do
    while turtle.detectUp() do turtle.digUp(); sleep(0.2) end
    turtle.up()
  end
  for i = 1, height - 1 do
    turtle.down()
  end
end

local function returnToStart(width)
  turtle.turnLeft()
  for i = 1, width - 1 do
    turtle.forward()
  end
  turtle.turnRight()
end

-- Torch Placement
local function placeTorch()
  turtle.turnRight()
  turtle.turnRight()
  turtle.select(1) -- Torch slot
  turtle.place()
  turtle.turnRight()
  turtle.turnRight()
end

-- Inventory Cleanup (optional)
local function cleanInventory()
  for i = 2, 16 do
    turtle.select(i)
    turtle.drop()
  end
end

-- Save/Resume
local stateFile = "dig_tunnel.state"
local configFile = "dig_tunnel.cfg"

local function saveState(state)
  local file = fs.open(stateFile, "w")
  file.write(textutils.serialize(state))
  file.close()
end

local function loadState()
  if not fs.exists(stateFile) then return nil end
  local file = fs.open(stateFile, "r")
  local data = file.readAll()
  file.close()
  return textutils.unserialize(data)
end

local function clearState()
  if fs.exists(stateFile) then fs.delete(stateFile) end
end

-- Load or prompt for configuration
local function loadConfig(tArgs)
  local config = {}

  if fs.exists(configFile) then
    local file = fs.open(configFile, "r")
    config = textutils.unserialize(file.readAll())
    file.close()
  end

  config.length = tonumber(tArgs[1]) or config.length or toNumberOrDefault(prompt("Tunnel length"), 10)
  config.width  = tonumber(tArgs[2]) or config.width or toNumberOrDefault(prompt("Tunnel width"), 3)
  config.height = tonumber(tArgs[3]) or config.height or toNumberOrDefault(prompt("Tunnel height"), 3)
  config.placeTorches = config.placeTorches ~= false
  config.torchEvery = config.torchEvery or 5
  config.cleanup = config.cleanup or false
  config.offsetX = config.offsetX or 0
  config.offsetY = config.offsetY or 0
  config.offsetZ = config.offsetZ or 0
  return config
end

-- Main dig loop
local function digTunnel(config, startState)
  local len = config.length
  local width = config.width
  local height = config.height
  local placeTorches = config.placeTorches
  local torchEvery = config.torchEvery
  local cleanup = config.cleanup
  local state = startState or { step = 0 }

  for step = state.step + 1, len do
    print("Digging segment " .. step .. "/" .. len)

    for w = 0, width - 1 do
      if w > 0 then
        turtle.turnRight()
        turtle.forward()
        turtle.turnLeft()
      end
      digAndMove()
      digColumn(height)
      turtle.turnLeft()
      for i = 1, height - 1 do turtle.up() end
      for i = 1, height - 1 do turtle.down() end
      turtle.turnRight()

      if w > 0 then
        turtle.turnLeft()
        turtle.back()
        turtle.turnRight()
      end
    end

    -- Place torch every N segments
    if placeTorches and step % torchEvery == 0 then
      placeTorch()
    end

    if cleanup then cleanInventory() end

    digAndMove()
    saveState({ step = step })
  end

  print("Tunnel complete!")
  clearState()
end

-- Entry
local args = {...}
local config = loadConfig(args)
local startState = loadState()
ensureFuel(config.length * config.width * config.height)
digTunnel(config, startState)