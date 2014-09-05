--name liteway
if fs.getName(shell.getRunningProgram())~="liteway" then
 error('Liteway o.s. file must be named "liteway"')
end

-- Always load as API
if shell then
 os.loadAPI(shell.getRunningProgram())
 return
end

-- Only initialize once
if liteway then
 print(liteway.versionName.." is already running")
 return
end

-- Version information
versionName = "Liteway 1.0 by John_Clarkson"
version = 1.0
 
-- Temporary storage space for use by apps. Data persists across app restarts, but is deleted when the computer restarts.
temp = {}
tmp = temp
 
-- Liteway main dir made available for those interested
installDir = shell.getRunningProgram()
installDir = installDir:sub(1,#installDir-#fs.getName(installDir))..""

-- Create the programs dir and add it to the shell path
programsDir = fs.combine(installDir, "programs")
shell.setPath(shell.path()..":"..programsDir)
if not fs.exists(programsDir) then
 fs.makeDir(programsDir)
end

--
-- App settings files (for use by apps!)
--
 
settingsDir = fs.combine(installDir, "settings")
if not fs.exists(settingsDir) then
 fs.makeDir(settingsDir)
end

-- Saves a string to the computer's filesystem so it can be loaded later with loadSettings().
-- Always begin the name with the name of your app to prevent conflicts!
-- e.g. liteway.saveSettings("myapp-settings", str)
function saveSettings(name, str)
 local file = fs.open(fs.combine(settingsDir, filename),"w")
 file.write(str)
 file.close()
end

-- Returns a string saved with saveSettings(), or nil if no settings with that name exists.
function loadSettings(name)
 local file = fs.open(fs.combine(settingsDir, filename),"r")
 local str = file.readAll()
 file.close()
 return str
end

--
-- Done
--
 
print(versionName)
