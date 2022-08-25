--[[
Title: user store
Author(s): big
CreateDate: 2018.8.17
ModifyDate: 2022.6.28
City: Foshan 
use the lib:
------------------------------------------------------------
local UserStore = NPL.load('(gl)Mod/WorldShare/store/UserStore.lua')
------------------------------------------------------------
]]

--libs
local RestartTable = commonlib.gettable('RestartTable')

local UserStore = commonlib.inherit(commonlib.gettable('System.Core.ToolBase'), NPL.export())

UserStore:Signal('onLogin', function() end)
UserStore:Signal('onLogout', function() end)
UserStore:Signal('onSetThirdPartyLoginAuthinfo', function() end)
UserStore:Signal('onParentPhoneVerification', function() end)

function UserStore:Action(data)
    local self = data

    return {
        SetToken = function(token)
            self.token = token
            commonlib.setfield('System.User.keepworktoken', token)
        end,
        SetIsVipSchool = function(isVipSchool)
            self.isVipSchool = isVipSchoolƒ
            commonlib.setfield('System.User.isVipSchool', self.isVipSchool)
        end,
        Login = function(token, userId, username, nickname, realname, isVipSchool)
            self.token = token
            self.userId = userId
            self.username = username
            self.nickname = nickname
            self.realname = realname
            self.isVipSchool = isVipSchool

            commonlib.setfield('System.User.keepworktoken', self.token)
            commonlib.setfield('System.User.username', self.username)
            commonlib.setfield('System.User.keepworkUsername', self.username)
            commonlib.setfield('System.User.NickName', self.nickname)
            commonlib.setfield('System.User.realname', self.realname)
            commonlib.setfield('System.User.userType', self.userType)
            commonlib.setfield('System.User.isVip', self.isVip)
            commonlib.setfield('System.User.isVipSchool', self.isVipSchool)

            RestartTable.username = self.username

            UserStore:onLogin()
        end,
        Logout = function()
            self.token = nil
            self.userId = nil
            self.username = nil
            self.nickname = nil
            self.myOrg = nil
            self.userType = nil

            commonlib.setfield('System.User.keepworktoken', nil)
            commonlib.setfield('System.User.username', nil)
            commonlib.setfield('System.User.keepworkUsername', nil)
            commonlib.setfield('System.User.NickName', nil)
            commonlib.setfield('System.User.userType', nil)
            commonlib.setfield('System.User.isVip', nil)
            

            UserStore:onLogout()
        end,
        SetPlayerController = function(playerController)
            self.playerController = playerController
        end,
        SetThirdPartyLoginAuthinfo = function(authType, authCode)
            self.authType = authType
            self.authCode = authCode

            UserStore:onSetThirdPartyLoginAuthinfo()
        end,
        SetWhereAnonymousUser = function(where)
            self.whereAnonymousUser = where
            RestartTable.whereAnonymousUser = where
        end,
        ParentPhoneVerification = function(payload)
            UserStore:onParentPhoneVerification(payload)
        end
    }
end

function UserStore:Getter(data)
    local self = data

    return {
        GetPlayerController = function()
            return self.playerController
        end,
        GetClientPassword = function()
            if not self.clientPassword then
                self.clientPassword = os.time()
            end

            return self.clientPassword
        end
    }
end
