--[[
Title: Validated
Author(s): big
Date: 2019.09.24
Desc: 
-------------------------------------------------------
local Validated = NPL.load("(gl)Mod/WorldShare/helper/Validated.lua")
-------------------------------------------------------
]]

local Validated = NPL.export()

function Validated:Account(str)
    if not str or #str == 0 then
        return false
    else
        return true
    end
end

function Validated:Email(str)
    if not string.find(str, "^%s*[%w%._%-]+@[%w%.%-]+%.[%a]+%s*$") then
        return false
    else
        return true
    end
end

function Validated:Phone(str)
    if not string.find(tostring(str), "^%d%d%d%d%d%d%d%d%d%d%d$") then
        return false
    else
        return true
    end
end

function Validated:Password(str)
    if not str or
       type(str) ~= "string" or
       str == '' or
       #str < 6 or
       #str > 64 then
        return false
    else
        return true
    end
end