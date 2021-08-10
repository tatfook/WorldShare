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
local AccountingOrgApi = NPL.load("(gl)Mod/WorldShare/api/Accounting/Org.lua")
local KeepworkUsersApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Users.lua")
local KeepworkRegionsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Regions.lua")
local KeepworkSchoolsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Schools.lua")
local AccountingOrgActivateCodeApi = NPL.load("(gl)Mod/WorldShare/api/Accounting/OrgActivateCode.lua")

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')

-- libs
local KeepWorkItemManager = NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua')

-- databases
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')

local KeepworkServiceSchoolAndOrg = NPL.export()

function KeepworkServiceSchoolAndOrg:GetUserAllOrgs(callback)
    if type(callback) ~= "function" then
        return false
    end

    AccountingOrgApi:GetUserAllOrgs(
        nil,
        true,
        function(data, err)
            if err == 200 then
                if data and data.data and type(data.data) == 'table' then
                    callback(data.data)
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

    local function Handle()
        if type(self.schoolData) ~= "table" then
            return false
        end

        if selectType == "province" then
            local provinceData = {}
            
            for key, item in ipairs(self.schoolData) do
                if item and item.level == 2 then
                    provinceData[#provinceData + 1] = item
                end
            end

            callback(provinceData)
        end

        if selectType == "city" then
            local cityData = {}

            for key, item in ipairs(self.schoolData) do
                if item and tonumber(item.parentId) == tonumber(parentId) then
                    cityData[#cityData + 1] = item
                end
            end

            callback(cityData)
        end

        if selectType == "area" then
            local areaData = {}

            for key, item in ipairs(self.schoolData) do
                if item and tonumber(item.parentId) == tonumber(parentId) then
                    areaData[#areaData + 1] = item
                end
            end

            callback(areaData)
        end
    end

    if self.schoolData then
        Handle()
        return
    end

    KeepworkRegionsApi:GetList(function(data)
        if not self.schoolData then
            self.schoolData = data
        end

        Handle()
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

function KeepworkServiceSchoolAndOrg:SearchSchoolByName(name, id, kind, callback)
    KeepworkSchoolsApi:GetList(name, id, kind, function(data, err)
        if data and data.rows then
            if callback and type(callback) == "function" then
                callback(data.rows)
            end
        end
    end)
end

function KeepworkServiceSchoolAndOrg:SearchSchoolBySchoolId(id, callback)
    KeepworkSchoolsApi:GetSchoolById(id, function(data, err)
        if data and data.rows then
            if callback and type(callback) == "function" then
                callback(data.rows)
            end
        end   
    end)
end

-- join school service
function KeepworkServiceSchoolAndOrg:ChangeSchool(schoolId, callback)
    KeepworkUsersApi:ChangeSchool(
        schoolId,
        function(data, err)
            Mod.WorldShare.Store:Set('user/hasJoinedSchool', true)

            SessionsData:SetAnyonymousInfo('lastSchoolId', schoolId)

            if callback and type(callback) == "function" then
                -- update field 
                KeepworkServiceSession:Profile(function(response, err)
                    local isVipSchool = false

                    if response and response.school and response.school.isVip == 1 then
                        isVipSchool = true
                    end

                    local SetIsVipSchool = Mod.WorldShare.Store:Action("user/SetIsVipSchool")
                    SetIsVipSchool(isVipSchool)

                    -- 1. for 柴桑小学 2. updated libs info
                    KeepWorkItemManager.school = response.school

                    callback(true)
                end)
            end
        end,
        function()
            if callback and type(callback) == 'function' then
                callback(false)
            end
        end
    )
end

-- return true or false
function KeepworkServiceSchoolAndOrg:JoinInstitute(code, callback)
    local realname = Mod.WorldShare.Store:Get("user/nickname")

    if not nickname or nickname == '' then
        realname = Mod.WorldShare.Store:Get("user/username")
    end

    code = Mod.WorldShare.Utils.RemoveLineEnding(code)

    AccountingOrgActivateCodeApi:Activate(
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

function KeepworkServiceSchoolAndOrg:GetMyClassList(schoolId, callback)
    KeepworkSchoolsApi:Classes(schoolId, callback, callback)
end