--[[
Title: DeleteWorld
Author(s):  big
Date: 2018.06.21
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/DeleteWorld.lua")
local DeleteWorld = commonlib.gettable("Mod.WorldShare.login.DeleteWorld")
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/login/LoginWorldList.lua")
NPL.load("(gl)Mod/WorldShare/store/Global.lua")
NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua")
NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
NPL.load("(gl)Mod/WorldShare/helper/GitEncoding.lua")
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua")

local Utils = commonlib.gettable("Mod.WorldShare.helper.Utils")
local LoginWorldList = commonlib.gettable("Mod.WorldShare.login.LoginWorldList")
local GlobalStore = commonlib.gettable("Mod.WorldShare.store.Global")
local KeepworkService = commonlib.gettable("Mod.WorldShare.service.KeepworkService")
local LoginMain = commonlib.gettable("Mod.WorldShare.login.LoginMain")
local GitService = commonlib.gettable("Mod.WorldShare.service.GitService")
local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding")
local WorldCommon    = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

local DeleteWorld = commonlib.gettable("Mod.WorldShare.login.DeleteWorld")

DeleteWorld.DeletePage = nil

function DeleteWorld.ShowDeleteWorldPage()
    Utils:ShowWindow(0, 0, "Mod/WorldShare/login/DeleteWorld.html", "DeleteWorld", 0, 0, "_fi", false)
end

function DeleteWorld.setDeletePage()
    DeleteWorld.DeletePage = document:GetPageCtrl()
end

function DeleteWorld.closeDeletePage()
    if (DeleteWorld.DeletePage) then
        DeleteWorld.DeletePage:CloseWindow()
    end
end

function DeleteWorld.GetSelectWorld()
    return GlobalStore.get("selectWorld")
end

function DeleteWorld.DeleteWorld()
    local IsEnterWorld = GlobalStore.get("IsEnterWorld")
    
    if (IsEnterWorld) then
        local selectWorld = GlobalStore.get("selectWorld")
        local enterWorld = GlobalStore.get("enterWorld")

        if(enterWorld.foldername == selectWorld.foldername) then
            _guihelper.MessageBox(L"不能刪除正在编辑的世界")
            return
        end
    end

    DeleteWorld.ShowDeleteWorldPage()
end

function DeleteWorld.DeleteLocal()
    local selectWorld = GlobalStore.get("selectWorld")

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
--     local selectWorld = GlobalStore.get("selectWorld")
--     local zipPath = selectWorld.localpath

--     if (ParaIO.DeleteFile(zipPath)) then
--         LoginWorldList.RefreshCurrentServerList()
--     else
--         _guihelper.MessageBox(L"无法删除可能您没有足够的权限")
--     end

--     DeleteWorld.closeDeletePage()
-- end

function DeleteWorld.DeleteRemote()
    local dataSourceInfo = GlobalStore.get("dataSourceInfo")

    if (dataSourceInfo.dataSourceType == "github") then
        DeleteWorld.DeleteGithub()
    elseif (dataSourceInfo.dataSourceType == "gitlab") then
        DeleteWorld.DeleteGitlab()
    end
end

function DeleteWorld.DeleteGitlab()
    local selectWorld = GlobalStore.get("selectWorld")
    local foldername = selectWorld.foldername

    _guihelper.MessageBox(
        format(L"确定删除Gitlab远程世界:%s?", foldername or ""),
        function(res)
            DeleteWorld.closeDeletePage()
            LoginMain.setPageRefreshing(true)

            if (res and res == 6) then
                GitService:new():getProjectIdByName(
                    GitEncoding.base32(foldername),
                    function(projectId)
                        if (projectId) then
                            GitService:new():deleteResp(
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
    local selectWorld = GlobalStore.get("selectWorld")
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
    local selectWorld = GlobalStore.get("selectWorld")
    local userinfo = GlobalStore.get("userinfo")
    local foldername = selectWorld.foldername

    local dataSourceInfo = GlobalStore.get("dataSourceInfo")

    if (dataSourceInfo.dataSourceType == "github") then
    elseif (dataSourceInfo.dataSourceType == "gitlab") then
        GitService:new():getProjectIdByName(
            foldername,
            function(projectId)
                if (projectId) then
                    local path = format("%s/paracraft/world_%s.md", userinfo.username, foldername)

                    GitService:new():deleteFile(
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
