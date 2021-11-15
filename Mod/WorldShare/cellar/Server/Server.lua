--[[
Title: Server Page
Author(s):  big
CreateDate: 2019.11.05
ModifyDate: 2021.11.15
Desc: 
use the lib:
------------------------------------------------------------
local Server = NPL.load('(gl)Mod/WorldShare/cellar/Server/Server.lua')
------------------------------------------------------------
]]

-- libs
local Screen = commonlib.gettable('System.Windows.Screen')
local SocketService = commonlib.gettable('Mod.WorldShare.service.SocketService')
local NetworkMain = commonlib.gettable('MyCompany.Aries.Game.Network.NetworkMain')

-- bottles
local LoginModal = NPL.load('(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua')
local Permission = NPL.load('(gl)Mod/WorldShare/cellar/Permission/Permission.lua')
local Compare = NPL.load('(gl)Mod/WorldShare/service/SyncService/Compare.lua')

local Server = NPL.export()

Server.seachFinished = false

function Server:ShowPage()
    local function Handle(result)
        if result then
            local params = Mod.WorldShare.Utils.ShowWindow(0, 0, 'Mod/WorldShare/cellar/Server/Server.html', 'Server', 0, 0, '_fi', false)

            Screen:Connect('sizeChanged', self, self.OnScreenSizeChange, 'UniqueConnection')
            self.OnScreenSizeChange()
        
            params._page.OnClose = function()
                Mod.WorldShare.Store:Remove('page/Server')
                Screen:Disconnect('sizeChanged', self, self.OnScreenSizeChange)
            end
        
            self:GetOnlineList()
        end

        Compare:RefreshWorldList()
    end

    Permission:CheckPermission('OnlineLearning', true, Handle)
end

function Server.OnScreenSizeChange()
    local ServerPage = Mod.WorldShare.Store:Get('page/Server')

    if not ServerPage then
        return false
    end

    local height = math.floor(Screen:GetHeight())

    local areaHeaderNode = ServerPage:GetNode('area_header')
    local marginLeft = math.floor((Screen:GetWidth() - 600) / 2)

    areaHeaderNode:SetCssStyle('margin-left', marginLeft)

    local areaContentNode = ServerPage:GetNode('area_content')

    areaContentNode:SetCssStyle('height', height - 47)
    areaContentNode:SetCssStyle('margin-left', marginLeft)

    ServerPage:Refresh(0.01)
end

function Server:GetOnlineList()
    local ServerPage = Mod.WorldShare.Store:Get('page/Server')
    self.seachFinished = false
    ServerPage:Refresh(0.01)

    SocketService:SendUDPWhoOnlineMsg()

    Mod.WorldShare.Utils.SetTimeOut(function()
        local udpServerList = Mod.WorldShare.Store:Get('user/udpServerList') or {}

        ServerPage:GetNode('udp_server_list'):SetAttribute('DataSource', udpServerList)

        self.seachFinished = true
        ServerPage:Refresh(0.01)
    end, 3000)
end

function Server:IsSeachFinished()
    return self.seachFinished == true
end

function Server:Connect(...)
    NetworkMain:Connect(...)
end