--[[
Title: MsgBox
Author(s): big
CreateDate: 2018.08.24
ModifyDate: 2021.09.27
City: Foshan
use the lib:
------------------------------------------------------------
local MsgBox = NPL.load('(gl)Mod/WorldShare/cellar/Common/MsgBox/MsgBox.lua')

Mod.WorldShare.MsgBox:Show(L'请稍候...', nil, nil, nil, nil, 10, nil, nil, true)
------------------------------------------------------------
]]
local MsgBox = NPL.export()
local self = MsgBox

MsgBox.msgIdCount = 0
MsgBox.allMsg = {}
MsgBox.allMsgBox = commonlib.Array:new()
MsgBox.customLabels = {}

function MsgBox:Wait(sec)
    self:Show(L'请稍候...', sec)
end

function MsgBox:Show(msg, sec, overtimeMsg, width, height, index, align, isTopLevel, isWait)
    self.msgIdCount = self.msgIdCount + 1

    local msgId = self.msgIdCount

    self.allMsgBox:push_back(msgId)
    self.allMsg[msgId] = msg

    local params = Mod.WorldShare.Utils.ShowWindow(
        0,
        0,
        'Mod/WorldShare/cellar/Common/MsgBox/Theme/MsgBox.html?msgId=' ..
            msgId ..
            '&width=' ..
            (width or 0) ..
            '&height=' ..
            (height or 0) ..
            '&is_wait=' ..
            (isWait and 'true' or 'false'),
        'MsgBox',
        0,
        0,
        align or '_fi',
        false,
        index or 11,
        isTopLevel
    )

    params._page.OnClose = function()
        Mod.WorldShare.Store:Remove('page/MsgBox' .. msgId)
    end

    Mod.WorldShare.Utils.SetTimeOut(
        function()
            for key, item in ipairs(self.allMsgBox) do
                if item == msgId then
                    if overtimeMsg then
                        GameLogic.AddBBS(nil, overtimeMsg, 3000, '255 0 0')
                    end
                    self:Close(msgId)
                    break;
                end
            end
        end,
        (sec or 10000)
    )

    return curIndex
end

function MsgBox:Close(msgId)
    local MessageInfoPage

    if type(msgId) ~= 'number' then
        msgId = self.allMsgBox[#self.allMsgBox]
    end

    for key, value in ipairs(self.allMsgBox) do
        if value == msgId then
            MessageInfoPage = Mod.WorldShare.Store:Get('page/MsgBox' .. msgId)
            self.allMsgBox:remove(key)
            self.allMsg[msgId] = nil;
            break;
        end
    end

    if MessageInfoPage then
        MessageInfoPage:CloseWindow()
    end
end

function MsgBox.SetPage(msgId)
    Mod.WorldShare.Store:Set('page/MsgBox' .. msgId, document:GetPageCtrl())
end

function MsgBox.GetMsg(msgId)
    if type(msgId) == 'number' then
        return self.allMsg[msgId]
    end
end

--[[
example:
MsgBox:Dialog(
    'your_content',
    {
        'Abort' = 'Abort',
        'Cancel' = 'Cancel'
    },
    function(res)
    end,
    _guihelper.MessageBoxButtons.YesNo
)
]]
function MsgBox:Dialog(dialogName, content, customLabels, MsgBoxClick_CallBack, buttons, styles, icon, isNotTopLevel, zorder)
    self.customLabels = {}
    self.styles = {}

    if type(customLabels) == 'table' then
        self.customLabels = {
            TitleLabel = customLabels['Title'],
            OKLabel = customLabels['OK'],
            CancelLabel = customLabels['Cancel'],
            AbortLabel = customLabels['Abort'],
            IgnoreLabel = customLabels['Ignore'],
            NoneLabel = customLabels['None'],
            RetryLabel = customLabels['Retry'],
            YesLabel = customLabels['Yes'],
            NoLabel = customLabels['No'],
        }
    end

    if type(styles) == 'table' then
        self.styles = {
            Window = styles['Window'] or {},
            Container = styles['Container'] or {},
            Yes = styles['Yes'] or {},
            No = styles['No'] or {},
        }
    end

    _guihelper.MessageBox(
        content,
        MsgBoxClick_CallBack,
        buttons,
        icon,
        'Mod/WorldShare/cellar/Common/MsgBox/Theme/Dialog.html?dialogName=' .. dialogName,
        isNotTopLevel,
        zorder
    )
end

function MsgBox:ShowNotice(content, script, mcss, templateType, width, height, index, align, isTopLevel)
    local template1 = [[
        <html>
            <body>
                <pe:mcml>
                    <script type='text/npl'>
                        <![CDATA[
                            local page = document:GetPageCtrl()

                            function close()
                                page:CloseWindow()
                            end

                            {{script}}

                        ]] .. ']]' .. [[>
                    </script>
                    {{mcss}}
                    <kp:window mode='lite'
                               style=''
                               width='{{width}}'
                               height='{{height}}'
                               onclose='close'
                               icon='Texture/Aries/Creator/keepwork/Window/title/biaoti_tishi_32bits.png'
                               title='<%=L"提示" %>'>
                        <div width='100%'
                             style='height: 40px;'>
                        </div>
                        <div width='100%'>
                            {{content}}
                        </div>
                    </kp:window>
                </pe:mcml>
            </body>
        </html>
    ]]

    local template2 = [[
        <html>
            <body>
                <pe:mcml>
                    <script type='text/npl'>
                        <![CDATA[
                            local page = document:GetPageCtrl()

                            function close()
                                page:CloseWindow()
                            end

                            {{script}}

                        ]] .. ']]' .. [[>
                    </script>
                    <style type='type/mcss' src='Mod/WorldShare/cellar/Common/MsgBox/Theme/MsgBoxMcss.mcss'></style>
                    {{mcss}}
                    <pe:container class='msgbox_container1'
                                  width='{{width}}'
                                  height='{{height}}'>
                        <div width='100%'
                            style='height: 40px;'>
                            <div class='msgbox_close'
                                 align='right'
                                 style='margin-right: 20px;
                                        margin-top: 20px;'
                                 onclick='close'></div>
                        </div>
                        <div width='100%'>
                            {{content}}
                        </div>
                    </pe:container>
                </pe:mcml>
            </body>
        </html>
    ]]

    local template = ''

    if templateType == 1 then
        template = template1
    elseif templateType == 2 then
        template = template2
    else
        template = template1
    end

    template = template:gsub('{{width}}', width or 300)
    template = template:gsub('{{height}}', height or 300)
    template = template:gsub('{{content}}', content or '')
    template = template:gsub('{{script}}', script or '')
    template = template:gsub('{{mcss}}', mcss or '')

    self.msgIdCount = self.msgIdCount + 1

    local msgId = self.msgIdCount

    Mod.WorldShare.Utils.ShowWindow(width, height, ParaXML.LuaXML_ParseString(template), 'Mod.WorldShare.MsgBox.Notice_' .. msgId)
end
