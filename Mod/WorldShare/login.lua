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
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua");
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua");
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua");

local SyncGUI			 = commonlib.gettable("Mod.WorldShare.sync.SyncGUI");
local LocalService		 = commonlib.gettable("Mod.WorldShare.service.LocalService");
local MainLogin          = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local HttpRequest        = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local GitlabService      = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local GithubService      = commonlib.gettable("Mod.WorldShare.service.GithubService");
local Encoding  	     = commonlib.gettable("commonlib.Encoding");
local InternetLoadWorld  = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local WorldRevision      = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local SyncMain			 = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local login = commonlib.gettable("Mod.WorldShare.login");

local Page;

login.login_type   = 1;
login.site         = "http://keepwork.com";
login.current_type = 1;

function login:ctor()
end

function login.init()
	GameLogic.GetFilters():add_filter("SaveWorldPage.ShowSharePage",function (bEnable)
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "Mod/WorldShare/sync/ShareWorld.html",
			name = "SaveWorldPage.ShowSharePage",
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -500/2,
				y = -270/2,
				width = 500,
				height = 270,
		});

		return false;
	end);
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

	_guihelper.MessageBox(L"正在登陆，请稍后...");

	login.LoginActionApi(account,password,function (response,err)
			LOG.std(nil,"debug","response",response);
			if(type(response) == "table") then
				if(response['data'] ~= nil and response['data']['userinfo']['_id']) then
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

					local userinfo = response['data']['userinfo'];

					login.username = userinfo['displayName'];
					login.userId   = userinfo['_id'];

					if(userinfo['dataSourceId'] and userinfo['dataSource'] ~= {}) then
						local defaultDataSource;

						for key,value in ipairs(userinfo['dataSource']) do
							if(value._id == userinfo['dataSourceId']) then
								defaultDataSource = value;
							end
						end

						if(not defaultDataSource) then
							_guihelper.MessageBox(L"默认数据源不存在");
							return
						end

						login.dataSourceId       = userinfo['dataSourceId'];				-- 数据源
						login.dataSourceToken    = defaultDataSource['dataSourceToken'];    -- 数据源Token
						login.dataSourceUsername = defaultDataSource['dataSourceUsername']; -- 数据源用户名
						login.dataSourceType     = defaultDataSource['type'];				-- 数据源类型
						login.apiBaseUrl		 = defaultDataSource['apiBaseUrl']			-- 数据源api
						login.rawBaseUrl		 = defaultDataSource['rawBaseUrl']          -- 数据源raw

						--echo({login.dataSourceToken,login.dataSourceUsername});
						login.personPageUrl = login.site .. "/" .. login.username .. "/paracraft/index";--login.site .. "/wiki/mod/worldshare/person/#?userid=" .. userinfo._id;

						local myWorlds = Page:GetNode("myWorlds");
						myWorlds:SetAttribute("href", login.personPageUrl);--login.site.."/wiki/mod/worldshare/person/"
						
						login.changeLoginType(3);
						login.syncWorldsList();
					else
						--local clientLogin = Page:GetNode("clientLogin");
						--login.changeLoginType(2);
						_guihelper.MessageBox(L"数据源不存在，请联系管理员");
						return;
					end

					--判断paracraf站点是否存在
					HttpRequest:GetUrl({
						url  = login.site.."/api/wiki/models/website/getDetailInfo",
						json = true,
						headers = {Authorization = "Bearer "..login.token},
						form = {
							username = login.username,
							sitename = "paracraft",
						},
					},function(data, err) 
						--LOG.std(nil,"debug","sitedata",data);
						local site = data["data"];
						if(not site.siteinfo) then
							--创建站点
							local siteParams = {};
							siteParams.categoryId = 1;
							siteParams.categoryName = "作品网站";
							siteParams.desc = "paracraft";
							siteParams.displayName = login.username;
							siteParams.domain = "paracraft";
							siteParams.logoUrl = "";
							siteParams.name = "paracraft";
							siteParams.styleId = 1;
							siteParams.styleName = "WIKI样式";
							siteParams.templateId = 1;
							siteParams.templateName = "WIKI模板";
							siteParams.userId = login.userId;
							siteParams.username = login.username;

							HttpRequest:GetUrl({
								url  = login.site.."/api/wiki/models/website/new",
								json = true,
								headers = {Authorization = "Bearer " .. login.token},
								form = siteParams,
							},function(data, err) 
								LOG.std(nil,"debug","new site",data);
							end);
						end
					end);
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
	size = tonumber(size);

	if(size and size ~= "") then
		if(size < 1048576) then
			s = string.format("%sKB",math.ceil(size/1024));
		else
			s = string.format("%sM",math.ceil(size/1024/1024));
		end
	else
		s = nil;
	end

	return s or "0";
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
	if(SyncGUI.isStart) then
		_guihelper.MessageBox(L"世界同步中，请等待同步完成后再返回");
		return;
	end

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
		elseif(PWD[3] == "keepworkDev") then
			Page:GetNode("keepworkDev"):SetAttribute("selected","selected");
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
	    login.site = "http://keepwork.com";
	elseif(loginServer == "keepworkDev") then
	    login.site = "http://dev.keepwork.com";
	elseif(loginServer == "local") then
	    login.site = "http://keepwork.local";
	end

	register:SetAttribute("href",login.site .. "/wiki/home");

	Page:Refresh();
end

function login.logout()
	login.changeLoginType(1);

	local localWorlds    = InternetLoadWorld.cur_ds;
	local newLocalWorlds = {};

	for key,value in ipairs(localWorlds) do
		if(value.revision ~= "2") then
			newLocalWorlds[#newLocalWorlds + 1] = value;
		end
	end

	InternetLoadWorld.cur_ds = newLocalWorlds;
end

function login.changeRevision()
	if(login.login_type == 1) then
		commonlib.TimerManager.SetTimeout(function()
			local localWorlds = InternetLoadWorld.ServerPage_ds[1]['ds'];

			if(localWorlds) then
				for key,value in ipairs(localWorlds) do
					value.filesTotals = LocalService:GetWorldFileSize(value.foldername);
				end

				--LOG.std(nil,"debug","localWorlds",localWorlds);

				for kl,vl in ipairs(localWorlds) do
					local WorldRevisionCheckOut = WorldRevision:new():init("worlds/DesignHouse/"..Encoding.Utf8ToDefault(vl.foldername).."/");
					localWorlds[kl].revision    = WorldRevisionCheckOut:GetDiskRevision();
				end

				Page:Refresh();
				return;
			else
				login.changeRevision();
			end
		end, 100);
	end
end

function login.syncWorldsList(_callback)
	local localWorlds = InternetLoadWorld.cur_ds;
	LOG.std(nil,"debug","localWorlds-syncWorldsList",localWorlds);
	--[[
		status代码含义:
		1:仅本地
		2:仅网络
		3:本地网络一致
		4:网络更新
		5:本地更新
	]]

	login.getWorldsList(function(data,err)
		SyncMain.remoteWorldsList = data;
		
	    -- 处理本地网络同时存在 本地不存在 网络存在 的世界 
	    for kd,vd in ipairs(data) do
	        local isExist = false;

	        for kl,vl in ipairs(localWorlds) do
	            if(vd["worldsName"] == vl["foldername"]) then
	            	LOG.std(nil,"debug","foldername",vl["foldername"]);
	            	LOG.std(nil,"debug","worldsName",vd["worldsName"]);

					if(localWorlds[kl].server) then
						if(tonumber(vl["revision"]) == tonumber(vd["revision"])) then
	            			localWorlds[kl].status      = 3; --本地网络一致
	            		elseif(tonumber(vl["revision"]) < tonumber(vd["revision"])) then
	            			localWorlds[kl].status      = 5; --本地更新
	            		elseif(tonumber(vl["revision"]) > tonumber(vd["revision"])) then
	            			localWorlds[kl].status      = 4; --网络更新
	            		end
					end

	            	--localWorlds[kl].revision = vd["revision"];
	            	isExist = true;
	            	break;
	            end
	        end

	        if(not isExist) then
            	localWorlds[#localWorlds + 1] = {
            		text        = vd["worldsName"];
            		foldername  = vd["worldsName"];
            		revision    = vd["revision"];
            		filesTotals = vd["filesTotals"];
            		status      = 2; --仅网络
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

		--LOG.std(nil,"debug","localWorlds",localWorlds);

	    Page:Refresh();

		if(_callback) then
			_callback();
		end
	end);
end

function login.enterWorld(_index)
	local index = tonumber(_index);
	SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];

	--LOG.std(nil,"debug","login.selectedWorldInfor",login.selectedWorldInfor);

	if(SyncMain.selectedWorldInfor.status == 2) then
		login.downloadWorld();
	else
		InternetLoadWorld.EnterWorld(_index);
	end
end

function login.downloadWorld()
	local foldername = SyncMain.selectedWorldInfor.foldername;
	local foldernameForLocal = Encoding.Utf8ToDefault(foldername);

	local worldDir = "worlds/DesignHouse/" .. foldername .. "/";
	local worldDirForLocal = "worlds/DesignHouse/" .. foldernameForLocal .. "/";

	for key,value in ipairs(SyncMain.remoteWorldsList) do
		if(value.worldsName == foldername) then
			GitlabService.projectId = value.gitlabProjectId;
		end
	end

	ParaIO.CreateDirectory(worldDirForLocal);
	SyncMain:syncToLocal(worldDir, SyncMain.selectedWorldInfor.foldername,function(success, params)
		if(success) then
		    SyncMain.selectedWorldInfor.status      = 3;
		    SyncMain.selectedWorldInfor.server      = "local";
		    SyncMain.selectedWorldInfor.is_zip      = false;
		    SyncMain.selectedWorldInfor.icon        = "Texture/blocks/items/1013_Carrot.png";
		    SyncMain.selectedWorldInfor.revision    = params.revison;
		    SyncMain.selectedWorldInfor.filesTotals = params.filesTotals;
		    SyncMain.selectedWorldInfor.text 		= foldername;
		    SyncMain.selectedWorldInfor.world_mode  = "edit";
		    SyncMain.selectedWorldInfor.gs_nid      = "";
		    SyncMain.selectedWorldInfor.force_nid   = 0;
		    SyncMain.selectedWorldInfor.ws_id       = "";
		    SyncMain.selectedWorldInfor.author      = "";
		    SyncMain.selectedWorldInfor.remotefile  = "local://worlds/DesignHouse/" .. foldernameForLocal;

		    Page:Refresh();
		end
	end);
end

function login.syncNow(_index)
	local index = tonumber(_index);
	SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];

	if(login.login_type == 3) then
		if(SyncMain.selectedWorldInfor.status ~= nil and SyncMain.selectedWorldInfor.status ~= 2)then
			local foldername = SyncMain.selectedWorldInfor.foldername;
			foldername = Encoding.Utf8ToDefault(foldername);

			local worldDir = "worlds/DesignHouse/" .. foldername .. "/";

			SyncMain.worldName = worldDir;
			LOG.std(nil,"debug","login.SyncMain.worldName",SyncMain.worldName);
			SyncMain:compareRevision(worldDir);
			SyncMain:StartSyncPage();
		else
			login.downloadWorld();
			--_guihelper.MessageBox(L"本地无数据，请直接登陆");
		end
	else
		_guihelper.MessageBox(L"登陆后才能同步");
	end
end

function login.deleteWorld(_index)
	Page:CloseWindow();

	local index = tonumber(_index);

	SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];
	SyncMain.deleteWorld();
end

function login.sharePersonPage()
	local url = login.personPageUrl;--login.site .. "/wiki/mod/worldshare/share/#?type=person&userid=" .. login.userid;
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

function login.LoginActionApi(_account,_password,_callback)
	local url = login.site .. "/api/wiki/models/user/login";
	HttpRequest:GetUrl({
		url  = url,
		json = true,
		form = {
			username = _account,
			password = _password,
		},
	},_callback);
end

function login.getUserInfo(_callback)
	System.os.GetUrl({url = login.site.."/api/wiki/models/user/",json = true,headers = {Authorization = "Bearer ".. login.token}},_callback);
end

function login.changeLoginType(_type)
	login.login_type = _type;
	Page:Refresh();
end

function login.getWorldsList(_callback) --_worldsName,
	HttpRequest:GetUrl({
		url  = login.site.."/api/mod/worldshare/models/worlds",
		json = true,
		headers = {Authorization = "Bearer "..login.token},
		form = {amount = 100},
	},_callback);
end