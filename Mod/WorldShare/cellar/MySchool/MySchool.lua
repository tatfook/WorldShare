--[[
Title: my school page
Author(s):  big
Date: 2019.09.11
Desc: 
use the lib:
------------------------------------------------------------
local MySchool = NPL.load("(gl)Mod/WorldShare/cellar/MySchool/MySchool.lua")
------------------------------------------------------------
]]

-- service
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")

local MySchool = NPL.export()

function MySchool:Show()
    self.hasJoined = nil
    self.schoolData = {}
    self.orgData = {}

    Mod.WorldShare.MsgBox:Show(L"请稍后...", nil, nil, nil, nil, 6)
    local params = Mod.WorldShare.Utils.ShowWindow(600, 330, "Mod/WorldShare/cellar/MySchool/MySchool.html", "MySchool")

    KeepworkServiceSchoolAndOrg:GetMyAllOrgsAndSchools(function(schoolData, orgData)
        Mod.WorldShare.MsgBox:Close()

        local hasJoinedSchool = false
        local hasJoinedOrg = false

        if type(schoolData) == "table" and schoolData.regionId then
            hasJoinedSchool = true
            self.schoolData= schoolData
        end

        if type(orgData) == "table" and #orgData > 0 then
            hasJoinedOrg = true
            self.orgData = orgData
        end

        if hasJoinedSchool or hasJoinedOrg then
            self.hasJoined = true
        else
            self.hasJoined = false
        end

        params._page:Refresh(0.01)
    end)
end

function MySchool:ShowJoinSchool()
    self.provinces = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        }
    }

    self.cities = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        }
    }

    self.areas = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        }
    }

    self.kinds = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        },
        {
            text = L"小学",
            value = L"小学"
        },
        {
            text = L"中学",
            value = L"中学"
        },
        {
            text = L"大学",
            value = L"大学",
        }
    }

    self.result = {
        {
            text = L"在这里显示筛选的结果",
            value = 0,
            selected = true,
        },
    }

    self.curId = 0
    self.kind = nil

    local params = Mod.WorldShare.Utils.ShowWindow(600, 330, "Mod/WorldShare/cellar/MySchool/JoinSchool.html", "JoinSchool")

    self:GetProvinces(function(data)
        if type(data) ~= "table" then
            return false
        end

        self.provinces = data

        params._page:Refresh(0.01)
    end)
end

function MySchool:ShowJoinInstitute()
    local params = Mod.WorldShare.Utils.ShowWindow(600, 200, "Mod/WorldShare/cellar/MySchool/JoinInstitute.html", "JoinInstitute")
end

function MySchool:ShowRecordSchool()
    self.provinces = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        }
    }

    self.cities = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        }
    }

    self.areas = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        }
    }

    self.kinds = {
        {
            text = L"请选择",
            value = 0,
            selected = true,
        },
        {
            text = L"小学",
            value = L"小学"
        },
        {
            text = L"中学",
            value = L"中学"
        },
        {
            text = L"大学",
            value = L"大学",
        }
    }

    self.curId = 0
    self.kind = nil

    local params = Mod.WorldShare.Utils.ShowWindow(600, 300, "Mod/WorldShare/cellar/MySchool/RecordSchool.html", "RecordSchool")

    self:GetProvinces(function(data)
        if type(data) ~= "table" then
            return false
        end

        self.provinces = data

        params._page:Refresh(0.01)
    end)
end

function MySchool:GetProvinces(callback)
    KeepworkServiceSchoolAndOrg:GetSchoolRegion("province", nil, function(data)
        if type(data) ~= "table" then
            return false
        end

        if type(callback) == "function" then
            for key, item in ipairs(data) do
                item.text = item.name
                item.value = item.id
            end

            data[#data + 1] = {
                text = L"请选择",
                value = 0,
                selected = true,
            }

            callback(data)
        end
    end)
end

function MySchool:GetCities(id, callback)
    KeepworkServiceSchoolAndOrg:GetSchoolRegion("city", id, function(data)
        if type(data) ~= "table" then
            return false
        end

        if type(callback) == "function" then
            for key, item in ipairs(data) do
                item.text = item.name
                item.value = item.id
            end

            data[#data + 1] = {
                text = L"请选择",
                value = 0,
                selected = true,
            }

            callback(data)
        end
    end)
end

function MySchool:GetAreas(id, callback)
    KeepworkServiceSchoolAndOrg:GetSchoolRegion('area', id, function(data)
        if type(data) ~= "table" then
            return false
        end

        if type(callback) == "function" then
            for key, item in ipairs(data) do
                item.text = item.name
                item.value = item.id
            end

            data[#data + 1] = {
                text = L"请选择",
                value = 0,
                selected = true,
            }

            callback(data)
        end
    end)
end

function MySchool:GetSearchSchoolResult(id, kind, callback)
    KeepworkServiceSchoolAndOrg:SearchSchool(id, kind, function(data)
        self.result = data

        for key, item in ipairs(self.result) do
            item.text = item.name
            item.value = item.id
        end

        if type(callback) == "function" then
            callback(self.result)
        end
    end)
end

function MySchool:ChangeSchool(schoolId, callback)
    KeepworkServiceSchoolAndOrg:ChangeSchool(schoolId, callback)
end

function MySchool:JoinInstitute(code, callback)
    KeepworkServiceSchoolAndOrg:JoinInstitute(code, callback)
end

function MySchool:RecordSchool(schoolType, regionId, schoolName, callback)
    KeepworkServiceSchoolAndOrg:SchoolRegister(schoolType, regionId, schoolName, callback)
end