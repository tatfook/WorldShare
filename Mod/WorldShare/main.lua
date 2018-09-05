--[[
Title: WorldShareMod
Author(s):  Big
Date: 2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/main.lua")
local WorldShare = commonlib.gettable("Mod.WorldShare")
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Files.lua")
NPL.load("(gl)script/ide/Encoding.lua")
NPL.load("(gl)script/ide/System/Encoding/sha1.lua")
NPL.load("(gl)script/ide/System/Encoding/base64.lua")
NPL.load("(gl)script/ide/System/Windows/Screen.lua")
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteServerList.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua")

local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
local CreateWorld = NPL.load("(gl)Mod/WorldShare/cellar/Login/CreateWorld.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncMain.lua")
local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")
local WorldExitDialog = NPL.load("(gl)Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua")

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local WorldShare = commonlib.inherit(commonlib.gettable("Mod.ModBase"), commonlib.gettable("Mod.WorldShare"))

WorldShare:Property({"Name", "WorldShare"})

-- LOG.SetLogLevel("DEBUG");

function WorldShare:ctor()
end

function WorldShare:GetName()
    return self.Name
end

function WorldShare:GetDesc()
    return self.Desc
end

function WorldShare:init()
    -- replace load world page
    GameLogic.GetFilters():add_filter(
        "InternetLoadWorld.ShowPage",
        function(bEnable, bShow)
            LoginMain.ShowLoginMainPage()
            return false
        end
    )

    -- replace the exit world dialog
    GameLogic.GetFilters():add_filter(
        "ShowExitDialog",
        function(dialog)
            if (dialog and dialog.callback) then
                WorldExitDialog.ShowPage(dialog.callback)
                return nil
            end
        end
    )

    -- replace share world page
    GameLogic.GetFilters():add_filter(
        "SaveWorldPage.ShowSharePage",
        function(bEnable)
            ShareWorld:init()
            return false
        end
    )

    -- replca implement or replace create new world event
    GameLogic.GetFilters():add_filter(
        "OnClickCreateWorld",
        function()
            CreateWorld.OnClickCreateWorld()
            return false
        end
    )
end

function WorldShare:OnInitDesktop()
end

function WorldShare:OnLogin()
end

function WorldShare:OnWorldLoad()
    Store:set("world/IsEnterWorld", true)

    LoginMain.closeLoginMainPage()

    CreateWorld:CheckRevision(
        function()
            SyncMain:SyncWillEnterWorld()
        end
    )
end
