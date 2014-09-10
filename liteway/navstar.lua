--name navstar

--Always load as API
if shell then
 error("The NavStar API must be loaded with os.loadAPI()")
end

--
-- Movement Tracker
--

--[[
Usage:
local origin = navstar.setOrigin()
--move the turtle
local location = navstar.getLocation(origin)
]]--

function getLocation(origin)
 if origin==nil then
  return {
   x = location.x,
   y = location.y,
   z = location.z,
   f = getDirectionFacing()
  }
 else
  local globalX = origin.x+location.x
  local globalY = origin.y+location.y
  local globalZ = origin.z+location.z
  local facing = addFacings(origin.f, getDirectionFacing())
  local facingOffset = tostring(origin.f):upper()
  if facingOffset=="N" then
   return {
    x = globalX,
    y = globalY,
    z = globalZ,
    f = facing
   }
  elseif facingOffset=="E" then
   return {
    x = globalZ,
    y = globalY,
    z = -globalX,
    f = facing
   }
  elseif facingOffset=="S" then
   return {
    x = -globalX,
    y = globalY,
    z = -globalZ,
    f = facing
   }
  else --facingOffset=="W"
   return {
    x = -globalZ,
    y = globalY,
    z = globalX,
    f = facing
   }
  end
 end
end

--offset is the DESIRED CURRENT COORDINATES of your turtle, not the offset from the turtle to the origin!
function setOrigin(offset)

 local offsetCopy = {}
 if offset==nil or offset.x==nil then
  offsetCopy.x = 0
 else
  offsetCopy.x = tonumber(offset.x)
 end
 if offset==nil or offset.y==nil then
  offsetCopy.y = 0
 else
  offsetCopy.y = tonumber(offset.y)
 end
 if offset==nil or offset.z==nil then
  offsetCopy.z = 0
 else
  offsetCopy.z = tonumber(offset.z)
 end
 if offset==nil or offset.f==nil then
  offsetCopy.f = "N"
 else
  offsetCopy.f = tostring(offset.f):upper()
  if offsetCopy.f~="N" and offsetCopy.f~="E" and offsetCopy.f~="S" and offsetCopy.f~="W" then
   error("Invalid facing "..offset.f)
  end
 end
 
 local facing = getDirectionFacing()
 local facingOffset
 
 if offsetCopy.f=="N" then
  if facing=="N" then
   facingOffset = "N"
  elseif facing=="E" then
   facingOffset = "W"
  elseif facing=="S" then
   facingOffset = "S"
  else --facing=="W"
   facingOffset = "E"
  end
  return {
   x = offsetCopy.x-location.x,
   y = offsetCopy.y-location.y,
   z = offsetCopy.z-location.z,
   f = facingOffset
  }
  
 elseif offsetCopy.f=="E" then
  if facing=="N" then
   facingOffset = "E"
  elseif facing=="E" then
   facingOffset = "N"
  elseif facing=="S" then
   facingOffset = "W"
  else --facing=="W"
   facingOffset = "S"
  end
  return {
   x = offsetCopy.z-location.x,
   y = offsetCopy.y-location.y,
   z = -offsetCopy.x-location.z,
   f = facingOffset
  }
  
 elseif offsetCopy.f=="S" then
  if facing=="N" then
   facingOffset = "S"
  elseif facing=="E" then
   facingOffset = "E"
  elseif facing=="S" then
   facingOffset = "N"
  else --facing=="W"
   facingOffset = "W"
  end
  return {
   x = -offsetCopy.x-location.x,
   y = offsetCopy.y-location.y,
   z = -offsetCopy.z-location.z,
   f = facingOffset
  }
  
 else --offsetCopy.f=="W"
  if facing=="N" then
   facingOffset = "W"
  elseif facing=="E" then
   facingOffset = "S"
  elseif facing=="S" then
   facingOffset = "E"
  else --facing=="W"
   facingOffset = "N"
  end
  return {
   x = -offsetCopy.z-location.x,
   y = offsetCopy.y-location.y,
   z = offsetCopy.x-location.z,
   f = facingOffset
  }
  
 end
 
end

local function getDirectionFacing()
 local direction = "N"
 if location.xDir==1 then
  direction = "E"
 elseif location.zDir==1 then
  direction = "S"
 elseif location.xDir==-1 then
  direction = "W"
 end
 return direction
end

--Takes "N", "S", "E" or "W" and returns the xDir and zDir components
local function compassToComponents(direction)
 direction = tostring(direction):upper()
 if direction=="N" then
  return 0, -1
 elseif direction=="E" then
  return 1, 0
 elseif direction=="S" then
  return 0, 1
 elseif direction=="W" then
  return -1, 0
 else
  error("Invalid facing "..direction)
 end
end

function addFacings(direction1, direction2)
 direction1 = tostring(direction1):upper()
 direction2 = tostring(direction2):upper()
 if direction2~="N" and direction2~="E" and direction2~="S" and direction2~="W" then
  error("Invalid facing "..direction2)
 end
 if direction1=="N" then
  return direction2
 elseif direction1=="E" then
  if direction2=="N" then
   return "E"
  elseif direction2=="E" then
   return "S"
   elseif direction2=="S" then
  return "W"
  else --direction2=="W"
   return "N"
  end
 elseif direction1=="S" then
  if direction2=="N" then
   return "S"
  elseif direction2=="E" then
   return "W"
   elseif direction2=="S" then
  return "N"
  else --direction2=="W"
   return "E"
  end
 elseif direction1=="W" then
  if direction2=="N" then
   return "W"
  elseif direction2=="E" then
   return "N"
   elseif direction2=="S" then
  return "E"
  else --direction2=="W"
   return "S"
  end
 else
  error("Invalid facing "..direction1)
 end
end

local turtle_forward = turtle.forward
local turtle_back = turtle.back
local turtle_up = turtle.up
local turtle_down = turtle.down
local turtle_left = turtle.left
local turtle_right = turtle.right
local turtle_refuel = turtle.refuel

local location = {
 x = 0,
 y = 0,
 z = 0,
 xDir = 0,
 zDir = -1
}

local function saveCoords(movement)
 liteway.saveSettings("navstar-location", {
  location:location,
  fuel:turtle.getFuelLevel(),
  move:movement
 })
end

turtle.forward = function (...)
 saveCoords({x:location.xDir, y:0, z:location.zDir})
 if turtle_forward(...) then
  location.x = location.x+location.xDir
  location.z = location.z+location.zDir
 end
 --saveCoords()
end

turtle.back = function (...)
 saveCoords({x:-location.xDir, y:0, z:-location.zDir})
 if turtle_back(...) then
  location.x = location.x-location.xDir
  location.z = location.z-location.zDir
 end
 --saveCoords()
end

turtle.up = function (...)
 saveCoords({x:0, y:1, z:0})
 if turtle_up(...) then
  location.y = location.y+1
 end
 --saveCoords()
end

turtle.down = function (...)
 saveCoords({x:0, y:-1, z:0})
 if turtle_down(...) then
  location.y = location.y-1
 end
 --saveCoords()
end

turtle.left = function (...)
 saveCoords()
 turtle_left(...)
end

turtle.right = function (...)
 saveCoords()
 turtle_right(...)
end

turtle.refuel = function (...)
 turtle_refuel(...)
 saveCoords()
end

--
-- Restore coords on reboot
--

local loadedCoords = liteway.loadSettings("navstar-location")
if loadedCoords then
 location.x = loadedCoords.location.x
 location.y = loadedCoords.location.y
 location.z = loadedCoords.location.z
 location.xDir = loadedCoords.location.xDir
 location.zDir = loadedCoords.location.zDir
 local fuelLevel = turtle.getFuelLevel()
 if loadedCoords.fuel~=fuelLevel then
  if fuelLevel==loadedCoords.fuel-1 and loadedCoords.move then
   location.x = location.x+loadedCoords.move.x
   location.y = location.y+loadedCoords.move.y
   location.z = location.z+loadedCoords.move.z
  else
   print("Fuel tracking error: Did you move or refuel the turtle without loading navstar first?")
  end
 end
else
 saveCoords()
end