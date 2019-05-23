--[[
Title: MsgBox
Author(s): big
Date: 2018.8.24
City: Foshan
use the lib:
------------------------------------------------------------
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local MsgBox = NPL.export()
local self = MsgBox

MsgBox.msgIdCount = 0
MsgBox.allMsg = {}
MsgBox.allMsgBox = commonlib.Array:new()

function MsgBox:Show(msg, sec, overtimeMsg)
    self.msgIdCount = self.msgIdCount + 1
    
    local msgId = self.msgIdCount

    self.allMsgBox:push_back(msgId)
    self.allMsg[msgId] = msg

    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/Common/MsgBox.html?msgId=" .. msgId, "MsgBox", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Store:Remove("page/MsgBox" .. msgId)
    end

    Utils.SetTimeOut(
        function()
            for key, item in ipairs(self.allMsgBox) do
                if (item == msgId) then
                    if overtimeMsg then
                        _guihelper.MessageBox(overtimeMsg)
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
            MessageInfoPage = Store:Get("page/MsgBox" .. msgId)
            self.allMsgBox:remove(key)
        end
    end

    if (MessageInfoPage) then
        MessageInfoPage:CloseWindow()
    end
end

function MsgBox.SetPage(msgId)
    Store:Set("page/MsgBox" .. msgId, document:GetPageCtrl())
end

function MsgBox.GetMsg(msgId)
    if type(msgId) == 'number' then
        return self.allMsg[msgId]
    end
end
