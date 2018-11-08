--[[
Title: Page
Author(s):  big
Date:  2018.8.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/store/Page.lua")
local PageStore = commonlib.gettable('Mod.WorldShare.store.Page')
------------------------------------------------------------
]]

local PageStore = commonlib.gettable('Mod.WorldShare.store.Page')

local function SetEmpty(page)
    if (not page) then
        page = {}
    end
end

SetEmpty(PageStore.UserConsole)
SetEmpty(PageStore.LoginModal)

SetEmpty(PageStore.StartSync)
SetEmpty(PageStore.StartSyncUseLocal)
SetEmpty(PageStore.StartSyncUseDataSource)

SetEmpty(PageStore.WorldExitDialog)