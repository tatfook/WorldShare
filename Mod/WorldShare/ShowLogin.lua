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
ShowLogin.site  = "http://localhost:8099";

function ShowLogin:ctor()
end

function ShowLogin.OnInit()
	Page = document:GetPageCtrl();
end

function ShowLogin:loginAction(_account,_password,_callback)
	System.os.GetUrl({url = self.site.."/api/wiki/models/user/login", json = true,form = {email=_account,password=_password}},_callback);
end

function ShowLogin:getUserInfo(_callback)
	System.os.GetUrl({url = self.site.."/api/wiki/models/user/",json = true,headers = {Authorization = "Bearer "..self.token}},_callback);
end

function ShowLogin:changeLoginType(_type)
	self.login_type = _type;
	Page:Refresh(0.01);
end

function ShowLogin:deleteWorld(_selectWorldInfor)
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/DeleteWorld.html", 
		name = "DeleteWorld", 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory / false will only hide window
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 0,
		allowDrag = true,
		bShow = bShow,
		directPosition = true,
			align = "_ct",
			x = -500/2,
			y = -270/2,
			width = 500,
			height = 270,
		cancelShowAnimation = true,
	});
end

function ShowLogin:deleteWorldLocal()
	InternetLoadWorld.DeleteSelectedWorld();
end

function ShowLogin:deleteWorldGithub()

end

function ShowLogin:deleteWorldAll()

end

function ShowLogin:getWorldsList(_callback) --_worldsName,
	System.os.GetUrl({
					  url = self.site.."/api/mod/WorldShare/models/worlds",
					  json=true,
					  headers = {Authorization = "Bearer "..self.token},
					  --form = {worldsNameForm = _worldsName}
					  },_callback);
end