--[[
Title: login
Author(s):  big
Date: 2017/4/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/loginMain.lua");
local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain");
loginMain.ShowPage()
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
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
NPL.load("(gl)Mod/WorldShare/main.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");

local CreateNewWorld	 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld");
local LocalLoadWorld	 = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld");
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
local ShareWorldPage     = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");

local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain");

loginMain.LoginPage = nil;
loginMain.InforPage = nil;
loginMain.ModalPage = nil;

loginMain.login_type   = 1;
loginMain.site         = "http://keepwork.com";
loginMain.current_type = 1;

function loginMain:ctor()
end

function loginMain.init()
end

function loginMain.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "Mod/WorldShare/login/LoginMain.html", 
			name = "LoadMainWorld", 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
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
end

function loginMain.OnInit()
end

function loginMain.setLoginPage()
	loginMain.LoginPage = document:GetPageCtrl();
end

function loginMain.setInforPage()
	if(loginMain.InforPage) then
		loginMain.InforPage:CloseWindow();
	end
	loginMain.InforPage = document:GetPageCtrl();
end

function loginMain.setModalPage()
	loginMain.ModalPage = document:GetPageCtrl();
end

function loginMain.closeLoginInfo(delayTimeMs)
	commonlib.TimerManager.SetTimeout(function()  
		if(loginMain.InforPage) then
			loginMain.InforPage:CloseWindow();
			loginMain.InforPage = nil;
		end
	end, delayTimeMs or 500)
end

function loginMain.closeModalPage()
	loginMain.ModalPage:CloseWindow();
end

function loginMain.refreshPage()
	loginMain.LoginPage:Refresh();
end

function loginMain.showLoginInfo()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "Mod/WorldShare/login/loginInfor.html",
		name = "loginMain.loginInfor",
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		isTopLevel = true,
		zorder = 1,
		directPosition = true,
			align = "_ct",
			x = -300/2,
			y = -150/2,
			width = 500,
			height = 270,
	});
end

function loginMain.showLoginModalImp()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "Mod/WorldShare/login/LoginModal.html",
		name = "loginMain.LoginModal",
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		isTopLevel = true,
		directPosition = true,
			align = "_ct",
			x = -320/2,
			y = -350/2,
			width = 320,
			height = 350,
	});
end

function loginMain.LoginAction(_page, _callback)
	local account       = _page:GetValue("account");
	local password      = _page:GetValue("password");
	local loginServer   = _page:GetValue("loginServer");
	local isRememberPwd = _page:GetValue("rememberPassword"); 
	local autoLogin     = _page:GetValue("autoLogin"); 

	if(account == nil or account == "") then
	    _guihelper.MessageBox(L"账号不能为空");
	    return;
	end

	if(password == nil or password == "") then
	    _guihelper.MessageBox(L"密码不能为空");
	    return;
	end

	loginMain.showLoginInfo();

	loginMain.LoginActionApi(account,password,function (response,err)
			LOG.std(nil,"debug","response",response);
			if(type(response) == "table") then
				if(response['data'] ~= nil and response['data']['userinfo']['_id']) then
					loginMain.token = response['data']['token'];

					-- 如果记住密码则保存密码到redist根目录下
					if(isRememberPwd) then
						local file      = ParaIO.open("/PWD", "w");
						local encodePwd = Encoding.PasswordEncodeWithMac(password);
						
						local value;

						if(autoLogin) then
							value = account .. "|" .. encodePwd .. "|" .. loginServer .. "|" .. loginMain.token .. "|" .. "true";
						else
							value = account .. "|" .. encodePwd .. "|" .. loginServer .. "|" .. loginMain.token .. "|" .. "false";
						end

						file:write(value,#value);
						file:close();
					else
						-- 判断文件是否存在，如果存在则删除文件
						if(loginMain.findPWDFiles()) then
							ParaIO.DeleteFile("PWD");
						end
					end

					local userinfo = response['data']['userinfo'];

					loginMain.username = userinfo['displayName'];
					loginMain.userId   = userinfo['_id'];

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

						loginMain.dataSourceId       = userinfo['dataSourceId'];				-- 数据源
						loginMain.dataSourceToken    = defaultDataSource['dataSourceToken'];    -- 数据源Token
						loginMain.dataSourceUsername = defaultDataSource['dataSourceUsername']; -- 数据源用户名
						loginMain.dataSourceType     = defaultDataSource['type'];				-- 数据源类型
						loginMain.apiBaseUrl		 = defaultDataSource['apiBaseUrl']			-- 数据源api
						loginMain.rawBaseUrl		 = defaultDataSource['rawBaseUrl']          -- 数据源raw
						loginMain.keepWorkDataSource = defaultDataSource['projectName']			-- keepwork仓名

						--echo({loginMain.dataSourceToken,loginMain.dataSourceUsername});
						loginMain.personPageUrl = loginMain.site .. "/" .. loginMain.username .. "/paracraft/index";--loginMain.site .. "/wiki/mod/worldshare/person/#?userid=" .. userinfo._id;

						--local myWorlds = loginMain.LoginPage:GetNode("myWorlds");
						--myWorlds:SetAttribute("href", loginMain.personPageUrl);--loginMain.site.."/wiki/mod/worldshare/person/"
						
						loginMain.changeLoginType(3);
						loginMain.closeLoginInfo();
						loginMain.syncWorldsList();

						if(loginMain.ModalPage) then
							loginMain.closeModalPage();
						end

						if(_callback) then
							_callback();
						end

						local requestParams = {
							url  = loginMain.site .. "/api/mod/worldshare/models/worlds",
							json = true,
							headers = {Authorization = "Bearer "..loginMain.token},
							form = {amount = 10000},
						}

						HttpRequest:GetUrl(requestParams,function(worldList, err)
							--LOG.std(nil,"debug","genWorldIndex-worldList-data",worldList);
							SyncMain:genIndexMD(_worldList);
						end);
					else
						--local clientLogin = Page:GetNode("clientLogin");
						--loginMain.changeLoginType(2);
						loginMain.closeLoginInfo();
						_guihelper.MessageBox(L"数据源不存在，请联系管理员");
						return;
					end

					--判断paracraf站点是否存在
					HttpRequest:GetUrl({
						url  = loginMain.site.."/api/wiki/models/website/getDetailInfo",
						json = true,
						headers = {Authorization = "Bearer "..loginMain.token},
						form = {
							username = loginMain.username,
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
							siteParams.desc = "paracraft作品集";
							siteParams.displayName = loginMain.username;
							siteParams.domain = "paracraft";
							siteParams.logoUrl = "";
							siteParams.name = "paracraft";
							siteParams.styleId = 1;
							siteParams.styleName = "WIKI样式";
							siteParams.templateId = 1;
							siteParams.templateName = "WIKI模板";
							siteParams.userId = loginMain.userId;
							siteParams.username = loginMain.username;

							HttpRequest:GetUrl({
								url  = loginMain.site .. "/api/wiki/models/website/new",
								json = true,
								headers = {Authorization = "Bearer " .. loginMain.token},
								form = siteParams,
							},function(data, err) 
								LOG.std(nil,"debug","new site",data);
							end);
						end
					end);
				else
					loginMain.closeLoginInfo();
					_guihelper.MessageBox(L"用户名或者密码错误");
				end
			else
				loginMain.closeLoginInfo();
				_guihelper.MessageBox(L"服务器连接失败");
			end
		end
	);
end

function loginMain.LoginActionModal()
	loginMain.LoginAction(loginMain.ModalPage, function()
		_guihelper.MessageBox(L"登陆成功");

		ShareWorldPage.ShowPage();
	end);
end

function loginMain.LoginActionMain()
	loginMain.LoginAction(loginMain.LoginPage);
end

function loginMain.IsMCVersion()
	if(System.options.mc) then
		return true;
	else
		return false;
	end
end

function loginMain.GetWorldSize(size, unit)
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
		if(not unit) then
			s = GetPreciseDecimal(size/1024/1024, 2) .. "M";
		elseif(unit == "KB") then
			s = GetPreciseDecimal(size/1024, 2) .. "KB";
		end
	else
		s = nil;
	end

	return s or "0";
end

function loginMain.formatStatus(_status)
	--LOG.std(nil, "debug", "_status", _status);
	if(_status == 1) then
		return L"仅本地";
	elseif(_status == 2) then
		return L"仅网络";
	elseif(_status == 3) then
		return L"本地版本与远程数据源一致";
	elseif(_status == 4) then
		return L"本地版本更加新";
	elseif(_status == 5) then
		return L"远程版本更加新";
	else
		return L"获取状态中";
	end
end

function loginMain.formatDatetime(_datetime)
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

function loginMain.GetWorldType()
	return InternetLoadWorld.type_ds;
end

function loginMain.CreateNewWorld()
	loginMain.LoginPage:CloseWindow();
	CreateNewWorld.ShowPage();
end

function loginMain.GetCurWorldInfo(info_type,world_index)
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

function loginMain.OnSwitchWorld(index)
	InternetLoadWorld.OnSwitchWorld(index);

	--local selected_world = InternetLoadWorld.cur_ds[index];
end

function loginMain.GetNetSpeed()
	return "100ms";
end

function loginMain.GetPeopleNumOnline()
	return "????";
end

function loginMain.InputSearchContent()
	InternetLoadWorld.isSearching = true;
	loginMain.LoginPage:Refresh(0.1);
end

function loginMain.ClosePage()
	if(SyncGUI.isStart) then
		_guihelper.MessageBox(L"世界同步中，请等待同步完成后再返回");
		return;
	end

	if(loginMain.IsMCVersion()) then
	    InternetLoadWorld.ReturnLastStep();
	else
	    loginMain.LoginPage:CloseWindow();
	end
end

function loginMain.GetDefaultValueForAddress()
	local s = "";

	if(loginMain.IsMCVersion()) then
		s = L"输入服务器地址";
	else
		s = L"输入服务器地址或者米米号";
	end

	return s;
end

function loginMain.LookPlayerInform()
	local cur_page = InternetLoadWorld.GetCurrentServerPage();
	local nid = cur_page.player_nid;

	if(nid) then
		Map3DSystem.App.Commands.Call(Map3DSystem.options.ViewProfileCommand, nid);
	end
end

function loginMain.IsBlockWorld()
	local cur_pageH = InternetLoadWorld.GetCurrentServerPage();

	if(cur_page.player_nid and cur_page.player_nid ~= "") then
		return false;
	else
		return true;
	end
end

function loginMain.OpenBBS()
	NPL.load("(gl)script/apps/Aries/Creator/Game/game_options.lua");

	local options = commonlib.gettable("MyCompany.Aries.Game.GameLogic.options");
	local url = options.bbs_home_url;

	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

function loginMain.OnImportWorld()
	ParaGlobal.ShellExecute("open", ParaIO.GetCurDirectory(0)..LocalLoadWorld.GetWorldFolder(), "", "", 1);
end

function loginMain.GetDesForWorld()
	local  str = ""
	return str;
end

function loginMain.GetOnlineDes()
	local isOnline = System.User.isOnline;
	local des = L"你的状态:";

	if(isOnline) then
		des = des..L"已登录";
	else
		des = des..L"未登录";
	end

	return des;
end

function loginMain.QQLogin()
	InternetLoadWorld.QQLogin();
end

function loginMain.OnChangeType(index)
	loginMain.current_type = index;
	InternetLoadWorld.OnChangeType(index);
end

function loginMain.BeHasWorldInSlot(is_empty_slot,is_buy_slot)
	local value;

	if(is_empty_slot or is_buy_slot) then
		value = false;
	else
		value = true;
	end

	return value;
end

function loginMain.OnPurchaseSaveSlot()
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

function loginMain.OnSaveToSlot(name)
	local slot_id = tonumber(name);
	InternetLoadWorld.OnSaveToSlot(slot_id);
end

function loginMain.IsSelfOnlineWorld()
	local cur_svr_page = InternetLoadWorld.GetCurrentServerPage() or {};

	if(InternetLoadWorld.type_index == 1 and cur_svr_page.name and cur_svr_page.name == "onlineworld") then
		return true;
	else
		return false;
	end
end

function loginMain.IsChangingName()
	return InternetLoadWorld.changedName;
end

function loginMain.IsChangingQQ()
	return InternetLoadWorld.changedQQ;
end

function loginMain.ChangeName()
	InternetLoadWorld.changedName = true;
	loginMain.LoginPage:Refresh(0.1);
end

function loginMain.SaveName()
	InternetLoadWorld.ChangeNickName();
	--changedName = false;
	--Page:Refresh(0.1);
end

function loginMain.ChangeQQ()
	InternetLoadWorld.changedQQ = true;
	loginMain.LoginPage:Refresh(0.1);
end

function loginMain.SaveQQ()
	InternetLoadWorld.changedQQ = false;
	loginMain.LoginPage:Refresh(0.1);
end

function loginMain.GetUserNickName()
	return System.User.NickName or L"匿名";
end

function loginMain.CancelChangeName()
	InternetLoadWorld.changedName = false;
	loginMain.LoginPage:Refresh(0.1);
end

function loginMain.findPWDFiles()
	local result = commonlib.Files.Find({}, "/", 0, 500,"*.*");

	for key,value in ipairs(result) do
	    if(value.filename == "PWD" and value.fileattr ~= 0) then
	        return true;
	    end
	end

	return false;
end

function loginMain.getRememberPassword()
	-- LOG.std(nil,"debug","getRememberPassword",PWD);

	local function setNodeValue(page)
		if(loginMain.findPWDFiles()) then
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

			page:SetNodeValue("account", PWD[1]);
			page:SetNodeValue("password",Encoding.PasswordDecodeWithMac(PWD[2]));

			page:GetNode("keepwork"):SetAttribute("selected",nil);
			page:GetNode("keepworkDev"):SetAttribute("selected",nil);
			page:GetNode("keepworkTest"):SetAttribute("selected",nil);
			page:GetNode("local"):SetAttribute("selected",nil);

			if(PWD[3] == "keepwork") then
				page:GetNode("keepwork"):SetAttribute("selected","selected");
			elseif(PWD[3] == "keepworkDev") then
				page:GetNode("keepworkDev"):SetAttribute("selected","selected");
			elseif(PWD[3] == "keepworkTest") then
				page:GetNode("keepworkTest"):SetAttribute("selected","selected");
			elseif(PWD[3] == "local") then
				page:GetNode("local"):SetAttribute("selected","selected");
			end

			page:GetNode("rememberPassword"):SetAttribute("checked","checked");

			if(not PWD[5] or PWD[5] == "true") then
				page:GetNode("autoLogin"):SetAttribute("checked","checked");
			else
				page:GetNode("autoLogin"):SetAttribute("checked",nil);
			end
		else
			page:GetNode("rememberPassword"):SetAttribute("checked",nil);
			page:GetNode("autoLogin"):SetAttribute("checked",nil);
		end
	end

	if(loginMain.LoginPage) then
		setNodeValue(loginMain.LoginPage);
	end

	if(loginMain.ModalPage) then
		setNodeValue(loginMain.ModalPage);
	end
end

function loginMain.setSite()
	local register;
	local loginServer;

	if(loginMain.LoginPage) then
		register    = loginMain.LoginPage:GetNode("register");
		loginServer = loginMain.LoginPage:GetValue("loginServer");
	end

	if(loginMain.ModalPage) then
		register    = loginMain.ModalPage:GetNode("register");
		loginServer = loginMain.ModalPage:GetValue("loginServer");
	end

	if(loginServer == "keepwork") then
	    loginMain.site = "http://keepwork.com";
	elseif(loginServer == "keepworkDev") then
	    loginMain.site = "http://dev.keepwork.com";
	elseif(loginServer == "keepworkTest") then
		loginMain.site = "http://test.keepwork.com";
	elseif(loginServer == "local") then
	    loginMain.site = "http://localhost:8099";
	end

	register:SetAttribute("href",loginMain.site .. "/wiki/home");
end

function loginMain.setRememberAuto()
	local function setRememberAuto(page)
		local account       = page:GetValue("account");
		local password      = page:GetValue("password");
		local loginServer   = page:GetValue("loginServer");

		local auto = page:GetValue("autoLogin");

		if(auto) then
			page:GetNode("autoLogin"):SetAttribute("checked","checked");
			page:GetNode("rememberPassword"):SetAttribute("checked","checked");
			page:SetNodeValue("account", account);
			page:SetNodeValue("password", password);

			page:Refresh(0.01);
		else
			local file = ParaIO.open("/PWD", "r");
			local binData = file:GetText(0, -1);
			file:close();

			--echo(binData);

			if(#binData == 0) then
				ParaIO.DeleteFile("PWD");
			else
				local newStr = ""
				local settingData = {};
				for value in string.gmatch(binData,"[^|]+") do
					settingData[#settingData + 1] = value;
				end

				newStr = newStr .. settingData[1] .. "|";
				newStr = newStr .. settingData[2] .. "|";
				newStr = newStr .. settingData[3] .. "|";
				newStr = newStr .. settingData[4] .. "|";
				newStr = newStr .. "false";

				local file = ParaIO.open("/PWD", "w");
				file:write(newStr,#newStr);
			
				file:close();
			end
		end
	end

	if(loginMain.LoginPage) then
		setRememberAuto(loginMain.LoginPage);
	end

	if(loginMain.ModalPage) then
		setRememberAuto(loginMain.ModalPage);
	end
end

function loginMain.setAutoRemember()
	local function setAutoRemember(page)
		local account       = page:GetValue("account");
		local password      = page:GetValue("password");
		local loginServer   = page:GetValue("loginServer");

		local remember = page:GetValue("rememberPassword");

		if(not remember) then
			page:GetNode("rememberPassword"):SetAttribute("checked",nil);
			page:GetNode("autoLogin"):SetAttribute("checked",nil);
			page:SetNodeValue("account", account);
			page:SetNodeValue("password", password);

			page:Refresh(0.01);

			if(loginMain.findPWDFiles()) then
				ParaIO.DeleteFile("PWD");
			end
		end
	end

	if(loginMain.LoginPage) then
		setAutoRemember(loginMain.LoginPage);
	end

	if(loginMain.ModalPage) then
		setAutoRemember(loginMain.ModalPage);
	end
end

function loginMain.autoLoginAction()

	local function autoLoginAction(_page)
		if(not loginMain.IsSignedIn()) then
			local autoLogin = _page:GetValue("autoLogin");

			if(autoLogin) then
				loginMain.LoginActionMain();
			end
		end
	end

	if(loginMain.LoginPage) then
		autoLoginAction(loginMain.LoginPage);
	end

	if(loginMain.ModalPage) then
		autoLoginAction(loginMain.ModalPage);
	end
end


function loginMain.IsSignedIn()
	return loginMain.token ~= nil;
end

function loginMain.logout()
	if(loginMain.IsSignedIn()) then
		loginMain.changeLoginType(1);
		loginMain:RefreshCurrentServerList();
	end
end

function loginMain.RefreshCurrentServerList()
	loginMain.refreshing = true;

	if(loginMain.login_type == 1) then
		loginMain.getLocalWorldList(function()
			loginMain.changeRevision(function()
				loginMain.refreshing = false;
			end);
		end);
	elseif(loginMain.login_type == 3) then
		loginMain.getLocalWorldList(function()
			loginMain.changeRevision(function()
				loginMain.syncWorldsList(function()
					loginMain.refreshing = false;
				end);
			end);
		end);
	end
end

function loginMain.getLocalWorldList(_callback)
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

function loginMain.changeRevision(_callback)
	commonlib.TimerManager.SetTimeout(function()
		local localWorlds = InternetLoadWorld.ServerPage_ds[1]['ds'];

		if(localWorlds) then
			--LOG.std(nil,"debug","localWorlds",localWorlds);

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

					--LOG.std(nil,"debug","zipWorldDir.default",zipWorldDir.default);

					value.revision = LocalService:GetZipRevision(zipWorldDir.default);
					value.size = LocalService:GetZipWorldSize(zipWorldDir.default);
				end
			end

			if(loginMain.LoginPage) then
				loginMain.LoginPage:Refresh();
			end

			if(_callback) then
				_callback();
			end

			return;
		else
			loginMain.changeRevision();
		end
	end, 30);
end

function loginMain.syncWorldsList(_callback)
	local localWorlds = InternetLoadWorld.cur_ds;

	if(not localWorlds) then
		localWorlds = {};
	end

	LOG.std(nil,"debug","localWorlds-syncWorldsList",localWorlds);
	--[[
		status代码含义:
		1:仅本地
		2:仅网络
		3:本地网络一致
		4:网络更新
		5:本地更新
	]]

	loginMain.getWorldsList(function(data,err)
		SyncMain.remoteWorldsList = data;
		LOG.std(nil,"debug","remoteWorldsList-syncWorldsList",SyncMain.remoteWorldsList);
	    -- 处理本地网络同时存在 本地不存在 网络存在 的世界 
	    for keyDistance,valueDistance in ipairs(SyncMain.remoteWorldsList) do
	        local isExist = false;

	        for keyLocal,valueLocal in ipairs(localWorlds) do
	            if(valueDistance["worldsName"] == valueLocal["foldername"]) then
	            	--LOG.std(nil,"debug","foldername",valueLocal["foldername"]);
	            	--LOG.std(nil,"debug","worldsName",valueDistance["worldsName"]);

					if(localWorlds[keyLocal].server) then
						if(tonumber(valueLocal["revision"]) == tonumber(valueDistance["revision"])) then
	            			localWorlds[keyLocal].status = 3; --本地网络一致
						elseif(tonumber(valueLocal["revision"]) > tonumber(valueDistance["revision"])) then
	            			localWorlds[keyLocal].status = 4; --网络更新
	            		elseif(tonumber(valueLocal["revision"]) < tonumber(valueDistance["revision"])) then
	            			localWorlds[keyLocal].status = 5; --本地更新
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

		if(loginMain.LoginPage) then
			loginMain.LoginPage:Refresh(0.01);
		end

		if(_callback) then
			_callback();
		end
	end);
end

function loginMain.enterWorld(_index)
	local index = tonumber(_index);
	SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];

	LOG.std(nil,"debug","SyncMain.selectedWorldInfor",SyncMain.selectedWorldInfor);

	if(SyncMain.selectedWorldInfor.status == 2) then
		loginMain.downloadWorld();
	else
		InternetLoadWorld.EnterWorld(_index);
	end
end

function loginMain.downloadWorld()
	SyncMain.foldername.utf8 = SyncMain.selectedWorldInfor.foldername;
	SyncMain.foldername.default = Encoding.Utf8ToDefault(SyncMain.foldername.utf8);

	SyncMain.worldDir.utf8    = "worlds/DesignHouse/" .. SyncMain.foldername.utf8 .. "/";
	SyncMain.worldDir.default = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";

	SyncMain.commitId = SyncMain:getGitlabCommitId(SyncMain.foldername.utf8);
	LOG.std(nil,"debug","SyncMain.commitId",SyncMain.commitId);
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

		    loginMain.LoginPage:Refresh();
		end
	end);
end

function loginMain.syncNow(_index)
	local index = tonumber(_index);
	SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];

	LOG.std(nil,"debug","SyncMain.selectedWorldInfor",SyncMain.selectedWorldInfor);
	if(loginMain.login_type == 3) then
		if(SyncMain.selectedWorldInfor.status ~= nil and SyncMain.selectedWorldInfor.status ~= 2)then
			if(SyncMain.selectedWorldInfor.is_zip)then
				_guihelper.MessageBox(L"不能同步ZIP文件");
				return;
			end

			SyncMain.foldername.utf8    = SyncMain.selectedWorldInfor.foldername;
			SyncMain.foldername.default = Encoding.Utf8ToDefault(SyncMain.foldername.utf8);

			SyncMain.worldDir.utf8 = "worlds/DesignHouse/" .. SyncMain.foldername.utf8 .. "/";
			SyncMain.worldDir.default = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";

			LOG.std(nil,"debug","SyncMain.worldDir.default",SyncMain.worldDir.default);
			SyncMain.syncCompare(true);
		else
			loginMain.downloadWorld();
			--_guihelper.MessageBox(L"本地无数据，请直接登陆");
		end
	else
		_guihelper.MessageBox(L"登陆后才能同步");
	end
end

function loginMain.deleteWorld(_index)
	--loginMain.LoginPage:CloseWindow();

	local index = tonumber(_index);
	SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[_index];

	if(SyncMain.tagInfor) then
		if(SyncMain.tagInfor.name == SyncMain.selectedWorldInfor.foldername) then
			_guihelper.MessageBox(L"不能刪除正在编辑的世界");
			return;
		end
	end

	SyncMain.deleteWorld();
end

function loginMain.sharePersonPage()
	local url = loginMain.personPageUrl;--loginMain.site .. "/wiki/mod/worldshare/share/#?type=person&userid=" .. login.userid;
	ParaGlobal.ShellExecute("open", url, "", "", 1);
end

function loginMain.LoginActionApi(_account,_password,_callback)
	local url = loginMain.site .. "/api/wiki/models/user/login";

	echo(url);

	HttpRequest:GetUrl({
		url  = url,
		json = true,
		form = {
			username = _account,
			password = _password,
		},
	},_callback);
end

function loginMain.getUserInfo(_callback)
	System.os.GetUrl({url = loginMain.site.."/api/wiki/models/user/",json = true,headers = {Authorization = "Bearer ".. loginMain.token}},_callback);
end

function loginMain.changeLoginType(_type)
	loginMain.login_type = _type;

	if(loginMain.LoginPage) then
		loginMain.LoginPage:Refresh();
	end
end

function loginMain.getWorldsList(_callback)
	local params = {
		url  = loginMain.site .. "/api/mod/worldshare/models/worlds",
		json = true,
		headers = {Authorization = "Bearer " .. loginMain.token},
		form = {amount = 100},
	};

	echo(params.url);

	HttpRequest:GetUrl(params,_callback);
end