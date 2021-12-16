--[[
Title: reload world command
Author(s): big
Date: 2020.11.23
Desc: 
use the lib:
------------------------------------------------------------
local ReloadWorldCommand = NPL.load("(gl)Mod/WorldShare/command/ReloadWorld.lua")
-------------------------------------------------------
]]

-- load lib
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local RemoteWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteWorld')

local ReloadWorldCommand = NPL.export()

function ReloadWorldCommand:Init()
    local reloadworld = {
        name="reload", 
        quick_ref="/reload", 
        desc=[[]],
        mode_deny = "",
        handler = function(cmd_name, cmd_text, cmd_params)
            local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

            if not currentEnterWorld then
                return
            end

            if currentEnterWorld.is_zip then
                local remoteWorld = RemoteWorld.LoadFromHref(currentEnterWorld.remotefile, "self")
                Mod.WorldShare.Store:Set('world/reloadStatus', true)

                local worldpath = remoteWorld:GetLocalFileName()

                remoteWorld:DownloadRemoteFile(function(bSucceed, msg)
                    if bSucceed then
                        Game.Start(worldpath)
                    end
                end)
            else
                Mod.WorldShare.Store:Set('world/reloadStatus', true)
                WorldCommon.OpenWorld(currentEnterWorld.worldpath)
            end
        end,
    }

    Commands['reload'] = reloadworld

    return reloadworld
end

