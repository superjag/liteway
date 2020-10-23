--name liteway

-- Never load as API
if not shell then
 error("The Liteway API must be loaded with shell.run()")
 return
end

-- Only initialize once
if liteway then
 print(liteway.versionName.." is already running")
 return
end
 
-- Create the global liteway object
liteway = {}

-- Version information
liteway.versionName = "Liteway 1.0"
liteway.version = 1.0
 
-- Temporary storage space for use by apps. Data persists across app restarts, but is deleted when the computer restarts.
liteway.temp = {}
liteway.tmp = liteway.temp
 
-- Liteway main dir made available for those interested
local installDir = shell.getRunningProgram()
installDir = installDir:sub(1,#installDir-#fs.getName(installDir))..""
liteway.installDir = installDir

-- Create the programs dir and add it to the shell path
local programsDir = fs.combine(installDir, "programs")
if not fs.exists(programsDir) then
 fs.makeDir(programsDir)
end
liteway.programsDir = programsDir
local shellPath = shell.path()
for i = 1, shellPath:len(), 1 do
 if shellPath:sub(i, i)=="." and
  (i==shellPath:len() or shellPath:sub(i+1, i+1)==":") and
  (i==1 or shellPath:sub(i-1, i-1)==":") then
  if i==shellPath:len() then
   shell.setPath(shellPath..":"..programsDir)
  else
   shell.setPath(shellPath:sub(1, i)..":"..programsDir..shellPath:sub(i+1, shellPath:len()))
  end
 end
end


--
-- App settings files (for use by apps!)
--
 
local settingsDir = fs.combine(installDir, "settings")
if not fs.exists(settingsDir) then
 fs.makeDir(settingsDir)
end
liteway.settingsDir = settingsDir

-- Saves a string or table to the computer's filesystem so it can be loaded later with loadSettings().
-- Always begin the name with the name of your app to prevent conflicts!
-- e.g. liteway.saveSettings("myapp-settings", str)
liteway.saveSettings = function (name, str)
 if str==nil then
  liteway.deleteSettings(name)
 end
 str = textutils.serialize(str)
 local file = fs.open(fs.combine(settingsDir, name),"w")
 file.write(str)
 file.close()
end

-- Returns a string or table saved with saveSettings(), or nil if no settings with that name exists.
liteway.loadSettings = function (name)
 if not file.exists(name) then
  return nil
 end
 local file = fs.open(fs.combine(settingsDir, name),"r")
 local str = file.readAll()
 file.close()
 return textutils.unserialize(str)
end

liteway.deleteSettings = function (name)
 fs.delete(fs.combine(settingsDir, name))
end

--
-- Function that tells you the filename portion of a url (very convenient!)
--

liteway.extractFilename = function (url)
 
 local filename = tostring(url)
 
 local index = filename:index("?")
 if index then
  filename = filename:sub(1, index-1)..""
 end
 
 index = filename:index("#")
 if index then
  filename = filename:sub(1, index-1)..""
 end
 
 while filename:index("/", -1)==filename:len() do
  filename = filename:sub(1, filename:len()-1)..""
 end
 
 filename = filename:sub(filename:index("/", -1)+1, filename:len())..""
 
 return filename
 
end

--
-- Load Additional Libraries
--
--print("1:"..tostring(liteway))

local libs = {
 "stringfunctions",
 "backgroundevents",
 "rhinoresume",
 --"navstar",
 "programs/turtlescript"
}

for i = 1, #libs, 1 do
 shell.run(fs.combine(installDir, libs[i]))
end

--
-- Done
--

print(liteway.versionName)
