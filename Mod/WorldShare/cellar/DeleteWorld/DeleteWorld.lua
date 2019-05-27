--[[
Title: DeleteWorld
Author(s):  big
Date: 2018.06.21
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local DeleteWorld = NPL.load("(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua")
------------------------------------------------------------
]]
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")

local DeleteWorld = NPL.export()

function DeleteWorld:ShowPage()
    local params =
        Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.html", "DeleteWorld", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Store:Remove("page/DeleteWorld")
    end
end

function DeleteWorld:SetPage()
    Store:Set("page/DeleteWorld", document:GetPageCtrl())
end

function DeleteWorld:ClosePage()
    local DeleteWorldPage = Store:Get("page/DeleteWorld")

    if (DeleteWorldPage) then
        DeleteWorldPage:CloseWindow()
    end
end

function DeleteWorld.GetSelectWorld()
    return Store:Get("world/currentWorld")
end

function DeleteWorld:DeleteWorld(foldername)
    local isEnterWorld = Store:Get("world/isEnterWorld")

    if (isEnterWorld) then
        local worldTag = WorldCommon.GetWorldInfo()

        if (foldername == worldTag.name) then
            _guihelper.MessageBox(L"不能刪除正在编辑的世界")
            return false
        end
    end

    self:ShowPage()
end

function DeleteWorld:DeleteLocal(callback)
    local currentWorld = Store:Get("world/currentWorld")

    if (not currentWorld) then
        _guihelper.MessageBox(L"请先选择世界")
        return
    end

    local function Delete()
        local worldDir = currentWorld.worldpath

        if (currentWorld.is_zip) then
            if (ParaIO.DeleteFile(worldDir)) then
                if (type(callback) == "function") then
                    callback()
                else
                    self:ClosePage()
                    WorldList:RefreshCurrentServerList()
                end
            else
                _guihelper.MessageBox(L"无法删除可能您没有足够的权限")
            end
        else
            if (GameLogic.RemoveWorldFileWatcher) then
                GameLogic.RemoveWorldFileWatcher() -- file watcher may make folder deletion of current world directory not working.
            end

            if (commonlib.Files.DeleteFolder(worldDir)) then
                if (type(callback) == "function") then
                    callback()
                else
                    self:ClosePage()
                    WorldList:RefreshCurrentServerList()
                end
            else
                _guihelper.MessageBox(L"无法删除可能您没有足够的权限")
            end
        end
    end

    if (currentWorld.status ~= 2) then
        _guihelper.MessageBox(
            format(L"确定删除本地世界:%s?", currentWorld.text or ""),
            function(res)
                if (res and res == _guihelper.DialogResult.Yes) then
                    Delete()
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )
    end
end

function DeleteWorld:DeleteRemote()
    local dataSourceInfo = Store:Get("user/dataSourceInfo")
    local foldername = Store:Get("world/foldername")

    if (not dataSourceInfo) then
        return false
    end

    _guihelper.MessageBox(
        format(L"确定删除远程世界:%s?", foldername.utf8 or ""),
        function(res)
            if (res and res == 6) then
                if (dataSourceInfo.dataSourceType == "github") then
                    self:DeleteGithub()
                elseif (dataSourceInfo.dataSourceType == "gitlab") then
                    self:ClosePage()
                    WorldList:SetRefreshing(true)
                    self:DeleteRecord()
                end
            end
        end
    )
end

function DeleteWorld:DeleteRecord(world)
    local currentWorld = world or Store:Get("world/currentWorld")

    if (not currentWorld) then
        return false
    end

    local kpProjectId = currentWorld.kpProjectId

    KeepworkService:DeleteWorld(
        kpProjectId,
        function(data, err)
            if (err ~= 204 and err ~= 200) then
                _guihelper.MessageBox(format("%s:%d", L"服务器返回错误状态码", err))
            end

            if currentWorld and currentWorld.worldpath and #currentWorld.worldpath > 0 then
                local tag = LocalService:GetTag(currentWorld.worldpath)

                tag.kpProjectId = nil
                LocalService:SetTag(currentWorld.worldpath, tag)
            end

            WorldList:RefreshCurrentServerList()
        end
    )
end

function DeleteWorld.DeleteWorldMd()
    local currentWorld = Store:Get("world/currentWorld")
    local userinfo = Store:Get("user/userinfo")
    local dataSourceInfo = Store:Get("user/dataSourceInfo")

    if (not currentWorld or not userinfo or not dataSourceInfo) then
        return false
    end

    local foldername = currentWorld.foldername

    if (dataSourceInfo.dataSourceType == "github") then
    elseif (dataSourceInfo.dataSourceType == "gitlab") then
        GitService:GetProjectIdByName(
            foldername,
            function(projectId)
                if (projectId) then
                    local path = format("%s/paracraft/world_%s.md", userinfo.username, foldername)

                    GitService:DeleteFile(
                        projectId,
                        nil,
                        path,
                        nil,
                        function()
                            WorldList:RefreshCurrentServerList()
                        end
                    )
                else
                    WorldList:RefreshCurrentServerList()
                end
            end
        )
    end
end

function DeleteWorld:DeleteAll()
    self:DeleteLocal(
        function()
            self:DeleteRemote()
        end
    )
end
