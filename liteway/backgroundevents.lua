--name background-events

local asyncListeners = {}
local osPullEventRaw = os.pullEventRaw

os.pullEventRaw = function (eventName)
 while true do
  local result = {osPullEventRaw()}
  if eventName~=nil and eventName~="terminate" and result[1] == "terminate" then
   error("Terminated", 0)
  end
  local listeners = asyncListeners[result[1]]
  if listeners~=nil then
   local i
   for i = 1, #listeners, 1 do
    listeners[i](unpack(result))
   end
  end
  if eventName==nil or eventName==result[1] then
   return unpack(result)
  end
 end
end

liteway.pullEventAsync = function (callback, ...)
 local args = {...}
 local i
 local j
 if callback==nil or type(callback)~="function" then
  error("No listener")
 end
 for i = 1, #args, 1 do
  if type(args[i])~="string" then
   error('Usage: os.pullEventAsync(callbackFunction, "event1", "event2", "eventN")')
  end
  local listenerDict = asyncListeners[args[i]]
  if listenerDict==nil then
   listenerDict = {}
   asyncListeners[args[i]] = listenerDict
  end
  local found = false
  for j = 1, #listenerDict, 1 do
   if listenerDict[j] == callback then
    found = true
    break
   end
  end
  if not found then
   listenerDict[#listenerDict+1] = callback
  end
 end
 return true
end
 
liteway.unpullEvent = function (callback, ...)
 local args = {...}
 local i
 local j
 if callback==nil or type(callback)~="function" then
  error("No listener")
 end
 for i = 1, #args, 1 do
  if type(args[i])~="string" then
   error('Usage: os.unpullEvent(callbackFunction, "event1", "event2", "eventN")')
  end
  local listenerDict = asyncListeners[args[i]]
  if listenerDict~=nil then
   for j = 1, #listenerDict, 1 do
    local found = false
    if listenerDict[j] == callback then
     found = true
    end
    if found then
     listenerDict[j] = listenerDict[j+1]
    end
   end
  end
 end
end

os.pullEventAsync = liteway.pullEventAsync
liteway.unpullEventAsync = liteway.unpullEvent
os.unpullEvent = liteway.unpullEvent
os.unpullEventAsync = liteway.unpullEvent
