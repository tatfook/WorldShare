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

local UserStore = commonlib.gettable('Mod.WorldShare.store.User')

function UserStore:Action()
    return {
        SetToken = function(token)
            self.token = token
            commonlib.setfield("System.User.keepworktoken", token)
        end,
        SetUserinfo = function(token, userId, username, nickname)
            self.token = token
            self.userId = userId
            self.username = username
            self.nickname = nickname

            commonlib.setfield("System.User.keepworktoken", token)
            commonlib.setfield("System.User.username", username)
            commonlib.setfield("System.User.keepworkUsername", username)
            commonlib.setfield("System.User.NickName", nickname)
        end,
        SetPlayerController = function(playerController)
            self.playerController = playerController
        end,
        Logout = function()
            self.token = nil
            self.userId = nil
            self.username = nil
            self.nickname = nil
            self.myOrg = nil

            commonlib.setfield("System.User.keepworktoken", nil)
            commonlib.setfield("System.User.username", nil)
            commonlib.setfield("System.User.keepworkUsername", nil)
            commonlib.setfield("System.User.NickName", nil)
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