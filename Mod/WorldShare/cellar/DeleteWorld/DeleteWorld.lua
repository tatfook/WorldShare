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

local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")

local DeleteWorld = NPL.export()

function DeleteWorld:ShowPage()
    local myWorldsFolder = Mod.WorldShare.Store:Get('world/myWorldsFolder')
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    local function Show()
        Mod.WorldShare.Utils.ShowWindow(0, 0, "Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.html", "DeleteWorld", 0, 0, "_fi", false)
    end

    local function Handle()
        if KeepworkServiceSession:IsCurrentWorldsFolder() then
            Show()
        else
            if myWorldsFolder == 'worlds/DesignHouse' then
                Mod.WorldShare.MsgBox:Dialog(
                    "DeleteWorld",
                    format(L"是否确认删除本地临时世界文件夹中储存的世界：%s？删除后该世界文件将在本地所有用户临时文件夹世界列表中删除。", currentWorld and currentWorld.foldername or ""),
                    {
                        Yes = L"取消",
                        No = L"确认"
                    },
                    function(res)
                        if res == 4 then
                            Show()
                        end
                    end,
                    _guihelper.MessageBoxButtons.YesNo
                )
            else
                _guihelper.MessageBox(L"无法删除他人本地世界文件夹中储存的世界。")
            end
        end
    end

    if KeepworkService:IsSignedIn() then
        Handle()
    else
        if myWorldsFolder and myWorldsFolder ~= 'worlds/DesignHouse' then
            Mod.WorldShare.MsgBox:Dialog(
                "DeleteWorld",
                L"未登录状态下无法删除世界，请先登录。",
                {
                    Yes = L"取消",
                    No = L"登录"
                },
                function(res)
                    if res == 4 then
                        LoginModal:Init(function(result)
                            if not result then
                                return false
                            end
                            
                            Mod.WorldShare.Store:Set('world/myWorldsFolder', myWorldsFolder)

                            WorldList:RefreshCurrentServerList()
            
                            Handle()
                        end)
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo
            )
        else
            Mod.WorldShare.MsgBox:Dialog(
                "DeleteWorld",
                format(L"是否确认删除本地临时世界文件夹中储存的世界：%s？删除后该世界文件将在本地所有用户临时文件夹世界列表中删除。", currentWorld and currentWorld.foldername or ""),
                {
                    Yes = L"取消",
                    No = L"确认"
                },
                function(res)
                    if res == 4 then
                        Show()
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo
            )
        end
    end
end

function DeleteWorld:SetPage()
    Mod.WorldShare.Store:Set("page/DeleteWorld", document:GetPageCtrl())
end

function DeleteWorld:ClosePage()
    local DeleteWorldPage = Mod.WorldShare.Store:Get("page/DeleteWorld")

    if DeleteWorldPage then
        DeleteWorldPage:CloseWindow()
    end
end

function DeleteWorld.GetSelectWorld()
    return Mod.WorldShare.Store:Get("world/currentWorld")
end

function DeleteWorld:DeleteWorld()
    local isEnterWorld = Mod.WorldShare.Store:Get("world/isEnterWorld")
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")
    local currentEnterWorld = Mod.WorldShare.Store:Get("world/currentEnterWorld")

    if not currentWorld or not currentEnterWorld then
        return false
    end

    if isEnterWorld then
        local worldTag = WorldCommon.GetWorldInfo()

        if currentWorld.worldpath == currentEnterWorld.worldpath and
           GameLogic.IsReadOnly() == currentWorld.is_zip then
            _guihelper.MessageBox(L"不能刪除正在编辑的世界")
            return false
        end
    end

    self:ShowPage()
end

function DeleteWorld:DeleteLocal(callback)
    local currentWorld = Mod.WorldShare.Store:Get("world/currentWorld")

    if not currentWorld then
        GameLogic.AddBBS(nil, L"删除失败", 3000, "255 0 0")
        return false
    end

    local function Delete()
        if not currentWorld.worldpath then
            return false
        end

        if currentWorld.is_zip then
            if ParaIO.DeleteFile(currentWorld.worldpath) then
                if type(callback) == "function" then
                    callback()
                else
                    self:ClosePage()
                    WorldList:RefreshCurrentServerList()
                end
            else
                GameLogic.AddBBS(nil, L"无法删除可能您没有足够的权限", 3000, "255 0 0")
            end
        else
            if GameLogic.RemoveWorldFileWatcher then
                GameLogic.RemoveWorldFileWatcher() -- file watcher may make folder deletion of current world directory not working.
            end

            if commonlib.Files.DeleteFolder(currentWorld.worldpath) then
                if type(callback) == "function" then
                    callback()
                else
                    self:ClosePage()
                    WorldList:RefreshCurrentServerList()
                end
            else
                GameLogic.AddBBS(nil, L"无法删除可能您没有足够的权限", 3000, "255 0 0")
            end
        end
    end

    if currentWorld.status ~= 2 then
        _guihelper.MessageBox(
            format(L"确定删除本地世界:%s?", currentWorld.text or ""),
            function(res)
                if res and res == _guihelper.DialogResult.Yes then
                    Delete()
                end
            end,
            _guihelper.MessageBoxButtons.YesNo
        )
    end
end

function DeleteWorld:DeleteRemote()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    _guihelper.MessageBox(
        format(L"确定删除远程世界(项目):%s?", currentWorld.foldername or ""),
        function(res)
            if res and res == 6 then
                KeepworkServiceProject:RemoveProject(
                    currentWorld.kpProjectId,
                    function(data, err)
                        self:ClosePage()

                        if err ~= 204 and err ~= 200 then
                            GameLogic.AddBBS(nil, format("%s:%d", L"服务器返回错误状态码", err), 3000, "255 0 0")
                        end

                        if currentWorld and currentWorld.worldpath and #currentWorld.worldpath > 0 then
                            local tag = LocalService:GetTag(currentWorld.worldpath)

                            tag.kpProjectId = nil
                            LocalService:SetTag(currentWorld.worldpath, tag)
                            currentWorld.kpProjectId = nil
                            Mod.WorldShare.Store:Set('world/currentWorld')
                        end

                        WorldList:RefreshCurrentServerList()
                    end
                )
            end
        end
    )
end

function DeleteWorld:DeleteAll()
    self:DeleteLocal(
        function()
            self:DeleteRemote()
        end
    )
end
