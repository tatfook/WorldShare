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

function MsgBox:Show(msg)
    Store:set("user/msg", msg)

    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/Common/MsgBox.html", "MsgBox", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Store:remove("page/MsgBox")
        Store:remove("user/msg")
    end
end

function MsgBox:Close()
    Utils.SetTimeOut(
        function()
            local MessageInfoPage = Store:get("page/MsgBox")

            if (MessageInfoPage) then
                MessageInfoPage:CloseWindow()
            end
        end
    )
end

function MsgBox.setPage()
    local MessageInfoPage = Store:get("page/MsgBox")

    if (MessageInfoPage) then
        MessageInfoPage:CloseWindow()
    end

    Store:set("page/MsgBox", document:GetPageCtrl())
end

function MsgBox.getMsg()
    return Store:get("user/msg")
end
