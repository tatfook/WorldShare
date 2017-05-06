--[[
Title: SyncMain
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/SyncMain.lua");
local SyncMain  = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
NPL.load("(gl)Mod/WorldShare/login.lua");
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

local SyncGUI            = commonlib.gettable("Mod.WorldShare.sync.SyncGUI");
local WorldCommon        = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local MainLogin		     = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local WorldRevision      = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local login              = commonlib.gettable("Mod.WorldShare.login");
local GithubService      = commonlib.gettable("Mod.WorldShare.service.GithubService");
local GitlabService      = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local LocalService       = commonlib.gettable("Mod.WorldShare.service.LocalService");
local HttpRequest		 = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local Encoding           = commonlib.gettable("commonlib.Encoding");
local EncodingS          = commonlib.gettable("System.Encoding");
local GitEncoding        = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local CommandManager     = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local InternetLoadWorld  = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local ShareWorldPage     = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
local WorldShare         = commonlib.gettable("Mod.WorldShare");
local KeepworkGen        = commonlib.gettable("Mod.WorldShare.helper.KeepworkGen");

local SyncMain = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local Page;
SyncMain.finish = true;

function SyncMain:ctor()
end

function SyncMain:init()
	LOG.std(nil, "debug", "SyncMain", "init");
	
	SyncMain.worldName = nil;

	-- 没有登陆则直接使用离线模式
	if(login.token) then
		SyncMain:compareRevision();
		SyncMain:StartSyncPage();
	end
end

function SyncMain.setPage()
	Page = document:GetPageCtrl();
end

function SyncMain.goBack()
    Page:CloseWindow();

    if(not WorldCommon.GetWorldInfo()) then
        MainLogin.state.IsLoadMainWorldRequested = nil;
        MainLogin:next_step();
    end
end

function SyncMain.closePage()
	SyncGUI.isStart = false;
	Page:CloseWindow();
end

function SyncMain:StartSyncPage()
	SyncGUI.isStart = true;

	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/sync/StartSync.html", 
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

function SyncMain:compareRevision(_worldDir)
	if(login.token) then
		if(WorldCommon:GetWorldInfo())then
			SyncMain.selectedWorldInfor = WorldCommon:GetWorldInfo();
		end
		LOG.std(nil,"debug","worldinfo",SyncMain.selectedWorldInfor);

		if(_worldDir) then
			SyncMain.worldDir = _worldDir;
		else
			SyncMain.worldDir = GameLogic.GetWorldDirectory();
		end

		LOG.std(nil,"debug","self.worldDir",SyncMain.worldDir);

		WorldRevisionCheckOut   = WorldRevision:new():init(SyncMain.worldDir);
		SyncMain.currentRevison = WorldRevisionCheckOut:Checkout();

		SyncMain.foldername = SyncMain.worldDir:match("worlds/DesignHouse/([^/]*)/");
		SyncMain.foldername = Encoding.DefaultToUtf8(SyncMain.foldername);
		SyncMain.localFiles = LocalService:LoadFiles(SyncMain.worldDir,"",nil,1000,nil);

		--LOG.std(nil,"debug","self.foldername",self.foldername);
		--LOG.std(nil,"debug","self.localFiles",self.localFiles);

		local hasRevision = false;
		for key,value in ipairs(SyncMain.localFiles) do
			--LOG.std(nil,"debug","filename",value.filename);
			if(value.filename == "revision.xml") then
				hasRevision = true;
				break;
			end
		end

		if(hasRevision) then
			local contentUrl;
			if(login.dataSourceType == 'github') then
				contentUrl = login.rawBaseUrl .. "/" .. login.dataSourceUsername .. "/" .. GitEncoding.base64(SyncMain.foldername) .. "/master/revision.xml";
			elseif(login.dataSourceType == 'gitlab') then
				local commitId = SyncMain:getGitlabCommitId(SyncMain.foldername);
				contentUrl = login.rawBaseUrl .. "/" .. login.dataSourceUsername .. "/" .. GitEncoding.base64(SyncMain.foldername) .. "/raw/" .. commitId .. "/revision.xml";
				LOG.std("SyncMain","debug","contentUrl",contentUrl);
			end

			SyncMain.remoteRevison = 0;

			--LOG.std(nil,"debug","contentUrl",contentUrl);

			HttpRequest:GetUrl(contentUrl, function(data,err)
				--LOG.std(nil,"debug","contentUrl",contentUrl);
				--LOG.std(nil,"debug","data",data);
				LOG.std(nil,"debug","err",err);

				if(err == 0) then
					Page:CloseWindow();
					_guihelper.MessageBox(L"网络错误");
					return
				end

				if(err == 404 or err == 401) then
					Page:CloseWindow();
					SyncMain.firstCreate = true;
					--_guihelper.MessageBox(L"数据源暂无数据，请先分享世界");

					ShareWorldPage.ShowPage();
					return
				end
				
				if(type(tonumber(data)) == "number") then
					SyncMain.remoteRevison = tonumber(data);
				else
					Page:CloseWindow();
					SyncMain.firstCreate = true;
					--_guihelper.MessageBox(L"数据源暂无数据，请先分享世界");

					ShareWorldPage.ShowPage();
					return
				end

				-- LOG.std(nil,"debug","self.githubRevison",self.githubRevison);

				if(tonumber(SyncMain.currentRevison) ~= tonumber(SyncMain.remoteRevison)) then
					Page:Refresh();
				else
					_guihelper.MessageBox(L"数据源已存在此作品，且版本相等");
					Page:CloseWindow();
				end
			end);
		else
			commonlib.TimerManager.SetTimeout(function() 
				Page:CloseWindow();

				CommandManager:RunCommand("/save");
				SyncMain:compareRevision();
				SyncMain:StartSyncPage();
			end, 500)
		end
	end
end

function SyncMain.shareNow()
    Page:CloseWindow();

	ShareWorldPage.TakeSharePageImage();
    if(not SyncMain.firstCreate and tonumber(SyncMain.currentRevison) < tonumber(SyncMain.remoteRevison)) then
        _guihelper.MessageBox("当前本地版本小于远程版本，是否继续上传？", function(res)
            if(res and res == 6) then
                SyncMain:syncToDataSource();
            end
        end);
    elseif(tonumber(SyncMain.currentRevison) > tonumber(SyncMain.remoteRevison)) then
        SyncMain:syncToDataSource();
    end
end

function SyncMain.useLocal()
    Page:CloseWindow();

    if(tonumber(SyncMain.currentRevison) < tonumber(SyncMain.remoteRevison)) then
        SyncMain:useLocalGUI();
    elseif(tonumber(SyncMain.currentRevison) > tonumber(SyncMain.remoteRevison)) then
        -- _guihelper.MessageBox("开始同步--将本地大小有变化的文件上传到github"); -- 上传或更新
        SyncMain:syncToDataSource();
    end
end

function SyncMain.useRemote()
    Page:CloseWindow();

    if(tonumber(SyncMain.remoteRevison) < tonumber(SyncMain.currentRevison)) then
        SyncMain:useDataSourceGUI();
    elseif(tonumber(SyncMain.remoteRevison) > tonumber(SyncMain.currentRevison)) then
        -- _guihelper.MessageBox("开始同步--将github大小有变化的文件下载到本地");-- 下载或覆盖
        SyncMain:syncToLocal();
    end
end

function SyncMain.useOffline()
    Page:CloseWindow();
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

function SyncMain:syncToLocal(_worldDir, _foldername, _callback)
	if(not SyncMain.finish) then
		_guihelper.MessageBox(L"同步尚未结束");
		return;
	end

	SyncMain.finish = false;

	--LOG.std(nil,"debug","worldDir",_worldDir);

	-- 加载进度UI界面
	local syncToLocalGUI = SyncGUI:new();

	if(_worldDir) then
		SyncMain.worldDir   = _worldDir;
		SyncMain.foldername = _foldername;
	end

	if(login.dataSourceType == "gitlab") then
		SyncMain:setGitlabProjectId(SyncMain.foldername);
	end

	if (SyncMain.worldDir == "") then
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

		-- LOG.std(nil,"debug","SyncMainGUI",SyncMain.curDownloadIndex);
		-- LOG.std(nil,"debug","SyncMainGUI",SyncMain.totalDataSourceIndex);

		syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, L'获取文件sha列表');

		local function finish()
			SyncMain.finish = true;

			syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, "同步完成");
			local localWorlds = InternetLoadWorld.cur_ds;

			for key, value in ipairs(localWorlds) do
				if(SyncMain.foldername == value["foldername"]) then
					LOG.std(nil,"debug","SyncMain.foldername",SyncMain.foldername);
					localWorlds[key].status   = 3;
					localWorlds[key].revision = SyncMain.remoteRevison;
					login.refreshPage();
				end
			end

			--成功是返回信息给login
			if(_callback) then
				local params = {};
				params.revison     = SyncMain.remoteRevison;
				params.filesTotals = LocalService:GetWorldFileSize(SyncMain.foldername);

				_callback(true,params);
			end
		end

		-- 下载新文件
		local function downloadOne()
			-- LOG.std(nil,"debug","githubFiles.tree[SyncMain.curDownloadIndex]",githubFiles.tree[SyncMain.curDownloadIndex]);
			-- LOG.std(nil,"debug","SyncMain.curDownloadIndex",SyncMain.curDownloadIndex);

			if (SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].needChange) then
				if(SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].type == "blob") then
					-- LOG.std(nil,"debug","githubFiles.tree[SyncMain.curDownloadIndex].type",githubFiles.tree[SyncMain.curDownloadIndex].type);
					LocalService:download(SyncMain.foldername, SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].path, function (bIsDownload, response)
						if (bIsDownload) then
							syncGUIIndex = syncGUIIndex + 1;
							syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, response.filename);

							if(response.filename == "revision.xml") then
								SyncMain.remoteRevison = response.content;
							end

							if(SyncMain.curDownloadIndex == SyncMain.totalDataSourceIndex) then
								finish();
							else
								SyncMain.curDownloadIndex = SyncMain.curDownloadIndex + 1;
								downloadOne();
							end
						else
							_guihelper.MessageBox(L'下载失败，请稍后再试');
							--syncToLocalGUI.finish();
							--SyncMain.finish = true;
						end
					end);
				end
			else
				syncGUIIndex = syncGUIIndex + 1;
				syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.dataSourceFiles[SyncMain.curDownloadIndex].path);

				if(SyncMain.curDownloadIndex == SyncMain.totalDataSourceIndex) then
					finish();
				else
					SyncMain.curDownloadIndex = SyncMain.curDownloadIndex + 1;
					downloadOne();
				end
			end
		end

		-- 更新本地文件
		local function updateOne()
			LOG.std(nil,"debug","SyncMain.curUpdateIndex ",SyncMain.curUpdateIndex);
			local bIsExisted      = false;
			local dataSourceIndex = nil;

			-- 用数据源的文件和本地的文件对比
			for key, value in ipairs(SyncMain.dataSourceFiles) do
				if(value.path == SyncMain.localFiles[SyncMain.curUpdateIndex].filename) then
					LOG.std(nil,"debug","value.path",value.path);
					bIsExisted = true;
					dataSourceIndex = key; 
					break;
				end
			end

			-- 本地是否存在数据源上的文件
			if (bIsExisted) then
				SyncMain.dataSourceFiles[dataSourceIndex].needChange = false;
				-- LOG.std(nil,"debug","self.localFiles[SyncMain.curUpdateIndex ].filename",self.localFiles[SyncMain.curUpdateIndex ].filename);
				-- LOG.std(nil,"debug","self.localFiles[SyncMain.curUpdateIndex ].sha1",self.localFiles[SyncMain.curUpdateIndex ].sha1);
				-- LOG.std(nil,"debug","githubFiles.tree[dataSourceIndex].sha",githubFiles.tree[dataSourceIndex].sha);

				if (SyncMain.localFiles[SyncMain.curUpdateIndex].sha1 ~= SyncMain.dataSourceFiles[dataSourceIndex].sha) then
					-- 更新已存在的文件
					LocalService:update(SyncMain.foldername, SyncMain.dataSourceFiles[dataSourceIndex].path, function (bIsUpdate, response)
						if (bIsUpdate) then
							if(response.filename == "revision.xml") then
								SyncMain.remoteRevison = response.content;
							end

							syncGUIIndex = syncGUIInde + 1;
							syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, response.filename);

							-- 如果当前计数大于最大计数则更新
							if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then      -- check whether all files have updated or not. if false, update the next one, if true, upload files.  
								downloadOne();
							else
								SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
								updateOne();
							end
						else
							_guihelper.MessageBox(L'更新失败,请稍后再试');
							--syncToLocalGUI.finish();
							--SyncMain.finish = true;
						end
					end);
				else
					syncGUIIndex = syncGUIIndex + 1;
					syncToLocalGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.dataSourceFiles[dataSourceIndex].path);

					if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
						downloadOne();
					else
						SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
						updateOne();
					end
				end
			else
				LOG.std(nil,"debug","delete-filename",SyncMain.localFiles[SyncMain.curUpdateIndex].filename);
				LOG.std(nil,"debug","delete-sha1",SyncMain.localFiles[SyncMain.curUpdateIndex].sha1);

				-- 如果过github不删除存在，则删除本地的文件
				deleteOne();
			end
		end

		-- 删除文件
		local function deleteOne()
			LocalService:delete(SyncMain.foldername, SyncMain.localFiles[SyncMain.curUpdateIndex].filename, function (data, err)
				if (SyncMain.curUpdateIndex == SyncMain.totalLocalIndex) then
					downloadOne();
				else
					SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
					updateOne();
				end
			end);
		end

		-- 获取数据源仓文件
		SyncMain:getFileShaListService(SyncMain.foldername, function(data, err)
			if(err ~= 404) then
				if(err == 409) then
					_guihelper.MessageBox(L"数据源上暂无数据");
					syncToLocalGUI.finish();
					return;
				end

				LOG.std(nil,"debug","SyncMain:getFileShaListService-data",data);

				SyncMain.localFiles      = LocalService:LoadFiles(SyncMain.worldDir,"",nil,1000,nil);
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

				LOG.std(nil,"debug","SyncMain.totalLocalIndex",SyncMain.totalLocalIndex);
				LOG.std(nil,"debug","SyncMain.totalDataSourceIndex",SyncMain.totalDataSourceIndex);

				if (SyncMain.totalLocalIndex ~= 0) then
					updateOne();
				else
					downloadOne(); --如果文档文件夹为空，则直接开始下载
				end
			else
				_guihelper.MessageBox(L"获取G数据源文件失败，请稍后再试！");
				syncToLocalGUI.finish();
			end
		end);
	end
end

function SyncMain:syncToDataSource()
	if(not SyncMain.finish) then
		_guihelper.MessageBox(L"同步尚未结束");
		return;
	end

	SyncMain.finish = false;

	-- 加载进度UI界面
	local syncToDataSourceGUI = SyncGUI:new();

	local function syncToDataSourceGo()
		SyncMain.localFiles = LocalService:LoadFiles(SyncMain.worldDir,"",nil,1000,nil);
		
		if (SyncMain.worldDir == "") then
			_guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空");
			return;
		else
			SyncMain.curUpdateIndex        = 1;
			SyncMain.curUploadIndex        = 1;
			SyncMain.totalLocalIndex       = nil;
			SyncMain.totalDataSourceIndex  = nil;
			SyncMain.dataSourceFiles       = {};

			local syncGUItotal = 0;
			local syncGUIIndex = 0;
			local syncGUIFiles = "";

			syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, L'获取文件sha列表');

			LOG.std(nil,"debug","SyncMain.curUploadIndex",SyncMain.curUploadIndex);
			LOG.std(nil,"debug","SyncMain.totalDataSourceIndex",SyncMain.totalDataSourceIndex);

			local function finish()
				LOG.std(nil,"debug","SyncMain.selectedWorldInfor",SyncMain.selectedWorldInfor);
				LOG.std(nil,"debug","send",SyncMain.selectedWorldInfor.tooltip);

				SyncMain:getCommits(function(data, err)
					LOG.std(nil,"debug","data",data);
					LOG.std(nil,"debug","err",err);
    
					if(data) then
						local lastCommits = data[1];
						lastCommitFile = lastCommits.title:gsub("keepwork commit: ","");
						lastCommitSha  = "";
        
						if(lastCommitFile == "revision.xml") then
							lastCommitSha = lastCommits.id;

							SyncMain.finish = true;

							local modDateTable = {};
							local readme;

							if(SyncMain.selectedWorldInfor.tooltip)then
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
									readme = LocalService:getFileContent(SyncMain.worldDir .. "README.md");
									readme = Encoding.DefaultToUtf8(readme);
									LOG.std(nil,"debug","SyncMain.worldDir",SyncMain.worldDir);
									LOG.std(nil,"debug","readme",readme);
								end
							end

							local preview = {};
							preview[0] = {};
							preview[0].previewUrl = login.rawBaseUrl .. "/" .. login.dataSourceUsername .. "/" .. GitEncoding.base64(SyncMain.foldername) .. "/raw/master/preview.jpg";
							preview = NPL.ToJson(preview,true);

							local filesTotals = LocalService:GetWorldFileSize(SyncMain.foldername);

							local params = {};
							params.modDate		   = modDateTable;
							params.worldsName      = SyncMain.foldername;
							params.revision        = SyncMain.currentRevison;
							params.hasPreview      = hasPreview;
							params.dataSourceType  = login.dataSourceType;
							params.gitlabProjectId = GitlabService.projectId;
							params.readme          = readme; --EncodingS.base64(readme);
							params.preview         = preview;
							params.filesTotals	   = filesTotals;
							params.commitId		   = lastCommitSha;

							LOG.std(nil,"debug","params",params);

							-- SyncMain:genWorldMD(params);

							HttpRequest:GetUrl({
								url     = login.site .. "/api/mod/worldshare/models/worlds/refresh",
								json    = true,
								form    = params,
								headers = {
									Authorization    = "Bearer " .. login.token,
									["content-type"] = "application/json",
								},
							},function(data, err)
								LOG.std(nil,"debug","finish",data);
								LOG.std(nil,"debug","finish",err);

								LOG.std(nil,"debug","SyncMain.worldName", SyncMain.worldName);
								if(err == 200) then
									params.opusId = data.msg.opusId;

									SyncMain:genWorldMD(params, function()
										HttpRequest:GetUrl({
											url  = login.site .. "/api/mod/worldshare/models/worlds",
											json = true,
											headers = {Authorization = "Bearer "..login.token},
											form = {amount = 100},
										},function(worldList, err)
											LOG.std(nil,"debug","worldList-data",worldList);
											SyncMain:genIndexMD(worldList);
										end);
									end);

									login.syncWorldsList();
								end
							end);

							if(SyncMain.firstCreate) then
								SyncMain.firstCreate = false;
							end
						else
							_guihelper.MessageBox(L"上传失败");
						end
        
						LOG.std(nil,"debug","lastCommits",lastCommits);
						LOG.std(nil,"debug","lastCommitFile",lastCommitFile);
						LOG.std(nil,"debug","lastCommitSha",lastCommitSha);
					else
						_guihelper.MessageBox(L"上传失败");
					end
				end);
			end

			-- 上传新文件
			local function uploadOne()
				LOG.std(nil,"debug","uploadOne-status",SyncMain.curUploadIndex);
				LOG.std(nil,"debug","uploadOne-status",SyncMain.totalLocalIndex);

				if (SyncMain.localFiles[SyncMain.curUploadIndex].needChange) then
					SyncMain.localFiles[SyncMain.curUploadIndex].needChange = false;
					SyncMain:uploadService(SyncMain.foldername, SyncMain.localFiles[SyncMain.curUploadIndex].filename, SyncMain.localFiles[SyncMain.curUploadIndex].file_content_t,function (bIsUpload, filename)
						if (bIsUpload) then
							syncGUIIndex = syncGUIIndex + 1;
							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);

							if (SyncMain.curUploadIndex == SyncMain.totalLocalIndex) then
								LOG.std(nil,"debug","SyncMain.localFiles",SyncMain.localFiles);
								finish();
							else
								SyncMain.curUploadIndex = SyncMain.curUploadIndex + 1;
								uploadOne(); --继续递归上传
							end
						else
							--_guihelper.MessageBox(L"上传失败");
							--syncGUIIndex = syncGUIIndex + 1;
							--syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);

							--syncToDataSourceGUI.finish();
							--SyncMain.finish = true;
						end
					end);
				else
--					syncGUIIndex = syncGUIIndex + 1;
--					syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.localFiles[SyncMain.curUploadIndex].filename);

					if (SyncMain.curUploadIndex == SyncMain.totalLocalIndex) then
						finish();
					else
						SyncMain.curUploadIndex = SyncMain.curUploadIndex + 1;
						uploadOne(); --继续递归上传
					end
				end
			end

			-- 更新数据源文件
			local function updateOne()
				LOG.std(nil,"debug","updateOne-status",SyncMain.curUpdateIndex);
				LOG.std(nil,"debug","updateOne-status",SyncMain.totalDataSourceIndex);

				local bIsExisted  = false;
				local LocalIndex  = nil;
				local curGitFiles = SyncMain.dataSourceFiles[SyncMain.curUpdateIndex];

				if(curGitFiles.type == "blob") then
					-- 用数据源的文件和本地的文件对比
					for key,value in ipairs(SyncMain.localFiles) do
						if(value.filename == curGitFiles.path) then
							bIsExisted  = true;
							LocalIndex  = key; 
							break;
						end
					end

					LOG.std(nil,"debug","dataSourceFiles",curGitFiles.path);

					if (bIsExisted) then
						SyncMain.localFiles[LocalIndex].needChange = false;
						--LOG.std(nil,"debug","SyncMain.dataSourceFiles.tree[SyncMain.curUpdateIndex].path",SyncMain.dataSourceFiles.tree[SyncMain.curUpdateIndex].path);
						--LOG.std(nil,"debug","SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].sha",SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].sha);
						--LOG.std(nil,"debug","self.localFiles.sha1",self.localFiles[LocalIndex].sha1);

						if (curGitFiles.sha ~= SyncMain.localFiles[LocalIndex].sha1) then
							-- 更新已存在的文件
							SyncMain:updateService(SyncMain.foldername, SyncMain.localFiles[LocalIndex].filename, SyncMain.localFiles[LocalIndex].file_content_t, curGitFiles.sha, function (bIsUpdate, filename)
								if (bIsUpdate) then
									syncGUIIndex = syncGUIIndex + 1;
									syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);

									if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
										for key,value in ipairs(SyncMain.localFiles) do
											LOG.std(nil,"debug","filename",value.filename);
											LOG.std(nil,"debug","needChange",value.needChange);
										end
										
										uploadOne();
									else
										SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1; -- 如果不等最大计数则更新
										updateOne();
									end
								else
									_guihelper.MessageBox(L"更新失败");
									syncGUIIndex = syncGUIIndex + 1;
									syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, filename);
									--syncToDataSourceGUI.finish();
									--SyncMain.finish = true;
								end
							end);
						else
							syncGUIIndex = syncGUIIndex + 1;
							syncToDataSourceGUI:updateDataBar(syncGUIIndex, syncGUItotal, SyncMain.localFiles[LocalIndex].filename);

							if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
								for key,value in ipairs(SyncMain.localFiles) do
									LOG.std(nil,"debug","filename",value.filename);
									LOG.std(nil,"debug","needChange",value.needChange);
								end
								uploadOne();
							else
								SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
								updateOne();
							end
						end
					else
						-- LOG.std(nil,"debug","delete-filename",self.localFiles[LocalIndex].filename);
						-- LOG.std(nil,"debug","delete-sha1",self.localFiles[LocalIndex].filename);

						-- 如果过数据源不删除存在，则删除本地的文件
						deleteOne();
					end
				else
					if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then
						uploadOne();
					else
						SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
						updateOne();
					end
				end
			end

			-- 删除数据源文件
			function deleteOne()
				LOG.std(nil,"debug","deleteOne-status");
				if(SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].type == "blob") then
					SyncMain:deleteFileService(SyncMain.foldername, SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].path, SyncMain.dataSourceFiles[SyncMain.curUpdateIndex].sha, function (bIsDelete)
						if (bIsDelete) then
							SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;

							if (SyncMain.curUpdateIndex > SyncMain.totalDataSourceIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
								uploadOne();
							else
								updateOne();
							end
						else
							_guihelper.MessageBox(L"删除失败");
							--syncToDataSourceGUI.finish();
							--SyncMain.finish = true;
						end
					end);
				else
					if (SyncMain.curUpdateIndex == SyncMain.totalDataSourceIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
						uploadOne();
					else
						SyncMain.curUpdateIndex = SyncMain.curUpdateIndex + 1;
						updateOne();
					end
				end
			end

			-- 获取数据源仓文件
			SyncMain:getFileShaListService(SyncMain.foldername, function(data, err)
				LOG.std(nil,"debug","SyncMain:getFileShaListService-data",data);
				LOG.std(nil,"debug","SyncMain:getFileShaListService-err",err);

				local hasReadme = false;

				for key,value in ipairs(SyncMain.localFiles) do
					if(value.filename == "README.md") then
						hasReadme = true;
						break;
					end
				end

				if(not hasReadme) then
					local filePath = SyncMain.worldDir .. "README.md";
					local file = ParaIO.open(filePath, "w");
					local content = Encoding.Utf8ToDefault(KeepworkGen.readmeDefault);

					file:write(content,#content);
					file:close();

					--LOG.std(nil,"debug","filePath",filePath);

					local readMeFiles = {
						filename       = "README.md",
						file_path      = Encoding.DefaultToUtf8(SyncMain.worldDir) .. "README.md",
						file_content_t = content
					};

					--LOG.std(nil,"debug","localFiles",readMeFiles);

					SyncMain.localFiles[#SyncMain.localFiles + 1] = readMeFiles;
				end

				SyncMain.totalLocalIndex = #SyncMain.localFiles;
				syncGUItotal = #SyncMain.localFiles;

				for i=1,#SyncMain.localFiles do
					-- LOG.std(nil,"debug","localFiles",self.localFiles[i]);
					SyncMain.localFiles[i].needChange = true;
					i = i + 1;
				end

				if (err ~= 409 and err ~= 404) then --409代表已经创建过此仓
					SyncMain.dataSourceFiles = data;
					SyncMain.totalDataSourceIndex = #SyncMain.dataSourceFiles;

					updateOne();
				else
					--if the repos is empty, then upload files 
					uploadOne();
				end
			end);
		end
	end

	------------------------------------------------------------------------

	if(SyncMain.firstCreate) then
		SyncMain:create(SyncMain.foldername,function(data, err)
			--LOG.std(nil,"debug","SyncMain:create",data);
			--LOG.std(nil,"debug","SyncMain:create",err);

			if(data == true or err == 422 or err == 201) then
				syncToDataSourceGo();
			else
				--if(data.name ~= self.foldername) then
				_guihelper.MessageBox(L"数据源创建失败");
				syncToDataSourceGUI.finish();
				return;
				--end
			end
		end);
	else
		LOG.std(nil,"debug","SyncMain:syncToGithub","非首次同步");

		if(login.dataSourceType == "gitlab") then
			SyncMain:setGitlabProjectId(SyncMain.foldername);
		end

		syncToDataSourceGo();
	end
end

function SyncMain:setGitlabProjectId(_foldername)
	for key,value in ipairs(SyncMain.remoteWorldsList) do
		if(value.worldsName == _foldername) then
			GitlabService.projectId = value.gitlabProjectId;
		end
	end
end

function SyncMain:getGitlabCommitId(_foldername)
	for key,value in ipairs(SyncMain.remoteWorldsList) do
		if(value.worldsName == _foldername) then
			return value.commitId;
		end
	end
end

function SyncMain:genIndexMD(_worldList, _callback)
	local function gen(keepworkId)
		SyncMain:getFileShaListService("keepworkDataSource", function(data, err)
			LOG.std(nil,"debug","genIndexMD",data);

			local hasIndex      = false;
			local indexPath     = "";
			SyncMain.indexFile  = "";

			if(login.dataSourceType == "gitlab") then
				username = login.dataSourceUsername:gsub("gitlab_" , "");
			else

			end

			local indexPath = username .. "/paracraft/index";

			for key,value in ipairs(data) do
				if(value.path == indexPath) then
					hasIndex = true;
				end
			end

			local function updateTree(_callback)
				SyncMain:refreshWikiPages(indexPath, SyncMain.indexFile, function(data, err)
					if(_callback) then
						_callback();
					end
				end);
			end

			local function updateIndexFile()
				LOG.std(nil,"debug","hasIndexO",hasIndex);
				if(hasIndex) then
					LOG.std(nil,"debug","hasIndex",hasIndex);
					SyncMain:getDataSourceContent("keepworkDataSource", indexPath, function(data, err)
						--LOG.std(nil,"debug","getDataSourceContent",data);
						--LOG.std(nil,"debug","getDataSourceContent",err);

						--local content = Encoding.unbase64(data);
						--local paramsText = KeepworkGen:GetContent(content);
						--local params = KeepworkGen:getCommand("worldList", paramsText);
						local worldList;

						if(_worldList)then
							LOG.std(nil,"debug","_worldListA")
							worldList = _worldList;
						else
							LOG.std(nil,"debug","_worldListB")
							worldList = SyncMain.remoteWorldsList;
						end

						worldList = KeepworkGen:setCommand("worldList",worldList);
						SyncMain.indexFile = KeepworkGen:SetAutoGenContent("", worldList)

						LOG.std(nil,"debug","SyncMain.indexFile",SyncMain.indexFile);

						SyncMain:updateService(
							"keepworkDataSource",
							indexPath,
							SyncMain.indexFile,
							"",
							function(isSuccess, path)
								LOG.std(nil,"debug","updateService-indexFile",isSuccess)
								LOG.std(nil,"debug","updateService-indexFile",path)
								updateTree(_callback);
							end,
							keepworkId
						);
					end, keepworkId)
				else
					local worldList;

					if(_worldList)then
						LOG.std(nil,"debug","_worldListA")
						worldList = _worldList;
					else
						LOG.std(nil,"debug","_worldListB")
						worldList = SyncMain.remoteWorldsList;
					end

					worldList = KeepworkGen:setCommand("worldList",worldList);
					SyncMain.indexFile = KeepworkGen:SetAutoGenContent("", worldList);

					LOG.std(nil,"debug","SyncMain.indexFile",SyncMain.indexFile);

					SyncMain:uploadService(
						"keepworkDataSource",
						indexPath,
						SyncMain.indexFile,
						function(data, err) 
							updateTree(_callback);
						end,
						keepworkId
					);
				end
			end

			updateIndexFile();
		end, keepworkId);
	end
	
	if(login.dataSourceType == "github") then
		gen();
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:getProjectIdByName("keepworkDataSource",function(keepworkId)
			gen(keepworkId);
		end);
	end
end

function SyncMain:genWorldMD(worldInfor, _callback)
	local function gen(keepworkId)
		SyncMain:getFileShaListService("keepworkDataSource", function(data, err)
			LOG.std(nil,"debug","genWorldMD",data);
			local hasWorldFile  = false;
			local worldFilePath = "";
			local worldUrl      = "";
			local username      = "";
			SyncMain.worldFile  = "";

			if(login.dataSourceType == "gitlab") then
				username = login.dataSourceUsername:gsub("gitlab_" , "");
				worldUrl = "http://git.keepwork.com/" .. login.dataSourceUsername .. "/" .. GitEncoding.base64(SyncMain.foldername) .. "/repository/archive.zip?ref=master";
			else

			end

			local worldFilePath =  username .. "/paracraft/world_" .. worldInfor.worldsName;

			for key,value in ipairs(data) do
				if(value.path == worldFilePath) then
					hasWorldFile = true;
				end
			end
			
			local function updateTree(_callback)
				SyncMain:refreshWikiPages(worldFilePath, SyncMain.worldFile, function(data, err)
					LOG.std(nil,"debug","refreshWikiPages-data",data);
					LOG.std(nil,"debug","refreshWikiPages-err",err);
					if(_callback) then
						_callback();
					end
				end);
			end

			local function updateWorldFile()
				if(hasWorldFile) then
					LOG.std(nil,"debug","hasWorldFile",hasWorldFile);
					SyncMain:getDataSourceContent("keepworkDataSource", worldFilePath, function(data, err)
						local content    = Encoding.unbase64(data);
						local paramsText = KeepworkGen:GetContent(content);
						local params     = KeepworkGen:getCommand("world3D", paramsText);

						--if(params.version ~= worldInfor.revision) then
						local world3D = {
							worldName	  = worldInfor.worldsName,
							worldUrl	  = worldUrl,
							logoUrl		  = worldInfor.preview,
							desc		  = "",
							username	  = username,
							visitCount    = 1,
							favoriteCount = 1,
							updateDate	  = worldInfor.modDate,
							version		  = worldInfor.revision,
							filesTotals   = worldInfor.filesTotals,
							opusId        = worldInfor.opusId,
						}

						world3D = KeepworkGen:setCommand("world3D",world3D);
						SyncMain.worldFile = KeepworkGen:SetAutoGenContent(content, world3D);

						LOG.std(nil,"debug","worldFile",SyncMain.worldFile);

						SyncMain:updateService(
							"keepworkDataSource",
							worldFilePath,
							SyncMain.worldFile,
							"",
							function(isSuccess, path)
								LOG.std(nil,"debug","updateService-worldFile",isSuccess)
								LOG.std(nil,"debug","updateService-worldFile",path)
								updateTree(_callback);
							end,
							keepworkId
						);
						--end
					end, keepworkId)
				else
					LOG.std(nil,"debug","hasWorldFile",hasWorldFile);
					local world3D = {
						worldName	  = worldInfor.worldsName,
						worldUrl	  = worldUrl,
						logoUrl		  = worldInfor.preview,
						desc		  = "",
						username	  = username,
						visitCount    = 1,
						favoriteCount = 1,
						updateDate	  = worldInfor.modDate,
						version		  = worldInfor.revision,
						opusId        = worldInfor.opusId,
						filesTotals   = worldInfor.filesTotals,
					}

					world3D = KeepworkGen:setCommand("world3D",world3D);

					SyncMain.worldFile = KeepworkGen:SetAutoGenContent("", world3D)
					SyncMain.worldFile = SyncMain.worldFile .. "\n\r" .. worldInfor.readme;
					SyncMain.worldFile = SyncMain.worldFile .. "\n\r" .. KeepworkGen:setCommand("comment");

					LOG.std(nil,"debug","worldFile",SyncMain.worldFile);
				
					SyncMain:uploadService(
						"keepworkDataSource",
						worldFilePath,
						SyncMain.worldFile,
						function(data, err) 
							updateTree(_callback);
						end,
						keepworkId
					);
				end
			end

			updateWorldFile();
		end, keepworkId);
	end

	if(login.dataSourceType == "github") then
		gen();
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:getProjectIdByName("keepworkDataSource",function(keepworkId)
			gen(keepworkId);
		end);
	end
end

function SyncMain:deleteWorldMD(_path, _callback)
	local function deleteFile(keepworkId)
		local path = login.username ..  "/paracraft/world_" ..   _path;
		LOG.std(nil,"debug","path",path);
		SyncMain:deleteFileService("keepworkDataSource", path, "", function(data, err)
			_callback();
		end, keepworkId)
	end

	if(login.dataSourceType == "github") then
		deleteFile();
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:getProjectIdByName("keepworkDataSource",function(keepworkId)
			deleteFile(keepworkId);
		end);
	end
end

function SyncMain:refreshWikiPages(_path, _content, _callback)
	LOG.std(nil,"debug","_content",_content);
	HttpRequest:GetUrl({
		url  = login.site.."/api/wiki/models/website_pageinfo/get",
		json = true,
		headers = {Authorization = "Bearer "..login.token},
		form = {
			username     = login.username,
			websiteName  = "paracraft",
			dataSourceId = login.dataSourceId,
		},
	},function(data, err)
		--LOG.std(nil,"debug","getUserPages",data);
		local pageinfoList = data.data.pageinfo;

		local params = {};
		NPL.FromJson(pageinfoList, params);

		pageinfoList    = params;
		newPageinfoList = {};

		local hasFile = false;

		for key,value in ipairs(pageinfoList) do
			if(value.url == "/" .. _path) then
				hasFile     = true;	
				hasFileInfo = value;
			else
				newPageinfoList[#newPageinfoList + 1] = value;
			end
		end

		--LOG.std(nil,"debug","_path",_path);
		--LOG.std(nil,"debug","_content",_content);
		--LOG.std(nil,"debug","hasFile",hasFile);
		--LOG.std(nil,"debug","pageinfoList",pageinfoList);

		if(hasFile) then
			hasFileInfo.timestamp = os.time() .. "000";
			hasFileInfo.content   = _content;
			hasFileInfo.isModify  = true;

			newPageinfoList[#newPageinfoList + 1] = hasFileInfo;
		else
			LOG.std(nil,"debug","os", os.time() .. "000");

			local thisInfor = {};

			thisInfor.timestamp    = os.time() .. "000";
			thisInfor.websiteName  = "paracraft";
			thisInfor.userId	   = login.userId;
			thisInfor.dataSourceId = login.dataSourceId;
			thisInfor.isModify	   = false;
			thisInfor.username	   = login.username;
			thisInfor.name	       = _path;
			thisInfor.url		   = "/" .. _path;
			thisInfor.content      = _content;

			newPageinfoList[#newPageinfoList + 1] = thisInfor;
		end

		LOG.std(nil,"debug","newPageinfoList",newPageinfoList);

		newPageinfoList = NPL.ToJson(newPageinfoList,true);

		local params = {};
		params.dataSourceId = login.dataSourceId;
		params.isExistSite  = 1;
		params.pageinfo     = newPageinfoList;
		params.username     = login.username;
		params.websiteName  = "paracraft";

		HttpRequest:GetUrl({
			url  = login.site.."/api/wiki/models/website_pageinfo/upsert",
			json = true,
			headers = {Authorization = "Bearer "..login.token},
			form = params,
		},_callback)
	end);
end

function SyncMain.deleteWorld()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/sync/DeleteWorld.html",
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

function SyncMain.deleteWorldLocal(_callback)
	local world = InternetLoadWorld:GetCurrentWorld();
	
	if(not world) then
		_guihelper.MessageBox(L"请先选择世界");
		return;
	end

	_guihelper.MessageBox(format(L"确定删除本地世界:%s?", world.text or ""), function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			if(world.RemoveLocalFile and world:RemoveLocalFile()) then
				InternetLoadWorld.RefreshAll();
			elseif(world.remotefile) then
				local targetDir = world.remotefile:gsub("^local://", ""); -- local world, delete all files in folder and the folder itself.

				if(GameLogic.RemoveWorldFileWatcher) then
					GameLogic.RemoveWorldFileWatcher(); -- file watcher may make folder deletion of current world directory not working.
				end

				if(commonlib.Files.DeleteFolder(targetDir)) then  
					local foldername = SyncMain.selectedWorldInfor.foldername;
					SyncMain.handleCur_ds = {};

					local hasRemote = false;
					for key,value in ipairs(InternetLoadWorld.cur_ds) do
						if(value.foldername == foldername and value.status == 3 or value.status == 4 or value.status == 5) then
							value.status = 2;
							hasRemote = true;
							break;
						end

						if(value.foldername ~= foldername) then
							SyncMain.handleCur_ds[#SyncMain.handleCur_ds + 1] = value;
						end
					end

					if (not hasRemote) then
						InternetLoadWorld.cur_ds = login.handleCur_ds;
					end

					if(type(_callback) == 'function') then
						_callback(foldername);
					else
						Page:CloseWindow();

						local localWorlds = InternetLoadWorld.cur_ds;
						local newLocalWorlds = {};

						for key,value in ipairs(localWorlds) do
							if(value.foldername ~= foldername) then
								newLocalWorlds[#newLocalWorlds + 1] = value;
							end
						end

						InternetLoadWorld.cur_ds = newLocalWorlds;
						LOG.std(nil,"debug","localWorlds-deleteWorldLocal",localWorlds);
						login.syncWorldsList();

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

function SyncMain.deleteWorldRemote()
	if(login.dataSourceType == "github") then
		SyncMain.deleteWorldGithubLogin();
	elseif(login.dataSourceType == "gitlab") then
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
	local basicAuth  = login.dataSourceUsername .. ":" .. _password;
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
	    	Page:CloseWindow();

	    	if(res and res == 6) then
	    		GithubService:deleteResp(foldername, AuthToken, function(data,err)
	    			--LOG.std(nil,"debug","GithubService:deleteResp",err);
	    			if(err == 204) then
	    				SyncMain.deleteKeepworkWorldsRecord();
	    			else
						_guihelper.MessageBox(L"远程仓库不存在，请联系管理员");
						if(not WorldCommon.GetWorldInfo()) then
							MainLogin.state.IsLoadMainWorldRequested = nil;
							MainLogin:next_step();
						end
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
	    Page:CloseWindow();

	    if(res and res == 6) then
	    	GitlabService:deleteResp(foldername, function(data, err)
				if(err == 202) then
					SyncMain.deleteKeepworkWorldsRecord();
				else
					_guihelper.MessageBox(L"远程仓库不存在，请联系管理员");
					if(not WorldCommon.GetWorldInfo()) then
						MainLogin.state.IsLoadMainWorldRequested = nil;
						MainLogin:next_step();
					end
				end
			end);
	    end
	end);
end

function SyncMain.deleteKeepworkWorldsRecord()
	local foldername = SyncMain.selectedWorldInfor.foldername;
	local url = login.site .. "/api/mod/worldshare/models/worlds";

	LOG.std(nil,"debug","deleteKeepworkWorldsRecord",url);
	LOG.std(nil,"debug","deleteKeepworkWorldsRecord",foldername);
	LOG.std(nil,"debug","deleteKeepworkWorldsRecord",login.token);

	HttpRequest:GetUrl({
		method  = "DELETE",
		url     = url,
		form    = {
			worldsName = foldername,
		},
		json    = true,
		headers = {
			Authorization = "Bearer " .. login.token,
		},
	},function(data, err)
		LOG.std(nil,"debug","deleteKeepworkWorldsRecord",data)
		LOG.std(nil,"debug","deleteKeepworkWorldsRecord",err)

		if(err == 204) then
			SyncMain.handleCur_ds = {};

			local hasLocal = false;
			for key,value in ipairs(InternetLoadWorld.cur_ds) do
				if(value.foldername == foldername and value.status == 3 or value.status == 4 or value.status == 5) then
					value.status = 1;
					hasLocal = true;
					break;
				end

				if(value.foldername ~= foldername) then
					SyncMain.handleCur_ds[#SyncMain.handleCur_ds + 1] = value;
				end
			end

			if(not hasLocal)then
				InternetLoadWorld.cur_ds = SyncMain.handleCur_ds;
			end

			LOG.std(nil,"debug","InternetLoadWorld.cur_ds",InternetLoadWorld.cur_ds);

			Page:CloseWindow();

			if(not WorldCommon.GetWorldInfo()) then
				MainLogin.state.IsLoadMainWorldRequested = nil;
				MainLogin:next_step();
			end

			SyncMain:deleteWorldMD(foldername,function()
				HttpRequest:GetUrl({
					url  = login.site.."/api/mod/worldshare/models/worlds",
					json = true,
					headers = {Authorization = "Bearer "..login.token},
					form = {amount = 100},
				},function(worldList, err)
					LOG.std(nil,"debug","worldList-data",worldList);
					SyncMain:genIndexMD(worldList);
				end);
			end)
		end
	end);
end

function SyncMain.deleteWorldAll()
	SyncMain.deleteWorldLocal(function()
		SyncMain.deleteWorldRemote();
	end);
end

function SyncMain:create(_foldername,_callback)
	if(login.dataSourceType == "github") then
		GithubService:create(_foldername,_callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:init(_foldername,_callback);
	end
end

function SyncMain:getDataSourceContent(_foldername, _path, _callback, _projectId)
	if(login.dataSourceType == "github") then
		GithubService:getContent(_foldername, _path, _callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:getContent(_path, _callback,_projectId);
	end
end

function SyncMain:uploadService(_foldername,_filename,_file_content_t,_callback, _projectId)
	if(login.dataSourceType == "github") then
		GithubService:upload(_foldername,_filename,_file_content_t,_callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:writeFile(_filename,_file_content_t,_callback, _projectId);
	end
end

function SyncMain:updateService(_foldername, _filename, _file_content_t, _sha, _callback, _projectId)
	if(login.dataSourceType == "github") then
		GithubService:update(_foldername, _filename, _file_content_t, _sha, _callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:update(_filename, _file_content_t, _sha, _callback, _projectId);
	end
end

function SyncMain:deleteFileService(_foldername, _path, _sha, _callback, _projectId)
	if(login.dataSourceType == "github") then
		GithubService:deleteFile(_foldername, _path, _sha, _callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:deleteFile(_path, _sha, _callback, _projectId);
	end
end

function SyncMain:getFileShaListService(_foldername, _callback, _projectId)
	if(login.dataSourceType == "github") then
		GithubService:getFileShaList(_foldername, _callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:getTree(_callback, _projectId);
	end
end

function SyncMain:getCommits(_callback, _projectId)
	if(login.dataSourceType == "github") then
		GithubService:getCommits(_foldername, _callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:listCommits(_callback, _projectId);
	end
end