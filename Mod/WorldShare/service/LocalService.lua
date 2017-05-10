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
NPL.load("(gl)Mod/WorldShare/login.lua");
NPL.load("(gl)Mod/WorldShare/service/GitlabService.lua");
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua");
NPL.load("(gl)Mod/WorldShare/SyncMain.lua");

local GitEncoding   = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local GitlabService = commonlib.gettable("Mod.WorldShare.service.GitlabService");
local GithubService = commonlib.gettable("Mod.WorldShare.service.GithubService");
local EncodingC     = commonlib.gettable("commonlib.Encoding");
local EncodingS     = commonlib.gettable("System.Encoding");
local Files         = commonlib.gettable("commonlib.Files");
local login         = commonlib.gettable("Mod.WorldShare.login");
local SyncMain      = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

local LocalService  = commonlib.gettable("Mod.WorldShare.service.LocalService");

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
		for i = 1, #_result do
			local item = _result[i];

			if(not string.match(item.filename, '/')) then
				if(item.filesize ~= 0) then
					-- path = string.gsub(path, 'MyWorld/', 'MyWorld', 1);
					item.file_path = self.path..'/'..item.filename;

					-- string.gsub(path..item.filename, '//', '/', 1);
					item.filename = EncodingC.DefaultToUtf8(string.gsub(item.file_path, self.worldDir..'/', '', 1));
					item.id = item.filename;
					item.file_content_t = self:getFileContent(item.file_path);
					item.file_content = EncodingS.base64(item.file_content_t);
					item.sha1 = EncodingS.sha1("blob " .. item.filesize .. "\0" .. item.file_content_t, "hex");
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

function LocalService:LoadFiles(_worldDir,_curPath,_filter,_nMaxFileLevels,_nMaxFilesNum)
	filter 		   = _filter or "*.*";
	nMaxFileLevels = _nMaxFileLevels or 0;
	nMaxFilesNum   = _nMaxFilesNum or 500;

	LocalService.output   = {};
	LocalService.path     = _worldDir.._curPath;
	LocalService.worldDir = _worldDir;

	if(_curPath ~= "") then
		LocalService.curPath = _curPath.."/";
	end

	local result = Files.Find({}, LocalService.path, 0, nMaxFilesNum, filter);

	LocalService:filesFind(result);

	local revision;
	local hasRevision;

	for key, value in ipairs(LocalService.output) do
		--LOG.std(nil,"debug","LocalService:LoadFiles-LocalService.output",value.filename);
		if(value.filename == "revision.xml") then
			revision    = value;
			hasRevision = true;
		end
	end

	--LOG.std(nil,"debug","LocalService:LoadFiles-revision",revision);
	--LOG.std(nil,"debug","LocalService:LoadFiles-hasRevision",hasRevision);

	local sortOutPut = {};

	if(hasRevision) then
		for key, value in ipairs(LocalService.output) do
			--LOG.std(nil, "debug", "LocalService:LoadFiles-LocalService.output", value.filename);
			if(value.filename ~= "revision.xml") then
				sortOutPut[#sortOutPut + 1] = value;
			end
		end

		sortOutPut[#sortOutPut + 1] = revision;
	end

	return sortOutPut;
end

function LocalService:update(_foldername, _path, _callback)
	LocalService:getDataSourceContent(_foldername, _path, function(content, err)
		--local foldernameForLocal = EncodingC.Utf8ToDefault(_foldername);
		local bashPath = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";

		local file = ParaIO.open(bashPath .. _path, "w");
		
		LOG.std(nil,"debug","LocalService:update",content);
		if(err == 200) then
			if(not content) then
				LocalService:getDataSourceContentWithRaw(_foldername, _path, function(data, err)
					if(err == 200) then
						content = data;

						file:write(content,#content);
						file:close();

						local returnData = {filename = _path, content = content};
						_callback(true,returnData);
					else
						_callback(false,nil);
					end
				end);

				return;
			end

			content = EncodingS.unbase64(content);
			file:write(content,#content);
			file:close();

			local returnData = {filename = _path,content = content};
			_callback(true,returnData);
		else
			_callback(false,nil);
		end
	end)	
end

function LocalService:download(_foldername, _path, _callback)
	-- LOG.std(nil,"debug","_foldername",_foldername);
	-- LOG.std(nil,"debug","_path",_path);
	-- LOG.std(nil,"debug","_callback",_callback);

	LocalService:getDataSourceContent(_foldername, _path, function(content, err)
		if(err == 200) then
			local path = {};
			local returnData = {};

			local bashPath = "worlds/DesignHouse/" .. SyncMain.foldername.default .. "/";
			local folderCreate = "";

			for segmentation in string.gmatch(_path,"[^/]+") do
				path[#path+1] = segmentation;
			end

			folderCreate = commonlib.copy(bashPath);

			for i = 1, #path - 1, 1 do
				folderCreate = folderCreate .. path[i] .. "/";
				ParaIO.CreateDirectory(folderCreate);
				--LOG.std(nil,"debug","folderCreate",folderCreate);
			end

			local file = ParaIO.open(bashPath .. _path, "w");

			if(not content) then
				LocalService:getDataSourceContentWithRaw(_foldername, _path, function(content, err)
					if(err == 200) then
						file:write(content,#content);
						file:close();

						returnData = {filename = _path, content = content};
						_callback(true,returnData);
					else
						_callback(false,nil);
					end
				end);

				return;
			end

			content = EncodingS.unbase64(content);
			file:write(content,#content);
			file:close();

			returnData = {filename = _path, content = content};
			_callback(true,returnData);
		else
			_callback(false,nil);
		end
	end);
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

	LOG.std(nil,"debug","output[1].filename",zipParentDir .. output[1].filename);
	local file = ParaIO.open(zipParentDir .. output[1].filename, "r");
	local binData;

	if(file:IsValid()) then
		binData = file:GetText(0, -1);
		LOG.std(nil,"debug","binData",binData);
		file:close();
	end
	
	return binData;
end

function LocalService:GetTag(_foldername)
	local filePath  = "worlds/DesignHouse/" .. _foldername .. "/tag.xml";

	local tag = ParaXML.LuaXML_ParseFile(filePath);
	tag = tag[1][1]['attr'];
	return tag;
end

function LocalService:getDataSourceContent(_foldername, _path, _callback)
	if(login.dataSourceType == "github") then
		GithubService:getContent(_foldername, _path, _callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:getContent(_path, _callback);
	end
end

function LocalService:getDataSourceContentWithRaw(_foldername, _path, _callback)
	if(login.dataSourceType == "github") then
		GithubService:getContentWithRaw(_foldername, _path, _callback);
	elseif(login.dataSourceType == "gitlab") then
		GitlabService:getContentWithRaw(_foldername, _path, _callback);
	end
end