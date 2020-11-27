--[[
Title: Beginner
Author(s):  big
Date: 2020.11.27
Desc: 
use the lib:
------------------------------------------------------------
local Beginner = NPL.load("(gl)Mod/WorldShare/cellar/Beginner/Beginner.lua")
------------------------------------------------------------
]]

-- libs
local KeepWorkItemManager = NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua')
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

local Beginner = NPL.export()

Beginner.inited = false

function Beginner:OnWorldLoad()
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    if not self.inited and not KeepWorkItemManager.HasGSItem(60000) then
        Mod.WorldShare.Utils.SetTimeOut(function()
            KeepWorkItemManager.DoExtendedCost(40000)
            _guihelper.MessageBox(
                L"是否进入新手教学？",
                function(res)
                    if res and res == _guihelper.DialogResult.Yes then
                        CommandManager:RunCommand('/loadworld -s 29477')
                        self.inited = true
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo
            )
        end, 3000)
    end
end
