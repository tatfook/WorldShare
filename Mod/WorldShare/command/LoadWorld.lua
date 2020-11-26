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
            if options and not options.s then
                local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                if currentEnterWorld then
                    _guihelper.MessageBox(
                        format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, cmd_text),
                        function(res)
                            if res and res == _guihelper.DialogResult.Yes then
                                local optionsStr = ''
    
                                for key, item in pairs(options) do
                                    if key ~= 's' then
                                        optionsStr = optionsStr .. '-' .. key .. ' '
                                    end
                                end
    
                                CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmd_text)
                            end
                        end,
                        _guihelper.MessageBoxButtons.YesNo
                    )
                    return false
                end
            end

            if options and options.personal then
                CommandManager:RunCommand("/loadpersonalworld " .. cmd_text)
                return false
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
