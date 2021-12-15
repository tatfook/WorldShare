--[[
Title: Common Load World
Author(s): big
CreateDate: 2021.01.20
ModifyDate: 2021.11.11
City: Foshan
use the lib:
------------------------------------------------------------
local CommonLoadWorld = NPL.load('(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua')
------------------------------------------------------------
]]

-- libs
local Game = commonlib.gettable('MyCompany.Aries.Game')
local DownloadWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.DownloadWorld')
local RemoteWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.RemoteWorld')
local InternetLoadWorld = commonlib.gettable('MyCompany.Aries.Creator.Game.Login.InternetLoadWorld')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')
local Screen = commonlib.gettable('System.Windows.Screen')

-- service
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local GitKeepworkService = NPL.load('(gl)Mod/WorldShare/service/GitService/GitKeepworkService.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')
local HttpRequest = NPL.load('(gl)Mod/WorldShare/service/HttpRequest.lua')

-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local WorldKeyDecodePage = NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/WorldKey/WorldKeyDecodePage.lua')

-- databse
local CacheProjectId = NPL.load('(gl)Mod/WorldShare/database/CacheProjectId.lua')

-- api
local KeepworkBaseApi = NPL.load('(gl)Mod/WorldShare/api/Keepwork/BaseApi.lua')

-- helper
local GitEncoding = NPL.load('(gl)Mod/WorldShare/helper/GitEncoding.lua')

local CommonLoadWorld = NPL.export()

function CommonLoadWorld:EnterCommunityWorld()
    if not KeepworkServiceSession:IsSignedIn() then
        return
    end
    local IsSummerUser = Mod.WorldShare.Utils.IsSummerUser()
    if KeepworkServiceSession:GetUserWhere() == 'HOME' then
        if IsSummerUser then
            GameLogic.RunCommand(format('/loadworld -s -auto %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
            return 
        end
        GameLogic.RunCommand(format('/loadworld -s -auto %s', Mod.WorldShare.Utils:GetConfig('homeWorldId')))
    elseif KeepworkServiceSession:GetUserWhere() == 'SCHOOL' then
        if IsSummerUser then
            GameLogic.RunCommand(format('/loadworld -s -auto %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
            return 
        end
        GameLogic.RunCommand(format('/loadworld -s -auto %s', Mod.WorldShare.Utils:GetConfig('schoolWorldId')))
    else
        CommonLoadWorld:SelectPlaceAndEnterCommunityWorld()
    end
end

function CommonLoadWorld:SelectPlaceAndEnterCommunityWorld()
    local IsSummerUser = Mod.WorldShare.Utils.IsSummerUser()
    MainLogin:ShowWhere(function(result)
        if result == 'HOME' then
            if IsSummerUser then
                GameLogic.RunCommand(format('/loadworld -s -auto %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
                return 
            end
            GameLogic.RunCommand(format('/loadworld -s -auto %s', Mod.WorldShare.Utils:GetConfig('homeWorldId')))
        elseif result == 'SCHOOL' then
            if IsSummerUser then
                GameLogic.RunCommand(format('/loadworld -s -auto %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
                return 
            end
            GameLogic.RunCommand(format('/loadworld -s -auto %s', Mod.WorldShare.Utils:GetConfig('schoolWorldId')))
        end
    end)
end

function CommonLoadWorld:EnterCourseWorld(aiCourseId, preRelease, releaseId)
    if not aiCourseId or type(preRelease) ~= 'boolean' or not releaseId then
        return
    end

    preRelease = preRelease == true and 'true' or 'false'

    local url = format(
        '%s/ai/courses/download?preRelease=%s&aiCourseId=%s&releaseId=%s',
        KeepworkBaseApi:GetCdnApi(),
        preRelease,
        aiCourseId,
        releaseId
    )

    Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

    local function LoadWorld(world, refreshMode)
        if world then
            if refreshMode == 'never' then
                if not LocalService:IsFileExistInZip(world:GetLocalFileName(), ':worldconfig.txt') then
                    refreshMode = 'force'
                end
            end

            local url = world:GetLocalFileName()
            DownloadWorld.ShowPage(url)
            InternetLoadWorld.LoadWorld(
                world,
                nil,
                refreshMode,
                function(bSucceed, localWorldPath)
                    DownloadWorld.Close()
                end
            )
        end
    end

    local world = RemoteWorld.LoadFromHref(url, 'self')
    local token = Mod.WorldShare.Store:Get('user/token')

    if token then
        world:SetHttpHeaders({Authorization = format('Bearer %s', token)})
    end

    local fileUrl = world:GetLocalFileName()

    if ParaIO.DoesFileExist(fileUrl) then
        LoadWorld(world, 'never')
    else
        LoadWorld(world, 'force')
    end
end

function CommonLoadWorld:EnterHomeworkWorld(aiHomeworkId, preRelease, releaseId)
    if not aiHomeworkId or type(preRelease) ~= 'boolean' or not releaseId then
        return
    end

    preRelease = preRelease == true and 'true' or 'false'

    local url = format(
        '%s/ai/homeworks/download?preRelease=%s&aiHomeworkId=%s&releaseId=%s',
        KeepworkBaseApi:GetCdnApi(),
        preRelease,
        aiHomeworkId,
        releaseId
    )

    Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

    local function LoadWorld(world, refreshMode)
        if world then
            if refreshMode == 'never' then
                if not LocalService:IsFileExistInZip(world:GetLocalFileName(), ':worldconfig.txt') then
                    refreshMode = 'force'
                end
            end

            local url = world:GetLocalFileName()
            DownloadWorld.ShowPage(url)
            InternetLoadWorld.LoadWorld(
                world,
                nil,
                refreshMode,
                function(bSucceed, localWorldPath)
                    DownloadWorld.Close()
                end
            )
        end
    end

    local world = RemoteWorld.LoadFromHref(url, 'self')
    local token = Mod.WorldShare.Store:Get('user/token')

    if token then
        world:SetHttpHeaders({Authorization = format('Bearer %s', token)})
    end

    local fileUrl = world:GetLocalFileName()

    if ParaIO.DoesFileExist(fileUrl) then
        LoadWorld(world, 'never')
    else
        LoadWorld(world, 'force')
    end
end

function CommonLoadWorld:EnterCacheWorldById(pid)
    pid = tonumber(pid)

    local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

    if not cacheWorldInfo or not cacheWorldInfo.worldInfo or not cacheWorldInfo.worldInfo.archiveUrl then
        return false
    end

    local worldInfo = cacheWorldInfo.worldInfo
    local url = cacheWorldInfo.worldInfo.archiveUrl
    local world = RemoteWorld.LoadFromHref(url, 'self')
    world:SetProjectId(pid)
    local fileUrl = world:GetLocalFileName()

    if fileUrl then
        WorldCommon.OpenWorld(fileUrl, true)
    else
        _guihelper.MessageBox(L'无效的世界文件')
    end
end

function CommonLoadWorld:IdsFilter(id)
    if not id or type(id) ~= 'number' then
        return
    end

    local whiteList = LocalServiceWorld:GetWhiteList()

    for _, item in pairs(whiteList) do
        if item == id then
            return true
        end
    end

    return false
end

function CommonLoadWorld:TimesFilter(timeRules)
    local serverTime = Mod.WorldShare.Store:Get('world/currentServerTime')
    local weekDay = Mod.WorldShare.Utils.GetWeekNum(serverTime)
    local dateList = {'一', '二', '三', '四', '五', '六', '日'}

    local function Check(timeRule)
        local year, month, day = timeRule.startDay:match('^(%d+)%D(%d+)%D(%d+)') 
        local startDateTimestamp = os.time(
                                    {
                                        day = tonumber(day),
                                        month = tonumber(month),
                                        year = tonumber(year),
                                        hour = 0,
                                        min = 0,
                                        sec = 0
                                    }
                                   )

        year, month, day = timeRule.endDay:match('^(%d+)%D(%d+)%D(%d+)')
        local endDateTimestamp = os.time(
                                    {
                                        day = tonumber(day),
                                        month = tonumber(month),
                                        year = tonumber(year),
                                        hour = 23,
                                        min = 59,
                                        sec=59
                                    }
                                )

        if serverTime < startDateTimestamp then
            return false, string.format(L'未到上课时间，请在%s之后来学习吧。', timeRule.startDay)
        end

        if serverTime > endDateTimestamp then
            return false, L'上课时间已过'
        end

        local weeks = timeRule.weeks
        local inWeekDay = false

        local dateStr = ''
        for i, v in ipairs(weeks) do
            if v == weekDay then
                inWeekDay = true
            end

            dateStr = dateStr .. L'周' .. dateList[v] or ''

            if i ~= #weeks then
                dateStr = dateStr .. '，'
            end
        end

        if not inWeekDay then
            return false, string.format(L'现在不是上课时间哦，请在上课时间（%s）内再来上课吧。', dateStr)
        end

        local startTimeStr = timeRule.startTime or '0:0'
        local startHour, startMin = startTimeStr:match('^(%d+)%D(%d+)') 
        startHour = tonumber(startHour)
        startMin = tonumber(startMin)

        local endTimeStr = timeRule.endTime or '23:59'
        local endHour, endMin = endTimeStr:match('^(%d+)%D(%d+)') 
        endHour = tonumber(endHour)
        endMin = tonumber(endMin)

        local timeStr = startTimeStr .. '-' .. endTimeStr

        local todayWeehours = commonlib.timehelp.GetWeeHoursTimeStamp(serverTime)
        local limitTimeStamp = todayWeehours + startHour * 60 * 60 + startMin * 60
        local limitTimeEndStamp = todayWeehours + endHour * 60 * 60 + endMin * 60

        if serverTime < limitTimeStamp or serverTime > limitTimeEndStamp then
            return false, string.format(L'现在不是上课时间哦，请在上课时间（%s）内再来上课吧。', timeStr)
        end

        return true
    end

    local failedReasonList = {}
    for _, timeRule in ipairs(timeRules) do
        local result, reason = Check(timeRule)
        if result then
            return true
        end

        failedReasonList[#failedReasonList + 1] = reason
    end

    return false, failedReasonList[1]
end

function CommonLoadWorld.StartOldVersion(index)
    local self = CommonLoadWorld

    if not self.downloadWorldInstances[index] then
        return
    end

    local downloadWorldInstance = self.downloadWorldInstances[index]

    downloadWorldInstance.breakDownload = true

    local worldInfo = downloadWorldInstance.worldInfo
    downloadWorldInstance.ShowOrHideStartOldVersionButton(false)
    DownloadWorld.Close()

    if not worldInfo or
       not worldInfo.extra or
       not worldInfo.extra.commitIds then
        return
    end

    local commitIds = worldInfo.extra.commitIds

    if type(commitIds) ~= 'table' or #commitIds <= 1 then
        return
    end

    local previousCommit = commitIds[#commitIds - 1]

    if not previousCommit or not previousCommit.commitId then
        return
    end

    Game.Exit()

    Mod.WorldShare.MsgBox:Show(L'正在加载旧版本，请稍后...', 30000, nil, 320, 130, 1002)

    -- TODO: clean old worlds

    local previousCommitId = previousCommit.commitId
    local tryTimes = 0
    local qiniuZipArchiveUrl = GitKeepworkService:GetQiNiuArchiveUrl(
                                        worldInfo.worldName,
                                        worldInfo.username,
                                        previousCommitId)
    local cdnArchiveUrl = GitKeepworkService:GetCdnArchiveUrl(
                            worldInfo.worldName,
                            worldInfo.username,
                            previousCommitId)

    local function HandleDownload(url)
        local world = RemoteWorld.LoadFromHref(url, 'self')
        world:SetProjectId(worldInfo.projectId)
        world:SetRevision(worldInfo.revision)
        world:SetSpecifyFilename(previousCommitId)
        local token = Mod.WorldShare.Store:Get('user/token')

        if token then
            world:SetHttpHeaders({Authorization = format('Bearer %s', token)})
        end

        local worldFile = world:GetLocalFileName() or ''
        local encryptWorldFile = string.match(worldFile, '(.+)%.zip$') .. '.pkg'

        if self.encryptWorldMode then
            if ParaIO.DoesFileExist(encryptWorldFile) then
                Game.Start(encryptWorldFile)
                return
            end
        else
            if ParaIO.DoesFileExist(worldFile) then
                Game.Start(worldFile)
                return
            end
        end

        ParaIO.DeleteFile(worldFile)
        ParaIO.DeleteFile(encryptWorldFile)

        world:DownloadRemoteFile(function(bSucceed, msg)
            if bSucceed then
                if not ParaIO.DoesFileExist(worldFile) then
                    Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage()
                    MainLogin:Show()

                    _guihelper.MessageBox(format(L'下载世界失败，请重新尝试几次（项目ID：%d）', worldInfo.projectId))
                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file not exist: %s', worldFile)

                    Mod.WorldShare.MsgBox:Close()
                    return
                end

                ParaAsset.OpenArchive(worldFile, true)
                
                local output = {}

                commonlib.Files.Find(output, '', 0, 500, ':worldconfig.txt', worldFile)

                if #output == 0 then
                    Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage()
                    MainLogin:Show()

                    _guihelper.MessageBox(format(L'下载的世界已损坏，请重新尝试几次（项目ID：%d）', worldInfo.projectId))
                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file will be deleted: %s', worldFile)

                    ParaAsset.CloseArchive(worldFile)
                    ParaIO.DeleteFile(worldFile)

                    Mod.WorldShare.MsgBox:Close()
                    return
                end

                ParaAsset.CloseArchive(worldFile)

                if self.encryptWorldMode then
                    LocalServiceWorld:EncryptWorld(worldFile, encryptWorldFile)

                    if not ParaEngine.GetAppCommandLineByParam('save_origin_zip', nil) then
                        ParaIO.DeleteFile(worldFile)
                    end

                    if ParaIO.DoesFileExist(encryptWorldFile) then
                        Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

                        Mod.WorldShare.MsgBox:Close()
                        Game.Start(encryptWorldFile)
                    end
                else
                    Mod.WorldShare.MsgBox:Close()
                    Game.Start(worldFile)
                end
            else
                Mod.WorldShare.Utils.SetTimeOut(function()
                    Mod.WorldShare.MsgBox:Close()

                    if tryTimes > 0 then
                        Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage()
                        MainLogin:Show()

                        Mod.WorldShare.MsgBox:Close()
                        return
                    end

                    Mod.WorldShare.MsgBox:Show(L'正在加载旧版本，请稍后...', 30000, nil, 320, 130, 1002)
                    HandleDownload(cdnArchiveUrl)
                    tryTimes = tryTimes + 1
                end, 3000)
            end
        end)
    end

    HandleDownload(qiniuZipArchiveUrl)
end

function CommonLoadWorld:InjectShowCustomDownloadWorldFilter(worldInfo, downloadWorldInstance)
    if not self.downloadWorldInstancesCount then
        self.downloadWorldInstancesCount = 0
    end

    if not self.downloadWorldInstances then
        self.downloadWorldInstances = {}
    end

    self.downloadWorldInstancesCount = self.downloadWorldInstancesCount + 1
    self.downloadWorldInstances[self.downloadWorldInstancesCount] = downloadWorldInstance

    downloadWorldInstance.worldInfo = worldInfo

    downloadWorldInstance.ToggleStartOldVersionButton = function(isShow)
        if isShow == true then
            if downloadWorldInstance.startOldVersionButtonNode then
                downloadWorldInstance.startOldVersionButtonNode = nil
                ParaUI.Destroy('start_old_version_button')
            end
    
            local rootNode = ParaUI.GetUIObject('root')
            downloadWorldInstance.startOldVersionButtonNode = ParaUI.CreateUIObject(
                                                                  'button',
                                                                  'start_old_version_button',
                                                                  '_ct',
                                                                  -45,
                                                                  110,
                                                                  90,
                                                                  35
                                                              )

            downloadWorldInstance.startOldVersionButtonNode.enabled = false
            downloadWorldInstance.startOldVersionButtonNode.background = 'Texture/Aries/Creator/keepwork/worldshare_32bits.png#624 198 38 64:12 10 12 15'
            downloadWorldInstance.startOldVersionButtonNode.zorder = 1002
            _guihelper.SetFontColor(self.startOldVersionButtonNode, '#000000')
            downloadWorldInstance.startOldVersionButtonNode:SetField('TextOffsetY', -2)
            downloadWorldInstance.startOldVersionButtonNode.text = L'启动旧版'
            downloadWorldInstance.startOldVersionButtonNode:SetCurrentState('highlight')
            downloadWorldInstance.startOldVersionButtonNode.color = '255 255 255'
            downloadWorldInstance.startOldVersionButtonNode:SetCurrentState('pressed')
            downloadWorldInstance.startOldVersionButtonNode.color = '160 160 160'
            downloadWorldInstance.startOldVersionButtonNode.onclick = format(
                ';NPL.load("(gl)Mod/WorldShare/cellar/Common/LoadWorld/CommonLoadWorld.lua").StartOldVersion(%d)',
                self.downloadWorldInstancesCount
            )

            local count = 10
            downloadWorldInstance.startCountdownTimer = commonlib.Timer:new(
                {
                    callbackFunc = function()
                        if count > 0 then
                            downloadWorldInstance.startOldVersionButtonNode.text = format(L'启动旧版(%d)', count)
                            count = count - 1
                        else
                            downloadWorldInstance.startOldVersionButtonNode.text = L'启动旧版'
                            downloadWorldInstance.startOldVersionButtonNode.enabled = true
                            downloadWorldInstance.startCountdownTimer:Change(nil, nil)
                        end
                    end
                }
            )

            downloadWorldInstance.startCountdownTimer:Change(0, 1000)

            rootNode:AddChild(downloadWorldInstance.startOldVersionButtonNode)
        elseif isShow == false then
            if downloadWorldInstance.startOldVersionButtonNode then
                downloadWorldInstance.startCountdownTimer:Change(nil, nil)
                downloadWorldInstance.startOldVersionButtonNode = nil
                ParaUI.Destroy('start_old_version_button')
                return
            end
        end
    end

    downloadWorldInstance.ShowOrHideStartOldVersionButton = function(result)
        if result == 'show' then
            downloadWorldInstance.ToggleStartOldVersionButton(true)

            return 'show'
        elseif result == 'close' then
            downloadWorldInstance.ToggleStartOldVersionButton(false)

            GameLogic.GetFilters():remove_filter(
                'show_custom_download_world',
                downloadWorldInstance.ShowOrHideStartOldVersionButton
            )

            downloadWorldInstance.worldInfo = nil
            downloadWorldInstance.ShowOrHideStartOldVersionButton = nil

            return 'close'
        end
    end

    GameLogic.GetFilters():add_filter(
        'show_custom_download_world',
        downloadWorldInstance.ShowOrHideStartOldVersionButton
    )
end

-- @param refreshMode: nil|'auto'|'check'|'never'|'force'.  
function CommonLoadWorld:EnterWorldById(pid, refreshMode, failed)
    if not pid then
        return
    end

    pid = tonumber(pid)

    local world
    local overtimeEnter = false
    local fetchSuccess = false
    local tryTimes = 0

    local function HandleLoadWorld(worldInfo, offlineMode)
        if overtimeEnter then
            -- stop here when overtime enter
            return
        end

        local localWorldFile = nil
        local encryptWorldFile = nil

        local encryptWorldFileExist = false
        local worldFileExist = false

        local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

        if cacheWorldInfo then
            local qiniuZipArchiveUrl = GitKeepworkService:GetQiNiuArchiveUrl(
                                        worldInfo.worldName,
                                        worldInfo.username,
                                        cacheWorldInfo.worldInfo.commitId)
            local cdnArchiveUrl = GitKeepworkService:GetCdnArchiveUrl(
                                    worldInfo.worldName,
                                    worldInfo.username,
                                    cacheWorldInfo.worldInfo.commitId)

            local qiniuWorld = RemoteWorld.LoadFromHref(qiniuZipArchiveUrl, 'self')
            qiniuWorld:SetProjectId(pid)
            qiniuWorld:SetRevision(cacheWorldInfo.worldInfo.revision)
            qiniuWorld:SetSpecifyFilename(cacheWorldInfo.worldInfo.commitId)

            local cdnArchiveWorld = RemoteWorld.LoadFromHref(cdnArchiveUrl, 'self')
            cdnArchiveWorld:SetProjectId(pid)
            cdnArchiveWorld:SetRevision(cacheWorldInfo.worldInfo.revision)
            cdnArchiveWorld:SetSpecifyFilename(cacheWorldInfo.worldInfo.commitId)

            local qiniuWorldFile = qiniuWorld:GetLocalFileName() or ''
            local cdnArchiveWorldFile = cdnArchiveWorld:GetLocalFileName() or ''
    
            local encryptQiniuWorldFile = string.match(qiniuWorldFile, '(.+)%.zip$') .. '.pkg'
            local encryptCdnArchiveWorldFile = string.match(cdnArchiveWorldFile, '(.+)%.zip$') .. '.pkg'
    
            if ParaIO.DoesFileExist(encryptQiniuWorldFile) then
                encryptWorldFileExist = true
                self.encryptWorldMode = true
                localWorldFile = qiniuWorldFile
                encryptWorldFile = encryptQiniuWorldFile
            elseif ParaIO.DoesFileExist(encryptCdnArchiveWorldFile) then
                encryptWorldFileExist = true
                self.encryptWorldMode = true
                localWorldFile = cdnArchiveWorldFile
                encryptWorldFile = encryptCdnArchiveWorldFile
            elseif ParaIO.DoesFileExist(qiniuWorldFile) then
                worldFileExist = true
                self.encryptWorldMode = nil
                localWorldFile = qiniuWorldFile
                encryptWorldFile = encryptQiniuWorldFile
            elseif ParaIO.DoesFileExist(cdnArchiveWorldFile) then
                worldFileExist = true
                self.encryptWorldMode = nil
                localWorldFile = cdnArchiveWorldFile
                encryptWorldFile = encryptCdnArchiveWorldFile
            end
        end

        local function LoadWorld(refreshMode) -- refreshMode(force or never)
            local newQiniuZipArchiveUrl = GitKeepworkService:GetQiNiuArchiveUrl(
                                    worldInfo.worldName,
                                    worldInfo.username,
                                    worldInfo.commitId)
            local newCdnArchiveUrl = GitKeepworkService:GetCdnArchiveUrl(
                                        worldInfo.worldName,
                                        worldInfo.username,
                                        worldInfo.commitId)

            local newQiniuWorld = RemoteWorld.LoadFromHref(newQiniuZipArchiveUrl, 'self')
            newQiniuWorld:SetProjectId(pid)
            newQiniuWorld:SetRevision(worldInfo.revision)
            newQiniuWorld:SetSpecifyFilename(worldInfo.commitId)

            local newCdnArchiveWorld = RemoteWorld.LoadFromHref(newCdnArchiveUrl, 'self')
            newCdnArchiveWorld:SetProjectId(pid)
            newCdnArchiveWorld:SetRevision(worldInfo.revision)
            newCdnArchiveWorld:SetSpecifyFilename(worldInfo.commitId)

            local newQiniuWorldFile = newQiniuWorld:GetLocalFileName() or ''
            local newCdnArchiveWorldFile = newCdnArchiveWorld:GetLocalFileName() or ''
    
            local newEncryptQiniuWorldFile = string.match(newQiniuWorldFile, '(.+)%.zip$') .. '.pkg'
            local newEncryptCdnArchiveWorldFile = string.match(newCdnArchiveWorldFile, '(.+)%.zip$') .. '.pkg'

            -- encrypt mode load world
            if self.encryptWorldMode then
                if refreshMode == 'never' then
                    if not LocalService:IsFileExistInZip(encryptWorldFile, ':worldconfig.txt') then
                        -- broken world
                        refreshMode = 'force'
                    end
                end

                if encryptWorldFileExist and refreshMode ~= 'force' then
                    Game.Start(encryptWorldFile)
                    return
                end

                if not encryptWorldFileExist or
                   refreshMode == 'force' then
                    if ParaIO.DoesFileExist(encryptWorldFile) then
                        ParaIO.DeleteFile(encryptWorldFile)
                    end

                    if ParaIO.DoesFileExist(localWorldFile) then
                        ParaIO.DeleteFile(localWorldFile)
                    end

                    local function DownloadEncrytWorld(url)
                        local world = nil
                        local downloadNewLocalWorldFile = nil
                        local downloadNewEncryptWorldFile = nil
    
                        if url == newQiniuZipArchiveUrl then
                            world = newQiniuWorld
                            downloadNewLocalWorldFile = newQiniuWorldFile
                            downloadNewEncryptWorldFile = newEncryptQiniuWorldFile
                        elseif url == newCdnArchiveUrl then
                            world = newCdnArchiveWorld
                            downloadNewLocalWorldFile = newCdnArchiveWorldFile
                            downloadNewEncryptWorldFile = newEncryptCdnArchiveWorldFile
                        end

                        local token = Mod.WorldShare.Store:Get('user/token')

                        if token then
                            world:SetHttpHeaders({Authorization = format('Bearer %s', token)})
                        end

                        self:InjectShowCustomDownloadWorldFilter(worldInfo, world)
                        DownloadWorld.ShowPage(url)

                        world:DownloadRemoteFile(function(bSucceed, msg)
                            if world.breakDownload then
                                return
                            end

                            DownloadWorld.Close()

                            if bSucceed then
                                if not ParaIO.DoesFileExist(downloadNewLocalWorldFile) then
                                    _guihelper.MessageBox(format(L'下载世界失败，请重新尝试几次（项目ID：%d）', pid))
    
                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file not exist: %s', localWorldFile)
    
                                    return
                                end
    
                                ParaAsset.OpenArchive(downloadNewLocalWorldFile, true)
                                
                                local output = {}
    
                                commonlib.Files.Find(output, '', 0, 500, ':worldconfig.txt', downloadNewLocalWorldFile)
    
                                if #output == 0 then
                                    _guihelper.MessageBox(format(L'下载的世界已损坏，请重新尝试几次（项目ID：%d）', pid))
    
                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file will be deleted: %s', downloadNewLocalWorldFile)
    
                                    ParaAsset.CloseArchive(downloadNewLocalWorldFile)
                                    ParaIO.DeleteFile(downloadNewLocalWorldFile)
    
                                    return
                                end
    
                                ParaAsset.CloseArchive(downloadNewLocalWorldFile)
    
                                LocalServiceWorld:EncryptWorld(downloadNewLocalWorldFile, downloadNewEncryptWorldFile)
    
                                if not ParaEngine.GetAppCommandLineByParam('save_origin_zip', nil) then
                                    ParaIO.DeleteFile(downloadNewLocalWorldFile)
                                end
    
                                if ParaIO.DoesFileExist(downloadNewEncryptWorldFile) then
                                    Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

                                    worldInfo.encryptWorldMode = self.encryptWorldMode
                                    CacheProjectId:SetProjectIdInfo(pid, worldInfo)

                                    Game.Start(downloadNewEncryptWorldFile)
                                end
                            else
                                Mod.WorldShare.MsgBox:Wait()

                                Mod.WorldShare.Utils.SetTimeOut(function()
                                    Mod.WorldShare.MsgBox:Close()

                                    if tryTimes > 0 then
                                        Create:Show()
                                        return
                                    end

                                    DownloadEncrytWorld(newCdnArchiveUrl)
                                    tryTimes = tryTimes + 1
                                end, 3000)
                            end
                        end)
                    end

                    DownloadEncrytWorld(newQiniuZipArchiveUrl)
                end
            else
                -- zip mode load world

                if refreshMode == 'never' then
                    -- broken world
                    if not LocalService:IsFileExistInZip(localWorldFile, ':worldconfig.txt') then
                        refreshMode = 'force'
                    end
                end
    
                if worldFileExist and refreshMode ~= 'force' then
                    Game.Start(localWorldFile)
                    return
                end

                if not worldFileExist or
                   refreshMode == 'force' then
                    if ParaIO.DoesFileExist(localWorldFile) then
                        ParaIO.DeleteFile(localWorldFile)
                    end

                    local function DownloadLocalWorld(url)
                        local world = nil
                        local downloadNewLocalWorldFile = nil

                        if url == newQiniuZipArchiveUrl then
                            world = newQiniuWorld
                            downloadNewLocalWorldFile = newQiniuWorldFile
                        elseif url == newCdnArchiveUrl then
                            world = newCdnArchiveWorld
                            downloadNewLocalWorldFile = newCdnArchiveWorldFile
                        end

                        if token then
                            world:SetHttpHeaders({Authorization = format('Bearer %s', token)})
                        end

                        self:InjectShowCustomDownloadWorldFilter(worldInfo, world)
                        DownloadWorld.ShowPage(url)

                        world:DownloadRemoteFile(function(bSucceed, msg)
                            if world.breakDownload then
                                return
                            end
                            
                            DownloadWorld.Close()

                            if bSucceed then
                                if not ParaIO.DoesFileExist(downloadNewLocalWorldFile) then
                                    _guihelper.MessageBox(format(L'下载世界失败，请重新尝试几次（项目ID：%d）', pid))

                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file not exist: %s', downloadNewLocalWorldFile)

                                    return
                                end

                                ParaAsset.OpenArchive(downloadNewLocalWorldFile, true)
                                
                                local output = {}

                                commonlib.Files.Find(output, '', 0, 500, ':worldconfig.txt', downloadNewLocalWorldFile)

                                if #output == 0 then
                                    _guihelper.MessageBox(format(L'下载的世界已损坏，请重新尝试几次（项目ID：%d）', pid))

                                    LOG.std(nil, 'warn', 'CommandLoadWorld', 'Invalid downloaded file will be deleted: %s', downloadNewLocalWorldFile)

                                    ParaAsset.CloseArchive(downloadNewLocalWorldFile)
                                    ParaIO.DeleteFile(downloadNewLocalWorldFile)

                                    return
                                end

                                ParaAsset.CloseArchive(downloadNewLocalWorldFile)

                                Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

                                worldInfo.encryptWorldMode = self.encryptWorldMode
                                CacheProjectId:SetProjectIdInfo(pid, worldInfo)

                                Game.Start(downloadNewLocalWorldFile)
                            else
                                Mod.WorldShare.MsgBox:Wait()

                                Mod.WorldShare.Utils.SetTimeOut(function()
                                    Mod.WorldShare.MsgBox:Close()

                                    if tryTimes > 0 then
                                        Create:Show()
                                        return
                                    end

                                    DownloadLocalWorld(newCdnArchiveUrl)
                                    tryTimes = tryTimes + 1
                                end, 3000)
                            end
                        end)
                    end

                    DownloadLocalWorld(newQiniuZipArchiveUrl)
                end
            end
        end

        -- check encrypt file
        if not encryptWorldFileExist and not worldFileExist then
            LoadWorld('force')
            return
        end

        if offlineMode then
            LoadWorld('never')
            return
        end

        if refreshMode == 'never' or
           refreshMode == 'force' then
            if refreshMode == 'never' then
                LoadWorld('never')
            elseif refreshMode == 'force' then
                LoadWorld('force')
            end
        elseif not refreshMode or
               refreshMode == 'auto' or
               refreshMode == 'check' then
            Mod.WorldShare.MsgBox:Wait()

            GitService:GetWorldRevision(pid, false, function(data, err)
                local localRevision = 0

                if self.encryptWorldMode then
                    localRevision = tonumber(LocalService:GetZipRevision(encryptWorldFile))
                else
                    localRevision = tonumber(LocalService:GetZipRevision(localWorldFile))
                end

                local remoteRevision = tonumber(data) or 0

                Mod.WorldShare.MsgBox:Close()

                if refreshMode == 'auto' then
                    if localRevision == 0 then
                        LoadWorld('force')
                        return
                    end

                    if localRevision < remoteRevision then
                        LoadWorld('force')
                    else
                        LoadWorld('never')
                    end
                elseif not refreshMode or refreshMode == 'check' then
                    if not refreshMode and refreshMode ~= 'check' then
                        if localRevision == 0 then
                            LoadWorld('force')
                            return
                        end
    
                        if localRevision == remoteRevision then
                            LoadWorld('never')
                            return
                        end
                    end

                    -- check or revision not equal
                    local worldName = ''

                    if worldInfo and worldInfo.extra and worldInfo.extra.worldTagName then
                        worldName = worldInfo.extra.worldTagName
                    else
                        worldName = worldInfo.worldName
                    end

                    local params = Mod.WorldShare.Utils.ShowWindow(
                        0,
                        0,
                        'Mod/WorldShare/cellar/Common/LoadWorld/ProjectIdEnter.html?project_id=' 
                            .. pid
                            .. '&remote_revision=' .. remoteRevision
                            .. '&local_revision=' .. localRevision
                            .. '&world_name=' .. worldName,
                        'ProjectIdEnter',
                        0,
                        0,
                        '_fi',
                        false
                    )

                    params._page.callback = function(data)
                        if data == 'local' then
                            LoadWorld('never')
                        elseif data == 'remote' then
                            LoadWorld('force')
                        end
                    end
                end                
            end)
        end
	end

    -- offline mode
    local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

    if System.options.loginmode == 'offline' and cacheWorldInfo then
        self.encryptWorldMode = cacheWorldInfo.worldInfo.encryptWorldMode
        HandleLoadWorld(cacheWorldInfo.worldInfo, true)
        return
    end

    -- show view over 10 seconds
    Mod.WorldShare.Utils.SetTimeOut(function()
        if fetchSuccess then
            return
        end

        MainLogin:Close()

        local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

        if not CreatePage then
            Create:Show()
        end

        Mod.WorldShare.MsgBox:Close()
    end, 10000)

    Mod.WorldShare.MsgBox:Wait(20000)

    KeepworkServiceProject:GetProject(
        pid,
        function(data, err)
            Mod.WorldShare.MsgBox:Close()
            fetchSuccess = true

            if err == 0 then
                local cacheWorldInfo = CacheProjectId:GetProjectIdInfo(pid)

                if not cacheWorldInfo or not cacheWorldInfo.worldInfo then
                    GameLogic.AddBBS(nil, format(L'网络环境差，或离线中，请联网后再试（%d）', err), 3000, '255 0 0')
                    return
                end

                HandleLoadWorld(cacheWorldInfo.worldInfo, true)
                return
            end

            if err == 404 or
               not data or
               not data.world or
               not data.world.archiveUrl or
               #data.world.archiveUrl == 0 then
                local archiveUrlLength = 0

                if data and data.world and data.world.archiveUrl then
                    archiveUrlLength = #data.world.archiveUrl
                end

                GameLogic.AddBBS(
                    nil,
                    format(L'未找到对应项目信息（项目ID：%d）（URL长度：%d）（ERR：%d）', pid, archiveUrlLength, err),
                    10000,
                    '255 0 0'
                )

                local CreatePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')

                if not CreatePage then
                    Create:Show() -- use local mode instead of enter world
                end
                return
            end

            if err ~= 200 then
                GameLogic.AddBBS(nil, format(L'服务器维护中（%d）', err), 3000, '255 0 0')
                return
            end

            -- update world info
            data.world.username = data.username

            local function ResetVerified()
                self.isVisiblityVerified = false
                self.vipVerified = false
                self.instituteVerified = false
                self.encodeWorldVerified = false
                self.encryptWorldVerified = false
                self.freeUserVerified = false
                self.timesVerified = false
            end

            local function HandleVerified()
                -- free user verifed
                local username = Mod.WorldShare.Store:Get('user/username')

                if (not username or
                    username ~= data.username) and
                    not self.freeUserVerified then

                    if System.options.useFreeworldWhitelist or
                       System.options.maxFreeworldUploadCount then
                        if not self:IdsFilter(pid) then
                            GameLogic.IsVip('LimitUserOpenShareWorld', true, function(result)
                                if not result then
                                    return
                                end

                                self.freeUserVerified = true

                                HandleVerified()
                            end)
                            return
                        end
                    end

                    local HttpRequest = NPL.load('(gl)Mod/WorldShare/service/HttpRequest.lua')

                    HttpRequest:Get(
                        'https://api.keepwork.com/ts-storage/siteFiles/21357/raw#DAAC412ACEE6D108',
                        nil,
                        nil,
                        function(data, err)
                            local keyFile = ParaIO.open('skip_world_key_file', 'r')

                            if keyFile:IsValid() then
                                local key = keyFile:GetText(0, -1)

                                if key == data then
                                    self.freeUserVerified = true
                                    HandleVerified()
                                else
                                    GameLogic.AddBBS(nil, L'证书配置失败，请联系管理员', 3000, '255 0 0')
                                end

                                keyFile:close()
                            else
                                GameLogic.AddBBS(nil, L'证书配置失败，请联系管理员', 3000, '255 0 0')
                            end
                        end
                    )

                    return
                end

                -- times verified
                if data.timeRules and
                   data.timeRules[1] and
                   not self.timesVerified then
                    local result, reason = self:TimesFilter(data.timeRules)

                    if result then
                        self.timesVerified = true

                        HandleVerified()
                    else
                        _guihelper.MessageBox(reason)
                    end

                    return
                end

                -- private world verfied
                if data.visibility == 1 and
                   not self.isVisiblityVerified then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L'该项目需要登录后访问', function(bIsSuccessed)
                            if bIsSuccessed then
                                HandleVerified()
                            end
                        end)
                    else
                        KeepworkServiceProject:GetMembers(pid, function(members, err)
                            if type(members) ~= 'table' then
                                return
                            end
    
                            local username = Mod.WorldShare.Store:Get('user/username')
    
                            for key, item in ipairs(members) do
                                if item and item.username and item.username == username then    
                                    data.world.archiveUrl = data.world.archiveUrl .. '&private=true'
                                    self.isVisiblityVerified = true

                                    HandleVerified()

                                    return
                                end
                            end

                            GameLogic.AddBBS(
                                nil,
                                format(L'您未获得该项目的访问权限（项目ID：%d）（用户名：%s）', pid or 0, username or ''),
                                3000,
                                '255 0 0'
                            )

                            ResetVerified()

                            return
                        end)
                    end

                    return
                end
    
                -- vip enter
                if not self.vipVerified and
                   data and
                   data.extra and
                   ((data.extra.vipEnabled and data.extra.vipEnabled == 1) or
                   (data.extra.isVipWorld and data.extra.isVipWorld == 1)) then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L'该项目需要登录后访问', function(bIsSuccessed)
                            if bIsSuccessed then
                                HandleVerified()
                            end
                        end)
                    else
                        local username = Mod.WorldShare.Store:Get('user/username')

                        if data.username and data.username ~= username then
                            GameLogic.IsVip('Vip', true, function(result)
                                if result then
                                    self.vipVerified = true
                                    HandleVerified()
                                else
                                    local username = Mod.WorldShare.Store:Get('user/username')

                                    _guihelper.MessageBox(
                                        format(L'你没有权限进入此世界（VIP）(项目ID：%d)（用户名：%s）', pid or 0, username or '')
                                    )

                                    ResetVerified()
                                end
                            end, 'Vip')
                        end
                    end
    
                    return
                end
    
                -- vip institute enter
                if data and
                   data.extra and
                   data.extra.instituteVipEnabled and
                   data.extra.instituteVipEnabled == 1 and
                   not self.instituteVerified then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L'该项目需要登录后访问', function(bIsSuccessed)
                            if bIsSuccessed then
                                HandleVerified()
                            end
                        end)
                        return
                    else
                        GameLogic.IsVip('IsOrgan', true, function(result)
                            if result then
                                self.instituteVerified = true
                                HandleVerified()
                            else
                                local username = Mod.WorldShare.Store:Get('user/username')

                                _guihelper.MessageBox(
                                    format(L'你没有权限进入此世界（机构VIP）(项目ID：%d)（用户名：%s）', pid or 0, username or '')
                                )

                                ResetVerified()
                            end
                        end, 'Institute')
                    end

                    return
                end

                -- encrypt world
                if data and
                   data.level and
                   data.level ~= 2 and
                   not self.encryptWorldVerified then
                    self.encryptWorldVerified = true
                    self.encryptWorldMode = true
                    HandleVerified()
                    return
                end

                -- encode world
                if data and
                   data.extra and
                   data.extra.encode_world == 1 and
                   not self.encodeWorldVerified then
                    if not KeepworkServiceSession:IsSignedIn() then
                        LoginModal:CheckSignedIn(L'该项目需要登录后访问', function(bIsSuccessed)
                            if bIsSuccessed then
                                HandleVerified()
                            end
                        end)
    
                        return
                    else
                        local username = Mod.WorldShare.Store:Get('user/username')
    
                        if data.username and data.username == username then
                            self.encodeWorldVerified = true
                            HandleVerified()
                        else
                            WorldKeyDecodePage.Show(data, function()
                                HandleLoadWorld(data.world)
                            end)

                            ResetVerified()
                        end
                    end

                    return
                end

                ResetVerified()

                -- enter world
                HandleLoadWorld(data.world)
            end

            HandleVerified()
        end
    )
end