--[[
Title: Progress
Author(s):  big
Date: 2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
local Progress = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Progress.lua")
------------------------------------------------------------
]]
local SyncMain = NPL.load("../Main.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local Progress = NPL.export()

function Progress:Init(instance)
    local params = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/WorldShare/cellar/Sync/Progress/Progress.html", "Progress", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Store:Remove("page/Progress")
    end

    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    ProgressPage.instance = instance
    ProgressPage.current = 0
    ProgressPage.total = 0
    ProgressPage.msg = L"同步中，请稍后..."
    ProgressPage.finish = false
    ProgressPage.broke = false

    self:Refresh()
end

function Progress:SetPage()
    Mod.WorldShare.Store:Set("page/Progress", document:GetPageCtrl())
end

function Progress:GetProgressBar()
    local ProgressPage = Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    return ProgressPage:GetNode("progressbar")
end

function Progress:Refresh(delayTimeMs)
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if ProgressPage then
        ProgressPage:Refresh(delayTimeMs or 0.01)
    end
end

function Progress:ClosePage()
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if ProgressPage then
        ProgressPage:CloseWindow()

        local callback = Mod.WorldShare.Store:Get("world/CloseProgress")

        if type(callback) == 'function' then
            callback()
            Mod.WorldShare.Store:Remove("world/CloseProgress")
        end
    end
end

function Progress:Cancel(callback)
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage or not ProgressPage.instance then
        return false
    end

    ProgressPage.instance:SetBroke(true)
    ProgressPage.msg = L"正在等待上次同步完成，请稍后..."
    ProgressPage.broke = true
    ProgressPage.finish = true

    Progress:Refresh()

    local function CheckFinish()
        Mod.WorldShare.Utils.SetTimeOut(
            function()
                if not ProgressPage.finish then
                    CheckFinish()
                    return false
                end

                ProgressPage.instance:SetFinish(true)
                self:ClosePage()
                Mod.WorldShare.MsgBox:Close()

                if type(callback) == "function" then
                    callback()
                end
            end,
            1000
        )
    end

    CheckFinish()
end

function Progress:Retry()
    self:Cancel(function()
        Compare:Init(function(result)
            if not result then
                GameLogic.AddBBS(nil, L"同步失败", 3000, "255 0 0")
                Mod.WorldShare.MsgBox:Close()
                return false
            end

            if result == Compare.JUSTLOCAL then
                SyncMain:SyncToDataSource()
            end

            if result == Compare.JUSTREMOTE then
                SyncMain:SyncToLocal()
            end

            if result == Compare.REMOTEBIGGER or result == Compare.LOCALBIGGER or result == Compare.EQUAL then
                SyncMain:ShowStartSyncPage()
            end
        end)
    end)
end

function Progress:UpdateDataBar(current, total, msg, finish)
    local ProgressPage = Store:Get("page/Progress")

    if (not ProgressPage) then
        return false
    end

    if (ProgressPage.broke) then
        return false
    end

    ProgressPage.current = current
    ProgressPage.total = total
    ProgressPage.msg = msg
    ProgressPage.finish = finish

    if (not msg) then
        ProgressPage.msg = L"同步中，请稍后..."
    end

    LOG.std("Progress", "debug", "Progress", format("Totals : %s , Current : %s, Status : %s", total, current, msg))

    if (not self:GetProgressBar()) then
        return false
    end

    self:GetProgressBar():SetAttribute("Maximum", total)
    self:GetProgressBar():SetAttribute("Value", current)
    self:Refresh()
end

function Progress:Copy(url)
    ParaMisc.CopyTextToClipboard(url)
end

function Progress:GetCurrent()
    local ProgressPage = Store:Get("page/Progress")

    if (not ProgressPage) then
        return false
    end

    return ProgressPage.current
end

function Progress:GetTotal()
    local ProgressPage = Store:Get("page/Progress")

    if (not ProgressPage) then
        return false
    end

    return ProgressPage.total
end

function Progress:GetMsg()
    local ProgressPage = Store:Get("page/Progress")

    if (not ProgressPage) then
        return false
    end

    return ProgressPage.msg
end

function Progress:GetFinish()
    local ProgressPage = Store:Get("page/Progress")

    if (not ProgressPage) then
        return false
    end

    return ProgressPage.finish
end

function Progress:GetBroke()
    local ProgressPage = Store:Get("page/Progress")

    if (not ProgressPage) then
        return false
    end

    return ProgressPage.broke
end

function Progress:SetBroke(value)
    local ProgressPage = Store:Get("page/Progress")

    if (not ProgressPage) then
        return false
    end

    ProgressPage.broke = value
end

function Progress:SetFinish(value)
    local ProgressPage = Store:Get("page/Progress")

    if (not ProgressPage) then
        return false
    end

    ProgressPage.finish = value
end