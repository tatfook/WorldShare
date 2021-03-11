--[[
Title: KeepworkService Permission
Author(s):  big
Date:  2020.05.20
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
    FlyOnParaWorld = {
        key = 'fly_on_paraworld',
        desc = L'马上飞行!'
    },
    VipGoods = {
        key = 'vip_goods',
        desc = L'拥有会员创造道具'
    },
    IsOrgan = {
        key = 'is_organ',
        desc = L'需要机构会员权限'
    }
}

function KeepworkServicePermission:GetAuth(authName)
    if self.AllAuth[authName] then
        return self.AllAuth[authName].key
    end

    return
end

function KeepworkServicePermission:GetAuthDesc(authName)
    if self.AllAuth[authName] then
        return self.AllAuth[authName].desc
    end

    return L'马上开通会员激活功能'
end

function KeepworkServicePermission:Authentication(authName, callback)
    if not self:GetAuth(authName) then
        if authName == '' or authName == 'Vip' then -- Vip
            if Mod.WorldShare.Store:Get('user/isVip') then
                if type(callback) == 'function' then
                    callback(true, 'vip', '')
                end

                return
            end
        elseif authName == 'Student' then
            local userType = Mod.WorldShare.Store:Get("user/userType") or {}
            if userType.student then
                if type(callback) == 'function' then
                    callback(true, 'student', '')
                end

                return
            end
        elseif authName == 'Teacher' then
            local userType = Mod.WorldShare.Store:Get("user/userType") or {}
            if userType.teacher then
                if type(callback) == 'function' then
                    callback(true, 'teacher', '')
                end

                return
            end
        end

        if type(callback) == 'function' then
            callback(false, authName, L'马上激活功能')
        end

        return
    end

    KeepworkPermissionsApi:Check(
        self:GetAuth(authName),
        function(data, err)
            if data and data.data == true then
                if type(callback) == 'function' then
                    callback(true, self:GetAuth(authName), self:GetAuthDesc(authName))
                end
            else
                if type(callback) == 'function' then
                    callback(false, self:GetAuth(authName), self:GetAuthDesc(authName))
                end
            end
        end,
        function(data, err)
            callback(false, self:GetAuth(authName), self:GetAuthDesc(authName))
        end
    )
end