--[[
Title: CreateWorld
Author(s):  big
Date: 2018.08.1
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
------------------------------------------------------------
]]

-- libs
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')
local ShareWorldPage = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage')
local CreateNewWorld = commonlib.gettable('MyCompany.Aries.Game.MainLogin.CreateNewWorld')
local WorldCommon = commonlib.gettable('MyCompany.Aries.Creator.WorldCommon')

-- helper
local Utils = NPL.load('(gl)Mod/WorldShare/helper/Utils.lua')

-- UI
local SyncMain = NPL.load('(gl)Mod/WorldShare/cellar/Sync/Main.lua')
local UserConsole = NPL.load('(gl)Mod/WorldShare/cellar/UserConsole/Main.lua')

-- service
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/World.lua')

local CreateWorld = NPL.export()

function CreateWorld:CreateNewWorld(foldername)
    CreateNewWorld.ShowPage()

    if type(foldername) == 'string' then
        CreateNewWorld.page:SetValue('new_world_name', foldername)
        CreateNewWorld.page:Refresh(0.01)
    end
end

function CreateWorld.OnClickCreateWorld(worldsTemplate)
    local worldName = CreateNewWorld.page:GetValue('new_world_name')

    if worldName == "" then
		_guihelper.MessageBox(L"世界名字不能为空, 请输入世界名称");
		return
	end

    local realWorldName = worldName .. '_' .. System.Encoding.guid.uuid()
    local localWorldList = LocalServiceWorld:GetWorldList()

    for key, item in ipairs(localWorldList) do
        if item and item.foldername then
            if item.foldername == worldName then
                _guihelper.MessageBox(L'此世界名已存在，请换一个名称，或删除同名的世界')
                return
            end
        end
    end

	local templWorld = worldsTemplate[CreateNewWorld.SelectedWorldTemplate_Index or 1]
    if not templWorld then 
        return
    end

	worldName = worldName or CreateNewWorld.default_worldname
	worldName = worldName:gsub("[%s/\\]", "")

	local worldNameLocale = commonlib.Encoding.Utf8ToDefault(realWorldName)

	local params = {
		worldname = worldNameLocale,
		title = worldName,
		creationfolder = CreateNewWorld.GetWorldFolder(),
		parentworld = templWorld.parent_world_path,
		world_generator = CreateNewWorld.cur_terrain.terrain or templ_world.world_generator,
		seed = worldName,
		inherit_scene = true,
		inherit_char = true,
	}

	LOG.std(nil, "debug", "Mod.WorldShare.cellar.CreateNewWorld.CreateWorld", params);

	GameLogic.GetFilters():apply_filters("user_event_stat", "world", "create:" .. tostring(worldName), 10, nil);

    local worldpath, errorMsg = CreateNewWorld.CreateWorld(params)

	if not worldpath then
		if errorMsg then
			_guihelper.MessageBox(errorMsg);
		end
	else
		LOG.std(nil, "info", "Mod.WorldShare.cellar.CreateNewWorld.CreateWorld", "new world created at %s", worldpath)
		CreateNewWorld.ClosePage()
		WorldCommon.OpenWorld(worldpath, true)
		GameLogic:UserAction("introduction")
	end

    Mod.WorldShare.Store:Remove('world/currentWorld')
end

function CreateWorld:CheckRevision(callback)
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or type(currentWorld) ~= 'table' then
        return false
    end

    if not currentWorld.is_zip and not Compare:HasRevision() then
        Mod.WorldShare.MsgBox:Show(L'正在初始化世界...')
        self:CreateRevisionXml()
        Mod.WorldShare.MsgBox:Close()
    else
        return false
    end
end

function CreateWorld:CreateRevisionXml()
    local currentWorld = Mod.WorldShare.Store:Get('world/currentWorld')

    if not currentWorld or not currentWorld.worldpath then
        return false
    end

    local revisionPath = format('%s/revision.xml', currentWorld.worldpath)

    local exist = ParaIO.DoesFileExist(revisionPath)

    if not exist then
        local file = ParaIO.open(revisionPath, 'w');
        file:WriteString('1')
        file:close();
    end
end

function CreateWorld:CheckSpecialCharacter(foldername)
    if string.match(foldername, '[_`~!@#$%%^&*()+=|{}":;",%[%]%.<>/?~！@#￥%……&*（）——+|{}；：”“。，、？©]+') then
        GameLogic.AddBBS(nil, L'世界名称不能含有特殊字符', 3000, '255 0 0')
        return false
    end

    return true
end