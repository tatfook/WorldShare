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