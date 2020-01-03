--[[
Title: GithubService
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/GithubService.lua");
local GithubService = commonlib.gettable("Mod.WorldShare.service.GithubService");
------------------------------------------------------------
]]

NPL.load("(gl)Mod/WorldShare/login.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua");
NPL.load("(gl)Mod/WorldShare/services/HttpRequest.lua");

local login         = commonlib.gettable("Mod.WorldShare.login");
local Encoding      = commonlib.gettable("System.Encoding");
local GitEncoding   = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local HttpRequest   = commonlib.gettable("Mod.WorldShare.service.HttpRequest");


local GithubService = commonlib.gettable("Mod.WorldShare.service.GithubService");

function GithubService:apiGet(_url, _callback)
	local github_token = login.github_token;

	--LOG.std(nil,"debug","url",url);
	HttpRequest:GetUrl({
		url     = login.apiBaseUrl .. "/" .. _url,
		json    = true,
		headers = {
			Authorization  = github_token["token_type"].." "..github_token["access_token"],
			["User-Agent"] = "npl",
		},
	},_callback);
end

function GithubService:apiPost(_url, _params, _callback)
	local github_token = login.github_token;

	HttpRequest:GetUrl({
		url       = login.apiBaseUrl .. "/" .. _url,
		headers   = {
			Authorization    = github_token["token_type"].." "..github_token["access_token"],
			["User-Agent"]   = "npl",
			["content-type"] = "application/json",
		},
		postfields = _params,
	},_callback);
end

function GithubService:apiPut(_url, _params, _callback)
	local github_token = login.github_token;

	HttpRequest:GetUrl({
		method     = "PUT",
		url        = login.apiBaseUrl .. "/" .._url,
	  	headers    = {
		  				 Authorization    = github_token["token_type"].." "..github_token["access_token"],
					     ["User-Agent"]   = "npl",
					     ["content-type"] = "application/json"
				     },
		postfields = _params
	},_callback);
end

function GithubService:apiDelete(_url, _params, _callback)
	local github_token = login.dataSourceToken;
	
	--LOG.std(nil,"debug","GithubService:githubApiDelete",github_token);
	HttpRequest:GetUrl({
		method     = "DELETE",
		url        = login.apiBaseUrl .. "/" .._url,
	  	headers    = {
	  				  Authorization    = github_token["token_type"].." "..github_token["access_token"],
					  ["User-Agent"]   = "npl",
					  ["content-type"] = "application/json"
				  	 },
		postfields = _params
	},_callback);
end

function GithubService:getTree(_foldername, _callback)
	_foldername = GitEncoding.Base32(_foldername);
	--LOG.std(nil,"debug","getFileShaList",_foldername);
	
	local url = "repos/" .. login.login .. "/" .. _foldername .. "/git/trees/master?recursive=1";

	--LOG.std(nil,"debug","url",url);
	self:githubApiGet(url, _callback);
end

function GithubService:getContent(_foldername, _fileName, _callback)
	_foldername = GitEncoding.Base32(_foldername);

	local github_token = login.github_token;

	local url = "repos/"..login.login.."/".._foldername.."/contents/".._fileName.."?access_token=" .. github_token["access_token"];

	self:apiGet(url,_callback);
end

function GithubService:create(_foldername, _callback)
	_foldername = GitEncoding.Base32(_foldername);

	local url = "/user/repos";

	params = '{"name": "' .. _foldername .. '"}';

	self:apiPost(url, params, _callback);
end

function GithubService:deleteResp(_foldername, authToken, _callback)
	local _foldername  = GitEncoding.Base32(_foldername);

	local url = "repos/" .. login.dataSourceUsername .. "/" .. _foldername;

	HttpRequest:GetUrl({
		method  = "DELETE",
		url     = url,
	  	headers = {
	  		Authorization  = "Bearer " .. authToken,
			["User-Agent"] = "npl",
		}
	},_callback);
end

function GithubService:update(_foldername, _fileName, _fileContent, _sha, _callback)
	_foldername = GitEncoding.Base32(_foldername);

	local github_token = login.dataSourceToken;

	--LOG.std(nil,"debug","GithubService:update",{_foldername, _fileName, Encoding.base64(_fileContent), _sha});
	local url = "repos/" .. login.login .. "/" .. _foldername .. "/contents/" .. _fileName .. "?access_token=" .. github_token["access_token"];

	params = '{"message":"File update","content":"' .. Encoding.base64(_fileContent) .. '","sha":"' .. _sha .. '"}';
	
	--_callback(true,{});

	self:githubApiPut(url,params,function(data)
		--LOG.std(nil,"debug","GithubService:update",data);
		_callback(true,{});
	end);
end

function GithubService:upload(foldername, fileName, fileContent, callback)
	foldername = GitEncoding.Base32(foldername);

	local github_token = login.dataSourceToken;

	local url = "repos/" .. login.dataSourceUsername .. "/" .. foldername .. "/contents/" .. fileName .. "?access_token=" .. github_token["access_token"];

	fileContent = Encoding.base64(fileContent);

	params = '{"message": "File upload","content": "'.. _fileContent ..'"}';

	self:apiPut(url,params,function(data)
		if(type(callback) == "function") then
			callback(true,{});
		end
	end);
end

function GithubService:delete(_foldername, _fileName, _sha, _callback)
	_foldername = GitEncoding.Base32(_foldername);
	
	local github_token = login.dataSourceToken;

	local url = "repos/" .. login.login .. "/" .. _foldername  .. "/contents/" .. _fileName .. "?access_token=" .. github_token["access_token"];

	params = '{"message":"File Delete","sha":"' .. _sha .. '"}';

	-- _callback(true,{});
	
	self:githubApiDelete(url,params,function(data)
		--LOG.std(nil,"debug","GithubService:delete",data);
		_callback(true,{});
	end);
end

function GithubService:getAllresponse(_callback)
	local github_token = login.dataSourceToken;

	local url = "user/repos?access_token=" .. github_token["access_token"] .. "&type=owner";

    self:githubApiGet(url,_callback);
end

function GithubService:getWorldRevison()
	local contentUrl = format("%s/%s/%s/master/revision.xml", UserConsole.rawBaseUrl, UserConsole.dataSourceUsername, foldername)
end