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
 
 local resumeStatePointer = 1
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
    if resumeStatePointer > #resumeState then
     local value = func(...)
     streamWriteFunction(textutils.serialize({f = name, r = value}))
     return value
    else
     local resumeValue = textutils.unserialize(resumeState[resumeStatePointer])
     if resumeValue.f~=name then
      error("Resume call out of order: expected "..resumeValue.f.."(), but "..name.."() called")
     end
     resumeStatePointer = resumeStatePointer+1
     return resumeValue.r
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
 resumeTable.add("args", function (...) return ... end)
 
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
  
  local i = 1
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
  file = fs.open(path, "w")
  file.write("")
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