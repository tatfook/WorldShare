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

	LOG.std(nil, "info", "OKOKOKOK", "11111111111");

	local page = "Mod/WorldShare/ShowLogin.html";
	GameLogic.GetFilters():add_filter("LoginPage",function ()
		return page;
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
	LOG.std(nil,"info","Share","Mod big on world loaded");

	WorldShareGUI:OnWorldLoad();
	--BigItem:OnWorldLoad();
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
	--_guihelper.MessageBox("wanna exit?" , function()
		--ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
		--ParaGlobal.ExitApp();
	--end)
	ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
	ParaGlobal.ExitApp();
	return true;
end
