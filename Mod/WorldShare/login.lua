--[[
Title: login
Author(s):  big
Date: 2017/4/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login.lua");
local login = commonlib.gettable("Mod.WorldShare.login");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/GetUrl.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/DOM.lua");
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua");
NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua");
NPL.load("(gl)Mod/WorldShare/service/GithubService.lua");

local MainLogin          = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local HttpRequest        = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local GitlabService      = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local GithubService      = commonlib.gettable("Mod.WorldShare.service.GithubService");
local Encoding  	     = commonlib.gettable("commonlib.Encoding");
local InternetLoadWorld  = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local WorldRevision      = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local SyncMain           = commonlib.gettable("Mod.WorldShare.sync.syncMain");

local login = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.login"));

local Page;

login.login_type   = 1;
login.site         = "http://keepwork.local";
login.current_type = 1;

function login:ctor()
end

function login.OnInit()
	Page = document:GetPageCtrl();
end

function login.LoginAction()
	local account       = Page:GetValue("account");
	local password      = Page:GetValue("password");
	local loginServer   = Page:GetValue("loginServer");
	local isRememberPwd = Page:GetValue("rememberPassword"); 

	if(account == nil or account == "") then
	    _guihelper.MessageBox("账号不能为空");
	    return;
	end

	if(password == nil or password == "") then
	    _guihelper.MessageBox("密码不能为空");
	    return;
	end

	login.LoginActionApi(account,password,function (response,err)
			if(type(response) == "table") then
				if(response['data']['userInfo']['_id']) then
					login.token = response['data']['token'];

					-- 如果记住密码则保存密码到redist根目录下
					if(isRememberPwd) then
						local file      = ParaIO.open("/PWD", "w");
						local encodePwd = Encoding.PasswordEncodeWithMac(password);
						local value     = account .. "|" .. encodePwd .. "|" .. loginServer .. "|" .. login.token;
						file:write(value,#value);
						file:close();
					else
						-- 判断文件是否存在，如果存在则删除文件
						if(login.findPWDFiles()) then
							ParaIO.DeleteFile("PWD");
						end
					end

					local userInfo = response['data']['userInfo'];

					login.username = userInfo['displayName'];
					login.userId   = userInfo['_id'];

					if(userInfo['dataSourceId'] and userInfo['dataSource'] ~= {}) then
						local defaultDataSource;

						for key,value in ipairs(userInfo['dataSource']) do
							if(value._id == userInfo['dataSourceId']) then
								defaultDataSource = value;
							end
						end

						login.dataSourceToken    = defaultDataSource['dataSourceToken'];    -- 数据源Token
						login.dataSourceUsername = defaultDataSource['dataSourceUsername']; -- 数据源用户名
						login.dataSourceType     = defaultDataSource['type'];				-- 数据源类型
						login.apiBaseUrl		 = defaultDataSource['apiBaseUrl']			-- 数据源api

						--echo({login.dataSourceToken,login.dataSourceUsername});
						login.personPageUrl = login.site .. "/wiki/mod/worldshare/person/#?userid=" .. userInfo._id;

						local myWorlds = Page:GetNode("myWorlds");
						myWorlds:SetAttribute("href",login.site.."/wiki/mod/worldshare/person/");
						
						login.changeLoginType(3);
						login.syncWorldsList();
					else
						--local clientLogin = Page:GetNode("clientLogin");
						--login.changeLoginType(2);
						_guihelper.MessageBox(L"数据源不存在，请联系管理员");
					end
				else
					_guihelper.MessageBox(L"用户名或者密码错误");
				end
			else
				_guihelper.MessageBox(L"服务器连接失败");
			end
		end
	);
end

function login.IsMCVersion()
	if(System.options.mc) then
		return true;
	else
		return false;
	end
end

function login.GetWorldSize(size)
	local s;

	if(size and size ~= "") then
		s = string.format("%sM",size);
	else
		s = nil;
	end

	return s or "5M";
end

function login.GetWorldType()
	return InternetLoadWorld.type_ds;
end

function login.CreateNewWorld()
	Page:CloseWindow();

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");
	local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld");

	CreateNewWorld.ShowPage();
end

function login.GetCurWorldInfo(info_type,world_index)
	local index = tonumber(world_index);
	local selected_world = InternetLoadWorld.cur_ds[world_index]
	--local cur_world = InternetLoadWorld:GetCurrentWorld();

	if(selected_world) then
		if(info_type == "mode") then
			local mode = selected_world["world_mode"];

			if(mode == "edit") then
				return L"创作";
			else
				return L"参观";
			end
		else
			return selected_world[info_type];
		end
	end
end

function login.GetNetSpeed()
	return "100ms";
end

function login.GetPeopleNumOnline()
	return "????";
end

function login.InputSearchContent()
	InternetLoadWorld.isSearching = true;
	Page:Refresh(0.1);
end

function login.ClosePage()
	if(login.IsMCVersion()) then
	    InternetLoadWorld.ReturnLastStep();
	else
	    Page:CloseWindow();
	end
end

function login.GetDefaultValueForAddress()
	local s = "";

	if(login.IsMCVersion()) then
		s = L"输入服务器地址";
	else
		s = L"输入服务器地址或者米米号";
	end

	return s;
end

function login.LookPlayerInform()
	local cur_page = InternetLoadWorld.GetCurrentServerPage();
	local nid = cur_page.player_nid;

	if(nid) then
		Map3DSystem.App.Commands.Call(Map3DSystem.options.ViewProfileCommand, nid);
	end
end

function login.IsBlockWorld()
	local cur_pageH = InternetLoadWorld.GetCurrentServerPage();

	if(cur_page.player_nid and cur_page.player_nid ~= "") then
		return false;
	else
		return true;
	end
end

function login.OpenBBS()
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");

	local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options");
	local url = options.bbs_home_url;

	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

function login.OnImportWorld()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");

	local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld");
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..LocalLoadWorld.GetWorldFolder(), "", "", 1);
end

function login.GetDesForWorld()
	local  str = ""
	return str;
end

function login.GetOnlineDes()
	local isOnline = System.User.isOnline;
	local des = L"你的状态:";

	if(isOnline) then
		des = des..L"已登录";
	else
		des = des..L"未登录";
	end

	return des;
end

function login.QQLogin()
	InternetLoadWorld.QQLogin();
end

function login.OnChangeType(index)
	login.current_type = index;
	InternetLoadWorld.OnChangeType(index);
end

function login.BeHasWorldInSlot(is_empty_slot,is_buy_slot)
	local value;

	if(is_empty_slot or is_buy_slot) then
		value = false;
	else
		value = true;
	end

	return value;
end

function login.OnPurchaseSaveSlot()
	if(System.options.mc) then
		_guihelper.MessageBox(L"此功能暂未开放");
	else
		_guihelper.MessageBox(L"你尚未开启这个存档槽. 每购买一个会员物品, 可永久获得一个存档槽.", function(res)
			if(res) then
				local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
				System.App.Commands.GetCommand("Profile.Aries.PurchaseItemWnd"):Call({gsid = WorldUploadPage.ExtendedSlotCountGsid});
			end
		end);
	end
end

function login.OnSaveToSlot(name)
	local slot_id = tonumber(name);
	InternetLoadWorld.OnSaveToSlot(slot_id);
end

function login.IsSelfOnlineWorld()
	local cur_svr_page = InternetLoadWorld.GetCurrentServerPage() or {};

	if(InternetLoadWorld.type_index == 1 and cur_svr_page.name and cur_svr_page.name == "onlineworld") then
		return true;
	else
		return false;
	end
end

function login.IsChangingName()
	return InternetLoadWorld.changedName;
end

function login.IsChangingQQ()
	return InternetLoadWorld.changedQQ;
end

function login.ChangeName()
	InternetLoadWorld.changedName = true;
	Page:Refresh(0.1);
end

function login.SaveName()
	InternetLoadWorld.ChangeNickName();
	--changedName = false;
	--Page:Refresh(0.1);
end

function login.ChangeQQ()
	InternetLoadWorld.changedQQ = true;
	Page:Refresh(0.1);
end

function login.SaveQQ()
	InternetLoadWorld.changedQQ = false;
	Page:Refresh(0.1);
end

function login.GetUserNickName()
	return System.User.NickName or L"匿名";
end

function login.CancelChangeName()
	InternetLoadWorld.changedName = false;
	Page:Refresh(0.1);
end

function login.findPWDFiles()
	local result = commonlib.Files.Find({}, "/", 0, 500,"*.*");

	for key,value in ipairs(result) do
	    -- LOG.std(nil,"debug","findPWDFiles",value);
	    if(value.filename == "PWD" and value.fileattr ~= 0) then
	        return true;
	    end
	end

	return false;
end

function login.getRememberPassword()
	local isRememberPwd = Page:GetNode("rememberPassword");

	-- LOG.std(nil,"debug","getRememberPassword",PWD);

	if(login.findPWDFiles()) then
	    local file = ParaIO.open("/PWD", "r");
	    local fileContent = "";

	    if(file:IsValid()) then
			fileContent = file:GetText(0, -1);
			file:close();
		end

		local PWD = {};
		for value in string.gmatch(fileContent,"[^|]+") do
			PWD[#PWD+1] = value;
		end

		Page:SetNodeValue("account", PWD[1]);
		Page:SetNodeValue("password",Encoding.PasswordDecodeWithMac(PWD[2]));

		Page:GetNode("keepwork"):SetAttribute("selected",nil);
		Page:GetNode("local"):SetAttribute("selected",nil);

		if(PWD[3] == "keepwork") then
			Page:GetNode("keepwork"):SetAttribute("selected","selected");
		elseif(PWD[3] == "local") then
			Page:GetNode("local"):SetAttribute("selected","selected");
		end

	    isRememberPwd:SetAttribute("checked","checked");
	else
	    isRememberPwd:SetAttribute("checked",nil);
	end
end

function login.setSite()
	local register    = Page:GetNode("register");
	local loginServer = Page:GetValue("loginServer");

	if(loginServer == "keepwork") then
	    login.site = "http://keepwork.local";
	elseif(loginServer == "local") then
	    login.site = "http://localhost:8099";
	end

	register:SetAttribute("href",login.site .. "/wiki/home");

	Page:Refresh(0.01);
end

function login.logout()
	login.changeLoginType(1);
end

function login.changeRevision()
	commonlib.TimerManager.SetTimeout(function()
		local localWorlds = InternetLoadWorld.ServerPage_ds[1]['ds'];

		for kl,vl in ipairs(localWorlds) do
			local WorldRevisionCheckOut = WorldRevision:new():init("worlds/DesignHouse/"..Encoding.Utf8ToDefault(vl.foldername).."/");
			localWorlds[kl].revision    = WorldRevisionCheckOut:GetDiskRevision();
		end

		Page:Refresh();
	end, 100);
end

function login.syncWorldsList()
	local localWorlds = InternetLoadWorld.ServerPage_ds[1]['ds'];

	-- 防止重复数据
	if(not login.originLocalWorlds) then
	    login.originLocalWorlds = commonlib.copy(localWorlds);
	else
	    localWorlds = commonlib.copy(login.originLocalWorlds);
	end
	
	--[[
		status代码含义:
		1:仅本地
		2:仅网络
		3:本地网络一致
		4:网络更新
		5:本地更新
	]]

	login.getWorldsList(function(data,err) --worldsName,
	    -- 处理本地网络同时存在 本地不存在 网络存在 的世界 
	    for kd,vd in ipairs(data) do
	        local isExist = false;

	        for kl,vl in ipairs(localWorlds) do
	            if(vd["worldsName"] == vl["foldername"]) then

	            	-- LOG.std(nil,"debug","localVersion",vl["revision"]);
	            	-- LOG.std(nil,"debug","networkVersion",vd["revision"]);

	            	if(tonumber(vl["revision"]) == tonumber(vd["revision"])) then
	            		localWorlds[kl].status   = 3; --本地网络一致
	            	elseif(tonumber(vl["revision"]) < tonumber(vd["revision"])) then
	            		localWorlds[kl].status   = 5; --本地更新
	            	elseif(tonumber(vl["revision"]) > tonumber(vd["revision"])) then
	            		localWorlds[kl].status   = 4; --网络更新
	            	end

	            	-- localWorlds[kl].revision = vd["revision"];
	            	isExist = true;
	            	break;
	            end
	        end

	        if(not isExist) then
            	localWorlds[#localWorlds + 1] = {
            		text       = vd["worldsName"];
            		foldername = vd["worldsName"];
            		revision   = vd["date"];
            		status     = 2; --仅网络
            	};
	        end
	    end
		
	    -- 处理 本地存在 网络不存在 的世界
	    for kl,vl in ipairs(localWorlds) do
	        local isExist = false;

	        for kd,vd in ipairs(data) do
	            if(vl["foldername"] == vd["worldsName"]) then
	            	isExist = true;
	            	break;
	            end
	        end

	        if(not isExist) then
	            localWorlds[kl].status = 1; --仅本地
	        end
	    end

	    Page:Refresh();
	end);
end

function login.enterWorld(_index)
	local index = tonumber(_index);
	login.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];

	--LOG.std(nil,"debug","login.selectedWorldInfor",login.selectedWorldInfor);

	if(login.selectedWorldInfor.status == 2) then
		local worldDir = "worlds/DesignHouse/" .. login.selectedWorldInfor.foldername .. "/";

		ParaIO.CreateDirectory(worldDir);
		syncMain:syncToLocal(worldDir,login.selectedWorldInfor.foldername,function(_success,_revision)
		    if(_success) then
		        login.selectedWorldInfor.status      = 3;
		        login.selectedWorldInfor.server      = "local";
		        login.selectedWorldInfor.is_zip      = false;
		        login.selectedWorldInfor.icon        = "Texture/blocks/items/1013_Carrot.png";
		        login.selectedWorldInfor.revision    = _revision;
		        login.selectedWorldInfor.text 		 = login.selectedWorldInfor.foldername;
		        login.selectedWorldInfor.world_mode  = "edit";
		        login.selectedWorldInfor.gs_nid      = "";
		        login.selectedWorldInfor.force_nid   = 0;
		        login.selectedWorldInfor.ws_id       = "";
		        login.selectedWorldInfor.author      = "";
		        login.selectedWorldInfor.remotefile  = "local://worlds/DesignHouse/" .. login.selectedWorldInfor.foldername;

		        Page:Refresh();
		    end
		end);
	else
		InternetLoadWorld.EnterWorld(_index);
	end
end

function login.syncNow()
	_guihelper.MessageBox(L"同步世界");
end

function login.deleteWorldUI(_index)
	Page:CloseWindow();

	local index = tonumber(_index);
	login.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];

	login.deleteWorld();
end

function login.deleteWorld(_selectWorldInfor)
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

function login.deleteWorldLocal(_callback)
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

					login.handleCur_ds = {};
					local hasGithub    = false;
					for key,value in ipairs(InternetLoadWorld.cur_ds) do
						if(value.foldername == foldername and value.status == 3 or value.status == 4 or value.status == 5) then
							LOG.std(nil,"debug","value.status",value.status);
							value.status = 2;
							hasGithub = true;
						end

						if(value.foldername ~= foldername) then
							login.handleCur_ds[#login.handleCur_ds+1] = value;
						end
					end

					if(not hasGithub)then
						InternetLoadWorld.cur_ds = login.handleCur_ds;
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

function login.deleteWorldGithubLogin()
	-- LOG.std(nil,"debug","login.selectedWorldInfor",login.selectedWorldInfor);

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

function login.deleteWorldGithub(_password)
	local foldername = login.selectedWorldInfor.foldername;

	local AuthUrl    = "https://api.github.com/authorizations";
	local AuthParams = '{"scopes":["delete_repo"], "note":"' .. ParaGlobal.timeGetTime() .. '"}';
	local basicAuth  = login.login .. ":" .. _password;
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
    	LOG.std(nil,"debug","GetUrl",data);
    	local basicAuthData = data;

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
							url     = login.site.."/api/mod/WorldShare/models/worlds/",
							form    = {
								worldsName = login.selectedWorldInfor.foldername,
							},
							json    = true,
							headers = {Authorization = "Bearer "..login.token}
						},function(data,err)

							login.handleCur_ds = {};
							local hasLocal    = false;
							for key,value in ipairs(InternetLoadWorld.cur_ds) do
								if(value.foldername == foldername and value.status == 3 or value.status == 4 or value.status == 5) then
									LOG.std(nil,"debug","value.status",value.status);
									value.status = 1;
									hasLocal = true;
								end

								if(value.foldername ~= foldername) then
									login.handleCur_ds[#login.handleCur_ds+1] = value;
								end
							end

							if(not hasLocal)then
								InternetLoadWorld.cur_ds = login.handleCur_ds;
							end

			    			Page:CloseWindow();

				            NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
				            local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");

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

function login.deleteWorldAll()
	login.deleteWorldLocal(function()
		login.deleteWorldGithubLogin();
	end);
end

function login.sharePersonPage()
	local url = login.site .. "/wiki/mod/worldshare/share/#?type=person&userid=" .. login.userid;
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

function login.LoginActionApi(_account,_password,_callback)
	local url = login.site .. "/api/wiki/models/user/login";
	HttpRequest:GetUrl({
		url  = url,
		json = true,
		form = {
				email    = _account,
				password = _password,
		},
	},_callback);
end

function login.getUserInfo(_callback)
	System.os.GetUrl({url = login.site.."/api/wiki/models/user/",json = true,headers = {Authorization = "Bearer ".. login.token}},_callback);
end

function login.changeLoginType(_type)
	login.login_type = _type;
	Page:Refresh(0.01);
end

function login.getWorldsList(_callback) --_worldsName,
	HttpRequest:GetUrl({
		url  = login.site.."/api/mod/worldshare/models/worlds",
		json = true,
		headers = {Authorization = "Bearer "..login.token},
		form = {amount = 100},
	},_callback);
end