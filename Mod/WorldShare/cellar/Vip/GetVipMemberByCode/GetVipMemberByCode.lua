--[[
Title: GetVipMemberByCode
Author(s):  big
Date: 2020.09.24
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local VipNotice = NPL.load("(gl)Mod/WorldShare/cellar/Vip/GetVipMemberByCode/GetVipMemberByCode.lua")
------------------------------------------------------------
]]

local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua")

local GetVipMemberByCode = NPL.export()

function GetVipMemberByCode:Show()
    local params = Mod.WorldShare.Utils.ShowWindow(400, 200, "(ws)Vip/GetVipMemberByCode/GetVipMemberByCode.html", "Mod.WorldShare.Vip.GetVipMemberByCode", nil, nil, nil, true, 102)
end

function GetVipMemberByCode:Activation()
    local GetVipMemberByCodePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Vip.GetVipMemberByCode')

    if not GetVipMemberByCodePage then
        return false
    end

    local code = GetVipMemberByCodePage:GetValue("code") or ""

    KeepworkServiceSession:ActiveVipByCode(code, function(data, err)
        if err == 200 then
            GetVipMemberByCodePage:CloseWindow()

            if data and type(data) == 'table' and data.message then
                GameLogic.AddBBS(nil, L"激活成功", 3000, "0 255 0")
            end

            return
        end

        if data and type(data) == 'table' and data.message then
            GameLogic.AddBBS(nil, format(L"激活失败，原因：%s（%d）", data.message, err), 3000, "255 0 0")
        end

        if data and type(data) == "string" then
            local dataParams = {}
            NPL.FromJson(data, dataParams)

            if dataParams and type(dataParams) == 'table' and dataParams.message then
                GameLogic.AddBBS(nil, format(L"激活失败，原因：%s（%d）", dataParams.message, err), 3000, "255 0 0")
            end
        end
    end)
end