--[[
Title: WorldShareGUI
Author(s):  big
Date:  2016.12.10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/WorldShareGUI.lua");
local WorldShareGUI = commonlib.gettable("Mod.WorldShare.WorldShareGUI");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldRevision.lua");
NPL.load("(gl)Mod/WorldShare/ShowLogin.lua");
NPL.load("(gl)Mod/WorldShare/GithubService.lua");
NPL.load("(gl)Mod/WorldShare/LocalService.lua");
NPL.load("(gl)Mod/WorldShare/SyncGUI.lua");

local WorldShareGUI = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.WorldShareGUI"));
local SyncGUI       = commonlib.gettable("Mod.WorldShare.SyncGUI");
local WorldCommon   = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local ShowLogin     = commonlib.gettable("Mod.WorldShare.ShowLogin");
local GithubService = commonlib.gettable("Mod.WorldShare.GithubService");
local LocalService  = commonlib.gettable("Mod.WorldShare.LocalService");

function WorldShareGUI:ctor()
end

function WorldShareGUI:init()
	Page = document:GetPageCtrl();
	LOG.std(nil, "debug", "WorldShareGUI", "init");
end

function WorldShareGUI:StartSyncPage()	
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/StartSync.html", 
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

	LOG.std(nil, "debug", "WorldShareGUI", "WorldShareGUI ShowLogin");
end

function WorldShareGUI:HideLogin()
	self.page:Close();
	LOG.std(nil, "debug", "WorldShareGUI", "WorldShareGUI HideLogin");
end

function WorldShareGUI:OnLogin()
	LOG.std(nil, "debug", "WorldShareGUI", "WorldShareGUI Login");
end

function WorldShareGUI:OnWorldLoad()
	-- 没有登陆则直接使用离线模式
	if(ShowLogin.login) then
		self:compareRevision();
		self:StartSyncPage();
	end
end

function WorldShareGUI:OnLeaveWorld()
end

function WorldShareGUI:OnInitDesktop()
end

function WorldShareGUI:handleKeyEvent(event)
	-- if(event.keyname == "DIK_SPACE") then
	-- 	_guihelper.MessageBox("you pressed "..event.keyname.." from Demo GUI");
	-- 	return true;
	-- end
end

function WorldShareGUI:compareRevision()
	if(ShowLogin.login) then
		-- self.getWorldInfo      = WorldCommon:GetWorldInfo();
		self.worldDir          = GameLogic.GetWorldDirectory();
		WorldRevisionCheckOut  = WorldRevision:new():init(self.worldDir);
		self.currentRevison    = WorldRevisionCheckOut:Checkout();

		self.foldername = self.worldDir:match("worlds/DesignHouse/(%w+)/");

		self.githubRevison  = 0;

		local contentUrl = "https://raw.githubusercontent.com/".. ShowLogin.login .."/".. self.foldername .."/master/revision.xml";

		GithubService:githubGet(contentUrl, function(data)
			self.githubRevison = data;

			if(tonumber(self.currentRevison) ~= tonumber(self.githubRevison)) then
				Page:Refresh(0.01);
			else
				Page:CloseWindow();
			end
		end);
	end
end

function WorldShareGUI:useLocal()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/StartSyncUseLocal.html", 
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

function WorldShareGUI:useGithub()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/WorldShare/StartSyncUseGithub.html", 
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

function WorldShareGUI:syncToLocal()
	-- 加载进度UI界面
	SyncGUI:ctor();

	self.localFiles = LocalService:LoadFiles(self.worldDir,"",nil,1000,nil);

	if (self.worldDir == "") then
		_guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空");
		return;
	else 
		local curUpdateIndex    = 1;
		local curDownloadIndex  = 1;
		local totalLocalIndex   = nil;
		local totalGithubIndex  = nil;
		local githubFiles       = {};
		local syncGUItotal      = 0;
		local syncGUIIndex      = 0;
		local syncGUIFiles      = "";

		-- LOG.std(nil,"debug","WorldShareGUI",curDownloadIndex);
		-- LOG.std(nil,"debug","WorldShareGUI",totalGithubIndex);

		-- 下载新文件
		function downloadOne()
			if (curDownloadIndex <= totalGithubIndex) then

				LOG.std(nil,"debug","githubFiles.tree[curDownloadIndex]",githubFiles.tree[curDownloadIndex]);

				if (githubFiles.tree[curDownloadIndex].needChange) then

					if(githubFiles.tree[curDownloadIndex].type == "blob") then
						LocalService:download(self.foldername, githubFiles.tree[curDownloadIndex].path, function (bIsDownload,data)
							if (bIsDownload) then
								_guihelper.MessageBox(githubFiles.tree[curDownloadIndex].path .. ' 下载成功' .. (curDownloadIndex + 1) .. '/' .. totalGithubIndex);
								curDownloadIndex = curDownloadIndex + 1;
								syncGUIIndex     = syncGUIIndex     + 1;
								syncGUIFiles     = githubFiles.tree[curUpdateIndex].path;

								SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);
							else
								_guihelper.MessageBox(self.localFiles[curDownloadIndex].filename .. ' 下载失败，请稍后再试');
							end
						end);
					else
						curDownloadIndex = curDownloadIndex + 1;
					end
				else
					curDownloadIndex = curDownloadIndex + 1;
				end

				if (curDownloadIndex > totalGithubIndex) then
					-- _guihelper.MessageBox('同步完成-D');
				else
					downloadOne(); --继续递归上传
				end
			end
		end

		-- 更新本地文件
		function updateOne()
			if (curUpdateIndex <= totalLocalIndex) then
				LOG.std(nil,"debug","curUpdateIndex",curUpdateIndex);
				local bIsExisted  = false;
				local githubIndex = nil;

				-- 用Gihub的文件和本地的文件对比
				for key,value in ipairs(githubFiles.tree) do
					if(value.path == self.localFiles[curUpdateIndex].filename) then
						LOG.std(nil,"debug","value.path",value.path);
						bIsExisted  = true;
						githubIndex = key; 
						break;
					end
				end

				-- compare the files in github with the ones in local host
				if (bIsExisted) then
					-- if existed
					githubFiles.tree[githubIndex].needChange = false;
					LOG.std(nil,"debug","self.localFiles[curUpdateIndex].filename",self.localFiles[curUpdateIndex].filename);
					LOG.std(nil,"debug","self.localFiles[curUpdateIndex].sha1",self.localFiles[curUpdateIndex].sha1);
					LOG.std(nil,"debug","githubFiles.tree[githubIndex].sha",githubFiles.tree[githubIndex].sha);

					if (self.localFiles[curUpdateIndex].sha1 ~= githubFiles.tree[githubIndex].sha) then
						-- 更新已存在的文件
						-- if file existed, and has different sha value, update it
						LocalService:update(self.foldername, githubFiles.tree[githubIndex].path, githubFiles.tree[githubIndex].sha, function (bIsUpdate,content)
							if (bIsUpdate) then
								-- _guihelper.MessageBox(githubFiles.tree[curUpdateIndex].path .. ' 更新成功' .. (curUpdateIndex + 1) .. '/' .. totalLocalIndex);
								curUpdateIndex = curUpdateIndex + 1;
								syncGUIIndex   = syncGUIIndex   + 1;
								syncGUIFiles   = githubFiles.tree[githubIndex].path;
								LOG.std(nil,"debug","syncGUIIndex",syncGUIIndex);
								LOG.std(nil,"debug","githubFiles.tree[githubIndex].path",githubFiles.tree[githubIndex].path);

								SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);

								-- 如果当前计数大于最大计数则更新
								if (curUpdateIndex > totalLocalIndex) then      -- check whether all files have updated or not. if false, update the next one, if true, upload files.  
									-- _guihelper.MessageBox(L'同步完成-A');
									downloadOne();
								else
									updateOne();
								end
							else
								_guihelper.MessageBox(githubFiles.tree[githubIndex].path .. ' 更新失败,请稍后再试');
							end
						end);
					else
						-- if file exised, and has same sha value, then contain it
						-- _guihelper.MessageBox(githubFiles.tree[curUpdateIndex].path .. ' 文件更新完成' .. (curUpdateIndex + 1) .. '/' .. totalLocalIndex);
						curUpdateIndex = curUpdateIndex + 1;
						syncGUIIndex   = syncGUIIndex   + 1;
						syncGUIFiles   = githubFiles.tree[githubIndex].path;
						LOG.std(nil,"debug","syncGUIIndex",syncGUIIndex);
						LOG.std(nil,"debug","githubFiles.tree[githubIndex].path",githubFiles.tree[githubIndex].path);

						SyncGUI:updateDataBar(syncGUIIndex,syncGUItotal, syncGUIFiles);

						if (curUpdateIndex > totalLocalIndex) then     -- check whether all files have updated or not. if false, update the next one, if true, upload files.
							-- _guihelper.MessageBox(L'同步完成-B');
							downloadOne();
						else
							updateOne();
						end
					end
				else
					LOG.std(nil,"debug","delete-filename",self.localFiles[curUpdateIndex].filename);
					LOG.std(nil,"debug","delete-sha1",self.localFiles[curUpdateIndex].sha1);

					-- 如果过github不删除存在，则删除本地的文件
					-- if file does not exist, delete it
					deleteOne();
				end
			end
		end

		-- 删除文件
		function deleteOne()
			LocalService.delete(self.foldername, self.localFiles[curUpdateIndex].filename, self.localFiles[curUpdateIndex].sha1, function (bIsDelete)
				if (bIsDelete) then
					-- _guihelper.MessageBox (self.localFiles[curUpdateIndex].filename .. ' 删除成功' .. (curUpdateIndex + 1) .. '/' .. totalLocalIndex);
					curUpdateIndex = curUpdateIndex + 1;

					if (curUpdateIndex > totalLocalIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
						_guihelper.MessageBox(L'同步完成-C');
						downloadOne();
					else
						updateOne();
					end
				else
					_guihelper.MessageBox('删除 ' .. self.localFiles[curUpdateIndex].filename .. ' 失败, 请稍后再试');
				end
			end);
		end

		-- 获取github仓文件
		-- get sha value of the files in github
		GithubService:getFileShaList(self.foldername, function(data)
			NPL.FromJson(data,githubFiles);

			if (githubFiles ~= 'false') then --if success, then update files
				--_guihelper.MessageBox(L"获取github仓文件成功");
				
				-- LOG.std(nil,"debug","WorldShareGUI",self.localFiles);
				-- LOG.std(nil,"debug","WorldShareGUI",#self.localFiles);

				for i=1,#githubFiles.tree do
					githubFiles.tree[i].needChange = true;

					if(githubFiles.tree[i].type == "blob") then
						syncGUItotal = syncGUItotal + 1;
					end

					i = i + 1;
				end

				SyncGUI:updateDataBar(syncGUIIndex,syncGUItotal);

				totalLocalIndex  = #self.localFiles;
				totalGithubIndex = #githubFiles.tree;

				LOG.std(nil,"debug","totalLocalIndex",totalLocalIndex);
				LOG.std(nil,"debug","totalGithubIndex",totalGithubIndex);

				updateOne();
			else
				--if the repos is empty, then upload files 
				downloadOne();
			end
		end);
	end
end

function WorldShareGUI:syncToGithub()
	-- 加载进度UI界面
	SyncGUI:ctor();

	self.localFiles = LocalService:LoadFiles(self.worldDir,"",nil,1000,nil);

	if (self.worldDir == "") then
		_guihelper.MessageBox(L"上传失败，将使用离线模式，原因：上传目录为空");
		return;
	else 
		self.progressText = L'获取文件sha列表';

		local curUpdateIndex    = 1;
		local curUploadIndex    = 1;
		local totalLocalIndex   = nil;
		local totalGithubIndex  = nil;
		local githubFiles       = {};
		local syncGUItotal      = 0;
		local syncGUIIndex      = 0;
		local syncGUIFiles      = "";

		-- LOG.std(nil,"debug","WorldShareGUI",curUploadIndex);
		-- LOG.std(nil,"debug","WorldShareGUI",totalGithubIndex);

		-- 上传新文件
		function uploadOne()
			if (curUploadIndex <= totalLocalIndex) then
				-- LOG.std(nil,"debug","self.localFiles[curUploadIndex]",self.localFiles[curUploadIndex]);
				if (self.localFiles[curUploadIndex].needChange) then
					
					GithubService:upload(self.foldername, self.localFiles[curUploadIndex].filename, self.localFiles[curUploadIndex].content,function (bIsDownload,data)
						if (bIsDownload) then
							-- self.progressText = self.localFiles[curUploadIndex].filename .. ' 上传成功' .. (curUploadIndex + 1) .. '/' .. totalGithubIndex;
							curUploadIndex = curUploadIndex + 1;
							syncGUIIndex   = syncGUIIndex   + 1;
							syncGUIFiles   = self.localFiles[LocalIndex].filename;

							SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);
						else
							_guihelper.MessageBox(self.localFiles[curUploadIndex].filename .. ' 上传失败，请稍后再试');
						end
					end);
				else
					curUploadIndex = curUploadIndex + 1;
				end

				if (curUploadIndex > totalLocalIndex) then
					finish();
					_guihelper.MessageBox('同步完成-D');
				else
					uploadOne(); --继续递归上传
				end
			end
		end

		-- 更新Github文件
		function updateOne()
			if (curUpdateIndex <= totalGithubIndex) then
				LOG.std(nil,"debug","curUpdateIndex",curUpdateIndex);
				LOG.std(nil,"debug","curUpdateIndex",totalGithubIndex);
				local bIsExisted  = false;
				local LocalIndex  = nil;

				-- 用Gihub的文件和本地的文件对比
				for key,value in ipairs(self.localFiles) do
					if(value.path == githubFiles.tree[curUpdateIndex].filename) then
						bIsExisted  = true;
						LocalIndex  = key; 
						break;
					end
				end

				-- compare the files in github with the ones in local host
				if (bIsExisted) then
					-- if existed
					self.localFiles.needChange = false;
					LOG.std(nil,"debug","githubFiles.tree[curUpdateIndex].path",githubFiles.tree[curUpdateIndex].path);
					LOG.std(nil,"debug","githubFiles.tree[curUpdateIndex].sha",githubFiles.tree[curUpdateIndex].sha);
					LOG.std(nil,"debug","self.localFiles.sha1",self.localFiles[LocalIndex].sha1);

					if (githubFiles.tree[curUpdateIndex].sha ~= self.localFiles[LocalIndex].sha1) then
						-- 更新已存在的文件
						-- if file existed, and has different sha value, update it
						GithubService:update(self.foldername, self.localFiles[LocalIndex].filename, self.localFiles[LocalIndex].content, self.localFiles[LocalIndex].sha1, function (bIsUpdate,content)
							if (bIsUpdate) then
								-- _guihelper.MessageBox(self.localFiles[LocalIndex].filename .. ' 更新成功' .. (curUpdateIndex + 1) .. '/' .. totalGithubIndex);
								curUpdateIndex = curUpdateIndex + 1;

								-- 如果当前计数大于最大计数则更新
								if (curUpdateIndex > totalGithubIndex) then      -- check whether all files have updated or not. if false, update the next one, if true, upload files.  
									-- _guihelper.MessageBox(L'同步完成-A');
									finish();
									uploadOne();
								else
									syncGUIIndex   = syncGUIIndex   + 1;
									syncGUIFiles   = self.localFiles[LocalIndex].filename;

									SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);
									updateOne();
								end
							else
								-- _guihelper.MessageBox(githubFiles.tree[curUpdateIndex].path .. ' 更新失败,请稍后再试');
							end
						end);
					else
						-- if file exised, and has same sha value, then contain it
						-- _guihelper.MessageBox(githubFiles.tree[curUpdateIndex].path .. ' 文件更新完成' .. (curUpdateIndex + 1) .. '/' .. totalGithubIndex);
						curUpdateIndex = curUpdateIndex + 1;

						if (curUpdateIndex > totalGithubIndex) then     -- check whether all files have updated or not. if false, update the next one, if true, upload files.
							-- _guihelper.MessageBox(L'同步完成-B');
							finish();
							uploadOne();
						else
							syncGUIIndex   = syncGUIIndex   + 1;
							syncGUIFiles   = self.localFiles[LocalIndex].filename;

							SyncGUI:updateDataBar(syncGUIIndex, syncGUItotal, syncGUIFiles);
							updateOne();
						end
					end
				else
					LOG.std(nil,"debug","delete-filename",self.localFiles[curUpdateIndex].filename);
					LOG.std(nil,"debug","delete-sha1",self.localFiles[curUpdateIndex].sha1);

					-- 如果过github不删除存在，则删除本地的文件
					-- if file does not exist, delete it
					deleteOne();
				end
			end
		end

		-- 删除Github文件
		function deleteOne()
			GithubService.delete(self.foldername, githubFiles.tree[curUpdateIndex].filename, githubFiles.tree[curUpdateIndex].sha, function (bIsDelete)
				if (bIsDelete) then
					_guihelper.MessageBox (self.localFiles[curUpdateIndex].filename .. ' 删除成功' .. (curUpdateIndex + 1) .. '/' .. totalLocalIndex);
					curUpdateIndex = curUpdateIndex + 1;

					if (curUpdateIndex > totalLocalIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
						_guihelper.MessageBox(L'同步完成-C');
						finish();
						uploadOne();
					else
						updateOne();
					end
				else
					_guihelper.MessageBox('删除 ' .. self.localFiles[curUpdateIndex].filename .. ' 失败, 请稍后再试');
				end
			end);
		end

		function finish()
			if(syncGUItotal == syncGUIIndex) then
				GithubService:GetUrl({
					url = ShowLogin.site.."/api/mod/WorldShare/models/worlds/refresh",
					form = {
						worldsName = self.foldername,
						revision   = self.currentRevison
					},
					headers = {Authorization = "Bearer "..ShowLogin.token}
				},function(data)

				end)
			end
		end

		-- 获取github仓文件
		-- get sha value of the files in github
		GithubService:getFileShaList(self.foldername, function(data)
			NPL.FromJson(data,githubFiles);

			if (githubFiles ~= 'false') then --if success, then update files
				--_guihelper.MessageBox(L"获取github仓文件成功");
				
				-- LOG.std(nil,"debug","WorldShareGUI",self.localFiles);
				-- LOG.std(nil,"debug","WorldShareGUI",#self.localFiles);

				for i=1,#self.localFiles do
					self.localFiles.needChange = true;
					i = i + 1;
				end

				syncGUItotal = #self.localFiles;
				SyncGUI:updateDataBar(syncGUIIndex,syncGUItotal);

				totalLocalIndex  = #self.localFiles;
				totalGithubIndex = #githubFiles.tree;
				updateOne();
			else
				--if the repos is empty, then upload files 
				uploadOne();
			end
		end);
	end
end
