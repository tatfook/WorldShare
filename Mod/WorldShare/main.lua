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
NPL.load("(gl)Mod/WorldShare/login.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/Files.lua");

local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local Encoding  = commonlib.gettable("commonlib.Encoding");
local SyncMain  = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local WorldShare = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.WorldShare"));

LOG.SetLogLevel("DEBUG");

function WorldShare:ctor()
end

-- virtual function get mod name
function WorldShare:GetName()
	return "WorldShare"
end

-- virtual function get mod description 
function WorldShare:GetDesc()
	return "WorldShare is a plugin in paracraft"
end

function WorldShare:init()
	GameLogic.GetFilters():add_filter("InternetLoadWorld.ShowPage",function (bEnable, bShow)
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "Mod/WorldShare/login.html", 
			name = "LoadMainWorld", 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 0,
			allowDrag = false,
			bShow = bShow,
			directPosition = true,
				align = "_ct",
				x = -860/2,
				y = -470/2,
				width = 860,
				height = 470,
			cancelShowAnimation = true,
		});

		return false;
	end);

	GameLogic.GetFilters():add_filter("SaveWorldPage.ShowSharePage",function (bEnable)
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "Mod/WorldShare/sync/ShareWorld.html",
			name = "SaveWorldPage.ShowSharePage",
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -310/2,
				y = -270/2,
				width = 310,
				height = 270,
		});

		return false;
	end);

	NPL.load("(gl)script/apps/WebServer/WebServer.lua");
	WebServer:Start("script/apps/WebServer/admin","0.0.0.0",8099);
end

function WorldShare:OnInitDesktop()
	-- LOG.std(nil,"debug","Share","OnInitDesktop");
	-- return true;
end

function WorldShare:OnLogin()
end

-- called when a new world is loaded. 
function WorldShare:OnWorldLoad()
	-- LOG.std(nil,"debug","Share","Mod WorldShare on world loaded");
	SyncMain:init();
end

function WorldShare:OnDestroy()
end
