--[[
Title: CreateWorld
Author(s):  big
Date: 2018.08.1
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua")
------------------------------------------------------------
]]
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")
local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")

local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/Main.lua")
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local CreateWorld = NPL.export()

function CreateWorld:CreateNewWorld(foldername)
    CreateNewWorld.ShowPage()

    if type(foldername) == 'string' then
        CreateNewWorld.page:SetValue('new_world_name', foldername)
        CreateNewWorld.page:Refresh(0.01)
    end
end

function CreateWorld.OnClickCreateWorld()
    -- if not CreateWorld:CheckSpecialCharacter(CreateNewWorld.page:GetValue('new_world_name') or '') then
    --      -- that return true to OnClickCreateWorld filter if have special charactor
    --     return true
    -- end

    Mod.WorldShare.Store:Remove("world/currentWorld")

    return false
end

function CreateWorld:CheckRevision(callback)
    if not GameLogic.IsReadOnly() and not Compare:HasRevision() then
        Mod.WorldShare.MsgBox:Show(L"正在初始化世界...")
        self:CreateRevisionXml()
        Mod.WorldShare.MsgBox:Close()
    end
end

function CreateWorld:CreateRevisionXml()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or not currentWorld.worldpath then
        return false
    end

    local revisionPath = format("%s/revision.xml", currentWorld.worldpath)

    local exist = ParaIO.DoesFileExist(revisionPath)

    if not exist then
        local file = ParaIO.open(revisionPath, "w");
        file:WriteString("1")
        file:close();
    end
end

function CreateWorld:CheckSpecialCharacter(foldername)
    if string.match(foldername, "[_`~!@#$%%^&*()+=|{}':;',%[%]%.<>/?~！@#￥%……&*（）——+|{}；：”“。，、？©]+") then
        GameLogic.AddBBS(nil, L"世界名称不能含有特殊字符", 3000, "255 0 0")
        return false
    end

    return true
end