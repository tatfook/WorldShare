--[[
Title: SessionsData
Author(s):  big
Date: 2019.07.24
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local SessionsData = NPL.load("(gl)Mod/WorldShare/database/SessionsData.lua")
------------------------------------------------------------
]] local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

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
                tokenExpire = 12345678
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

    if not session.allPositions then
        local oldSession = self:GetSessionByUsername(session.account)

        if oldSession and oldSession.allPositions then
            session.allPositions = oldSession.allPositions
        end
    end

    session.account = string.lower(session.account)

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
    local sessionsData = self:GetSessions()
    local currentParacraftDir = ParaIO.GetWritablePath()

    if not sessionsData.softwareUUID or
       not sessionsData.paracraftDir or
       sessionsData.paracraftDir ~= currentParacraftDir then
        sessionsData.paracraftDir = ParaIO.GetWritablePath()
        sessionsData.softwareUUID = System.Encoding.guid.uuid()
        GameLogic.GetPlayerController():SaveLocalData("sessions", sessionsData, true)
    end

    local machineID = ParaEngine.GetAttributeObject():GetField("MachineID","")

    return sessionsData.softwareUUID .. "-" .. machineID
end

function SessionsData:GetUserLastPosition(projectId, username)
    if not username then
        username = Mod.WorldShare.Store:Get('user/username')
    end

    if not projectId then
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

        if not currentEnterWorld or not currentEnterWorld.kpProjectId then
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

function SessionsData:SetUserLastPosition(x, y, z, cameraLiftupAngle, cameraRotY, projectId, username)
    if not x or not y or not z or not cameraLiftupAngle or not cameraRotY then
        return
    end

    if not username then
        username = Mod.WorldShare.Store:Get('user/username')
    end

    if not projectId then
        local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

        if not currentEnterWorld or not currentEnterWorld.kpProjectId then
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
