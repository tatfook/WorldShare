--[[
Title: Project Setting
Author: big  
CreateDate: 2020.08.15
ModifyDate: 2021.08.26
Place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local OpusSetting = NPL.load('(gl)Mod/WorldShare/cellar/OpusSetting/OpusSetting.lua')
------------------------------------------------------------
]]

-- libs
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand")

--- service
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")

local OpusSetting = NPL.export()

function OpusSetting:OnWorldLoad()
    local instituteVipChangeOnly = WorldCommon.GetWorldTag('instituteVipChangeOnly')
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    local currentEnterWorldUserId = currentEnterWorld.user and currentEnterWorld.user.id or 0
    local userId = Mod.WorldShare.Store:Get('user/userId')
    local userType = Mod.WorldShare.Store:Get('user/userType') or {}
    local isStudent = userType.student
    local isTeacher = userType.teacher

    -- exclude myself and institute user and teacher
    if instituteVipChangeOnly and
       currentEnterWorldUserId ~= userId and
       not isStudent and 
       not isTeacher then
        GameLogic.options:SetLockedGameMode('game')
        SlashCommand.slash_command_maps['mode'].mode_deny = 'game'
    end
end

function OpusSetting:Show()
    local params = Mod.WorldShare.Utils.ShowWindow(
        505,
        385,
        '(ws)OpusSetting',
        'Mod.WorldShare.OpusSetting'
    )

    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return
    end

    Mod.WorldShare.MsgBox:Wait()

    KeepworkServiceProject:GetProject(currentWorld.kpProjectId, function(data, err)
        Mod.WorldShare.MsgBox:Close()

        if type(data) == 'table' then
            if data.visibility and data.visibility == 0 then
                -- public
                params._page:GetNode('public'):SetAttribute('checked', 'checked')
                params._page:SetValue('private', false)
                if data.extra and
                   ((data.extra.vipEnabled and
                   data.extra.vipEnabled == 1) or
                   (data.extra.isVipWorld and
                   data.extra.isVipWorld == 1)) then
                    params._page:SetValue('vip_checkbox', true)
                    self.isVipWorld = true
                else
                    params._page:SetValue('vip_checkbox', false)
                    self.isVipWorld = false
                end

                if data.extra and data.extra.instituteVipEnabled and data.extra.instituteVipEnabled == 1 then
                    params._page:SetValue('institute_vip_checkbox', true)
                    self.instituteVipEnabled = true
                else
                    params._page:SetValue('institute_vip_checkbox', false)
                    self.instituteVipEnabled = false
                end

                if data.extra and data.extra.encode_world and data.extra.encode_world == 1 then
                    params._page:SetValue('encode_world', true)
                    self.encode_world = true
                else
                    params._page:SetValue('encode_world', false)
                    self.encode_world = false
                end

            elseif data.visibility == 1 then
                -- private
                params._page:SetValue('public', false)
                params._page:GetNode('private'):SetAttribute('checked', 'checked')
            end
        end
        params._page:Refresh(0.01)
    end)
end

function OpusSetting:SetPublic(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        return false
    end

    local params = {}

    if value == 'public' then
        params.visibility = 0
    elseif value == 'private' then
        params.visibility = 1
    end

    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, "255 0 0")
        end
    end)
end

function OpusSetting:SetVip(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return
    end

    local params = {
        extra = {}
    }

    if value then
        params.extra.isVipWorld = 1
    else
        params.extra.isVipWorld = 0
    end

    params.extra.vipEnabled = 0

    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
            self.isVipWorld = value
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, '255 0 0')
        end
    end)
end

function OpusSetting:SetInstituteVip(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or not currentWorld.kpProjectId or currentWorld.kpProjectId == 0 then
        return false
    end

    local params = {
        extra = {}
    }

    if value then
        params.extra.instituteVipEnabled = 1
    else
        params.extra.instituteVipEnabled = 0
    end

    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
            self.instituteVipEnabled = value
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, '255 0 0')
        end
    end)
end

function OpusSetting:SetEncodeWorld(value)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld or
       not currentWorld.kpProjectId or
       currentWorld.kpProjectId == 0 then
        return
    end

    local params = {
        extra = {}
    }

    if value then
        params.extra.encode_world = 1
    else
        params.extra.encode_world = 0
    end

    KeepworkServiceProject:UpdateProject(currentWorld.kpProjectId, params, function(data, err)
        if err == 200 then
            GameLogic.AddBBS(nil, L'设置成功', 3000, '0 255 0')
            self.encode_world = true
        else
            GameLogic.AddBBS(nil, L'设置失败', 3000, '255 0 0')
        end
    end)
end
