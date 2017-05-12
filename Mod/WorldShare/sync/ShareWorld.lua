--[[
Title: share world to datasource
Author(s): big
Date: 2017.5.12
Desc:  It can take snapshot for the current world. It can quick save or full save the world to datasource. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua");
local ShareWorld = commonlib.gettable("Mod.WorldShare.sync.ShareWorld");
-------------------------------------------------------
]]

NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
NPL.load("(gl)Mod/WorldShare/login.lua");

local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
local ShareWorld     = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.sync.ShareWorld"));
local SyncMain       = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
local login          = commonlib.gettable("Mod.WorldShare.login");

function ShareWorld:ctor()

end

function ShareWorld:init()
	local filepath = SyncMain.worldDir.default .. "preview.jpg";
	LOG.std(nil,"debug","filepath",filepath);
	SyncMain.ComparePage:SetNodeValue("ShareWorldImage", filepath);

	SyncMain.ComparePage:Refresh();
end

function ShareWorld.snapshot()
	ShareWorldPage.TakeSharePageImage();
	SyncMain.ComparePage:Refresh();
end

function ShareWorld.getWorldUrl()
	local url = login.site .. "/" .. login.username .. "/paracraft/" .. SyncMain.foldername.utf8;
	return url;
end

function ShareWorld.openWorldWebPage()
	local url = ShareWorld.getWorldUrl();
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

