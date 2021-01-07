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
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

local MySchool = NPL.export()

function MySchool:Show(callback)
    self.hasJoined = false
    self.hasSchoolJoined = false
    self.schoolData = {}
    self.orgData = {}
    self.allData = {}
    self.callback = callback
    self.searchText = ""

    Mod.WorldShare.MsgBox:Show(L"请稍候...", nil, nil, nil, nil, 6)

    local params = Mod.WorldShare.Utils.ShowWindow(600, 380, "(ws)Theme/MySchool/MySchool.html", "Mod.WorldShare.MySchool")

    KeepworkServiceSchoolAndOrg:GetUserAllOrgs(function(orgData)
        Mod.WorldShare.MsgBox:Close()

        self.hasJoined = false
        if type(orgData) == "table" and #orgData > 0 then
            self.hasJoined = true
        
            for key, item in ipairs(orgData) do
                if item and not item.fullname then
                    item.fullname = ''
                end
            end

            for key, item in ipairs(orgData) do
                if item and item.type == 4 then
                    self.hasSchoolJoined = true
                    break
                end
            end
        end

        for key, item in ipairs(orgData) do
            if item.type ~= 4 then
                -- org data
                self.orgData[#self.orgData + 1] = item
            end

            if item.type == 4 then
                -- school data
                self.schoolData[#self.schoolData + 1] = item
            end
        end

        if self.schoolData and #self.schoolData > 0 then
            self.allData[#self.allData + 1] = {
                element_type = 1,
                title = 'Texture/Aries/Creator/keepwork/my_school_32bits.png#6 31 85 18'
            }
    
            for key, item in ipairs(self.schoolData) do
                item.element_type = 2
                self.allData[#self.allData + 1] = item
            end
        end

        if self.orgData and #self.orgData > 0 then
            self.allData[#self.allData + 1] = {
                element_type = 1,
                title = 'Texture/Aries/Creator/keepwork/my_school_32bits.png#6 7 85 18'
            }
    
            for key, item in ipairs(self.orgData) do
                item.element_type = 2
                self.allData[#self.allData + 1] = item
            end
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

    self:SetResult({
        {
            text = L"在这里显示筛选的结果",
            value = 0,
            selected = true,
        },
    })

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
        self:SetResult(data)

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
            self:SetResult({
                {
                    text = L"在这里显示筛选的结果",
                    value = 0,
                    selected = true,
                },
            })

            callback()
        end

        return false
    end

    KeepworkServiceSchoolAndOrg:SearchSchoolByName(name, self.curId, self.kind, function(data)
        self:SetResult(data)

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

function MySchool:SetResult(data)
    self.result = data
    
    if self.result and type(self.result) == 'table' then
        for aKey, aItem in ipairs(self.result) do
            local sameName = false

            for bKey, bItem in ipairs(self.result) do
                if aItem.id ~= bItem.id and aItem.name == bItem.name then
                    sameName = true
                    break
                end
            end

            if sameName then
                aItem.sameName = true
            end
        end

        for key, item in ipairs(self.result) do
            if item and item.name then
                item.originName = item.name

                if item and item.status and item.status == 0 then
                    item.name = item.name .. L"（审核中）"
                end
            end

            if item and item.region and item.sameName then
                local regionString = ''

                if item.region.country and item.region.country.name then
                    regionString = regionString .. item.region.country.name
                end

                if item.region.state and item.region.state.name then
                    regionString = regionString .. item.region.state.name
                end

                if item.region.city and item.region.city.name then
                    regionString = regionString .. item.region.city.name
                end

                if item.region.county and item.region.county.name then
                    regionString = regionString .. item.region.county.name
                end

                regionString = '（' .. regionString .. '）'

                item.name = item.name .. regionString
            end
        end
    end
end

function MySchool:OpenTeachingPlanCenter(orgUrl)
    if not orgUrl or type(orgUrl) ~= 'string' then
        return false
    end

    KeepworkServiceSession:SetUserLevels(nil, function()
        local userType = Mod.WorldShare.Store:Get('user/userType')

        if not userType or type(userType) ~= 'table' then
            return false
        end

        if userType.orgAdmin then
            local url = '/org/' .. orgUrl .. '/admin/packages'
            Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
            return
        end

        if userType.teacher then
            local url = '/org/' .. orgUrl .. '/teacher/teach'
            Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
            return
        end

        if userType.student or userType.freeStudent then
            local url = '/org/' .. orgUrl .. '/student'
            Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
            return
        end
    end)
end
