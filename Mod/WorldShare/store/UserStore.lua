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

local UserStore = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable('Mod.WorldShare.store.User'))

UserStore:Signal("onLogin", function() end)
UserStore:Signal("onLogout", function() end)

function UserStore:Action()
    return {
        SetToken = function(token)
            self.token = token
            commonlib.setfield("System.User.keepworktoken", token)
        end,
        Login = function(token, userId, username, nickname)
            self.token = token
            self.userId = userId
            self.username = username
            self.nickname = nickname

            if self.userType == 'vip' then
                -- true or nil
                commonlib.setfield("System.User.isVip", true)
            end

            commonlib.setfield("System.User.keepworktoken", token)
            commonlib.setfield("System.User.username", username)
            commonlib.setfield("System.User.keepworkUsername", username)
            commonlib.setfield("System.User.NickName", nickname)
            commonlib.setfield("System.User.userType", self.userType)

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