--[[
Title: VersionChange
Author(s):  big
Date: 2018.06.25
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local VersionChange = NPL.load("(gl)Mod/WorldShare/cellar/VersionChange/VersionChange.lua")
------------------------------------------------------------
]]
local DeleteWorld = NPL.load("(gl)Mod/WorldShare/cellar/DeleteWorld/DeleteWorld.lua")
local SyncMain = NPL.load("(gl)Mod/WorldShare/cellar/Sync/SyncMain.lua")
local GitService = NPL.load("(gl)Mod/WorldShare/service/GitService.lua")
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")
local LoginMain = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginMain.lua")
local LoginUserInfo = NPL.load("(gl)Mod/WorldShare/cellar/Login/LoginUserInfo.lua")
local MsgBox = NPL.load("(gl)Mod/WorldShare/cellar/Common/MsgBox.lua")

local VersionChange = NPL.export()

function VersionChange:init()
    if (not LoginUserInfo.IsSignedIn()) then
        _guihelper.MessageBox(L"登录后才能继续")
        return false
    end

    self.foldername = Store:get("world/foldername")

    local IsEnterWorld = Store:get("world/IsEnterWorld")

    if (IsEnterWorld) then
        local selectWorld = Store:get("world/selectWorld")
        local enterWorld = Store:get("world/enterWorld")

        if(enterWorld.foldername == selectWorld.foldername) then
            _guihelper.MessageBox(L"不能切换当前编辑的世界")
            return
        end
    end

    MsgBox:Show(L"请稍后...")

    self:GetVersionSource(
        function()
            MsgBox:Close()
            self:ShowPage()
        end
    )
end

function VersionChange:SetPage()
    Store:set('page/VersionChange', document:GetPageCtrl())
end

function VersionChange:ClosePage()
    local VersionChangePage = Store:get('page/VersionChange')

    if (VersionChangePage) then
        VersionChangePage:CloseWindow()
    end
end

function VersionChange:ShowPage()
    local params = Utils:ShowWindow(0, 0, "Mod/WorldShare/cellar/VersionChange/VersionChange.html", "VersionChange", 0, 0, "_fi", false)

    params._page.OnClose = function()
        Store:remove('page/VersionChange')
    end
end

function VersionChange:GetVersionSource(callback)
    self.allRevision = commonlib.vector:new()

    local function GetAllRevision(projectId)
        GitService:getCommits(
            projectId,
            nil,
            true,
            function(data, err)
                for key, item in ipairs(data) do
                    local path = item.title:gsub("keepwork commit: ", "")

                    local date = {}
                    for v in string.gmatch(item.created_at, "[^T]+") do
                        date[#date + 1] = v
                    end

                    if (path == "revision.xml") then
                        local currentRevision = {
                            path = path,
                            commitId = item.id,
                            date = date[1]
                        }

                        self.allRevision:push_back(currentRevision)
                    end
                end

                self:GetRevisionContent(callback)
            end
        )
    end

    GitService:getProjectIdByName(
        self.foldername.base32,
        function(projectId)
            if (not projectId) then
                return false
            end

            GetAllRevision(projectId)
        end
    )
end

local index = 1
function VersionChange:GetRevisionContent(callback)
    if (index > #self.allRevision) then
        index = 1

        if (type(callback) == "function") then
            callback()
        end

        return false
    end

    local currentItem = self.allRevision[index]
    local selectWorld = Store:get("world/selectWorld")
    local commitId = SyncMain:GetCurrentRevisionInfo()

    commitId = commitId and commitId["id"] or ""

    GitService:getContentWithRaw(
        self.foldername.base32,
        currentItem.path,
        currentItem.commitId,
        function(content)
            if (not content) then
                return false
            end

            currentItem.revision = content
            currentItem.shortId = string.sub(currentItem.commitId, 1, 5)

            if (tonumber(selectWorld.revision) == tonumber(currentItem.revision)) then
                currentItem.isActive = true
            else
                currentItem.isActive = false
            end

            if (currentItem.commitId == commitId) then
                currentItem.isActiveFull = true
            else
                currentItem.isActiveFull = false
            end

            index = index + 1
            self:GetRevisionContent(callback)
        end
    )
end

function VersionChange:GetAllRevision()
    return self.allRevision
end

function VersionChange:SelectVersion(index)
    local selectWorld = Store:get("world/selectWorld")
    local foldername = Store:get("world/foldername")
    local commitId = self.allRevision[index]["commitId"]

    Store:set("world/commitId", commitId)
    SyncMain:SetCurrentCommidId(commitId)

    local targetDir = format("%s/%s/", SyncMain.GetWorldFolderFullPath(), foldername.default)

    commonlib.Files.DeleteFolder(targetDir)

    MsgBox:Show(L'请稍后...')

    SyncMain:syncToLocal()

    self:ClosePage()
end