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

MsgBox.count = 0
MsgBox.allMsgBox = commonlib.Array:new()

function MsgBox:Show(msg, sec, overtimeMsg)
    self.count = self.count + 1
    local curIndex = self.count
    self.allMsgBox:push_back(curIndex)

    Store:Set("user/msg", msg)

    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/Common/MsgBox.html", "MsgBox", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Store:Remove("page/MsgBox")
        Store:Remove("user/msg")
    end

    if not sec or type(sec) ~= 'number' then
        return curIndex
    end

    Utils.SetTimeOut(
        function()
            for key, item in ipairs(self.allMsgBox) do
                if (item == curIndex) then
                    _guihelper.MessageBox(overtimeMsg)

                    local MessageInfoPage = Store:Get("page/MsgBox")

                    if (MessageInfoPage) then
                        MessageInfoPage:CloseWindow()
                    end
                end
            end
        end,
        sec or 0
    )

    return curIndex
end

function MsgBox:Close(index)
    if type(index) == 'number' then
        for key, value in ipairs(self.allMsgBox) do
            if value == index then
                self.allMsgBox:remove(key)
            end
        end
    else
        self.allMsgBox:remove(#self.allMsgBox)
    end

    local MessageInfoPage = Store:Get("page/MsgBox")

    if (MessageInfoPage) then
        MessageInfoPage:CloseWindow()
    end
end

function MsgBox.SetPage()
    local MessageInfoPage = Store:Get("page/MsgBox")

    if (MessageInfoPage) then
        MessageInfoPage:CloseWindow()
    end

    Store:Set("page/MsgBox", document:GetPageCtrl())
end

function MsgBox.GetMsg()
    return Store:Get("user/msg")
end
