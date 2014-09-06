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
getfenv().liteway = {}

-- Version information
liteway.versionName = "Liteway 1.0 by John_Clarkson"
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
shell.setPath(shell.path()..":"..programsDir)
if not fs.exists(programsDir) then
 fs.makeDir(programsDir)
end
liteway.programsDir = programsDir

--
-- App settings files (for use by apps!)
--
 
local settingsDir = fs.combine(installDir, "settings")
if not fs.exists(settingsDir) then
 fs.makeDir(settingsDir)
end
liteway.settingsDir = settingsDir

-- Saves a string to the computer's filesystem so it can be loaded later with loadSettings().
-- Always begin the name with the name of your app to prevent conflicts!
-- e.g. liteway.saveSettings("myapp-settings", str)
liteway.saveSettings = function (name, str)
 local file = fs.open(fs.combine(settingsDir, filename),"w")
 file.write(str)
 file.close()
end

-- Returns a string saved with saveSettings(), or nil if no settings with that name exists.
liteway.loadSettings = function (name)
 local file = fs.open(fs.combine(settingsDir, filename),"r")
 local str = file.readAll()
 file.close()
 return str
end

--
-- Load Additional Libraries
--

local libs = {
 "backgroundevents",
 "stringfunctions"
}

for i = 1, #libs, 1 do
 shell.run(fs.combine(installDir, libs[i]))
end

--
-- Done
--
 
print(liteway.versionName)
