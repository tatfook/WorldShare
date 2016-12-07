--[[
Title: ShowLogin
Author(s):  big
Date: 2016/12/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/ShowLogin.lua");
local ShowLogin = commonlib.gettable("Mod.WorldShare.ShowLogin");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/GetUrl.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/DOM.lua");

local ShowLogin   = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.ShowLogin"));
InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local Page;

ShowLogin.login_type = 1;
local site  = "http://localhost:8099";

function ShowLogin:ctor()
end

function ShowLogin.OnInit()
	Page = document:GetPageCtrl();
end

function ShowLogin:loginAction(_account,_password,_callback)
	System.os.GetUrl({url = site.."/api/wiki/models/user/login", json = true,form = {email=_account,password=_password}},_callback);
end

function ShowLogin:getUserInfo(_callback)
	System.os.GetUrl({url = site.."/api/wiki/models/user/",json = true,headers = {Authorization = "Bearer "..self.token}},_callback);
end

function ShowLogin:changeLoginType(_type)
	self.login_type = _type;
	Page:Refresh(0.01);
end

function ShowLogin.OnClickSelectedWorld(_index)
	InternetLoadWorld.selected_world_index = _index or 1;
	Page:Refresh(0.01);

	if(mouse_button == "left") then
		InternetLoadWorld.DeleteSelectedWorld();
	end
end

function ShowLogin:syncWorldsList(_worldsName,_callback)
	System.os.GetUrl({
					  url = site.."/api/mod/WorldShare/models/worlds",
					  json=true,
					  headers = {Authorization = "Bearer "..self.token},
					  form = {worldsName = _worldsName}
					  },_callback);
end