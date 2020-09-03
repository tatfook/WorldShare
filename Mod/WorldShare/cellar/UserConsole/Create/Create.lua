--[[
Title: UserConsoleCreate Page
Author(s):  Big
Date: 2020.9.1
Desc: 
use the lib:
------------------------------------------------------------
local UserConsoleCreate = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Create/Create.lua")
------------------------------------------------------------
]]

-- UI
local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")

local UserConsoleCreate = NPL.export()

UserConsoleCreate.currentMenuSelectIndex = 1
function UserConsoleCreate:Show()
    local UserConsolePage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.UserConsole')

    if UserConsolePage then
        WorldList:RefreshCurrentServerList()
        return true
    end

    local params = Mod.WorldShare.Utils.ShowWindow(850, 490, "(ws)UserConsole/Create/Create.html", "Mod.WorldShare.UserConsole")

    WorldList:RefreshCurrentServerList()
end