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
local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
local LoginWorldList = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginWorldList.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local GitEncoding = NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")

local DeleteWorld = NPL.export()

function DeleteWorld.ShowDeleteWorldPage()
    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.html", "DeleteWorld", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Store:remove('page/DeleteWorld')
    end
end

function DeleteWorld.setDeletePage()
    Store:set("page/DeleteWorld", document:GetPageCtrl())
end

function DeleteWorld.closeDeletePage()
    local DeleteWorldPage = Store:get('page/DeleteWorld')

    if (DeleteWorldPage) then
        DeleteWorldPage:CloseWindow()
    end
end

function DeleteWorld.GetSelectWorld()
    return Store:get("world/selectWorld")
end

function DeleteWorld.DeleteWorld()
    local IsEnterWorld = Store:get("world/IsEnterWorld")
    
    if (IsEnterWorld) then
        local selectWorld = Store:get("world/selectWorld")
        local enterWorld = Store:get("world/enterWorld")

        if(enterWorld.foldername == selectWorld.foldername) then
            _guihelper.MessageBox(L"不能刪除正在编辑的世界")
            return false
        end
    end

    DeleteWorld.ShowDeleteWorldPage()
end

function DeleteWorld.DeleteLocal(callback)
    local selectWorld = Store:get("world/selectWorld")

    if (not selectWorld) then
        _guihelper.MessageBox(L"请先选择世界")
        return
    end

    local foldername = selectWorld.foldername

    local function delete()
        local worldDir = selectWorld.worldpath

        if (selectWorld.is_zip) then
            if (ParaIO.DeleteFile(worldDir)) then
                if (type(callback) == "function") then
                    callback()
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
                    callback(foldername)
                end
            else
                _guihelper.MessageBox(L"无法删除可能您没有足够的权限")
            end
        end

        DeleteWorld.closeDeletePage()
        LoginWorldList.RefreshCurrentServerList()
    end

    if (selectWorld.status ~= 2) then
        _guihelper.MessageBox(
            format(L"确定删除本地世界:%s?", selectWorld.text or ""),
            function(res)
                if (res and res == _guihelper.DialogResult.Yes) then
                    delete()
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )
    end
end

-- function DeleteWorld.DeleteRemote_(index)
--     local selectWorld = Store:get("selectWorld")
--     local zipPath = selectWorld.localpath

--     if (ParaIO.DeleteFile(zipPath)) then
--         LoginWorldList.RefreshCurrentServerList()
--     else
--         _guihelper.MessageBox(L"无法删除可能您没有足够的权限")
--     end

--     DeleteWorld.closeDeletePage()
-- end

function DeleteWorld.DeleteRemote()
    local dataSourceInfo = Store:get("user/dataSourceInfo")

    if (not dataSourceInfo) then
        return false
    end

    if (dataSourceInfo.dataSourceType == "github") then
        DeleteWorld.DeleteGithub()
    elseif (dataSourceInfo.dataSourceType == "gitlab") then
        DeleteWorld.DeleteGitlab()
    end
end

function DeleteWorld.DeleteGitlab()
    local selectWorld = Store:get("world/selectWorld")

    if (not selectWorld) then
        return false
    end

    local foldername = selectWorld.foldername

    _guihelper.MessageBox(
        format(L"确定删除Gitlab远程世界:%s?", foldername or ""),
        function(res)
            DeleteWorld.closeDeletePage()
            LoginMain.setLoginMainPageRefreshing(true)

            if (res and res == 6) then
                GitService:getProjectIdByName(
                    GitEncoding.base32(foldername),
                    function(projectId)
                        if (projectId) then
                            GitService:deleteResp(
                                projectId,
                                nil,
                                function()
                                    DeleteWorld.DeleteKeepworkRecord()
                                end
                            )
                        else
                            DeleteWorld.DeleteKeepworkRecord()
                        end
                    end
                )
            end
        end
    )
end

function DeleteWorld.DeleteGithub(password)
    -- local foldername = SyncMain.selectedWorldInfor.foldername
    -- foldername = Encoding.Utf8ToDefault(foldername)
    -- local AuthUrl = "https://api.github.com/authorizations"
    -- local AuthParams = {
    --     scopes = {
    --         "delete_repo"
    --     },
    --     note = ParaGlobal.timeGetTime()
    -- }
    -- local basicAuth = loginMain.dataSourceUsername .. ":" .. password
    -- local AuthToken = ""
    -- basicAuth = Encoding.base64(basicAuth)
    -- HttpRequest:GetUrl(
    --     {
    --         url = AuthUrl,
    --         json = true,
    --         headers = {
    --             Authorization = "Basic " .. basicAuth,
    --             ["User-Agent"] = "npl",
    --             ["content-type"] = "application/json"
    --         },
    --         form = AuthParams
    --     },
    --     function(data, err)
    --         local basicAuthData = data
    --         AuthToken = basicAuthData.token
    --         _guihelper.MessageBox(
    --             format(L"确定删除Gihub远程世界:%s?", foldername or ""),
    --             function(res)
    --                 SyncMain.DeletePage:CloseWindow()
    --                 if (res and res == 6) then
    --                     GithubService:deleteResp(
    --                         foldername,
    --                         AuthToken,
    --                         function(data, err)
    --                             --LOG.std(nil,"debug","GithubService:deleteResp",err);
    --                             if (err == 204) then
    --                                 SyncMain.deleteKeepworkWorldsRecord()
    --                             else
    --                                 _guihelper.MessageBox(L"远程仓库不存在，记录将直接被删除")
    --                                 SyncMain.deleteKeepworkWorldsRecord()
    --                             end
    --                         end
    --                     )
    --                 end
    --             end
    --         )
    --     end
    -- )
end

function DeleteWorld.DeleteKeepworkRecord()
    local selectWorld = Store:get("world/selectWorld")

    if (not selectWorld) then
        return false
    end

    local foldername = selectWorld.foldername
    KeepworkService.deleteWorld(
        foldername,
        function(data, err)
            if (err == 204 or err == 200) then
                DeleteWorld.DeleteWorldMd()
            end
        end
    )
end

function DeleteWorld.DeleteWorldMd()
    local selectWorld = Store:get("world/selectWorld")
    local userinfo = Store:get("user/userinfo")
    local dataSourceInfo = Store:get("user/dataSourceInfo")

    if (not selectWorld or not userinfo or not dataSourceInfo) then
        return false
    end

    local foldername = selectWorld.foldername

    if (dataSourceInfo.dataSourceType == "github") then
    elseif (dataSourceInfo.dataSourceType == "gitlab") then
        GitService:getProjectIdByName(
            foldername,
            function(projectId)
                if (projectId) then
                    local path = format("%s/paracraft/world_%s.md", userinfo.username, foldername)

                    GitService:deleteFile(
                        projectId,
                        nil,
                        path,
                        nil,
                        function()
                            LoginWorldList.RefreshCurrentServerList()
                        end
                    )
                else
                    LoginWorldList.RefreshCurrentServerList()
                end
            end
        )
    end
end

function DeleteWorld.DeleteAll()
    DeleteWorld.DeleteLocal(DeleteWorld.DeleteRemote)
end
