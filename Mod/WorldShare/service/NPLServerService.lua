--[[
Title: NPLServerService
Author(s):  big
Date:  2020.7.10
Place: Foshan
use the lib:
------------------------------------------------------------
local NPLServerService = NPL.load("(gl)Mod/WorldShare/service/NPLServerService.lua")
------------------------------------------------------------
]]

NPL.load("(gl)script/apps/WebServer/WebServer.lua")
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua")

local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager")

local NPLServerService = NPL.export()

function NPLServerService:CheckDefaultServerStarted(callbackFunc)
	callbackFunc = callbackFunc or function(bStarted) 
		LOG.std(nil, "info", "CheckServerStarted", "%s", tostring(bStarted))
	end

    local addr = WebServer:site_url()

	if addr then
		callbackFunc(true, addr)
		return true, addr
	else
        self:StartDefaultServer()

		addr = WebServer:site_url()
		if addr then
			callbackFunc(true, addr)
			return true, addr
		else
			local count = 0;
			local function CheckServerStarted()
				commonlib.TimerManager.SetTimeout(function()  
					local addr = WebServer:site_url();
					if(addr) then
						callbackFunc(true, addr);
					else
						count = count + 1;
						-- try 5 times in 5 seconds
						if(count < 5)  then
							CheckServerStarted()
						else
							callbackFunc(false)
						end
					end
				end, 1000)
			end
			CheckServerStarted()
		end
	end
end

function NPLServerService:StartDefaultServer()
    local doc_root_dir, host, port;

    doc_root_dir = "script/apps/WebServer/admin"
    port = 8099

    if not doc_root_dir then
        return false
    end

    local att = NPL.GetAttributeObject();

    -- start server
    local function startserver_()
        if WebServer:Start(doc_root_dir, host, port) then
            CommandManager:RunCommand("/clicktocontinue off")
            local addr = WebServer:site_url()

            if addr then
                -- change windows title
                local wnd_title = ParaEngine.GetAttributeObject():GetField("WindowText", "")
                wnd_title = wnd_title:gsub("%sport:%d+", "")
                wnd_title = wnd_title .. format(" port:%d", port)
                ParaEngine.GetAttributeObject():SetField("WindowText", wnd_title)
            end
        else
            GameLogic.AddBBS(nil, L"只能同时启动一个Server")
        end
    end

    if not att:GetField("IsServerStarted", false) then
        local function TestOpenNPLPort_()
            System.os.GetUrl(format("http://127.0.0.1:%s/ajax/console?action=getpid", port), function(err, msg, data)
                if(data and data.pid) then
                    if(System.os.GetCurrentProcessId() ~= data.pid) then
                        -- already started by another application, 
                        -- try 
                        port = port + 1
                        TestOpenNPLPort_()
                        return
                    else
                        -- already opened by the same process
                    end
                else
                    startserver_()
                end
            end)
        end

        TestOpenNPLPort_()
    elseif not WebServer:IsStarted() then
        -- this could happen when game server is started before web server, we will share the same port with exiting server. 
        port = tonumber(att:GetField("HostPort", "8099"))
        startserver_()
    end
end