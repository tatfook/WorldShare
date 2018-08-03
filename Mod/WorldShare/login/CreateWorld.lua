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
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncCompare.lua")
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua")
NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")

local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain")
local SyncCompare = commonlib.gettable("Mod.WorldShare.sync.SyncCompare")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")

local CreateWorld = commonlib.gettable("Mod.WorldShare.login.CreateWorld")

function CreateWorld.OnClickCreateWorld()
    GlobalStore.remove("enterWorld")
end

function CreateWorld.CheckRevision(callback)
    function handleCheck()
        if (not SyncCompare:HasRevision()) then
            LoginMain.showMessageInfo(L"请稍后...")

            Utils.SetTimeOut(
                function()
                    CommandManager:RunCommand("/save")
                    LoginMain.closeMessageInfo()
                    if (type(callback) == "function") then
                        callback()
                    end
                end,
                1000
            )
        end
    end

    SyncMain:CommandEnter(handleCheck)
end
