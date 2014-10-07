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
  
  if type(func)=="string" then
   local swap = name
   name = func
   func = swap
  end
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
     
     -- call function and record it in the resume state
     
     streamWriteFunction("~"..name)
     local value
     local replacer = __replace[func]
     if replacer then
      value = replacer(false, resumeTable, ...)
     else
      value = func(...)
     end
     streamWriteFunction("="..textutils.serialize(value))
     return value
     
    else
     
     -- ignore function call while resuming
     
     local function skipRecursiveCall()
      if resumeStatePointer <= #resumeState and resumeState[resumeStatePointer]:sub(1,1)=="~" then
       resumeStatePointer = resumeStatePointer+1
       while skipRecursiveCall() do
        resumeStatePointer = resumeStatePointer+1
       end
       return true
      else
       return false
      end
     end
     
     resumeStatePointer = resumeStatePointer+1
     if resumeState[resumeStatePointer]~="~"..name then
      error("Resume call out of order: expected "..resumeState[resumeStatePointer].."(), but "..name.."() called")
     end
     
     local startPointer = resumeStatePointer
     skipRecursiveCall()
     
     if resumeStatePointer <= #resumeState then
      if resumeState[resumeStatePointer]:sub(1,1)~="=" then
       error("Internal rhinoresume error: Unmatched return value encountered in resume stream.")
      end
      return textutils.unserialize(resumeState[resumeStatePointer]:sub(2).."")
     else
      local replacer = __replace[func]
      if replacer then
       resumeStatePointer = startPointer+1
       local value = replacer(true, resumeTable)
       if resumeStatePointer < #resumeState then
        error("Recursive resume call not called")
       end
       streamWriteFunction("="..textutils.serialize(value))
       return value
      else
       streamWriteFunction("="..textutils.serialize(nil))
       return nil
      end
     end
     
     
     
     
     if resumeStatePointer < #resumeState then
      return textutils.unserialize(resumeState[resumeStatePointer]:sub(2).."")
     else
      local replacer = __replace[func]
      if replacer then
       local value = replacer(true, resumeTable)
       streamWriteFunction("="..textutils.serialize(value))
       return value
      else
       streamWriteFunction("="..textutils.serialize(nil))
       return nil
      end
     end
     
    end
   end
   
   resumeTable[name] = proxy
   return proxy
   
  elseif type(func)=="table" then
   
   local addedItems = {}
   for key,value in pairs(func) do
    if type(value)=="function" then
     addedItems[key] = add(name..key, value)
    end
   end
   return addedItems
   
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


--
-- File Tracker (wrapper function)
--

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
   local length = data:sub(i, string.index(data, "\n", i)-1)
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

--
-- String Compare
--

-- Compares two strings case-insensitively
-- Has absolutely nothing to do with resume functionality; it is intended to be used in conjunction with fileTracker():
-- local tracker = rhinoresume.fileTracker("resume.progress", rhinoresume.stringCompare("resume", ...))
function stringCompare(str1, str2, arg3)
 if type(str1)~="string" or type(str2)~="string" then
  return false
 end
 if str1:lower()==str2:lower() then
  if arg3~=nil then
   error("Too many arguments")
  end
  return true
 end
 return false
end

--
-- Default replacements
--

__replace = {}

local function addReplacement(forFunc)
 __replace[forFunc] = function (resuming, tracker, ...)
  local currentFuel = turtle.getFuelLevel()
  local fuel = tracker.args(currentFuel)
  if resuming then
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
