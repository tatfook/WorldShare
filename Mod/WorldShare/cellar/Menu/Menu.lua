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

    local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld") or {}
    local projectMenu = {}

    if currentEnterWorld and currentEnterWorld.kpProjectId then
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

    menuItems[#menuItems + 1] = projectMenu
        

    return menuItems
end
