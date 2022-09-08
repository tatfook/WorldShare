--[[
Title: SessionsData
Author(s): big
CreateDate: 2019.07.24
ModifyDate: 2021.09.24
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local SessionsData = NPL.load('(gl)Mod/WorldShare/database/SessionsData.lua')
------------------------------------------------------------
]]

-- config
local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')

local SessionsData = NPL.export()

-- session struct
--[[
{
    selectedUser = "1111",
    allUsers = {
        {
            value = "1111",
            text = "1111",
            session = {
                account = "1111",
                loginServer = "ONLINE",
                password = "12345678",
                autoLogin = true,
                rememberMe = true,
                token = "jwttoken",
                tokenExpire = 12345678,
                loginTime = 111111111,
                doNotNoticeVerify = false,
                isVip = false,
                userType = {
                    orgAdmin = false,
                    teacher = false,
                    student = false,
                    freeStudent = false,
                    plain = true,
                }
            },
            allPositions = {
                {
                    projectId = 1111,
                    lastPosition = { x = 19200, y = 6, x = 19200 },
                    orientation = { CameraLiftupAngle = 0.11111, CameraRotY = 0.22222 }
                }
            }
        },
        {
            value = "2222",
            text = "2222",
            session = {
                account = "2222",
                loginServer = "STAGE",
                autoLogin = false,
                rememberMe = true,
                token = "jwttoken",
                tokenExpire = 12345678
            }
        },
        {
            value = "3333",
            text = "3333",
            session = {
                account = "3333",
                loginServer = "ONLINE",
                autoLogin = false,
                rememberMe = false,
                password = "123456",
                token = "jwttoken",
                tokenExpire = 12345678
            }
        },
    }
}
]]
function SessionsData:GetSessions()
    local playerController = GameLogic.GetPlayerController()

    return playerController:LoadLocalData("sessions", {
        selectedUser = "",
        allUsers = {}
    }, true)
end

function SessionsData:RemoveSession(username)
    local sessionsData = self:GetSessions()

    if sessionsData.selectedUser == username then
        sessionsData.selectedUser = ""
    end

    local newAllUsers = commonlib.Array:new(sessionsData.allUsers);

    for key, item in ipairs(newAllUsers) do
        if item.value == username then
            newAllUsers:remove(key)
            break
        end
    end

    sessionsData.allUsers = newAllUsers

    GameLogic.GetPlayerController():SaveLocalData("sessions", sessionsData, true)
end

function SessionsData:SaveSession(session)
    if not session or not session.account or not session.loginServer then
        return false
    end

    local oldSession = self:GetSessionByUsername(session.account)

    if oldSession then
        for key, item in pairs(oldSession) do
            if session[key] == nil then
                session[key] = item
            end
        end
    end

    if session.rememberMe == false then
        session.password = nil
    end

    session.account = string.lower(session.account)
    session.loginTime = os.time()

    local sessionsData = self:GetSessions()
    sessionsData.selectedUser = session.account

    local beExist = false

    for key, item in ipairs(sessionsData.allUsers) do
        if item.value == session.account then
            item.session = session
            beExist = true
        end
    end

    if not beExist then
        sessionsData.allUsers[#sessionsData.allUsers + 1] = {
            value = session.account,
            text = session.account,
            session = session
        }
    end

    GameLogic.GetPlayerController():SaveLocalData("sessions", sessionsData, true)
end

function SessionsData:GetAnonymousUser()
    local default = {
        value = 'ano',
        text = 'ano',
        session = {
            account = 'ano',
            loginServer = Config.defaultEnv,
        }
    }

    local sessionsData = self:GetSessions()

    if not sessionsData or not sessionsData.allUsers then
        return default
    end

    for key, item in ipairs(sessionsData.allUsers) do
        if item.value == 'ano' then
            return item
        end
    end

    return default
end

function SessionsData:GetAnonymousInfo()
    local anonymousUser = self:GetAnonymousUser()

    if anonymousUser and anonymousUser.anonymousInfo and type(anonymousUser.anonymousInfo) == 'table' then
        return anonymousUser.anonymousInfo
    else
        return {}
    end
end

function SessionsData:SetAnyonymousInfo(key, value)
    if not key or type(key) ~= 'string' or not value then
        return false
    end

    local anonymousInfo = self:GetAnonymousInfo()

    anonymousInfo[key] = value

    local sessionsData = self:GetSessions()

    if not sessionsData or type(sessionsData) ~= 'table' then
        return false
    end

    local beExist = false

    for key, item in ipairs(sessionsData.allUsers) do
        if item.value == 'ano' then
            item.anonymousInfo = anonymousInfo
            beExist = true
        end
    end

    if not beExist then
        local anoUser = self:GetAnonymousUser()

        anoUser.anonymousInfo = anonymousInfo

        sessionsData.allUsers[#sessionsData.allUsers + 1] = anoUser
    end

    GameLogic.GetPlayerController():SaveLocalData("sessions", sessionsData, true)

    return true
end

function SessionsData:GetSessionByUsername(username)
    local sessionsData = SessionsData:GetSessions()

    if not sessionsData or not sessionsData.allUsers then
        return false
    end

    for key, item in ipairs(sessionsData.allUsers) do
        if item.value == username then
            return item.session
        end
    end

    return false
end

function SessionsData:GetDeviceUUID()
    return ParaEngine.GetAttributeObject():GetField('MachineID', '')
end

function SessionsData:GetUserLastPosition(projectId, username)
    if not username then
        username = Mod.WorldShare.Store:Get('user/username')
    end

    if not projectId then
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

        if not currentEnterWorld or not currentEnterWorld.kpProjectId or currentEnterWorld.kpProjectId == 0 then
            return
        end

        projectId = currentEnterWorld.kpProjectId
    end

    local session = self:GetSessionByUsername(username)

    if not session or type(session) ~= 'table' then
        return
    end

    if session.allPositions and type(session.allPositions) == 'table' then
        for key, item in ipairs(session.allPositions) do
            if tonumber(item.projectId) == tonumber(projectId) then
                return item
            end
        end
    end
end

function SessionsData:SetUserLocation(where, username)
    local session = self:GetSessionByUsername(username)

    if not session or type(session) ~= 'table' then
        return
    end

    session.where = where
    self:SaveSession(session)
end

function SessionsData:SetUserLastPosition(x, y, z, cameraLiftupAngle, cameraRotY, projectId, username)
    if not x or not y or not z or not cameraLiftupAngle or not cameraRotY then
        return
    end

    if not username then
        username = Mod.WorldShare.Store:Get('user/username')
    end

    if not projectId then
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

        if not currentEnterWorld or not currentEnterWorld.kpProjectId or currentEnterWorld.kpProjectId == 0 then
            return
        end

        projectId = currentEnterWorld.kpProjectId
    end

    local session = self:GetSessionByUsername(username)

    if not session or type(session) ~= 'table' then
        return
    end

    local beExist = false
    local curItem = {}

    if session.allPositions and type(session.allPositions) == 'table' then
        for key, item in ipairs(session.allPositions) do
            if tonumber(item.projectId) == tonumber(projectId) then
                beExist = true
                curItem = item
                break
            end
        end
    end

    if beExist then
        curItem.position = { x = x, y = y, z = z }
        curItem.orientation = { cameraLiftupAngle = cameraLiftupAngle , cameraRotY = cameraRotY }
    else
        curItem = {
            projectId = projectId,
            position = { x = x, y = y, z = z },
            orientation = { cameraLiftupAngle = cameraLiftupAngle , cameraRotY = cameraRotY }
        }

        if not session.allPositions or type(session.allPositions) ~= 'table' then
            session.allPositions = {}
        end

        session.allPositions[#session.allPositions + 1] = curItem
    end

    self:SaveSession(session)
end
