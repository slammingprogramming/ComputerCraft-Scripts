-- Supercharged Room Digger
-- Allows both CLI arguments and interactive prompts.
-- Supports offsets, center-based positioning, and advanced dig patterns.
-- Designed for ComputerCraft turtles.

-- ========== Utility Functions ==========

local function promptInput(promptText, default)
  io.write(promptText)
  if default then
    io.write(" [" .. tostring(default) .. "]")
  end
  io.write(": ")
  local input = read()
  return input ~= "" and input or default
end

local function parseArgsOrPrompt(tArgs)
  local params = {}

  -- Interactive fallback for missing args
  params.length = tonumber(tArgs[1]) or tonumber(promptInput("Room length", 9))
  params.width  = tonumber(tArgs[2]) or tonumber(promptInput("Room width", 9))
  params.height = tonumber(tArgs[3]) or tonumber(promptInput("Room height", 5))

  print("Use current position as center of room? (y/n)")
  local center = read()
  params.centered = center:lower() == "y"

  if not params.centered then
    params.offsetX = tonumber(promptInput("Offset X from current position (forward)", 0))
    params.offsetZ = tonumber(promptInput("Offset Z from current position (right)", 0))
  else
    params.offsetX = math.floor(params.length / 2)
    params.offsetZ = math.floor(params.width / 2)
  end

  return params
end

local function ensureFuel(requiredFuel)
  if turtle.getFuelLevel() < requiredFuel then
    print("Not enough fuel. Please refuel the turtle.")
    while turtle.getFuelLevel() < requiredFuel do
      turtle.select(1)
      if not turtle.refuel(1) then
        sleep(2)
      end
    end
  end
end

local function detect(direction)
  if direction == "up" then return turtle.detectUp()
  elseif direction == "down" then return turtle.detectDown()
  else return turtle.detect() end
end

local function dig(direction)
  if direction == "up" then return turtle.digUp()
  elseif direction == "down" then return turtle.digDown()
  else return turtle.dig() end
end

local function move(direction)
  if direction == "up" then return turtle.up()
  elseif direction == "down" then return turtle.down()
  else return turtle.forward() end
end

local function tunnel(length, direction)
  for i = 1, length do
    while detect(direction) do
      dig(direction)
      sleep(0.4)
    end
    move(direction)
  end
end

local function turnAround()
  turtle.turnLeft()
  turtle.turnLeft()
end

-- ========== Room Digging Core ==========

local function digRoom(params)
  local length = params.length
  local width  = params.width
  local height = params.height
  local offsetX = params.offsetX
  local offsetZ = params.offsetZ

  -- Fuel estimation: assume 3 moves per block (dig + travel + turn)
  local estimatedFuel = (length * width * height * 3)
  ensureFuel(estimatedFuel)

  print("Positioning for start...")

  -- Move to start position
  for _ = 1, offsetX do move("forward") end
  turtle.turnRight()
  for _ = 1, offsetZ do move("forward") end
  turtle.turnLeft()

  print("Digging room " .. length .. "x" .. width .. "x" .. height .. "...")

  for h = 1, height do
    for w = 1, width do
      tunnel(length - 1)

      if w < width then
        if w % 2 == 1 then
          turtle.turnRight()
          tunnel(1)
          turtle.turnRight()
        else
          turtle.turnLeft()
          tunnel(1)
          turtle.turnLeft()
        end
      end
    end
    if h < height then
      tunnel(1, "up")
      turnAround()
    end
  end

  print("Room excavation complete. Returning to origin...")
  for _ = 1, height - 1 do move("down") end
  turtle.turnRight()
  for _ = 1, offsetZ do move("forward") end
  turtle.turnLeft()
  for _ = 1, offsetX do move("back") end
end

-- ========== Entry Point ==========

local args = { ... }
local config = parseArgsOrPrompt(args)
digRoom(config)
