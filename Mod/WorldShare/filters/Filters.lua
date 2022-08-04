--[[
Title: filters
Author(s): big
CreateDate: 2020.12.11
ModifyDate: 2021.11.15
Desc: 
use the lib:
------------------------------------------------------------
local Filters = NPL.load('(gl)Mod/WorldShare/filters/Filters.lua')
Filters:Init()
------------------------------------------------------------
]]

-- bottles
local MainLogin = NPL.load('(gl)Mod/WorldShare/cellar/MainLogin/MainLogin.lua')
local Create = NPL.load('(gl)Mod/WorldShare/cellar/Create/Create.lua')
local WorldExitDialog = NPL.load('(gl)Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
local ShareWorld = NPL.load('(gl)Mod/WorldShare/cellar/ShareWorld/ShareWorld.lua')
local CreateWorld = NPL.load('(gl)Mod/WorldShare/cellar/CreateWorld/CreateWorld.lua')
local Permission = NPL.load('(gl)Mod/WorldShare/cellar/Permission/Permission.lua')
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local Server = NPL.load("(gl)Mod/WorldShare/cellar/Server/Server.lua")
local Menu = NPL.load('(gl)Mod/WorldShare/cellar/Menu/Menu.lua')
local SyncWorld = NPL.load('(gl)Mod/WorldShare/cellar/Sync/SyncWorld.lua')
local Certificate = NPL.load("(gl)Mod/WorldShare/cellar/Certificate/Certificate.lua")

-- api
local QiniuRootApi = NPL.load("(gl)Mod/WorldShare/api/Qiniu/QiniuRootApi.lua")
local SocketBaseApi = NPL.load("(gl)Mod/WorldShare/api/Socket/BaseApi.lua")

-- service
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')
local KeepworkServiceSchoolAndOrg = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/SchoolAndOrg.lua")
local KeepworkServiceWorld = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceWorld.lua")
local KeepworkService = NPL.load("(gl)Mod/WorldShare/service/KeepworkService.lua")
local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
local EventTrackingService = NPL.load('(gl)Mod/WorldShare/service/EventTracking.lua')
local LocalServiceWorld = NPL.load('(gl)Mod/WorldShare/service/LocalService/LocalServiceWorld.lua')

-- libs
local GameLogic = commonlib.gettable('MyCompany.Aries.Game.GameLogic')
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop")

-- command
local MenuCommand = NPL.load('(gl)Mod/WorldShare/command/Menu.lua')

-- load all filters
local MySchoolFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/MySchool/MySchoolFilter.lua')
local VipNoticeFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/VipNotice/VipNoticeFilter.lua')
local ClientUpdateDialogFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/ClientUpdateDialog/ClientUpdateDialogFilter.lua')
local MsgBoxFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Common/MsgBox/MsgBoxFilter.lua')
local MainLoginFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/MainLogin/MainLoginFilter.lua')
local ShareWorldFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/ShareWorld/ShareWorldFilter.lua')
local SyncMainFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Sync/SyncMainFilter.lua')
local CommonLoadWorldFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Common/LoadWorld/CommonLoadWorldFilter.lua')
local OpusFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Opus/OpusFilter.lua')

local KeepworkServiceSessionFilter = NPL.load('(gl)Mod/WorldShare/filters/service/KeepworkService/KeepworkServiceSessionFilter.lua')
local LocalServiceWorldFilter = NPL.load('(gl)Mod/WorldShare/filters/service/LocalService/LocalServiceWorldFilter.lua')
local LocalServiceFilter = NPL.load('(gl)Mod/WorldShare/filters/service/LocalService/LocalServiceFilter.lua')
local GitServiceFilter = NPL.load('(gl)Mod/WorldShare/filters/service/GitServiceFilter.lua')
local KeepworkServiceWorldFilter = NPL.load('(gl)Mod/WorldShare/filters/service/KeepworkService/KeepworkServiceWorldFilter.lua')
local SyncToDataSourceFilter = NPL.load('(gl)Mod/WorldShare/filters/service/SyncService/SyncToDataSourceFilter.lua')

local KeepworkProjectsApiFilter = NPL.load('(gl)Mod/WorldShare/filters/api/Keepwork/KeepworkProjectsApiFilter.lua')

local SessionsDataFilter = NPL.load('(gl)Mod/WorldShare/filters/database/SessionsDataFilter.lua')

local OnWorldInitialRegionsLoadedFilter = NPL.load('(gl)Mod/WorldShare/filters/libs/OnWorldInitialRegionsLoadedFilter.lua')
local WorldInfoFilter = NPL.load('(gl)Mod/WorldShare/filters/libs/WorldInfoFilter.lua')
local CertificateFilter = NPL.load('(gl)Mod/WorldShare/filters/cellar/Certificate/CertificateFilter.lua')
local KeepworkServiceProjectFilter = NPL.load('(gl)Mod/WorldShare/filters/service/KeepworkService/KeepworkServiceProjectFilter.lua')

local Filters = NPL.export()

function Filters:Init()
    -- init session filter
    KeepworkServiceSessionFilter:Init()

    -- init myschool filter
    MySchoolFilter:Init()

    -- init vip notice filter
    VipNoticeFilter:Init()

    -- init client update dialog filter
    ClientUpdateDialogFilter:Init()

    -- init msg box filter
    MsgBoxFilter:Init()

    -- init on load block region filter
    OnWorldInitialRegionsLoadedFilter:Init()

    -- init world info filter
    WorldInfoFilter:Init()

    -- init local service world filter
    LocalServiceWorldFilter:Init()

    -- init main login filter
    MainLoginFilter:Init()

    -- init git service filter
    GitServiceFilter:Init()

    -- init keepwork projects api filter
    KeepworkProjectsApiFilter:Init()

    -- init common load world filter
    CommonLoadWorldFilter:Init()

    -- init local service filter
    LocalServiceFilter:Init()

    -- init share world filter
    ShareWorldFilter:Init()

    -- init sync main filter
    SyncMainFilter:Init()

    -- init sessions data filter
    SessionsDataFilter:Init()

    -- init CertificateFilter filter
    CertificateFilter:Init()

    -- init keepwork service filters
    KeepworkServiceProjectFilter:Init()

    KeepworkServiceWorldFilter:Init()

    SyncToDataSourceFilter:Init()

    OpusFilter:Init()

    GameLogic.GetFilters():add_filter(
        'ShowClientUpdaterNotice',
        function()
            if Mod.WorldShare.Utils.IsEnglish() then
                Mod.WorldShare.MsgBox:Show(L'checking for updates...', nil, nil, nil, nil, nil, '_ct')
            else
                Mod.WorldShare.MsgBox:Show(L'正在检查更新， 请稍候...', nil, nil, nil, nil, nil, '_ct')
            end
        end
    )

    GameLogic.GetFilters():add_filter(
        'HideClientUpdaterNotice',
        function()
            Mod.WorldShare.MsgBox:Close()
        end
    )

    -- replace the exit world dialog
    GameLogic.GetFilters():add_filter(
        'ShowExitDialog',
        function(dialog)
            if (dialog and dialog.callback) then
                WorldExitDialog.ShowPage(dialog.callback)
                return nil
            end
        end
    )

    -- replace share world page
    GameLogic.GetFilters():add_filter(
        'SaveWorldPage.ShowSharePage',
        function(callback)
            NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua")
            NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldMiniChunkGenerator.lua")

            local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
            local generatorName = WorldCommon.GetWorldTag("world_generator")
            local ParaWorldMiniChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldMiniChunkGenerator")
            local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

            if string.match(currentEnterWorld.foldername, '.+_main') and generatorName == "paraworldMini" then
                ParaWorldMiniChunkGenerator:OnSaveWorld()
            else
                ShareWorld:Init(callback)
            end

            return false
        end
    )

    -- replace implement or replace create new world event
    GameLogic.GetFilters():add_filter(
        'OnClickCreateWorld',
        function()
            return CreateWorld.OnClickCreateWorld()
        end
    )

    -- filter KeepworkPremission
    GameLogic.GetFilters():add_filter(
        'KeepworkPermission',
        function(bEnabled, authName, bOpenUIIfNot, callback, uiType)
            Permission:CheckPermission(authName, bOpenUIIfNot, callback, uiType)

            return true
        end
    )

    -- filter CheckSignedIn
    GameLogic:GetFilters():add_filter(
        'LoginModal.CheckSignedIn',
        function(bEnabled, desc, callback)
            LoginModal:CheckSignedIn(desc, callback)
            return true
        end
    )
    
    -- filter menu project
    GameLogic:GetFilters():add_filter(
        'desktop_menu',
        function(menuItems)
            return Menu:Init(menuItems)
        end
    )

    -- filter menu command
    GameLogic:GetFilters():add_filter(
        'menu_command',
        function(bEnable, cmdName, cmdText, cmdParams)
            return MenuCommand:Call(cmdName, cmdText, cmdParams)
        end
    )

    -- filter user behavior
    GameLogic:GetFilters():add_filter(
        'user_behavior',
        function(type, action, extra)
            EventTrackingService:Send(type, action, extra)
        end
    )

    -- filter old user behavior
    GameLogic:GetFilters():add_filter(
        'user_event_stat',
        function(category, action, value, label)
            local sArray = {}

            for item in string.gmatch(action, "[^%:]+") do
                sArray[#sArray + 1] = item
            end

            local newActionName = "click.world." .. category .. "." .. sArray[1]

            EventTrackingService:Send(1, newActionName)

            -- count edit block
            if newActionName == 'click.world.block.create' or
               newActionName == 'click.world.block.destroy' then
                local blockCount = Mod.WorldShare.Store:Get('world/blockCount')

                if not blockCount or type(blockCount) ~= 'number' then
                    blockCount = 0
                end

                if newActionName == 'click.world.block.create' then
                    blockCount = blockCount + 1
                end

                if newActionName == 'click.world.block.destroy' then
                    blockCount = blockCount - 1
                end

                Mod.WorldShare.Store:Set('world/blockCount', blockCount)
            end

            return category
        end
    )

    -- filter is signed in
    GameLogic.GetFilters():add_filter(
        'is_signed_in',
        function()
            return KeepworkServiceSession:IsSignedIn()
        end
    )

    -- filter set mode
    GameLogic.GetFilters():add_filter(
        'set_mode',
        function(mode, bFireModeChangeEvent)
            local loadWorldFinish = Mod.WorldShare.Store:Get('world/loadWorldFinish')

            if loadWorldFinish then
                if mode == 'editor' then
                    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.world.edit");

                    -- stop play event tracking
                    if GameLogic.GameMode:GetMode() ~= mode then
                        GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.world.play", { ended = true });
                    end
            
                    GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.world.edit", { started = true });
                else
                    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.world.play");

                    -- stop edit event tracking
                    if GameLogic.GameMode:GetMode() ~= mode then
                        GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.world.edit", { ended = true });
                    end
            
                    GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.world.play", { started = true });
                end
            end
        end
    )

    -- filter get user type
    GameLogic.GetFilters():add_filter(
        'get_user_type',
        function()
            return Mod.WorldShare.Store:Get("user/userType")
        end
    )

    -- filter get user id
    GameLogic.GetFilters():add_filter(
        'get_user_id',
        function()
            return Mod.WorldShare.Store:Get("user/userId") or 0
        end
    )

    -- filter get world by project id
    GameLogic.GetFilters():add_filter(
        'get_world_by_project_id',
        function(projectId, callback)
            KeepworkServiceWorld:GetWorldByProjectId(projectId, callback)
        end
    )

    -- filter get keepwork url
    GameLogic.GetFilters():add_filter(
        'get_keepwork_url',
        function()
            return KeepworkService:GetKeepworkUrl()
        end
    )

    -- filter get project id by lesson id
    GameLogic.GetFilters():add_filter(
        'get_project_id_by_lesson_id',
        function(txtLessonId)
            return Mod.WorldShare.Utils.GetProjectId(txtLessonId)
        end
    )

    -- filter on exit
    GameLogic.GetFilters():add_filter(
        'on_exit',
        function(bForceExit, bRestart, callback)
            EventTrackingService:SaveToDisk()

            if System.options.isForceOffline then
                Desktop.ForceExit()
                return
            end

            if callback and type(callback) == 'function' then
                callback()
            end
        end
    )

    -- filter open keepwork url with token
    GameLogic.GetFilters():add_filter(
        'open_keepwork_url',
        function(url)
            Mod.WorldShare.Utils.OpenKeepworkUrlByToken(url)
        end
    )

    -- filter check signed in
    GameLogic.GetFilters():add_filter(
        'check_signed_in',
        function(text, callback)
            LoginModal:CheckSignedIn(text, callback)
        end
    )

    -- filter show login page
    GameLogic.GetFilters():add_filter(
        'show_login_page',
        function()
            LoginModal:Init()
        end
    )

    -- filter qiniu upload file
    GameLogic.GetFilters():add_filter(
        'qiniu_upload_file',
        function(token, key, filename, content, callback)
            QiniuRootApi:Upload(token, key, filename, content, callback, callback)
        end
    )

    -- filter show create page
    GameLogic.GetFilters():add_filter(
        'show_create_page',
        function()
            Create:Show()
		    return Mod.WorldShare.Store:Get('page/Mod.WorldShare.Create')
        end
    )

    -- filter compare init
    GameLogic.GetFilters():add_filter(
        'compare_init',
        function(worldpath, callback)
            Compare:Init(worldpath, callback)
        end
    )

    -- filter get current world
    GameLogic.GetFilters():add_filter(
        'current_world',
        function()
            return Mod.WorldShare.Store:Get('world/currentWorld')
        end
    )

    -- filter show offical worlds 
    GameLogic.GetFilters():add_filter(
        'show_offical_worlds_page',
        function(...)
            GameLogic.GetFilters():apply_filters('cellar.explorer.show', ...)
        end
    )

    -- filter check world updated before enter my home
    GameLogic.GetFilters():add_filter(
        'check_and_updated_before_enter_my_home',
        function(callback)
            SyncWorld:CheckAndUpdatedBeforeEnterMyHome(function()
                GameLogic.RunCommand("/loadworld home");
            end)
        end
    )

    -- filter show server page
    GameLogic.GetFilters():add_filter(
        'show_server_page',
        function()
            Server:ShowPage()
        end
    )

    -- filter get my orgs and school
    GameLogic.GetFilters():add_filter(
        'get_my_orgs_and_schools',
        function(callback)
            KeepworkServiceSchoolAndOrg:GetMyAllOrgsAndSchools(callback)
        end
    )

    -- filter get school region
    GameLogic.GetFilters():add_filter(
        'get_school_region',
        function(selectType, parentId, callback)
            KeepworkServiceSchoolAndOrg:GetSchoolRegion(selectType, parentId, callback)
        end
    )

    -- filter store set data
    GameLogic.GetFilters():add_filter(
        'store_set',
        function(key, value)
            Mod.WorldShare.Store:Set(key, value)
        end
    )

    -- filter store get data
    GameLogic.GetFilters():add_filter(
        'store_get',
        function(key)
            return Mod.WorldShare.Store:Get(key)
        end
    )

    -- filter get single file
    GameLogic.GetFilters():add_filter(
        'get_single_file',
        function(pid, filename, callback, cdnState)
            KeepworkServiceWorld:GetSingleFile(pid, filename, callback, cdnState)
        end
    )

    -- filter get single file by commit id
    GameLogic.GetFilters():add_filter(
        'get_single_file_by_commit_id',
        function(pid, commitId, filename, callback, cdnState)
            KeepworkServiceWorld:GetSingleFileByCommitId(pid, commitId, filename, callback, cdnState)
        end
    )

    -- filter get socket url
    GameLogic.GetFilters():add_filter(
        'get_socket_url',
        function()
            return SocketBaseApi:GetApi()
        end
    )

    -- filter get api url
    GameLogic.GetFilters():add_filter(
        'get_core_api_url',
        function()
            return KeepworkService:GetCoreApi()
        end
    )

    -- filter show certificate icon
    GameLogic.GetFilters():add_filter(
        'show_certificate',
        function(callback)
            Certificate:Init(callback)
        end
    )

    -- filter show panorama
    GameLogic.GetFilters():add_filter(
        'show_panorama',
        function(callback)
            local Panorama = NPL.load("(gl)Mod/WorldShare/cellar/Panorama/Panorama.lua")
            Panorama:ShowCreate(true)
        end
    )

    -- filter download remote world show bbs
    GameLogic.GetFilters():add_filter(
        'download_remote_world_show_bbs',
        function()
            return false
        end
    )

    --vip button
    GameLogic.GetFilters():add_filter("get_vip_btn_div", function(styleStr,key,desc)
        if System.options.channelId=="430" then
            return nil
        end
        if _G._main_on_vipbtn_click==nil then
            _G._main_on_vipbtn_click = function()
                local cmd = string.format("/vip show -key=%s -desc=%s",key or "",desc or "")
                GameLogic.RunCommand(cmd);
            end
        end
        local str =  [[
            <input type="button" value='' onclick="_main_on_vipbtn_click" class="red_summer_camp_open_vip_btn" style="%s" />
        ]]
        styleStr = styleStr or "margin-right:20px;margin-top:5px;";
        str = string.format(str,styleStr)
        return str
    end);
    -- vip time icon
    GameLogic.GetFilters():add_filter("get_vip_time_icon_div" ,function (margin_top,click_func_name)
        local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
        local profile = KeepWorkItemManager.GetProfile()
        if not profile.vipDeadline or profile.vipDeadline == "" then
            return ""
        end
        if System.options.channelId=="430" then
            return ""
        end

        local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(profile.vipDeadline)
        --time_stamp = RedSummerCampSchoolMainPage.TimeVip or time_stamp
        local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
        local cur_time_stamp = QuestAction.GetServerTime()

        --test
        -- time_stamp = test_time1 or time_stamp
        -- cur_time_stamp = test2 or cur_time_stamp

        local left_time = time_stamp - cur_time_stamp
        if left_time < 0 then
            return ""
        end

        local min = math.floor(left_time/60)
        local hour = math.floor(min/60) 
        local day = math.floor(hour/24)

        
        if day > 30 then
            return ""
        end

        local show_value = day >= 1 and day or hour
        local unit_icon = day >= 1 and "Texture/Aries/Creator/keepwork/vip/vip_time/tian_10x9_32bits.png#0 0 10 9" or "Texture/Aries/Creator/keepwork/vip/vip_time/xiaoshi_9x8_32bits.png#0 0 9 8"

        local show_value_desc = "0" .. show_value
        local num_margin_left = -8
        local unit_margin_left = -10

        if show_value == 21 then
            num_margin_left = -13
            unit_margin_left = 0
        elseif show_value == 1 then
            num_margin_left = -2
            unit_margin_left = -20 
        elseif show_value == 11 then
            num_margin_left = -5
            unit_margin_left = -15
        elseif show_value >= 20 then
            num_margin_left = -16
            unit_margin_left = 3
        elseif show_value >= 10 then
            num_margin_left = -13
            unit_margin_left = -3 
        end

        margin_top = margin_top or 16
        click_func_name = click_func_name or "OpenVip"
        local div = [[
        <pe:container name="VipLimitTimeIcon" style="float: left;margin-right:15px;margin-top:%s; width: 66px;height: 67px; background: url()">
            <input zorder = "-1" type="button" value='' onclick="%s" is_tool_tip_click_enabled="true" is_lock_position="true" enable_tooltip_hover="true"
                tooltip='page_static://script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/VipTimeToolTip.html'
                style="position:relative;margin-left:0px;margin-top:0px;width:66px;height:70px;background: url(Texture/Aries/Creator/keepwork/vip/vip_time/dipan_66x70_32bits.png#0 0 66 70)" />
            <div style="margin-top: 18px;">
                <pe:textsprite ClickThrough="true" name="VipLimitTimeNum" fontName="VipLimitTime" value = '%s' style="float: left;width: 63px; margin-left:%s;margin-top:2px;font-size:20pt;" />
                <div style="float: left;margin-left: %s;margin-top: 13px; width: 10px;height: 9px; background: url(%s)"></div>
            </div>
        </pe:container>
        ]]

        div = string.format(div, margin_top, click_func_name, show_value_desc, num_margin_left, unit_margin_left, unit_icon)
        return div
    end)
    
    GameLogic.GetFilters():add_filter('SaveWorld', function(_, callback)
        if not callback or type(callback) ~= 'function' then
            return false
        end

        callback()

        LocalServiceWorld:OnSaveWorld()

        if ShareWorld:GetPage() then
            local currentRevision = Mod.WorldShare.Store:Get('world/currentRevision')

            ShareWorld:GetPage():SetUIValue('current_revision', currentRevision)
        end

        return true
    end)
end