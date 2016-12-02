--[[
Title: BigGUI
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/Test/BigGUI.lua");
local BigGUI = commonlib.gettable("Mod.Test.DemoGUI");
------------------------------------------------------------
]]

local BigGUI = commonlib.inherit(nil,commonlib.gettable("Mod.big.BigGUI"));

function BigGUI:ctor()
end

function BigGUI:init()
	LOG.std(nil, "info", "BigGUI", "init");
end

function BigGUI:ShowMyGUI()
	if(not self.page) then
		-- create if not created before
		NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
		self.page = Map3DSystem.mcml.PageCtrl:new({url="Mod/big/BigGUI.html"});		
		self.page:Create("BigGUI", nil, "_ct", -350,-200,700,400);
	end
end

function BigGUI:ShowLogin()
	-- NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
	-- self.page = Map3DSystem.mcml.PageCtrl:new({url="Mod/big/ShowLogin.html"});
	-- self.page:Create("BigGUI", nil, "_ct", -430,-235,860,470);
	
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/big/ShowLogin.html", 
		name = "LoadMainWorld", 
		isShowTitleBar = false,
		DestroyOnClose = false, -- prevent many ViewProfile pages staying in memory / false will only hide window
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 0,
		allowDrag = true,
		bShow = bShow,
		directPosition = true,
			align = "_ct",
			x = -860/2,
			y = -470/2,
			width = 860,
			height = 470,
		cancelShowAnimation = true,
	});

	LOG.std(nil, "info", "BigGUI", "BigGUI ShowLogin");
end

function BigGUI:HideLogin()
	self.page:Close();
	LOG.std(nil, "debug", "BigGUI", "BigGUI HideLogin");
end

function BigGUI:OnLogin()
	LOG.std(nil, "info", "BigGUI", "BigGUI Login");
end

function BigGUI:OnWorldLoad()
	self:ShowLogin();
	--self:ShowMyGUI();
end

function BigGUI:OnLeaveWorld()
end

function BigGUI:OnInitDesktop()
	
end

function BigGUI:handleKeyEvent(event)
	if(event.keyname == "DIK_SPACE") then
		_guihelper.MessageBox("you pressed "..event.keyname.." from Demo GUI");
		return true;
	end
end
