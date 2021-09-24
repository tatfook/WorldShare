--[[
Title: Offline Account Manager
Author(s): big
CreateDate: 2021.09.08
ModifyDate: 2021.09.24
Desc: 
use the lib:
------------------------------------------------------------
local OfflineAccountManager = NPL.load('(gl)Mod/WorldShare/cellar/OfflineAccount/OfflineAccountManager.lua')
------------------------------------------------------------
]]

local OfflineAccountManager = NPL.export()

function OfflineAccountManager:ShowActivationPage()
    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/OfflineAccount/ActivationPage.html',
        'Mod.WorldShare.OfflineAccount.ActivationPage',
        0,
        0,
        '_fi',
        false
    )
end