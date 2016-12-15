--[[
Title: GithubService
Author(s):  big
Date:  2016.12.10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/GithubService.lua");
local GithubService = commonlib.gettable("Mod.WorldShare.GithubService");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/ShowLogin.lua");

local GithubService = commonlib.gettable("Mod.WorldShare.GithubService");
local ShowLogin     = commonlib.gettable("Mod.WorldShare.ShowLogin");

GithubService.githubApi      = "https://api.github.com/";
GithubService.githubTryTimes = 0; 

function GithubService:GetUrl(_params,_callback)
	System.os.GetUrl(_params,function(err, msg, data)
		self:retry(err, msg, data, _params, _callback);
	end);
end

function GithubService:retry(_err, _msg, _data, _params, _callback)
	LOG.std(nil,"debug","GithubService:retry",{_err, _data});

	if(_err == 422 or _err == 404 or _err == 409) then
		_callback(_err);
		return;
	end

	if(self.githubTryTimes >= 3) then
		_callback(_err);
		self.githubTryTimes = 0;
		return;
	end

	if(_err == 200 or
	   _err == 201 and _data ~= "") then

		_callback(_data);
		self.githubTryTimes = 0;
	else
		self.githubTryTimes = self.githubTryTimes + 1;
		-- 如果获取失败则递归获取数据
		commonlib.TimerManager.SetTimeout(function()
			self:GetUrl(_params, _callback);
		end, 2100);
	end
end

function GithubService:githubGet(_url,_callback)
	self:GetUrl(_url, _callback);
end

function GithubService:githubApiGet(_url, _callback)
	local github_token = ShowLogin.github_token;
	--LOG.std(nil,"debug","url",url);
	self:GetUrl({url = _url,
			     json = true,
			     headers = {Authorization  = github_token["token_type"].." "..github_token["access_token"],
					        ["User-Agent"] = "npl"}
			    },_callback);
end

function GithubService:githubApiPost(_url, _params, _callback)
	local github_token = ShowLogin.github_token;

	self:GetUrl({
					url       = _url,
				    headers   = {
		     			Authorization    = github_token["token_type"].." "..github_token["access_token"],
				        ["User-Agent"]   = "npl",
				        ["content-type"] = "application/json"
				    },
				    postfields = _params
			    },
			     _callback);
end

function GithubService:githubApiPut(_url,_params,_callback)
	local github_token = ShowLogin.github_token;

	self:GetUrl({
		method  = "PUT",
		url     = _url,
		form    = _params,
	  	headers = {Authorization  = github_token["token_type"].." "..github_token["access_token"],
				   ["User-Agent"] = "npl"}
	},_callback);
end

function GithubService:githubApiDelete(_url,_params,_callback)
	local github_token = ShowLogin.github_token;
	
	System.os.GetUrl({
		method  = "DELETE",
		url     = _url,
		form    = _params,
		json    = true,
	  	headers = {Authorization  = github_token["token_type"].." "..github_token["access_token"],
				   ["User-Agent"] = "npl"}
	},_callback);
end

function GithubService:getFileShaList(_foldername, _callback)
	LOG.std(nil,"debug","getFileShaList","getFileShaList")
	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/git/trees/master?recursive=1";

	self:githubApiGet(url, _callback);
end

function GithubService:getContent(_foldername, _fileName, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/"..ShowLogin.login.."/".._foldername.."/contents/".._fileName.."?access_token=" .. github_token["access_token"];

	self:githubApiGet(url,_callback);
end

function GithubService:create(_foldername, _callback)
	local url = self.githubApi .. "user/repos";

	params = '{"name": "' .. _foldername .. '"}';

	self:githubApiPost(url, params, _callback);
end

function GithubService:update(_foldername, _fileName, _fileContent, _sha, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/contents/" .. _fileName .. "?access_token=" .. github_token["access_token"];

	params = {
		message = 'File update',
		content = _fileContent,
		sha     = _sha
	}
	
	--_callback(true,{});

	self:githubApiPut(url,params,function(data)
		LOG.std(nil,"debug","GithubService:update",data);
		_callback(true,{});
	end);
end

function GithubService:upload(_foldername, _fileName, _fileContent, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/contents/" .. _fileName .. "?access_token=" .. github_token["access_token"];

	params = {
		message = 'File upload',
		content = _fileContent
	}

	_callback(true,{});

	-- self:githubApiPut(url,params,function(data)
	-- 	LOG.std(nil,"debug","GithubService:upload",data);
	-- 	_callback(true,{});
	-- end);
end

function GithubService:delete(_foldername, _fileName, _sha, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername  .. "/contents/" .. _fileName .. "?access_token=" .. github_token["access_token"];

	params = {
			message = 'File delete',
			sha = _sha
	}

	_callback(true,{});
	
	-- self:githubApiDelete(url,params,function(data)
	-- 	LOG.std(nil,"debug","GithubService:delete",data);
	-- end);
end

function GithubService:getAllresponse(_callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "user/repos?access_token=" .. github_token["access_token"] .. "&type=owner";

    self:githubApiGet(url,_callback);
end