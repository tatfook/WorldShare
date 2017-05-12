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
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteServerList.lua");
NPL.load("(gl)Mod/WorldShare/main.lua");

local WorldShare         = commonlib.gettable("Mod.WorldShare");
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
local RemoteServerList   = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList");

local login = commonlib.gettable("Mod.WorldShare.login");

login.LoginPage = nil;
login.InforPage = nil;

login.login_type   = 1;
login.site         = "http://keepwork.com";
login.current_type = 1;

function login:ctor()
end

function login.init()
end

function login.OnInit()
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

function login.setLoginPage()
	login.LoginPage = document:GetPageCtrl();
end

function login.setInforPage()
	login.InforPage = document:GetPageCtrl();
end

function login.closeLoginInfor()
	commonlib.TimerManager.SetTimeout(function()
		login.InforPage:CloseWindow();
	end,1000);
end

function login.refreshPage()
	login.LoginPage:Refresh();
end

function login.showLoginInfo()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "Mod/WorldShare/loginInfor.html",
		name = "login.loginInfor",
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		isTopLevel = true,
		directPosition = true,
			align = "_ct",
			x = -300/2,
			y = -150/2,
			width = 500,
			height = 270,
	});
end

function login.LoginAction()
	local account       = login.LoginPage:GetValue("account");
	local password      = login.LoginPage:GetValue("password");
	local loginServer   = login.LoginPage:GetValue("loginServer");
	local isRememberPwd = login.LoginPage:GetValue("rememberPassword"); 

	if(account == nil or account == "") then
	    _guihelper.MessageBox(L"账号不能为空");
	    return;
	end

	if(password == nil or password == "") then
	    _guihelper.MessageBox(L"密码不能为空");
	    return;
	end

	login.showLoginInfo();

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

						--local myWorlds = login.LoginPage:GetNode("myWorlds");
						--myWorlds:SetAttribute("href", login.personPageUrl);--login.site.."/wiki/mod/worldshare/person/"
						
						login.changeLoginType(3);
						login.syncWorldsList();

						login.closeLoginInfor();
					else
						--local clientLogin = Page:GetNode("clientLogin");
						--login.changeLoginType(2);
						login.closeLoginInfor();
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
					login.closeLoginInfor();
					_guihelper.MessageBox(L"用户名或者密码错误");
				end
			else
				login.closeLoginInfor();
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

	function GetPreciseDecimal(nNum, n)
		if type(nNum) ~= "number" then
			return nNum;
		end
    
		n = n or 0;
		n = math.floor(n)
		local fmt = '%.' .. n .. 'f'
		local nRet = tonumber(string.format(fmt, nNum))

		return nRet;
	end

	if(size and size ~= "") then
		s = GetPreciseDecimal(size/1024/1024, 2) .. "M";
	else
		s = nil;
	end

	return s or "0";
end

function login.formatStatus(_status)
	LOG.std(nil, "debug", "_status", _status);
	if(_status == 1) then
		return L"仅本地";
	elseif(_status == 2) then
		return L"仅网络";
	elseif(_status == 3) then
		return L"本地网络一致";
	elseif(_status == 4) then
		return L"网络更新";
	elseif(_status == 5) then
		return L"本地更新";
	else
		return L"未登录";
	end
end

function login.formatDatetime(_datetime)
	--LOG.std(nil,"debug","_datetime",_datetime);
	
	if(_datetime) then
		local n = 1;
		local formatDatetime = "";
		for value in string.gmatch(_datetime,"[^-]+") do
			--LOG.std(nil,"debug","formatDatetime",value);

			if(n == 3) then
				formatDatetime = formatDatetime .. value .. " ";
			elseif(n < 3) then
				formatDatetime = formatDatetime .. value .. "-";
			elseif(n == 5) then
				formatDatetime = formatDatetime .. value;
			elseif(n < 5) then
				formatDatetime = formatDatetime .. value .. ":"
			end

			n = n + 1;
		end

		return formatDatetime;
	end

	return _datetime;
end

function login.GetWorldType()
	return InternetLoadWorld.type_ds;
end

function login.CreateNewWorld()
	login.LoginPage:CloseWindow();

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

function login.OnSwitchWorld(index)
	InternetLoadWorld.OnSwitchWorld(index);

	--local selected_world = InternetLoadWorld.cur_ds[index];
end

function login.GetNetSpeed()
	return "100ms";
end

function login.GetPeopleNumOnline()
	return "????";
end

function login.InputSearchContent()
	InternetLoadWorld.isSearching = true;
	login.LoginPage:Refresh(0.1);
end

function login.ClosePage()
	if(SyncGUI.isStart) then
		_guihelper.MessageBox(L"世界同步中，请等待同步完成后再返回");
		return;
	end

	if(login.IsMCVersion()) then
	    InternetLoadWorld.ReturnLastStep();
	else
	    login.LoginPage:CloseWindow();
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
	login.LoginPage:Refresh(0.1);
end

function login.SaveName()
	InternetLoadWorld.ChangeNickName();
	--changedName = false;
	--Page:Refresh(0.1);
end

function login.ChangeQQ()
	InternetLoadWorld.changedQQ = true;
	login.LoginPage:Refresh(0.1);
end

function login.SaveQQ()
	InternetLoadWorld.changedQQ = false;
	login.LoginPage:Refresh(0.1);
end

function login.GetUserNickName()
	return System.User.NickName or L"匿名";
end

function login.CancelChangeName()
	InternetLoadWorld.changedName = false;
	login.LoginPage:Refresh(0.1);
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
	local isRememberPwd = login.LoginPage:GetNode("rememberPassword");

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

		login.LoginPage:SetNodeValue("account", PWD[1]);
		login.LoginPage:SetNodeValue("password",Encoding.PasswordDecodeWithMac(PWD[2]));

		login.LoginPage:GetNode("keepwork"):SetAttribute("selected",nil);
		login.LoginPage:GetNode("local"):SetAttribute("selected",nil);

		if(PWD[3] == "keepwork") then
			login.LoginPage:GetNode("keepwork"):SetAttribute("selected","selected");
		elseif(PWD[3] == "keepworkDev") then
			login.LoginPage:GetNode("keepworkDev"):SetAttribute("selected","selected");
		elseif(PWD[3] == "local") then
			login.LoginPage:GetNode("local"):SetAttribute("selected","selected");
		end

	    isRememberPwd:SetAttribute("checked","checked");
	else
	    isRememberPwd:SetAttribute("checked",nil);
	end
end

function login.setSite()
	local register    = login.LoginPage:GetNode("register");
	local loginServer = login.LoginPage:GetValue("loginServer");

	if(loginServer == "keepwork") then
	    login.site = "http://keepwork.com";
	elseif(loginServer == "keepworkDev") then
	    login.site = "http://dev.keepwork.com";
	elseif(loginServer == "local") then
	    login.site = "http://keepwork.local";
	end

	register:SetAttribute("href",login.site .. "/wiki/home");

	login.LoginPage:Refresh();
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

function login.RefreshCurrentServerList()
	if(login.login_type == 1) then
		login.getLocalWorldList(function()
			login.changeRevision();
		end);
	elseif(login.login_type == 3) then
		login.getLocalWorldList(function()
			login.changeRevision(function()
				login.syncWorldsList();
			end);
		end);
	end
end

function login.getLocalWorldList(_callback)
	local ServerPage = InternetLoadWorld.GetCurrentServerPage();
	
	RemoteServerList:new():Init("local", "localworld", function(bSucceed, serverlist)
		if(not serverlist:IsValid()) then
			BroadcastHelper.PushLabel({id="userworlddownload", label = L"无法下载服务器列表, 请检查网络连接", max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		end

		ServerPage.ds = serverlist.worlds or {};
		InternetLoadWorld.OnChangeServerPage();

		if(_callback) then
			_callback();
		end

	end);
end

function login.changeRevision(_callback)
	commonlib.TimerManager.SetTimeout(function()
		local localWorlds = InternetLoadWorld.ServerPage_ds[1]['ds'];

		if(localWorlds) then
			LOG.std(nil,"debug","localWorlds",localWorlds);

			for key,value in ipairs(localWorlds) do
				if(not value.is_zip) then
					value.modifyTime = value.revision;

					local foldername = {};
					foldername.utf8    = value.foldername;
					foldername.default = Encoding.Utf8ToDefault(value.foldername);

					local WorldRevisionCheckOut = WorldRevision:new():init("worlds/DesignHouse/" .. foldername.default .. "/");
					value.revision = WorldRevisionCheckOut:GetDiskRevision();

--					local worldSize = WorldShare:GetWorldData("worldSize", foldername.utf8);
					local tag = LocalService:GetTag(foldername.default);
					--LOG.std(nil,"debug","tag",tag);

					if(tag.size) then
						value.size = tag.size;
					else
						value.size = 0;
					end
				else
					value.modifyTime = value.revision;

					local zipWorldDir = {};
					zipWorldDir.default = value.remotefile:gsub("local://","");
					zipWorldDir.utf8 = Encoding.Utf8ToDefault(zipWorldDir.default);

					local zipFoldername = {};
					zipFoldername.default = zipWorldDir.default:gsub("worlds/DesignHouse/","");
					zipFoldername.utf8    = Encoding.Utf8ToDefault(zipFoldername.default);

					LOG.std(nil,"debug","zipWorldDir.default",zipWorldDir.default);

					value.revision = LocalService:GetZipRevision(zipWorldDir.default);
					value.size = LocalService:GetZipWorldSize(zipWorldDir.default);
				end
			end

			login.LoginPage:Refresh();

			if(_callback) then
				_callback();
			end

			return;
		else
			login.changeRevision();
		end
	end, 30);
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
		LOG.std(nil,"debug","remoteWorldsList-syncWorldsList",SyncMain.remoteWorldsList);
	    -- 处理本地网络同时存在 本地不存在 网络存在 的世界 
	    for keyDistance,valueDistance in ipairs(SyncMain.remoteWorldsList) do
	        local isExist = false;

	        for keyLocal,valueLocal in ipairs(localWorlds) do
	            if(valueDistance["worldsName"] == valueLocal["foldername"]) then
	            	LOG.std(nil,"debug","foldername",valueLocal["foldername"]);
	            	LOG.std(nil,"debug","worldsName",valueDistance["worldsName"]);

					if(localWorlds[keyLocal].server) then
						if(tonumber(valueLocal["revision"]) == tonumber(valueDistance["revision"])) then
	            			localWorlds[keyLocal].status = 3; --本地网络一致
	            		elseif(tonumber(valueLocal["revision"]) < tonumber(valueDistance["revision"])) then
	            			localWorlds[keyLocal].status = 5; --本地更新
	            		elseif(tonumber(valueLocal["revision"]) > tonumber(valueDistance["revision"])) then
	            			localWorlds[keyLocal].status = 4; --网络更新
	            		end
					end

	            	--localWorlds[kl].revision = vd["revision"];
	            	isExist = true;
	            	break;
	            end
	        end

	        if(not isExist) then
            	localWorlds[#localWorlds + 1] = {
            		text        = valueDistance["worldsName"];
            		foldername  = valueDistance["worldsName"];
            		revision    = valueDistance["revision"];
            		size        = valueDistance["filesTotals"];
					modifyTime  = valueDistance["modDate"];
            		status      = 2; --仅网络
            	};
	        end
	    end
		
	    -- 处理 本地存在 网络不存在 的世界
	    for keyLocal,valueLocal in ipairs(localWorlds) do
	        local isExist = false;

	        for keyDistance,valueDistance in ipairs(SyncMain.remoteWorldsList) do
	            if(valueLocal["foldername"] == valueDistance["worldsName"]) then
	            	isExist = true;
	            	break;
	            end
	        end

	        if(not isExist) then
	            localWorlds[keyLocal].status = 1; --仅本地
	        end
	    end

		--LOG.std(nil,"debug","localWorlds",localWorlds);

	    login.LoginPage:Refresh();

		if(_callback) then
			_callback();
		end
	end);
end

function login.enterWorld(_index)
	local index = tonumber(_index);
	SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];

	LOG.std(nil,"debug","SyncMain.selectedWorldInfor",SyncMain.selectedWorldInfor);

	if(SyncMain.selectedWorldInfor.status == 2) then
		login.downloadWorld();
	else
		InternetLoadWorld.EnterWorld(_index);
		login.enterStatus = true;
	end
end

function login.downloadWorld()
	SyncMain.foldername.utf8 = SyncMain.selectedWorldInfor.foldername;
	SyncMain.foldername.default = Encoding.Utf8ToDefault(SyncMain.foldername.utf8);

	SyncMain.worldDir.utf8    = "worlds/DesignHouse/" .. SyncMain.foldername.utf8 .. "/";
	SyncMain.worldDir.default = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";

	SyncMain.commitId = SyncMain:getGitlabCommitId(SyncMain.foldername.utf8);

	ParaIO.CreateDirectory(SyncMain.worldDir.default);

	SyncMain:syncToLocal(function(success, params)
		if(success) then
		    SyncMain.selectedWorldInfor.status      = 3;
		    SyncMain.selectedWorldInfor.server      = "local";
		    SyncMain.selectedWorldInfor.is_zip      = false;
		    SyncMain.selectedWorldInfor.icon        = "Texture/blocks/items/1013_Carrot.png";
		    SyncMain.selectedWorldInfor.revision    = params.revison;
		    SyncMain.selectedWorldInfor.filesTotals = params.filesTotals;
		    SyncMain.selectedWorldInfor.text 		= SyncMain.foldername.utf8;
		    SyncMain.selectedWorldInfor.world_mode  = "edit";
		    SyncMain.selectedWorldInfor.gs_nid      = "";
		    SyncMain.selectedWorldInfor.force_nid   = 0;
		    SyncMain.selectedWorldInfor.ws_id       = "";
		    SyncMain.selectedWorldInfor.author      = "";
		    SyncMain.selectedWorldInfor.remotefile  = "local://worlds/DesignHouse/" .. SyncMain.foldername.default;

		    login.LoginPage:Refresh();
		end
	end);
end

function login.syncNow(_index)
	local index = tonumber(_index);
	SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];

	LOG.std(nil,"debug","SyncMain.selectedWorldInfor",SyncMain.selectedWorldInfor);
	if(login.login_type == 3) then
		if(SyncMain.selectedWorldInfor.status ~= nil and SyncMain.selectedWorldInfor.status ~= 2)then
			if(not SyncMain.selectedWorldInfor.foldername)then
				_guihelper.MessageBox(L"不能同步ZIP文件");
				return;
			end

			SyncMain.foldername.utf8    = SyncMain.selectedWorldInfor.foldername;
			SyncMain.foldername.default = Encoding.Utf8ToDefault(SyncMain.foldername.utf8);

			SyncMain.worldDir.utf8 = "worlds/DesignHouse/" .. SyncMain.foldername.utf8 .. "/";
			SyncMain.worldDir.default = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";

			LOG.std(nil,"debug","SyncMain.worldDir.default",SyncMain.worldDir.default);
			SyncMain:compareRevision(true);
		else
			login.downloadWorld();
			--_guihelper.MessageBox(L"本地无数据，请直接登陆");
		end
	else
		_guihelper.MessageBox(L"登陆后才能同步");
	end
end

function login.deleteWorld(_index)
	login.LoginPage:CloseWindow();

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
	login.LoginPage:Refresh();
end

function login.getWorldsList(_callback) --_worldsName,
	HttpRequest:GetUrl({
		url  = login.site.."/api/mod/worldshare/models/worlds",
		json = true,
		headers = {Authorization = "Bearer " .. login.token},
		form = {amount = 100},
	},_callback);
end