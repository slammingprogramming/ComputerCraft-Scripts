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

-- Digs and moves in a direction for n blocks
local function tunnel(n, dir)
  n = n or 1
  dir = dir or "forward"
  for _ = 1, n do
    while detect(dir) do
      if not dig(dir) then
        error("Blocked by unbreakable block.")
      end
      sleep(0.4)
    end
    while not move(dir) do
      sleep(0.2)
    end
  end
end

local function turnRight()
  turtle.turnRight()
end

local function turnLeft()
  turtle.turnLeft()
end

local function uTurn()
  turnRight()
  turnRight()
end

--=======================
-- ROOM DIGGING LOGIC
--=======================

local function digRoom(length, width, height)
  for h = 1, height do
    for w = 1, width do
      tunnel(length - 1)

      if w ~= width then
        if (w % 2 == 1) then
          turnRight()
          tunnel()
          turnRight()
        else
          turnLeft()
          tunnel()
          turnLeft()
        end
      end
    end

    -- Return to front wall if needed
    if width % 2 == 1 then
      uTurn()
    end
    tunnel(length - 1)

    -- Move up a level if not last height
    if h ~= height then
      tunnel(1, "up")
    end
  end
end

--=======================
-- RETURN TO START
--=======================

local function returnHome(length, width, height)
  -- Return to bottom level
  tunnel(height - 1, "down")

  -- Return to origin on X-Y plane
  if (width % 2 == 1) then
    uTurn()
    tunnel(width - 1)
    turnRight()
  else
    turnRight()
    tunnel(1)
    turnRight()
    tunnel(width - 1)
  end

  tunnel(length - 1)
end

--=======================
-- MAIN EXECUTION
--=======================

print("Digging room ", LENGTH, "x", WIDTH, "x", HEIGHT, "...")
tunnel() -- initial move forward
digRoom(LENGTH, WIDTH, HEIGHT)
print("Returning to start...")
returnHome(LENGTH, WIDTH, HEIGHT)
print("Done.")
