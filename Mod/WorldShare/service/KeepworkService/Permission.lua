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

local KeepworkPermissionsApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/Permissions.lua')

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
    Limit3Worlds = {
        key = 'limit_3_worlds',
        desc = L'免费用户只能分享3个世界',
        role = {
            'student',
            'teacher',
            'vip'
        }
    },
    LimitWorldSize10Mb = {
        key = 'limit_world_size_10_mb',
        desc = L'免费用户只能分享不超过10M的世界',
        role = {
            'student',
            'teacher',
            'vip'
        }
    },
    LimitUserOpenShareWorld = {
        key = 'limit_user_open_share_world',
        desc = L'免费用户不能打开别人的世界',
        role = {
            'student',
            'teacher',
            'vip'
        }
    }
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
