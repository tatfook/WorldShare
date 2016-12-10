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

local WorldShareGUI = commonlib.inherit(nil,commonlib.gettable("Mod.WorldShare.WorldShareGUI"));
local WorldCommon   = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local WorldRevision = commonlib.gettable("MyCompany.Aries.Creator.Game.WorldRevision");
local ShowLogin     = commonlib.gettable("Mod.WorldShare.ShowLogin");
local GithubService = commonlib.gettable("Mod.WorldShare.GithubService");

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
	local getWorldInfo = WorldCommon:GetWorldInfo();
	local worldDir     = GameLogic.GetWorldDirectory();
	local xmlRevison   = WorldRevision:new():init(worldDir);

	LOG.std(nil,"debug","getWorldInfo",getWorldInfo);
	LOG.std(nil,"debug","worldDir",worldDir);
	LOG.std(nil,"debug","revison",xmlRevison);

	if(ShowLogin.login) then --如果为登陆状态 则比较版本
		local foldername = worldDir:match("worlds/DesignHouse/(%w+)/");
		self.foldername  = foldername;

		self.currentRevison = xmlRevison["current_revision"];
		self.githubRevison  = 0;

		GithubService:getFileShaList(foldername,function(err, msg, data)
			local tree = data["tree"];
			for key,value in ipairs(tree) do
				if(value["path"] == "revision.xml" and value["type"] == "blob") then
					local contentUrl = "https://raw.githubusercontent.com/".. ShowLogin.login .."/".. foldername .."/master/revision.xml";
					GithubService:githubApiGet(contentUrl,function(err,msg,data)
						self.githubRevison = data;
						Page:Refresh(0.01);
					end)
				end
			end
		end);

		if(self.currentRevison ~= self.githubRevison) then
			self:StartSyncPage();
		end
	end
end

function WorldShareGUI:OnLeaveWorld()
end

function WorldShareGUI:OnInitDesktop()
end

function WorldShareGUI:handleKeyEvent(event)
	if(event.keyname == "DIK_SPACE") then
		_guihelper.MessageBox("you pressed "..event.keyname.." from Demo GUI");
		return true;
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

function WorldShareGUI:sync() {
	self.files = self:LoadFiles(self.worldDir,"",nil,1000,nil);

	if (self.worldDir == "") then
		_guihelper.MessageBox("上传目录为空");
		return;
	else 
		self.progressText = 'getting file sha list...';

		local curUploadIndex   = 0;
		local totalUploadIndex = #self.files;

		-- 上传新文件
		local uploadOne = function ()
			if (curUploadIndex < totalUploadIndex) then
				if (self.files[curUploadIndex].needUpload) then
					GithubService:upload(self.foldername, self.files[curUploadIndex].filename, self.files[curUploadIndex].file_content, function (err, msg, bIsUpload)
						if (bIsUpload) then
							self.progressText = self.files[curUploadIndex].filename .. ' upload successfully...' + (curUploadIndex + 1) .. '/' + totalUploadIndex;
							curUploadIndex += 1;

							if (curUploadIndex >= totalUploadIndex) then
								_guihelper.MessageBox('sync successfully!');
							else
								uploadOne(); --未上传完继续递归上传
							end
						else
							_guihelper.MessageBox(self.files[curUploadIndex].filename .. ' upload failed, please try again later...');
						end
					end);
				else
					curUploadIndex += 1;

					if (curUploadIndex >= totalUploadIndex) then
						_guihelper.MessageBox('sync successfully!');
					else
						uploadOne();
					end
				end
			end
		end

		-- 获取github仓文件
		-- get sha value of the files in github
		GithubService.getFileShaList(self.foldername, function (returnInfo)
			if (returnInfo != 'false') then --if success, then update files

				self.progressText    = 'get remote file sha list successfully...';
				local aLocalFileName = {};

				for i=0,#self.files do
					aLocalFileName[i] = self.files[i].filename;
					i++;
				end

				self.progressText = 'get local file list successfully...';

				local curIndex = 0;
				local totalIndex = #returnInfo.tree;

				local updateOne  = function ()         -- update files had existed in github one by one
					if (curIndex < totalIndex) then

						local bIsExisted = aLocalFileName.indexOf(returnInfo.tree[curIndex].path);

						-- compare the files in github with the ones in local host
						if (bIsExisted > -1) then
							-- if existed,
							self.files[bIsExisted].needUpload = false;
							if (self.files[bIsExisted].sha1 ~= returnInfo.tree[curIndex].sha) then
								-- 更新已存在的文件
								-- if file existed, and has different sha value, update it
								GithubService.update(self.foldername, returnInfo.tree[curIndex].path, self.files[bIsExisted].file_content, returnInfo.tree[curIndex].sha, function (bIsUpdate)
									if (bIsUpdate) then
										self.progressText = returnInfo.tree[curIndex].path .. ' update successfully...' .. (curIndex + 1) .. '/' .. totalIndex;
										curIndex += 1;

										if (curIndex >= totalIndex) then      -- check whether all files have updated or not. if false, update the next one, if true, upload files.  
											$scope.progressText = 'all file update successfully...';
											uploadOne();
										else
											updateOne();
										end
									else
										_guihelper.MessageBox(returnInfo.tree[curIndex].path .. ' update failed, please try again later...');
									end
								end);
							else
								-- if file exised, and has same sha value, then contain it
								self.progressText = returnInfo.tree[curIndex].path .. ' has existed...' .. (curIndex + 1) .. '/' .. totalIndex;
								curIndex += 1;

								if (curIndex >= totalIndex) then     -- check whether all files have updated or not. if false, update the next one, if true, upload files.
									self.progressText = 'all file update successfully...';
									uploadOne();
								else
									updateOne();
								end
							end
						else
							-- 删除存在的文件
							-- if file does not exist, delete it
							if (returnInfo.tree[curIndex].type == 'blob') then
								GithubService.delete(self.foldername, returnInfo.tree[curIndex].path, returnInfo.tree[curIndex].sha, function (bIsDelete)
									if (bIsDelete) then
										self.progressText = returnInfo.tree[curIndex].path + ' delete successfully...' + (curIndex + 1) + '/' + totalIndex;
										curIndex += 1;

										if (curIndex >= totalIndex) then  --check whether all files have updated or not. if false, update the next one, if true, upload files.
											self.progressText = 'all file update successfully...';
											uploadOne();
										else
											updateOne();
										end
									else
										_guihelper.MessageBox('delete ' + returnInfo.tree[curIndex].path + ' failed, please try again later...');
									end
								end);
							else
								self.progressText = returnInfo.tree[curIndex].path .. 'has existed...' .. (curIndex + 1) .. '/' .. totalIndex;
								curIndex += 1;

								if (curIndex >= totalIndex) then   -- check whether all files have updated or not. if false, update the next one, if true, upload files.
									self.progressText = 'all file update successfully...';
									uploadOne();
								else
									updateOne();
								end
							end

						end
					end
				end

				updateOne();

			else
				--if the repos is empty, then upload files 
				uploadOne();
			end
		end);
	end
};

function WorldShareGUI:LoadFiles(worldDir,curPath,filter,nMaxFileLevels,nMaxFilesNum)
	filter 		   = filter or "*.*";
	nMaxFileLevels = nMaxFileLevels or 0;
	nMaxFilesNum   = nMaxFilesNum or 500;
	local output   = {};
	local path     = worldDir..curPath;

	if(curPath ~= "") then
		curPath = curPath.."/";
	end

	NPL.load("(gl)script/ide/Files.lua");
	
	local function filesFind(result)
		if(type(result) == "table") then
			for i = 1, #result do
				local item = result[i];
				if(not string.match(item.filename, '/')) then
					if(item.filesize ~= 0) then
						--path = string.gsub(path, 'MyWorld/', 'MyWorld', 1);
						item.file_path = path..'/'..item.filename;
						--string.gsub(path..item.filename, '//', '/', 1);
						item.filename = commonlib.Encoding.DefaultToUtf8(string.gsub(item.file_path, 'worlds/designhouse/abc//', '', 1));
						item.id = item.filename;
						item.file_content_t = getFileContent(item.file_path);
						item.file_content = Encoding_.base64(item.file_content_t);
						item.sha1 = Encoding_.sha1("blob "..item.filesize.."\0"..item.file_content_t, "hex");
						item.needUpload = true;
						output[#output+1] = item;
					else
						path = path ..'/'.. item.filename;
						local result = commonlib.Files.Find({}, path, 0, nMaxFilesNum, filter);
						filesFind(result);
						path = string.gsub(path, ('/'..item.filename), '', 1);
					end
				end
			end
		end
	end

	local result = commonlib.Files.Find({}, path, 0, nMaxFilesNum, filter);
	filesFind(result);
	
	return output;
end
