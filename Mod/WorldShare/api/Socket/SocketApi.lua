--[[
Title: Socket API
Author(s): big
CreateDate: 2020.05.26
ModifyDate: 2022.03.25
Place: Foshan
use the lib:
------------------------------------------------------------
local SocketApi = NPL.load('(gl)Mod/WorldShare/api/Socket/SocketApi.lua')
------------------------------------------------------------
]]

-- api
local SocketBaseApi = NPL.load('(gl)Mod/WorldShare/api/Socket/BaseApi.lua')

-- libs
local SocketIOClient = NPL.load('(gl)script/ide/System/os/network/SocketIO/SocketIOClient.lua')
local KpChatChannel = NPL.load('(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/KpChatChannel.lua')

local SocketApi = NPL.export()

SocketApi.client = commonlib.gettable('Mod.WorldShare.api.Socket.SocketApi.client')

local ackIdCounter = -1;

function SocketApi:Connect(callback)
    if self.client.connection then
        return self.client.connection
    end

    self.client.connection = SocketIOClient:new()
    self.client.connection.Send = function(connectionSelf, name, ...)
        local _args = {}
        local args

        for i = 1, select('#', ...) do
            local v = select(i, ...)
    
            table.insert(_args, v)
        end

        if _args[1] and type(_args[1]) == 'table' then
            _args[1].token = Mod.WorldShare.Store:Get('user/token')
        end

        if #_args == 1 then
            args = connectionSelf:GetArgs(name, _args[1])
        elseif #_args == 2 then
            args = connectionSelf:GetArgs(name, _args[1], _args[2])
        elseif #_args == 3 then
            args = connectionSelf:GetArgs(name, _args[1], _args[2], _args[3])
        elseif #_args == 4 then
            args = connectionSelf:GetArgs(name, _args[1], _args[2], _args[3], _args[4])
        elseif #_args == 5 then
            args = connectionSelf:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5])
        elseif #_args == 6 then
            args = connectionSelf:GetArgs(name, _args[1], _argswo[2], _args[3], _args[4], _args[5], _args[6])
        elseif #_args == 7 then
            args = connectionSelf:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7])
        elseif #_args == 8 then
            args = connectionSelf:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8])
        elseif #_args == 9 then
            args = connectionSelf:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9])
        elseif #_args == 10 then
            args = connectionSelf:GetArgs(name, _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10])
        else
            LOG.std(nil, 'info', 'WorldShare/Socket', 'max args')
            return
        end

        ackIdCounter = ackIdCounter + 1

        local pkt = {
            eio_pkt_name = 'message',
            sio_pkt_name = 'event',
            body = args,
            ack_id = ackIdCounter,
        }

        connectionSelf:SendPacket(pkt)
    end

    KpChatChannel.PreloadSocketIOUrl(function()
        self.client.connection:Connect(SocketBaseApi:GetApi())

        if callback and type(callback) == 'function' and self.client.connection then
            callback(self.client.connection)
        end
    end)
end

function SocketApi:SendMsg(url, params)
    if not self.client.connection or not self.client.connection.Send then
        return
    end

    self.client.connection:Send(url, params)
end

function SocketApi:GetConnection()
    return self.client.connection
end