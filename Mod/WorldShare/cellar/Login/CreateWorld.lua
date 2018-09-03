--[[
Title: CreateWorld
Author(s):  big
Date: 2018.08.1
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/CreateWorld.lua")
local CreateWorld = commonlib.gettable("Mod.WorldShare.login.CreateWorld")
------------------------------------------------------------
]]
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage")

local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncMain.lua")
local SyncCompare = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncCompare.lua")
local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local CreateWorld = NPL.export()

function CreateWorld.OnClickCreateWorld()
    Store:remove("world/enterWorld")
end

function CreateWorld:CheckRevision(callback)
    local enterWorld = Store:get("world/enterWorld")

    if (enterWorld and enterWorld.is_zip) then
        return false
    end

    function handleCheck()
        if (not SyncCompare:HasRevision()) then
            MsgBox:Show(L"正在初始化世界...")

            Utils.SetTimeOut(
                function()
                    self:CreateRevisionXml()
                    self:CreateSnapshot()

                    MsgBox:Close()

                    if (type(callback) == "function") then
                        callback()
                    end
                end,
                1000
            )

            MsgBox:Close()
        else

            if (type(callback) == "function") then
                callback()
            end
        end
    end

    if (SyncMain:isCommandEnter()) then
        SyncMain:CommandEnter(handleCheck)
    else
        handleCheck()
    end
end

function CreateWorld:CreateRevisionXml()
    local path = ParaWorld.GetWorldDirectory()
    local revisionPath = format("%srevision.xml", path)

    local exist = ParaIO.DoesFileExist(revisionPath)

    if not exist then
        local file = ParaIO.open(revisionPath, "w");
        file:WriteString("1")
        file:close();
    end
end

function CreateWorld:CreateSnapshot()
    ShareWorldPage.TakeSharePageImage()
end