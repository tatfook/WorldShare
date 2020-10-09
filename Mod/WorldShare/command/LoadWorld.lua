--[[
Title: load world command
Author(s): big
Date: 2020.10.9
Desc: 
use the lib:
------------------------------------------------------------
local LoadWorldCommand = NPL.load("(gl)Mod/WorldShare/command/LoadWorld.lua")
-------------------------------------------------------
]]

local LoadWorldCommand = NPL.export()

local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

function LoadWorldCommand:Init()
    -- cmd load world
    GameLogic.GetFilters():add_filter(
        "cmd_loadworld", 
        function(cmd_text, options)
            if options and options.personal then
                CommandManager:RunCommand("/loadpersonalworld " .. cmd_text)
                return
            end

            local refreshMode = nil

            if options and options.force then
                refreshMode = 'force'
            end

            local pid = UserConsole:GetProjectId(cmd_text)

            if pid then
                UserConsole:HandleWorldId(pid, refreshMode)
                return false
            else
                return cmd_text
            end
        end
    )
end
