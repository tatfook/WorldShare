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

GithubService.githubApi = "https://api.github.com/";

function GithubService:GetUrl(_params,_callback)
	System.os.GetUrl(_params,function(err, msg, data)
		self:retry(err, msg, data, _params, _callback);
	end);
end

function GithubService:retry(_err, _msg, _data, _params, _callback)
	if(_err == 200 and _data ~= "") then
		_callback(_data);
	else
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

	self:GetUrl({url = _url,
			     json = true,
			     headers = {Authorization  = github_token["token_type"].." "..github_token["access_token"],
					        ["User-Agent"] = "npl"}
			    },_callback);
end

function GithubService:githubApiPut(_url,_params,_callback)
	local github_token = ShowLogin.github_token;

	self:GetUrl({
		method = "PUT",
		url    = _url,
		form   = _params,
		json = true,
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
	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/git/trees/master?recursive=1";

	self:githubApiGet(url, _callback);
end

function GithubService:getContent(_foldername, _fileName, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/"..ShowLogin.login.."/".._foldername.."/contents/".._fileName.."?access_token=" .. github_token["access_token"];

	self:githubApiGet(url,_callback);
end

function GithubService:update(_foldername, _fileName, _fileContent, _sha, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/contents/" .. _fileName .. "?access_token=" .. github_token["access_token"];

	params = {
		message = 'file update',
		content = _fileContent,
		sha     = _sha
	}
	
	_callback(true,{});

	-- self:githubApiPut(url,params,function(data)
	-- 	LOG.std(nil,"debug","GithubService:update",data);
	-- 	_callback(true,{});
	-- end);
end

function GithubService:upload(_foldername, _fileName, _fileContent, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername .. "/contents/" .. fileName .. "?access_token=" .. github_token["access_token"];

	params = {
		message = 'file update',
		content = _fileContent
	}

	self:githubApiPut(url,params,_callback);
end

function GithubService:delete(_foldername, _fileName, _sha, _callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "repos/" .. ShowLogin.login .. "/" .. _foldername  .. "/contents/" .. _fileName .. "?access_token=" .. github_token["access_token"];

	params = {
			message = 'file delete',
			sha = _sha
	}

	self:githubApiDelete(url,params,_callback);
end

function GithubService:getAllresponse(_callback)
	local github_token = ShowLogin.github_token;

	local url = self.githubApi .. "user/repos?access_token=" .. github_token["access_token"] .. "&type=owner";

    self:githubApiGet(url,_callback);
end