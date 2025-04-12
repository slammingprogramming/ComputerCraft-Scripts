local args = {...}
if #args ~= 3 then
  print("Usage: room <length> <width> <height>")
  print("Example: room 9 9 5")
  return
end

local LENGTH = tonumber(args[1])
local WIDTH  = tonumber(args[2])
local HEIGHT = tonumber(args[3])

--=======================
-- UTILITY FUNCTIONS
--=======================

local function validateDirection(dir)
  local valid = {forward=true, up=true, down=true}
  if not valid[dir] then
    error("Invalid direction '"..tostring(dir).."', must be 'forward', 'up', or 'down'")
  end
end

local function detect(dir)
  validateDirection(dir or "forward")
  return (dir == "up" and turtle.detectUp or dir == "down" and turtle.detectDown or turtle.detect)()
end

local function dig(dir)
  validateDirection(dir or "forward")
  return (dir == "up" and turtle.digUp or dir == "down" and turtle.digDown or turtle.dig)()
end

local function move(dir)
  validateDirection(dir or "forward")
  return (dir == "up" and turtle.up or dir == "down" and turtle.down or turtle.forward)()
end

-- Digs forward and up to make walkable path
local function smartDigForward()
  while detect() do
    dig()
    sleep(0.2)
  end
  while not move() do
    sleep(0.2)
  end
  if detect("up") then
    dig("up")
  end
end

-- Digs a walkable 2-block-high tunnel
local function walkableTunnel(n)
  for _ = 1, n do
    smartDigForward()
  end
end

local function turnRight() turtle.turnRight() end
local function turnLeft()  turtle.turnLeft() end
local function uTurn()     turtle.turnRight() turtle.turnRight() end

--=======================
-- ROOM DIGGING LOGIC
--=======================

local function digRoom(length, width, height)
  for h = 1, height do
    for w = 1, width do
      walkableTunnel(length - 1)

      if w ~= width then
        if (w % 2 == 1) then
          turnRight()
          smartDigForward()
          turnRight()
        else
          turnLeft()
          smartDigForward()
          turnLeft()
        end
      end
    end

    -- Return to starting wall
    if width % 2 == 1 then
      uTurn()
    end
    walkableTunnel(length - 1)

    -- Move up a level if not done
    if h ~= height then
      while detect("up") do dig("up") sleep(0.2) end
      while not move("up") do sleep(0.2) end
    end
  end
end

--=======================
-- RETURN TO START
--=======================

local function returnHome(length, width, height)
  -- Return to ground level
  for _ = 1, height - 1 do
    move("down")
  end

  -- Return to front corner
  if width % 2 == 1 then
    uTurn()
    walkableTunnel(width - 1)
    turnRight()
  else
    turnRight()
    smartDigForward()
    turnRight()
    walkableTunnel(width - 1)
  end

  walkableTunnel(length - 1)
end

--=======================
-- MAIN EXECUTION
--=======================

print("Digging walkable room ", LENGTH, "x", WIDTH, "x", HEIGHT, "...")
smartDigForward() -- move into room
digRoom(LENGTH, WIDTH, HEIGHT)
print("Returning to start...")
returnHome(LENGTH, WIDTH, HEIGHT)
print("Done.")
