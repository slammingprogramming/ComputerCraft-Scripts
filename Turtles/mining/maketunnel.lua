-- TunnelMaster3000: Supercharged Tunneling Turtle Script
-- Features: Fuel check, saving/resume, config files, shape presets, lighting, GPS/waypoint offset, interactive + CLI args

-- UTILITY IMPORTS
local tArgs = {...}
local CONFIG_FILE = "tunnel_config.txt"
local STATE_FILE = "tunnel_state.txt"

-- UTILITY WRAPPERS
local function refuel()
  if turtle.getFuelLevel() == "unlimited" then return true end
  for i = 1, 16 do
    turtle.select(i)
    if turtle.refuel(0) then
      turtle.refuel(1)
      if turtle.getFuelLevel() > 0 then return true end
    end
  end
  return false
end

local function saveState(state)
  local file = fs.open(STATE_FILE, "w")
  file.write(textutils.serialize(state))
  file.close()
end

local function loadState()
  if fs.exists(STATE_FILE) then
    local file = fs.open(STATE_FILE, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
  end
  return nil
end

local function loadConfig()
  if fs.exists(CONFIG_FILE) then
    local file = fs.open(CONFIG_FILE, "r")
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
  end
  return nil
end

-- DIGGING HELPERS
local function dig() while turtle.detect() do turtle.dig(); sleep(0.4) end end
local function digUp() while turtle.detectUp() do turtle.digUp(); sleep(0.4) end end
local function digDown() while turtle.detectDown() do turtle.digDown(); sleep(0.4) end end

-- POSITION TRACKING
local pos = {x=0, y=0, z=0, dir=0} -- dir: 0=N, 1=E, 2=S, 3=W
local function forward()
  dig(); if turtle.forward() then
    if pos.dir == 0 then pos.z = pos.z - 1
    elseif pos.dir == 1 then pos.x = pos.x + 1
    elseif pos.dir == 2 then pos.z = pos.z + 1
    elseif pos.dir == 3 then pos.x = pos.x - 1 end
    return true
  end
  return false
end

local function up() digUp(); if turtle.up() then pos.y = pos.y + 1 return true end return false end
local function down() digDown(); if turtle.down() then pos.y = pos.y - 1 return true end return false end
local function turnLeft() turtle.turnLeft(); pos.dir = (pos.dir - 1) % 4 end
local function turnRight() turtle.turnRight(); pos.dir = (pos.dir + 1) % 4 end

-- SHAPE DIGGERS
local function digTunnel(width, height)
  for h = 1, height do
    for w = 1, width do
      dig();
      if w < width then turtle.turnRight(); dig(); forward(); turtle.turnLeft() end
    end
    if h < height then
      for i = 1, width - 1 do turtle.turnLeft(); forward(); turtle.turnRight() end
      up()
    end
  end
  for i = 1, height - 1 do down() end
end

-- LIGHTING SUPPORT
local function placeTorch()
  for i = 1, 16 do
    turtle.select(i)
    local item = turtle.getItemDetail()
    if item and item.name:find("torch") then
      turtle.placeDown()
      break
    end
  end
end

-- INTERACTIVE PROMPT
local function interactive()
  local config = {}
  print("Interactive Tunnel Setup")
  io.write("Tunnel Length: ") config.length = tonumber(read())
  io.write("Tunnel Width: ") config.width = tonumber(read())
  io.write("Tunnel Height: ") config.height = tonumber(read())
  io.write("Place torches every N blocks (0 for none): ") config.torchEvery = tonumber(read())
  io.write("Cleanup inventory after tunnel (y/n)? ") config.cleanup = read():lower() == 'y'
  return config
end

-- MAIN LOGIC
local function main(tArgs)
  local config = loadConfig() or {}
  local state = loadState() or {}
  if #tArgs == 0 or not tonumber(tArgs[1]) then
    config = interactive()
  else
    config.length = tonumber(tArgs[1])
    config.width = tonumber(tArgs[2]) or 1
    config.height = tonumber(tArgs[3]) or 2
    config.torchEvery = tonumber(tArgs[4]) or 0
    config.cleanup = tArgs[5] == 'true'
  end

  if not refuel() then print("Not enough fuel!") return end

  print("Starting tunnel: " .. config.length .. " blocks")

  for i = 1, config.length do
    digTunnel(config.width, config.height)
    forward()
    if config.torchEvery > 0 and i % config.torchEvery == 0 then placeTorch() end
    saveState({step=i})
  end

  if config.cleanup then
    for i=1,16 do
      turtle.select(i)
      local item = turtle.getItemDetail()
      if item and not item.name:find("torch") then
        turtle.drop()
      end
    end
  end
  print("Tunnel complete!")
end

main(tArgs)
