--[[
Title: Register Modal
Author(s): big
CreateDate: 2019.09.20
ModifyDate: 2021.09.10
City: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local RegisterModal = NPL.load('(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua')
RegisterModal:ShowPage()
------------------------------------------------------------
]]

-- libs
local PlayerAssetFile = commonlib.gettable('MyCompany.Aries.Game.EntityManager.PlayerAssetFile')

-- helper
local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')

-- service
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

-- bottles
local Certificate = NPL.load('(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua')

local RegisterModal = NPL.export()

RegisterModal.m_mode = 'account'
RegisterModal.account = ''
RegisterModal.password = ''
RegisterModal.phonenumber = ''
RegisterModal.phonepassword = ''
RegisterModal.phonecaptcha = ''
RegisterModal.bindphone = nil

function RegisterModal:ShowPage(callback, zorder)
    local LoginModalPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.LoginModal')

    if LoginModalPage then
        LoginModalPage:CloseWindow()
    end

    self.callback = callback
    self.m_mode = 'account'
    self.account = ''
    self.password = ''
    self.phonenumber = ''
    self.phonepassword = ''
    self.phonecaptcha = ''
    self.bindphone = nil

    Mod.WorldShare.Utils.ShowWindow(
        320,
        360,
        'Mod/WorldShare/cellar/RegisterModal/Theme/RegisterModal.html',
        'Mod.WorldShare.RegisterModal',
        nil,
        nil,
        nil,
        nil,
        zorder
    )
end

function RegisterModal:ShowUserAgreementPage()
    Mod.WorldShare.Utils.ShowWindow(400, 580, 'Mod/WorldShare/cellar/RegisterModal/UserAgreement.html', 'Mod.WorldShare.RegisterModal.UserAgreement')
end

function RegisterModal:ShowUserPrivacyPage()
    Mod.WorldShare.Utils.ShowWindow(400, 580, 'Mod/WorldShare/cellar/RegisterModal/UserPrivacy.html', 'Mod.WorldShare.RegisterModal.UserPrivacy')
end

function RegisterModal:ShowBindingPage()
    Mod.WorldShare.Utils.ShowWindow(360, 480, 'Mod/WorldShare/cellar/RegisterModal/Binding.html', 'Mod.WorldShare.RegisterModal.Binding')
end

function RegisterModal:ShowClassificationPage(callback, forceCallback)
    Certificate:Init(function(result)
        if result == true or forceCallback == true then
            if callback and type(callback) == 'function' then
                callback()
            end
        end
    end)
end

function RegisterModal:RegisterWithAccount(callback)
    if not Validated:Account(self.account) then
        return
    end

    if not Validated:Password(self.password) then
        return
    end

    Mod.WorldShare.MsgBox:Show(L'正在注册，请稍候...', 10000, L'链接超时', 500, 120, 20)

    KeepworkServiceSession:RegisterWithAccount(self.account, self.password, function(state)
        Mod.WorldShare.MsgBox:Close()

        if not state then
            GameLogic.AddBBS(nil, L'未知错误', 5000, '0 255 0')
            return
        end

        if state.id then
            if state.code then
                GameLogic.AddBBS(nil, format('%s%s(%d)', L'错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
            else
                -- set default user role
                local filename = self.GetValidAvatarFilename('boy01')
                GameLogic.options:SetMainPlayerAssetName(filename)

                -- register success
            end

            if self.callback and type(self.callback) == 'function' then
                self.callback(true)
            end

            if callback and type(callback) == 'function' then
                callback(true)
            end

            return
        end

        GameLogic.AddBBS(nil, format('%s%s(%d)', L'注册失败，错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
    end)
end

function RegisterModal:RegisterWithPhone(callback)
    if not Validated:Phone(self.phonenumber) then
        return false
    end

    if not Validated:Password(self.password) then
        return false
    end

    if not Validated:Account(self.account) then
        return false
    end

    if not self.phonecaptcha or self.phonecaptcha == '' then
        return false
    end

    Mod.WorldShare.MsgBox:Show(L'正在注册，请稍候...', 10000, L'链接超时', 500, 120)

    KeepworkServiceSession:RegisterWithPhone(self.account, self.phonenumber, self.phonecaptcha, self.password, function(state)
        Mod.WorldShare.MsgBox:Close()

        if not state then
            GameLogic.AddBBS(nil, L'未知错误', 5000, '0 255 0')
            return
        end

        if state.id then
            if state.code then
                GameLogic.AddBBS(nil, format('%s%s(%d)', L'错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
            else
                -- set default user role
                local filename = self.GetValidAvatarFilename('boy01')
                GameLogic.options:SetMainPlayerAssetName(filename)

                -- register success
            end

            if self.callback and type(self.callback) == 'function' then
                self.callback(true)
            end

            if callback and type(callback) == 'function' then
                callback(true)
            end

            return
        end

        GameLogic.AddBBS(nil, format('%s%s(%d)', L'注册失败，错误信息：', state.message or '', state.code or 0), 5000, '255 0 0')
    end)
end

function RegisterModal:Classification(phonenumber, captcha, callback)
    KeepworkServiceSession:ClassificationPhone(phonenumber, captcha, function(data, err, bSuccess)
        if bSuccess then
            GameLogic.AddBBS(nil, L'实名认证成功', 5000, '0 255 0')

            if callback and type(callback) == 'function' then
                callback()
            end

            return
        end

        GameLogic.AddBBS(nil, format('%s%s(%d)', L'认证失败，错误信息：', data.message, data.code), 5000, '255 0 0')
    end)
end

function RegisterModal:ClassificationAndBind(phonenumber, captcha, callback)
    KeepworkServiceSession:ClassificationAndBindPhone(phonenumber, captcha, function(data, err)
        if data.data then
            GameLogic.AddBBS(nil, L'实名认证成功，手机号绑定成功', 5000, '0 255 0')

            Mod.WorldShare.Store:Set('user/isVerified', true)
            Mod.WorldShare.Store:Set('user/isBind', true)

            if type(callback) == 'function' then
                callback()
            end
            return true
        end

        GameLogic.AddBBS(nil, format('%s%s(%d)', L'认证失败，错误信息：', data.message, data.code), 5000, '255 0 0')
    end)
end

function RegisterModal:Bind(method, ...)
    if method == 'bindphone' then
        local phonenumber, phonecaptcha, callback = ...;

        if not Validated:Phone(phonenumber) then
            GameLogic.AddBBS(nil, L'手机号码格式错误', 3000, '255 0 0')
            return false
        end

        if phonecaptcha == '' then
            GameLogic.AddBBS(nil, L'手机验证码不能为空', 3000, '255 0 0')
            return false
        end

        Mod.WorldShare.MsgBox:Show(L'请稍候...')
        KeepworkServiceSession:BindPhone(phonenumber, phonecaptcha, function(data, err)
            Mod.WorldShare.MsgBox:Close()

            if err == 200 and data.data then
                GameLogic.AddBBS(nil, L'绑定成功', 3000, '0 255 0')
                if type(callback) == 'function' then
                    callback()
                end
                return true
            end

            GameLogic.AddBBS(nil, format('%s%s(%d)', L'绑定失败，错误信息：', data.message, data.code), 5000, '255 0 0')
        end)

        return true
    end

    if method == 'bindemail' then
        local email, emailcaptcha, callback = ...;

        if not Validated:Email(email) then
            GameLogic.AddBBS(nil, L'EMAIL格式错误', 3000, '255 0 0')
            return false
        end

        if emailcaptcha == '' then
            GameLogic.AddBBS(nil, L'EMAIL验证码不能为空', 3000, '255 0 0')
            return false
        end

        Mod.WorldShare.MsgBox:Show(L'请稍候...')
        KeepworkServiceSession:BindEmail(email, emailcaptcha, function(data, err)
            Mod.WorldShare.MsgBox:Close()

            if err == 409 then
                GameLogic.AddBBS(nil, L'邮箱已被绑定', 3000, '255 0 0')
                return false
            end

            if err == 200 and data.data then
                GameLogic.AddBBS(nil, L'绑定成功', 3000, '0 255 0')
                if type(callback) == 'function' then
                    callback()
                end
                return true
            end

            GameLogic.AddBBS(nil, format('%s%s(%d)', L'绑定失败，错误信息：', data.message, data.code), 5000, '255 0 0')
        end)

        return true
    end
end

function RegisterModal.GetValidAvatarFilename(playerName)
    if playerName then
        PlayerAssetFile:Init()
        return PlayerAssetFile:GetValidAssetByString(playerName)
    end
end
