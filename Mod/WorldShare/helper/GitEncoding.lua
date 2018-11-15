--[[
Title: EncodingGithub
Author(s):  big
Date:  2017.4.22
Desc: 
use the lib: corvent base32 and fit to github or gitlab
------------------------------------------------------------
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Encoding/basexx.lua")

local Encoding = commonlib.gettable("System.Encoding.basexx")

local GitEncoding = NPL.export()

function GitEncoding.Base32(text)
    if (text) then
        local notLetter = string.find(text, "[^a-zA-Z0-9]")

        if (notLetter) then
            text = Encoding.to_base32(text)

            text = "world_base32_" .. text
        else
            text = "world_" .. text
        end

        return text
    else
        return nil
    end
end

function GitEncoding.Unbase32(text)
    if (text) then
        local notLetter = string.find(text, "world_base32_")

        if (notLetter) then
            text = text:gsub("world_base32_", "")

            return Encoding.from_base32(text)
        else
            text = text:gsub("world_", "")

            return text
        end
    else
        return nil
    end
end