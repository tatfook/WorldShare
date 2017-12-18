--[[
Title: WorldShareMod
Author(s):  Big
Date: 2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/main.lua");
local WorldShare = commonlib.gettable("Mod.WorldShare");
------------------------------------------------------------
]]

NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua");
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/Files.lua");

local GameLogic  = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local Encoding   = commonlib.gettable("commonlib.Encoding");
local loginMain  = commonlib.gettable("Mod.WorldShare.login.loginMain");
local SyncMain   = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local WorldShare = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.WorldShare"));

WorldShare:Property({"Name", "WorldShare"});

-- LOG.SetLogLevel("DEBUG");

function WorldShare:ctor()
end

function WorldShare:GetName()
    return self.Name;
end

function WorldShare:GetDesc()
    return self.Desc;
end

function WorldShare:init()
    -- replace load world page
    GameLogic.GetFilters():add_filter("InternetLoadWorld.ShowPage",function (bEnable, bShow)
        NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
        local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain");
        loginMain.ShowPage();
        return false;
    end);

    -- replace the exit world dialog
    GameLogic.GetFilters():add_filter("ShowExitDialog",function (dialog)
        if(dialog and dialog.callback) then
            NPL.load("(gl)Mod/WorldShare/login/WorldExitDialog.lua");
            local WorldExitDialog = commonlib.gettable("Mod.WorldShare.login.WorldExitDialog");
            WorldExitDialog.ShowPage(dialog.callback);
            return nil;
        end
    end);

    -- replace share world page
    GameLogic.GetFilters():add_filter("SaveWorldPage.ShowSharePage",function (bEnable)
        NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua");
        local ShareWorld = commonlib.gettable("Mod.WorldShare.sync.ShareWorld");
        ShareWorld.ShowPage()
        return false;
    end);
end

function WorldShare:OnInitDesktop()
end

function WorldShare:OnLogin()
end

function WorldShare:OnWorldLoad()
    SyncMain:init();
end

function WorldShare:OnDestroy()
end
