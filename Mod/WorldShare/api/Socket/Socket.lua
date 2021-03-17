--[[
Title: Socket API
Author(s):  big
Date:  2020.05.26
Place: Foshan
use the lib:
------------------------------------------------------------
local SocketApi = NPL.load("(gl)Mod/WorldShare/api/Socket/Socket.lua")
------------------------------------------------------------
]]

-- api
local SocketBaseApi = NPL.load("(gl)Mod/WorldShare/api/Socket/BaseApi.lua")

-- libs
local SocketIOClient = NPL.load("(gl)script/ide/System/os/network/SocketIO/SocketIOClient.lua")
local KpChatChannel = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua")

local SocketApi = NPL.export()

SocketApi.client = commonlib.gettable('Mod.WorldShare.api.Socket.SocketApi.client')

local ack_id_counter = -1;

function SocketApi:Connect()
    if self.client.connection then
        return self.client.connection
    end

    self.client.connection = SocketIOClient:new()
    self.client.connection.Send = function(self, name, ...)
        local _args = {}
        local args

        for i = 1, select("#", ...) do
            local v = select(i, ...)
    
            table.insert(_args, v)
        end

        if type(_args[1]) == 'table' then
            _args[1].token = Mod.WorldShare.Store:Get('user/token')
        end

        if #_args == 1 then
            args = self:GetArgs(name, _args[1])
        elseif #_args == 2 then
            args = self:GetArgs(name, _args[1], _args[2])
        elseif #_args == 3 then
            args = self:GetArgs(name, _args[1], _args[2], _args[3])
        elseif #_args == 4 then
            args = self:GetArgs(name, _args[1], _args[2], _args[3], _args[4])
        elseif #_args == 5 then
            args = self:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5])
        elseif #_args == 6 then
            args = self:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5], _args[6])
        elseif #_args == 7 then
            args = self:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7])
        elseif #_args == 8 then
            args = self:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8])
        elseif #_args == 9 then
            args = self:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9])
        elseif #_args == 10 then
            args = self:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10])
        else
            LOG.std(nil, "info", "WorldShare/Socket", "max args")
            return false
        end

        ack_id_counter = ack_id_counter + 1

        local pkt = {
            eio_pkt_name = "message",
            sio_pkt_name = "event",
            body = args,
            ack_id = ack_id_counter,
        }

        self:SendPacket(pkt)
    end

    KpChatChannel.PreloadSocketIOUrl(function()
        self.client.connection:Connect(SocketBaseApi:GetApi())
    
        if self.client.connection then
            return self.client.connection
        end
    end)
end

function SocketApi:SendMsg(url, params)
    if not self.client.connection or not self.client.connection.Send then
        return false
    end

    self.client.connection:Send(url, params)
end

function SocketApi:GetConnection()
    return self.client.connection
end