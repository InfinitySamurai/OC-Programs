local component = require("component")
gen = component.generator
robot = require("robot")

positionx = 0
positiony = 0
positionz = 0
facing = 0
currentSelection = 1


function writeOut(message)
  print(message)
end


function checkResources()
  writeOut("Checking there are resources to build with....")
  for i=1,16 do
    if i == 16 then
      writeOut("Robot has no resources left to build with, please put new resources in to continue building.")
      io.read()
      currentSelection = 1
      robot.select(currentSelection)

    elseif robot.count(i) > 0 then
      writeOut("Found some blocks in slot "..i)
      currentSelection = i
      robot.select(currentSelection)
      return true

    else
      writeOut("Slot "..i.." is empty, trying next slot")
    end
    os.sleep(0.2)
  end
end


function checkFuel()
  fuelThreshold = 20

  while gen.count() < 20 do
    robot.select(16)
    ret, err = gen.insert()
    if(not ret) then
      writeOut(err)
      writeOut("Please rectify, and press enter")
      io.read()
      gen.insert()
    end
  end
  robot.select(currentSelection)
  writeOut("Succesful refuel!")
end


function placeBlock()

  if robot.detectDown() and not robot.compareDown() then
    robot.swingDown()
  end

  checkResources()
  robot.placeDown()
end


-- Navigation features
-- allow the turtle to move while tracking its position
-- this allows us to just give a destination point and have it go there
function turnRightTrack()

  robot.turnRight()
  facing = facing + 1
  if facing >= 4 then
    facing = 0
  end
end


function turnLeftTrack()

  robot.turnLeft()
  facing = facing - 1
  if facing < 0 then
    facing = 3
  end
end


function turnAroundTrack()
        turnLeftTrack()
        turnLeftTrack()
end


function safeForward()

  checkFuel()
  success = false
  while not success do
    success = robot.forward()
    if not success then
      while robot.detect() do
        if not robot.swing() then
          print("Blocked attempting to move forward.")
          print("Please clear and press enter to continue.")
          io.read()
        end
      end
    end
  end
end


function safeBack()

  checkFuel()
  success = false
  while not success do
    success = robot.back()
    if not success then
      turnAroundTrack();
      while robot.detect() do
        if not robot.swing() then
          break;
        end
      end
      turnAroundTrack()
      success = robot.back()
      if not success then
        print("Blocked attempting to move back.")
        print("Please clear and press enter to continue.")
        io.read()
      end
    end
  end
end


function safeUp()

  checkFuel()
  success = false
  while not success do
    success = robot.up()
    if not success then
      while robot.detectUp() do
        if not robot.swingUp() then
          print("Blocked attempting to move up.")
          print("Please clear and press enter to continue.")
          io.read()
        end
      end
    end
  end
end


function safeDown()

  checkFuel()
  success = false
  while not success do
    success = robot.down()
    if not success then
      while robot.detectDown() do
        if not robot.swingDown() then
          print("Blocked attempting to move down.")
          print("Please clear and press enter to continue.")
          io.read()
        end
      end
    end
  end
end


function moveY(targety)
  if targety == positiony then
    return
  end

  if (facing ~= 0 and facing ~= 2) then -- check axis
    turnRightTrack()
  end

  while targety > positiony do
    if facing == 0 then
      safeForward()
    else
      safeBack()
    end
    positiony = positiony + 1
  end

  while targety < positiony do
    if facing == 2 then
      safeForward()
    else
      safeBack()
    end
    positiony = positiony - 1
  end
end

function moveX(targetx)
  if targetx == positionx then
    return
  end

  if (facing ~= 1 and facing ~= 3) then -- check axis
    turnRightTrack()
  end

  while targetx > positionx do
    if facing == 1 then
      safeForward()
    else
      safeBack()
    end
    positionx = positionx + 1
  end

  while targetx < positionx do
    if facing == 3 then
      safeForward()
    else
      safeBack()
    end
    positionx = positionx - 1
  end
end


function moveZ(targetZ)
  if targetZ == positionz then
    return
  end
  while targetZ < positionz do
    safeDown()
    positionz = positionz - 1
  end
  while targetZ > positionz do
    safeUp()
    positionz = positionz + 1
  end
end


function navigateTo(targetX, targetY, targetZ, move_z_first)
  targetZ = targetZ or positionz -- If targetZ isn't used in the function call, it defaults to its current z position, this should make it compatible with all previous implementations of navigateTo()
  move_z_first = move_z_first or false -- Defaults to moving z last, if true is passed as 4th argument, it moves vertically first

  if move_z_first then
    moveZ(targetZ)
  end

  if facing == 0 or facing == 2 then -- Y axis
    moveY(targetY)
    moveX(targetX)
  else
    moveX(targetX)
    moveY(targetY)
  end

  if not move_z_first then
    moveZ(targetZ)
end
end


function line(length)
  if length <= 0 then
    error("Error, length can not be 0")
  end
  local i
  for i=1, length do
    placeBlock()
    if i ~= length then
      safeForward()
    end
  end
end


function rectangle(depth, width)
  if depth <= 0 then
    error("Error, depth can not be 0")
  end
  if width <= 0 then
    error("Error, width can not be 0")
  end
  local lengths = {depth, width, depth, width }
  local j
  for j=1,4 do
    line(lengths[j])
    turnRightTrack()
  end
end


function square(width)
  rectangle(width, width)
end


function wall(length, height)
  turnRightTrack()
  local i
  local j
  for i = 1, length do
    for j = 1, height do
      placeBlock()
      if j < height then
        safeUp()
      end
    end
    safeForward()
    for j = 1, height-1 do
      safeDown()
    end
  end
  turnLeftTrack()
end


function platform(x, y)
  local forward = true
  for cy = 0, y-1 do
    for cx = 0, x-1 do
      if forward then
        navigateTo(cx, cy)
      else
        navigateTo(x - cx - 1, cy)
      end
      placeBlock()
    end
    if forward then
      forward = false
    else
      forward = true
    end
  end
end


function stair(width, height)
  turnRightTrack()
  local cx=1
  local cy=0
  local goforward=0
  while cy < height do
    while cx < width do
      placeBlock()
      safeForward()
      cx = cx + 1
    end
    placeBlock()
    cx = 1
    cy = cy + 1
    if cy < height then
      if goforward == 1 then
        turnRightTrack()
        safeUp()
        safeForward()
        turnRightTrack()
        goforward = 0
      else
        turnLeftTrack()
        safeUp()
        safeForward()
        turnLeftTrack()
        goforward = 1
      end
    end
  end
end


function circle(diameter)
  odd = not (math.fmod(diameter, 2) == 0)
  radius = diameter / 2
  if odd then
    width = (2 * math.ceil(radius)) + 1
    offset = math.floor(width/2)
  else
    width = (2 * math.ceil(radius)) + 2
    offset = math.floor(width/2) - 0.5
  end
  --diameter --radius * 2 + 1
  sqrt3 = 3 ^ 0.5
  boundaryRadius = radius + 1.0
  boundary2 = boundaryRadius ^ 2
  radius2 = radius ^ 2
  z = math.floor(radius)
  cz2 = (radius - z) ^ 2
  limitOffsetY = (boundary2 - cz2) ^ 0.5
  maxOffsetY = math.ceil(limitOffsetY)
  -- We do first the +x side, then the -x side to make movement efficient
  for side = 0,1 do
      -- On the right we go from small y to large y, on the left reversed
      -- This makes us travel clockwise (from below) around each layer
      if (side == 0) then
        yStart = math.floor(radius) - maxOffsetY
        yEnd = math.floor(radius) + maxOffsetY
        yStep = 1
      else
        yStart = math.floor(radius) + maxOffsetY
        yEnd = math.floor(radius) - maxOffsetY
        yStep = -1
      end
      for y = yStart,yEnd,yStep do
        cy2 = (radius - y) ^ 2
        remainder2 = (boundary2 - cz2 - cy2)
        if remainder2 >= 0 then
          -- This is the maximum difference in x from the centre we can be without definitely being outside the radius
          maxOffsetX = math.ceil((boundary2 - cz2 - cy2) ^ 0.5)
          -- Only do either the +x or -x side
          if (side == 0) then
            -- +x side
            xStart = math.floor(radius)
            xEnd = math.floor(radius) + maxOffsetX
          else
            -- -x side
            xStart = math.floor(radius) - maxOffsetX
            xEnd = math.floor(radius) - 1
          end
          -- Reverse direction we traverse xs when in -y side
          if y > math.floor(radius) then
            temp = xStart
            xStart = xEnd
            xEnd = temp
            xStep = -1
          else
            xStep = 1
          end

          for x = xStart,xEnd,xStep do
            -- Only blocks within the radius but still within 1 3d-diagonal block of the edge are eligible
            if isSphereBorder(offset, x, y, z, radius2) then
              navigateTo(x, y)
              placeBlock()
            end
          end
        end
      end
    end
end


function blockInSphereIsFull(offset, x, y, z, radiusSq)
  x = x - offset
  y = y - offset
  z = z - offset
  x = x ^ 2
  y = y ^ 2
  z = z ^ 2
  return x + y + z <= radiusSq
end

function isSphereBorder(offset, x, y, z, radiusSq)
  spot = blockInSphereIsFull(offset, x, y, z, radiusSq)
  if spot then
    spot = not blockInSphereIsFull(offset, x, y - 1, z, radiusSq) or
      not blockInSphereIsFull(offset, x, y + 1, z, radiusSq) or
      not blockInSphereIsFull(offset, x - 1, y, z, radiusSq) or
      not blockInSphereIsFull(offset, x + 1, y, z, radiusSq) or
      not blockInSphereIsFull(offset, x, y, z - 1, radiusSq) or
      not blockInSphereIsFull(offset, x, y, z + 1, radiusSq)
  end
  return spot
end

function cylinder(diameter, height)
  for i = 1, height do
    circle(diameter)
    if i ~= height then
      navigateTo(positionx, positiony, positionz + 1)
    end
  end
end


writeOut("Shape Maker 1.1. Created by Michiel using a bit of Vliekkie's code")
writeOut("Fixed and made readable by Aeolun ;)")
writeOut("Ported to OpenComputers by InfinitySamurai")
writeOut("");
writeOut("What should be built?")
writeOut("+---------+-----------+-------+-------+")
writeOut("| line    | rectangle | wall  | room  |")
writeOut("| square  | platform  | stair | dome  |")
writeOut("| pyramid | cylinder  | circle|       |")
writeOut("+---------+-----------+-------+-------+")
writeOut("")


local choice = io.read()
writeOut("Building a "..choice)

if choice == "line" then --fixed
  writeOut("How long does the line need to be?")
  local ll = io.read()
  ll = tonumber(ll)
  line(ll)

elseif choice == "rectangle" then -- fixed
  writeOut("How deep do you want it to be?")
  h = io.read()
  h = tonumber(h)
  writeOut("How wide do you want it to be?")
  v = io.read()
  v = tonumber(v)
  rectangle(h, v)

elseif choice == "square" then --fixed
  writeOut("How long does it need to be?")
  local s = io.read()
  s = tonumber(s)
  square(s)

elseif choice == "wall" then --fixed
        writeOut("How long does it need to be?")
        local wl = io.read()
        wl = tonumber(wl)
        writeOut("How high does it need to be?")
        local wh = io.read()
        wh = tonumber(wh)
        if  wh <= 0 then
                error("Error, the height can not be zero")
        end
        if wl <= 0 then
                error("Error, the length can not be 0")
        end
        wall(wl, wh)

elseif choice == "platform" then
        writeOut("How long do you want it to be?")
        x = io.read()
        x = tonumber(x)
        writeOut("How wide do you want it to be?")
        y = io.read()
        y = tonumber(y)
        platform(x, y)
        writeOut("Done")

elseif choice == "stair" then --fixed
        writeOut("How wide do you want it to be?")
        x = io.read()
        x = tonumber(x)
        writeOut("How high do you want it to be?")
        y = io.read()
        y = tonumber(y)
        stair(x, y)
        writeOut("Done")

elseif choice == "circle" then
        writeOut("What radius do you need it to be?")
        local rad = io.read()
        rad = tonumber(rad)
        circle(rad)
elseif choice == "cylinder" then
  local diameter = 0
  local height = 0
  writeOut("What diameter does it need to be?")
  diameter = io.read()
  writeOut("How high does it need to be?")
  height = io.read()
  cylinder(diameter, height)

else
  navigateTo(3,3,3)
end
