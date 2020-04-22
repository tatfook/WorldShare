--[[
Title: MsgBox
Author(s): big
Date: 2018.8.24
City: Foshan
use the lib:
------------------------------------------------------------
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox/MsgBox.lua")
------------------------------------------------------------
]]
local MsgBox = NPL.export()
local self = MsgBox

MsgBox.msgIdCount = 0
MsgBox.allMsg = {}
MsgBox.allMsgBox = commonlib.Array:new()
MsgBox.customLabels = {}

function MsgBox:Show(msg, sec, overtimeMsg, witdh, height, index)
    self.msgIdCount = self.msgIdCount + 1

    local msgId = self.msgIdCount

    self.allMsgBox:push_back(msgId)
    self.allMsg[msgId] = msg

    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        "Mod/WorldShare/cellar/Common/MsgBox/MsgBox.html?msgId=" .. msgId .. "&width=" .. (witdh or 0) .. "&height=" .. (height or 0),
        "MsgBox",
        0,
        0,
        "_fi",
        false,
        index
    )

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove("page/MsgBox" .. msgId)
    end

    Mod.WorldShare.Utils.SetTimeOut(
        function()
            for key, item in ipairs(self.allMsgBox) do
                if item == msgId then
                    if overtimeMsg then
                        GameLogic.AddBBS(nil, overtimeMsg, 3000, "255 0 0")
                    end

                    self:Close(msgId)
                end
            end
        end,
        (sec or 10000)
    )

    return curIndex
end

function MsgBox:Close(msgId)
    local MessageInfoPage

    if type(msgId) ~= 'number' then
        msgId = self.allMsgBox[#self.allMsgBox]
    end

    for key, value in ipairs(self.allMsgBox) do
        if value == msgId then
            MessageInfoPage = Mod.WorldShare.Store:Get("page/MsgBox" .. msgId)
            self.allMsgBox:remove(key)
        end
    end

    if MessageInfoPage then
        MessageInfoPage:CloseWindow()
    end
end

function MsgBox.SetPage(msgId)
    Mod.WorldShare.Store:Set("page/MsgBox" .. msgId, document:GetPageCtrl())
end

function MsgBox.GetMsg(msgId)
    if type(msgId) == 'number' then
        return self.allMsg[msgId]
    end
end

function MsgBox:Dialog(content, customLabels, MsgBoxClick_CallBack, buttons, icon, isNotTopLevel, zorder)
    if type(customLabels) == 'table' then
        self.customLabels = {
            AbortLabel = customLabels["Abort"],
            CancelLabel = customLabels["Cancel"],
            IgnoreLabel = customLabels["Ignore"],
            NoLabel = customLabels["No"],
            NoneLabel = customLabels["None"],
            OKLabel = customLabels["OK"],
            RetryLabel = customLabels["Retry"],
            YesLabel = customLabels["Yes"],
            TitleLabel = customLabels["Title"]
        }
    end

    _guihelper.MessageBox(
        content,
        MsgBoxClick_CallBack,
        buttons,
        icon,
        "Mod/WorldShare/cellar/Common/MsgBox/Dialog.html",
        isNotTopLevel,
        zorder
    )

    self.customLabels = {}
end