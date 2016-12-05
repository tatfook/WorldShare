--[[
Title: ShowLogin
Author(s):  big
Date: 2016/12/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/big/ShowLogin.lua");
local ShowLogin = commonlib.gettable("Mod.big.ShowLogin");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/GetUrl.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/DOM.lua");

local ShowLogin = commonlib.inherit(nil,commonlib.gettable("Mod.big.ShowLogin"));
local Page;

ShowLogin.login_type = 1;

function ShowLogin:ctor()
end

function ShowLogin.OnInit()
	Page = document:GetPageCtrl();
end

function ShowLogin:loginAction(_account,_password,_callback)
	LOG.std(nil, "debug", "loginAction", _account.._password);

	System.os.GetUrl({url = "http://localhost:8099/api/wiki/models/user/login", json = true,form = {email=_account,password=_password}},_callback);
end

function ShowLogin:getUserInfo(_token,_callback)
	System.os.GetUrl({url = "http://localhost:8099/api/wiki/models/user/",json = true,headers = {Authorization = "Bearer ".._token}},_callback);
end

function ShowLogin:changeLoginType(_type)
	self.login_type = _type;
	Page:Refresh(0.01);
end