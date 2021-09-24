--[[
Title: Bind Database
Author(s): big
CreateDate: 2021.09.22
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local BindDatabase = NPL.load('(gl)Mod/OfflineMod/database/BindDatabase.lua')
------------------------------------------------------------
]]

local BindDatabase = NPL.export()

-- bind database structure
--[[
    {
        UUID = 'xxx-xxx-xxxxxx',
        machineID = 'xxx-xxx-xxxxxx',
        isBind = true,
        bindUsername = 'xxx',
        bindDate = '',
    }
]]
function BindDatabase:GetDatabase()
    if not self.tempDatabase then
        self.tempDatabase = GameLogic.GetPlayerController():LoadLocalData(
            'bind_devices',
            {
                UUID = nil,
                machineID = nil,
                isBind = nil,
                bindUsername = nil,
                bindDate = nil,
            },
            true
        )
    end

    return self.tempDatabase or {}
end

function BindDatabase:SetValue(key, value)
    local db = self:GetDatabase()

    db[key] = value
end

function BindDatabase:GetValue(key, value)
    local db = self:GetDatabase()

    return db[key]
end

function BindDatabase:SaveDatabase()
    GameLogic.GetPlayerController():SaveLocalData(
        'bind_devices',
        self:GetDatabase(),
        true
    )
end
