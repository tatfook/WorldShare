--[[
Title: Event Tracking Service
Author(s): big
Date: 2020.11.2
City: Foshan
use the lib:
------------------------------------------------------------
local EventTrackingService = NPL.load("(gl)Mod/WorldShare/service/EventTracking.lua")
------------------------------------------------------------
]]

-- libs
local ParaWorldAnalytics = NPL.load("(gl)script/apps/Aries/Creator/Game/Login/ParaWorldAnalytics.lua")

-- api
local EventGatewayEventsApi = NPL.load("(gl)Mod/WorldShare/api/EventGateway/Events.lua")

-- service
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")

-- database
local EventTrackingDatabase = NPL.load("(gl)Mod/WorldShare/database/EventTracking.lua")

local EventTrackingService = NPL.export()

EventTrackingService.firstInit = false
EventTrackingService.timeInterval = 10000 -- 10 seconds
EventTrackingService.currentLoop = nil
EventTrackingService.map = {
    duration = {
        world = {
            stay = 'duration.world.stay' -- 用户当前所在世界留存时间
        },
    },
    click = {
        world = { -- 世界
            edit = 'click.world.edit', -- 切换世界为编辑模式
            play = 'click.world.play', -- 切换世界为播放模式
        },
        minimap = { -- 小地图
            paraworldlist = 'click.minimap.paraworldlist', -- 显示所有并行世界
            localworldinfo = 'click.minimap.localworldinfo', -- 显示当前并行世界选地窗口
            spawnpoint = 'click.minimap.spawnpoint', -- 回到出生点
        },
        dock = { -- 并行世界DOCK栏
            character = 'click.dock.character', -- 人物
            bag = 'click.dock.bag', -- 背包
            work = 'click.dock.work', -- 创造
            explore = 'click.dock.explore', -- 探索
            study = 'click.dock.study', -- 学习
            home = 'click.dock.home', -- 家园
            friends = 'click.dock.friends', -- 朋友
            school = 'click.dock.school', -- 学校
            system = 'click.dock.system', -- 系统
            vip = 'click.dock.vip', -- 会员
            mall = 'click.dock.mall', -- 资源
            competition = 'click.dock.competition', -- 大赛
            checkin = 'click.dock.checkin', -- 成长任务
            weekquest = 'click.dock.weekquest', -- 实战提升
            codewar = 'click.dock.codewar', -- 玩学课堂
            webkeepworkhome = 'click.dock.webkeepworkhome', -- 用户社区
            usertip = 'click.dock.usertip', -- 成长日记
        },
        task = { -- 实战提升
            program = 'click.task.program', -- 编程
            animation = 'click.task.animation', -- 动画
            CAD = 'click.task.CAD', -- CAD
            language = 'click.task.language', -- 语文
            math = 'click.task.math', -- 数学
            english = 'click.task.english', -- 英语
            science = 'click.task.science', -- 科学
            humanities = 'click.task.humanities' -- 人文
        },
        menu = { -- 菜单
            file = { -- 文件
                createworld = "click.menu.file.createworld", -- 新建
                loadworld = "click.menu.file.loadworld", -- 打开
                saveworld = "click.menu.file.saveworld", -- 快速保存
                saveworldas = "click.menu.file.saveworldas", -- 另存为
                uploadworld = "click.menu.file.uploadworld", -- 分享上传
                makeapp = "click.menu.file.makeapp", -- 生成独立应用程序
                worldrevision = "click.menu.file.worldrevision", -- 备份
                openworlddir = "click.menu.file.openworlddir", -- 打开本地目录
                settings = "click.menu.file.settings", -- 系统设置
                exit = "click.menu.file.exit" -- 退出
            },
            edit = { -- 编辑
                undo = "click.menu.edit.undo", -- 撤销
                redo = "click.menu.edit.redo", -- 重做
                copy = "click.menu.edit.copy", -- 复制
                paste = "click.menu.edit.paste", -- 粘贴
                delete = "click.menu.edit.delete", -- 删除
                find = "click.menu.edit.find", -- 方块跳转
                findfile = "click.menu.edit.findfile", -- 全文搜索
                upstairs = "click.menu.edit.upstairs", -- 跳到上一层
                downstairs = "click.menu.edit.downstairs", -- 跳到下一层
            },
            online = { -- 多人联网
                server = "click.menu.online.server",  -- 多人服务器
                teacher_panel = "click.menu.online.teacher_panel", -- 联网控制面板
            },
            window = { -- 窗口
                changeskin = "click.menu.window.changeskin", -- 角色换装
                texturepack = "click.menu.window.texturepack", -- 材质包管理
                mall = "click.menu.window.mall", -- 资源
                userbag = "click.menu.window.userbag", -- 背包
                videorecoder = "click.menu.window.videorecoder", -- 视频录制
                videosharing = "click.menu.window.videosharing", -- 短视频分享
                info = "click.menu.window.info", -- 信息
                console = "click.menu.window.console", -- NPL控制面板
                mod = "click.menu.window.mod", -- MOD插件管理
            },
            help = { -- 帮助
                userintroduction = "click.menu.help.userintroduction", -- 新手引导
                videotutorials = "click.menu.help.videotutorials", -- 教学视频
                learn = "click.menu.help.learn", -- 学习资源
                ask = "click.menu.help.ask", -- 提问
                help = "click.menu.help.help", -- 帮助
                shortcutkey = "click.menu.help.shortcutkey", -- 快捷键
                bug = "click.menu.help.bug", -- 提交意见与反馈
                about = "click.menu.help.about", -- 关于Paracraft
            },
            project = { -- 项目
                share = "click.menu.project.share", -- 上传分享
                index = "click.menu.project.index", -- 项目首页
                author = "click.menu.project.author", -- 项目作者
                openworlddir = "click.menu.project.openworlddir", -- 本地目录
                worldrevision = "click.menu.project.worldrevision", -- 本地备份
                setting = "click.menu.project.setting", -- 项目设置
                member = "click.menu.project.member", -- 成员管理
                apply = "click.menu.project.apply", -- 申请加入
            }
        },
        systemsetting = { -- 系统设置
            shareworld = "click.systemsetting.shareworld", -- 分享世界
            saveworld = "click.systemsetting.saveworld", -- 保存世界
            changetexture = "click.systemsetting.changetexture", -- 更换材质
            loadworld = "click.systemsetting.loadworld", -- 加载世界
            systemsetting = "click.systemsetting.systemsetting", -- 系统设置
            exitworld = "click.systemsetting.exitworld", -- 退出世界
            friends = "click.systemsetting.friends", -- 邀请好友
            continuegame = "click.systemsetting.continuegame", -- 继续创作
            createnewworld = "click.systemsetting.createnewworld", -- 新建世界
            openserverpage = "click.systemsetting.openserverpage", -- 架设私服
        }
    }
}

function EventTrackingService:Init()
    if self.firstInit then
        return        
    end

    self.firstInit = true
    self.timeInterval = 10000 -- 10 seconds

    -- send not finish event
    self:Loop()
end

function EventTrackingService:GenerateDataPacket(type, userId, action)
    if not userId or not action then
        return
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    local projectId

    if currentEnterWorld and currentEnterWorld.kpProjectId then
        projectId = currentEnterWorld.kpProjectId
    end

    if type == 1 then -- one click event
        return {
            userId = userId,
            projectId = projectId,
            currentAt = os.time(),
            traceId = System.Encoding.guid.uuid()
        }
    elseif type == 2 then -- duration event
        local unitinfo =  {
            userId = userId,
            projectId = projectId
        }

        -- get previous action from local storage
        local previousUnitinfo = EventTrackingDatabase:GetPacket(userId, action)

        if not previousUnitinfo then
            unitinfo.beginAt = os.time()
            unitinfo.endAt = 0
            unitinfo.duration = 0
            unitinfo.traceId = System.Encoding.guid.uuid()
        else
            unitinfo.beginAt = previousUnitinfo.beginAt
            unitinfo.endAt = os.time()
            unitinfo.duration = unitinfo.endAt - previousUnitinfo.beginAt
            unitinfo.traceId = previousUnitinfo.traceId
        end

        return unitinfo
    end
end

function EventTrackingService:GetAction(action)
    if not action or type(action) ~= 'string' then
        return false
    end

    local cur

    for item in string.gmatch(action, "[^%.]+") do
        if not cur then
            cur = self.map[item]
        else
            if type(cur) == 'table' then
                cur = cur[item]
            end
        end

        if not cur then
            return false
        end

        if type(cur) == 'string' then
            return cur
        end
    end
end

-- type: 1 is one click event, 2 is duration event
function EventTrackingService:Send(type, action, ...)
    if not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    if not type or not action then
        return false
    end

    action = self:GetAction(action)

    if not action then
        return false
    end

    local userId = Mod.WorldShare.Store:Get('user/userId')
    local dataPacket = self:GenerateDataPacket(type, userId, action)

    if EventTrackingDatabase:PutPacket(userId, action, dataPacket) then
        EventGatewayEventsApi:Send(
            "behavior",
            action,
            dataPacket,
            nil,
            function(data, err)
                if err ~= 200 then
                    return false
                end

                -- remove packet
                -- we won't remove record if endAt == 0

                if dataPacket.endAt and dataPacket.endAt == 0 then
                    return
                end

                EventTrackingDatabase:RemovePacket(userId, action, dataPacket)
            end,
            function(data, err)
                -- fail
                -- do nothing...
            end
        )
    end

    return dataPacket
end

function EventTrackingService:Loop()
    EventTrackingDatabase:ClearUselessCache()

    if not self.currentLoop then
        self.currentLoop = commonlib.Timer:new(
            {
                callbackFunc = function()
                    -- send not finish event
                    local allData = EventTrackingDatabase:GetAllData()

                    for key, item in ipairs(allData) do
                        local userId = item.userId
                        local unitinfo = item.unitinfo

                        if unitinfo and type(unitinfo) == 'table' then
                            for uKey, uItem in ipairs(unitinfo) do
                                if uItem and uItem.packet then
                                    -- send and remove cache
                                    EventGatewayEventsApi:Send(
                                        "behavior",
                                        uItem.action,
                                        uItem.packet,
                                        nil,
                                        function(data, err)
                                            if err ~= 200 then
                                                return false
                                            end

                                            -- remove packet
                                            -- we won't remove record if endAt == 0

                                            if uItem.packet.endAt and uItem.packet.endAt == 0 then
                                                return
                                            end

                                            EventTrackingDatabase:RemovePacket(userId, uItem.action, uItem.packet)
                                        end,
                                        function(data, err)
                                            -- fail
                                            -- do nothing...
                                        end
                                    )
                                end
                            end
                        end
                    end
                end
            }
        )
    end

	self.currentLoop:Change(0, self.timeInterval)
end

