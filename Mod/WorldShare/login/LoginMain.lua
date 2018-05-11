--[[
Title: login
Author(s):  big, minor refactor by LiXizhi
Date: 2017/4/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
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

local CreateNewWorld     = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld");
local LocalLoadWorld     = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld");
local WorldShare         = commonlib.gettable("Mod.WorldShare");
local SyncGUI            = commonlib.gettable("Mod.WorldShare.sync.SyncGUI");
local LocalService       = commonlib.gettable("Mod.WorldShare.service.LocalService");
local MainLogin          = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local HttpRequest        = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local GitlabService      = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local GithubService      = commonlib.gettable("Mod.WorldShare.service.GithubService");
local Encoding           = commonlib.gettable("commonlib.Encoding");
local InternetLoadWorld  = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local WorldRevision      = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local SyncMain           = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
local RemoteServerList   = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList");
local ShareWorldPage     = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
local GameLogic          = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain");

loginMain.LoginPage  = nil;
loginMain.InforPage  = nil;
loginMain.ModalPage  = nil;
loginMain.isVerified = "noLogin"; 

loginMain.login_type   = 1;
loginMain.site         = "http://keepwork.com";
loginMain.current_type = 1;
loginMain.serverLists  = {
    {value="keepwork"        , name="keepwork"        , text=L"使用KeepWork登录", selected=true},
    {value="keepworkRelease" , name="keepworkRelease" , text=L"使用KeepWorkRelease登录"},
    {value="keepworkDev"     , name="keepworkDev"     , text=L"使用KeepWorkDev登录"},
    {value="local"           , name="local"           , text=L"使用本地服务登录"},
}

function loginMain:ctor()
end

function loginMain.init()
end

function loginMain.ShowPage()
    local params = {
        url            = "Mod/WorldShare/login/LoginMain.html", 
        name           = "LoadMainWorld", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style          = CommonCtrl.WindowFrame.ContainerStyle,
        zorder         = 0,
        allowDrag      = true,
        bShow          = bShow,
        directPosition = true,
        align          = "_ct",
        x              = -850/2,
        y              = -470/2,
        width          = 850,
        height         = 470,
        cancelShowAnimation = true,
    }
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    params._page.OnClose = function()
        loginMain.LoginPage  = nil;
    end

    -- load last selected avatar if world is not loaded before. 
    loginMain.OnChangeAvatar();
    
    if(not loginMain.IsSignedIn() and loginMain.LoginWithTokenApi()) then
        return;
    end

    if(loginMain.notFirstTimeShown) then
        loginMain.ignore_auto_login = true;
    else
        loginMain.notFirstTimeShown = true;
        if(not loginMain.ignore_auto_login) then
            -- auto sign in here
            loginMain.checkDoAutoSignin(loginMain.LoginPage);
        end
    end

    if(loginMain.hasExplicitLogin) then
        loginMain.getRememberPassword();
        loginMain.setSite();
        -- loginMain.autoLoginAction("main");
    end
    loginMain.RefreshCurrentServerList();
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

function loginMain.refreshPage()
    loginMain.LoginPage:Refresh();
end

function loginMain.showMessageInfo(msg)
    loginMain.Msg = msg;
    
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url            = "Mod/WorldShare/login/Infor.html",
        name           = "loginMain.Infor",
        isShowTitleBar = false,
        DestroyOnClose = true,
        style          = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag      = false,
        isTopLevel     = true,
        zorder         = 1,
        directPosition = true,
        align          = "_ct",
        x              = -300/2,
        y              = -150/2,
        width          = 500,
        height         = 270,
    });

    loginMain.Msg = nil;
end

function loginMain.showLoginModalImp(callback)
    if(loginMain.LoginWithTokenApi(callback)) then
        return;
    end

    local params = {
        url            = "Mod/WorldShare/login/LoginModal.html",
        name           = "loginMain.LoginModal",
        isShowTitleBar = false,
        DestroyOnClose = true,
        style          = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag      = true,
        isTopLevel     = true,
        directPosition = true,
        align          = "_ct",
        x              = -320/2,
        y              = -350/2,
        width          = 320,
        height         = 350,
    }
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    params._page.OnClose = function()
        loginMain.modalCall  = nil;
    end

    if(type(callback) == "function") then
        loginMain.modalCall = callback;
    end

    loginMain.getRememberPassword();
    loginMain.setSite();
    loginMain.autoLoginAction("modal");
end

function loginMain.closeMessageInfo(delayTimeMs)
    commonlib.TimerManager.SetTimeout(function()  
        if(loginMain.InforPage) then
            loginMain.InforPage:CloseWindow();
            loginMain.InforPage = nil;
        end
    end, delayTimeMs or 500);
end

function loginMain.closeModalPage()
    loginMain.ModalPage:CloseWindow();
end

function loginResponse(page, response, err, callback)
    local account       = page and page:GetValue("account");
    local password      = page and page:GetValue("password");
    local loginServer   = page and page:GetValue("loginServer");
    local isRememberPwd = page and page:GetValue("rememberPassword"); 
    local autoLogin     = page and page:GetValue("autoLogin"); 
    
    if(type(response) == "table") then
        if(response['data'] ~= nil and response['data']['userinfo']['_id']) then
            if(not response['data']['userinfo']['realNameInfo']) then
                loginMain.isVerified = false;
            else
                loginMain.isVerified = true;
            end

            loginMain.token = response['data']['token'];

            -- 手机号或其他账号登陆时，重新获取用户名 
            account = response.data.userinfo.defaultSiteDataSource.username;

            local getDataSourceApi = loginMain.site .. '/api/wiki/models/site_data_source/getDefaultSiteDataSource'

            if(loginMain.token) then
                HttpRequest:GetUrl({
                    url     = getDataSourceApi,
                    json    = true,
                    headers = {
                        Authorization = "Bearer " .. loginMain.token,
                    },
                    form    = {
                        username = account
                    },
                }, function(data, err)
                    if(not data) then
                        _guihelper.MessageBox(L"数据源不存在，请联系管理员");
                        loginMain.closeMessageInfo();
                        return
                    end

                    local defaultSiteDataSource = data.data;

                    -- 如果记住密码则保存密码到redist根目录下
                    if(isRememberPwd) then
                        loginMain.SaveSigninInfo({
                            account = account,
                            password = password, 
                            loginServer = loginServer, 
                            token = loginMain.token,
                            autoLogin = autoLogin, 
                        });
                    end

                    local userinfo = response['data']['userinfo'];

                    loginMain.username = userinfo['username'];
                    loginMain.userId   = userinfo['_id'];
            
                    if(type(userinfo['vipInfo']) == "table" and userinfo["vipInfo"]["endDate"]) then
                        local endDate     = userinfo["vipInfo"]["endDate"];
                        local datePattern = "(%d+)-(%d+)-(%d+)";

                        local year, month, day = endDate:match(datePattern);

                        local endDateTimestamp;

                        if(year and month and day) then
                            endDateTimestamp = os.time({year = year, month = month, day = day});
                        end

                        if(not endDateTimestamp or endDateTimestamp < os.time()) then
                            loginMain.userType = "normal";
                        else
                            loginMain.userType = "vip";
                        end
                    else
                        loginMain.userType = "normal";
                    end

                    for _, value in ipairs(userinfo['dataSource']) do
                        if(value.type == defaultSiteDataSource.type) then
                            dataSourceSetting = value;
                            break;
                        end
                    end

                    if(not dataSourceSetting) then
                        _guihelper.MessageBox(L"数据源配置文件不存在");
                        loginMain.closeMessageInfo();
                        return
                    end

                    loginMain.dataSourceToken      = defaultSiteDataSource['dataSourceToken'];    -- 数据源Token
                    loginMain.dataSourceUsername   = defaultSiteDataSource['dataSourceUsername']; -- 数据源用户名
                    loginMain.dataSourceType       = defaultSiteDataSource['type']                -- 数据源类型
                    loginMain.apiBaseUrl           = defaultSiteDataSource['apiBaseUrl'];         -- 数据源api
                    loginMain.rawBaseUrl           = defaultSiteDataSource['rawBaseUrl'];         -- 数据源raw
                    loginMain.keepWorkDataSource   = defaultSiteDataSource['projectName'];        -- keepwork仓名
                    loginMain.keepWorkDataSourceId = defaultSiteDataSource['projectId'];          -- keepwork仓ID

                    loginMain.personPageUrl = loginMain.site .. "/" .. loginMain.username .. "/paracraft/index";--loginMain.site .. "/wiki/mod/worldshare/person/#?userid=" .. userinfo._id;

                    --判断paracraf站点是否存在，不存在则创建
                    HttpRequest:GetUrl({
                        url     = loginMain.site .. "/api/wiki/models/website/getDetailInfo",
                        json    = true,
                        headers = {Authorization = "Bearer "..loginMain.token},
                        form    = {
                            username = loginMain.username,
                            sitename = "paracraft",
                        },
                    },function(data, err)
                        local site = data["data"];
                            
                        if(not site) then
                            loginMain.closeMessageInfo();
                            _guihelper.MessageBox(L"检查站点失败");
                            return;
                        end

                        if(not site.siteinfo) then
                            --创建站点
                            local siteParams = {};

                            siteParams.categoryId   = 1;
                            siteParams.categoryName = "作品网站";
                            siteParams.desc         = "paracraft作品集";
                            siteParams.displayName  = loginMain.username;
                            siteParams.domain       = "paracraft";
                            siteParams.logoUrl      = "/wiki/assets/imgs/paracraft.png";
                            siteParams.name         = "paracraft";
                            siteParams.styleId      = 1;
                            siteParams.styleName    = "WIKI样式";
                            siteParams.templateId   = 1;
                            siteParams.templateName = "WIKI模板";
                            siteParams.userId   = loginMain.userId;
                            siteParams.username = loginMain.username;

                            HttpRequest:GetUrl({
                                url     = loginMain.site .. "/api/wiki/models/website/new",
                                json    = true,
                                headers = {Authorization = "Bearer " .. loginMain.token},
                                form    = siteParams,
                            },function(data, err) end);
                        end

                        loginMain.changeLoginType(3);
                        loginMain.closeMessageInfo();
                        loginMain.RefreshCurrentServerList();

                        if(loginMain.ModalPage) then
                            loginMain.closeModalPage();
                        end

                        if(type(callback) == "function") then
                            callback();
                        end

                        SyncMain:genIndexMD();
                        SyncMain:genThemeMD();
                    end);
                end)
            end
        else
            loginMain.closeMessageInfo();
            _guihelper.MessageBox(L"用户名或者密码错误");
        end
    else
        loginMain.closeMessageInfo();
        _guihelper.MessageBox(L"服务器连接失败");
    end
end

function loginMain.LoginAction(page, callback)
    local account       = page:GetValue("account");
    local password      = page:GetValue("password");

    page:SetNodeValue("account", account);
    page:SetNodeValue("password", password);

    if(account == nil or account == "") then
        _guihelper.MessageBox(L"账号不能为空");
        return;
    end

    if(password == nil or password == "") then
        _guihelper.MessageBox(L"密码不能为空");
        return;
    end

    loginMain.showMessageInfo(L"正在登陆，请稍后...");

    loginMain.LoginActionApi(account, password, function(response, err)
        loginResponse(page, response, err, callback);
    end);
end

function loginMain.LoginActionModal()
    loginMain.LoginAction(loginMain.ModalPage, function()

        if(type(loginMain.modalCall) == "function") then
            loginMain.modalCall();
        end

        loginMain.modalCall = nil;
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

function loginMain.formatDatetime(datetime)
    if(datetime) then
        local n = 1;
        local formatDatetime = "";
        for value in string.gmatch(datetime,"[^%-]+") do

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

    return datetime;
end

function loginMain.GetWorldType()
    return InternetLoadWorld.type_ds;
end

--[[ TODO: this makes paracraft NOT able to run when network is down.
local OnClickCreateWorld = CreateNewWorld.OnClickCreateWorld;

CreateNewWorld.OnClickCreateWorld = function()
    loginMain:sensitiveCheck(function(hasSensitive)
        if(hasSensitive) then
            _guihelper.MessageBox(L"世界名字中含有敏感词汇，请重新输入");
        else
            OnClickCreateWorld();
        end
    end)
end
]]

function loginMain:sensitiveCheck(callback)
    local new_world_name = CreateNewWorld.page:GetValue("new_world_name");

    if(new_world_name) then
        HttpRequest:GetUrl({
            url    = loginMain.site .. "/api/wiki/models/sensitive_words/query";
            form = {
                query = {
                    name = new_world_name
                }
            },
            json   = true,
        }, function(data, err)
            if(data and type(data) == "table") then
                if(data.data.total ~= 0) then
                    if(callback and type(callback) == "function") then
                        callback(true);
                    end
                else
                    if(callback and type(callback) == "function") then
                        callback(false);
                    end
                end
            end
        end);
    end
end

function loginMain.CreateNewWorld()
    loginMain.LoginPage:CloseWindow();
    CreateNewWorld.ShowPage();
end

function loginMain.GetCurWorldInfo(info_type, world_index)
    --local cur_world = InternetLoadWorld:GetCurrentWorld();

    local index          = tonumber(world_index);
    local selected_world = InternetLoadWorld.cur_ds[world_index];

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

function loginMain.updateWorldInfo(worldIndex, callback)
    local selectWorld = LocalLoadWorld.BuildLocalWorldList(true)[worldIndex];
    
    if(type(selectWorld) == "table") then
        local filesize = LocalService:GetWorldSize(selectWorld.worldpath);
        local worldTag = LocalService:GetTag(Encoding.Utf8ToDefault(selectWorld.foldername));

        worldTag.size = filesize;

        LocalService:SetTag(selectWorld.worldpath, worldTag);

        InternetLoadWorld.GetCurrentServerPage().ds[worldIndex].size = filesize;

        if(type(callback) == "function") then
            callback();
        end
    end
end

function loginMain.OnSwitchWorld(index)
    InternetLoadWorld.OnSwitchWorld(index);

    if(loginMain.current_type == 1) then
        loginMain.updateWorldInfo(index, function()
            loginMain.LoginPage:Refresh(0.01);
        end);
    else
        loginMain.LoginPage:Refresh(0.01);
    end
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
    if(loginMain.IsMCVersion()) then
        InternetLoadWorld.ReturnLastStep();
    end
    if(loginMain.LoginPage) then
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

local default_avatars = {
    "boy01", 
    "girl01", 
    "boy02", 
    "girl02", 
    "boy03", 
    "girl03", 
    "boy04", 
    "default", 
}
local cur_index = 1;

function loginMain.GetValidAvatarFilename(playerName)
    if(playerName) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
        local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
        PlayerAssetFile:Init();
        return PlayerAssetFile:GetValidAssetByString(playerName)
    end
end

--cycle through 
-- @param btnName: if nil, we will load the default one if scene is not started. 
function loginMain.OnChangeAvatar(btnName)
    if(not btnName) then
        local filename = GameLogic.options:GetMainPlayerAssetName();
        if(not GameLogic.IsStarted) then
            GameLogic.options:SetMainPlayerAssetName();
            filename = GameLogic.options:GetMainPlayerAssetName() or loginMain.GetValidAvatarFilename(default_avatars[cur_index]);
        end
        if(filename and loginMain.LoginPage) then
            loginMain.LoginPage:CallMethod("MyPlayer", "SetAssetFile", filename);
        end
        return
    end

    if(btnName == "pre") then
        cur_index = cur_index - 1;
    else
        cur_index = cur_index + 1;
    end
    cur_index = ((cur_index-1) % (#default_avatars)) + 1
    local playerName = default_avatars[cur_index];
    
    if(playerName and loginMain.LoginPage) then
        local filename = loginMain.GetValidAvatarFilename(playerName);
        if(filename) then
            if(GameLogic.RunCommand) then
                GameLogic.RunCommand("/avatar "..playerName);
            end
            GameLogic.options:SetMainPlayerAssetName(filename);
            loginMain.LoginPage:CallMethod("MyPlayer", "SetAssetFile", playerName);
        end
    end
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
    ParaGlobal.ShellExecute("open", LocalLoadWorld.GetWorldFolderFullPath(), "", "", 1);
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

function loginMain.OnClickLocalWorlds()
    loginMain.OnChangeType(1);
end

function loginMain.OnClickOfficialWorlds()
    NPL.load("(gl)Mod/WorldShare/login/BrowseRemoteWorlds.lua");
    local BrowseRemoteWorlds = commonlib.gettable("Mod.WorldShare.login.BrowseRemoteWorlds");
    BrowseRemoteWorlds.ShowPage(function(bHasEnteredWorld)
        if(bHasEnteredWorld) then
            loginMain.ClosePage();
        end
    end)
end

function loginMain.OnChangeType(index)
    loginMain.current_type = index;
    InternetLoadWorld.OnChangeType(index);

    loginMain.LoginPage:Refresh(0.01);
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

function loginMain.GetPasswordFile()
    if(not loginMain.filename_) then
        loginMain.filename_ = ParaIO.GetWritablePath() .. "PWD";
    end
    return loginMain.filename_;
end

-- @return nil if not found or {account, password, loginServer, autoLogin}
function loginMain.LoadSigninInfo()
    local file        = ParaIO.open(loginMain.GetPasswordFile(), "r");
    local fileContent = "";

    if(file:IsValid()) then
        fileContent = file:GetText(0, -1);
        file:close();

        local PWD = {};
        for value in string.gmatch(fileContent,"[^|]+") do
            PWD[#PWD+1] = value;
        end
        
        local info = {};
        if(PWD[1]) then
            info.account = PWD[1];
        end
        if(PWD[2]) then
            info.password = Encoding.PasswordDecodeWithMac(PWD[2]);
        end
        info.loginServer = PWD[3];
        if(PWD[4]) then
            info.token = Encoding.PasswordDecodeWithMac(PWD[4]);
        end
        info.autoLogin = (not PWD[5] or PWD[5] == "true");
        return info;
    end
end

-- @param info: if nil, we will delete the login info. 
function loginMain.SaveSigninInfo(info)
    if(not info) then
        ParaIO.DeleteFile(loginMain.GetPasswordFile());
    else
        local newStr = ""
        newStr = newStr .. (info.account or "") .. "|";
        newStr = newStr .. Encoding.PasswordEncodeWithMac(info.password or "") .. "|";
        newStr = newStr .. (info.loginServer or "") .. "|";
        newStr = newStr .. Encoding.PasswordEncodeWithMac(info.token or "") .. "|";
        newStr = newStr .. (info.autoLogin and "true" or "false");

        local file = ParaIO.open(loginMain.GetPasswordFile(), "w");
        if(file) then
            LOG.std(nil, "info", "loginMain", "save signin info to %s", loginMain.GetPasswordFile());
            file:write(newStr,#newStr);
            file:close();
        else
            LOG.std(nil, "error", "loginMain", "failed to write file to %s", loginMain.GetPasswordFile());
        end
    end
end

function loginMain.checkDoAutoSignin(callback)
    local info = loginMain.LoadSigninInfo();
    if(info) then
        if(info.autoLogin and info.account and info.password) then
            loginMain.showMessageInfo(L"正在登陆，请稍后...");
            loginMain.LoginActionApi(info.account, info.password, function(response, err)
                loginResponse(nil, response, err, callback);
            end);
        end
    end
end

function loginMain.getRememberPassword()
    local info = loginMain.LoadSigninInfo();
    local function getRememberPassword(page)
        if(info) then
            if(info.account) then
                page:SetValue("account", info.account);
            end

            if(info.password) then
                page:SetValue("password", info.password);
            end

            page:SetValue("loginServer", info.loginServer);
            page:SetValue("rememberPassword", true);

            page:SetValue("autoLogin", info.autoLogin == true);
        else
            page:SetValue("rememberPassword",false);
            page:SetValue("autoLogin", false);
        end
    end

    if(loginMain.LoginPage) then
        getRememberPassword(loginMain.LoginPage);
    end

    if(loginMain.ModalPage) then
        getRememberPassword(loginMain.ModalPage);
    end
end

function loginMain.setSite()
    local page;

    if(loginMain.LoginPage) then
        page = loginMain.LoginPage;
    end

    if(loginMain.ModalPage) then
        page = loginMain.ModalPage;
    end

    local loginServer = page:GetValue("loginServer");

    if(loginServer == "keepwork") then
        loginMain.site = "http://keepwork.com";
    elseif(loginServer == "keepworkRelease") then
        loginMain.site = "http://release.keepwork.com";
    elseif(loginServer == "keepworkDev") then
        loginMain.site = "http://dev.keepwork.com";
    elseif(loginServer == "local") then
        loginMain.site = "http://localhost:8099";
    end

    local node = page:GetNode("register");
    if(node) then
        node:SetAttribute("href",loginMain.site .. "/wiki/join");
    end
    page:Refresh(0.01);
end

function loginMain.OnClickLogin()
    loginMain.ignore_auto_login = true;
    loginMain.showLoginModalImp(function()
        if(page) then
            page:Refresh(0.01);
        end
    end);
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
            local info = loginMain.LoadSigninInfo();
            if(info) then
                info.autoLogin = false;
                loginMain.SaveSigninInfo(info);
            end
        end
    end

    if(loginMain.LoginPage and loginMain.hasExplicitLogin) then
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

            loginMain.SaveSigninInfo(nil);
        end
    end

    if(loginMain.LoginPage and loginMain.hasExplicitLogin) then
        setAutoRemember(loginMain.LoginPage);
    end

    if(loginMain.ModalPage) then
        setAutoRemember(loginMain.ModalPage);
    end
end

function loginMain.autoLoginAction(type)
    if(loginMain.ignore_auto_login) then
        return
    end
    local function autoLoginAction(page)
        if(not loginMain.IsSignedIn()) then
            local autoLogin = page:GetValue("autoLogin");

            if(autoLogin) then
                if(type == "main") then
                    loginMain.LoginActionMain();
                elseif(type == "modal") then
                    loginMain.LoginActionModal();
                end
            end
        end
    end

    if(loginMain.LoginPage and loginMain.hasExplicitLogin) then
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
        loginMain.token = nil;
        loginMain.RefreshCurrentServerList();
    end
end

function loginMain.RefreshCurrentServerList(callback)
    if(loginMain.LoginPage) then
        loginMain.refreshing = true;
        loginMain.LoginPage:Refresh(0.01);

        -- user
        if(loginMain.current_type == 1 and not loginMain.IsSignedIn()) then
            loginMain.getLocalWorldList(function()
                loginMain.changeRevision(function()
                    loginMain.refreshing = false;
                    if(type(callback) == "function") then
                        callback();
                    end
                end);
            end);
        elseif(loginMain.current_type == 1 and loginMain.IsSignedIn()) then
            loginMain.getLocalWorldList(function()
                loginMain.changeRevision(function()
                    loginMain.syncWorldsList(function()
                        loginMain.refreshing = false;
                        if(type(callback) == "function") then
                            callback();
                        end
                    end);
                end);
            end);
        end

        --offical
        if(loginMain.current_type == 2) then
            local ServerPage = InternetLoadWorld.GetCurrentServerPage();

            if(not ServerPage.isFetching) then
                InternetLoadWorld.FetchServerPage(ServerPage);
            end

            loginMain.refreshing = false;
        end

        loginMain.LoginPage:Refresh(0.01);
    end

    if(loginMain.ModalPage) then
        loginMain.getLocalWorldList(function()
            loginMain.changeRevision(function()
                loginMain.syncWorldsList(function()
                    loginMain.refreshing = false;
                    if(type(callback) == "function") then
                        callback();
                    end
                end);
            end);
        end);
    end
end

function loginMain.getLocalWorldList(callback)
    local ServerPage = InternetLoadWorld.GetCurrentServerPage();
    
    RemoteServerList:new():Init("local", "localworld", function(bSucceed, serverlist)
        if(not serverlist:IsValid()) then
            BroadcastHelper.PushLabel({id="userworlddownload", label = L"无法下载服务器列表, 请检查网络连接", max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
        end

        ServerPage.ds = serverlist.worlds or {};
        InternetLoadWorld.OnChangeServerPage();

        if(callback) then
            callback();
        end
    end);
end

function loginMain.changeRevision(callback)
    local localWorlds = InternetLoadWorld.GetCurrentServerPage().ds;

    if(localWorlds) then
        for key, value in ipairs(localWorlds) do
            if(not value.is_zip) then
                value.modifyTime = value.revision;

                local foldername = {};
                foldername.utf8    = value.foldername;
                foldername.default = Encoding.Utf8ToDefault(value.foldername);

                local WorldRevisionCheckOut = WorldRevision:new():init(SyncMain.GetWorldFolderFullPath() .. "/" .. foldername.default .. "/");
                value.revision = WorldRevisionCheckOut:GetDiskRevision();

                local tag = LocalService:GetTag(foldername.default);

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
                zipFoldername.default = zipWorldDir.default:match("([^/\\]+)/[^/]*$");
                zipFoldername.utf8    = Encoding.Utf8ToDefault(zipFoldername.default);

                --LOG.std(nil,"debug","zipWorldDir.default",zipWorldDir.default);

                value.revision = LocalService:GetZipRevision(zipWorldDir.default);
                value.size = LocalService:GetZipWorldSize(zipWorldDir.default);
            end
        end

        if(loginMain.LoginPage) then
            loginMain.LoginPage:Refresh();
        end

        if(callback) then
            callback();
        end

        return;
    else
        loginMain.changeRevision();
    end
end

function loginMain.syncWorldsList(_callback)
    local localWorlds = InternetLoadWorld.cur_ds;

    if(not localWorlds) then
        localWorlds = {};
    end

    --[[
        status代码含义:
        1:仅本地
        2:仅网络
        3:本地网络一致
        4:网络更新
        5:本地更新
    ]]

    loginMain.getWorldsList(function(response, err)
        SyncMain.remoteWorldsList = response.data;
        -- 处理本地网络同时存在 本地不存在 网络存在 的世界 
        if(type(SyncMain.remoteWorldsList) ~= "table") then
            _guihelper.MessageBox(L"获取服务器世界列表错误");
            return;
        end

        for keyDistance,valueDistance in ipairs(SyncMain.remoteWorldsList) do
            local isExist = false;

            for keyLocal,valueLocal in ipairs(localWorlds) do
                if(valueDistance["worldsName"] == valueLocal["foldername"]) then

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

        if(localWorlds) then
            local tmp = 0;
  
            for i=1,#localWorlds-1 do
                for j=1,#localWorlds-i do
                    if loginMain:formatDate(localWorlds[j].modifyTime) < loginMain:formatDate(localWorlds[j+1].modifyTime) then
                        tmp = localWorlds[j];
                        localWorlds[j] = localWorlds[j+1];
                        localWorlds[j+1] = tmp;
                    end
                end
            end
        end

        if(loginMain.LoginPage) then
            loginMain.LoginPage:Refresh(0.01);
        end

        if(_callback) then
            _callback();
        end
    end);
end

function loginMain:formatDate(modDate)
    local function strRepeat(num,str)
        local strRepeat = "";

        for i=1,num do
            strRepeat = strRepeat .. str;
        end

        return strRepeat;
    end

    local modDateTable = {};

    for modDateEle in string.gmatch(modDate,"[^%-]+") do
        modDateTable[#modDateTable+1] = modDateEle;
    end

    local newModDate = "";

    if(modDateTable[1] and #modDateTable[1] ~= 4) then
        local num = 4 - #modDateTable[1];
        newModDate = newModDate .. strRepeat(num,'0') .. modDateTable[1];
    elseif(modDateTable[1] and #modDateTable[1] == 4) then
        newModDate = newModDate .. modDateTable[1];
    end

    if(modDateTable[2] and #modDateTable[2] ~= 2) then
        local num = 2 - #modDateTable[2];
        newModDate = newModDate .. strRepeat(num,'0') .. modDateTable[2];
    elseif(modDateTable[2] and #modDateTable[2] == 2) then
        newModDate = newModDate .. modDateTable[2];
    end

    if(modDateTable[3] and #modDateTable[3] ~= 2) then
        local num = 2 - #modDateTable[3];
        newModDate = newModDate .. strRepeat(num,'0') .. modDateTable[3];
    elseif(modDateTable[3] and #modDateTable[3] == 2) then
        newModDate = newModDate .. modDateTable[3];
    end

    if(modDateTable[4] and #modDateTable[4] ~= 2) then
        local num = 2 - #modDateTable[4];
        newModDate = newModDate .. strRepeat(num,'0') .. modDateTable[4];
    elseif(modDateTable[4] and #modDateTable[4] == 2) then
        newModDate = newModDate .. modDateTable[4];
    end

    if(modDateTable[5] and #modDateTable[5] ~= 2) then
        local num = 2 - #modDateTable[5];
        newModDate = newModDate .. strRepeat(num,'0') .. modDateTable[5];
    elseif(modDateTable[5] and modDateTable[5] and #modDateTable[5] == 2) then
        newModDate = newModDate .. modDateTable[5];
    end

    return tonumber(newModDate);
end

function loginMain.enterWorld(index)
    local index = tonumber(index);
    SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[index];

    if(SyncMain.selectedWorldInfor.status == 2) then
        loginMain.downloadWorld();
    else
        InternetLoadWorld.EnterWorld(index);
    end
end

function loginMain.downloadWorld()
    SyncMain.foldername.utf8 = SyncMain.selectedWorldInfor.foldername;
    SyncMain.foldername.default = Encoding.Utf8ToDefault(SyncMain.foldername.utf8);

    SyncMain.worldDir.utf8    = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.utf8 .. "/";
    SyncMain.worldDir.default = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.default .. "/";

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
            SyncMain.selectedWorldInfor.text        = SyncMain.foldername.utf8;
            SyncMain.selectedWorldInfor.world_mode  = "edit";
            SyncMain.selectedWorldInfor.gs_nid      = "";
            SyncMain.selectedWorldInfor.force_nid   = 0;
            SyncMain.selectedWorldInfor.ws_id       = "";
            SyncMain.selectedWorldInfor.author      = "";
            SyncMain.selectedWorldInfor.remotefile  = "local://"..SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.default;

            loginMain.LoginPage:Refresh();
        end
    end);
end

function loginMain.syncNow(index)
    if(loginMain.isVerified ~= "noLogin" and not loginMain.isVerified) then
        _guihelper.MessageBox(L"您需要到keepwork官网进行实名认证，认证成功后需重启paracraft即可正常操作，是否现在认证？", function(res)
            if(res and res == _guihelper.DialogResult.Yes) then
                ParaGlobal.ShellExecute("open", "http://keepwork.com/wiki/user_center", "", "", 1);
            end
        end, _guihelper.MessageBoxButtons.YesNo);

        return;
    end

    local index = tonumber(index);

    SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[index];

    if(loginMain.login_type == 3) then
        if(SyncMain.selectedWorldInfor.status ~= nil and SyncMain.selectedWorldInfor.status ~= 2)then
            if(SyncMain.selectedWorldInfor.is_zip)then
                _guihelper.MessageBox(L"不能同步ZIP文件");
                return;
            end

            SyncMain.foldername.utf8    = SyncMain.selectedWorldInfor.foldername;
            SyncMain.foldername.default = Encoding.Utf8ToDefault(SyncMain.foldername.utf8);

            SyncMain.worldDir.utf8    = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.utf8 .. "/";
            SyncMain.worldDir.default = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.default .. "/";

            SyncMain.syncCompare(true);
        else
            loginMain.downloadWorld();
        end
    else
        _guihelper.MessageBox(L"登陆后才能同步");
    end
end

function loginMain.deleteWorld(index)
    local index = tonumber(index);

    SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[index];

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

function loginRequest(url, params, headers, callback)
    local timeout = false;

    commonlib.TimerManager.SetTimeout(function()
        if(not timeout) then
            timeout = true;
            _guihelper.MessageBox(L"链接超时");
            loginMain.closeMessageInfo();
        end
    end, 4000);

    HttpRequest:GetUrl({
        url     = url,
        json    = true,
        form    = params,
        headers = headers,
    },function(data, err)
        if(not timeout) then
            if(err == 503) then
                _guihelper.MessageBox(L"keepwork正在维护中，我们马上回来");
                loginMain.closeMessageInfo();

                timeout = true;
            elseif(err == 200) then
                if(type(callback) == "function") then
                    callback(data, err);
                end

                timeout = true;
            end
        end
    end, 503);
end

function loginMain.LoginActionApi(account, password, callback)
    local url = loginMain.site .. "/api/wiki/models/user/login";
    
    local params = {
        username = account,
        password = password,
    };

    local headers = {};

    loginRequest(url, params, headers, callback);
end

function loginMain.LoginWithTokenApi(callback)
    local cmdline = ParaEngine.GetAppCommandLine();
    local urlProtocol = string.match(cmdline or "", "paracraft://(.*)$");
    urlProtocol = string.gsub(urlProtocol or "", '%%22', '\"')

    local usertoken = urlProtocol:match("usertoken=\"([%S]+)\"");

    if(type(usertoken) == "string" and #usertoken > 0) then
        loginMain.showMessageInfo(L"正在登陆，请稍后...");

        local url = loginMain.site .. "/api/wiki/models/user/getProfile";

        local params  = {};
        local headers = {
            Authorization = "Bearer " .. usertoken,
        };

        loginRequest(url, params, headers, function(response)
            if(response and response.data) then
                local params = {
                    data = {
                        token    = usertoken,
                        userinfo = response.data,
                    }
                };

                loginResponse(nil, params, err, callback);
            end
        end);

        return true;
    else
        return false;
    end
end

function loginMain.getUserInfo(callback)
    System.os.GetUrl({url = loginMain.site.."/api/wiki/models/user/", json = true, headers = {Authorization = "Bearer " .. loginMain.token}}, callback);
end

function loginMain.changeLoginType(_type)
    loginMain.login_type = _type;

    if(loginMain.LoginPage) then
        loginMain.LoginPage:Refresh();
    end
end

function loginMain.getWorldsList(callback)
    if(not loginMain.token) then
        return
    end
    local params = {
        url     = loginMain.site .. "/api/mod/worldshare/models/worlds",
        json    = true,
        headers = {Authorization = "Bearer " .. loginMain.token},
        form    = {amount = 100},
    };

    HttpRequest:GetUrl(params, callback);
end
