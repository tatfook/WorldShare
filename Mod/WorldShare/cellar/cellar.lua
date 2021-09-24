--[[
Title: Cellar
Author(s): big
CreateDate: 2021.09.24
Desc: convert npl.load to inherit
use the lib:
------------------------------------------------------------
local Cellar = NPL.load('(gl)Mod/WorldShare/cellar/cellar.lua')
------------------------------------------------------------
]]

-- bottles
local OfflineAccountManager = NPL.load('(gl)Mod/WorldShare/cellar/OfflineAccount/OfflineAccountManager.lua')

local CellarInherit = commonlib.gettable('Mod.WorldShare.cellar')

CellarInherit.OfflineAccountManager = OfflineAccountManager
