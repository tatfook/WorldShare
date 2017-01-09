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
NPL.load("(gl)Mod/WorldShare/GithubService.lua");

local ShowLogin     = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.ShowLogin"));
local MainLogin     = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local GithubService = commonlib.gettable("Mod.WorldShare.GithubService");
local Encoding      = commonlib.gettable("System.Encoding");
InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");

local Page;

ShowLogin.login_type = 1;
ShowLogin.site  = nil;

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

function ShowLogin:deleteWorldLocal(_callback)
	local world = InternetLoadWorld:GetCurrentWorld();
	if(not world) then
		_guihelper.MessageBox(L"请先选择世界")
		return;
	end

	_guihelper.MessageBox(format(L"确定删除本地世界:%s?", world.text or ""), function(res)
		LOG.std(nil, "info", "InternetLoadWorld", "ask to delete world %s", world.text or "");
		if(res and res == _guihelper.DialogResult.Yes) then
			if(world.RemoveLocalFile and world:RemoveLocalFile()) then
				InternetLoadWorld.RefreshAll();

			elseif(world.remotefile) then
				-- local world, delete all files in folder and the folder itself.
				local targetDir = world.remotefile:gsub("^local://", "");

				if(GameLogic.RemoveWorldFileWatcher) then
					-- file watcher may make folder deletion of current world directory not working. 
					GameLogic.RemoveWorldFileWatcher();
				end

				if(commonlib.Files.DeleteFolder(targetDir)) then  
					LOG.std(nil, "info", "LocalLoadWorld", "world dir deleted: %s ", targetDir);
					-- InternetLoadWorld.RefreshCurrentServerList();
					local foldername = targetDir:match("worlds/DesignHouse/(%w+)");

					self.handleCur_ds = {};
					local hasGithub    = false;
					for key,value in ipairs(InternetLoadWorld.cur_ds) do
						if(value.foldername == foldername and value.status == 3) then
							LOG.std(nil,"debug","value.status",value.status);
							value.status = 2;
							hasGithub = true;
						end

						if(value.foldername ~= foldername) then
							self.handleCur_ds[#self.handleCur_ds+1] = value;
						end
					end

					if(not hasGithub)then
						InternetLoadWorld.cur_ds = self.handleCur_ds;
					end

					-- LOG.std(nil,"debug","_callback",_callback);

					if(_callback) then
						_callback(foldername);
					else
						Page:CloseWindow();
	                    NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");

	                    local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

	                    if(not WorldCommon.GetWorldInfo()) then
	                        MainLogin.state.IsLoadMainWorldRequested = nil;
	                        MainLogin:next_step();
	                    end
					end
				else
					_guihelper.MessageBox(L"无法删除可能您没有足够的权限"); 
				end
			end
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function ShowLogin:deleteWorldGithubLogin()
	-- LOG.std(nil,"debug","ShowLogin.selectedWorldInfor",ShowLogin.selectedWorldInfor);

	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/DeleteWorldLogin.html", 
		name = "DeleteWorldLogin", 
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

function ShowLogin:deleteWorldGithub(_password)
	local foldername = ShowLogin.selectedWorldInfor.foldername;

	local AuthUrl    = "https://api.github.com/authorizations";
	local AuthParams = '{"scopes":["delete_repo"], "note":"' .. ParaGlobal.timeGetTime() .. '"}';
	local basicAuth  = self.login .. ":" .. _password;
	local AuthToken  = "";

	basicAuth = Encoding.base64(basicAuth);

	LOG.std(nil,"debug","basicAuth",basicAuth);

	GithubService:GetUrl({
		url        = AuthUrl,
		headers    = {
						Authorization  = "Basic " .. basicAuth,
						["User-Agent"]   = "npl",
				        ["content-type"] = "application/json"
			         },
		postfields = AuthParams
    },function(data,err)
    	local basicAuthData = {};
    	NPL.FromJson(data,basicAuthData);
    	AuthToken = basicAuthData.token;

	    _guihelper.MessageBox(format(L"确定删除远程世界:%s?", foldername or ""), function(res)
	    	Page:CloseWindow();
	    	LOG.std(nil,"debug","res and res == _guihelper.DialogResult.Yes",res);
	    	LOG.std(nil,"debug","self.deleteFolderName",foldername);

	    	if(res and res == 6) then
	    		GithubService:deleteResp(foldername, AuthToken,function(data,err)
	    			LOG.std(nil,"debug","GithubService:deleteResp",err);

	    			if(err == 204) then
	    				GithubService:GetUrl({
							method  = "DELETE",
							url     = ShowLogin.site.."/api/mod/WorldShare/models/worlds/",
							form    = {
								worldsName = ShowLogin.selectedWorldInfor.foldername,
							},
							json    = true,
							headers = {Authorization = "Bearer "..ShowLogin.token}
						},function(data,err) 
							-- LOG.std(nil,"debug","errrrrr",err);

							InternetLoadWorld.cur_ds = self.handleCur_ds;

			    			Page:CloseWindow();
				            NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");

				            local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

				            if(not WorldCommon.GetWorldInfo()) then
				                MainLogin.state.IsLoadMainWorldRequested = nil;
				                MainLogin:next_step();
				            end
						end);
			        else
			        	_guihelper.MessageBox(L"远程删除失败");

	    			end
	    		end)
	    	end
	    end);
	end)

end

function ShowLogin:deleteWorldAll()
	self:deleteWorldLocal(function()
		self:deleteWorldGithubLogin();
	end);
end

function ShowLogin:getWorldsList(_callback) --_worldsName,
	GithubService:GetUrl({
					  url = self.site.."/api/mod/WorldShare/models/worlds",
					  json=true,
					  headers = {Authorization = "Bearer "..self.token},
					  form = {amount = 100}
					  },_callback);
end