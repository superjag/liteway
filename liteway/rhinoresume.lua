--name rhinoresume

--Always load as API
if shell then
 os.loadAPI(shell.getRunningProgram())
 return
end

function customTracker(streamWriteFunction, resumeState)
 
 if resumeState==nil then
  resumeState = {}
 end
 if type(resumeState)~="table" then
  error("resumeState must be a table array")
 end
 
 local resumeStatePointer = 0
 local resumeTable
 
 local function add (name, func)
  
  if func==nil then
   func = name
   name = ""
  else
   if name==nil then
    name = ""
   end
   name = tostring(name)
  end
  
  if type(func)=="function" then
   
   if name=="" then
    error("name required")
   end
   if resumeTable[name] then
    error("a resumable function named "..name.." already exists")
   end
   
   local function proxy(...)
    if resumeStatePointer >= #resumeState then
     streamWriteFunction(name)
     local value
     local replacer = __replace[func]
     if replacer then
      value = replacer(false, resumeTable, ...)
     else
      value = func(...)
     end
     streamWriteFunction(textutils.serialize(value))
     return value
    else
     resumeStatePointer = resumeStatePointer+1
     if resumeState[resumeStatePointer]~=name then
      error("Resume call out of order: expected "..resumeValue.f.."(), but "..name.."() called")
     end
     resumeStatePointer = resumeStatePointer+1
     if resumeStatePointer < #resumeState then
      return textutils.unserialize(resumeState[resumeStatePointer])
     else
      local replacer = __replace[func]
      if replacer then
       local value = replacer(true, resumeTable)
       streamWriteFunction(textutils.serialize(value))
       return value
      else
       streamWriteFunction(textutils.serialize(nil))
       return nil
      end
     end
    end
   end
   
   resumeTable[name] = proxy
   return proxy
   
  elseif type(func)=="table" then
   for key,value in pairs(func) do
    if type(value)=="function" then
     add(name..tostring(key), value)
    end
   end
   
  else
   error("Type error: add() accepts a function or table")
  end
  
 end
 
 resumeTable = {
  add = add
 }
 
 local function args (...)
  return ...
 end
 resumeTable.add("args", args)
 
 return resumeTable
 
end

function fileTracker(path, allowResume)

 local file
 local resumeState = {}
 local disposed = false
 
 if (allowResume==nil or allowResume) and fs.exists(path) then
  
  file = fs.open(path, "r")
  local data = file.readAll()
  file.close()
  
  if data:sub(1, 12):lower()~="rhinoresume\n" then
   error(path.." does not appear to be a rhinoresume file")
  end
  
  local i = 13
  while i < data:len() do
   local length = data:sub(i, data:index("\n", i)-1)
   i = i+length:len()+1
   length = tonumber(length)
   if length > 0 then
    resumeState[#resumeState+1] = data:sub(i, i+length-1)
    i = i+length+1
   else
    resumeState[#resumeState+1] = ""
    i = i+1
   end
  end
  
 else
  
  if fs.exists(path) then
   file = fs.open(path, "r")
   local firstLine = file.readLine()
   file.close()
   if firstLine:lower()~="rhinoresume" then
    error(path.." does not appear to be a rhinoresume file")
   end
  end
  
  file = fs.open(path, "w")
  file.write("rhinoresume\n")
  file.close()
  
 end
 
 local tracker = customTracker(
  function (data)
   if disposed then
    return
   end
   file = fs.open(path, "a")
   file.write(data:len().."\n")
   file.write(data.."\n")
   file.close()
  end,
  resumeState
 )
 
 tracker.dispose = function ()
   if disposed then
    return
   end
  disposed = true
  fs.delete(path)
 end
 
 return tracker
 
end

__replace = {}

local function addReplacement(forFunc)
 __replace[forFunc] = function (resuming, tracker, ...)
  local fuel = tracker.args(turtle.getFuelLevel())
  if resuming then
   local currentFuel = turtle.getFuelLevel()
   if currentFuel==fuel then
    return forFunc()
   elseif currentFuel==fuel-1 then
    return true
   else
    error("Fuel-based movement tracking failed")
   end
  else
   return forFunc()
  end
 end
end

addReplacement(turtle.forward)
addReplacement(turtle.back)
addReplacement(turtle.up)
addReplacement(turtle.down)

local function copyTable(t)
 local r = {}
 for key,value in pairs(func) do
  r[key] = value
 end
 return r
end
