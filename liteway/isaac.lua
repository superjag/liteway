--[[
 * Ported by Jonathan A. Graef (mc user John_Clarkson)
 * from isaac.js by Yves-Marie K. Rinquin, which is
 * licensed under the following terms:
 * ----------------------------------------------------------------------
 * Copyright (c) 2012 Yves-Marie K. Rinquin
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ----------------------------------------------------------------------
 *
 * ISAAC is a cryptographically secure pseudo-random number generator
 * (or CSPRNG for short) designed by Robert J. Jenkins Jr. in 1996 and
 * based on RC4. It is designed for speed and security.
 *
 * ISAAC's informations & analysis:
 *   http://burtleburtle.net/bob/rand/isaac.html
 * ISAAC's implementation details:
 *   http://burtleburtle.net/bob/rand/isaacafa.html
 *
 * ISAAC succesfully passed TestU01
 *
 * ----------------------------------------------------------------------
 *
 * Usage:
 *   local random_number = isaac.random();
 *
 * Output: [ 0x00000000; 0xffffffff]
 *         [-2147483648; 2147483647]
 *
 *
--]]

-- Never load as API
if not shell then
 error("The Isaac API must be loaded with shell.run()")
 return
end

-- Only initialize once
if os.liteway.isaac then
 print("Isaac API is already loaded")
 return
end

local isaac = {}
os.liteway.isaac = isaac
isaac.__index = isaac
 
function isaac.create(initialSeed)
 local rng = {}
 setmetatable(rng,isaac)
 
 -- internal states
 rng.m = {} -- internal memory
 rng.acc = 0 -- accumulator
 rng.brs = 0 -- last result
 rng.cnt = 0 -- counter
 rng.r = {} -- result array
 rng.gnt = 0 -- generation counter
 
 if initialSeed~=nil then
  rng:seed(initialSeed)
 else
  rng:seed(os.time() * (0xffffffff / 24))
 end
 
 return rng
end
 
function isaac.stringToIntArray(s)
 local i = 1
 local r = {}
 local l = s:len()
 s = s.."\0\0\0"
 while i<=l do
  r[#r+1] = s:byte(i) + s:byte(i+1)*0x100 + s:byte(i+2)*0x10000 + s:byte(i+3)*0x1000000
  i = i+4
 end
 return r
end
 
-- 32-bit integer safe adder
local function add(x,y)
 local lsb = bit.band(x,0xffff) + bit.band(y,0xffff)
 local msb = bit.blogic_rshift(x,16) + bit.blogic_rshift(y,16) + bit.blogic_rshift(lsb,16)
 return bit.bor(bit.blshift(msb,16),bit.band(lsb,0xffff))
end
 
-- initialization
function isaac:reset()
 local i
 self.acc = 0
 self.brs = 0
 self.cnt = 0
 for i = 1, 256, 1 do
  self.m[i] = 0
  self.r[i] = 0
 end
 self.gnt = 0
end
 
-- seeding function
function isaac:seed(s)
 local i
 local a = 0x9e3779b9 -- the golden ratio
 local b = 0x9e3779b9
 local c = 0x9e3779b9
 local d = 0x9e3779b9
 local e = 0x9e3779b9
 local f = 0x9e3779b9
 local g = 0x9e3779b9
 local h = 0x9e3779b9
 
 if type(s)=="string" then
  s = isaac.stringToIntArray(s)
 elseif type(s)=="number" then
  s = {math.floor(s)}
 end
 
 if type(s)=="table" then
  self:reset()
  for i = 1, #s, 1 do
   self.r[bit.band(i,0xff)] = self.r[bit.band(i,0xff)] + s[i]
  end
 end
 
 -- seed mixer
 local function seed_mix()
 
  a = bit.bxor(a,bit.blshift(b,11))
  d = add(d,a)
  b = add(b,c)
 
  b = bit.bxor(b,bit.blogic_rshift(c,2))
  e = add(e,b)
  c = add(c,d)
 
  c = bit.bxor(c,bit.blshift(d,8))
  f = add(f,c)
  d = add(d,e)
 
  d = bit.bxor(d,bit.blogic_rshift(e,16))
  g = add(g,d)
  e = add(e,f)
 
  e = bit.bxor(e,bit.blshift(f,10))
  h = add(h,e)
  f = add(f,g)
 
  f = bit.bxor(f,bit.blogic_rshift(g,4))
  a = add(a,f)
  g = add(g,h)
 
  g = bit.bxor(g,bit.blshift(h,8))
  b = add(b,g)
  h = add(h,a)
 
  h = bit.bxor(h,bit.blogic_rshift(a,9))
  c = add(c,h)
  a = add(a,b)
 
 end
 
 for i = 1, 4, 1 do -- scramble it
  seed_mix()
 end
 
 for i = 1, 256, 8 do
  if s~=nil then -- use all the information in the seed
   a = add(a,self.r[i+0])
   b = add(b,self.r[i+1])
   c = add(c,self.r[i+2])
   d = add(d,self.r[i+3])
   e = add(e,self.r[i+4])
   f = add(f,self.r[i+5])
   g = add(g,self.r[i+6])
   h = add(h,self.r[i+7])
  end
  seed_mix()
  -- fill in m[] with messy stuff
  self.m[i+0] = a
  self.m[i+1] = b
  self.m[i+2] = c
  self.m[i+3] = d
  self.m[i+4] = e
  self.m[i+5] = f
  self.m[i+6] = g
  self.m[i+7] = h
 end
 if s~=nil then
  -- do a second pass to make all of the seed affect all of m[]
  for i = 1, 256, 8 do
   a = add(a,self.m[i+0])
   b = add(b,self.m[i+1])
   c = add(c,self.m[i+2])
   d = add(d,self.m[i+3])
   e = add(e,self.m[i+4])
   f = add(f,self.m[i+5])
   g = add(g,self.m[i+6])
   h = add(h,self.m[i+7])
   seed_mix()
  -- fill in m[] with messy stuff (again)
  self.m[i+0] = a
  self.m[i+1] = b
  self.m[i+2] = c
  self.m[i+3] = d
  self.m[i+4] = e
  self.m[i+5] = f
  self.m[i+6] = g
  self.m[i+7] = h
  end
 end
 
 self:prng() -- fill in the first set of results
 self.gnt = 256 -- prepare to use the first set of results
end
 
-- isaac generator, n = number of run
function isaac:prng(n)
 local i
 local x
 local y
 
 if type(n)=="number" then
  n = math.abs(math.floor(n))
 else
  n = 1
 end
 
 while n>0 do
  n = n-1
  self.cnt = add(self.cnt,1)
  self.brs = add(self.brs,self.cnt)
 
  for i = 0, 255, 1 do
   if bit.band(i,3)==0 then
    self.acc = bit.bxor(self.acc,bit.blshift(self.acc,13))
   elseif bit.band(i,3)==1 then
    self.acc = bit.bxor(self.acc,bit.blogic_rshift(self.acc,6))
   elseif bit.band(i,3)==2 then
    self.acc = bit.bxor(self.acc,bit.blshift(self.acc,2))
   else
    self.acc = bit.bxor(self.acc,bit.blogic_rshift(self.acc,16))
   end
   self.acc = add(self.m[bit.band(i + 128,0xff) + 1],self.acc)
   x = self.m[i + 1]
   y = add(self.m[bit.band(bit.blogic_rshift(x,2),0xff) + 1],add(self.acc,self.brs))
   self.m[i + 1] = y
   self.brs = add(self.m[bit.band(bit.blogic_rshift(y,10),0xff) + 1],x)
   self.r[i + 1] = self.brs
  end
 end
end
 
-- return a random number between
function isaac:rand()
 self.gnt = self.gnt-1
 if self.gnt<0 then
  self:prng()
  self.gnt = 255
 end
 return self.r[self.gnt+1]
end
 
-- global rng for convenience
local globalRng = isaac.create()
 
-- output
function isaac:random()
 if self~=nil then
  return self:rand() * 2.3283064365386963e-10 -- 2^-32
 else
  return globalRng:random()
 end
end
