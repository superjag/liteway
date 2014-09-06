--name update

local args = {...}

if #args==0 then
 print("Must specify file to update")
 return
end

local filename = shell.resolve(table.concat(args, " "))

if not fs.exists(filename) or fs.isDir(filename) then
 print("No file")
 return
end

local updateURL = nil
local oldExternalFiles = {}
local updateCommands = {}

local file = fs.open(filename, "r")
local line = file.readLine()
while line~=nil do
 if line:sub(1, 13)=="--update-url " and line:len()>13 then
  if updateURL then
   print("Error: Multiple --update-urls")
   return
  end
  updateURL = line:sub(14, line:len())
 elseif line:sub(1, 17)=="--update-command " and line:len()>17 then
  if not updateURL then
   updateCommands[#updateCommands] = updateURL = line:sub(18, line:len())
  end
 elseif line:sub(1, 16)=="--external-file " and line:len()>16 then
  
 end
 line = file.readLine()
end