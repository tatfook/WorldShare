
--[[
Title: Prevent Indulge
Author(s):  big
Date: 2020.4.7
Desc: 
use the lib:
------------------------------------------------------------
local PreventIndulge = NPL.load("(gl)Mod/WorldShare/cellar/PreventIndulge/PreventIndulge.lua")
------------------------------------------------------------
]]

local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

local PreventIndulge = NPL.export()

function PreventIndulge.Init()
    -- prevent indulge
    KeepworkServiceSession:PreventIndulge(function(str)
        if str == '40MINS' then
            _guihelper.MessageBox(L"你已经连续使用了40分钟。", function()
                _guihelper.MessageBox(L"建议您休息下眼睛，眺望远方会有助于放松。")
            end, _guihelper.MessageBoxButtons.OK)
        end
    
        if str == '2HOURS' then
            _guihelper.MessageBox(L"你已经连续使用了2个小时。", function()
                _guihelper.MessageBox(L"建议站起来活动下身体，休息下眼睛。", function()
                    _guihelper.MessageBox(L"创作虽然有趣，也请不要忽略其他的工作学习。")
                end, _guihelper.MessageBoxButtons.OK)
            end, _guihelper.MessageBoxButtons.OK)
        end
    
        if str == '4HOURS' then
            _guihelper.MessageBox(L"你已连续使用了4个小时，真的有些久了。", function()
                _guihelper.MessageBox(L"是时候离开电脑，与家人朋友享受下户外的清新空气。")
            end, _guihelper.MessageBoxButtons.OK)
        end

        if str == '22:30' then
            _guihelper.MessageBox(L"夜已深，是时候洗漱休息，以饱满的精神迎接新的一天了。")
        end
    end)
end
