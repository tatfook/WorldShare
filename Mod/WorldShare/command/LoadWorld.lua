--[[
Title: Load World Command
Author(s): big
CreateDate: 2020.10.09
ModifyDate: 2021.09.23
Desc: 
use the lib:
------------------------------------------------------------
local LoadWorldCommand = NPL.load('(gl)Mod/WorldShare/command/LoadWorld.lua')
-------------------------------------------------------
]]

-- bottles
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')

-- service
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local GitKeepworkService = NPL.load('(gl)Mod/WorldShare/service/GitService/GitKeepworkService.lua')

-- libs
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local CmdParser = commonlib.gettable('MyCompany.Aries.Game.CmdParser')
local DownloadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.DownloadWorld')
local RemoteWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteWorld')

-- command
local WorldShareCommand = NPL.load('(gl)Mod/WorldShare/command/Command.lua')

-- databse
local CacheProjectId = NPL.load('(gl)Mod/WorldShare/database/CacheProjectId.lua')

local LoadWorldCommand = NPL.export()

function LoadWorldCommand:Init()
    -- cmd load world
    GameLogic.GetFilters():add_filter(
        'cmd_loadworld', 
        function(cmdText, options)
            -- a boolean value needs to be returned.

            if options and options.d then
                self:Download(cmdText, options)
                return false
            end

            if options and options.fork then
                self:Fork(cmdText, options)
                return false
            end

            if options and not options.s then
                if cmdText:match('^https?://') then
                    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                    if currentEnterWorld then
                        _guihelper.MessageBox(
                            format(L'即将离开【%s】', currentEnterWorld.name or ''),
                            function(res)
                                if res and res == _guihelper.DialogResult.Yes then
                                    local optionsStr = ''
        
                                    for key, item in pairs(options) do
                                        if key ~= 's' then
                                            optionsStr = optionsStr .. '-' .. key .. ' '
                                        end
                                    end
        
                                    CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmdText)
                                end
                            end,
                            _guihelper.MessageBoxButtons.YesNo
                        )
                    else
                        local optionsStr = ''
        
                        for key, item in pairs(options) do
                            if key ~= 's' then
                                optionsStr = optionsStr .. '-' .. key .. ' '
                            end
                        end

                        CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmdText)
                    end

                    return false
                end

                if cmdText == 'home' then
                    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                    if currentEnterWorld then
                        _guihelper.MessageBox(
                            format(L'即将离开【%s】进入【%s】', currentEnterWorld.name or '', L'家园'),
                            function(res)
                                if res and res == _guihelper.DialogResult.Yes then
                                    local optionsStr = ''
        
                                    for key, item in pairs(options) do
                                        if key ~= 's' then
                                            optionsStr = optionsStr .. '-' .. key .. ' '
                                        end
                                    end
        
                                    CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmdText)
                                end
                            end,
                            _guihelper.MessageBoxButtons.YesNo
                        )
                    else
                        CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmdText)
                    end

                    return false
                end

                if cmdText == 'back' then
                    local lastWorld = Mod.WorldShare.Store:Get('world/lastWorld')

                    if not lastWorld then
                        _guihelper.MessageBox(L'没有上一级的世界了')
                        return
                    end

                    _guihelper.MessageBox(
                        format(L'是否返回世界：%s？', lastWorld.text or ''),
                        function(res)
                            if res and res == _guihelper.DialogResult.Yes then
                                CommandManager:RunCommand('/loadworld -s back')
                            end
                        end,
                        _guihelper.MessageBoxButtons.YesNo
                    )
                    return false
                end

                local pid = string.match(cmdText, '^%s-(%d+)%s-$')
                if pid then
                    local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(tonumber(pid))

                    if (System.options.loginmode == 'offline' or options.e) and
                       cacheWorldInfo then
                        local optionsStr = ''
    
                        for key, item in pairs(options) do
                            if key ~= 's' then
                                optionsStr = optionsStr .. '-' .. key .. ' '
                            end
                        end

                        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                        if currentEnterWorld and cacheWorldInfo and cacheWorldInfo.worldName then
                            local remoteWorldName = ''

                            if cacheWorldInfo and cacheWorldInfo.extra and cacheWorldInfo.extra.worldTagName then
                                remoteWorldName = cacheWorldInfo.extra.worldTagName
                            else
                                remoteWorldName = cacheWorldInfo.name
                            end

                            _guihelper.MessageBox(
                                format(L'即将离开【%s】进入【%s】', currentEnterWorld.name or '', remoteWorldName or ''),
                                function(res)
                                    if res and res == _guihelper.DialogResult.Yes then
                                        CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmdText)
                                    end
                                end,
                                _guihelper.MessageBoxButtons.YesNo
                            )
                        else
                            CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmdText)
                        end

                        return false
                    end

                    Mod.WorldShare.MsgBox:Wait()
                    KeepworkServiceProject:GetProject(pid, function(data, err)
                        Mod.WorldShare.MsgBox:Close()
                        if err ~= 200 or not data or type(data) ~='table' or not data.name then
                            GameLogic.AddBBS(nil, L'加载世界失败，无法在服务器找到该资源', 3000, '255 0 0')
                            return
                        end

                        local optionsStr = ''

                        for key, item in pairs(options) do
                            if key ~= 's' then
                                optionsStr = optionsStr .. '-' .. key .. ' '
                            end
                        end

                        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                        if currentEnterWorld then
                            local remoteWorldName = ''

                            if data and data.extra and data.extra.worldTagName then
                                remoteWorldName = data.extra.worldTagName
                            else
                                remoteWorldName = data.name
                            end

                            _guihelper.MessageBox(
                                format(L'即将离开【%s】进入【%s】', currentEnterWorld.name or '', remoteWorldName or ''),
                                function(res)
                                    if res and res == _guihelper.DialogResult.Yes then
                                        CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmdText)
                                    end
                                end,
                                _guihelper.MessageBoxButtons.YesNo
                            )
                        else
                            CommandManager:RunCommand('/loadworld -s ' .. optionsStr .. cmdText)
                        end
                    end)

                    return false
                end
            end

            if cmdText == 'home' then
                return cmdText
            end

            if cmdText:match('^https?://') then
                return cmdText
            end

            if cmdText:match('^worlds/DesignHouse/') then
                return cmdText
            end

            if cmdText == 'back' then
                local lastWorld = Mod.WorldShare.Store:Get('world/lastWorld')

                if not lastWorld then
                    _guihelper.MessageBox(L'没有上一级的世界了')
                    return
                end

                if lastWorld.kpProjectId and lastWorld.kpProjectId ~= 0 then
                    local userId = Mod.WorldShare.Store:Get('user/userId')

                    if tonumber(lastWorld.user.id) == tonumber(userId) then
                        GameLogic.RunCommand(format('/loadworld -s -personal %d', lastWorld.kpProjectId))
                    else
                        GameLogic.RunCommand(format('/loadworld -s -force %d', lastWorld.kpProjectId))
                    end
                else
                    WorldCommon.OpenWorld(lastWorld.worldpath)
                end

                return false
            end

            if options and options.personal then
                CommandManager:RunCommand('/loadpersonalworld ' .. cmdText)
                return false
            end

            local pid = string.match(cmdText, '^%s-(%d+)%s-$')

            if not pid then
                return false
            end

            local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(tonumber(pid))

            if options and options.e and cacheWorldInfo then
                CommonLoadWorld:EnterCacheWorldById(pid)
                return
            end

            if options and options.inplace then
                local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                local command = string.match(cmdText, '|[ ]+(%/[%w]+)[ ]+')
                if command == '/sendevent' then
                    local execCommand = string.match(cmdText, '|[ ]+(%/[%w]+[ ]+[ {}=_\',%w]+)$')
                    local event = string.match(cmdText, '|[ ]+%/[%w]+[ ]+([%w]+)')

                    if currentEnterWorld and
                       type(currentEnterWorld) == 'table' and
                       currentEnterWorld.kpProjectId and
                       currentEnterWorld.kpProjectId ~= 0 and
                       tonumber(pid) == tonumber(currentEnterWorld.kpProjectId) then
                        if string.match(event, '^global') then
                            GameLogic.RunCommand(execCommand or '')
                        end
                    else
                        if string.match(event, '^global') then
                            WorldShareCommand:PushAfterLoadWorldCommand(execCommand or '')
                        end

                        if options and options.force then
                            CommandManager:RunCommand('/loadworld -s -force ' .. pid)
                        else
                            CommandManager:RunCommand('/loadworld -s ' .. pid)
                        end
                    end
                end
                return false
            end

            local refreshMode = nil
            local failed = nil

            if options and options.force then
                refreshMode = 'force'
            end

            if options and options.failed then
                failed = true
            end

            -- enter read only world
            CommonLoadWorld:EnterWorldById(pid, refreshMode, failed)

            return false
        end
    )
end

function LoadWorldCommand:Fork(cmdText, options)
    local projectId, worldName = string.match(cmdText, '^(%w+)[ ]+(.+)$')

    if not projectId or not worldName or type(tonumber(projectId)) ~= 'number' then
        return
    end

    projectId = tonumber(projectId)

    local worldPath = 'worlds/DesignHouse/' .. commonlib.Encoding.Utf8ToDefault(worldName)
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if ParaIO.DoesFileExist(worldPath .. '/tag.xml', false) then
        local tag = LocalService:GetTag(worldPath)

        if not tag or type(tag) ~= 'table' or not tag.name then
            return
        end

        if options.s then
            WorldCommon.OpenWorld(worldPath, true)
        else
            _guihelper.MessageBox(
                format(L'即将离开【%s】进入【%s】', currentEnterWorld.text, tag.name),
                function(res)
                    if res and res == _guihelper.DialogResult.Yes then
                        WorldCommon.OpenWorld(worldPath, true)
                    end
                end,
                _guihelper.MessageBoxButtons.YesNo
            )
        end

        return
    end

    Mod.WorldShare.MsgBox:Show(L'请稍候...')

    KeepworkServiceProject:GetProject(projectId, function(data, err)
        if not data or
           type(data) ~= 'table' or
           not data.name or
           not data.username or
           not data.world or
           not data.world.commitId then
            return
        end

        LocalServiceWorld:DownLoadZipWorld(
            data.name,
            data.username,
            data.world.commitId,
            worldPath .. '/',
            function()
                local tag = LocalService:GetTag(worldPath)
                
                if not tag and type(tag) ~= 'table' then
                    return
                end

                if not tag.fromProjects then
                    tag.fromProjects = tostring(tag.kpProjectId)
                else
                    tag.fromProjects = tag.fromProjects .. ',' .. tostring(tag.kpProjectId)
                end

                tag.kpProjectId = nil

                if options.replacename then
                    tag.name = worldName
                end

                LocalService:SetTag(worldPath, tag)

                Mod.WorldShare.MsgBox:Close()

                if options.s then
                    WorldCommon.OpenWorld(worldPath, true)
                else
                    _guihelper.MessageBox(
                        format(L'即将离开【%s】进入【%s】', currentEnterWorld.text, data.name),
                        function(res)
                            if res and res == _guihelper.DialogResult.Yes then
                                WorldCommon.OpenWorld(worldPath, true)
                            end
                        end,
                        _guihelper.MessageBoxButtons.YesNo
                    )
                end
            end
        )
    end)
end

function LoadWorldCommand:Download(cmdText, options)
    local kpProjectId = 0

    kpProjectId, cmdText = CmdParser.ParseInt(cmdText)

    if not kpProjectId or type(kpProjectId) ~= 'number' then
        return
    end

    KeepworkServiceProject:GetProject(
        kpProjectId,
        function(data, err)
            if not data or
               type(data) ~= 'table' or
               not data.name or
               not data.username or
               not data.world or
               not data.world.commitId then
                return
            end

            local qiniuZipArchiveUrl = GitKeepworkService:GetQiNiuArchiveUrl(data.name, data.username, data.world.commitId)
            local cdnArchiveUrl = GitKeepworkService:GetCdnArchiveUrl(data.name, data.username, data.world.commitId)
            local tryTimes = 0

            local function Handle(url)
                if not url:match('^https?://') then
                    return
                end

                world = RemoteWorld.LoadFromHref(url, 'self')
                world:SetProjectId(kpProjectId)
    
                local token = Mod.WorldShare.Store:Get('user/token')
                if token then
                    world:SetHttpHeaders({Authorization = format('Bearer %s', token)})
                end

                local localWorldFile = world:GetLocalFileName() or ''
                local encryptWorldFile = string.match(localWorldFile, '(.+)%.zip$') .. '.pkg'

                -- judge commit ID
                local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(kpProjectId)

                if cacheWorldInfo and
                   type(cacheWorldInfo) == 'table' and
                   cacheWorldInfo.worldInfo and
                   cacheWorldInfo.worldInfo.commitId then
                    local qiniuWorld = RemoteWorld.LoadFromHref(qiniuZipArchiveUrl, 'self')
                    qiniuWorld:SetProjectId(kpProjectId)

                    local cdnArchiveWorld = RemoteWorld.LoadFromHref(cdnArchiveUrl, 'self')
                    cdnArchiveWorld:SetProjectId(kpProjectId)

                    local qiniuWorldFile = qiniuWorld:GetLocalFileName() or ''
                    local cdnArchiveWorldFile = cdnArchiveWorld:GetLocalFileName() or ''

                    local encryptQiniuWorldFile = string.match(qiniuWorldFile, '(.+)%.zip$') .. '.pkg'
                    local encryptCdnArchiveWorldFile = string.match(cdnArchiveWorldFile, '(.+)%.zip$') .. '.pkg'

                    if cacheWorldInfo.worldInfo.commitId == data.world.commitId and
                       (ParaIO.DoesFileExist(encryptQiniuWorldFile) or
                        ParaIO.DoesFileExist(encryptCdnArchiveWorldFile)) then
                        LOG.std(nil, 'warn', 'LoadWorldCommand', 'world %s already exists', data.name)
                        return
                    end
                end

                DownloadWorld.ShowPage(url)

                world:DownloadRemoteFile(function(bSucceed, msg)
                    DownloadWorld.Close()

                    if bSucceed then
                        if not ParaIO.DoesFileExist(localWorldFile) then
                            _guihelper.MessageBox(format(L'下载世界失败，请重新尝试几次（项目ID：%d）', kpProjectId))

                            LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file not exist: %s', localWorldFile)
                            return
                        end

                        ParaAsset.OpenArchive(localWorldFile, true)

                        local output = {}

                        commonlib.Files.Find(output, "", 0, 500, ":worldconfig.txt", localWorldFile)

                        if #output == 0 then
                            _guihelper.MessageBox(format(L'下载的世界已损坏，请重新尝试几次（项目ID：%d）', kpProjectId))

                            LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file will be deleted: %s', localWorldFile)

                            ParaIO.DeleteFile(localWorldFile)

                            ParaAsset.CloseArchive(localWorldFile)
                            return
                        end

                        ParaAsset.CloseArchive(localWorldFile)

                        LocalServiceWorld:EncryptWorld(localWorldFile, encryptWorldFile)

                        if not ParaEngine.GetAppCommandLineByParam('save_origin_zip', nil) then
                            ParaIO.DeleteFile(localWorldFile)
                        end

                        if ParaIO.DoesFileExist(encryptWorldFile) then
                            CacheProjectId:SetProjectIdInfo(kpProjectId, data.world)
                            GameLogic.RunCommand('/sendevent download_offline_world_finish ' .. kpProjectId)
                        end
                    else
                        if tryTimes > 0 then
                            return
                        end

                        Handle(cdnArchiveUrl)
                        tryTimes = tryTimes + 1
                    end
                end)
            end

            Handle(qiniuZipArchiveUrl)
        end
    )
end
