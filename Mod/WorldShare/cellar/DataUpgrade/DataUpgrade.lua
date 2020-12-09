--[[
Title: DataUpgrade
Author(s):  big
Date: 2020.11.23
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local DataUpgrade = NPL.load("(gl)Mod/WorldShare/cellar/DataUpgrade/DataUpgrade.lua")
------------------------------------------------------------
]]

-- service
local LocalService = NPL.load("(gl)Mod/WorldShare/service/LocalService.lua")
local KeepworkServiceProject = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Project.lua")
local HttpRequest = NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua")

local DataUpgrade = NPL.export()

DataUpgrade.ver = 1
DataUpgrade.lockFile = 'upgrade.lock'

function DataUpgrade:Init()
    if not ParaIO.DoesFileExist(self.lockFile) then
        -- generate lock file
        self:SetLockFile({status = 'Started'})
    end

    local contentTable = self:GetLockFile()

    if not contentTable.ver or
       type(contentTable.ver) ~= 'number' or
       contentTable.ver > self.ver then
        return
    end

    if contentTable.status == 'Finished' then
        return
    end

    if contentTable.status == 'Progressing' then
        Mod.WorldShare.MsgBox:Show(
            L'上次没有完成数据迁移，必须完成完成数据迁移后才能继续使用，5秒后将继续数据迁移...',
            nil,
            nil,
            600,
            400
        )
        Mod.WorldShare.Utils.SetTimeOut(function()
            Mod.WorldShare.MsgBox:Close()
            self:Exec()
        end, 5000)
        return
    end

    self:Exec()
end

function DataUpgrade:GetLockFile()
    local content = LocalService:GetFileContent(self.lockFile)
    local contentTable = {}

    if not content or type(content) ~= 'string' or #content == 0 then
        return contentTable
    end

    NPL.FromJson(content, contentTable)

    return contentTable or {}
end

function DataUpgrade:SetLockFile(lockFileTable)
    if not lockFileTable or type(lockFileTable) ~= 'table' then
        return false
    end

    lockFileTable.ver = self.ver

    local write = ParaIO.open(self.lockFile, "w")
    local content = NPL.ToJson(lockFileTable)
    write:write(content, #content)
    write:close()
end

DataUpgrade.checkList = {
    'CheckNetwork',
    'BackupAllWorlds',
    'RenameAllWorlds',
    'RemoveOldWorldFolders'
}

function DataUpgrade:Exec()
    local params = Mod.WorldShare.Utils.ShowWindow(600, 400, "(ws)DataUpgrade", "Mod.WorldShare.DataUpgrade", nil, nil, nil, false)

    Mod.WorldShare.Utils.SetTimeOut(function()
        if self.inited then
            return
        end

        self.inited = true
        self:SetLockFile({status = 'Progressing'})

        self:ExecuteList(1, function()
            self:SetLockFile({status = 'Finished'})

            self.mainMsg = L"迁移数据完成"
            self:Refresh()

            Mod.WorldShare.Utils.SetTimeOut(function()
                if params and params._page then
                    params._page:CloseWindow()
                end
            end, 1000)
        end)
    end, 5000)
end

function DataUpgrade:Refresh()
    local DataUpgradePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.DataUpgrade')

    if DataUpgradePage then
        DataUpgradePage:Refresh(0.01)
    end
end

function DataUpgrade:ExecuteList(step, callback)
    if not step or type(step) ~= 'number' then
        step = 1
    end

    local execFinished = false
    local timer = commonlib.Timer:new(
        {
            callbackFunc = function(timer)
                if not execFinished then
                    execFinished = true

                    if not self.checkList[step] or not self[self.checkList[step]] then
                        timer:Change(nil, nil)

                        if callback and type(callback) == 'function' then
                            callback()
                        end
                        return
                    end

                    self[self.checkList[step]](self, function()
                        step = step + 1
                        execFinished = false
                    end)
                end
            end
        }
    )

    timer:Change(0, 200)
end

function DataUpgrade:CheckNetwork(callback)
    if not callback or type(callback) ~= 'function' then
        return
    end

    -- the http request for check network.
    HttpRequest:Get(
        'http://tmlog.paraengine.com/version.php',
        nil,
        nil,
        function(data, err)
            if err ~= 200 then
                self.mainMsg = L"网络无法连接，请连接网络后再试"
                self:Refresh()
                return
            end

            callback()
        end
    )
end

function DataUpgrade:BackupAllWorlds(backUpCallback)
    self.mainMsg = L"正在备份您的数据，请稍后..."
    self:Refresh()

    -- find mine world
    local findMineWorlds = LocalService:Find('worlds/DesignHouse/')
    local mineWorlds = {}

    if findMineWorlds and type(findMineWorlds) == 'table' then
        for key, item in ipairs(findMineWorlds) do
            if item and
               item.fileattr == 16 and
               item.filename ~= 'userworlds' and
               item.filename ~= '_shared' and
               not string.match(item.filename, '_main') then
                mineWorlds[#mineWorlds + 1] = item.filename .. '/'
            end
        end
    end

    -- find shared world
    local sharedRootPath = 'worlds/DesignHouse/_shared/'
    local findSharedWorlds = LocalService:Find(sharedRootPath)
    local sharedWorlds = {}

    if findSharedWorlds and type(findSharedWorlds) == 'table' then
        for key, item in ipairs(findSharedWorlds) do
            if item and
               item.fileattr == 16 then
                local sharedUserPath = sharedRootPath .. item.filename .. '/'
                local findSharedUserWorlds = LocalService:Find(sharedUserPath)

                if findSharedUserWorlds and type(findSharedUserWorlds) == 'table' then
                    for fKey, fItem in ipairs(findSharedUserWorlds) do
                        sharedWorlds[#sharedWorlds + 1] = item.filename .. '/' .. fItem.filename .. '/'
                    end
                end
            end
        end
    end

    local function CopyWorld(path, destPath, callback)
        local copyIndex = 1
        local currentWorldFiles = {}

        local function CopyFile()
            local copyFile = currentWorldFiles[copyIndex]

            if copyFile and copyFile.src and copyFile.dest then
                ParaIO.CopyFile(copyFile.src, copyFile.dest, true)
                self.subtitleMsg = format(
                    L'正在复制：%s 到 %s',
                    commonlib.Encoding.DefaultToUtf8(copyFile.src),
                    commonlib.Encoding.DefaultToUtf8(copyFile.dest)
                )
                self:Refresh()
            end
        end

        local function FindAllCurrentWorldFiles(path, destPath)
            local findCurrentWorldFiles = LocalService:Find(path)

            for key, item in ipairs(findCurrentWorldFiles) do
                if item and item.fileattr == 32 then
                    currentWorldFiles[#currentWorldFiles + 1] = {
                        src = path .. item.filename,
                        dest = destPath .. item.filename
                    }
                end

                if item and item.fileattr == 16 then
                    ParaIO.CreateDirectory(destPath .. item.filename .. '/')
                    FindAllCurrentWorldFiles(path .. item.filename .. '/', destPath .. item.filename .. '/')
                end
            end
        end

        local tag = LocalService:GetTag(path)

        if tag and type(tag) == 'table' and tag.upgrade_ver then
            if callback and type(callback) == 'function' then
                callback()
            end
            return
        end

        ParaIO.CreateDirectory(destPath)
        FindAllCurrentWorldFiles(path, destPath)

        local timer = commonlib.Timer:new(
            {
                callbackFunc = function(timer)
                    if not currentWorldFiles[copyIndex] then
                        timer:Change(nil, nil)

                        if callback and type(callback) == 'function' then
                            callback()
                        end

                        return
                    end

                    CopyFile()
                    copyIndex = copyIndex + 1
                end
            }
        )

        timer:Change(0, 20)
    end

    -- copy mine worlds
    local mineWorldsIndex = 1
    local function CopyMineWorlds(callback)
        local execFinished = false
        local timer = commonlib.Timer:new(
            {
                callbackFunc = function(timer)
                    if not execFinished then
                        execFinished = true

                        local filename = mineWorlds[mineWorldsIndex]

                        if not filename then
                            timer:Change(nil, nil)

                            if callback and type(callback) == 'function' then
                                callback()
                            end
                            return
                        end

                        CopyWorld(
                            'worlds/DesignHouse/' .. filename,
                            'temp/backup_worlds/' .. filename,
                            function()
                                mineWorldsIndex = mineWorldsIndex + 1
                                execFinished = false
                            end
                        )
                    end
                end
            }
        )

        timer:Change(0, 200)
    end

    -- copy shared worlds
    local sharedWorldsIndex = 1
    local function CopySharedWorlds(callback)
        local execFinished = false
        local timer = commonlib.Timer:new(
            {
                callbackFunc = function(timer)
                    if not execFinished then
                        execFinished = true

                        local filename = sharedWorlds[sharedWorldsIndex]

                        if not filename then
                            timer:Change(nil, nil)

                            if callback and type(callback) == 'function' then
                                callback()
                            end
                            return
                        end

                        CopyWorld(
                            'worlds/DesignHouse/_shared/' .. filename,
                            'temp/backup_worlds/_shared/' .. filename,
                            function()
                                sharedWorldsIndex = sharedWorldsIndex + 1
                                execFinished = false
                            end
                        )
                    end
                end
            }
        )

        timer:Change(0, 200)
    end

    ParaIO.CreateDirectory('temp/backup_worlds/')
    CopyMineWorlds(function()
        CopySharedWorlds(function()
            if backUpCallback and type(backUpCallback) == 'function' then
                backUpCallback()
            end
        end)
    end)
end

function DataUpgrade:RenameAllWorlds(callback)
    self.mainMsg = L'正在迁移世界，请勿关闭程序...'
    self:Refresh()

    -- find mine worlds
    local findMineWorlds = LocalService:Find('worlds/DesignHouse/')
    local mineWorlds = {}

    if findMineWorlds and type(findMineWorlds) == 'table' then
        for key, item in ipairs(findMineWorlds) do
            if item and
               item.fileattr == 16 and
               item.filename ~= 'userworlds' and
               item.filename ~= '_shared' and
               not string.match(item.filename, '_main') then
                mineWorlds[#mineWorlds + 1] = item.filename
            end
        end
    end

    -- find shared worlds
    local sharedRootPath = 'worlds/DesignHouse/_shared/'
    local findSharedWorlds = LocalService:Find(sharedRootPath)
    local sharedWorlds = {}

    if findSharedWorlds and type(findSharedWorlds) == 'table' then
        for key, item in ipairs(findSharedWorlds) do
            if item and
               item.fileattr == 16 then
                local sharedUserPath = sharedRootPath .. item.filename .. '/'
                local findSharedUserWorlds = LocalService:Find(sharedUserPath)

                if findSharedUserWorlds and type(findSharedUserWorlds) == 'table' then
                    for fKey, fItem in ipairs(findSharedUserWorlds) do
                        sharedWorlds[#sharedWorlds + 1] = item.filename .. '/' .. fItem.filename
                    end
                end
            end
        end
    end

    local function MoveWorld(root, filename, callback)
        local currentWorldFiles = {}
        local isShared = false
        local newFilename = ''
        local moveFileIndex = 1

        if root == 'worlds/DesignHouse/_shared/' then
            isShared = true
        end

        local oldTag = LocalService:GetTag(root .. filename .. '/')
        local oldProjectData = {}

        -- ignore upgraded world
        if not oldTag or not oldTag.name or oldTag.upgrade_ver then
            if callback and type(callback) == 'function' then
                callback()
            end

            return
        end

        local function MoveFile(finishFun)
            local currentFile = currentWorldFiles[moveFileIndex]

            if not currentFile then
                return
            end

            -- move file
            ParaIO.MoveFile(currentFile.src, currentFile.dest)
            self.subtitleMsg = format(
                L'正在移动：%s 到 %s',
                commonlib.Encoding.DefaultToUtf8(currentFile.src),
                commonlib.Encoding.DefaultToUtf8(currentFile.dest)
            )
            self:Refresh()

            -- handle tag file
            if string.match(currentFile.dest, 'tag.xml$') then
                -- add upgrade_ver to tag.xml
                local newWorldpath = root .. newFilename .. '/'
                local tag = LocalService:GetTag(newWorldpath)

                if tag and type(tag) == 'table' then
                    tag.upgrade_ver = self.ver

                    if isShared then
                        tag.seed = commonlib.Encoding.DefaultToUtf8(string.match(filename, "^%w+%/(.+)"))
                    else
                        tag.seed = commonlib.Encoding.DefaultToUtf8(filename)
                    end
                end

                if tag and type(tag) == 'table' and tag.kpProjectId then
                    if not oldProjectData or type(oldProjectData) ~= 'table' or not oldProjectData.username or not oldProjectData.userId then
                        LocalService:SetTag(newWorldpath, tag)

                        moveFileIndex = moveFileIndex + 1
                        if finishFun and type(finishFun) == 'function' then
                            finishFun()
                        end

                        return
                    end

                    tag.username = oldProjectData.username
                    tag.user_id = oldProjectData.userId

                    LocalService:SetTag(newWorldpath, tag)

                    moveFileIndex = moveFileIndex + 1
                    if finishFun and type(finishFun) == 'function' then
                        finishFun()
                    end
                else
                    LocalService:SetTag(newWorldpath, tag)

                    moveFileIndex = moveFileIndex + 1
                    if finishFun and type(finishFun) == 'function' then
                        finishFun()
                    end
                end

                return
            end

            moveFileIndex = moveFileIndex + 1
            if finishFun and type(finishFun) == 'function' then
                finishFun()
            end
        end

        local function FindAllCurrentWorldFiles(path, destPath)
            local findCurrentWorldFiles = LocalService:Find(path)

            for key, item in ipairs(findCurrentWorldFiles) do
                if item and item.fileattr == 32 then
                    currentWorldFiles[#currentWorldFiles + 1] = {
                        src = path .. item.filename,
                        dest = destPath .. item.filename
                    }
                end

                if item and item.fileattr == 16 then
                    ParaIO.CreateDirectory(destPath .. item.filename .. '/')
                    FindAllCurrentWorldFiles(
                        path .. item.filename .. '/',
                        destPath .. item.filename .. '/'
                    )
                end
            end
        end

        local execFinished = false
        local timer = commonlib.Timer:new(
            {
                callbackFunc = function(timer)
                    if not execFinished then
                        execFinished = true

                        local currentFile = currentWorldFiles[moveFileIndex]

                        if not currentFile then
                            if callback and type(callback) == 'function' then
                                callback()
                            end
                            return
                        end

                        MoveFile(function()
                            execFinished = false
                        end)
                    end
                end
            }
        )

        if oldTag and type(oldTag) == 'table' and oldTag.kpProjectId then
            -- get uuid from api if world has project id.
            KeepworkServiceProject:GetProject(oldTag.kpProjectId, function(data, err)
                if err ~= 200 or not data or not data.world or not data.world.uuid then
                    newFilename = filename .. '_' .. System.Encoding.guid.uuid()

                    ParaIO.CreateDirectory(root .. newFilename .. '/')

                    FindAllCurrentWorldFiles(
                        root .. filename .. '/',
                        root .. newFilename .. '/'
                    )

                    timer:Change(0, 10)
                    return
                end

                oldProjectData = data
                newFilename = filename .. '_' .. data.world.uuid

                ParaIO.CreateDirectory(root .. newFilename .. '/')

                FindAllCurrentWorldFiles(
                    root .. filename .. '/',
                    root .. newFilename .. '/'
                )

                timer:Change(0, 10)
            end)
        else
            newFilename = filename .. '_' .. System.Encoding.guid.uuid()

            ParaIO.CreateDirectory(root .. newFilename .. '/')

            FindAllCurrentWorldFiles(
                root .. filename .. '/',
                root .. newFilename .. '/'
            )

            timer:Change(0, 10)
        end
    end

    -- move mine worlds
    local mineWorldsIndex = 1
    local function MoveMineWorlds(callback)
        local execFinished = false
        local timer = commonlib.Timer:new(
            {
                callbackFunc = function(timer)
                    if not execFinished then
                        execFinished = true

                        local filename = mineWorlds[mineWorldsIndex]

                        if not filename then
                            timer:Change(nil, nil)

                            if callback and type(callback) == 'function' then
                                callback()
                            end
                            return
                        end

                        MoveWorld(
                            'worlds/DesignHouse/',
                            filename,
                            function()
                                mineWorldsIndex = mineWorldsIndex + 1
                                execFinished = false
                            end
                        )
                    end
                end
            }
        )

        timer:Change(0, 200)
    end

    -- move shared worlds
    local sharedWorldsIndex = 1
    local function MoveSharedWorlds(callback)
        local execFinished = false
        local timer = commonlib.Timer:new(
            {
                callbackFunc = function(timer)
                    if not execFinished then
                        execFinished = true

                        local filename = sharedWorlds[sharedWorldsIndex]

                        if not filename then
                            timer:Change(nil, nil)

                            if callback and type(callback) == 'function' then
                                callback()
                            end
                            return
                        end

                        MoveWorld(
                            'worlds/DesignHouse/_shared/',
                            filename,
                            function()
                                sharedWorldsIndex = sharedWorldsIndex + 1
                                MoveSharedWorlds(callback)
                            end
                        )
                    end
                end
            }
        )

        timer:Change(0, 200)
    end

    MoveMineWorlds(function()
        MoveSharedWorlds(function()
            if callback and type(callback) == 'function' then
                callback()
            end
        end)
    end)
end

function DataUpgrade:RemoveOldWorldFolders(callback)
    self.mainMsg = L"正在删除旧数据，请勿关闭程序..."
    self:Refresh()

    -- find mine worlds
    local findMineWorlds = LocalService:Find('worlds/DesignHouse/')
    local mineOldWorldFolders = {}

    if findMineWorlds and type(findMineWorlds) == 'table' then
        for key, item in ipairs(findMineWorlds) do
            if item and
               item.fileattr == 16 and
               item.filename ~= 'userworlds' and
               item.filename ~= '_shared' and
               not string.match(item.filename, '_main') then
                mineOldWorldFolders[#mineOldWorldFolders + 1] = item.filename
            end
        end
    end

    if not mineOldWorldFolders or
       type(mineOldWorldFolders) ~= 'table' or
       #mineOldWorldFolders == 0 then
        if callback and type(callback) == 'function' then
            callback()
        end
    end

    -- remove mine world folders
    for key, item in ipairs(mineOldWorldFolders) do
        local worldpath = 'worlds/DesignHouse/' .. item .. '/'
        local tag = LocalService:GetTag(worldpath)

        if not tag or type(tag) ~= 'table' or not tag.upgrade_ver then
            ParaIO.DeleteFile(worldpath)
        end
    end

    -- find shared worlds
    local sharedRootPath = 'worlds/DesignHouse/_shared/'
    local findSharedWorlds = LocalService:Find(sharedRootPath)
    local sharedOldWorldFolders = {}

    if findSharedWorlds and type(findSharedWorlds) == 'table' then
        for key, item in ipairs(findSharedWorlds) do
            if item and
               item.fileattr == 16 then
                local sharedUserPath = sharedRootPath .. item.filename .. '/'
                local findSharedUserWorlds = LocalService:Find(sharedUserPath)

                if findSharedUserWorlds and type(findSharedUserWorlds) == 'table' then
                    for fKey, fItem in ipairs(findSharedUserWorlds) do
                        sharedOldWorldFolders[#sharedOldWorldFolders + 1] = item.filename .. '/' .. fItem.filename
                    end
                end
            end
        end
    end

    -- remove shared world folders
    for key, item in ipairs(sharedOldWorldFolders) do
        local worldpath = 'worlds/DesignHouse/_shared/' .. item .. '/'
        local tag = LocalService:GetTag(worldpath)

        if not tag or type(tag) ~= 'table' or not tag.upgrade_ver then
            ParaIO.DeleteFile(worldpath)
        end
    end

    if callback and type(callback) == 'function' then
        callback()
    end
end
