--[[
Title: Menu
Author: big
Date: 2020.8.4
place: Foshan
Desc:
use the lib:
------------------------------------------------------------
local Menu = NPL.load("(gl)Mod/WorldShare/cellar/Menu/Menu.lua")
------------------------------------------------------------
]]

-- UI
local ShareWorld = NPL.load("(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua")

-- service
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

local Menu = NPL.export()

function Menu:Init(menuItems)
    menuItems = menuItems or {}

    for key, item in ipairs(menuItems) do
        if item.order == 3 then
            item.order = 2
        end
    end

    local STATES = {
        ["FAVORITE"] = 1,
        ["UNFAVORITE"] = 2
    }
    local state = STATES.FAVORITE
    local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld") or {}
    local projectMenu = {}
    if currentEnterWorld and currentEnterWorld.kpProjectId and currentEnterWorld.kpProjectId ~= 0 then
        if KeepworkServiceSession:IsSignedIn() then
            local username = Mod.WorldShare.Store:Get("user/username")

            if currentEnterWorld and
               currentEnterWorld.user and
               currentEnterWorld.user.username and
               currentEnterWorld.user.username == username then
                projectMenu = {
                    text = L"项目", order=3, name="project", children =
                    {
                        {text = Mod.WorldShare.Utils.WordsLimit(currentEnterWorld.text) or "", name = "project.name", Enable = false, onclick = nil},
                        {text = format(L"项目ID：%d", currentEnterWorld.kpProjectId or 0), name = "project.pid", Enable = false, onclick = nil},
                        {text = format(L"派生自：%d", currentEnterWorld.fromProjectId or 0),name = "project.ppid", Enable = false, onclick = nil},
                        {Type = "Separator"},
                        {text = L"上传分享", name = "project.share", onclick = nil},
                        {Type = "Separator"},
                        {text = L"项目首页", name = "project.index", onclick = nil},
                        {text = L"项目作者", name = "project.author", onclick = nil},
                        {Type = "Separator"},
                        {text = L"本地目录", name = "file.openworlddir", onclick = nil},
                        {text = L"本地备份", name = "file.worldrevision", onclick = nil},
                        {Type = "Separator"},
                        {text = L"项目设置", name = "project.setting", onclick = nil},
                        {text = L"成员管理", name = "project.member", onclick = nil},
                    }
                }
            else
                projectMenu = {
                    text = L"项目", order=3, name="project", children =
                    {
                        {text = Mod.WorldShare.Utils.WordsLimit(currentEnterWorld.text) or "", name = "project.name", Enable = false, onclick = nil},
                        {text = format(L"项目ID：%d", currentEnterWorld.kpProjectId or 0), name = "project.pid", Enable = false, onclick = nil},
                        {text = format(L"派生自：%d", currentEnterWorld.fromProjectId or 0),name = "project.ppid", Enable = false, onclick = nil},
                        {Type = "Separator"},
                        {text = L"项目首页", name = "project.index", onclick = nil},
                        {text = L"项目作者", name = "project.author", onclick = nil},
                    }
                }

                if currentEnterWorld.memberCount and type(currentEnterWorld.memberCount) == 'number' and currentEnterWorld.memberCount > 1 then
                    if currentEnterWorld.members and type(currentEnterWorld.members) == 'table' then
                        local canApply = true

                        for key, item in ipairs(currentEnterWorld.members) do
                            if item == username then
                                canApply = false
                                break
                            end
                        end

                        if canApply then
                            projectMenu.children[#projectMenu.children + 1] = { Type = "Separator" }
                            projectMenu.children[#projectMenu.children + 1] = { text = L"申请加入", name = "project.apply", onclick = nil }
                        end
                    else
                        projectMenu.children[#projectMenu.children + 1] = { Type = "Separator" }
                        projectMenu.children[#projectMenu.children + 1] = { text = L"申请加入", name = "project.apply", onclick = nil }
                    end
                else
                    projectMenu.children[#projectMenu.children + 1] = { Type = "Separator" }
                    projectMenu.children[#projectMenu.children + 1] = { text = L"申请加入", name = "project.apply", onclick = nil }
                end
            end
        else
            projectMenu = {
                text = L"项目", order=3, name="project", children =
                {
                    {text = Mod.WorldShare.Utils.WordsLimit(currentEnterWorld.text) or "", name = "project.name", Enable = false, onclick = nil},
                    {text = format(L"项目ID：%d", currentEnterWorld.kpProjectId or 0), name = "project.pid", Enable = false, onclick = nil},
                    {text = format(L"派生自：%d", currentEnterWorld.fromProjectId or 0),name = "project.ppid", Enable = false, onclick = nil},
                    {Type = "Separator"},
                    {text = L"项目首页", name = "project.index", onclick = nil},
                    {text = L"项目作者", name = "project.author", onclick = nil},
                    {Type = "Separator"},
                    {text = L"申请加入", name = "project.apply", onclick = nil}
                }
            }
        end
    else
        projectMenu = {
            text = L"项目", order=3, name="project", children =
            {
                {text = Mod.WorldShare.Utils.WordsLimit(currentEnterWorld.text) or "", name = "project.name", Enable = false, onclick = nil},
                {Type = "Separator"},
                {text = L"上传分享", name = "project.share", onclick = nil},
                {Type = "Separator"},
                {text = L"本地目录", name = "file.openworlddir", onclick = nil},
                {text = L"本地备份", name = "file.worldrevision", onclick = nil},
            }
        }
    end

    NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.user.lua")
    NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua")
    keepwork.world.is_favorited({objectId = currentEnterWorld.kpProjectId, objectType = 5}, function(err, msg, data)
        if (err == 200) then
            state = data == true and STATES.UNFAVORITE or STATES.FAVORITE
        end
        table.insert(projectMenu.children,{Type = "Separator"})
        if state == STATES.FAVORITE then
            table.insert(projectMenu.children,{text = L"收藏项目", name = "project.favorite", onclick = nil})
        else
            table.insert(projectMenu.children,{text = L"取消收藏", name = "project.unfavorite", onclick = nil})
        end
        NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenu.lua");
        local DesktopMenu = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.DesktopMenu")
        DesktopMenu.RebuildMenuItem(projectMenu)
    end)

    menuItems[#menuItems + 1] = projectMenu
    return menuItems
end
