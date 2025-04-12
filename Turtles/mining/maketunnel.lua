-- Super Tunneler with Interactive Config and State Save/Resume
-- Turtle will mine tunnels with flexible dimensions and smart features.

local STATE_FILE = "tunnel_state"
local CONFIG_FILE = "tunnel_config.txt"

-- Utilities
local function prompt(msg, default)
  io.write(msg .. (default and (" [" .. default .. "]") or "") .. ": ")
  local input = read()
  if input == "" and default then return default end
  return input
end

local function saveState(state)
  local f = fs.open(STATE_FILE, "w")
  f.write(textutils.serialize(state))
  f.close()
end

local function loadState()
  if fs.exists(STATE_FILE) then
    local f = fs.open(STATE_FILE, "r")
    local state = textutils.unserialize(f.readAll())
    f.close()
    return state
  end
  return nil
end

local function clearState()
  if fs.exists(STATE_FILE) then fs.delete(STATE_FILE) end
end

local function refuelIfNeeded()
  if turtle.getFuelLevel() == "unlimited" then return true end
  if turtle.getFuelLevel() < 100 then
    for i = 1, 16 do
      turtle.select(i)
      if turtle.refuel(1) then
        print("Refueled.")
        return true
      end
    end
    print("⚠️ Low fuel and no fuel items found.")
    return false
  end
  return true
end

local function placeTorch()
  for i = 1, 16 do
    turtle.select(i)
    local detail = turtle.getItemDetail()
    if detail and (detail.name:lower():find("torch") or detail.name:lower():find("lantern")) then
      turtle.placeDown()
      return
    end
  end
end

local function cleanInventory()
  for i = 1, 16 do
    turtle.select(i)
    local detail = turtle.getItemDetail()
    if detail and not (detail.name:lower():find("torch") or detail.name:lower():find("fuel")) then
      turtle.drop()
    end
  end
end

-- Tunnel Builder
local function digTunnel(config, startState)
  local len = config.length
  local width = config.width
  local height = config.height
  local torchEvery = config.torchEvery
  local placeTorches = config.placeTorches
  local cleanup = config.cleanup
  local offsetX = config.offsetX or 0
  local offsetY = config.offsetY or 0
  local offsetZ = config.offsetZ or 0

  local state = startState or { step = 0 }

  local function digBlock()
    while turtle.detect() do
      turtle.dig()
      sleep(0.2)
    end
  end

  local function digUp()
    while turtle.detectUp() do
      turtle.digUp()
      sleep(0.2)
    end
  end

  local function digDown()
    while turtle.detectDown() do
      turtle.digDown()
      sleep(0.2)
    end
  end

  local function moveForward()
    while not turtle.forward() do
      turtle.dig()
      sleep(0.2)
    end
  end

  -- Tunnel is dug from bottom-left corner, scanning row by row
  for step = state.step + 1, len do
    print("🚧 Digging section " .. step .. " / " .. len)

    for h = 0, height - 1 do
      for w = 0, width - 1 do
        -- Move to the correct horizontal offset
        if w > 0 then
          turtle.turnRight()
          moveForward()
          turtle.turnLeft()
        end

        -- Dig front, up, and down at this position
        digBlock()
        if h > 0 then
          for i = 1, h do
            turtle.up()
            digBlock()
            digUp()
          end

          for i = 1, h do
            turtle.down()
          end
        else
          digDown()
        end

        -- Move back to the original column if we moved sideways
        if w > 0 then
          turtle.turnLeft()
          turtle.back()
          turtle.turnRight()
        end
      end
    end

    -- Place torch
    if placeTorches and step % torchEvery == 0 then
      placeTorch()
    end

    -- Cleanup inventory if enabled
    if cleanup then cleanInventory() end

    -- Move forward one tunnel length
    moveForward()

    -- Save progress
    saveState({ step = step })
  end

  print("✅ Tunnel complete.")
  clearState()
end

-- Load config file (optional)
local function loadConfigFromFile(filename)
  if not fs.exists(filename) then return nil end
  local f = fs.open(filename, "r")
  local data = textutils.unserialize(f.readAll())
  f.close()
  return data
end

-- Main Entry
local args = {...}
local config = {}

-- Check for saved state
local savedState = loadState()
if savedState then
  print("⚠️ Resume previous session?")
  print("Y to resume, anything else to start new")
  local r = read()
  if r:lower() == "y" then
    config = loadConfigFromFile(CONFIG_FILE)
    if not config then
      print("❌ Config file missing. Cannot resume.")
      return
    end
    digTunnel(config, savedState)
    return
  else
    clearState()
  end
end

-- CLI arguments
local lengthArg = tonumber(args[1])
local widthArg = tonumber(args[2])
local heightArg = tonumber(args[3])

-- Interactive prompts if missing args
if not (lengthArg and widthArg and heightArg) then
  print("🛠 Tunnel Builder - Interactive Setup")
  config.length = tonumber(prompt("Tunnel length", "20"))
  config.width = tonumber(prompt("Tunnel width", "3"))
  config.height = tonumber(prompt("Tunnel height", "3"))
else
  config.length = lengthArg
  config.width = widthArg
  config.height = heightArg
end

config.placeTorches = prompt("Place torches? (y/n)", "y"):lower() == "y"
config.torchEvery = tonumber(prompt("Torch every N blocks", "5"))
config.cleanup = prompt("Drop blocks? (y/n)", "n"):lower() == "y"
config.offsetX = tonumber(prompt("X offset from turtle position", "0"))
config.offsetY = tonumber(prompt("Y offset (vertical)", "0"))
config.offsetZ = tonumber(prompt("Z offset (forward)", "0"))

-- Save config for future resume
local f = fs.open(CONFIG_FILE, "w")
f.write(textutils.serialize(config))
f.close()

if not refuelIfNeeded() then
  print("❌ Aborting due to low fuel.")
  return
end

-- Begin tunneling
digTunnel(config)
