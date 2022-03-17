--[[
Title: Client Update Dialog
Author(s): big
Date: 2021.1.25
City: Foshan
use the lib:
------------------------------------------------------------
local ClientUpdateDialog = NPL.load('(gl)Mod/WorldShare/cellar/ClientUpdateDialog/ClientUpdateDialog.lua')
------------------------------------------------------------
]]

local ClientUpdateDialog = NPL.export()

--只有当前版本号 < 允许启动的最低版本号，才弹出这个弹窗
function ClientUpdateDialog:Show(updater, gamename)
    -- if updater:isAutoSkip() then 
    --     return
    -- end
    System.App.Commands.Call("File.MCMLWindowFrame", {
        url = format("Mod/WorldShare/cellar/ClientUpdateDialog/ClientUpdateDialog.html?latestVersion=%s&curVersion=%s&curGame=%s", updater:getLatestVersion(), updater:getCurVersion(), gamename), 
        name = "Mod.WorldShare.ClientUpdateDialog", 
        isShowTitleBar = false,
        DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
        style = CommonCtrl.WindowFrame.ContainerStyle,
        zorder = 1,
        allowDrag = false,
        isTopLevel = true,
        directPosition = true,
            align = "_ct",
            x = -210,
            y = -100,
            width = 420,
            height = 300,
    });
end
