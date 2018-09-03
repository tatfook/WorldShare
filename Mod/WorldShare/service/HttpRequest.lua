--[[
Title: HttpRequest
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
local HttpRequest = NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")
------------------------------------------------------------
]]
local HttpRequest = NPL.export()

HttpRequest.tryTimes = 1
HttpRequest.maxTryTimes = 3
HttpRequest.successCode = {200, 201, 202, 204}

function HttpRequest:GetUrl(params, callback, noTryStatus)
    System.os.GetUrl(
        params,
        function(err, msg, data)
            ---- debug code ----
            local debugUrl = type(params) == "string" and params or params.url
            local method = type(params) == 'table' and params.method and params.method or 'GET'

            LOG.std("HttpRequest", "debug", "Request", "Status Code: %s, Method: %s, URL: %s", err, method, debugUrl)
            ---- debug code ----

            -- no try status code, return directly
            if (type(noTryStatus) == "table") then
                for _, status in pairs(noTryStatus) do
                    if (err == status and type(callback) == "function") then
                        callback(data, err)
                    end
                end
            elseif (type(noTryStatus) == "number") then
                if (err == noTryStatus and type(callback) == "function") then
                    callback(data, err)
                end
            end

            if (err == 422 or err == 404 or err == 409 or err == 401) then -- 失败时可直接返回的代码
                if (type(callback) == "function") then
                    callback(data, err)
                end

                HttpRequest.tryTimes = 1
                return
            end

            -- success return
            for _, code in pairs(HttpRequest.successCode) do
                if (err == code and type(callback) == "function") then
                    callback(data, err)

                    HttpRequest.tryTimes = 1
                    return
                end
            end

            -- fail try
            HttpRequest:retry(err, msg, data, params, callback)
        end
    )
end

function HttpRequest:retry(err, msg, data, params, callback)
    -- beyond the max try times, must be return
    if (HttpRequest.tryTimes >= HttpRequest.maxTryTimes) then
        if (type(callback) == "function") then
            callback(data, err)
        end

        HttpRequest.tryTimes = 1
        return
    end

    -- continue try
    HttpRequest.tryTimes = HttpRequest.tryTimes + 1

    commonlib.TimerManager.SetTimeout(
        function()
            HttpRequest:GetUrl(params, callback)
        end,
        2100
    )
end
