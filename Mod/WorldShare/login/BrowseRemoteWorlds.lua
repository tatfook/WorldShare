--[[
Title: remote worlds
Author(s):  LiXizhi
Date: 2018/5/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/login/BrowseRemoteWorlds.lua");
local BrowseRemoteWorlds = commonlib.gettable("Mod.WorldShare.login.BrowseRemoteWorlds");
BrowseRemoteWorlds.ShowPage(callbackFunc)
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteServerList.lua");
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua");
local Encoding           = commonlib.gettable("commonlib.Encoding");
local InternetLoadWorld  = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local RemoteServerList   = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList");
local GameLogic          = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BrowseRemoteWorlds = commonlib.gettable("Mod.WorldShare.login.BrowseRemoteWorlds");
local SyncMain           = commonlib.gettable("Mod.WorldShare.sync.SyncMain");

BrowseRemoteWorlds.itemsPerLine = 3;

function BrowseRemoteWorlds.init()
    InternetLoadWorld.OnChangeType(2);
    BrowseRemoteWorlds.LoginPage = document:GetPageCtrl();
end

function BrowseRemoteWorlds.GetItemsPerLine()
    return BrowseRemoteWorlds.itemsPerLine;
end

-- @param callbackFunc: callbackFunc(bHasEnteredWorld) end
function BrowseRemoteWorlds.ShowPage(callbackFunc)
    BrowseRemoteWorlds.callbackFunc = callbackFunc;

    NPL.load("(gl)script/ide/System/Windows/Screen.lua");
    local Screen = commonlib.gettable("System.Windows.Screen");
    echo({Screen:GetWidth(), Screen:GetHeight()})

    BrowseRemoteWorlds.itemsPerLine = math.floor((Screen:GetWidth()-50)/255);

    local params = {
        url            = "Mod/WorldShare/login/BrowseRemoteWorlds.html", 
        name           = "BrowseRemoteWorlds", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style          = CommonCtrl.WindowFrame.ContainerStyle,
        zorder         = 0,
        allowDrag      = false,
        enable_esc_key = true,
        bShow          = true,
        directPosition = true,
        align          = "_fi",
        x              = 0,
        y              = 0,
        width          = 0,
        height         = 0,
        cancelShowAnimation = true,
    }
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    params._page.OnClose = function()
        BrowseRemoteWorlds.LoginPage  = nil;
        InternetLoadWorld.OnChangeType(1);
    end
   
    BrowseRemoteWorlds.RefreshCurrentServerList();
end

function BrowseRemoteWorlds.refreshPage()
    BrowseRemoteWorlds.LoginPage:Refresh();
end

function BrowseRemoteWorlds.GetWorldType()
    return InternetLoadWorld.type_ds;
end

function BrowseRemoteWorlds.GetCurWorldInfo(info_type, world_index)
    local index          = tonumber(world_index);
    local selected_world = InternetLoadWorld.cur_ds[world_index];

    if(selected_world) then
        if(info_type == "mode") then
            local mode = selected_world["world_mode"];

            if(mode == "edit") then
                return L"创作";
            else
                return L"参观";
            end
        else
            return selected_world[info_type];
        end
    end
end

function BrowseRemoteWorlds.OnClickBack()
    BrowseRemoteWorlds.ClosePage(false)
end

function BrowseRemoteWorlds.ClosePage(bHasEnteredWorld)
    if(BrowseRemoteWorlds.LoginPage) then
        BrowseRemoteWorlds.LoginPage:CloseWindow();
    end
    if(BrowseRemoteWorlds.callbackFunc) then
        BrowseRemoteWorlds.callbackFunc(bHasEnteredWorld);
    end
end

function BrowseRemoteWorlds.RefreshCurrentServerList(callback)
    if(BrowseRemoteWorlds.LoginPage) then
        BrowseRemoteWorlds.refreshing = true;
        BrowseRemoteWorlds.LoginPage:Refresh(0.01);
       
        local ServerPage = InternetLoadWorld.GetCurrentServerPage();

        if(not ServerPage.isFetching) then
            InternetLoadWorld.FetchServerPage(ServerPage);
        end

        BrowseRemoteWorlds.refreshing = false;

        BrowseRemoteWorlds.LoginPage:Refresh(0.01);
    end
end

function BrowseRemoteWorlds.enterWorld(index)
    local index = tonumber(index);
    SyncMain.selectedWorldInfor = InternetLoadWorld.cur_ds[index];

    if(SyncMain.selectedWorldInfor.status == 2) then
        BrowseRemoteWorlds.downloadWorld();
    else
        InternetLoadWorld.EnterWorld(index);
        BrowseRemoteWorlds.ClosePage(true);
    end
end

function BrowseRemoteWorlds.downloadWorld()
    SyncMain.foldername.utf8 = SyncMain.selectedWorldInfor.foldername;
    SyncMain.foldername.default = Encoding.Utf8ToDefault(SyncMain.foldername.utf8);

    SyncMain.worldDir.utf8    = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.utf8 .. "/";
    SyncMain.worldDir.default = SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.default .. "/";

    SyncMain.commitId = SyncMain:getGitlabCommitId(SyncMain.foldername.utf8);

    ParaIO.CreateDirectory(SyncMain.worldDir.default);

    SyncMain:syncToLocal(function(success, params)
        if(success) then
            SyncMain.selectedWorldInfor.status      = 3;
            SyncMain.selectedWorldInfor.server      = "local";
            SyncMain.selectedWorldInfor.is_zip      = false;
            SyncMain.selectedWorldInfor.icon        = "Texture/blocks/items/1013_Carrot.png";
            SyncMain.selectedWorldInfor.revision    = params.revison;
            SyncMain.selectedWorldInfor.filesTotals = params.filesTotals;
            SyncMain.selectedWorldInfor.text        = SyncMain.foldername.utf8;
            SyncMain.selectedWorldInfor.world_mode  = "edit";
            SyncMain.selectedWorldInfor.gs_nid      = "";
            SyncMain.selectedWorldInfor.force_nid   = 0;
            SyncMain.selectedWorldInfor.ws_id       = "";
            SyncMain.selectedWorldInfor.author      = "";
            SyncMain.selectedWorldInfor.remotefile  = "local://"..SyncMain.GetWorldFolderFullPath() .. "/" .. SyncMain.foldername.default;

            BrowseRemoteWorlds.LoginPage:Refresh();
        end
    end);
end

