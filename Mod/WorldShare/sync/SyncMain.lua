--[[
Title: SyncMain
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua");
local SyncMain  = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
NPL.load("(gl)Mod/WorldShare/service/GithubService.lua");
NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua");
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua");
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua");
NPL.load("(gl)Mod/WorldShare/sync/SyncGUI.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
NPL.load("(gl)Mod/WorldShare/main.lua");
NPL.load("(gl)Mod/WorldShare/helper/KeepworkGen.lua");
NPL.load("(gl)Mod/WorldShare/sync/ShareWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");

local LocalLoadWorld     = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld");
local ShareWorld         = commonlib.gettable("Mod.WorldShare.sync.ShareWorld");
local SyncGUI            = commonlib.gettable("Mod.WorldShare.sync.SyncGUI");
local WorldCommon        = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local MainLogin          = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local WorldRevision      = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local loginMain          = commonlib.gettable("Mod.WorldShare.login.loginMain");
local GithubService      = commonlib.gettable("Mod.WorldShare.service.GithubService");
local GitlabService      = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local LocalService       = commonlib.gettable("Mod.WorldShare.service.LocalService");
local HttpRequest        = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local Encoding           = commonlib.gettable("commonlib.Encoding");
local EncodingS          = commonlib.gettable("System.Encoding");
local GitEncoding        = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local CommandManager     = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local InternetLoadWorld  = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local ShareWorldPage     = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
local WorldShare         = commonlib.gettable("Mod.WorldShare");
local KeepworkGen        = commonlib.gettable("Mod.WorldShare.helper.KeepworkGen");

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

SyncMain.SyncPage    = nil;
SyncMain.DeletePage  = nil;
SyncMain.BeyondPage  = nil;
SyncMain.finish      = true;
SyncMain.worldDir    = {};
SyncMain.foldername  = {};

function SyncMain:ctor()
end

function SyncMain:init()
    SyncMain.worldName = nil;

    -- 没有登陆则直接使用离线模式
    if(loginMain.token and loginMain.current_type == 1) then
        SyncMain.syncCompare();
    end
end

function SyncMain.setSyncPage()
    SyncMain.SyncPage = document:GetPageCtrl();
end

function SyncMain.setDeletePage()
    SyncMain.DeletePage = document:GetPageCtrl();
end

function SyncMain.setBeyondPage()
    SyncMain.BeyondPage = document:GetPageCtrl();
end

function SyncMain.closeDeletePage()
    SyncMain.DeletePage:CloseWindow();

--    if(not WorldCommon.GetWorldInfo()) then
--        MainLogin.state.IsLoadMainWorldRequested = nil;
--        MainLogin:next_step();
--    end
end

function SyncMain.closeSyncPage()
    SyncMain.isStart = false;
    SyncMain.SyncPage:CloseWindow();
end

function SyncMain.closeBeyondPage()
    SyncMain.BeyondPage:CloseWindow();
end

function SyncMain:StartSyncPage()
    SyncMain.isStart  = true;
    SyncMain.syncType = "sync";

    System.App.Commands.Call("File.MCMLWindowFrame", {
        url            = "Mod/WorldShare/sync/StartSync.html", 
        name           = "SyncWorldShare",
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory / false will only hide window
        style          = CommonCtrl.WindowFrame.ContainerStyle,
        zorder         = 0,
        allowDrag      = true,
        bShow          = bShow,
        directPosition = true,
        align          = "_ct",
        x              = -500/2,
        y              = -270/2,
        width          = 500,
        height         = 270,
        cancelShowAnimation = true,
    });
end

function SyncMain:compareRevision(LoginStatus, callback)
    SyncMain.compareFinish = false;

    if(loginMain.token) then
        local function go()
            SyncMain.foldername.base32 = GitEncoding.base32(SyncMain.foldername.utf8);

            WorldRevisionCheckOut   = WorldRevision:new():init(SyncMain.worldDir.default);
            SyncMain.currentRevison = WorldRevisionCheckOut:Checkout();

            SyncMain.localFiles = LocalService:new():LoadFiles(SyncMain.worldDir.default);

            --[[if(GitlabService:checkSpecialCharacter(SyncMain.foldername.utf8))then
                return;
            end]]

            local hasRevision = false;
            for key,value in ipairs(SyncMain.localFiles) do
                if(string.lower(value.filename) == "revision.xml") then
                    hasRevision = true;
                    break;
                end
            end

            if(hasRevision and SyncMain.currentRevison ~= 0 and SyncMain.currentRevison ~= 1) then
                local contentUrl;
                if(loginMain.dataSourceType == 'github') then
                    contentUrl = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/master/revision.xml";
                elseif(loginMain.dataSourceType == 'gitlab') then
                    SyncMain.commitId = SyncMain:getGitlabCommitId(SyncMain.foldername.utf8);

                    if(SyncMain.commitId) then
                        contentUrl = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/raw/" .. SyncMain.commitId .. "/revision.xml";
                    else
                        contentUrl = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/raw/master/revision.xml";
                    end
                end

                SyncMain.remoteRevison = 0;

                HttpRequest:GetUrl(contentUrl, function(data,err)

                    SyncMain.remoteRevison = tonumber(data);
                    if(not SyncMain.remoteRevison) then
                        SyncMain.remoteRevison = 0;
                    end

                    SyncMain.currentRevison = tonumber(SyncMain.currentRevison);

                    if(err == 0) then
                        _guihelper.MessageBox(L"网络错误");

                        if(type(callback) == "function") then
                            callback(false);
                        end

                        return
                    else
                        local result;

                        if(SyncMain.currentRevison < SyncMain.remoteRevison) then
                            result = "remoteBigger"
                        elseif(SyncMain.remoteRevison == 0) then
                            result = "justLocal";
                        elseif(SyncMain.currentRevison > SyncMain.remoteRevison) then
                            result = "localBigger";
                        elseif(SyncMain.currentRevison == SyncMain.remoteRevison) then
                            result = "equal";
                        end

                        if(SyncMain.remoteRevison ~= 0) then
                            local isWorldInRemoteLists = false;

                            for keyDistance, valueDistance in ipairs(SyncMain.remoteWorldsList) do
                                if(valueDistance["worldsName"] == SyncMain.foldername.utf8) then
                                    isWorldInRemoteLists = true;
                                end
                            end

                            if(not isWorldInRemoteLists) then
                                SyncMain:refreshRemoteWorldLists(nil, function()
                                    SyncMain.compareFinish = true;

                                    if(type(callback) == "function") then
                                        callback("tryAgain");
                                    end
                                end)

                                return;
                            end
                        end

                        SyncMain.compareFinish = true;

                        if(type(callback) == "function") then
                            callback(result);
                        end
                    end
                end);
            else
                if(not LoginStatus) then
                    CommandManager:RunCommand("/save");
                    
                    SyncMain.compareFinish = true;

                    if(type(callback) == "function") then
                        callback("tryAgain");
                    end
                else
                    _guihelper.MessageBox(L"本地世界沒有版本信息");
                    SyncMain.compareFinish = true;
                    return;
                end
            end
        end

        if(not LoginStatus) then
            SyncMain.tagInfor = WorldCommon.GetWorldInfo();

            SyncMain.worldDir.default = GameLogic.GetWorldDirectory():gsub("\\","/");
            SyncMain.worldDir.utf8    = Encoding.DefaultToUtf8(SyncMain.worldDir.default);

            SyncMain.foldername.default = SyncMain.worldDir.default:match("worlds/DesignHouse/([^/]*)/");
            SyncMain.foldername.utf8    = SyncMain.worldDir.utf8:match("worlds/DesignHouse/([^/]*)/");

            loginMain.RefreshCurrentServerList(function()
                if(GameLogic.IsReadOnly()) then
                    if(type(callback) == "function")then
                        callback("zip");
                    end
                
                    return;
                end
            
                if(InternetLoadWorld.cur_ds) then
                    for _, value in ipairs(InternetLoadWorld.cur_ds) do
                        if(value.foldername == SyncMain.foldername.utf8)then
                            SyncMain.selectedWorldInfor = value;
                        end
                    end
                end

                go();
            end);
        else
            go();
        end
    end
end

function SyncMain.syncCompare(LoginStatus)
    SyncMain:compareRevision(LoginStatus, function(result)
        if(LoginStatus) then
            if(result == "justLocal") then
                SyncMain.syncToDataSource();
            else
                SyncMain:StartSyncPage();
            end
        else
            if(result == "remoteBigger") then
                SyncMain:StartSyncPage();
            elseif(result == "tryAgain") then
                commonlib.TimerManager.SetTimeout(function()
                    SyncMain.syncCompare();
                end,1000)
            end
        end
    end);
end

function SyncMain.useLocal()
    SyncMain.SyncPage:CloseWindow();

    if(tonumber(SyncMain.currentRevison) < tonumber(SyncMain.remoteRevison)) then
        SyncMain:useLocalGUI();
    elseif(tonumber(SyncMain.currentRevison) >= tonumber(SyncMain.remoteRevison)) then
        SyncMain:syncToDataSource();
    end
end

function SyncMain:backupWorld()
    local world_revision = WorldRevision:new():init(SyncMain.worldDir.default);
    world_revision:Backup();
end

function SyncMain.useRemote()
    SyncMain.SyncPage:CloseWindow();

    if(tonumber(SyncMain.remoteRevison) < tonumber(SyncMain.currentRevison)) then
        SyncMain:useDataSourceGUI();
    elseif(tonumber(SyncMain.remoteRevison) >= tonumber(SyncMain.currentRevison)) then
        SyncMain:syncToLocal();
    end
end

function SyncMain.useOffline()
    SyncMain.ComparePage:CloseWindow();
end

function SyncMain:useLocalGUI()
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url  = "Mod/WorldShare/sync/StartSyncUseLocal.html", 
        name = "SyncWorldShare", 
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

function SyncMain:useDataSourceGUI()
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url  = "Mod/WorldShare/sync/StartSyncUseDataSource.html", 
        name = "SyncWorldShare",
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

function SyncMain:syncToLocal(callback)
    if(not SyncMain.finish) then
        --_guihelper.MessageBox(L"同步尚未结束");
        --return;
    end

    SyncMain.localSync = {};
    SyncMain.finish = false;

    -- 加载进度UI界面
    local syncToLocalGUI = SyncGUI:new();

    if(loginMain.dataSourceType == "gitlab") then
        SyncMain:setGitlabProjectId(SyncMain.foldername.utf8);
    end

    if (SyncMain.worldDir.default == "") then
        _guihelper.MessageBox(L"下载失败，原因：下载目录为空");
        return;
    else
        SyncMain.curUpdateIndex        = 1;
        SyncMain.curDownloadIndex      = 1;
        SyncMain.totalLocalIndex       = nil;
        SyncMain.totalDataSourceIndex  = nil;
        SyncMain.dataSourceFiles       = {};

        local syncGUItotal = 0;
        local syncGUIIndex = 0;
        local syncGUIFiles = "";

        SyncMain.finish = false;

        syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, L'获取文件sha列表');

        function SyncMain.localSync.finish()
            syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, L"同步完成");
            local localWorlds = InternetLoadWorld.cur_ds;

            for key, value in ipairs(localWorlds) do
                if(SyncMain.foldername.utf8 == value["foldername"]) then
                    --LOG.std(nil,"debug","SyncMain.foldername",SyncMain.foldername.utf8);
                    localWorlds[key].status   = 3;
                    localWorlds[key].revision = SyncMain.remoteRevison;
                    loginMain.refreshPage();
                end
            end

            --成功是返回信息给login
            if(type(callback) == "function") then
                local params = {};
                params.revison = SyncMain.remoteRevison;

                callback(true,params);
            end

            SyncMain.finish = true;
        end

        -- 下载新文件
        function SyncMain.localSync.downloadOne()
            LOG.std("SyncMain","debug","NumbersToLCDL","totals : %s , current : %s", SyncMain.totalDataSourceIndex, SyncMain.curDownloadIndex);

            if(SyncMain.finish) then
                LOG.std("SyncMain","debug", "强制中断");
                return;
            end

            if (SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].needChange) then
                if(SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].type == "blob") then
                    -- LOG.std(nil,"debug","githubFiles.tree[SyncMain.curDownloadIndex].type",githubFiles.tree[SyncMain.curDownloadIndex].type);

                    SyncMain.isFetching = true;
                    LocalService:download(SyncMain.foldername.utf8, SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].path, function (bIsDownload, response)
                        if (bIsDownload) then
                            syncGUIIndex = syncGUIIndex + 1;
                            syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, response.filename);

                            if(response.filename == "revision.xml") then
                                SyncMain.remoteRevison = response.content;
                            end

                            if(SyncMain.curDownloadIndex == SyncMain.totalDataSourceIndex) then
                                SyncMain.localSync.finish();
                            else
                                SyncMain.curDownloadIndex = SyncMain.curDownloadIndex + 1;
                                SyncMain.localSync.downloadOne();
                            end
                        else
                            _guihelper.MessageBox(L'下载失败，请稍后再试');
                            --syncToLocalGUI.finish();
                            --SyncMain.finish = true;
                        end

                        SyncMain.isFetching = false;
                    end);
                end
            else
                if(SyncMain.curDownloadIndex == SyncMain.totalDataSourceIndex) then
                    SyncMain.localSync.finish();
                else
                    SyncMain.curDownloadIndex = SyncMain.curDownloadIndex + 1;
                    SyncMain.localSync.downloadOne();
                end
            end
        end

        -- 删除文件
        function SyncMain.localSync.deleteOne()
            if(SyncMain.finish) then
                LOG.std("SyncMain","debug", "强制中断");
                return;
            end

            LocalService:delete(SyncMain.foldername.utf8, SyncMain.localFiles[SyncMain.curUpdateIndex].filename, function (data, err)
                if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
                    SyncMain.localSync.downloadOne();
                else
                    SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
                    SyncMain.localSync.updateOne();
                end
            end);
        end

        -- 更新本地文件
        function SyncMain.localSync.updateOne()
            LOG.std("SyncMain","debug","NumbersToLCUD","totals : %s , current : %s", SyncMain.totalLocalIndex, SyncMain.curUpdateIndex);

            if(SyncMain.finish) then
                LOG.std("SyncMain","debug", "强制中断");
                return;
            end

            local bIsExisted      = false;
            local dataSourceIndex = nil;

            -- 用数据源的文件和本地的文件对比
            for key, value in ipairs(SyncMain.dataSourceFiles) do
                if(value.path == SyncMain.localFiles[SyncMain.curUpdateIndex].filename) then
                    --LOG.std(nil,"debug","value.path",value.path);
                    bIsExisted = true;
                    dataSourceIndex = key; 
                    break;
                end
            end

            -- 本地是否存在数据源上的文件
            if (bIsExisted) then
                SyncMain.dataSourceFiles[dataSourceIndex].needChange = false;
                LOG.std("SyncMain", "debug", "FilesShaToLCUP", "File : %s, DSSha : %s , LCSha : %s", SyncMain.dataSourceFiles[dataSourceIndex].path, SyncMain.dataSourceFiles[dataSourceIndex].sha, SyncMain.localFiles[SyncMain.curUpdateIndex].sha1);

                if (SyncMain.localFiles[SyncMain.curUpdateIndex].sha1 ~= SyncMain.dataSourceFiles[dataSourceIndex].sha) then
                    -- 更新已存在的文件

                    SyncMain.isFetching = true;
                    LocalService:update(SyncMain.foldername.utf8, SyncMain.dataSourceFiles[dataSourceIndex].path, function (bIsUpdate, response)
                        if (bIsUpdate) then
                            if(response.filename == "revision.xml") then
                                SyncMain.remoteRevison = response.content;
                            end

                            syncGUIIndex = syncGUIIndex + 1;
                            syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, response.filename);

                            if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
                                SyncMain.localSync.downloadOne();
                            else
                                SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
                                SyncMain.localSync.updateOne();
                            end
                        else
                            _guihelper.MessageBox(L'更新失败,请稍后再试');
                            --syncToLocalGUI.finish();
                            --SyncMain.finish = true;
                        end

                        SyncMain.isFetching = false;
                    end);
                else
                    syncGUIIndex = syncGUIIndex + 1;
                    syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.dataSourceFiles[dataSourceIndex].path);

                    if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
                        SyncMain.localSync.downloadOne();
                    else
                        SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
                        SyncMain.localSync.updateOne();
                    end
                end
            else
                -- 如果数据源不存在，则删除本地的文件
                SyncMain.localSync.deleteOne();
            end
        end

        -- 获取数据源仓文件
        SyncMain:getFileShaListService(SyncMain.foldername.utf8, function(data, err)
            if(err ~= 404) then
                if(err == 409) then
                    _guihelper.MessageBox(L"数据源上暂无数据");
                    syncToLocalGUI.finish();
                    return;
                end

                SyncMain.localFiles      = LocalService:new():LoadFiles(SyncMain.worldDir.default);
                SyncMain.dataSourceFiles = data;

                SyncMain.totalLocalIndex      = #SyncMain.localFiles;
                SyncMain.totalDataSourceIndex = #SyncMain.dataSourceFiles;

                for key,value in ipairs(SyncMain.dataSourceFiles) do
                    value.needChange = true;

                    if(value.type == "blob") then
                        syncGUItotal = syncGUItotal + 1;
                    end
                end

                syncToLocalGUI:updateDataBar(syncGUIIndex , syncGUItotal, L"开始同步");

                if (SyncMain.totalLocalIndex ~= 0) then
                    SyncMain.localSync.updateOne();
                else
                    --downloadOne(); 
                    --如果文档文件夹为空，则直接开始下载
                    LocalService:downloadZip(SyncMain.foldername.utf8, SyncMain.commitId ,function(bSuccess, remoteRevison)
                        if(bSuccess) then
                            SyncMain.remoteRevison = remoteRevison;
                            syncGUIIndex = syncGUItotal;
                            SyncMain.localSync.finish();
                            loginMain.RefreshCurrentServerList();
                        else
                            _guihelper.MessageBox(L'下载失败，请稍后再试');
                        end
                    end);
                end
            else
                _guihelper.MessageBox(L"获取数据源文件失败，请稍后再试！");
                syncToLocalGUI.finish();
            end
        end, SyncMain.commitId);
    end
end

function SyncMain:syncToDataSource()
    if(SyncMain:checkWorldSize()) then
        return;
    end

    SyncMain.remoteSync = {};

    -- 加载进度UI界面
    local syncToDataSourceGUI = SyncGUI:new();
    SyncMain.finish = false;
    syncToDataSourceGUI:refresh();

    local function syncToDataSourceGo()
        if (SyncMain.worldDir.default == "") then
            _guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空");
            return;
        else
            SyncMain.curUpdateIndex        = 1;
            SyncMain.curUploadIndex        = 1;
            SyncMain.totalLocalIndex       = nil;
            SyncMain.totalDataSourceIndex  = nil;
            SyncMain.dataSourceFiles       = {};

            SyncMain.revisionUpload = false;
            SyncMain.revisionUpdate = false;

            local syncGUItotal = 0;
            local syncGUIIndex = 0;
            local syncGUIFiles = "";

            syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L'获取文件sha列表');

            function SyncMain.remoteSync.revision(callback)
                if(SyncMain.revisionUpload) then
                    SyncMain:uploadService(SyncMain.foldername.base32, "revision.xml", SyncMain.revisionContent, function (bIsUpload, filename)
                        if (bIsUpload) then
                            syncGUIIndex = syncGUIIndex + 1;
                            syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L'同步完成，正在更新世界信息，请稍后...');

                            if(type(callback) == "function") then
                                callback();
                            end
                        else
                            _guihelper.MessageBox(L"revision上传失败");
                            syncGUIIndex = syncGUIIndex + 1;
                            syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);
                        end
                    end);
                end

                if(SyncMain.revisionUpdate) then
                    SyncMain:updateService(SyncMain.foldername.base32, "revision.xml", SyncMain.revisionContent, SyncMain.revisionSha1, function (bIsUpdate, filename)
                        if (bIsUpdate) then
                            syncGUIIndex = syncGUIIndex + 1;
                            syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L'同步完成，正在更新世界信息，请稍后...');

                            if(type(callback) == "function") then
                                callback();
                            end
                        else
                            _guihelper.MessageBox(L"revision更新失败");
                            syncGUIIndex = syncGUIIndex + 1;
                            syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);
                        end
                    end);
                end
            end

            function SyncMain.remoteSync.finish()
                SyncMain.remoteSync.revision(function()
                    if(syncGUIIndex > syncGUItotal) then
                        _guihelper.MessageBox(L"更新失败，请重试再试");
                        syncToDataSourceGUI.closeWindow();
                        return;
                    end

                    SyncMain:refreshRemoteWorldLists(syncToDataSourceGUI);
                end)
            end

            -- 上传新文件
            function SyncMain.remoteSync.uploadOne()
                LOG.std("SyncMain", "debug", "NumbersToDSUD", "totals : %s , current : %s, file : %s", SyncMain.totalLocalIndex, SyncMain.curUploadIndex, SyncMain.localFiles[SyncMain.curUploadIndex].filename);

                if(SyncMain.finish) then
                    LOG.std("SyncMain","debug", "强制中断");
                    return;
                end

                if(string.lower(SyncMain.localFiles[SyncMain.curUploadIndex].filename) == "revision.xml" and SyncMain.localFiles[SyncMain.curUploadIndex].needChange) then
                    SyncMain.revisionUpload  = true;
                    SyncMain.revisionContent = SyncMain.localFiles[SyncMain.curUploadIndex].file_content_t;

                    if (SyncMain.curUploadIndex == SyncMain.totalLocalIndex) then
                        SyncMain.remoteSync.finish();
                    else
                        SyncMain.curUploadIndex = SyncMain.curUploadIndex + 1;
                        SyncMain.remoteSync.uploadOne(); --继续递归上传
                    end

                    return;
                end

                if (SyncMain.localFiles[SyncMain.curUploadIndex].needChange) then
                    SyncMain.localFiles[SyncMain.curUploadIndex].needChange = false;
                    SyncMain.isFetching = true;

                    LOG.std("SyncMain", "debug", "FilesShaToDSUD", "File : %s, 上传中", SyncMain.localFiles[SyncMain.curUploadIndex].filename);
                    syncGUIIndex = syncGUIIndex + 1;
                    syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, format(L"%s （%s） 上传中", SyncMain.localFiles[SyncMain.curUploadIndex].filename, loginMain.GetWorldSize(SyncMain.localFiles[SyncMain.curUploadIndex].filesize, "KB")));

                    SyncMain:uploadService(SyncMain.foldername.base32, SyncMain.localFiles[SyncMain.curUploadIndex].filename, SyncMain.localFiles[SyncMain.curUploadIndex].file_content_t,function (bIsUpload, filename)
                        SyncMain.isFetching = false;

                        if (bIsUpload) then
                            LOG.std("SyncMain", "debug", "FilesShaToDSUD", "File : %s, 上传完成", SyncMain.localFiles[SyncMain.curUploadIndex].filename);
                            syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, format(L"%s（%s）上传完成", filename,  loginMain.GetWorldSize(SyncMain.localFiles[SyncMain.curUploadIndex].filesize, "KB")));

                            if (SyncMain.curUploadIndex == SyncMain.totalLocalIndex) then
                                SyncMain.remoteSync.finish();
                            else
                                SyncMain.curUploadIndex = SyncMain.curUploadIndex + 1;
                                SyncMain.remoteSync.uploadOne(); --继续递归上传
                            end
                        else
                            _guihelper.MessageBox(format("%s上传失败" ,SyncMain.localFiles[SyncMain.curUploadIndex].filename));
                            LOG.std("SyncMain", "debug", "FilesShaToDSUD", "File : %s, 上传失败", SyncMain.localFiles[SyncMain.curUploadIndex].filename);

                            syncGUIIndex = syncGUIIndex + 1;
                            syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, format(L"%s上传失败", SyncMain.localFiles[SyncMain.curUploadIndex].filename));

                            --syncToDataSourceGUI.finish();
                            --SyncMain.finish = true;
                        end
                    end);
                else
                    LOG.std("SyncMain", "debug", "FilesShaToDSUD", "File : %s, 已更新，跳过", SyncMain.localFiles[SyncMain.curUploadIndex].filename);

                    if (SyncMain.curUploadIndex == SyncMain.totalLocalIndex) then
                        SyncMain.remoteSync.finish();
                    else
                        SyncMain.curUploadIndex = SyncMain.curUploadIndex + 1;
                        SyncMain.remoteSync.uploadOne(); --继续递归上传
                    end
                end
            end

            -- 删除数据源文件
            function SyncMain.remoteSync.deleteOne()
                if(SyncMain.finish) then
                    LOG.std("SyncMain","debug", "强制中断");
                    return;
                end

                if(SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].type == "blob") then
                    SyncMain.isFetching = true;

                    SyncMain:deleteFileService(SyncMain.foldername.base32, SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].path, SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].sha, function (bIsDelete)
                        if (bIsDelete) then
                            SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;

                            if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
                                SyncMain.remoteSync.uploadOne();
                            else
                                SyncMain.remoteSync.updateOne();
                            end
                        else
                            _guihelper.MessageBox(L"删除失败");
                            --syncToDataSourceGUI.finish();
                            --SyncMain.finish = true;
                        end

                        SyncMain.isFetching = false;
                    end);
                else
                    if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
                        SyncMain.remoteSync.uploadOne();
                    else
                        SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
                        SyncMain.remoteSync.updateOne();
                    end
                end
            end

            -- 更新数据源文件
            function SyncMain.remoteSync.updateOne()
                LOG.std("SyncMain", "debug", "NumbersToDSUP", "totals : %s , current : %s", SyncMain.totalDataSourceIndex, SyncMain.curUpdateIndex);

                if(SyncMain.finish) then
                    LOG.std("SyncMain","debug", "强制中断");
                    return;
                end

                local bIsExisted  = false;
                local LocalIndex  = nil;
                local curGitFiles = SyncMain.dataSourceFiles[SyncMain.curUpdateIndex];

                -- 用数据源的文件和本地的文件对比
                for key,value in ipairs(SyncMain.localFiles) do
                    if(value.filename == curGitFiles.path) then
                        bIsExisted  = true;
                        LocalIndex  = key; 
                        break;
                    end
                end

                if(bIsExisted and string.lower(SyncMain.localFiles[LocalIndex].filename) == "revision.xml") then
                    SyncMain.revisionUpdate  = true;
                    SyncMain.revisionContent = SyncMain.localFiles[LocalIndex].file_content_t;
                    SyncMain.revisionSha1    = SyncMain.localFiles[LocalIndex].sha1;

                    SyncMain.localFiles[LocalIndex].needChange = false;

                    if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
                        SyncMain.remoteSync.uploadOne();
                    else
                        SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1; -- 如果不等最大计数则更新
                        SyncMain.remoteSync.updateOne();
                    end

                    return;
                end

                if (bIsExisted) then
                    syncGUIIndex = syncGUIIndex + 1;
                    syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, format(L"%s比对中", SyncMain.localFiles[LocalIndex].filename));

                    SyncMain.localFiles[LocalIndex].needChange = false;
                    SyncMain.isFetching = true;

                    LOG.std("SyncMain", "debug", "FilesShaToDSUP", "File : %s, DSSha : %s , LCSha : %s", curGitFiles.path, curGitFiles.sha, SyncMain.localFiles[LocalIndex].sha1);

                    if (curGitFiles.sha ~= SyncMain.localFiles[LocalIndex].sha1) then
                        syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, format(L"%s更新中", SyncMain.localFiles[LocalIndex].filename));

                        -- 更新已存在的文件
                        SyncMain:updateService(SyncMain.foldername.base32, SyncMain.localFiles[LocalIndex].filename, SyncMain.localFiles[LocalIndex].file_content_t, curGitFiles.sha, function (bIsUpdate, filename)
                            if (bIsUpdate) then
                                syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, format(L"%s更新完成", filename));

                                if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
                                    SyncMain.remoteSync.uploadOne();
                                else
                                    SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1; -- 如果不等最大计数则更新
                                    SyncMain.remoteSync.updateOne();
                                end
                            else
                                _guihelper.MessageBox(L"更新失败");
                                syncGUIIndex = syncGUIIndex + 1;
                                syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);
                            end

                            SyncMain.isFetching = false;
                        end);
                    else
                        syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, format(L"%s版本一致，跳过", SyncMain.localFiles[LocalIndex].filename));

                        if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
                            SyncMain.remoteSync.uploadOne();
                        else
                            SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
                            SyncMain.remoteSync.updateOne();
                        end
                    end
                else
                    -- 如果本地不删除存在，则删除数据源的文件
                    SyncMain.remoteSync.deleteOne();
                end
            end

            -- 获取数据源仓文件
            SyncMain:getFileShaListService(SyncMain.foldername.base32, function(data, err)
                SyncMain.localFiles = LocalService:new():LoadFiles(SyncMain.worldDir.default); --再次获取本地文件，保证上传的内容为最新

                local hasReadme = false;

                for key,value in ipairs(SyncMain.localFiles) do
                    if(string.upper(value.filename) == "README.MD") then
                        if(value.filename == "README.md") then
                            hasReadme = true;
                        else
                            LocalService:delete(SyncMain.foldername.utf8, value.filename);
                            hasReadme = false;
                        end
                    end
                end

                if(not hasReadme) then
                    local filePath = SyncMain.worldDir.default .. "README.md";
                    local file = ParaIO.open(filePath, "w");
                    local content = KeepworkGen.readmeDefault;

                    file:write(content,#content);
                    file:close();

                    local readMeFiles = {
                        filename       = "README.md",
                        file_path      = filePath,
                        file_content_t = content,
                    };

                    local otherFile = commonlib.copy(SyncMain.localFiles[#SyncMain.localFiles]);
                    SyncMain.localFiles[#SyncMain.localFiles] = readMeFiles;
                    SyncMain.localFiles[#SyncMain.localFiles + 1] = otherFile;
                end

                SyncMain.totalLocalIndex = #SyncMain.localFiles;
                syncGUItotal = #SyncMain.localFiles;

                for i=1,#SyncMain.localFiles do
                    SyncMain.localFiles[i].needChange = true;
                    i = i + 1;
                end

                if (err ~= 409 and err ~= 404) then --409代表已经创建过此仓
                    SyncMain.dataSourceFiles = data;
                    SyncMain.totalDataSourceIndex = #SyncMain.dataSourceFiles;

                    if(SyncMain.totalDataSourceIndex ~= 0)then
                        SyncMain.remoteSync.updateOne();
                    end
                else
                    SyncMain.remoteSync.uploadOne();
                end
            end);
        end
    end

    ------------------------------------------------------------------------

    if(SyncMain.remoteRevison == 0) then
        --"首次同步"
        SyncMain:create(SyncMain.foldername.base32,function(data, status)
            if(data == true) then
                syncToDataSourceGo();
            else
                _guihelper.MessageBox(L"数据源创建失败");
                syncToDataSourceGUI.finish();
                return;
            end
        end);
    else
        --"非首次同步"
        if(loginMain.dataSourceType == "gitlab") then
            SyncMain:setGitlabProjectId(SyncMain.foldername.utf8);
            syncToDataSourceGo();
        end
    end
end

function SyncMain:refreshRemoteWorldLists(syncGUI, callback)
    SyncMain:getCommits(SyncMain.foldername.base32, function(data, err)
        if(data and data[1]) then
            local lastCommits    = data[1];
            local lastCommitFile = lastCommits.title:gsub("keepwork commit: ","");
            local lastCommitSha  = lastCommits.id;

            if(lastCommitFile ~= "revision.xml") then
                _guihelper.MessageBox(L"上一次同步到数据源同步失败，请重新同步世界到数据源");
                return;
            end

            local modDateTable = {};
            local readme	   = "";

            if(SyncMain.selectedWorldInfor and SyncMain.selectedWorldInfor.tooltip)then
                for modDateEle in string.gmatch(SyncMain.selectedWorldInfor.tooltip,"[^:]+") do
                    modDateTable[#modDateTable+1] = modDateEle;
                end

                modDateTable = modDateTable[1];
            else
                modDateTable = os.date("%Y-%m-%d-%H-%M-%S");
            end

            local hasPreview = false;

            for key,value in ipairs(SyncMain.localFiles) do
                if(value.filename == "preview.jpg") then
                    hasPreview = true;
                end
            end

            for key,value in ipairs(SyncMain.localFiles) do
                if(value.filename == "README.md") then
                    readme = LocalService:getFileContent(SyncMain.worldDir.default .. "README.md");
                end
            end

            local preview         = {};
            preview[0]            = {};
            preview[0].previewUrl = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/raw/master/preview.jpg";
            preview               = NPL.ToJson(preview,true);

            local filesTotals = 0;
            if(SyncMain.selectedWorldInfor) then
                filesTotals = SyncMain.selectedWorldInfor.size;
            end

            local worldTag = LocalService:GetTag(SyncMain.foldername.default);

            local params = {};
            params.modDate		   = modDateTable;
            params.worldsName      = SyncMain.foldername.utf8;
            params.revision        = SyncMain.currentRevison;
            params.hasPreview      = hasPreview;
            params.dataSourceType  = loginMain.dataSourceType;
            params.gitlabProjectId = GitlabService.projectId;
            params.readme          = readme;
            params.preview         = preview;
            params.filesTotals	   = filesTotals;
            params.commitId		   = lastCommitSha;
            params.name            = worldTag.name;

            loginMain.refreshing = true;

            if(loginMain.LoginPage) then
                loginMain.LoginPage:Refresh(0.01);
            end

            HttpRequest:GetUrl({
                url     = loginMain.site .. "/api/mod/worldshare/models/worlds/refresh",
                json    = true,
                form    = params,
                headers = {
                    Authorization    = "Bearer " .. loginMain.token,
                    ["content-type"] = "application/json",
                },
            },function(response, err)
                if(err == 200) then
                    if(type(response) == "table" and response.error.id == 0) then
                        params.opusId = response.data.opusId;
                    else
                        _guihelper.MessageBox(L"更新服务器列表失败");
                        return;
                    end

                    SyncMain:genWorldMD(params, function()
                        SyncMain.finish = true;

                        if(syncGUI) then
                            syncGUI:refresh();
                        end

                        loginMain.RefreshCurrentServerList(function()
                            if(type(callback) == "function") then
                                callback();
                            end
                        end);
                    end);
                end
            end);

            if(SyncMain.firstCreate) then
                SyncMain.firstCreate = false;
            end
        else
            _guihelper.MessageBox(L"获取Commit列表失败");
        end

        GitlabService.projectId = nil;
    end);
end

function SyncMain:showBeyondVolume()
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url            = "Mod/WorldShare/sync/BeyondVolume.html", 
        name           = "BeyondVolume", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory / false will only hide window
        style          = CommonCtrl.WindowFrame.ContainerStyle,
        zorder         = 0,
        allowDrag      = true,
        bShow          = bShow,
        directPosition = true,
        align          = "_ct",
        x              = -500/2,
        y              = -270/2,
        width          = 500,
        height         = 270,
        cancelShowAnimation = true,
    });
end

function SyncMain.getBeyondMsg()
    local str = format(L"世界%s文件总大小超过了%dMB，是否清理文件？(请使用MP3、OGG格式音频，避免使用FBX格式，VIP用户最大可上传%dMB)", SyncMain.foldername.utf8, 25, 50);

    return str;
end

function SyncMain.openWorldFolder()
    SyncMain.closeBeyondPage();
    local path = ParaIO.GetCurDirectory(0) .. LocalLoadWorld.GetWorldFolder() .. "/" .. SyncMain.foldername.default;
    ParaGlobal.ShellExecute("open", path, "", "", 1);
end

function SyncMain:checkWorldSize()
    local maxSize    = 25 * 1024 * 1024;
    local filesTotal =  LocalService:GetWorldSize(SyncMain.worldDir.default);

    if(filesTotal > maxSize) then
        SyncMain:showBeyondVolume();

        return true;
    else
        return false;
    end
end

function SyncMain:setGitlabProjectId(foldername)
    for key,value in ipairs(SyncMain.remoteWorldsList) do
        if(value.worldsName == foldername) then
            GitlabService.projectId = value.gitlabProjectId;

            return;
        end
    end

    GitlabService.projectId = nil;
end

function SyncMain:getGitlabCommitId(foldername)
    if(not SyncMain.remoteWorldsList) then
        SyncMain.remoteWorldsList = {};
    end

    for key,value in ipairs(SyncMain.remoteWorldsList) do
        if(value.worldsName == foldername) then
            return value.commitId;
        end
    end
end

function SyncMain:genIndexMD(callback)
    local contentUrl = "projects/" .. loginMain.keepWorkDataSourceId .. "/repository/files/" .. loginMain.username .. "/paracraft/index.md?ref=master";

    self:getUrl(contentUrl , function(data, err)
        if(err == 404) then
            local indexPath = loginMain.username .. "/paracraft/index.md";

            local worldList = KeepworkGen:setCommand("worldList", {userid = loginMain.userId});
            SyncMain.indexFile = KeepworkGen:SetAutoGenContent("", worldList);

            SyncMain:uploadService(
                loginMain.keepWorkDataSource,
                indexPath,
                SyncMain.indexFile,
                function(data, err) 
                    if(type(callback) == "function") then
                        callback();
                    end
                end,
                loginMain.keepWorkDataSourceId
            );
        end
    end);
end

function SyncMain:genThemeMD(callback)
    local contentUrl = "projects/" .. loginMain.keepWorkDataSourceId .. "/repository/files/" .. loginMain.username .. "/paracraft/_theme.md?ref=master";

    self:getUrl(contentUrl , function(data, err)
        if(err == 404) then
            local themePath = loginMain.username .. "/paracraft/_theme.md";

            SyncMain:uploadService(
                loginMain.keepWorkDataSource,
                themePath,
                KeepworkGen.paracraftContainer,
                function(data, err) 
                    if(type(callback) == "function") then
                        callback();
                    end
                end,
                loginMain.keepWorkDataSourceId
            );
        end
    end);
end

function SyncMain:genWorldMD(worldInfor, callback)
    local contentUrl = "projects/" .. loginMain.keepWorkDataSourceId .. "/repository/files/" .. loginMain.username .. "/paracraft/world_" .. worldInfor.worldsName .. ".md?ref=master";
    local worldUrl   = "";

    if(loginMain.dataSourceType == "gitlab") then
        worldUrl = "http://git.keepwork.com/" .. loginMain.dataSourceUsername .. "/" .. GitEncoding.base32(SyncMain.foldername.utf8) .. "/repository/archive.zip?ref=" .. worldInfor.commitId;
    end

    local worldFilePath = loginMain.username .. "/paracraft/world_" .. worldInfor.worldsName .. ".md";
    local worldTag      = LocalService:GetTag(SyncMain.foldername.default);

    self:getUrl(contentUrl , function(data, err)
        if(err == 404) then
            local world3D = {
                worldName     = worldTag.name,
                worldUrl      = worldUrl,
                logoUrl       = worldInfor.preview,
                desc          = "",
                username      = loginMain.username,
                visitCount    = 1,
                favoriteCount = 1,
                updateDate    = worldInfor.modDate,
                version       = worldInfor.revision,
                opusId        = worldInfor.opusId,
                filesTotals   = worldInfor.filesTotals,
            }
                
            world3D = KeepworkGen:setCommand("world3D",world3D);

            if(not worldInfor.readme) then
                worldInfor.readme = "";
            end

            SyncMain.worldFile = KeepworkGen:SetAutoGenContent(worldInfor.readme, world3D)
            SyncMain.worldFile = SyncMain.worldFile .. "\r\n" .. KeepworkGen:setCommand("comment");

            SyncMain:uploadService(
                loginMain.keepWorkDataSource,
                worldFilePath,
                SyncMain.worldFile,
                function(data, err)
                    if(type(callback) == "function") then
                        callback();
                    end
                end,
                loginMain.keepWorkDataSourceId
            );
        elseif(err == 200 or err == 304) then
            data = Encoding.unbase64(data.content);

            local world3D = {
                worldName     = worldTag.name,
                worldUrl      = worldUrl,
                logoUrl       = worldInfor.preview,
                desc          = "",
                username      = loginMain.username,
                visitCount    = 1,
                favoriteCount = 1,
                updateDate    = worldInfor.modDate,
                version       = worldInfor.revision,
                filesTotals   = worldInfor.filesTotals,
                opusId        = worldInfor.opusId,
            }

            world3D = KeepworkGen:setCommand("world3D",world3D);
            SyncMain.worldFile = KeepworkGen:SetAutoGenContent(data, world3D);

            SyncMain:updateService(
                loginMain.keepWorkDataSource,
                worldFilePath,
                SyncMain.worldFile,
                "",
                function(isSuccess, path)
                    if(type(callback) == "function") then
                        callback();
                    end
                end,
                loginMain.keepWorkDataSourceId
            );
        end
    end)
end

function SyncMain:deleteWorldMD(_path, callback)
    local function deleteFile(keepworkId)
        local path = loginMain.username ..  "/paracraft/world_" .. _path .. ".md";

        --LOG.std(nil,"debug","path",path);
        SyncMain:deleteFileService(loginMain.keepWorkDataSource, path, "", function(data, err)
            if(type(callback) == "function") then
                callback();
            end
        end, keepworkId)
    end

    if(loginMain.dataSourceType == "github") then
        deleteFile();
    elseif(loginMain.dataSourceType == "gitlab") then
        GitlabService:getProjectIdByName(loginMain.keepWorkDataSource,function(keepworkId)
            deleteFile(keepworkId);
        end);
    end
end

function SyncMain.deleteWorld()
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url  = "Mod/WorldShare/sync/DeleteWorld.html",
        name = "DeleteWorld", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory / false will only hide window
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 0,
        isTopLevel = true,
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

function SyncMain.deleteServerWorld()
    local zipPath = SyncMain.selectedWorldInfor.localpath;

    if(ParaIO.DeleteFile(zipPath)) then
        loginMain.RefreshCurrentServerList();
    else
        _guihelper.MessageBox(L"无法删除可能您没有足够的权限"); 
    end

    SyncMain.DeletePage:CloseWindow();
end

function SyncMain.deleteWorldLocal(callback)
    --local world      = InternetLoadWorld:GetCurrentWorld();
    local foldername = SyncMain.selectedWorldInfor.foldername;

    --LOG.std(nil,"debug","world",world);
    --LOG.std(nil,"debug","SyncMain.selectedWorldInfor",SyncMain.selectedWorldInfor);

    if(not SyncMain.selectedWorldInfor) then
        _guihelper.MessageBox(L"请先选择世界");
        return;
    end

    local function deleteNow()
        if(SyncMain.selectedWorldInfor.RemoveLocalFile and SyncMain.selectedWorldInfor:RemoveLocalFile()) then
            InternetLoadWorld.RefreshAll();
        elseif(SyncMain.selectedWorldInfor.remotefile) then
            local targetDir = SyncMain.selectedWorldInfor.remotefile:gsub("^local://", ""); -- local world, delete all files in folder and the folder itself.

            --LOG.std(nil,"debug","SyncMain.deleteWorldLocal",targetDir);
            
            if(SyncMain.selectedWorldInfor.is_zip) then

                if(ParaIO.DeleteFile(targetDir)) then
                    if(type(callback) == "function") then
                        callback();
                    end
                else
                    _guihelper.MessageBox(L"无法删除可能您没有足够的权限"); 
                end
            else
                if(GameLogic.RemoveWorldFileWatcher) then
                    GameLogic.RemoveWorldFileWatcher(); -- file watcher may make folder deletion of current world directory not working.
                end

                if(commonlib.Files.DeleteFolder(targetDir)) then  
                    if(type(callback) == 'function') then
                        callback(foldername);
                    end
                else
                    _guihelper.MessageBox(L"无法删除可能您没有足够的权限"); 
                end
            end

            SyncMain.DeletePage:CloseWindow();
            loginMain.RefreshCurrentServerList();
        end
    end

    if(SyncMain.selectedWorldInfor.status == nil or SyncMain.selectedWorldInfor.status == 1) then
        deleteNow();
    else
        _guihelper.MessageBox(format(L"确定删除本地世界:%s?", SyncMain.selectedWorldInfor.text or ""), function(res)
            if(res and res == _guihelper.DialogResult.Yes) then
                deleteNow();
            end
        end, _guihelper.MessageBoxButtons.YesNo);
    end

    
end

function SyncMain.deleteWorldRemote()
    if(loginMain.dataSourceType == "github") then
        SyncMain.deleteWorldGithubLogin();
    elseif(loginMain.dataSourceType == "gitlab") then
        SyncMain.deleteWorldGitlab();
    end
end

function SyncMain.deleteWorldGithubLogin()
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url  = "Mod/WorldShare/sync/DeleteWorldGithub.html", 
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

function SyncMain.deleteWorldGithub(_password)
    local foldername = SyncMain.selectedWorldInfor.foldername;
    foldername = Encoding.Utf8ToDefault(foldername);

    local AuthUrl    = "https://api.github.com/authorizations";
    local AuthParams = {
        scopes = {
            "delete_repo",
        },
        note   = ParaGlobal.timeGetTime(),
    };
    local basicAuth  = loginMain.dataSourceUsername .. ":" .. _password;
    local AuthToken  = "";

    basicAuth = Encoding.base64(basicAuth);

    HttpRequest:GetUrl({
        url     = AuthUrl,
        json    = true,
        headers = {
            Authorization    = "Basic " .. basicAuth,
            ["User-Agent"]   = "npl",
            ["content-type"] = "application/json"
        },
        form    = AuthParams
    },function(data,err)
        local basicAuthData = data;
        AuthToken = basicAuthData.token;

        _guihelper.MessageBox(format(L"确定删除Gihub远程世界:%s?", foldername or ""), function(res)
            SyncMain.DeletePage:CloseWindow();

            if(res and res == 6) then
                GithubService:deleteResp(foldername, AuthToken, function(data,err)
                    --LOG.std(nil,"debug","GithubService:deleteResp",err);
                    if(err == 204) then
                        SyncMain.deleteKeepworkWorldsRecord();
                    else
                        _guihelper.MessageBox(L"远程仓库不存在，记录将直接被删除");
                        SyncMain.deleteKeepworkWorldsRecord();
                    end
                end)
            end
        end);
    end)
end

function SyncMain.deleteWorldGitlab()
    local foldername = SyncMain.selectedWorldInfor.foldername;

    SyncMain:setGitlabProjectId(foldername);

    _guihelper.MessageBox(format(L"确定删除Gitlab远程世界:%s?", foldername or ""), function(res)
        SyncMain.DeletePage:CloseWindow();

        loginMain.refreshing = true;
        loginMain.LoginPage:Refresh(0.01);

        if(res and res == 6) then
            GitlabService:deleteResp(foldername, function(data, err)
                if(err == 202) then
                    SyncMain.deleteKeepworkWorldsRecord();
                else
                    _guihelper.MessageBox(L"远程仓库不存在，记录将直接被删除");
                    SyncMain.deleteKeepworkWorldsRecord();
                end
            end);
        end
    end);
end

function SyncMain.deleteKeepworkWorldsRecord()
    local foldername = SyncMain.selectedWorldInfor.foldername;
    local url = loginMain.site .. "/api/mod/worldshare/models/worlds";

    LOG.std(nil,"debug","deleteKeepworkWorldsRecord",url);

    HttpRequest:GetUrl({
        method  = "DELETE",
        url     = url,
        form    = {
            worldsName = foldername,
        },
        json    = true,
        headers = {
            Authorization = "Bearer " .. loginMain.token,
        },
    },function(data, err)
        LOG.std(nil,"debug","deleteKeepworkWorldsRecord",data)
        LOG.std(nil,"debug","deleteKeepworkWorldsRecord",err)

        if(err == 204 or err == 200) then
            SyncMain:deleteWorldMD(foldername,function()
                loginMain.RefreshCurrentServerList();
            end)
        end
    end);
end

function SyncMain.deleteWorldAll()
    SyncMain.deleteWorldLocal(function()
        SyncMain.deleteWorldRemote();
    end);
end


function SyncMain:create(foldername, callback)
    if(loginMain.dataSourceType == "github") then
        GithubService:create(foldername, callback);
    elseif(loginMain.dataSourceType == "gitlab") then
        GitlabService:init(foldername, callback);
    end
end

function SyncMain:getDataSourceContent(foldername, path, callback, projectId)
    if(loginMain.dataSourceType == "github") then
        GithubService:getContent(foldername, path, callback);
    elseif(loginMain.dataSourceType == "gitlab") then
        GitlabService:getContent(path, callback, projectId);
    end
end

function SyncMain:uploadService(foldername, filename, file_content_t, callback, projectId)
    if(loginMain.dataSourceType == "github") then
        GithubService:upload(foldername, filename, file_content_t, callback);
    elseif(loginMain.dataSourceType == "gitlab") then
        GitlabService:writeFile(filename, file_content_t, callback, projectId, foldername);
    end
end

function SyncMain:updateService(foldername, filename, file_content_t, sha, callback, projectId)
    if(loginMain.dataSourceType == "github") then
        GithubService:update(foldername, filename, file_content_t, sha, callback);
    elseif(loginMain.dataSourceType == "gitlab") then
        GitlabService:update(filename, file_content_t, sha, callback, projectId, foldername);
    end
end

function SyncMain:deleteFileService(foldername, path, sha, callback, projectId)
    if(loginMain.dataSourceType == "github") then
        GithubService:deleteFile(foldername, path, sha, callback);
    elseif(loginMain.dataSourceType == "gitlab") then
        GitlabService:deleteFile(path, sha, callback, projectId, foldername);
    end
end

function SyncMain:getFileShaListService(foldername, callback, commitId, projectId)
    if(loginMain.dataSourceType == "github") then
        GithubService:getFileShaList(foldername, callback);
    elseif(loginMain.dataSourceType == "gitlab") then
        GitlabService:getTree(callback, commitId, projectId, foldername);
    end
end

function SyncMain:getCommits(foldername, callback, projectId)
    if(loginMain.dataSourceType == "github") then
        GithubService:getCommits(foldername, callback);
    elseif(loginMain.dataSourceType == "gitlab") then
        GitlabService:listCommits(callback, projectId, foldername);
    end
end

function SyncMain:getUrl(url, callback)
    if(loginMain.dataSourceType == "github") then
        
    elseif(loginMain.dataSourceType == "gitlab") then
        GitlabService:apiGet(url, callback);
    end
end