--[[
Title: CreateWorld
Author(s): big
CreateDate: 2018.08.01
ModifyDate: 2021.09.10
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
------------------------------------------------------------
]]

-- libs
local CreateNewWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.CreateNewWorld')

local CreateWorld = NPL.export()

function CreateWorld:CreateNewWorld(foldername)
    CreateNewWorld.ShowPage(true)

    if type(foldername) == 'string' then
        CreateNewWorld.page:SetValue('new_world_name', foldername)
        CreateNewWorld.page:Refresh(0.01)
    end
end

function CreateWorld.OnClickCreateWorld()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local currentWorldList = Mod.WorldShare.Store:Get('world/compareWorldList') or {}

    local beExisted = false
    local foldername = CreateNewWorld.page:GetValue('new_world_name')

    for key, item in ipairs(currentWorldList) do
        if item.foldername == foldername and
           currentWorld.foldername ~= foldername then
            _guihelper.MessageBox(L'世界名已存在，请列表中进入')
            return true
        end
    end

    Mod.WorldShare.Store:Remove('world/currentWorld')

    return false
end

function CreateWorld.ClosePage()
    CreateNewWorld.ClosePage()
end