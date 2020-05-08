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

-- UI
local SyncMain = NPL.load("../Main.lua")

-- service
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local Screen = commonlib.gettable("System.Windows.Screen")

local Progress = NPL.export()

Progress.syncInstance = {}
Progress.current = 0
Progress.msg = ''
Progress.finish = false
Progress.broke = false

function Progress:Init(syncInstance)
    local progressParams = Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/WorldShare/cellar/Sync/Progress/Progress.html", "Progress", 0, 0, "_fi", false, 9)
    local operateParams = Mod.WorldShare.Utils.ShowWindow(270, 65, "Mod/WorldShare/cellar/Sync/Progress/Operate.html", "ProgressOperate", 230, -150 ,"_ct", false, 10)

    if not progressParams._page or not operateParams._page then
        return false
    end

    progressParams._page.OnClose = function()
        operateParams._page:CloseWindow()
        Mod.WorldShare.Store:Remove("page/Progress")
        Mod.WorldShare.Store:Remove("page/ProgressOperate")
    end

    Mod.WorldShare.Store:Set("page/Progress", progressParams._page)
    Mod.WorldShare.Store:Set("page/ProgressOperate", operateParams._page)

    self.syncInstance = syncInstance

    self.current = 0
    self.total = 0
    self.msg = L"同步中，请稍后..."
    self.finish = false
    self.broke = false

    self:Refresh()

    Screen:Connect("sizeChanged", self, self.OnScreenSizeChange, "UniqueConnection")
end

function Progress:OnScreenSizeChange()
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if ProgressPage then
        ProgressPage:Rebuild()
    end
end

function Progress:GetProgressBar()
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

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

function Progress:RefreshOperate()
    local ProgressOperatePage = Mod.WorldShare.Store:Get("page/ProgressOperate")

    if ProgressOperatePage then
        ProgressOperatePage:Refresh(0.01)
    end
end

function Progress:ClosePage()
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if ProgressPage then
        ProgressPage:CloseWindow()

        self.syncInstance:Close()
    end
end

function Progress:Cancel(callback)
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage or not self.syncInstance then
        return false
    end

    self.syncInstance:SetBroke(true)

    Mod.WorldShare.MsgBox:Show(L"正在等待上次同步完成，请稍后...", nil, nil, 380, 130, 11)

    self.broke = true
    self.finish = true

    local function CheckFinish()
        if not self.syncInstance.finish then
            Mod.WorldShare.Utils.SetTimeOut(
                function()
                    CheckFinish()
                end,
                100
            )
            return false
        end

        Mod.WorldShare.MsgBox:Close()
        self:ClosePage()

        if type(callback) == "function" then
            callback()
        end
    end

    CheckFinish()
end

function Progress:Retry()
    self:Cancel(function()
        Compare:Init(function(result)
            if not result then
                GameLogic.AddBBS(nil, L"同步失败", 3000, "255 0 0")
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

function Progress:UpdateDataBar(current, total, msg)
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    self.current = current
    self.total = total
    self.msg = msg

    if not msg then
        self.msg = L"同步中，请稍后..."
    end

    LOG.std("Progress", "debug", "Progress", format("Totals : %s , Current : %s, Status : %s", self.total, self.current, self.msg))

    ProgressPage:Rebuild()
end

function Progress:Copy(url)
    ParaMisc.CopyTextToClipboard(url)
end

function Progress:GetCurrent()
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    return self.current
end

function Progress:GetTotal()
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    return self.total
end

function Progress:GetMsg()
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    return self.msg
end

function Progress:SetFinish(value)
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    self.finish = value
end

function Progress:GetFinish()
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    return self.finish
end

function Progress:SetBroke(value)
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    self.broke = value
end

function Progress:GetBroke()
    local ProgressPage = Mod.WorldShare.Store:Get("page/Progress")

    if not ProgressPage then
        return false
    end

    return self.broke
end
