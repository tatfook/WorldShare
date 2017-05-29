--[[
Title: LocalService
Author(s):  big
Date:  2016.12.11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua");
local LocalService = commonlib.gettable("Mod.WorldShare.service.LocalService");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Files.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/System/Encoding/sha1.lua");
NPL.load("(gl)Mod/WorldShare/service/GithubService.lua");
NPL.load("(gl)Mod/WorldShare/login/loginMain.lua");
NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua");
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua");
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua");
NPL.load("(gl)Mod/WorldShare/service/FileDownloader.lua");

local FileDownloader = commonlib.inherit(nil, commonlib.gettable("Mod.WorldShare.service.FileDownloader"));
local GitEncoding    = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local GitlabService  = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local GithubService  = commonlib.gettable("Mod.WorldShare.service.GithubService");
local EncodingC      = commonlib.gettable("commonlib.Encoding");
local EncodingS      = commonlib.gettable("System.Encoding");
local Files          = commonlib.gettable("commonlib.Files");
local loginMain      = commonlib.gettable("Mod.WorldShare.login.loginMain");
local SyncMain       = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local LocalService   = commonlib.gettable("Mod.WorldShare.service.LocalService");

LocalService.gitAttribute = "*.* binary";

--get file content by text
function LocalService:getFileContent(_filePath)      
	local file = ParaIO.open(_filePath, "r");
	if(file:IsValid()) then
		local fileContent = file:GetText(0, -1);
		file:close();
		return fileContent;
	end
end

function LocalService:filesFind(_result)
	if(type(_result) == "table") then
		local convertLineEnding = {[".xml"] = true, [".txt"] = true, [".md"] = true, [".bmax"] = true};

		for i = 1, #_result do
			local item = _result[i];

			if(not string.match(item.filename, '/')) then
				if(item.filesize ~= 0) then
					item.file_path = self.path..'/'..item.filename;
					item.filename = EncodingC.DefaultToUtf8(string.gsub(item.file_path, self.worldDir..'/', '', 1));
					item.id = item.filename;

					local sExt = item.filename:match("%.[^&.]+$");

					if(convertLineEnding[sExt]) then
						item.file_content_t = self:getFileContent(item.file_path):gsub("\r\n","\n");
						item.filesize = #item.file_content_t;
						item.sha1 = EncodingS.sha1("blob " .. item.filesize .. "\0" .. item.file_content_t, "hex");
					else
						item.file_content_t = self:getFileContent(item.file_path);
						item.sha1 = EncodingS.sha1("blob " .. item.filesize .. "\0" .. item.file_content_t, "hex");
					end

					item.needChange = true;

					self.output[#self.output+1] = item;
				else
					self.path = self.path ..'/'.. item.filename;
					local result = Files.Find({}, self.path, 0, nMaxFilesNum, filter);
					self:filesFind(result);

					self.path = string.gsub(self.path, ('/'..item.filename), '', 1);
				end
			end
		end
	end
end

function LocalService:LoadFiles(_worldDir, _curPath, _filter, _nMaxFileLevels, _nMaxFilesNum)
	filter 		   = _filter or "*.*";
	nMaxFileLevels = _nMaxFileLevels or 0;
	nMaxFilesNum   = _nMaxFilesNum or 500;

	LocalService.output   = {};
	LocalService.path     = _worldDir .. _curPath;
	LocalService.worldDir = _worldDir;

	if(_curPath ~= "") then
		LocalService.curPath = _curPath .. "/";
	end

	local result = Files.Find({}, LocalService.path, 0, nMaxFilesNum, filter);
	LocalService:filesFind(result);

	return LocalService.output;
end

function LocalService:update(_foldername, _path, _callback)
	LocalService:FileDownloader(_foldername, _path, _callback);
--	LocalService:getDataSourceContent(_foldername, _path, function(content, err)
--		local foldernameForLocal = EncodingC.Utf8ToDefault(_foldername);
--		local bashPath = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";
--
--		local file = ParaIO.open(bashPath .. _path, "w");
--		
--		LOG.std(nil,"debug","LocalService:update",content);
--		if(err == 200) then
--			if(not content) then
--				LocalService:getDataSourceContentWithRaw(_foldername, _path, function(data, err)
--					if(err == 200) then
--						content = data;
--						
--						file:write(content,#content);
--						file:close();
--
--						local returnData = {filename = _path, content = content};
--						_callback(true,returnData);
--					else
--						_callback(false,nil);
--					end
--				end);
--
--				return;
--			end
--
--			content = EncodingS.unbase64(content);
--			file:write(content,#content);
--			file:close();
--
--			local returnData = {filename = _path,content = content};
--			_callback(true,returnData);
--		else
--			_callback(false,nil);
--		end
--	end)
end

function LocalService:download(_foldername, _path, _callback)
	-- LOG.std(nil,"debug","_foldername",_foldername);
	-- LOG.std(nil,"debug","_path",_path);
	-- LOG.std(nil,"debug","_callback",_callback);

	LocalService:FileDownloader(_foldername, _path, _callback);
--	LocalService:getDataSourceContent(_foldername, _path, function(content, err)
--		if(err == 200) then
--			local path = {};
--			local returnData = {};
--
--			local bashPath = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";
--			local folderCreate = "";
--
--			for segmentation in string.gmatch(_path,"[^/]+") do
--				path[#path+1] = segmentation;
--			end
--
--			folderCreate = commonlib.copy(bashPath);
--
--			for i = 1, #path - 1, 1 do
--				folderCreate = folderCreate .. path[i] .. "/";
--				ParaIO.CreateDirectory(folderCreate);
--				--LOG.std(nil,"debug","folderCreate",folderCreate);
--			end
--
--			local file = ParaIO.open(bashPath .. _path, "w");
--
--			if(not content) then
--				LocalService:getDataSourceContentWithRaw(_foldername, _path, function(content, err)
--					if(err == 200) then
--						file:write(content,#content);
--						file:close();
--
--						returnData = {filename = _path, content = content};
--						_callback(true,returnData);
--					else
--						_callback(false,nil);
--					end
--				end);
--
--				return;
--			end
--
--			content = EncodingS.unbase64(content);
--			file:write(content,#content);
--			file:close();
--
--			returnData = {filename = _path, content = content};
--			_callback(true,returnData);
--		else
--			_callback(false,nil);
--		end
--	end);
end

function LocalService:downloadZip(_foldername, _commitId, _callback)
	local foldername = GitEncoding.base32(SyncMain.foldername.utf8);
	local url = "http://git.keepwork.com/" .. loginMain.dataSourceUsername .. "/" .. foldername .. "/repository/archive.zip?ref=" .. SyncMain.commitId;

	local Files = FileDownloader:new():Init(nil, url, "temp/archive.zip", function(bSuccess, downloadPath)
		if(bSuccess) then
			local remoteRevison;

			if(ParaAsset.OpenArchive(downloadPath, true)) then
				local zipParentDir = downloadPath:gsub("[^/\\]+$", "");

				--LOG.std(nil,"debug","zipParentDir",zipParentDir);

				local filesOut = {};
				commonlib.Files.Find(filesOut, "", 0, 10000, ":.", downloadPath); -- ":.", any regular expression after : is supported. `.` match to all strings. 

				--LOG.std(nil,"debug","filesOut", filesOut);

				local bashPath = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";
				local folderCreate = "";
				local rootFolder = filesOut[1].filename;

				--LOG.std(nil,"debug","rootFolder",rootFolder);

				for _, item in ipairs(filesOut) do
					if(item.filesize > 0) then
						local file = ParaIO.open(zipParentDir .. item.filename, "r")
						if(file:IsValid()) then
							local binData = file:GetText(0, -1);
							local pathArray = {};
							local path =  commonlib.copy(item.filename);

							path = path:sub(#rootFolder,#path);

							--LOG.std(nil,"debug","path",path);

							if(path == "/revision.xml") then
								remoteRevison = binData;
							end

							for segmentation in string.gmatch(path,"[^/]+") do
								if(segmentation ~= rootFolder) then
									pathArray[#pathArray + 1] = segmentation;
								end
							end

							folderCreate = commonlib.copy(bashPath);

							for i = 1, #pathArray - 1, 1 do
								folderCreate = folderCreate .. pathArray[i] .. "/";
								ParaIO.CreateDirectory(folderCreate);
								--LOG.std(nil,"debug","folderCreate",folderCreate);
							end

							local writeFile = ParaIO.open(bashPath .. path, "w");

							writeFile:write(binData,#binData);
							writeFile:close();

							file:close();
						end
					else
						-- this is a folder
					end
				end

				ParaAsset.CloseArchive(downloadPath);
			end

			_callback(true,remoteRevison);
		else
			_callback(false,nil);
		end
	end, "access plus 5 mins", true);
end

function LocalService:FileDownloader(_foldername, _path, _callback)
	local foldername = GitEncoding.base32(SyncMain.foldername.utf8);
	
	--LOG.std(nil,"debug","FileDownloader","FileDownloader");
	local url = "";
	local downloadDir = "";

	if(loginMain.dataSourceType == "github") then
	elseif(loginMain.dataSourceType == "gitlab") then
		url = loginMain.rawBaseUrl .. "/" .. loginMain.dataSourceUsername .. "/" .. foldername .. "/raw/" .. SyncMain.commitId .. "/" .. _path;
		downloadDir = SyncMain.worldDir.default .. _path;
	end

	--LOG.std(nil,"debug","FileDownloader-url",url);
	--LOG.std(nil,"debug","FileDownloader-downloadDir",downloadDir);

	local Files = FileDownloader:new():Init(_path, url, downloadDir, function(bSuccess, downloadPath)
		--LOG.std(nil,"debug","FileDownloader-downloadPath",downloadPath);

		local content = LocalService:getFileContent(downloadPath);

		if(bSuccess) then
			local returnData = {filename = _path, content = content};
			return _callback(bSuccess,returnData);
		else
			return _callback(bSuccess,nil);
		end
	end,"access plus 5 mins",true);
end

function LocalService:delete(_foldername, _filename, _callback)
	local bashPath = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";
	-- LOG.std(nil,"debug","ParaIO.DeleteFile",bashPath .. _filename);

	ParaIO.DeleteFile(bashPath .. _filename);
	_callback();
end

function LocalService:GetZipWorldSize(_zipWorldDir)
	return ParaIO.GetFileSize(_zipWorldDir);
end

function LocalService:GetZipRevision(_zipWorldDir)
	local zipParentDir = _zipWorldDir:gsub("[^/\\]+$", "");

	ParaAsset.OpenArchive(_zipWorldDir, true);	
	local output = {};

	Files.Find(output, "", 0, 500, ":revision.xml", _zipWorldDir);

	if(#output ~= 0) then
		--LOG.std(nil,"debug","output[1].filename",zipParentDir .. output[1].filename);
		local file = ParaIO.open(zipParentDir .. output[1].filename, "r");
		local binData;

		if(file:IsValid()) then
			binData = file:GetText(0, -1);
			--LOG.std(nil,"debug","binData",binData);
			file:close();
		end
	
		ParaAsset.CloseArchive(_zipWorldDir);
		return binData;
	else
		return 0;
	end
end

function LocalService:GetTag(_foldername)
	local filePath  = "worlds/DesignHouse/" .. _foldername .. "/tag.xml";

	local tag = ParaXML.LuaXML_ParseFile(filePath);
	tag = tag[1][1]['attr'];
	return tag;
end

function LocalService:getDataSourceContent(_foldername, _path, _callback)
	if(loginMain.dataSourceType == "github") then
		GithubService:getContent(_foldername, _path, _callback);
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:getContent(_path, _callback);
	end
end

function LocalService:getDataSourceContentWithRaw(_foldername, _path, _callback)
	if(loginMain.dataSourceType == "github") then
		GithubService:getContentWithRaw(_foldername, _path, _callback);
	elseif(loginMain.dataSourceType == "gitlab") then
		GitlabService:getContentWithRaw(_foldername, _path, _callback);
	end
end