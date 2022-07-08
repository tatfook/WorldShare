--[[
Title: world menu command
Author(s): big
Date: 2020/8/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load('(gl)Mod/WorldShare/command/Menu.lua')
-------------------------------------------------------
]]

-- load lib
local CmdParser = commonlib.gettable('MyCompany.Aries.Game.CmdParser')
local Commands = commonlib.gettable('MyCompany.Aries.Game.Commands')

-- service
local KeepworkService = NPL.load('(gl)Mod/WorldShare/service/KeepworkService.lua')
local EventTrackingService = NPL.load('(gl)Mod/WorldShare/service/EventTracking.lua')

-- UI
local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua')
local OpusSetting = NPL.load('(gl)Mod/WorldShare/cellar/OpusSetting/OpusSetting.lua')
local MemberManager = NPL.load('(gl)Mod/WorldShare/cellar/MemberManager/MemberManager.lua')
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')

local MenuCommand = NPL.export()

function MenuCommand:Init()
    NPL.load('(gl)script/apps/Aries/Creator/Game/Commands/CommandMenu.lua');
    Commands['menu'].desc = Commands['menu'].desc .. [[
/menu project.share
/menu project.index
/menu project.author
/menu project.setting
/menu project.apply
]]
end

function MenuCommand:Call(cmdName, cmdText, cmdParams)
    local name, cmdText = CmdParser.ParseString(cmdText);
    if name and type(name) == 'string' then
        local action = 'click.menu.' .. name

        EventTrackingService:Send(1, action)
    end

    if name == 'file.createworld' then
        self:CreateWorld()
        return true
    elseif name == 'project.share' then
        self:Share()
        return true
    elseif name == 'project.index' then
        self:OpenUserOpusPage()
        return true
    elseif name == 'project.author' then
        self:OpenUserPage()
        return true
    elseif name == 'project.setting' then
        self:OpusSetting()
        return true
    elseif name == 'project.member' then
        self:MemberManager()
        return true
    elseif name == 'project.apply' then
        self:Apply()
        return true
    elseif name == 'project.unfavorite' then
        self:Favorite(true)
        return true
    elseif name == 'project.favorite' then
        self:Favorite(false)
        return true
    elseif name == 'project.like' then
        self:LikeProject()
        return true
    elseif name == 'project.unlike' then
        return true
    end

    return false
end

function MenuCommand:Share()
    ShareWorld:Init()
end

GameLogic.GetFilters():add_filter(
    'favorite_change',
    function (data)
        MenuCommand:ChangeFavoriteItemState(data.showFavorite)
    end
)

GameLogic.GetFilters():add_filter(
    'like_change',
    function (data)
        MenuCommand:ChangeLikeItemState(data.isLiked)
    end
)

function MenuCommand:ChangeLikeItemState(isLiked)
    NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenu.lua');
    local DesktopMenu = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop.DesktopMenu')
    local projectMenu = DesktopMenu.GetMenuItem('project')
    if projectMenu then
        for index, item in ipairs(projectMenu.children) do
            if(item.Type ~= 'Separator' ) then
                if isLiked and item.name == 'project.like' then
                    item.name = 'project.unlike'
                    item.text = L'今日已点'
                elseif not isLiked and item.name == 'project.unlike'  then
                    item.name = 'project.like'
                    item.text = L'点赞项目'
                end
            end
        end
        DesktopMenu.RebuildMenuItem(projectMenu)
    end
end

function MenuCommand:ChangeFavoriteItemState(showFavorite)
    NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/DesktopMenu.lua');
    local DesktopMenu = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop.DesktopMenu')
    local projectMenu = DesktopMenu.GetMenuItem('project')
    if projectMenu then
        for index, item in ipairs(projectMenu.children) do
            if(item.Type ~= 'Separator' ) then
                if showFavorite and item.name == 'project.unfavorite' then
                    item.name = 'project.favorite'
                    item.text = L'收藏项目'
                elseif not showFavorite and item.name == 'project.favorite'  then
                    item.name = 'project.unfavorite'
                    item.text = L'取消收藏'
                end
            end
        end
        DesktopMenu.RebuildMenuItem(projectMenu)
    end
end

function MenuCommand:LikeProject()
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
		GameLogic.GetFilters():apply_filters('check_signed_in', '请先登录', function(result)
			if result == true then
				commonlib.TimerManager.SetTimeout(function()

				end, 500)
			end
		end)

		return
	end

    NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/keepwork.user.lua')
    NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua')
    local ProjectId = GameLogic.options:GetProjectId()
    if ProjectId then
        keepwork.world.star({router_params = {id = ProjectId}}, function(err, msg, data)
            local isLiked = err == 200
            self:ChangeLikeItemState(isLiked)
        end)
    else
        GameLogic.AddBBS(nil, L'点赞失败，请先分享该项目，再重试！', 3000, '255 0 0')
    end
end

function MenuCommand:Favorite(isFavorited)
    if not GameLogic.GetFilters():apply_filters('is_signed_in') then
		GameLogic.GetFilters():apply_filters('check_signed_in', '请先登录', function(result)
			if result == true then
				commonlib.TimerManager.SetTimeout(function()

				end, 500)
			end
		end)

		return
	end

    NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/keepwork.user.lua')
    NPL.load('(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua')
    local ProjectId = GameLogic.options:GetProjectId()
    if ProjectId then
        if isFavorited then
            keepwork.world.unfavorite({objectId = ProjectId, objectType = 5}, function(err, msg, data)
                if (err == 200) then
                    --GameLogic.AddBBS(nil, L'项目取消收藏成功', 3000, '0 255 0')
                    self:ChangeFavoriteItemState(true)
                elseif (err == 500) then
                    GameLogic.AddBBS(nil, L'该项目已被其作者删除', 3000, '0 255 0')
                end
            end);
        else
            keepwork.world.favorite({objectId = ProjectId, objectType = 5}, function(err, msg, data)
                if (err == 200) then
                    --GameLogic.AddBBS(nil, L'项目收藏成功', 3000, '0 255 0')
                    self:ChangeFavoriteItemState(false)
                elseif (err == 500) then
                    GameLogic.AddBBS(nil, L'该项目已被其作者删除', 3000, '0 255 0')
                else
                    GameLogic.AddBBS(nil, L'收藏项目失败，请重试！', 3000, '0 255 0')
                end
            end)
        end
        GameLogic.GetFilters():apply_filters('user_behavior', 1, 'click.home.favorited')
    else
        GameLogic.AddBBS(nil, L'收藏失败，请先分享该项目，再重试！', 3000, '255 0 0')
    end
end

function MenuCommand:OpenUserOpusPage()
    ParaGlobal.ShellExecute('open', KeepworkService:GetShareUrl(), '', '', 1)
end

function MenuCommand:OpenUserPage()
    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    local username = ''

    if currentEnterWorld and type(currentEnterWorld) == 'table' then
        if currentEnterWorld.user and currentEnterWorld.user.username then
            username = currentEnterWorld.user.username
        else
            return
        end
    else
        return
    end

    ParaGlobal.ShellExecute(
        'open',
        format(
            '%s/u/%s',
            KeepworkService:GetKeepworkUrl(),
            username
        ),
        '',
        '',
        1
    )
end

function MenuCommand:OpusSetting()
    OpusSetting:Show()
end

function MenuCommand:MemberManager()
    MemberManager:Show()
end

function MenuCommand:Apply()
    MemberManager:ShowApply()
end

function MenuCommand:CreateWorld()
    CreateWorld:CreateNewWorld()
end
