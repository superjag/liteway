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
if args[2]==nil then

 filename = args[1]
 
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

print("Download complete")

local file = fs.open(shell.resolve(filename), "w")
file.write(response.readAll())
file.close()
