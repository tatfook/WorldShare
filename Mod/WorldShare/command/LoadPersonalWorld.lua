--[[
Title: load personal world command
Author(s): big
Date: 2020/9/25
Desc: 
use the lib:
------------------------------------------------------------
local LoadPersonalWorldCommand = NPL.load("(gl)Mod/WorldShare/command/LoadPersonalWorld.lua")
-------------------------------------------------------
]]

-- load lib
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser")
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

-- service
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/World.lua")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")

-- UI
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")

local LoadPersonalWorldCommand = NPL.export()

function LoadPersonalWorldCommand:Init()
    local loadpersonalworld = {
        name="loadpersonalworld", 
        quick_ref="/loadpersonalworld [project_id]", 
        desc=[[]],
        mode_deny = "",
        handler = function(cmd_name, cmd_text, cmd_params)
            local options;
            options, cmd_text = CmdParser.ParseOptions(cmd_text)

            if cmd_params and cmd_params.value then
                if type(cmd_params.value) ~= 'string' and type(cmd_params.value) ~= 'number' then
                    return false
                end

                local projectId = tonumber(cmd_params.value)

                if not projectId then
                    return false
                end

                LoginModal:CheckSignedIn("请先登录", function(bSucceed)
                    KeepworkServiceProject:GetProject(projectId, function(data, err)
                        if not data or type(data) ~= 'table' or not data.username then
                            return false
                        end
    
                        local username = Mod.WorldShare.Store:Get('user/username')
                        
                        if data.username ~= username then
                            _guihelper.MessageBox(L"您正在试图加载的个人世界非您的个人世界，操作已被取消！")
                            return
                        end
    
                        WorldList:RefreshCurrentServerList(function()
                            KeepworkServiceWorld:SetWorldInstanceByPid(projectId, function()
                                SyncMain:SyncToLocal(function()
                                    WorldList:EnterWorld()
                                end, false)
                            end)
                        end)
                    end)
                end)

            end
        end,
    }

    Commands['loadpersonalworld'] = loadpersonalworld

    return loadpersonalworld
end

