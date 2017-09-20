--[[
Title: HttpRequest
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua");
local HttpRequest = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
------------------------------------------------------------
]]

local HttpRequest = commonlib.gettable("Mod.WorldShare.service.HttpRequest");

HttpRequest.tryTimes = 0;

function HttpRequest:GetUrl(params, callback, noTryStatus)
	System.os.GetUrl(params, function(err, msg, data)
		-- debug code
		local debugUrl = "";

		if(type(params) == "string") then
			debugUrl = params;
		elseif(type(params) == "table") then
			debugUrl = params.url;
		end

		LOG.std("HttpRequest","debug","Request","Status Code: %s, URL: %s", err, debugUrl);
		-- debug code end

		-- no try status code, return directly
		if(type(noTryStatus) == "table") then
			for _, status in pairs(noTryStatus) do
				if(err == status and type(callback) == "function") then
					callback(data, err);
				end
			end
		elseif(type(noTryStatus) == "number") then
			if(err == noTryStatus and type(callback) == "function") then
				callback(data, err);
			end
		end

		-- success return
		if(err == 200 or err == 201 or err == 202 or err == 204) then
			if(type(callback) == "function") then
				callback(data, err);
			end

			return;
		else
			-- fail try
			HttpRequest:retry(err, msg, data, params, callback);
		end
	end);
end

function HttpRequest:retry(err, msg, data, params, callback)
	if(err == 422 or err == 404 or err == 409 or err == 401) then -- 失败时可直接返回的代码
		if(type(callback) == "function") then
			callback(data, err);
		end

		return;
	end

	if(HttpRequest.tryTimes >= 3) then
		if(type(callback) == "function") then
			callback(data, err);
		end

		HttpRequest.tryTimes = 0;

		return;
	end

	if(err == 200 or err == 201 or err == 204) then -- 成功时可直接返回的代码
		if(type(callback) == "function") then
			callback(data, err);
		end

		HttpRequest.tryTimes = 0;

		return
	else
		HttpRequest.tryTimes = HttpRequest.tryTimes + 1;
		
		commonlib.TimerManager.SetTimeout(function()
			HttpRequest:GetUrl(params, callback); -- 如果获取失败则递归获取数据
		end, 2100);
	end
end
