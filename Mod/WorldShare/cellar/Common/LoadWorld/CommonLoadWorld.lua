--[[
Title: Common Load World
Author(s): big
CreateDate: 2021.01.20
ModifyDate: 2021.10.13
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

-- service
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local GitKeepworkService = NPL.load('(gl)Mod/WorldShare/service/GitService/GitKeepworkService.lua')
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')

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
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
            return 
        end
        GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('homeWorldId')))
    elseif KeepworkServiceSession:GetUserWhere() == 'SCHOOL' then
        if IsSummerUser then
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
            return 
        end
        GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('schoolWorldId')))
    else
        CommonLoadWorld:SelectPlaceAndEnterCommunityWorld()
    end
end

function CommonLoadWorld:SelectPlaceAndEnterCommunityWorld()
    local IsSummerUser = Mod.WorldShare.Utils.IsSummerUser()
    MainLogin:ShowWhere(function(result)
        if result == 'HOME' then
            if IsSummerUser then
                GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
                return 
            end
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('homeWorldId')))
        elseif result == 'SCHOOL' then
            if IsSummerUser then
                GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('campWorldId')))
                return 
            end
            GameLogic.RunCommand(format('/loadworld -s -force %s', Mod.WorldShare.Utils:GetConfig('schoolWorldId')))
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

    local whiteList = {
        75, 76, 78, 81, 83, 84, 85, 87, 89, 90,
        93, 94 ,95, 96, 97, 98, 100, 101, 103, 106,
        111, 112, 113, 114, 115, 123, 126, 128, 130, 131,
        132, 133, 134, 136, 137, 138, 140, 141, 142, 143,
        144, 145, 146, 147, 148, 149, 150, 151, 152, 153,
        155, 156, 158, 159, 160, 161, 162, 163, 164, 166,
        167, 168, 169, 171, 172, 173, 174, 175, 176, 177,
        178, 179, 181, 183, 189, 196, 204, 210, 211, 213,
        242, 246, 247, 248, 251, 278, 284, 300, 301, 304,
        306, 307, 308, 309, 310, 312, 313, 314, 316, 317,
        318, 319, 320, 321, 323, 326, 327, 333, 348, 349,
        350, 351, 353, 355, 356, 363, 365, 367, 376, 378,
        379, 380, 381, 382, 385, 387, 388, 391, 400, 401,
        404, 454, 455, 456, 459, 468, 471, 472, 488, 492,
        506, 507, 508, 509, 510, 511, 530, 536, 552, 562,
        565, 569, 572, 613, 626, 676, 677, 694, 700, 702,
        708, 709, 712, 736, 758, 779, 798, 801, 804, 805,
        807, 821, 830, 840, 852, 867, 889, 923, 936, 985,
        170,
        1036, 1050, 1063, 1065, 1066, 1067, 1068, 1069, 1070, 1071,
        1073, 1074, 1075, 1076, 1077, 1079, 1080, 1081, 1082, 1083,
        1149, 1164, 1199, 1200, 1202, 1204, 1205, 1206, 1207, 1209,
        1210, 1211, 1212, 1228, 1231, 1233, 1234, 1235, 1237, 1248,
        1397, 1562, 1563, 1598, 1789, 2423, 2518, 2613, 2769, 3549,
        3590, 4073, 4119, 7945, 8225, 9162, 4181, 9776, 
        41150, 41494, 45014, 45903, 47738, 48674, 48815, 75309, 81855, 81857,
        81858, 81859, 81864, 81869, 81871, 81872, 81873, 81874, 81854, 81875,
        81895, 81896, 81898, 81897, 73139, 19405, 71346, 72945, 79969, 19759,
        52217, 18962, 80684, 42457, 42701, 42670, 58191, 84481, 83044, 85544,
        73104, 85615, 12642, 12728, 23496, 41020, 58194, 80682, 72171, 23540,
        41659, 84530, 88149, 88941, 82849, 54805, 89361, 77284, 20000, 89561,
        -- class world ID
        1311, 1315, 1316, 1398, 99, 2639, 2639, 2815, 2763, 623,
        685, 703, 756, 853, 984, 1321, 1399, 1401, 1319, 1407,
        1322, 1322, 878, 709, 1562, 19351, 19352,
        -- community world ID
        29477, 40499, 70351
    }

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
                        DownloadWorld.ShowPage(url)

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

                        world:DownloadRemoteFile(function(bSucceed, msg)
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
    
                                    ParaIO.DeleteFile(downloadNewLocalWorldFile)
    
                                    ParaAsset.CloseArchive(downloadNewLocalWorldFile)
    
                                    return
                                end
    
                                ParaAsset.CloseArchive(downloadNewLocalWorldFile)
    
                                LocalServiceWorld:EncryptWorld(downloadNewLocalWorldFile, downloadNewEncryptWorldFile)
    
                                if not ParaEngine.GetAppCommandLineByParam('save_origin_zip', nil) then
                                    ParaIO.DeleteFile(downloadNewLocalWorldFile)
                                end
    
                                if ParaIO.DoesFileExist(downloadNewEncryptWorldFile) then
                                    Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

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
                        DownloadWorld.ShowPage(url)

                        local world = nil
                        local downloadNewLocalWorldFile = nil

                        if url == newQiniuZipArchiveUrl then
                            world = newQiniuWorld
                            downloadNewLocalWorldFile = newQiniuWorldFile
                        elseif url == newCdnArchiveUrl then
                            world = newCdnArchiveWorld
                            downloadNewLocalWorldFile = newCdnArchiveWorldFile
                        end

                        world:DownloadRemoteFile(function(bSucceed, msg)
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

                                    ParaIO.DeleteFile(downloadNewLocalWorldFile)

                                    ParaAsset.CloseArchive(downloadNewLocalWorldFile)

                                    return
                                end

                                ParaAsset.CloseArchive(downloadNewLocalWorldFile)

                                Mod.WorldShare.Store:Set('world/currentRemoteFile', url)

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

            local archiveUrl = GitKeepworkService:GetQiNiuArchiveUrl(
                                data.world.worldName,
                                data.world.username,
                                data.world.commitId
                               )

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

                    self.freeUserVerified = true

                    HandleVerified()

                    return
                end

                -- times verified
                if data.timeRules and
                   data.timeRules[1] and
                   not self.timesVerified then
                    local reuslt, reason = self:TimesFilter(data.timeRules)

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