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

function MySchool:Show(callback)
    self.hasJoined = nil
    self.schoolData = {}
    self.orgData = {}
    self.callback = callback
    self.searchText = ""

    Mod.WorldShare.MsgBox:Show(L"请稍后...", nil, nil, nil, nil, 6)

    local params = Mod.WorldShare.Utils.ShowWindow(600, 380, "(ws)Theme/MySchool/MySchool.html", "Mod.WorldShare.MySchool")

    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        Mod.WorldShare.MsgBox:Close()

        self.hasJoined = false

        if type(orgData) == "table" and #orgData > 0 then
            self.orgData = orgData
            self.hasJoined = true
        end

        params._page:Refresh(0.01)
    end)

    -- KeepworkServiceSchoolAndOrg:GetMyAllOrgsAndSchools(function(schoolData, orgData)
    --     Mod.WorldShare.MsgBox:Close()

    --     local hasJoinedSchool = false
    --     local hasJoinedOrg = false

    --     if type(schoolData) == "table" and schoolData.regionId then
    --         hasJoinedSchool = true
    --         self.schoolData= schoolData
    --     end

    --     if type(orgData) == "table" and #orgData > 0 then
    --         hasJoinedOrg = true
    --         self.orgData = orgData
    --     end

    --     if hasJoinedSchool or hasJoinedOrg then
    --         self.hasJoined = true
    --     else
    --         self.hasJoined = false
    --     end

    --     params._page:Refresh(0.01)
    -- end)
end

function MySchool:ShowJoinSchool(callback)
    self.provinces = {
        {
            text = L"省",
            value = 0,
            selected = true,
        }
    }

    self.cities = {
        {
            text = L"市",
            value = 0,
            selected = true,
        }
    }

    self.areas = {
        {
            text = L"区",
            value = 0,
            selected = true,
        }
    }

    self.kinds = {
        {
            text = L"学校类型",
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
        },
        {
            text = L"综合",
            value = L"综合",
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
    self.joinSchoolCallback = callback

    local params1 = Mod.WorldShare.Utils.ShowWindow(600, 420, "(ws)Theme/MySchool/JoinSchool.html", "Mod.WorldShare.JoinSchool", nil, nil, nil, false, 1)
    local params2 = Mod.WorldShare.Utils.ShowWindow(380, 100, "(ws)Theme/MySchool/JoinSchoolResult.html", "Mod.WorldShare.JoinSchoolResult", nil, 20, nil, false, 2)

    self:GetProvinces(function(data)
        if type(data) ~= "table" then
            return false
        end

        self.provinces = data

        self:RefreshJoinSchool()
    end)

    params1._page.OnClose = function()
        if params2._page then
            params2._page:CloseWindow()
        end
    end
end

function MySchool:RefreshJoinSchool()
    local JoinSchoolPage = Mod.WorldShare.Store:Get("page/Mod.WorldShare.JoinSchool")

    if JoinSchoolPage then
        JoinSchoolPage:Refresh(0.01)

        local JoinSchoolResultPage = Mod.WorldShare.Store:Get("page/Mod.WorldShare.JoinSchoolResult")

        if JoinSchoolResultPage then
            JoinSchoolResultPage:Refresh(0.01)
        end
    end
end

function MySchool:ShowJoinInstitute()
    local params = Mod.WorldShare.Utils.ShowWindow(600, 200, "(ws)Theme/MySchool/JoinInstitute.html", "Mod.WorldShare.JoinInstitute")
end

function MySchool:ShowRecordSchool()
    self.provinces = {
        {
            text = L"省",
            value = 0,
            selected = true,
        }
    }

    self.cities = {
        {
            text = L"市",
            value = 0,
            selected = true,
        }
    }

    self.areas = {
        {
            text = L"区",
            value = 0,
            selected = true,
        }
    }

    self.kinds = {
        {
            text = L"学校类型",
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
        },
        {
            text = L"综合",
            value = L"综合",
        }
    }

    self.curId = 0
    self.kind = nil

    local params = Mod.WorldShare.Utils.ShowWindow(600, 300, "(ws)Theme/MySchool/RecordSchool.html", "Mod.WorldShare.RecordSchool")

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
                text = L"省",
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
                text = L"市",
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
                text = L"区",
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

        if callback and type(callback) == "function" then
            callback(self.result)
        end
    end)
end

function MySchool:GetSearchSchoolResultByName(name, callback)
    if not name or type(name) ~= "string" or #name == 0 then
        if callback and type(callback) == "function" then
            self.result = {
                {
                    text = L"在这里显示筛选的结果",
                    value = 0,
                    selected = true,
                },
            }

            callback()
        end

        return false
    end

    KeepworkServiceSchoolAndOrg:SearchSchoolByName(name, self.curId, self.kind, function(data)
        self.result = data

        for key, item in ipairs(self.result) do
            item.text = item.name or ""
            item.value = item.id
        end

        if callback and type(callback) == "function" then
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