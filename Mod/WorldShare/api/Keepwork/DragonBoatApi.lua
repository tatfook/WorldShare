--[[
Title: Keepwork Dragon Boat API
Author(s):  big
Date:  2020.03.31
Place: Foshan
use the lib:
------------------------------------------------------------
local KeepworkDragonBoatApi = NPL.load("(gl)Mod/WorldShare/api/Keepwork/DragonBoatApi.lua")
------------------------------------------------------------
]]

local KeepworkBaseApi = NPL.load('./BaseApi.lua')

local KeepworkDragonBoatApi = NPL.export()

-- url: /dragonBoat/rice
-- name: 贡献糯米
-- method: POST
-- params:
--[[
    rice number necessary 贡献多少糯米
]]
-- return: object
function KeepworkDragonBoatApi:Rice(rice, success, error)
    if not rice or type(rice) ~= 'number' then
        return
    end

    KeepworkBaseApi:Post('/dragonBoat/rice', { rice = rice }, nil, success, error)
end

-- url: /dragonBoat/process
-- name: 获取领奖进度
-- method: GET
-- params:
-- return:
--[[
    totalRice number necessary 总共糯米数
    userGifts object [] not necessary item 类型: object
        - step string necessary 领过了第几步的奖励
]]
function KeepworkDragonBoatApi:Process(success, error)
    KeepworkBaseApi:Get('/dragonBoat/process', nil, nil, success, error)
end

-- url: /dragonBoat/gifts
-- name: 领取奖励
-- method: GET
-- params:
--[[
    step int necessary example: 2 领取第二步的奖励
]]
-- return: object
function KeepworkDragonBoatApi:Gifts(step, success, error)
    if type(step) ~= "number" then
        return
    end

    KeepworkBaseApi:Get('/dragonBoat/gifts', { step = step }, nil, success, error)
end