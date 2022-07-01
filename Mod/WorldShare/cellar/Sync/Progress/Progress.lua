--[[
Title: Progress
Author(s):  big
Date: 2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
local Progress = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Progress/Progress.lua')
------------------------------------------------------------
]]

-- UI
local SyncWorld = NPL.load('../SyncWorld.lua')

-- service
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceProject.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

-- libs
local Screen = commonlib.gettable('System.Windows.Screen')

local Progress = NPL.export()

Progress.syncInstance = {}
Progress.current = 0
Progress.msg = ''
Progress.finish = false
Progress.broke = false

function Progress:Init(syncInstance)
    self.syncInstance = syncInstance

    self.current = 0
    self.total = 0
    self.msg = L'同步中，请稍候...'
    self.finish = false
    self.broke = false

    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')
    local ProgressOperatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress.ProgressOperate')

    if ProgressPage then
        ProgressPage:CloseWindow()
    end

    if ProgressOperatePage then
        ProgressOperatePage:CloseWindow()
    end

    local progressParams = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/Sync/Progress/Theme/Progress.html',
        'Mod.WorldShare.Progress',
        0,
        0,
        '_fi',
        false,
        2,
        nil,
        false
    )

    local operateParams = Mod.WorldShare.Utils.ShowWindow(
        270,
        65,
        'Mod/WorldShare/cellar/Sync/Progress/Theme/Operate.html',
        'Mod.WorldShare.Progress.ProgressOperate',
        270,
        -150,
        '_ct',
        false,
        4,
        nil,
        false
    )

    if not progressParams._page or not operateParams._page then
        return
    end

    progressParams._page.OnClose = function()
        operateParams._page:CloseWindow()
        Mod.WorldShare.Store:Remove('page/Mod.WorldShare.Progress')
        Mod.WorldShare.Store:Remove('page/Mod.WorldShare.Progress.ProgressOperate')
    end

    self:Refresh()

    Screen:Connect('sizeChanged', self, self.OnScreenSizeChange, 'UniqueConnection')
end

function Progress:ShowFinishPage()
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return
    end

    Mod.WorldShare.MsgBox:Wait()

    KeepworkServiceProject:GenerateMiniProgramCode(
        currentWorld.kpProjectId,
        function(bSucceed, wxacode)
            Mod.WorldShare.MsgBox:Close()

            Mod.WorldShare.Utils.ShowWindow(
                550,
                400,
                'Mod/WorldShare/cellar/Sync/Progress/Theme/Finish.html?wxacode=' .. (wxacode or ''),
                'Mod.WorldShare.Progress.Finish'
            )
        end
    )
end

function Progress:OnScreenSizeChange()
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if ProgressPage then
        ProgressPage:Rebuild()
    end
end

function Progress:GetProgressBar()
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage then
        return
    end

    return ProgressPage:GetNode('progressbar')
end

function Progress:Refresh(delayTimeMs)
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if ProgressPage then
        ProgressPage:Refresh(delayTimeMs or 0.01)
    end
end

function Progress:RefreshOperate()
    local ProgressOperatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress.ProgressOperate')

    if ProgressOperatePage then
        ProgressOperatePage:Refresh(0.01)
    end
end

function Progress:ClosePage()
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if ProgressPage then
        ProgressPage:CloseWindow()
    end
end

function Progress:CloseFinishPage()
    local FinishPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress.Finish')

    if FinishPage then
        FinishPage:CloseWindow()

        if self.syncInstance and self.syncInstance.Close then
            self.syncInstance:Close()
        end
    end
end

function Progress:Cancel(callback)
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage or not self.syncInstance then
        return false
    end

    self.syncInstance:SetBroke(true)

    Mod.WorldShare.MsgBox:Show(L'正在等待上次同步完成，请稍候...', 8000, nil, 380, 130, 11)

    self.broke = true
    self.finish = true

    local checkI = 0
    local checkTimer

    checkTimer = commonlib.Timer:new({
        callbackFunc = function()
            if not self.syncInstance.finish and
               checkI <= 7 then
                checkI = checkI + 1
                return
            end

            checkTimer:Change(nil, nil)

            self.syncInstance:SetFinish(true)

            Mod.WorldShare.MsgBox:Close()
            self:ClosePage()
        end
    })

    checkTimer:Change(0, 1000)
end

function Progress:Retry()
    self:Cancel(function()
        local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

        Compare:Init(currentWorld.worldpath, function(result)
            if not result then
                GameLogic.AddBBS(nil, L'同步失败', 3000, '255 0 0')
                return false
            end

            if result == Compare.JUSTLOCAL then
                SyncWorld:SyncToDataSource()
            end

            if result == Compare.JUSTREMOTE then
                SyncWorld:SyncToLocal()
            end

            if result == Compare.REMOTEBIGGER or result == Compare.LOCALBIGGER or result == Compare.EQUAL then
                SyncWorld:ShowStartSyncPage()
            end
        end)
    end)
end

function Progress:UpdateDataBar(current, total, msg)
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage then
        return
    end

    self.current = current
    self.total = total
    self.msg = msg

    if not msg then
        self.msg = L'同步中，请稍候...'
    end

    LOG.std('Progress', 'debug', 'Progress', format('Totals : %s , Current : %s, Status : %s', self.total, self.current, self.msg))

    if self:GetFinish() then
        self:ClosePage()
        self:ShowFinishPage()
    else
        ProgressPage:Rebuild()
    end
end

function Progress:Copy(url)
    ParaMisc.CopyTextToClipboard(url)
end

function Progress:GetCurrent()
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage then
        return
    end

    return self.current
end

function Progress:GetTotal()
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage then
        return
    end

    return self.total
end

function Progress:GetMsg()
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage then
        return
    end

    return self.msg
end

function Progress:SetFinish(value)
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage then
        return
    end

    self.finish = value
end

function Progress:GetFinish()
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage then
        return
    end

    return self.finish
end

function Progress:SetBroke(value)
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage then
        return
    end

    self.broke = value
end

function Progress:GetBroke()
    local ProgressPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Progress')

    if not ProgressPage then
        return
    end

    return self.broke
end
