--[[
Title: KeepworkService School
Author(s):  big
Date:  2020.7.7
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
------------------------------------------------------------
]]

-- api
local LessonOrganizationsApi = NPL.load("(gl)Mod/WorldShare/api/Lesson/LessonOrganizations.lua")
local KeepworkUsersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Users.lua")
local KeepworkRegionsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Regions.lua")
local KeepworkSchoolsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Schools.lua")
local LessonOrganizationActivateCodesApi = NPL.load("(gl)Mod/WorldShare/api/Lesson/LessonOrganizationActivateCodes.lua")

local KeepworkServiceSchoolAndOrg = NPL.export()

function KeepworkServiceSchoolAndOrg:GetUserAllOrgs(callback)
    if type(callback) ~= "function" then
        return false
    end

    LessonOrganizationsApi:GetUserAllOrgs(
        function(data, err)
            if err == 200 then
                if data and data.data and type(data.data.allOrgs) == 'table' then
                    callback(data.data.allOrgs)
                end
            end
        end,
        function()
            callback({})
        end
    )
end

function KeepworkServiceSchoolAndOrg:GetUserAllSchools(callback)
    if type(callback) ~= "function" then
        return false
    end

    KeepworkUsersApi:School(
        function(data, err)
            if err == 200 then
                callback(data)
            end
        end,
        function()
            callback({})
        end
    )
end

function KeepworkServiceSchoolAndOrg:GetMyAllOrgsAndSchools(callback)
    if type(callback) ~= "function" then
        return false
    end

    self:GetUserAllSchools(function(data)
        local schoolData = data

        self:GetUserAllOrgs(function(data)
            local orgData = data

            callback(schoolData, orgData)
        end)
    end)
end

function KeepworkServiceSchoolAndOrg:GetSchoolRegion(selectType, parentId, callback)
    if type(selectType) ~= "string" or not callback then
        return false
    end

    KeepworkRegionsApi:GetList(function(data)
        if type(data) ~= "table" then
            return false
        end

        if selectType == "province" then
            local provinceData = {}
            
            for key, item in ipairs(data) do
                if item and item.level == 2 then
                    provinceData[#provinceData + 1] = item
                end
            end

            callback(provinceData)
        end

        if selectType == "city" then
            local cityData = {}

            for key, item in ipairs(data) do
                if item and tonumber(item.parentId) == tonumber(parentId) then
                    cityData[#cityData + 1] = item
                end
            end

            callback(cityData)
        end

        if selectType == "area" then
            local areaData = {}

            for key, item in ipairs(data) do
                if item and tonumber(item.parentId) == tonumber(parentId) then
                    areaData[#areaData + 1] = item
                end
            end

            callback(areaData)
        end
    end)
end

function KeepworkServiceSchoolAndOrg:SearchSchool(id, kind, callback)
    KeepworkSchoolsApi:GetList(nil, id, kind, function(data, err)
        if data and data.rows then
            if type(callback) == "function" then
                callback(data.rows)
            end
        end
    end)
end

function KeepworkServiceSchoolAndOrg:SearchSchoolByName(name, regionId, kind, callback)
    KeepworkSchoolsApi:GetList(name, regionId, kind, function(data, err)
        if data and data.rows then
            if type(callback) == "function" then
                callback(data.rows)
            end
        end
    end)
end

-- return true or false
function KeepworkServiceSchoolAndOrg:ChangeSchool(schoolId, callback)
    KeepworkUsersApi:ChangeSchool(schoolId, function(data, err)
        if err == 200 then
            if type(callback) == "function" then
                callback(true)
            else
                callback(false)
            end
        end
    end)
end

-- return true or false
function KeepworkServiceSchoolAndOrg:JoinInstitute(code, callback)
    local realname = Mod.WorldShare.Store:Get("user/nickname")

    if not nickname or nickname == '' then
        realname = Mod.WorldShare.Store:Get("user/username")
    end

    code = string.gsub(code, " ", "")

    LessonOrganizationActivateCodesApi:Activate(
        code,
        realname,
        function(data, err)
            if err == 200 then
                if type(callback) == "function" then
                    callback(true)
                else
                    callback(false)
                end
            end
        end,
        function(data, err)
            if type(callback) == "function" then
                if data and type(data) == "table" then
                    callback(false, data, err)
                    return false
                end

                if data and type(data) == "string" then
                    local dataParams = {}
                    NPL.FromJson(data, dataParams)
                    callback(false, dataParams, err)
                    return false
                end

                callback(false)
            end
        end
    )
end

function KeepworkServiceSchoolAndOrg:SchoolRegister(schoolType, regionId, schoolName, callback)
    KeepworkUsersApi:SchoolRegister(
        schoolType,
        regionId,
        schoolName,
        function(data, err)
            if err ~= 200 then
                if type(callback) == "function" then
                    callback(false)
                end

                return false
            end


            if type(callback) == "function" then
                callback(true, data)
            end
        end,
        function(data, err)
            if type(callback) == "function" then
                callback(false, data)
            end
        end)
end