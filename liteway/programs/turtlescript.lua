--name turtlescript

local version = "TurtleScript 0.3"
local args = {...}
local firstProgram = true

if turtlescript==nil then
 getfenv().turtlescript = {}
end

local performAction = function (action,iterations,errorMsg,...)
 local i = 1
 while i<=iterations do
  if not action(...) then
   if turtle.getFuelLevel()==0 then
    error("Out of fuel")
   else
    print(errorMsg)
    print("Path is obstructed")
   end
   while not action(...) do
    sleep(1)
   end
  end
  i = i+1
 end
end

local selectSlot = function (instruction)
 if tonumber(instruction[2])~=nil then
  turtle.select(tonumber(instruction[2]))
 elseif tonumber(instruction[3])~=nil then
  turtle.select(tonumber(instruction[3]))
 else
  turtle.select(1)
 end
end

turtlescript.run = function (script)

local instructions = {}
local loopCounters = {}
local labels = {}
local stack = {}
local i

i = 1
local offset = 1
while offset<=script:len() do
 local instruction = {""}
 while offset<=script:len() do
  local char = script:sub(offset,offset)
  offset = offset+1
  if char==":" then
   instruction[#instruction+1] = ""
  elseif char==" " or char=="\r" or char=="\n" then
   break
  else
   instruction[#instruction] = instruction[#instruction]..char
  end
 end
 
 if instruction[1]:len()~=0 then
  instruction[1] = instruction[1]:lower()
  instructions[#instructions+1] = instruction
  
  -- Labels
  if instruction[1]=="label" then
   local labelName = instruction[2]:lower()
   if labels[labelName] then
    error("Duplicate label "..instruction[2])
   end
   labels[labelName] = #instructions
  end
  
  -- Movement
  if instruction[2]==nil then
   local letter = instruction[1]:sub(1,1)
   if letter=="f" or letter=="b" or letter=="l" or letter=="r" or letter=="u" or letter=="d" then
    local offset = 2
    while offset<=instruction[1]:len() and instruction[1]:sub(offset,offset)==letter do
     offset = offset+1
    end
    if offset>instruction[1]:len() then
     instruction[2] = instruction[1]:len()
     instruction[1] = letter
    end
   end
  end
  if instruction[1]=="f" or instruction[1]=="forward" or instruction[1]=="forwards" or instruction[1]=="b" or instruction[1]=="back" or instruction[1]=="backward" or instruction[1]=="backwards" or instruction[1]=="l" or instruction[1]=="left" or instruction[1]=="r" or instruction[1]=="right" or instruction[1]=="u" or instruction[1]=="up" or instruction[1]=="d" or instruction[1]=="down" then
   if instruction[2]==nil then
    instruction[2] = 1
   else
    if tonumber(instruction[2])==nil then
     error("Invalid instruction "..table.concat(instruction,":"))
    end
    instruction[2] = tonumber(instruction[2])
   end
   instruction[1] = instruction[1]:sub(1,1)
  end
  
 end
 i = i+1
end

--print(textutils.serialize(instructions))

if firstProgram then
 print("Performing task...")
 firstProgram = false
end

local rhino = turtle
local resumeFilename = nil

function setupResume(filename, allowResume)
 if resumeFilename~=nil then
  fs.delete(resumeFilename)
 end
 resumeFilename = filename
 if filename==nil then
  return
 end
 if rhinoresume==nil then
  error("RhinoResume not found: Did you install liteway?")
 end
 rhino = rhinoresume.fileTracker(resumeFilename, allowResume)
 rhino.add("parameters", function (...)
  return ...
 end)
 offset = rhino.parameters(offset)
 local slot = rhino.parameters(turtle.getSelectedSlot())
 if turtle.getSelectedSlot() ~= slot then
  turtle.select(slot)
 end
 stack = {rhino.parameters(table.unpack(stack))}
 i = rhino.parameters(i)
end

i = 1
while instructions[i]~=nil do
 if resumeFilename ~= nil then
  setupResume(resumeFilename, false)
 end
 local instruction = instructions[i]
 
 -- Movement
 if instruction[1]=="f" or instruction[1]=="forward" or instruction[1]=="forwards" then
  performAction(turtle.forward,instruction[2],"Can't go forward",1)
 elseif instruction[1]=="b" or instruction[1]=="back" or instruction[1]=="backward" or instruction[1]=="backwards" then
  performAction(turtle.back,instruction[2],"Can't go backward",1)
 elseif instruction[1]=="l" or instruction[1]=="left" then
  performAction(turtle.turnLeft,instruction[2],"Can't turn left")
 elseif instruction[1]=="r" or instruction[1]=="right" then
  performAction(turtle.turnRight,instruction[2],"Can't turn right")
 elseif instruction[1]=="u" or instruction[1]=="up" then
  performAction(turtle.up,instruction[2],"Can't go up",1)
 elseif instruction[1]=="d" or instruction[1]=="down" then
  performAction(turtle.down,instruction[2],"Can't go down",1)
  
 -- Mining
 elseif instruction[1]=="mine" then
  selectSlot(instruction)
  if instruction[2]=="above" or instruction[2]=="up" or instruction[2]=="u" then
   turtle.digUp()
  elseif instruction[2]=="below" or instruction[2]=="down" or instruction[2]=="d" then
   turtle.digDown()
  else
   turtle.dig()
  end
  
 -- Sucking Items
 elseif instruction[1]=="suck" then
  --selectSlot(instruction)
  turtle.select(1)
  if instruction[2]=="above" or instruction[2]=="up" or instruction[2]=="u" or instruction[3]=="above" or instruction[3]=="up" or instruction[3]=="u" then
   turtle.suckUp()
  elseif instruction[2]=="below" or instruction[2]=="down" or instruction[2]=="d" or instruction[3]=="below" or instruction[3]=="down" or instruction[3]=="d" then
   turtle.suckDown()
  else
   turtle.suck()
  end
  
 -- Suck All Items (not just a stack)
 elseif instruction[1]=="loot" then
  selectSlot(instruction)
  if instruction[2]=="above" or instruction[2]=="up" or instruction[2]=="u" or instruction[3]=="above" or instruction[3]=="up" or instruction[3]=="u" then
   while turtle.suckUp() do end
  elseif instruction[2]=="below" or instruction[2]=="down" or instruction[2]=="d" or instruction[3]=="below" or instruction[3]=="down" or instruction[3]=="d" then
   while turtle.suckDown() do end
  else
   while turtle.suck() do end
  end
  
 -- Dropping Items
 elseif instruction[1]=="drop" or instruction[1]=="dump" then
  if instruction[1]=="drop" and instruction[2]==nil then
   error("You must specify which slot to drop items from e.g. drop:1")
  elseif instruction[1]=="dump" and instruction[2]==nil then
   local i
   for i = 1, 16, 1 do
    turtle.select(i)
    turtle.drop()
   end
  else
   turtle.select(tonumber(instruction[2]))
   if instruction[3] then
    turtle.drop(tonumber(instruction[3]))
   else
    turtle.drop()
   end
  end
  
 -- Placing Blocks
 elseif instruction[1]=="place" then
  if instruction[2]==nil or (tonumber(instruction[2])==nil and (instruction[3]==nil or tonumber(instruction[3])==nil)) then
   error("You must specify which inventory slot to place the block from")
  end
  local slot = tonumber(instruction[2])
  local direction = instruction[3]
  if slot==nil then
   slot = tonumber(instruction[3])
   direction = instruction[2]
  end
  turtle.select(slot)
  if direction~=nil then
   direction = string.lower(direction)
  end
  if direction=="above" or direction=="up" or direction=="u" then
   turtle.placeUp()
  elseif direction=="below" or direction=="down" or direction=="d" then
   turtle.placeDown()
  else
   turtle.place()
  end
  
 -- Crafting
 elseif instruction[1]=="craft" then
  if instruction[2]==nil then
   turtle.select(1)
  else
   turtle.select(tonumber(instruction[2]))
  end
  turtle.craft()
  
 -- Refueling
 elseif instruction[1]=="refuel" then
  if instruction[2]==nil then
   local slot
   for slot = 1, 16, 1 do
    turtle.select(slot)
    if turtle.refuel() then
     break
    end
   end
  elseif instruction[3]==nil then
   turtle.select(tonumber(instruction[2]))
   turtle.refuel()
  elseif instruction[2]:lower() == "any" then
   local fuelRequired = tonumber(instruction[3])
   local slot
   for slot = 1, 16, 1 do
    turtle.select(slot)
    while turtle.getFuelLevel()<fuelRequired and turtle.refuel(1) do end
   end
  else
   turtle.select(tonumber(instruction[2]))
   local fuelRequired = tonumber(instruction[3])
   while turtle.getFuelLevel()<fuelRequired and turtle.refuel(1) do end
  end
  
 -- If
 elseif instruction[1]=="if" then
  local condition = function(result)
   if not result then
    i = i+1
   end
  end

  if instruction[2]=="obstructed" then
   if instruction[3]=="above" or instruction[3]=="up" or instruction[3]=="u" then
    condition(turtle.detectUp())
   elseif instruction[3]=="below" or instruction[3]=="down" or instruction[3]=="d" then
    condition(turtle.detectDown())
   else
    condition(turtle.detect())
   end
   
  elseif instruction[2]=="unobstructed" then
   if instruction[3]=="above" or instruction[3]=="up" or instruction[3]=="u" then
    condition(not turtle.detectUp())
   elseif instruction[3]=="below" or instruction[3]=="down" or instruction[3]=="d" then
    condition(not turtle.detectDown())
   else
    condition(not turtle.detect())
   end
   
  elseif instruction[2]=="empty" then
   if instruction[3]~=nil then
    error("Invalid if:empty instruction")
   end
   local result = true
   local slotID
   for slotID = 1, 16, 1 do
    result = result and (turtle.getItemSpace(slotID)==64)
   end
   condition(result)
   
  elseif instruction[2]=="same" or instruction[2]=="different" then
   local inverted = instruction[2]=="different"
   if instruction[3]==nil or instruction[5]~=nil then
    error("Invalid if:"..instruction[2].." instruction")
   elseif instruction[4]==nil then
    turtle.select(tonumber(instruction[3]))
    condition(turtle.compare() ~= inverted)
   elseif tonumber(instruction[3])~=nil and tonumber(instruction[4])~=nil then
    turtle.select(tonumber(instruction[3]))
    condition(turtle.compareTo(tonumber(instruction[4])) ~= inverted)
   else
    local slot = tonumber(instruction[3])
    local direction = instruction[4]
    if slot==nil then
     slot = tonumber(instruction[4])
     direction = instruction[3]
    end
    if slot==nil then
      error("Invalid if:"..instruction[2].." instruction")
    end
    turtle.select(slot)
    direction = direction:lower()
    if direction=="above" or direction=="up" or direction=="u" then
     condition(turtle.compareUp() ~= inverted)
    elseif direction=="below" or direction=="down" or direction=="d" then
     condition(turtle.compareDown() ~= inverted)
    else
     condition(turtle.compare() ~= inverted)
    end
   end
   
  elseif instruction[2]=="fuel" and tonumber(instruction[3]) then
   turtle.select(tonumber(instruction[3]))
   condition(turtle.refuel(0))
   
  else
   error("Invalid instruction "..table.concat(instruction,":"))
  end
  
 -- Goto
 elseif instruction[1]=="goto" then
  if instruction[2]==nil then
   error("Goto instruction must specify a label to go to")
  elseif labels[instruction[2]:lower()]==nil then
   error("Invalid label specified by goto instruction")
  end
  stack[#stack+1] = i
  i = labels[instruction[2]:lower()]
  
 -- Return
 elseif instruction[1]=="return" then
  if #stack==0 then
   error("Nothing to return to")
  end
  i = stack[#stack]
  stack[#stack] = nil
  
 -- Loop
 elseif instruction[1]=="loop" then
  if instruction[2]==nil then
   i = 0
  else
   if loopCounters[i]==nil or loopCounters[i]<0 then
     loopCounters[i] = tonumber(instruction[2])-1
   end
   loopCounters[i] = loopCounters[i]-1
   if loopCounters[i]>=0 then
    if instruction[3]==nil then
     i = 0
    elseif labels[instruction[3]:lower()]==nil then
     error("Invalid label specified by loop instruction")
    else
     i = labels[instruction[3]:lower()]
    end
   end
  end
  
 -- Resume
 elseif instruction[1]=="resume" then
  setupResume()
  if instruction[2]~=nil then
   local filename = instruction[2]
   if filename:sub(#filename-6):upper()~=".RESUME" then
    filename = filename..".RESUME"
   end
   setupResume(filename, true)
  end
  
 -- Wait
 elseif instruction[1]=="wait" then
  if instruction[2]==nil or tonumber(instruction[2])==nil then
   error("Invalid wait command")
  end
  sleep(tonumber(instruction[2]))
  
 -- Run
 elseif instruction[1]=="run" then
  if instruction[2]==nil then
   error("You must specify a file to run e.g. run:mine4me")
  end
  local file = fs.open(shell.resolve(instruction[2]),"r")
  if file==nil then
   error("No file")
  end
  local program = file.readAll()
  file.close()
  turtlescript.run(program)
  
 -- Print
 --elseif instruction[1]=="say" then
  
  
 -- Comment
 elseif instruction[1]:sub(1,1)=="(" then
  while i<=#instructions and table.concat(instructions[i],":"):sub(table.concat(instructions[i],":"):len())~=")" do
   i = i+1
  end
  if i>#instructions then
   error("Unending comment")
  end
  
 -- Ignore labels
 elseif instruction[1]=="label" then
  
 -- Syntax Error
 else
  error("Invalid instruction "..table.concat(instruction,":"))
 end
 i = i+1
end

setupResume()

end

if args[1]==nil then
 firstProgram = false
 print(version)
else
 turtlescript.run(table.concat(args," "))
 print("Done")
end
