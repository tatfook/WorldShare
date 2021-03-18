--[[
Title: Socket Base API
Author(s):  big
Date:  2020.05.26
Place: Foshan
use the lib:
------------------------------------------------------------
local SocketBaseApi = NPL.load("(gl)Mod/WorldShare/api/Socket/BaseApi.lua")
------------------------------------------------------------
]]

-- libs
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua")

-- config
local Config = NPL.load('(gl)Mod/WorldShare/config/Config.lua')

local BaseApi = NPL.load('../BaseApi.lua')

local SocketBaseApi = NPL.export()

-- private
function SocketBaseApi:GetApi()
    return KpChatChannel.GetPreloadSocketIOUrl() or Config.socket[BaseApi:GetEnv()] or ""
end