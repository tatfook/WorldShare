-- bottles
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
local MySchool = NPL.load('(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepWorkService/Session.lua')
local EventTrackingService = NPL.load('(gl)Mod/WorldShare/service/EventTracking.lua')

-- helper
local Validated = NPL.load('(gl)Mod/WorldShare/helper/Validated.lua')

local be_show_password = false
local account_agree = true
local phone_agree = true
local is_clicked_get_phone_captcha = false
local phone_show_field = ''
local b_next_button_right = true
local phone_account_exist = false

function get_page()
    return Mod.WorldShare.Store:Get('page/Mod.WorldShare.cellar.MainLogin.UpdatePassword')
end

function close()
    if get_page() then
        get_page():CloseWindow()
    end
end

function back()
    close()
    MainLogin:ShowLogin()
end

function update_password()
    local cur_password = get_page():GetValue("cur_password") or ""
    local new_password = get_page():GetValue("new_password") or ""
    local new_password_again = get_page():GetValue("new_password_again") or ""

    if cur_password == '' then
        _guihelper.MessageBox(L'请输入当前密码')
        return
    end

    if new_password == '' then
        _guihelper.MessageBox(L'请输入新的密码')
        return
    end

    if new_password_again == '' then
        _guihelper.MessageBox(L'请再次输入需要设置的新密码')
        return
    end

    if new_password ~= new_password_again then
        _guihelper.MessageBox(L'两次输入的密码不一致，请检查输入是否有误。')
        return
    end

    if new_password == cur_password then
        _guihelper.MessageBox(L'新密码与旧密码一致，请检查输入是否有误。')
        return
    end

    if not Validated:Password(new_password) then
        _guihelper.MessageBox(L'新密码不合法。')
        return
    end

    keepwork.user.pwd(
        {
            password = new_password,
            oldpassword = cur_password,
        },
        function(err, msg, data)
            if data == true then
                _guihelper.MessageBox(L'修改密码成功，请重新登录')
                
                KeepworkServiceSession:Logout(nil, function()
                    Mod.WorldShare.MsgBox:Close()
                    close()
                    MainLogin:ShowLogin()
                end)

            else
                _guihelper.MessageBox(L'修改密码失败，请确认当前密码是否正确')
            end
        end
    )
end

function parent()
    EventTrackingService:Send(1, 'click.main_login.select_parents', nil, true)
    MainLogin:ShowParent()
end

function on_click_exit()
    MainLogin:Exit()
end