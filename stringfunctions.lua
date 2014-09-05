-- Returns the index of the first occurance of the string 'chars' within the string 'str'.
-- Indices are 1-based, so the first character is index 1 and the last character is index str:len().
-- fromIndex (optional) determines the first character that will be searched, e.g. a fromIndex of 2 will only find matches occurring at index 2 or greater. The default is 1, which searches the entire string.
-- A negative fromIndex searches the string from end to beginning instead of beginning to end, returning the last occurance of 'chars' in 'str' instead of the first.
string.index = function (str, chars, fromIndex)
 
 str = tostring(str)
 chars = tostring(chars)
 
 if chars:len()==0 then
  error("chars must not be an empty string")
 end
 
 if fromIndex~=nil then
  if type(fromIndex)~="number" then
   error("fromIndex must be a number")
  end
  if fromIndex==0 then
   error("fromIndex must not be 0")
  end
 else
  fromIndex = 1
 end
 
 local charsLenOffset = chars:len()-1
 
 if math.abs(fromIndex)+charsLenOffset > str:len() then
  return 0
 end
 
 if fromIndex > 0 then
  
  for i = fromIndex, str:len()-charsLenOffset, 1 do
   if str:sub(i, i+charsLenOffset)==chars then
    return i
   end
  end
  
 else
  
  for i = str:len()+fromIndex+1-charsLenOffset, 1, -1 do
   if str:sub(i, i+charsLenOffset)==chars then
    return i
   end
  end
  
 end
 
 return 0
 
end

-- Divides str into substrings on each occurrance of sep, equivalent to string.split() in other languages.
-- Returns a table array containing the resulting substrings.
-- max (optional) limits the maximum number of substrings returned. The remainder of str will be included in the final substring. The default is nil (unlimited).
string.split = function (str, sep, max)
 
 local result = {}
 
 if max==nil then
  max = math.huge
 end
 
 str = tostring(str)
 sep = tostring(sep)
 max = tonumber(max)
 
 if sep:len()==0 then
  error("sep must not be an empty string")
 end
 
 if max < 1 then
  error("max must be at least 1")
 end
 
 if max==1 then
  result[1] = str
  return result
 end
 
 local i = 0
 local prev = 1
 while i = str:index(sep, prev) do
  
  if i==prev then
   result[#result+1] = ""
  else
   result[#result+1] = str:sub(prev, i-1)
  end
  
  prev = i+sep:len()
  
  if #result==max-1 then
   if prev > str:len() then
    result[#result+1] = ""
   else
    result[#result+1] = str:sub(prev, str:len())
   end
   return result
  end
  
 end
 
 return result
 
end