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
EventTrackingService.firstSave = false
EventTrackingService.timeInterval = 10000 * 6 -- 60 seconds
EventTrackingService.currentLoop = nil
EventTrackingService.map = {
    duration = {
        world = {
            stay = 'duration.world.stay', -- 用户当前所在世界留存时间
            edit = 'duration.world.edit', -- 用户编辑世界时间
            play = 'duration.world.play'  -- 用户播放世界时间
        },
        macro = { -- 宏
            task = 'duration.macro.task', -- 任务
        },
        learning_daily = 'duration.learning_daily' -- 成长日记
    },
    click = {
        main_login = {
            offline_enter = 'click.main_login.offline_enter', -- 离线进入
        },
        world = { -- 世界
            edit = 'click.world.edit', -- 切换世界为编辑模式
            play = 'click.world.play', -- 切换世界为播放模式
            after_upload = 'click.world.after_upload', -- 上传世界后
            after_upload_panorama = 'click.world.after_upload_panorama', -- 上传全景图后,
            visit_user_home = 'click.world.visit_user_home', -- 观看用户家园
            block = {
                -- destroy = 'click.world.block.destroy', -- 删除方块
                -- create = 'click.world.block.create', -- 创建方块
                DeleteSelection = 'click.world.block.DeleteSelection', -- 删除选择的方块
            },
            -- tool = {
            --     pick = 'click.world.tool.pick', -- 拾取方块
            --     help = 'click.world.tool.help', -- 查看代码方块帮助
            --     browser = 'click.world.tool.browser' -- 角色 显示新页面
            -- },
            help = {
                browser = {
                    codeblock = 'click.world.help.browser.codeblock' -- 点击学习Codeblock
                },
                startTutorial = 'click.world.help.startTutorial', -- 开始向导
            },
            world = {
                save = 'click.world.world.save', -- 保存世界
                saveas = 'click.world.world.saveas', -- 另存为世界
                enter = 'click.world.world.enter', -- 进入世界
                create = 'click.world.world.create', -- 创建新世界
                delete = 'click.world.world.delete', -- 删除世界
            },
            desktop = {
                ForceExit = 'click.world.desktop.ForceExit', -- 强制退出世界
            },
            cmd = {
                execute = 'click.world.cmd.execute', -- 执行命令
            },
            model = {
                export = {
                    bmax = 'click.world.model.export.bmax', -- 保存bmax模型
                },
                exportAsTemplate = 'click.world.model.exportAsTemplate', -- 导出模板
            },
            paraworld = {
                DockerClick = 'click.world.paraworld.DockerClick', -- 点击顶部Docker
            },
            movie = {
                play = 'click.world.movie.play', -- 播放电影
            },
            actor = {
                addNPC = 'click.world.actor.addNPC', -- 添加NPC
                edit = 'click.world.actor.edit', -- 编辑角色
            },
            certificate = {
                certificate_now = 'click.world.certificate.certificate_now', -- 我要认证
                sel_school = 'click.world.certificate.sel_school', -- 我在学校
                sel_my_home = 'click.world.certificate.sel_my_home', -- 我在家里
                get_phone_captcha = 'click.world.certificate.get_phone_captcha', -- 我在家里-获取验证码
                bind = 'click.world.certificate.bind', -- 我在家里-确认实名
                send_msg_to_parent = 'click.world.certificate.send_msg_to_parent', -- 发送短信给父母
            },
            npc = 'click.world.npc', -- 点击世界中的NPC
        },
        mini_map = { -- 小地图
            paraworld_list = 'click.mini_map.paraworld_list', -- 显示所有并行世界
            local_worldinfo = 'click.mini_map.local_worldinfo', -- 显示当前并行世界选地窗口
            spawn_point = 'click.mini_map.spawn_point', -- 回到出生点
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
            week_quest = 'click.dock.week_quest', -- 实战提升
            code_war = 'click.dock.code_war', -- 玩学课堂
            web_keepwork_home = 'click.dock.web_keepwork_home', -- 用户社区
            user_tip = 'click.dock.user_tip', -- 成长日记
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
                createworld = "click.menu.file.create_world", -- 新建
                loadworld = "click.menu.file.load_world", -- 打开
                saveworld = "click.menu.file.save_world", -- 快速保存
                saveworldas = "click.menu.file.save_world_as", -- 另存为
                uploadworld = "click.menu.file.upload_world", -- 分享上传
                makeapp = "click.menu.file.make_app", -- 生成独立应用程序
                worldrevision = "click.menu.file.world_revision", -- 备份
                openworlddir = "click.menu.file.open_world_dir", -- 打开本地目录
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
                findfile = "click.menu.edit.find_file", -- 全文搜索
                upstairs = "click.menu.edit.up_stairs", -- 跳到上一层
                downstairs = "click.menu.edit.down_stairs", -- 跳到下一层
            },
            online = { -- 多人联网
                server = "click.menu.online.server",  -- 多人服务器
                teacher_panel = "click.menu.online.teacher_panel", -- 联网控制面板
            },
            window = { -- 窗口
                changeskin = "click.menu.window.change_skin", -- 角色换装
                texturepack = "click.menu.window.texture_pack", -- 材质包管理
                mall = "click.menu.window.mall", -- 资源
                userbag = "click.menu.window.user_bag", -- 背包
                videorecoder = "click.menu.window.video_recoder", -- 视频录制
                videosharing = "click.menu.window.video_sharing", -- 短视频分享
                info = "click.menu.window.info", -- 信息
                console = "click.menu.window.console", -- NPL控制面板
                mod = "click.menu.window.mod", -- MOD插件管理
            },
            help = { -- 帮助
                userintroduction = "click.menu.help.user_introduction", -- 新手引导
                videotutorials = "click.menu.help.video_tutorials", -- 教学视频
                learn = "click.menu.help.learn", -- 学习资源
                ask = "click.menu.help.ask", -- 提问
                help = "click.menu.help.help", -- 帮助
                shortcutkey = "click.menu.help.shortcut_key", -- 快捷键
                bug = "click.menu.help.bug", -- 提交意见与反馈
                about = "click.menu.help.about", -- 关于Paracraft
            },
            project = { -- 项目
                share = "click.menu.project.share", -- 上传分享
                index = "click.menu.project.index", -- 项目首页
                author = "click.menu.project.author", -- 项目作者
                openworlddir = "click.menu.project.open_world_dir", -- 本地目录
                worldrevision = "click.menu.project.world_revision", -- 本地备份
                setting = "click.menu.project.setting", -- 项目设置
                member = "click.menu.project.member", -- 成员管理
                apply = "click.menu.project.apply", -- 申请加入
            }
        },
        daily_task = { -- 成长任务
            growth_diary = 'click.daily_task.growth_diary', -- 成长日记
            week_work = 'click.daily_task.week_work', -- 实战提升
            class_room = 'click.daily_task.class_room', -- 玩学课堂
            update_world = 'click.daily_task.update_world', -- 更新世界
            visit_world = 'click.daily_task.visit_world', -- 参观5个世界
        },
        system_setting = { -- 系统设置
            share_world = "click.system_setting.share_world", -- 分享世界
            save_world = "click.system_setting.save_world", -- 保存世界
            change_texture = "click.system_setting.change_texture", -- 更换材质
            load_world = "click.system_setting.load_world", -- 加载世界
            system_setting = "click.system_setting.system_setting", -- 系统设置
            exit_world = "click.system_setting.exit_world", -- 退出世界
            friends = "click.system_setting.friends", -- 邀请好友
            continue_game = "click.system_setting.continue_game", -- 继续创作
            create_new_world = "click.system_setting.create_new_world", -- 新建世界
            open_server_page = "click.system_setting.open_server_page", -- 架设私服
        },
        quest_action = { -- 任务系统
            setvalue = 'click.quest_action.setvalue', -- 设置任务虚拟目标进度
            do_finish = 'click.quest_action.do_finish', -- 执行完成任务
            when_finish = 'click.quest_action.when_finish', -- 任务状态变更
            click_go_button = 'click.quest_action.click_go_button', -- 任务“前往”按键点击次数
        },
        promotion = { -- 活动
            -- 公告点击次数 访问营地|go_to_camp, 人工智能课程|AI_class, 换装系统|clothes_sys, 春节资源|sf_res, 实名认证|realname
            announcement = 'click.promotion.announcement', 
            horm = 'click.promotion.horm', -- 喇叭点击次数
            knowledge_bean = 'click.promotion.knowledge_bean', -- 知识豆兑换次数
            skin = 'click.promotion.skin', -- 皮肤兑换次数
            partake = 'click.promotion.partake', -- 参与活动人数（记录用户获取的第一个帽子）
            turnable = 'click.promotion.turnable', -- 活动转盘点击次数
            weekend = 'click.promotion.weekend', -- 点击周末创造
            winter_camp = {
                lessons = {
                    ai = 'click.promotion.winter_camp.lessons.ai', -- AI云游学
                    epidemic = 'click.promotion.winter_camp.lessons.epidemic', -- 防疫教学
                    hour_of_code = 'click.promotion.winter_camp.lessons.hour_of_code', -- 一小时编程课程
                },
                first_page = 'click.promotion.winter_camp.first_page', -- 冬令营主页
                notification = 'click.promotion.winter_camp.notification', -- 冬令营通知
            }
        },
        home = { -- 家园
            click_avatar = 'click.home.click_avatar', -- 头像点击次数
            click_code_block = 'click.home.click_code_block', -- 代码方块点击次数
            thumbs_up = 'click.home.click.thumbs_up', -- 点赞点击次数
            favorited = 'click.home.click.favorited', -- 收藏点击次数
        },
        sun_s_art_of_war_game = { -- 孙子兵法
            night_road = 'click.sun_s_art_of_war_game.night_road', -- 关卡“夜路前行”点击次数
            click_pay = 'click.sun_s_art_of_war_game.click_pay', -- 孙子兵法中点击已完成支付用户会员人数
        },
        vip = { -- VIP
            vip_popup = 'click.vip.vip_popup', -- 弹出会员弹窗次数(废弃)
            parents_help = 'click.vip.parents_help', -- "找家长续费" 点击次数
            payment_completed = 'click.vip.payment_completed', -- “已完成支付” 点击次数
            funnel = {
                open = 'click.vip.funnel.open' -- 弹出会员弹窗次数
            }
        },
        macro = { -- 宏
            task = 'click.macro.task', -- 任务
        },
        beginner = {
            catation = 'click.beginner.catation' -- 领取奖状
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

function EventTrackingService:GetServerTime()
    return Mod.WorldShare.Store:Get('world/currentServerTime')
end

function EventTrackingService:GenerateDataPacket(eventType, userId, action, started)
    if not userId or not action then
        return
    end

    local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')
    local projectId

    if currentEnterWorld and currentEnterWorld.kpProjectId then
        projectId = currentEnterWorld.kpProjectId
    end

    if eventType == 1 then -- one click event
        return {
            userId = userId,
            projectId = projectId,
            currentAt = self:GetServerTime(),
            traceId = System.Encoding.guid.uuid()
        }
    elseif eventType == 2 then -- duration event
        local unitinfo =  {
            userId = userId,
            projectId = projectId
        }

        -- get previous action from local storage
        local previousUnitinfo = EventTrackingDatabase:GetPacket(userId, action)

        if not previousUnitinfo then
            unitinfo.beginAt = self:GetServerTime()
            unitinfo.endAt = 0
            unitinfo.duration = 0
            unitinfo.traceId = System.Encoding.guid.uuid()
        else
            if started then
                unitinfo.beginAt = previousUnitinfo.beginAt
                unitinfo.endAt = 0
                unitinfo.duration = self:GetServerTime() - previousUnitinfo.beginAt
                unitinfo.traceId = previousUnitinfo.traceId
            else
                unitinfo.beginAt = previousUnitinfo.beginAt
                unitinfo.endAt = self:GetServerTime()
                unitinfo.duration = unitinfo.endAt - previousUnitinfo.beginAt
                unitinfo.traceId = previousUnitinfo.traceId
            end
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

function EventTrackingService:SaveToDisk()
    EventTrackingDatabase:SaveToDisk()
end

-- eventType: 1 is one click event, 2 is duration event
function EventTrackingService:Send(eventType, action, extra, offlineMode)
    if not offlineMode and not KeepworkServiceSession:IsSignedIn() then
        return false
    end

    if not eventType or not action then
        return false
    end

    action = self:GetAction(action)

    if not action then
        return false
    end

    local userId = Mod.WorldShare.Store:Get('user/userId') or 0
    local dataPacket = self:GenerateDataPacket(eventType, userId, action, extra and extra.started or false)

    if not offlineMode and (not dataPacket or not dataPacket.projectId) then
        return false
    end

    if eventType == 2 then
        if not extra then
            return false
        end

        -- prevent send and remove not started event 
        if extra.ended and (dataPacket.duration == 0 or dataPacket.endAt == 0) then
            EventTrackingDatabase:RemovePacket(userId, action, dataPacket)
            return false
        end
    end

    if extra and type(extra) == 'table' then
        extra.started = nil -- remove started key in extra table because we needn't upload that
        extra.ended = nil -- remove ended key in extra table because we needn't upload that

        for key, value in pairs(extra) do
            dataPacket[key] = value
        end
    end

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
                    local finishedCount = 0
                    local dataTatol = 0

                    for key, item in ipairs(allData) do
                        local unitinfo = item.unitinfo
                        dataTatol = dataTatol + #unitinfo
                    end

                    local function firstTimeSave()
                        if firstSave then
                            return
                        end

                        if finishedCount == dataTatol then
                            EventTrackingDatabase:SaveToDisk()
                            firstSave = true
                        end
                    end

                    for key, item in ipairs(allData) do
                        local userId = item.userId
                        local unitinfo = item.unitinfo

                        if unitinfo and type(unitinfo) == 'table' then
                            for uKey, uItem in ipairs(unitinfo) do
                                if uItem and uItem.packet then
                                    if uItem.packet.endAt and uItem.packet.endAt == 0 then
                                        if not self:GetServerTime() or not uItem.packet.beginAt then
                                            return
                                        end

                                        uItem.packet.duration = self:GetServerTime() - uItem.packet.beginAt
                                    end

                                    -- send and remove cache
                                    EventGatewayEventsApi:Send(
                                        "behavior",
                                        uItem.action,
                                        uItem.packet,
                                        nil,
                                        function(data, err)
                                            finishedCount = finishedCount + 1

                                            if err ~= 200 then
                                                firstTimeSave()
                                                return false
                                            end

                                            -- remove packet
                                            -- we won't remove record if endAt == 0
                                            local currentEnterWorld = Mod.WorldShare.Store:Get('world/currentEnterWorld')

                                            if currentEnterWorld and
                                               currentEnterWorld.kpProjectId and
                                               tonumber(currentEnterWorld.kpProjectId) == tonumber(uItem.packet.projectId) then
                                                if uItem.packet.endAt and uItem.packet.endAt == 0 then
                                                    firstTimeSave()
                                                    return
                                                end
                                            end

                                            EventTrackingDatabase:RemovePacket(userId, uItem.action, uItem.packet)
                                            firstTimeSave()
                                        end,
                                        function(data, err)
                                            -- fail
                                            -- do nothing...
                                            firstTimeSave()
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

