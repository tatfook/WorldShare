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
NPL.load("(gl)Mod/WorldShare/ShareCommand.lua");
NPL.load("(gl)Mod/WorldShare/ShareItem.lua");
NPL.load("(gl)Mod/WorldShare/ShareGUI.lua");
NPL.load("(gl)Mod/WorldShare/ShareEntity.lua");
NPL.load("(gl)Mod/WorldShare/ShareSceneContext.lua");
NPL.load("(gl)Mod/WorldShare/ShowLogin.lua");

local ShareSceneContext = commonlib.gettable("Mod.Share.ShareSceneContext");

local GameLogic       = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local ShareItem		  = commonlib.gettable("Mod.Share.ShareItem");
local ShareGUI        = commonlib.gettable("Mod.Share.ShareGUI");
local ShareEntity     = commonlib.gettable("Mod.Share.ShareEntity");
local ShareCommand	  = commonlib.gettable("Mod.Share.ShareCommand");

local Share = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.Share"));

LOG.SetLogLevel("DEBUG");

function Share:ctor()

end

-- virtual function get mod name
function Share:GetName()
	return "Share"
end

-- virtual function get mod description 
function Share:GetDesc()
	return "Share is a plugin in paracraft"
end

function Share:init()
	ShareItem:init();
	ShareGUI:init();
	ShareEntity:init();
	ShareCommand:init();

	ShareSceneContext:ApplyToDefaultContext();

	local page = "Mod/WorldShare/ShowLogin.html";
	GameLogic.GetFilters():add_filter("LoginPage",function ()
		return page;
	end);

end

function Share:OnInitDesktop()
	LOG.std(nil,"debug","Share","OnInitDesktop");
	return true;
end

function Share:OnLogin()
end

-- called when a new world is loaded. 
function Share:OnWorldLoad()
	LOG.std(nil,"info","Share","Mod big on world loaded");

	ShareGUI:OnWorldLoad();
	--BigItem:OnWorldLoad();
end

function Share:handleKeyEvent(event)
	return ShareGUI:handleKeyEvent(event);
end

function Share:OnActivateDesktop(mode)
	local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");

	if(Desktop.mode) then
		-- GameLogic.ADDBBS("test",L"Big进入编辑模式",4000,"0 255 0");
	else
		-- GameLogic.AddBBS("test",L"Big进入游戏模式",4000,"255 255 0");
	end

	return;
end

-- called when a world is unloaded. 
function Share:OnLeaveWorld()
	LOG.std(nil,"info","Share","Mod Share on leave world");
	ShareGUI:OnLeaveWorld();
end

function Share:OnDestroy()
end

function Share:OnClickExitApp()
	--_guihelper.MessageBox("wanna exit?" , function()
		--ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
		--ParaGlobal.ExitApp();
	--end)
	ParaEngine.GetAttributeObject():SetField("IsWindowClosingAllowed", true);
	ParaGlobal.ExitApp();
	return true;
end
