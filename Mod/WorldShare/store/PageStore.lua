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

local function setEmpty(page)
    if (not page) then
        page = {}
    end
end

setEmpty(PageStore.LoginMain)
setEmpty(PageStore.LoginModal)

setEmpty(PageStore.StartSync)
setEmpty(PageStore.StartSyncUseLocal)
setEmpty(PageStore.StartSyncUseDataSource)

setEmpty(PageStore.WorldExitDialog)