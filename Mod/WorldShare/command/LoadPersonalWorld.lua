--[[
Title: load personal world command
Author(s): big
Date: 2020/9/25
Desc: 
use the lib:
------------------------------------------------------------
local LoadPersonalWorldCommand = NPL.load('(gl)Mod/WorldShare/command/LoadPersonalWorld.lua')
-------------------------------------------------------
]]

-- load lib
local CmdParser = commonlib.gettable('MyCompany.Aries.Game.CmdParser')
local Commands = commonlib.gettable('MyCompany.Aries.Game.Commands')
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')

-- service
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/World.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')

-- UI
local SyncMain = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Main.lua')
local WorldList = NPL.load('(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua')
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')

local LoadPersonalWorldCommand = NPL.export()

function LoadPersonalWorldCommand:Init()
    local loadpersonalworld = {
        name='loadpersonalworld', 
        quick_ref='/loadpersonalworld -nosync [project_id]', 
        desc=[[]],
        mode_deny = '',
        handler = function(cmd_name, cmd_text, cmd_params)
            local option = ''
            local kpProjectId = 0
            local noSync = false

            option, cmd_text = CmdParser.ParseOption(cmd_text)

            if option == 'nosync' then
                noSync = true
            end

            kpProjectId, cmd_text = CmdParser.ParseInt(cmd_text)

            if not kpProjectId and type(kpProjectId) ~= 'number' then
                return
            end

            LoginModal:CheckSignedIn('请先登录', function(bSucceed)
                KeepworkServiceProject:GetProject(kpProjectId, function(data, err)
                    if not data or type(data) ~= 'table' or not data.username then
                        return false
                    end

                    local username = Mod.WorldShare.Store:Get('user/username')
                    
                    if data.username ~= username then
                        _guihelper.MessageBox(L'您正在试图加载的个人世界非您的个人世界，操作已被取消！')
                        return
                    end

                    if noSync then
                        KeepworkServiceWorld:SetWorldInstanceByPid(kpProjectId, function()
                            local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

                            if currentWorld and currentWorld.worldpath then
                                WorldCommon.OpenWorld(currentWorld.worldpath)
                            end
                        end)
                    else
                        KeepworkServiceWorld:SetWorldInstanceByPid(kpProjectId, function()
                            SyncMain:SyncToLocal(function()
                                local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

                                if currentWorld and currentWorld.worldpath then
                                    WorldCommon.OpenWorld(currentWorld.worldpath)
                                end
                            end, false)
                        end)
                    end
                end)
            end)
        end,
    }

    Commands['loadpersonalworld'] = loadpersonalworld

    return loadpersonalworld
end

