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
local Sync

function SyncGUI.init()
    current = 0
    total = 0
    files = L"同步中，请稍后..."
    finish = false
    broke = false

    Utils:ShowWindow(0, 0, "Mod/WorldShare/sync/SyncGUI.html", "SyncGUI", 0, 0, "_fi", false)
end

function SyncGUI.SetSync(sync)
    Sync = sync
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
    Sync:SetBroke(true)

    files = L"正在等待上次同步完成，请稍后..."

    SyncGUI.SetBroke(true)
    SyncGUI.SetFinish(true)
    SyncGUI:refresh()

    local function checkFinish()
        Utils.SetTimeOut(
            function()
                if (not Sync.finish) then
                    checkFinish()
                    return false
                end

                SyncGUI:closeWindow()

                if (type(callback) == "function") then
                    callback()
                end
            end,
            1000
        )
    end

    checkFinish()
end

function SyncGUI.retry()
    SyncGUI.cancel(
        function()
            SyncCompare:syncCompare()
        end
    )
end

function SyncGUI:updateDataBar(pCurrent, pTotal, pFiles, pFinish)
    if (broke) then
        return false
    end

    current = pCurrent
    total = pTotal
    files = pFiles
    finish = pFinish

    if (not files) then
        files = L"同步中，请稍后..."
    end

    LOG.std("SyncGUI", "debug", "SyncGUI", format("Totals : %s , Current : %s, Status : %s", total, current, files))

    SyncGUI:GetProgressBar():SetAttribute("Maximum", total)
    SyncGUI:GetProgressBar():SetAttribute("Value", current)

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

function SyncGUI.SetBroke(value)
    broke = value
end

function SyncGUI.SetFinish(value)
    finish = value
end
