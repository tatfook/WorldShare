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

-- UI
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")

-- service
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")

-- libs
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

local LoadWorldCommand = NPL.export()

function LoadWorldCommand:Init()
    -- cmd load world
    GameLogic.GetFilters():add_filter(
        "cmd_loadworld", 
        function(cmd_text, options)
            if options and not options.s then
                local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                if currentEnterWorld then
                    local pid = UserConsole:GetProjectId(cmd_text)
                    
                    if pid then
                        Mod.WorldShare.MsgBox:Show(L"请稍候...")
                        KeepworkServiceProject:GetProject(pid, function(data, err)
                            Mod.WorldShare.MsgBox:Close()
                            if err ~= 200 or not data or type(data) ~='table' or not data.name then
                                GameLogic.AddBBS(nil, L"无法找到该资源", 300, '255 0 0')
                                return
                            end

                            _guihelper.MessageBox(
                                format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, data.name),
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
                        end)
                    else
                        local worldname = L'自定义世界'

                        if cmd_text == 'home' then
                            worldname = L'家园'
                        end

                        _guihelper.MessageBox(
                            format(L"即将离开【%s】进入【%s】", currentEnterWorld.text, worldname),
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
                    end
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
