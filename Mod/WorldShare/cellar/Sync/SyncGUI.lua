--[[
Title: SyncGUI
Author(s):  big
Date: 	2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
local SyncGUI = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncGUI.lua")
------------------------------------------------------------
]]
local SyncMain = NPL.load("./SyncMain.lua")
local SyncCompare = NPL.load("./SyncCompare.lua")
local ShareWorld = NPL.load("../ShareWorld/ShareWorld.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local SyncGUI = NPL.export()

function SyncGUI:init(instance)
    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/Sync/SyncGUI.html", "SyncGUI", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Store:remove("page/SyncGUI")
    end

    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    SyncGUIPage.instance = instance
    SyncGUIPage.current = 0
    SyncGUIPage.total = 0
    SyncGUIPage.msg = L"同步中，请稍后..."
    SyncGUIPage.finish = false
    SyncGUIPage.broke = false

    self:refresh()
end

function SyncGUI:setPage()
    Store:set("page/SyncGUI", document:GetPageCtrl())
end

function SyncGUI:getProgressBar()
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    return SyncGUIPage:GetNode("progressbar")
end

function SyncGUI:refresh(delayTimeMs)
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (SyncGUIPage) then
        SyncGUIPage:Refresh(delayTimeMs or 0.01)
    end
end

function SyncGUI:closeWindow()
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (SyncGUIPage) then
        SyncGUIPage:CloseWindow()
    end
end

function SyncGUI:cancel(callback)
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage or not SyncGUIPage.instance) then
        return false
    end

    SyncGUIPage.instance:SetBroke(true)
    SyncGUIPage.msg = L"正在等待上次同步完成，请稍后..."
    SyncGUIPage.broke = true
    SyncGUIPage.finish = true

    SyncGUI:refresh()

    local function checkFinish()
        Utils.SetTimeOut(
            function()
                if (not SyncGUIPage.finish) then
                    checkFinish()
                    return false
                end

                SyncGUI:closeWindow()
                MsgBox:Close()

                if (type(callback) == "function") then
                    callback()
                end
            end,
            1000
        )
    end

    checkFinish()
end

function SyncGUI:retry()
    self:cancel(
        function()
            SyncCompare:syncCompare()
        end
    )
end

function SyncGUI:updateDataBar(current, total, msg, finish)
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    if (SyncGUIPage.broke) then
        return false
    end

    SyncGUIPage.current = current
    SyncGUIPage.total = total
    SyncGUIPage.msg = msg
    SyncGUIPage.finish = finish

    if (not msg) then
        SyncGUIPage.msg = L"同步中，请稍后..."
    end

    LOG.std("SyncGUI", "debug", "SyncGUI", format("Totals : %s , Current : %s, Status : %s", total, current, msg))

    if (not self:getProgressBar()) then
        return false
    end

    self:getProgressBar():SetAttribute("Maximum", total)
    self:getProgressBar():SetAttribute("Value", current)
    self:refresh()
end

function SyncGUI:copy()
    ParaMisc.CopyTextToClipboard(ShareWorld.getWorldUrl())
end

function SyncGUI:getCurrent()
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    return SyncGUIPage.current
end

function SyncGUI:getTotal()
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    return SyncGUIPage.total
end

function SyncGUI:getMsg()
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    return SyncGUIPage.msg
end

function SyncGUI:getFinish()
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    return SyncGUIPage.finish
end

function SyncGUI:getBroke()
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    return SyncGUIPage.broke
end

function SyncGUI:setBroke(value)
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    SyncGUIPage.broke = value
end

function SyncGUI:setFinish(value)
    local SyncGUIPage = Store:get("page/SyncGUI")

    if (not SyncGUIPage) then
        return false
    end

    SyncGUIPage.finish = value
end