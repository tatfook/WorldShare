--[[
Title: user store
Author(s): big
Date: 2018.8.17
City: Foshan 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/store/User.lua")
local UserStore = commonlib.gettable('Mod.WorldShare.store.User')
------------------------------------------------------------
]]

--libs
local RestartTable = commonlib.gettable('RestartTable')

local UserStore = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable('Mod.WorldShare.store.User'))

UserStore:Signal("onLogin", function() end)
UserStore:Signal("onLogout", function() end)
UserStore:Signal("onSetThirdPartyLoginAuthinfo", function() end)

function UserStore:Action()
    return {
        SetToken = function(token)
            self.token = token
            commonlib.setfield("System.User.keepworktoken", token)
        end,
        SetIsVipSchool = function(isVipSchool)
            self.isVipSchool = isVipSchool
            commonlib.setfield("System.User.isVipSchool", self.isVipSchool)
        end,
        Login = function(token, userId, username, nickname, realname, isVipSchool)
            self.token = token
            self.userId = userId
            self.username = username
            self.nickname = nickname
            self.realname = realname
            self.isVipSchool = isVipSchool

            commonlib.setfield("System.User.keepworktoken", self.token)
            commonlib.setfield("System.User.username", self.username)
            commonlib.setfield("System.User.keepworkUsername", self.username)
            commonlib.setfield("System.User.NickName", self.nickname)
            commonlib.setfield("System.User.realname", self.realname)
            commonlib.setfield("System.User.userType", self.userType)
            commonlib.setfield("System.User.isVip", self.isVip)
            commonlib.setfield("System.User.isVipSchool", self.isVipSchool)

            RestartTable.username = self.username

            self:onLogin()
        end,
        Logout = function()
            self.token = nil
            self.userId = nil
            self.username = nil
            self.nickname = nil
            self.myOrg = nil
            self.userType = nil

            commonlib.setfield("System.User.keepworktoken", nil)
            commonlib.setfield("System.User.username", nil)
            commonlib.setfield("System.User.keepworkUsername", nil)
            commonlib.setfield("System.User.NickName", nil)
            commonlib.setfield("System.User.userType", nil)
            commonlib.setfield("System.User.isVip", nil)
            

            self:onLogout()
        end,
        SetPlayerController = function(playerController)
            self.playerController = playerController
        end,
        SetThirdPartyLoginAuthinfo = function(authType, authCode)
            self.authType = authType
            self.authCode = authCode

            self:onSetThirdPartyLoginAuthinfo()
        end,
        SetWhereAnonymousUser = function(where)
            self.whereAnonymousUser = where
            RestartTable.whereAnonymousUser = where
        end
    }
end

function UserStore:Getter()
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
