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
    if not str or
       type(str) ~= 'string' or
       str == '' or
       #str <= 3 or
       #str > 20  then
        return false
    else
        -- contains digits or characters
        if string.match(str, '%a+') or string.match(str, '%d+') then
            if string.match(str, '^%d+') then
                return false
            else
                return true
            end
        else
            return false
        end
    end
end

function Validated:AccountCompatible(str)
    if not str or
       type(str) ~= 'string' or
       str == '' or
       #str <= 3 or
       #str > 20  then
        return false
    else
        -- contains digits and characters
        if string.match(str, '%a+') or string.match(str, '%d+') then
            return true
        else
            return false
        end
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
       #str < 4 or
       #str > 24 then
        return false
    else
        return true
    end
end