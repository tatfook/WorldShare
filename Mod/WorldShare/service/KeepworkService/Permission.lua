--[[
Title: KeepworkService Permission
Author(s):  big
Date:  2020.05.20
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkServicePermission = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Permission.lua")
------------------------------------------------------------
]]

local KeepworkPermissionsApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/Permissions.lua")

local KeepworkServicePermission = NPL.export()

KeepworkServicePermission.AllAuth = {
    SchoolManagementSystem = "a_school_management_system",
    OnlineTeaching = "t_online_teaching",
    OnlineLearning = "s_online_learning",
    WorldDataSaveAs = "vip_world_data_save_as",
    SkinOfAllProtagonists = "vip_skin_of_all_protagonists",
    PythonCodeBlock = "vip_python_code_block",
    VideoPluginWatermarkRemoval = "vip_video_plugin_watermark_removal",
    Lan40PeopleOnline = "vip_lan_40_people_online",
    WanNetworking = "vip_wan_networking",
    OnlineWorldData50Mb = "vip_online_world_data_50mb",
}

function KeepworkServicePermission:GetAuth(authName)
    return self.AllAuth[authName]
end

function KeepworkServicePermission:Authentication(authName, callback)
    KeepworkPermissionsApi:Check(
        self:GetAuth(authName),
        function(data, err)
            if data and data.data == true then
                if type(callback) == "function" then
                    callback(true)
                end
            else
                if type(callback) == "function" then
                    callback(false)
                end
            end
        end,
        function(data, err)
            callback(false)
        end
    )
end