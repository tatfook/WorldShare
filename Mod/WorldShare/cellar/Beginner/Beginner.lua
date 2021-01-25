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
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')

local Beginner = NPL.export()

Beginner.inited = false
Beginner.guideWorldIds = { 40499, 40499, 40513, 40514, 40516 }

function Beginner:OnWorldLoad()
    if self.inited then
        return
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if currentEnterWorld and type(currentEnterWorld) == 'table' and currentEnterWorld.kpProjectId then
        if tonumber(currentEnterWorld.kpProjectId) == self:GetBeginnerWorldId() or
           tonumber(currentEnterWorld.kpProjectId) == self:GetGuideWorldId() then
            return
        end

        if self:InGuideWorld(tonumber(currentEnterWorld.kpProjectId)) then
            return
        end
    end

    Mod.WorldShare.Utils.SetTimeOut(function()
        self:Show()
        self.inited = true
    end, 5000)
end

function Beginner:GetBeginnerWorldId()
    if KeepworkService:GetEnv() == 'ONLINE' then
        return 29477
    elseif KeepworkService:GetEnv() == 'RELEASE' then
        return 1376
    else
        return 0
    end
end

function Beginner:GetGuideWorldId()
    if KeepworkService:GetEnv() == 'ONLINE' then
        return 40499
    elseif KeepworkService:GetEnv() == 'RELEASE' then
        return 1457
    else
        return 0
    end
end

function Beginner:InGuideWorld(id)
    for key, item in ipairs(self.guideWorldIds) do
        if item == id then
            return true
        end
    end

    return false
end

function Beginner:Show(callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    if not KeepWorkItemManager.HasGSItem(60001) then
        _guihelper.MessageBox(
            L"是否进入新手教学？",
            function(res)
                if res and res == _guihelper.DialogResult.OK then
                    CommandManager:RunCommand('/loadworld -s -force ' .. self:GetBeginnerWorldId())
                end

                if res and res == _guihelper.DialogResult.Cancel then
                    if callback and type(callback) == 'function' then
                        callback()
                    end
                end
            end,
            _guihelper.MessageBoxButtons.OKCancel_CustomLabel
        )

        return
    end

    if not KeepWorkItemManager.HasGSItem(60007) then
        _guihelper.MessageBox(
            L"是否参观3D校园？",
            function(res)
                if res and res == _guihelper.DialogResult.OK then
                    CommandManager:RunCommand('/loadworld -s -force ' .. self:GetGuideWorldId())
                end

                if res and res == _guihelper.DialogResult.Cancel then
                    if callback and type(callback) == 'function' then
                        callback()
                    end
                end
            end,
            _guihelper.MessageBoxButtons.OKCancel_CustomLabel
        )

        return
    end
end
