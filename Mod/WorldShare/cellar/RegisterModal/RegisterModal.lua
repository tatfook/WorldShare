--[[
Title: register modal
Author(s):  big
Date: 2019.9.20
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local RegisterModal = NPL.load("(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua")
RegisterModal:ShowPage()
------------------------------------------------------------
]]

local Validated = NPL.load("(gl)Mod/WorldShare/helper/Validated.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

local RegisterModal = NPL.export()

function RegisterModal:ShowPage()
    Mod.WorldShare.Utils:ShowWindow(360, 480, "Mod/WorldShare/cellar/RegisterModal/RegisterModal.html", "RegisterModal")
end

function RegisterModal:ShowUserAgreementPage()
    Mod.WorldShare.Utils:ShowWindow(400, 580, "Mod/WorldShare/cellar/RegisterModal/UserAgreement.html", "UserAgreement")
end

function RegisterModal:ShowBindingPage()
    Mod.WorldShare.Utils:ShowWindow(360, 480, "Mod/WorldShare/cellar/RegisterModal/Binding.html", "Binding")
end

function RegisterModal:GetServerList()
    local serverList = KeepworkService:GetServerList()

    if self.registerServer then
        for key, item in ipairs(serverList) do
            item.selected = nil
            if item.value == self.registerServer then
                item.selected = true
            end
        end
    end

    return serverList
end

function RegisterModal:Register()
    local RegisterModalPage = Mod.WorldShare.Store:Get('page/RegisterModal')

    if not RegisterModalPage then
        return false
    end

    local loginServer = KeepworkService:GetEnv()
    local account = RegisterModalPage:GetValue("account")
    local password = RegisterModalPage:GetValue("password")
    local captcha = RegisterModalPage:GetValue("captcha")
    local phone = RegisterModalPage:GetValue("phone")
    local phonecaptcha = RegisterModalPage:GetValue("phonecaptcha")
    local agree = RegisterModalPage:GetValue("agree")

    if not agree then
        GameLogic.AddBBS(nil, L"您未同意用户协议", 3000, "255 0 0")
        return false
    end

    if not account or account == "" then
        GameLogic.AddBBS(nil, L"账号不能为空", 3000, "255 0 0")
        return false
    end

    if #password < 6 then
        GameLogic.AddBBS(nil, L"密码最少为6位", 3000, "255 0 0")
        return false
    end

    if not captcha or captcha == "" then
        GameLogic.AddBBS(nil, L"验证码不能为空", 3000, "255 0 0")
        return false
    end

    if #phone > 0 and not Validated:Phone(phone) then
        GameLogic.AddBBS(nil, L"手机格式错误", 3000, "255 0 0")
        return false
    end

    if #phone > 0 and #phonecaptcha == 0 then
        GameLogic.AddBBS(nil, L"手机验证码不能为空", 3000, "255 0 0")
        return false
    end

    -- Mod.WorldShare.Store:Set("user/env", loginServer)

    Mod.WorldShare.MsgBox:Show(L"正在注册，可能需要10-15秒的时间，请稍后...", 20000, L"链接超时", 500, 120)

    KeepworkServiceSession:Register(account, password, captcha, phone, phonecaptcha, function(state)
        if state and state.id then
            if state.code then
                GameLogic.AddBBS(nil, state.message, 5000, "0 0 255")
            else
                GameLogic.AddBBS(nil, L"注册成功", 5000, "0 255 0")
            end

            RegisterModalPage:CloseWindow()
            Mod.WorldShare.MsgBox:Close()
            WorldList:RefreshCurrentServerList()
            return true
        end

        GameLogic.AddBBS(nil, format("%s%s(%d)", L"注册失败，错误信息：", state.message, state.code), 5000, "255 0 0")
        Mod.WorldShare.MsgBox:Close()
    end)
end

function RegisterModal:Bind(method)
    local BindingPage = Mod.WorldShare.Store:Get('page/Binding')

    if not BindingPage then
        return false
    end

    if method == 'bindphone' then
        local phone = BindingPage:GetValue("phone")
        local phonecaptcha = BindingPage:GetValue("phonecaptcha")

        if not Validated:Phone(phone) then
            GameLogic.AddBBS(nil, L"手机号码格式错误", 3000, "255 0 0")
            return false
        end

        if phonecaptcha == '' then
            GameLogic.AddBBS(nil, L"手机验证码不能为空", 3000, "255 0 0")
            return false
        end

        KeepworkServiceSession:BindPhone(phone, phonecaptcha, function(data, err)
            BindingPage:CloseWindow()

            if data == 'true' and err == 200 then
                GameLogic.AddBBS(nil, L"绑定成功", 3000, "0 255 0")
                return true
            end

            GameLogic.AddBBS(nil, L"绑定失败", 3000, "255 0 0")
        end)

        return true
    end

    if method == 'bindemail' then
        local email = BindingPage:GetValue("email")
        local emailcaptcha = BindingPage:GetValue("emailcaptcha")

        if not Validated:Email(email) then
            GameLogic.AddBBS(nil, L"EMAIL格式错误", 3000, "255 0 0")
            return false
        end

        if emailcaptcha == '' then
            GameLogic.AddBBS(nil, L"EMAIL验证码不能为空", 3000, "255 0 0")
            return false
        end

        KeepworkServiceSession:BindEmail(email, emailcaptcha, function(data, err)
            BindingPage:CloseWindow()

            if data == 'true' and err == 200 then
                GameLogic.AddBBS(nil, L"绑定成功", 3000, "0 255 0")
                return true
            end

            GameLogic.AddBBS(nil, L"绑定失败", 3000, "255 0 0")
        end)

        return true
    end
end