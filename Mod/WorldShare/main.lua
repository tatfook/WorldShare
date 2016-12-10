--[[
Title: WorldShareMod
Author(s):  Big
Date: 2016/12/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/main.lua");
local Share = commonlib.gettable("Mod.Share");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/WorldShareCommand.lua");
NPL.load("(gl)Mod/WorldShare/WorldShareItem.lua");
NPL.load("(gl)Mod/WorldShare/WorldShareGUI.lua");
NPL.load("(gl)Mod/WorldShare/WorldShareEntity.lua");
NPL.load("(gl)Mod/WorldShare/WorldShareSceneContext.lua");
NPL.load("(gl)Mod/WorldShare/ShowLogin.lua");

local WorldShareSceneContext = commonlib.gettable("Mod.WorldShare.WorldShareSceneContext");

local GameLogic			= commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local WorldShareItem    = commonlib.gettable("Mod.WorldShare.WorldShareItem");
local WorldShareGUI     = commonlib.gettable("Mod.WorldShare.WorldShareGUI");
local WorldShareEntity  = commonlib.gettable("Mod.WorldShare.WorldShareEntity");
local WorldShareCommand = commonlib.gettable("Mod.WorldShare.WorldShareCommand");

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
	WorldShareItem:init();
	WorldShareGUI:init();
	WorldShareEntity:init();
	WorldShareCommand:init();

	WorldShareSceneContext:ApplyToDefaultContext();

	GameLogic.GetFilters():add_filter("InternetLoadWorld.ShowPage",function (bEnable, bShow)
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "Mod/WorldShare/ShowLogin.html", 
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
			url = "Mod/WorldShare/ExitWorld.html",
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
end

function WorldShare:OnInitDesktop()
	LOG.std(nil,"debug","Share","OnInitDesktop");
	return true;
end

function WorldShare:OnLogin()
end

-- called when a new world is loaded. 
function WorldShare:OnWorldLoad()
	LOG.std(nil,"debug","Share","Mod WorldShare on world loaded");

	WorldShareGUI:OnWorldLoad();
end

function WorldShare:handleKeyEvent(event)
	return WorldShareGUI:handleKeyEvent(event);
end

function WorldShare:OnActivateDesktop(mode)
	local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");

	if(Desktop.mode) then
		-- GameLogic.ADDBBS("test",L"Big进入编辑模式",4000,"0 255 0");
	else
		-- GameLogic.AddBBS("test",L"Big进入游戏模式",4000,"255 255 0");
	end

	return;
end

-- called when a world is unloaded. 
function WorldShare:OnLeaveWorld()
	LOG.std(nil,"info","Share","Mod Share on leave world");
	WorldShareGUI:OnLeaveWorld();
end

function WorldShare:OnDestroy()
end

function WorldShare:OnClickExitApp()
	-- _guihelper.MessageBox("wanna exit?" , function()
	-- 	ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
	-- 	ParaGlobal.ExitApp();
	-- end)

	-- ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
	-- ParaGlobal.ExitApp();
end
