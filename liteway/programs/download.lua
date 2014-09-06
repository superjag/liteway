local args = {...}

if #args > 2 then
 error("Too many arguments")
end

local url = args[1]
if args[1]==nil then
 print("URL required")
 return -1
end

if url:sub(1, 5):lower()~="http:" and url:sub(1, 6):lower()~="https:" then
 url = "http://"..url
end

local filename = args[2]
local hasFilename = filename~=nil
if filename==nil then
 
 filename = liteway.extractFilename(args[1])
 
 if filename:len() > 4 then
  if filename:sub(filename:len()-4):lower()==".lua" then
   filename = filename:sub(1, filename:len()-4)
  end
 end
 
end

print("Downloading "..filename.."...")

local response = http.get(url)
if response.getResponseCode()~=300 then
 print(response.getResponseCode()..": Download failed")
 return response.getResponseCode()
end

local fileContents = response.readAll()

print("Download complete")

if (not hasFilename) and fileContents:sub(1, 7) == "--name " and fileContents:sub(8, 8)~="\n" and fileContents:sub(8, 8)~="\r" then
 filename = ""
 local i = 8
 while i <= fileContents:len() do
  local char = fileContents:sub(i, i)
  if char~="\n" and char~="\r" then
   filename = filename..char
  else
   i = fileContents:len()
  end
  i = i + 1
 end
end

if file.exists(filename) then
 if not hasFilename then
  print("Saving as "..filename)
 end
 print("Error: File already exists")
 return
end

local file = fs.open(shell.resolve(filename), "w")
file.write(fileContents)
file.close()

if not hasFilename then
 print("Saved as "..filename)
end