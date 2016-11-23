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

function BigGUI:OnLogin()
	LOG.std(nil, "debug", "BigGUI", "BigGUI Login");
end

function BigGUI:OnWorldLoad()
	self:ShowMyGUI();
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
