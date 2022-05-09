--[[
Title: KeepworkService Permission
Author(s): big
CreateDate: 2020.05.20
ModifyDate: 2021.09.28
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServicePermission = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Permission.lua')
------------------------------------------------------------
]]

-- api
local KeepworkPermissionsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Permissions.lua')
local KeepworkCommonApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/KeepworkCommonApi.lua")

local KeepworkServicePermission = NPL.export()

KeepworkServicePermission.AllAuth = {
    SchoolManagementSystem = {
        key = 'a_school_management_system',
        desc = L'马上激活功能'
    },
    OnlineTeaching = {
        key = 't_online_teaching',
        desc = L'马上激活功能'
    },
    OnlineLearning = {
        key = 's_online_learning',
        desc =  L'马上激活功能'
    },
    WorldDataSaveAs = {
        key = 'vip_world_data_save_as',
        desc = L'马上激活功能',
    },
    SkinOfAllProtagonists = {
        key = 'vip_skin_of_all_protagonists',
        desc = L'激活全部皮肤'
    },
    PythonCodeBlock = {
        key = 'vip_python_code_block',
        desc = L'使用Python方块'
    },
    VideoPluginWatermarkRemoval = {
        key = 'vip_video_plugin_watermark_removal',
        desc = L'去除视频水印'
    },
    Lan40PeopleOnline = {
        key = 'vip_lan_40_people_online',
        desc = L'扩展联网人数'
    },
    WanNetworking = {
        key = 'vip_wan_networking',
        desc = L'组建互联网服务器'
    },
    OnlineWorldData50Mb = {
        key = 'vip_online_world_data_50mb',
        desc = L'存储大型作品'
    },
    MakeApp = {
        key = 'MakeApp',
        desc = L'创建自己的App'
    },
    ChangeAvatarSkin = {
        key = 'ChangeAvatarSkin',
        desc = L'尽享精彩形象'
    },
    TeacherCreateVipWorld = {
        key = 't_create_vip_world',
        desc = L'创建特殊权限世界'
    },
    VipCodeGameArtOfWar = {
        key = 'vip_code_game_art_of_war',
        desc = L'畅享玩学课堂'
    },
    VipWeeklyTraining = {
        key = 'vip_weekly_training',
        desc = L'畅享每周实战'
    },
    DailyNote = {
        key = 'daily_note',
        desc = L'随意观看每日成长视频'
    },
    VipGoods = {
        key = 'vip_goods',
        desc = L'拥有会员创造道具'
    },
    IsOrgan = {
        key = 'is_organ',
        desc = L'需要机构会员权限'
    },
    LongMarch = {
        key = 'long_march',
        desc = L'畅学征程编程课'
    },
    VipPrivateWorld = {
        key = 'vip_private_world',
        desc = L'自主授权开放及私有空间'
    },
    UnlimitWorldsNumber = {
        key = 'unlimit_worlds_number',
        desc = L'分享更多世界',
    },
    LimitUserOpenShareWorld = {
        key = 'limit_user_open_share_world',
        desc = L'免费用户不能打开别人的世界',
    }
}

KeepworkServicePermission.AllLocalAuth = {
    FlyOnParaWorld = {
        key = 'fly_on_paraworld',
        desc = L'马上飞行!',
        role = {
            'vip',
            'student',
            'teacher'
        }
    },
    PlyText = {
        key = 'play_text',
        desc = L'AI朗读'
    },
    MakeApk = {
        key = 'make_apk',
        desc = L'生成APK',
        role = {
            'vip',
            'student',
            'teacher'
        }
    },
    RedSummerCampMain = {
        key = 'red_summer_camp_main', -- red summer vip
        desc = nil
    },
    -- Limit3Worlds = {
    --     key = 'limit_3_worlds',
    --     desc = L'免费用户只能分享3个世界',
    --     role = {
    --         'student',
    --         'teacher',
    --         'vip'
    --     }
    -- },
    LimitWorldSize10Mb = {
        key = 'limit_world_size_10_mb',
        desc = L'免费用户只能分享不超过10M的世界',
        role = {
            'student',
            'teacher',
            'vip'
        }
    },
    -- LimitUserOpenShareWorld = {
    --     key = 'limit_user_open_share_world',
    --     desc = L'免费用户不能打开别人的世界',
    --     role = {
    --         'student',
    --         'teacher',
    --         'vip'
    --     }
    -- }
}

function KeepworkServicePermission:GetLocalAuthKey(authName)
    if self.AllLocalAuth[authName] then
        return self.AllLocalAuth[authName].key
    end

    return
end

function KeepworkServicePermission:GetAuthKey(authName)
    if self.AllAuth[authName] then
        return self.AllAuth[authName].key
    end

    return
end

function KeepworkServicePermission:GetLocalAuthDesc(authName)
    if self.AllLocalAuth[authName] then
        return self.AllLocalAuth[authName].desc
    end

    return L'马上开通会员激活功能'
end

function KeepworkServicePermission:GetAuthDesc(authName)
    if self.AllAuth[authName] then
        return self.AllAuth[authName].desc
    end

    return L'马上开通会员激活功能'
end

function KeepworkServicePermission:GetLocalAuthRole(authName)
    if self.AllLocalAuth[authName] then
        return self.AllLocalAuth[authName].role
    end

    return
end

function KeepworkServicePermission:Authentication(authName, callback)
    -- check permission locally for VIP permission
    if self:GetLocalAuthKey(authName) then
        local localAuthRole = self:GetLocalAuthRole(authName)

        if localAuthRole and
           type(localAuthRole) == 'table' and
           #localAuthRole > 0 then
            for _, item in pairs(localAuthRole) do
                if item == 'vip' then
                    if Mod.WorldShare.Store:Get('user/isVip') then
                        callback(true, self:GetLocalAuthKey(authName), self:GetLocalAuthDesc(authName))
                        return
                    end
                elseif item == 'student' then
                    local userType = Mod.WorldShare.Store:Get('user/userType')

                    if userType.student then
                        callback(true, self:GetLocalAuthKey(authName), self:GetLocalAuthDesc(authName))
                        return
                    end
                elseif item == 'teacher' then
                    local userType = Mod.WorldShare.Store:Get('user/userType')

                    if userType.teacher then
                        callback(true, self:GetLocalAuthKey(authName), self:GetLocalAuthDesc(authName))
                        return
                    end
                end
            end

            callback(false, self:GetLocalAuthKey(authName), self:GetLocalAuthDesc(authName))
        else
            if Mod.WorldShare.Store:Get('user/isVip') then
                if callback and type(callback) == 'function' then
                    callback(true, self:GetLocalAuthKey(authName), self:GetLocalAuthDesc(authName))
                end
            else
                if callback and type(callback) == 'function' then
                    callback(false, self:GetLocalAuthKey(authName), self:GetLocalAuthDesc(authName))
                end
            end
        end

        return
    end

    if not self:GetAuthKey(authName) then
        if authName == '' or authName == 'Vip' then -- Vip
            if Mod.WorldShare.Store:Get('user/isVip') then
                if callback and type(callback) == 'function' then
                    callback(true, 'vip', '')
                end

                return
            end
        elseif authName == 'Student' then
            local userType = Mod.WorldShare.Store:Get("user/userType") or {}
            if userType.student then
                if callback and type(callback) == 'function' then
                    callback(true, 'student', '')
                end

                return
            end
        elseif authName == 'Teacher' then
            local userType = Mod.WorldShare.Store:Get("user/userType") or {}
            if userType.teacher then
                if callback and type(callback) == 'function' then
                    callback(true, 'teacher', '')
                end

                return
            end
        end

        if callback and type(callback) == 'function' then
            callback(false, authName, L'马上激活功能')
        end

        return
    end

    KeepworkPermissionsApi:Check(
        self:GetAuthKey(authName),
        function(data, err)
            if data and data.data == true then
                if callback and type(callback) == 'function' then
                    callback(true, self:GetAuthKey(authName), self:GetAuthDesc(authName))
                end
            else
                if callback and type(callback) == 'function' then
                    callback(false, self:GetAuthKey(authName), self:GetAuthDesc(authName))
                end
            end
        end,
        function(data, err)
            if callback and type(callback) == 'function' then
                callback(false, self:GetAuthKey(authName), self:GetAuthDesc(authName))
            end
        end
    )
end

function KeepworkServicePermission:TimesFilter(timeRules)
    local serverTime = Mod.WorldShare.Store:Get('world/currentServerTime')
    local weekDay = Mod.WorldShare.Utils.GetWeekNum(serverTime)
    local dateList = {'一', '二', '三', '四', '五', '六', '日'}

    local function Check(timeRule)
        local year, month, day = timeRule.startDay:match('^(%d+)%D(%d+)%D(%d+)') 
        local startDateTimestamp = 
            os.time(
                {
                    day = tonumber(day),
                    month = tonumber(month),
                    year = tonumber(year),
                    hour = 0,
                    min = 0,
                    sec = 0
                }
            )

        year, month, day = timeRule.endDay:match('^(%d+)%D(%d+)%D(%d+)')
        local endDateTimestamp =
            os.time(
                {
                    day = tonumber(day),
                    month = tonumber(month),
                    year = tonumber(year),
                    hour = 23,
                    min = 59,
                    sec=59
                }
            )

        if serverTime < startDateTimestamp then
            return false, string.format(L'未到上课时间，请在%s之后来学习吧。', timeRule.startDay)
        end

        if serverTime > endDateTimestamp then
            return false, L'上课时间已过'
        end

        local weeks = timeRule.weeks
        local inWeekDay = false

        local dateStr = ''

        for i, v in ipairs(weeks) do
            if v == weekDay then
                inWeekDay = true
            end

            dateStr = dateStr .. L'周' .. dateList[v] or ''

            if i ~= #weeks then
                dateStr = dateStr .. '，'
            end
        end

        if not inWeekDay then
            return false, string.format(L'现在不是上课时间哦，请在上课时间（%s）内再来上课吧。', dateStr)
        end

        local startTimeStr = timeRule.startTime or '0:0'
        local startHour, startMin = startTimeStr:match('^(%d+)%D(%d+)') 
        startHour = tonumber(startHour)
        startMin = tonumber(startMin)

        local endTimeStr = timeRule.endTime or '23:59'
        local endHour, endMin = endTimeStr:match('^(%d+)%D(%d+)') 
        endHour = tonumber(endHour)
        endMin = tonumber(endMin)

        local timeStr = startTimeStr .. '-' .. endTimeStr

        local todayWeehours = commonlib.timehelp.GetWeeHoursTimeStamp(serverTime)
        local limitTimeStamp = todayWeehours + startHour * 60 * 60 + startMin * 60
        local limitTimeEndStamp = todayWeehours + endHour * 60 * 60 + endMin * 60

        if serverTime < limitTimeStamp or serverTime > limitTimeEndStamp then
            return false, string.format(L'现在不是上课时间哦，请在上课时间（%s）内再来上课吧。', timeStr)
        end

        return true
    end

    local failedReasonList = {}
    local bIsSuccessed = nil
    local hasDateType = false

    for _, timeRule in ipairs(timeRules) do
        if not timeRule.dateType and
           timeRule.startDate or
           timeRule.endDate or
           timeRule.weeks then
            local result, reason = Check(timeRule)

            if result then
                bIsSuccessed = true
                break
            end

            bIsSuccessed = false
            failedReasonList[#failedReasonList + 1] = reason
        else
            if timeRule.dateType then
                hasDateType = true
            end
        end
    end

    if bIsSuccessed == nil or bIsSuccessed == true then
        return true
    else
        if hasDateType then
            return true
        else
            return false, failedReasonList[1]
        end
    end
end

function KeepworkServicePermission:HolidayTimesFilter(timeRules, callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    local hasLimit = nil
    local lastDateType = nil
    local curTimeRule = nil

    for _, timeRule in ipairs(timeRules) do
        if type(timeRule.dateType) == 'number' then
            if timeRule.dateType == 0 then
                if not lastDateType or lastDateType > 0 then
                    lastDateType = 0
                    hasLimit = false
                    curTimeRule = timeRule
                end
            elseif timeRule.dateType == 1 then
                if not lastDateType or lastDateType > 1 then
                    lastDateType = 1
                    hasLimit = true
                    curTimeRule = timeRule
                end
            elseif timeRule.dateType == 2 then
                if not lastDateType then
                    lastDateType = 2
                    hasLimit = true
                    curTimeRule = timeRule
                end
            end
        end
    end

    if hasLimit == true then
        KeepworkCommonApi:Holiday(
            nil,
            function(data, err)
                if data and type(data) == 'table' and type(data.isHoliday) == 'boolean' then
                    if curTimeRule.dateType == 0 then
                        callback(true)
                    elseif curTimeRule.dateType == 1 then
                        local serverTime = Mod.WorldShare.Store:Get('world/currentServerTime')
                        local startTimeStr = curTimeRule.startTime or '0:0'
                        local endTimeStr = curTimeRule.endTime or '23:59'
                        local timeStr = startTimeStr .. '-' .. endTimeStr

                        if data.isHoliday then
                            callback(false, string.format(L'现在不是上课时间哦，请在上课时间（上学日%s）内再来上课吧。', timeStr))
                        else
                            local startHour, startMin = startTimeStr:match('^(%d+)%D(%d+)')
                            startHour = tonumber(startHour)
                            startMin = tonumber(startMin)

                            local endHour, endMin = endTimeStr:match('^(%d+)%D(%d+)')
                            endHour = tonumber(endHour)
                            endMin = tonumber(endMin)

                            local todayWeehours = commonlib.timehelp.GetWeeHoursTimeStamp(serverTime)
                            local limitTimeStamp = todayWeehours + startHour * 60 * 60 + startMin * 60
                            local limitTimeEndStamp = todayWeehours + endHour * 60 * 60 + endMin * 60

                            if serverTime < limitTimeStamp or serverTime > limitTimeEndStamp then
                                callback(false, string.format(L'现在不是上课时间哦，请在上课时间（%s）内再来上课吧。', timeStr))
                            else
                                callback(true)
                            end
                        end
                    elseif curTimeRule.dateType == 2 then
                        local serverTime = Mod.WorldShare.Store:Get('world/currentServerTime')
                        local startTimeStr = curTimeRule.startTime or '0:0'
                        local endTimeStr = curTimeRule.endTime or '23:59'
                        local timeStr = startTimeStr .. '-' .. endTimeStr

                        if not data.isHoliday then
                            callback(false, string.format(L'现在不是上课时间哦，请在上课时间（节假日%s）内再来上课吧。', timeStr))
                        else
                            local startHour, startMin = startTimeStr:match('^(%d+)%D(%d+)')
                            startHour = tonumber(startHour)
                            startMin = tonumber(startMin)

                            local endHour, endMin = endTimeStr:match('^(%d+)%D(%d+)')
                            endHour = tonumber(endHour)
                            endMin = tonumber(endMin)

                            local todayWeehours = commonlib.timehelp.GetWeeHoursTimeStamp(serverTime)
                            local limitTimeStamp = todayWeehours + startHour * 60 * 60 + startMin * 60
                            local limitTimeEndStamp = todayWeehours + endHour * 60 * 60 + endMin * 60

                            if serverTime < limitTimeStamp or serverTime > limitTimeEndStamp then
                                callback(false, string.format(L'现在不是上课时间哦，请在上课时间（%s）内再来上课吧。', timeStr))
                            else
                                callback(true)
                            end
                        end
                    else
                        callback(false, L'校验上课时间失败')
                    end
                else
                    callback(false, L'校验上课时间失败')
                end
            end,
            function()
                callback(false, L'校验上课时间失败')
            end
        )
    elseif hasLimit == false then
        callback(true)
    else
        callback(false, '校验上课时间失败')
    end
end
