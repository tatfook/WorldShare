--[[
Title: Main Login Login script
Author: big  
CreateDate: 2022.9.6
place: Foshan
Desc: 
]]

-- bottles
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
local ForgetPassword = NPL.load('(gl)Mod/WorldShare/cellar/ForgetPassword/ForgetPassword.lua')
local MySchool = NPL.load('(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua')
local RegisterModal = NPL.load('(gl)Mod/WorldShare/cellar/RegisterModal/RegisterModal.lua')
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/KeepworkServiceSession.lua')
local EventTrackingService = NPL.load('(gl)Mod/WorldShare/service/EventTracking.lua')

-- helper
local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')

-- database
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

local account_list_data = MainLogin:GetHistoryUsers()

if account_list_data and
   type(account_list_data) == 'table' and
   #account_list_data > 0 then
    local tmp = {}

    for i = 1, #account_list_data - 1 do
        for j = 1, #account_list_data - i do
            local curItemModifyTime = 0
            local nextItemModifyTime = 0

            if account_list_data[j] and
                account_list_data[j].session and
                account_list_data[j].session.loginTime then
                curItemModifyTime = account_list_data[j].session.loginTime
            end

            if account_list_data[j + 1] and
                account_list_data[j + 1].session and
                account_list_data[j + 1].session.loginTime then
                nextItemModifyTime = account_list_data[j + 1].session.loginTime
            end

            if curItemModifyTime < nextItemModifyTime then
                tmp = account_list_data[j]
                account_list_data[j] = account_list_data[j + 1]
                account_list_data[j + 1] = tmp
            end
        end
    end
else
    account_list_data = {}
end

function get_page()
    return Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')
end

function get_is_modal()
    return get_page():GetRequestParam('is_modal') == 'true' and true or false
end

function get_history_users()
    return MainLogin:GetHistoryUsers()
end

function is_support_third_party_login()
    if System.os.GetPlatform() == 'win32' or System.os.GetPlatform() == 'mac' then
        return true
    else
        return false
    end
end

function register()
    close()

    if get_is_modal() then
        RegisterModal:ShowPage()
    else
        MainLogin:ShowRegister()
    end
end

-- @param name: 'local', 'internet'
function use_offline()
    MainLogin:Next(true)
    EventTrackingService:Send(1, 'click.main_login.offline_enter', { machineId = ParaEngine.GetAttributeObject():GetField('MachineID','') }, true)
end

function close()
    local MainLoginLoginPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Login')

    if MainLoginLoginPage then
        MainLoginLoginPage:CloseWindow()
    end
end

function forget_password()
    EventTrackingService:Send(1, 'click.main_login.find_password', nil, true)
    ForgetPassword:ShowPage()
end

function login()
    if is_login then
        return
    end

    is_login = true

    GameLogic.GetFilters():apply_filters('on_start_login')

    if not MainLogin:LoginAction(function(b_succeed)
        is_login = false

        if not b_succeed then
            if get_is_modal() then
                LoginModal:Close(false)
            end

            return
        end

        if get_is_modal() then
            LoginModal:Close(true)
        else
            local account = get_page():GetValue('account')
            get_page():SetUIValue('auto_username', account or '')
            set_mode('auto_login')

            commonlib.TimerManager.SetTimeout(function()  
                MainLogin:Next()
            end,0)
        end
    end) then
        is_login = false
    end
end

function update_login_button_status()
    local account = get_page():GetValue('account')
    local password = get_page():GetValue('password')

    local beSuccess = true

    if not Validated:AccountCompatible(account) then
       beSuccess = false
    else
        get_page():FindControl('account_field_error').visible = false
    end

    local password

    if be_show_password then
        password = get_page():GetValue('password_show')
    else
        password = get_page():GetValue('password_hide')
    end

    if string.find(password, 'pa') == 1 and not has_click_change_show_password then
        local check_str = {'p','a','r','a'} 
        local is_macth = true

        for i = 1, #check_str do
            local char = string.sub(password, i, i)
            if char and char ~= '' and check_str[i] ~= char then
                is_macth = false
                break
            end
        end

        if not is_macth then
            if auto_show_password then
                get_page():SetValue('eye_show_password', false)
                auto_show_password = false
                be_show_password = true
                set_show_password()

                local node = get_page():FindControl('password_hide')
                if node then
                    node:Focus()
                    node:SetCaretPosition(#password)
                end
            end
        elseif not be_show_password then
            get_page():SetValue('eye_show_password', true)
            set_show_password()
            auto_show_password = true
            local node = get_page():FindControl('password_show')
            if node then
                node:Focus()
                node:SetCaretPosition(#password)
            end
        end
    end

    if string.find(password, 'paracraft.cn') == 1 then
        -- 不允许自动登录
        get_page():SetUIValue('auto_login_name', false)
    end

    get_page():SetValue('password', password)

    if not Validated:Password(password) then
        beSuccess = false
    else
        get_page():FindControl('password_field_error').visible = false
    end

    if beSuccess then
        get_page():SetUIBackground('login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')
    else
        get_page():SetUIBackground('login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 197 258 44')
    end
end

function click_set_show_password()
    has_click_change_show_password = true
    set_show_password()
end

function set_show_password()
    if be_show_password then
        be_show_password = false

        local val = get_page():GetValue('password_show')
        get_page():SetValue('password_hide', val)
        get_page():SetValue('password', val)

        get_page():FindControl('password_show').visible = false
        get_page():FindControl('password_hide').visible = true
    else
        be_show_password = true

        local val = get_page():GetValue('password_hide')
        get_page():SetValue('password_show', val)
        get_page():SetValue('password', val)

        get_page():FindControl('password_show').visible = true
        get_page():FindControl('password_hide').visible = false
    end
end

function set_auto_login()
    local password

    if be_show_password then
        password = get_page():GetValue('password_show')
    else
        password = get_page():GetValue('password_hide')
    end
    if string.find(password, 'paracraft.cn') == 1 then
        -- 不允许自动登录
        get_page():SetUIValue('auto_login_name', false)
        _guihelper.MessageBox(L'你的密码为通用密码， 不可以自动登录，请回家后绑定手机并修改密码，防止别人使用你的账号。');
    else
        local is_auto = get_page():GetUIValue('auto_login_name')
        if is_auto then
            _guihelper.MessageBox(L'只有在自己家里的电脑才能使用“自动登录”，并且要牢记自己的账号和密码哦。', function(result)
                if result == _guihelper.DialogResult.OK then
                    get_page():SetUIValue('auto_login_name', false)
                end
               
            end, _guihelper.MessageBoxButtons.OKCancel_CustomLabel_Gray_All, nil, nil, nil, nil, {cancel='记住密码',ok='取消'});
        end
    end
end

function get_account_list()
    return account_list_data
end

function get_account_list_style()
    local count = #account_list_data

    if count > 4 then
        count = 4
    end

    return 'width: 240px;padding-left: 15px;height: ' .. (count * 40) .. 'px;background-color: #25282e;'
end

local is_show_account_list = false

function show_account_list()
    if is_show_account_list then
        is_show_account_list = false
        get_page():FindControl('account_list').visible = false
    else
        is_show_account_list = true
        get_page():FindControl('account_list').visible = true
    end
end

function hide_account_list()
    is_show_account_list = false
    get_page():FindControl('account_list').visible = false
end

function select_account(index)
    local account_data = account_list_data[index]
    local value = account_data.value
    get_page():SetValue('account', value);
    local password = account_data.session.rememberMe and account_data.session.password or ''
    get_page():SetUIValue('password_show', password or '')
    get_page():SetUIValue('password_hide', password or '')
    get_page():SetUIValue('password', password or '')

    local session = SessionsData:GetSessionByUsername(value) or {}

    if session.autoLogin then
        get_page():SetUIValue('auto_login_name', true)
        get_page():SetUIBackground('login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')
    else
        get_page():SetUIValue('auto_login_name', false)
        get_page():SetUIBackground('login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 197 258 44')
    end

    get_page():SetUIValue('account_field_error_msg', '')
    get_page():FindControl('account_field_error').visible = true
    get_page():SetUIValue('password_field_error_msg', '')
    get_page():FindControl('password_field_error').visible = true

    hide_account_list()
    update_login_button_status()
end

function remove_account(index)
    local value = account_list_data[index].value
    SessionsData:RemoveSession(value)

    local username = get_page():GetValue('account')

    if value == username then
        get_page():SetValue('account', '')
    end

    hide_account_list()
    get_page():Rebuild()
end

function set_account_mode()
    set_mode('account')
end

function set_phone_mode()
    set_mode('phone')
end

function set_mode(mode)
    local login_with_phone_number = get_page():FindControl('phone_mode')
    local login_with_account = get_page():FindControl('account_mode')
    local auto_login_mode = get_page():FindControl('auto_login_mode')
    local change_button = get_page():FindControl('change_button')
    local update_password_button = get_page():FindControl('update_password_button')

    if mode == 'account' then
        get_page():FindControl('login_button'):SetDefault(true)

        if login_with_phone_number then
            login_with_phone_number.visible = false
        end

        if login_with_account then
            login_with_account.visible = true
        end

        if auto_login_mode then
            auto_login_mode.visible = false
        end

        if auto_login_mode then
            if change_button then
                change_button.visible = false
            end
        end

        if auto_login_mode then
            if update_password_button then
                update_password_button.visible = false
            end
        end
    elseif mode == 'phone' then
        get_page():FindControl('phone_login_button'):SetDefault(true)

        if login_with_phone_number then
            login_with_phone_number.visible = true
        end

        if login_with_account then
            login_with_account.visible = false
        end

        if auto_login_mode then
            auto_login_mode.visible = false
        end

        if auto_login_mode then
            if change_button then
                change_button.visible = false
            end
        end

        if auto_login_mode then
            if update_password_button then
                update_password_button.visible = false
            end
        end
    elseif mode == 'auto_login' then
        if get_page():FindControl('login_button') then
            get_page():FindControl('login_button'):SetDefault(false)
        end

        if login_with_phone_number then
            login_with_phone_number.visible = false
        end

        if login_with_account then
            login_with_account.visible = false
        end

        if auto_login_mode then
            auto_login_mode.visible = true
        end

        if auto_login_mode then
            if change_button then
                change_button.visible = true
            end
            MainLogin:UpdatePasswordRemindVisible(true)
        end

        if auto_login_mode then
            update_password_button.visible = true
        end

        get_page():FindControl('start_button'):SetDefault(true)
        get_page():FindControl('title_login').visible = false
        get_page():FindControl('title_username').visible = true
    end
end

function login_with_phone()
    local phone_number = get_page():GetValue('phone_number')
    local phone_captcha = get_page():GetValue('phone_captcha')

    if not phone_captcha or phone_captcha == '' then
        get_page():SetUIValue('captcha_field_error_msg', L'*手机验证码不能为空')
        get_page():FindControl('captcha_field_error').visible = true
        return
    end

    KeepworkServiceSession:CellphoneCaptchaVerify(
        phone_number,
        phone_captcha,
        function(result)
            if not result or type(result) ~= 'table' then
                return
            end

            if result.verify ~= true then
                get_page():SetUIValue('phone_field_error_msg', format(L'%s(%d)', result.message, result.code))
                get_page():FindControl('phone_field_error').visible = true
                return
            end

            KeepworkServiceSession:CheckPhonenumberExist(phone_number, function(be_exist)
                if be_exist then
                    MainLogin:AndroidLoginWithPhoneNumber(phone_number, phone_captcha, function(be_succeed, reason, message)
                        if not be_succeed then
                            get_page():SetUIValue('phone_field_error_msg', message)
                            get_page():FindControl('phone_field_error').visible = true
                            return
                        end

                        -- close()

                        if true then
                            local account = Mod.WorldShare.Store:Get('user/username')
                            get_page():SetUIValue('auto_username', account or '')
                            set_mode('auto_login')
                            commonlib.TimerManager.SetTimeout(function()  
                                MainLogin:Next()
                            end,0)
                            return
                        end

                        SessionsData:SetUserLocation('HOME', Mod.WorldShare.Store:Get('user/username'))

                        if not Mod.WorldShare.Store:Get('user/hasJoinedSchool') then
                            MySchool:ShowJoinSchoolAfterRegister(function()
                                MainLogin:EnterUserConsole()
                            end)
                        else
                            MainLogin:EnterUserConsole()
                        end
                    end)
                else
                    register()

                    Mod.WorldShare.Utils.SetTimeOut(function()
                        local register_page = Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.Register')

                        register_page:SetUIValue('phonenumber', phone_number)
                        register_page:SetUIValue('phonecaptcha', phone_captcha)
                        register_page:FindControl('account_register_mode').visible = false
                        register_page:FindControl('phone_register_mode').visible = true
                        
                        register_page:SetUIBackground('account_button', '')
                        register_page:SetUIBackground('phone_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#5 378 128 26')

                        _guihelper.SetFontColor(register_page:FindControl('account_button'), '#FFFFFF')
                        _guihelper.SetFontColor(register_page:FindControl('phone_button'), '#25282E')

                        register_page:FindControl('account_register_mode').visible = false
                        register_page:FindControl('phone_register_mode').visible = true
                    end, 100)
                end
            end)
        end
    )
end

function update_phone_login_button_status()
    local phone_number = get_page():GetValue('phone_number')
    local phone_captcha = get_page():GetValue('phone_captcha')

    local be_success = true

    if not Validated:Phone(phone_number) then
        be_success = false
    else
        get_page():FindControl('phone_field_error').visible = false
    end

    if not phone_captcha or #phone_captcha == 0 then
        be_success = false
    else
        get_page():FindControl('captcha_field_error').visible = false
    end

    if be_success then
        get_page():SetUIBackground('phone_login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 98 258 44')
    else
        get_page():SetUIBackground('phone_login_button', 'Texture/Aries/Creator/paracraft/paracraft_login_32bits.png#271 197 258 44')
    end
end

function get_phone_captcha()
    local phone_number = get_page():GetValue('phone_number')

    if not Validated:Phone(phone_number) then
        _guihelper.MessageBox(L'*手机号格式错误')
        return
    end

    if is_clicked_get_phone_captcha then
        return false
    end

    is_clicked_get_phone_captcha = true

    local times = 60

    local timer = commonlib.Timer:new({
        callbackFunc = function(timer)
            get_page():SetValue('get_phone_captcha', format('%s(%ds)', L'重新发送', times))

            if times == 0 then
                is_clicked_get_phone_captcha = false
                get_page():SetValue('get_phone_captcha', L'获取验证码')
                timer:Change(nil, nil)
            end

            times = times - 1
        end
    })

    KeepworkServiceSession:GetPhoneCaptcha(phone_number, function(data, err)
        if err == 400 and data and data.code and data.message then
            is_clicked_get_phone_captcha = false
            get_page():SetValue('get_phone_captcha', L'获取验证码')
            GameLogic.AddBBS(nil, format('%s%s(%d)', L'获取验证码失败，错误信息：', data.message, data.code), 3000, '255 0 0')
            timer:Change(nil, nil)
        end
    end)

    timer:Change(1000, 1000)
end

function change()
    Mod.WorldShare.MsgBox:Show(L'正在退出，请稍后...')
    KeepworkServiceSession:Logout(nil, function()
        Mod.WorldShare.MsgBox:Close()
        close()
        MainLogin:ShowLogin()
    end)
end

function start()
    MainLogin:Next()
end

function parent()
    EventTrackingService:Send(1, 'click.main_login.select_parents', nil, true)
    MainLogin:ShowParent()
end

function on_click_exit()
    MainLogin:Exit()
end

function update_password()
    if not KeepworkServiceSession:IsRealName() then
        _guihelper.MessageBox(L'*修改密码前请先完成实名认证。', function()
            local Certificate = NPL.load('(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua')
            Certificate:ShowMyHomePage(function(result)
                if KeepworkServiceSession:IsRealName() then
                    MainLogin:UpdatePasswordRemindVisible(false)
                    close()
                    MainLogin:ShowUpdatePassword()
                end
            end)
        end)
        return
    end

    MainLogin:UpdatePasswordRemindVisible(false)
    close()
    MainLogin:ShowUpdatePassword()
end

function get_container_style()
    if get_is_modal() then
        return 'margin-top: -200px;'
    end
end
