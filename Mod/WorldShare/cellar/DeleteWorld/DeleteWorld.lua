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
    return Store:Get("world/selectWorld")
end

function DeleteWorld:DeleteWorld()
    local isEnterWorld = Store:Get("world/isEnterWorld")

    if (isEnterWorld) then
        local selectWorld = Store:Get("world/selectWorld")
        local enterWorld = Store:Get("world/enterWorld")

        if (enterWorld and enterWorld.foldername == selectWorld.foldername) then
            _guihelper.MessageBox(L"不能刪除正在编辑的世界")
            return false
        end
    end

    self:ShowPage()
end

function DeleteWorld:DeleteLocal(callback)
    local selectWorld = Store:Get("world/selectWorld")

    if (not selectWorld) then
        _guihelper.MessageBox(L"请先选择世界")
        return
    end

    local function Delete()
        local worldDir = selectWorld.worldpath

        if (selectWorld.is_zip) then
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

    if (selectWorld.status ~= 2) then
        _guihelper.MessageBox(
            format(L"确定删除本地世界:%s?", selectWorld.text or ""),
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

function DeleteWorld:DeleteRecord()
    local selectWorld = Store:Get("world/selectWorld")

    if (not selectWorld) then
        return false
    end

    local kpProjectId = selectWorld.kpProjectId

    KeepworkService:DeleteWorld(
        kpProjectId,
        function(data, err)
            if (err == 204 or err == 200) then
                WorldList:RefreshCurrentServerList()
            end
        end
    )
end

function DeleteWorld:DeleteGitlab()
    local foldername = Store:Get("world/foldername")

    _guihelper.MessageBox(
        format(L"确定删除Gitlab远程世界:%s?", foldername.utf8 or ""),
        function(res)
            self:ClosePage()
            WorldList:SetRefreshing(true)

            if (res and res == 6) then
                DeleteWorld.DeleteKeepworkRecord()
            end
        end
    )
end

function DeleteWorld.DeleteWorldMd()
    local selectWorld = Store:Get("world/selectWorld")
    local userinfo = Store:Get("user/userinfo")
    local dataSourceInfo = Store:Get("user/dataSourceInfo")

    if (not selectWorld or not userinfo or not dataSourceInfo) then
        return false
    end

    local foldername = selectWorld.foldername

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
