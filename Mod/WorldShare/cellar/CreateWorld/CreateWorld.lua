--[[
Title: CreateWorld
Author(s): big
CreateDate: 2018.08.01
ModifyDate: 2021.09.10
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
------------------------------------------------------------
]]

-- libs
NPL.load('(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua')

local CreateNewWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.CreateNewWorld')

-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')

-- service
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Session.lua')
local KeepworkServiceWorld = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua')

local CreateWorld = NPL.export()

function CreateWorld:CreateNewWorld(foldername, callback)
    local function Handle()
        CreateNewWorld.ShowPage(true)

        if type(foldername) == 'string' then
            CreateNewWorld.page:SetValue('new_world_name', foldername)
            CreateNewWorld.page:Refresh(0.01)
        end
    end

    if KeepworkServiceSession:IsSignedIn() then
        KeepworkServiceWorld:LimitFreeUser(false, function(result)
            if result then
                Handle()
            else
                GameLogic.ShowVipGuideTip("UnlimitWorldsNumber")
            end
        end)
    else
        LoginModal:CheckSignedIn(L'请先登录！', function(bIsSuccessed)
            if bIsSuccessed then
                _guihelper.MessageBox(L'登录成功')

                if callback and type(callback) == 'function' then
                    callback()
                end
            end
        end)
    end
end

function CreateWorld.OnClickCreateWorld()
    local foldername = CreateNewWorld.page:GetValue('new_world_name')
    local currentWorldList = Mod.WorldShare.Store:Get('world/compareWorldList') or {}

    for key, item in ipairs(currentWorldList) do
        if item.foldername == foldername then
            _guihelper.MessageBox(L'世界名已存在，请列表中进入')
            return true
        end
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

    if currentEnterWorld and currentEnterWorld.foldername == foldername then
        _guihelper.MessageBox(L'世界名已存在，请列表中进入')
        return true
    end

    local worldPath = ParaIO.GetWritablePath() .. 'worlds/DesignHouse/' .. foldername

    if ParaIO.DoesFileExist(worldPath, true) == true then
        Mod.WorldShare.worldpath = nil -- force update world data.
        local curWorldUsername = Mod.WorldShare:GetWorldData('username', worldPath)
        local backUpWorldPath

        if curWorldUsername then
            backUpWorldPath =
                'temp/sync_backup_world/' ..
                curWorldUsername ..
                '_' ..
                commonlib.Encoding.Utf8ToDefault(foldername)

            commonlib.Files.MoveFolder(worldPath, backUpWorldPath)

            ParaIO.DeleteFile(worldPath)
        end
    end

    Mod.WorldShare.Store:Remove('world/currentWorld')

    return false
end

function CreateWorld.ClosePage()
    CreateNewWorld.ClosePage()
end