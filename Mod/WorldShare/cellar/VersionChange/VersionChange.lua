--[[
Title: VersionChange
Author(s): big
CreateDate: 2018.06.25
ModifyDate: 2021.12.09
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local VersionChange = NPL.load('(gl)Mod/WorldShare/cellar/VersionChange/VersionChange.lua')
------------------------------------------------------------
]]

-- bottles
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')

-- service
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')

local Encoding = commonlib.gettable('commonlib.Encoding')

local VersionChange = NPL.export()

function VersionChange:Init(foldername, callback)
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end

    if callback then
        self.callback = callback
    end

    local isEnterWorld = Mod.WorldShare.Store:Get('world/isEnterWorld')
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if isEnterWorld then
        if currentWorld.foldername == currentEnterWorld.foldername and
           currentWorld.shared == currentEnterWorld.shared and
           currentWorld.is_zip == currentEnterWorld.is_zip then
            if KeepworkServiceSession:IsSignedIn() then
                if currentWorld.shared then
                    if currentWorld.kpProjectId == currentEnterWorld.kpProjectId then
                        _guihelper.MessageBox(L'不能切换当前编辑的世界')
                        return
                    end
                else
                    _guihelper.MessageBox(L'不能切换当前编辑的世界')
                    return
                end
            else
                _guihelper.MessageBox(L'不能切换当前编辑的世界')
                return
            end
        end
    end

    if not currentWorld.status then
        _guihelper.MessageBox(L'此世界仅在本地，无需切换版本')
        return
    end

    Mod.WorldShare.MsgBox:Wait()

    self.foldername = foldername

    self:GetVersionSource(
        function()
            Mod.WorldShare.MsgBox:Close()
            self:ShowPage()
        end
    )
end

function VersionChange:SetPage()
    Mod.WorldShare.Store:Set('page/Mod.WorldShare.VersionChange', document:GetPageCtrl())
end

function VersionChange:ClosePage()
    local VersionChangePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.VersionChange')

    if VersionChangePage then
        VersionChangePage:CloseWindow()
    end
end

function VersionChange:ShowPage()
    local params = Mod.WorldShare.Utils.ShowWindow(
                    0,
                    0,
                    'Mod/WorldShare/cellar/VersionChange/VersionChange.html',
                    'Mod.WorldShare.VersionChange',
                    0,
                    0,
                    '_fi',
                    false
                )

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/Mod.WorldShare.VersionChange')
    end
end

function VersionChange:GetVersionSource(callback)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local commitId = SyncWorld:GetCurrentRevisionInfo() or {}

    if not currentWorld then
        return false
    end

    self.allRevision = commonlib.vector:new()

    KeepworkServiceWorld:GetWorld(
        self.foldername,
        currentWorld.shared,
        currentWorld.user.id,
        function(world)
            if type(callback) ~= 'function' then
                return false
            end

            if not world or not world.extra or not world.extra.commitIds then
                callback()
                return false
            end

            for key, item in ipairs(world.extra.commitIds) do
                item.shortId = string.sub(item.commitId, 1, 5)

                if tonumber(currentWorld.revision) == tonumber(item.revision) then
                    item.isActive = true
                else
                    item.isActive = false
                end

                if item.commitId == commitId.id then
                    item.isActiveFull = true
                else
                    item.isActiveFull = false
                end

                self.allRevision:push_front(item)
            end

            callback()
        end
    )
end

function VersionChange:GetAllRevision()
    return self.allRevision
end

function VersionChange:SelectVersion(index)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')
    local commitId = self.allRevision[index]['commitId']

    local targetDir = format(
                        '%s/%s/',
                        Mod.WorldShare.Utils.GetWorldFolderFullPath(),
                        commonlib.Encoding.Utf8ToDefault(currentWorld.foldername)
                      )

    commonlib.Files.DeleteFolder(targetDir)
    ParaIO.CreateDirectory(targetDir)

    currentWorld.status = 2
    currentWorld.lastCommitId = commitId
    Mod.WorldShare.Store:Set('world/currentWorld', currentWorld)

    SyncWorld:SyncToLocalSingle(function(result, msg)
        if result == false then
            if msg == 'NEWWORLD' then
                return false
            end

            GameLogic.AddBBS(nil, msg, 3000, '255 0 0')
        end

        if self.callback and type(self.callback) == 'function' then
            self.callback()
        end
    end)

    self:ClosePage()
end