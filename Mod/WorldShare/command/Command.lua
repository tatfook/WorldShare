--[[
Title: Command
Author(s):  big
Date: 2019.01.02
place: Foshan
Desc: Registry world share command.
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/command/Command.lua")
------------------------------------------------------------
]]

function Registry(name)
    NPL.load("./" .. name .. ".lua")
end

Registry("SignIn")