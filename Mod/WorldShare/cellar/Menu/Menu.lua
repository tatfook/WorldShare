--[[
Title: Menu
Author: big
CreateDate: 2020.8.4
ModifyDate: 2022.7.20
place: Foshan
Desc:
use the lib:
------------------------------------------------------------
local Menu = NPL.load('(gl)Mod/WorldShare/cellar/Menu/Menu.lua')
------------------------------------------------------------
]]

-- UI
local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')

-- libs
NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenu.lua')

local DesktopMenu = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop.DesktopMenu')

local Menu = NPL.export()

function Menu:Init(menuItems)
    menuItems = menuItems or {}

    for key, item in ipairs(menuItems) do
        if item.order == 3 then
            item.order = 2
        end
    end

    self:Online(menuItems)

    local projectMenu = self:Projects(menuItems)

    menuItems[#menuItems + 1] = projectMenu
    return menuItems
end

function Menu:Projects(menuItems)
    local STATES = {
        ['FAVORITE'] = 1,
        ['UNFAVORITE'] = 2
    }

    local state = STATES.FAVORITE
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld') or {}
    local projectMenu = {}

    if currentEnterWorld and
       currentEnterWorld.kpProjectId and
       currentEnterWorld.kpProjectId ~= 0 then
        if KeepworkServiceSession:IsSignedIn() then
            local username = Mod.WorldShare.Store:Get('user/username')

            if currentEnterWorld and
               currentEnterWorld.user and
               currentEnterWorld.user.username and
               currentEnterWorld.user.username == username then
                projectMenu = {
                    text = L'项目',
                    order = 3,
                    name = 'project',
                    children = {
                        {
                            text = Mod.WorldShare.Utils.WordsLimit(currentEnterWorld.text) or '',
                            name = 'project.name',
                            Enable = false,
                            onclick = nil
                        },
                        {
                            text = format(L'项目ID：%d', currentEnterWorld.kpProjectId or 0),
                            name = 'project.pid',
                            Enable = false,
                            onclick = nil
                        },
                        {
                            text = format(L'派生自：%d', currentEnterWorld.fromProjectId or 0),
                            name = 'project.ppid',
                            Enable = false,
                            onclick = nil
                        },
                        { Type = 'Separator' },
                        {
                            text = L'上传分享',
                            name = 'project.share',
                            onclick = nil
                        },
                        { Type = 'Separator' },
                        {
                            text = L'项目首页',
                            name = 'project.index',
                            onclick = nil
                        },
                        {
                            text = L'项目作者',
                            name = 'project.author',
                            onclick = nil
                        },
                        { Type = 'Separator' },
                        {
                            text = L'本地目录',
                            name = 'file.openworlddir',
                            onclick = nil
                        },
                        {
                            text = L'本地备份',
                            name = 'file.worldrevision',
                            onclick = nil
                        },
                        { Type = 'Separator' },
                        {
                            text = L'项目设置',
                            name = 'project.setting',
                            onclick = nil
                        },
                        {
                            text = L'成员管理',
                            name = 'project.member',
                            onclick = nil
                        },
                    }
                }
            else
                projectMenu = {
                    text = L'项目',
                    order = 3,
                    name = 'project',
                    children = {
                        {
                            text = Mod.WorldShare.Utils.WordsLimit(currentEnterWorld.text) or '',
                            name = 'project.name',
                            Enable = false,
                            onclick = nil
                        },
                        {
                            text = format(L'项目ID：%d', currentEnterWorld.kpProjectId or 0),
                            name = 'project.pid',
                            Enable = false,
                            onclick = nil
                        },
                        {
                            text = format(L'派生自：%d', currentEnterWorld.fromProjectId or 0),
                            name = 'project.ppid',
                            Enable = false,
                            onclick = nil
                        },
                        { Type = 'Separator' },
                        {
                            text = L'项目首页',
                            name = 'project.index',
                            onclick = nil
                        },
                        {
                            text = L'项目作者',
                            name = 'project.author',
                            onclick = nil
                        },
                    }
                }

                if currentEnterWorld.memberCount and
                   type(currentEnterWorld.memberCount) == 'number' and
                   currentEnterWorld.memberCount > 1 then
                    if currentEnterWorld.members and
                       type(currentEnterWorld.members) == 'table' then
                        local canApply = true

                        for key, item in ipairs(currentEnterWorld.members) do
                            if item == username then
                                canApply = false
                                break
                            end
                        end

                        if canApply then
                            projectMenu.children[#projectMenu.children + 1] = { Type = 'Separator' }
                            projectMenu.children[#projectMenu.children + 1] = { text = L'申请加入', name = 'project.apply', onclick = nil }
                        end
                    else
                        projectMenu.children[#projectMenu.children + 1] = { Type = 'Separator' }
                        projectMenu.children[#projectMenu.children + 1] = { text = L'申请加入', name = 'project.apply', onclick = nil }
                    end
                else
                    projectMenu.children[#projectMenu.children + 1] = { Type = 'Separator' }
                    projectMenu.children[#projectMenu.children + 1] = { text = L'申请加入', name = 'project.apply', onclick = nil }
                end
            end
        else
            projectMenu = {
                text = L'项目',
                order = 3,
                name = 'project',
                children = {
                    {
                        text = Mod.WorldShare.Utils.WordsLimit(currentEnterWorld.text) or '',
                        name = 'project.name',
                        Enable = false,
                        onclick = nil
                    },
                    {
                        text = format(L'项目ID：%d', currentEnterWorld.kpProjectId or 0),
                        name = 'project.pid',
                        Enable = false,
                        onclick = nil
                    },
                    {
                        text = format(L'派生自：%d', currentEnterWorld.fromProjectId or 0),
                        name = 'project.ppid',
                        Enable = false,
                        onclick = nil
                    },
                    { Type = 'Separator' },
                    {
                        text = L'项目首页',
                        name = 'project.index',
                        onclick = nil
                    },
                    {
                        text = L'项目作者',
                        name = 'project.author',
                        onclick = nil
                    },
                    { Type = 'Separator' },
                    {
                        text = L'申请加入',
                        name = 'project.apply',
                        onclick = nil
                    }
                }
            }
        end
    else
        projectMenu = {
            text = L'项目',
            order = 3,
            name = 'project',
            children = {
                {
                    text = Mod.WorldShare.Utils.WordsLimit(currentEnterWorld.text) or '',
                    name = 'project.name',
                    Enable = false,
                    onclick = nil
                },
                { Type = 'Separator' },
                {
                    text = L'上传分享',
                    name = 'project.share',
                    onclick = nil
                },
                { Type = 'Separator' },
                {
                    text = L'本地目录',
                    name = 'file.openworlddir',
                    onclick = nil
                },
                {
                    text = L'本地备份',
                    name = 'file.worldrevision',
                    onclick = nil
                },
            }
        }
    end

    NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/keepwork.user.lua')
    NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua')

    keepwork.world.is_stared(
        { router_params = { id = currentEnterWorld.kpProjectId } },
        function(err, msg, data)
            local isLiked = false

            if (err == 200) then
                isLiked = data == true
            end

            table.insert(projectMenu.children, { Type = 'Separator' })

            if isLiked then
                table.insert(
                    projectMenu.children,
                    {
                        text = L'今日已点',
                        name = 'project.unlike',
                        onclick = nil
                    }
                )
            else
                table.insert(
                    projectMenu.children,
                    {
                        text = L'点赞项目',
                        name = 'project.like',
                        onclick = nil
                    }
                )
            end

            keepwork.world.is_favorited(
                { objectId = currentEnterWorld.kpProjectId, objectType = 5 },
                function(err, msg, data)
                    if (err == 200) then
                        state = data == true and STATES.UNFAVORITE or STATES.FAVORITE
                    end

                    if state == STATES.FAVORITE then
                        table.insert(
                            projectMenu.children,
                            {
                                text = L'收藏项目',
                                name = 'project.favorite',
                                onclick = nil
                            }
                        )
                    else
                        table.insert(
                            projectMenu.children,
                            {
                                text = L'取消收藏',
                                name = 'project.unfavorite',
                                onclick = nil
                            }
                        )
                    end

                    DesktopMenu.RebuildMenuItem(projectMenu)
                end
            )
        end
    )
    return projectMenu
end

function Menu:Online(menuItems)
    if not menuItems or type(menuItems) ~= 'table' then
        return
    end

    for key, item in ipairs(menuItems) do
        if item and item.name == 'online' then
            if item.children and type(item.children) == 'table' then
                if GameLogic.options:IsCommunityWorld() then
                    item.children[#item.children + 1] = { name = 'online.community', text = L'关闭 社区联网' }
                else
                    item.children[#item.children + 1] = { name = 'online.community', text = L'开启 社区联网' }
                end
            end
        end
    end
end
