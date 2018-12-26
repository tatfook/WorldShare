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
        SetUserinfo = function(token, username, nickname)
            self.token = token
            self.username = username
            self.nickname = nickname
            commonlib.setfield("System.User.keepworktoken", token)
            commonlib.setfield("System.User.username", username)
            commonlib.setfield("System.User.keepworkUsername", username)
            commonlib.setfield("System.User.NickName", nickname)
        end,
        SetPlayerController = function(playerController)
            self.playerController = playerController
        end
    }
end

function UserStore:Getter()
    return {
        GetPlayerController = function()
            return self.playerController
        end
    }
end