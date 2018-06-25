--[[
Title: SyncGUI
Author(s):  big
Date: 	2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua")
local SyncGUI = commonlib.gettable("Mod.WorldShare.sync.SyncGUI")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncCompare.lua")

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local ShareWorld = commonlib.gettable("Mod.WorldShare.sync.ShareWorld")
local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")

local SyncGUI = commonlib.inherit(nil, commonlib.gettable("Mod.WorldShare.sync.SyncGUI"))

local SyncPage
local current = 0
local total = 0
local files = ""
local finish
local broke

function SyncGUI:ctor(sync)
    current = 0
    total = 0
    files = L "同步中，请稍后..."
    finish = false
    broke = false

    self.sync = sync

    Utils:ShowWindow(550, 320, "Mod/WorldShare/sync/SyncGUI.html", "SyncGUI")
end

function SyncGUI:OnInit()
    SyncPage = document:GetPageCtrl()
end

function SyncGUI:GetProgressBar()
    return SyncPage:GetNode("progressbar")
end

function SyncGUI:refresh(delayTimeMs)
    if (SyncPage) then
        SyncPage:Refresh(delayTimeMs or 0.01)
    end
end

function SyncGUI.closeWindow()
    if (SyncPage) then
        SyncPage:CloseWindow()
    end
end

function SyncGUI.cancel(callback)
    files = L "正在等待上次同步完成，请稍后..."
    self:SetBroke(true)
    self:refresh()

    local function checkFinish()
        Utils.SetTimeOut(
            function()
                if (self.sync.finish) then
                    checkFinish()
                else
                    self:CloseWindow()

                    if(type(callback) == 'function') then
                        callback()
                    end
                end
            end
        )
    end

    checkFinish()
end

function SyncGUI:retry()
    self.finish(
        function()
            SyncCompare:syncCompare()
        end
    )

    -- if (SyncMain.syncType == "sync") then
    --     SyncMain.syncCompare(true)
    -- elseif (SyncMain.syncType == "share") then
    --     ShareWorld.shareCompare()
    -- else
    --     SyncMain.syncCompare(true)
    -- end
end

function SyncGUI:updateDataBar(pCurrent, pTotal, pFiles, pFinish)
    current = pCurrent
    total = pTotal
    files = pFiles
    finish = pFinish

    if (not files) then
        files = L "同步中，请稍后..."
    end

    LOG.std("SyncGUI", "debug", "SyncGUI", format("Totals : %s , Current : %s, Status : %s", total, current, files))

    self:GetProgressBar():SetAttribute("Maximum", total)
    self:GetProgressBar():SetAttribute("Value", current)

    self:refresh()
end

function SyncGUI.copy()
    ParaMisc.CopyTextToClipboard(ShareWorld.getWorldUrl())
end

function SyncGUI.GetCurrent()
    return current
end

function SyncGUI.GetTotal()
    return total
end

function SyncGUI.GetFiles()
    return files
end

function SyncGUI.GetFinish()
    return finish
end

function SyncGUI.GetBroke()
    return broke
end

function SyncGUI:SetBroke(value)
    broke = value
end

function SyncGUI:SetFinish(value)
    finish = value
end