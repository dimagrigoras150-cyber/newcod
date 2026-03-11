script_name("AutoPiar")
script_author("ARMOR")
script_version("2.0")

require "lib.moonloader"
local imgui = require "imgui"
local inicfg = require "inicfg"
local encoding = require 'encoding'
local ev = require 'lib.samp.events'

encoding.default = 'CP1251'
u8 = encoding.UTF8

local cfg = inicfg.load({
    config = {
        vr = "",
        fam = "",
        j = "",
        s = "",
        ad = "",
    },
    interface = {
        vr_checkbox = false,
        fam_checkbox = false,
        j_checkbox = false,
        s_checkbox = false,
        ad_checkbox = false,
        vr_slider = 1,
        fam_slider = 1,
        j_slider = 1,
        s_slider = 1,
        ad_slider = 1,
        ad_radiobutton = 1,
        theme_id = 0,
    }
}, "AutoPiar.ini")

local enable = false
local main_window_state = imgui.ImBool(false)

local vr_check = imgui.ImBool(cfg.interface.vr_checkbox)
local fam_check = imgui.ImBool(cfg.interface.fam_checkbox)
local j_check = imgui.ImBool(cfg.interface.j_checkbox)
local s_check = imgui.ImBool(cfg.interface.s_checkbox)
local ad_check = imgui.ImBool(cfg.interface.ad_checkbox)

local vr = imgui.ImBuffer(256)
local fam = imgui.ImBuffer(256)
local j = imgui.ImBuffer(256)
local s = imgui.ImBuffer(256)
local ad = imgui.ImBuffer(256)

local vr_slider = imgui.ImInt(cfg.interface.vr_slider)
local fam_slider = imgui.ImInt(cfg.interface.fam_slider)
local j_slider = imgui.ImInt(cfg.interface.j_slider)
local s_slider = imgui.ImInt(cfg.interface.s_slider)
local ad_slider = imgui.ImInt(cfg.interface.ad_slider)

local ad_radiobutton = imgui.ImInt(cfg.interface.ad_radiobutton)
local themes_combo = imgui.ImInt(0)

local delay = 0.5

-- Блокировка управления
function disableControls()
    lockPlayerControl(true)
end

function enableControls()
    lockPlayerControl(false)
    -- Включаем обратно отключенные клавиши  --setVirtualKeyDisabled(0x20, true)
end

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(100)
    end

    if not doesFileExist(getWorkingDirectory()..'\\config\\AutoPiar.ini') then
        inicfg.save(cfg, 'AutoPiar.ini')
    end

    sampAddChatMessage("[AutoPiar]: {FFFFFF}Скрипт загружен, для настройки введите /ap", 0x5CBCFF)
    sampAddChatMessage("[AutoPiar]: {FFFFFF}Отдельное спасибо: mafizik и всему разделу помощи в разделе Разработка LUA :)", 0x5CBCFF)

    sampRegisterChatCommand("ap", function()
        main_window_state.v = not main_window_state.v
        imgui.Process = main_window_state.v
    end)

		while true do
        wait(0)
        vr.v = cfg.config.vr
        fam.v = cfg.config.fam
        j.v = cfg.config.j
        s.v = cfg.config.s
        ad.v = cfg.config.ad
        themes_combo.v = cfg.interface.theme_id
        styles = cfg.interface.theme_id

        -- Проверка состояния чекбоксов и флага
        if enable and not vr_check.v and not fam_check.v and not j_check.v and not ad_check.v and not s_check.v then
            sampAddChatMessage("[AutoPiar]: {FFFFFF}Произошла ошибка, были сняты все CheckBox'ы ", 0xFF0000)
            enable = false
        end

        -- Управление блокировкой при открытии/закрытии окна
        if main_window_state.v then
            disableControls()
        else
            enableControls()
        end

    end
end
function piar_fam()
    wait(1000)
    while enable do
        if fam_check.v then
            sampSendChat("/fam " .. u8:decode(cfg.config.fam))
            sampAddChatMessage("[AutoPiar]: {FFFFFF}Отправлено сообщение в /fam", 0x5CBCFF) -- Хз зачем, но пусть будет
        end
        wait(fam_slider.v * 1000)
    end
end

function piar_j()
    wait(500)
    while enable do
        if j_check.v then
            sampSendChat("/j " .. u8:decode(cfg.config.j))
            sampAddChatMessage("[AutoPiar]: {FFFFFF}Отправлено сообщение в /j", 0x5CBCFF)
        end
        wait(j_slider.v * 1000)
    end
end

function piar_s()
    wait(1000)
    while enable do
        if s_check.v then
            local message = u8:decode(cfg.config.s)
            -- Проверка длины сообщения
            if #message > 128 then
                sampAddChatMessage("[AutoPiar]: {FF0000}Ошибка - Сообщение слишком длинное для /s", 0xFF0000)
            else
                sampSendChat("/s " .. message)
                sampAddChatMessage("[AutoPiar]: {FFFFFF}Отправлено сообщение в /s", 0x5CBCFF)
            end
        end
        wait(s_slider.v * 1000)
    end
end

function piar_ad()
    wait(1500)
    while enable do
        if ad_check.v then
            local message = u8:decode(cfg.config.ad)
            sampSendChat("/ad " .. message)
            wait(300)
            local button = cfg.interface.ad_radiobutton == 1 and 1 or 2
            sampSendDialogResponse(15346, 1, button, nil)
            sampCloseCurrentDialogWithButton(1)
            wait(500)
            sampCloseCurrentDialogWithButton(1)
            sampAddChatMessage("[AutoPiar]: {FFFFFF}Отправлено объявление /ad", 0x5CBCFF)
        end
        wait(ad_slider.v * 1000)
    end
end

function piar_vr()
    wait(2300)
    while enable do
        if vr_check.v then
            pcall(sampProcessChatInput, "/vr " .. u8:decode(cfg.config.vr))
            sampAddChatMessage("[AutoPiar]: {FFFFFF}Отправлено сообщение в /vr", 0x5CBCFF)
        end
        wait(vr_slider.v * 1000)
    end
end

function ev.onShowDialog(id, style, title, b1, b2, text)
    if text:find("рекламой") and vr_check.v and enable then
        lua_thread.create(function()
            wait(50)
            sampSendDialogResponse(25628,1,0,"")
            sampCloseCurrentDialogWithButton(1)
        end)
    end
end

function imgui.OnDrawFrame()
    local style = imgui.GetStyle()
    local clrs = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.Alpha = 1
    style.ChildWindowRounding = 0
    style.WindowRounding = 0
    style.GrabRounding = 0
    style.GrabMinSize = 12
    style.FrameRounding = 5
    local triangle = 0xFF002779

    if styles == 0 then
        clrs[clr.Text] = ImVec4(1, 1, 1, 1)
        clrs[clr.TextDisabled] = ImVec4(0.6, 0.6, 0.6, 1)
        clrs[clr.WindowBg] = ImVec4(0, 0, 0, 1)
        clrs[clr.ChildWindowBg] = ImVec4(0, 0, 0, 0)
        clrs[clr.PopupBg] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.Border] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.BorderShadow] = ImVec4(0, 0, 0, 0)
        clrs[clr.FrameBg] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.FrameBgHovered] = ImVec4(0.06, 0.37, 0.74, 1)
        clrs[clr.FrameBgActive] = ImVec4(0.1, 0.41, 0.78, 1)
        clrs[clr.TitleBg] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.TitleBgActive] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.TitleBgCollapsed] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.MenuBarBg] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.ScrollbarBg] = ImVec4(0.15, 0.15, 0.15, 1)
        clrs[clr.ScrollbarGrab] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.ScrollbarGrabHovered] = ImVec4(0.06, 0.37, 0.74, 1)
        clrs[clr.ScrollbarGrabActive] = ImVec4(0.1, 0.41, 0.78, 1)
        clrs[clr.ComboBg] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.CheckMark] = ImVec4(1, 1, 1, 1)
        clrs[clr.SliderGrab] = ImVec4(0.18, 0.18, 0.18, 1)
        clrs[clr.SliderGrabActive] = ImVec4(0.26, 0.26, 0.26, 1)
        clrs[clr.Button] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.ButtonHovered] = ImVec4(0.06, 0.37, 0.74, 1)
        clrs[clr.ButtonActive] = ImVec4(0.1, 0.41, 0.78, 1)
        clrs[clr.Header] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.HeaderHovered] = ImVec4(0.06, 0.37, 0.74, 1)
        clrs[clr.HeaderActive] = ImVec4(0.1, 0.41, 0.78, 1)
        clrs[clr.Separator] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.SeparatorHovered] = ImVec4(0.06, 0.37, 0.74, 1)
        clrs[clr.SeparatorActive] = ImVec4(0.1, 0.41, 0.78, 1)
        clrs[clr.ResizeGrip] = ImVec4(0.14, 0.45, 0.82, 1)
        clrs[clr.ResizeGripHovered] = ImVec4(0.06, 0.37, 0.74, 1)
        clrs[clr.ResizeGripActive] = ImVec4(0.1, 0.41, 0.78, 1)
        clrs[clr.CloseButton] = ImVec4(0.2, 0.2, 0.2, 0.88)
        clrs[clr.CloseButtonHovered] = ImVec4(0.2, 0.2, 0.2, 1)
        clrs[clr.CloseButtonActive] = ImVec4(0.2, 0.2, 0.2, 0.61)
        clrs[clr.PlotLines] = ImVec4(1, 1, 1, 1)
        clrs[clr.PlotLinesHovered] = ImVec4(1, 1, 1, 1)
        clrs[clr.PlotHistogram] = ImVec4(1, 1, 1, 1)
        clrs[clr.PlotHistogramHovered] = ImVec4(1, 1, 1, 1)
        clrs[clr.TextSelectedBg] = ImVec4(0, 0, 0, 0.35)
        clrs[clr.ModalWindowDarkening] = ImVec4(0.2, 0.2, 0.2, 0.35)
    elseif styles == 1 then
        triangle = 0xFF007723
        clrs[clr.Text] = ImVec4(1, 1, 1, 1)
        clrs[clr.TextDisabled] = ImVec4(0.6, 0.6, 0.6, 1)
        clrs[clr.WindowBg] = ImVec4(0, 0, 0, 1)
        clrs[clr.ChildWindowBg] = ImVec4(0, 0, 0, 0)
        clrs[clr.PopupBg] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.Border] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.BorderShadow] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.FrameBg] = ImVec4(0.53, 0.71, 0.01, 0.71)
        clrs[clr.FrameBgHovered] = ImVec4(0.53, 0.71, 0.01, 0.59)
        clrs[clr.FrameBgActive] = ImVec4(0.53, 0.71, 0.01, 0.39)
        clrs[clr.TitleBg] = ImVec4(0.53, 0.71, 0.01, 0.82)
        clrs[clr.TitleBgActive] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.TitleBgCollapsed] = ImVec4(0.53, 0.71, 0.01, 0.67)
        clrs[clr.MenuBarBg] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.ScrollbarBg] = ImVec4(0, 0, 0, 1)
        clrs[clr.ScrollbarGrab] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.ScrollbarGrabHovered] = ImVec4(0.53, 0.71, 0.01, 0.78)
        clrs[clr.ScrollbarGrabActive] = ImVec4(0.53, 0.71, 0.01, 0.59)
        clrs[clr.ComboBg] = ImVec4(0.53, 0.71, 0.01, 0.78)
        clrs[clr.CheckMark] = ImVec4(1, 1, 1, 1)
        clrs[clr.SliderGrab] = ImVec4(0.18, 0.18, 0.18, 1)
        clrs[clr.SliderGrabActive] = ImVec4(0.26, 0.26, 0.26, 1)
        clrs[clr.Button] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.ButtonHovered] = ImVec4(0.53, 0.71, 0.01, 0.78)
        clrs[clr.ButtonActive] = ImVec4(0.53, 0.71, 0.01, 0.71)
        clrs[clr.Header] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.HeaderHovered] = ImVec4(0.53, 0.71, 0.01, 0.78)
        clrs[clr.HeaderActive] = ImVec4(0.53, 0.71, 0.01, 0.71)
        clrs[clr.Separator] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.SeparatorHovered] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.SeparatorActive] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.ResizeGrip] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.ResizeGripHovered] = ImVec4(0.53, 0.71, 0.01, 0.78)
        clrs[clr.ResizeGripActive] = ImVec4(0.53, 0.71, 0.01, 0.71)
        clrs[clr.CloseButton] = ImVec4(0, 0, 0, 1)
        clrs[clr.CloseButtonHovered] = ImVec4(0.29, 0.29, 0.29, 1)
        clrs[clr.CloseButtonActive] = ImVec4(0.77, 0.77, 0.77, 0.78)
        clrs[clr.PlotLines] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.PlotLinesHovered] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.PlotHistogram] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.PlotHistogramHovered] = ImVec4(0.53, 0.71, 0.01, 1)
        clrs[clr.TextSelectedBg] = ImVec4(0.26, 0.26, 0.26, 0.35)
        clrs[clr.ModalWindowDarkening] = ImVec4(0.2, 0.2, 0.2, 0.35)
    elseif styles == 2 then
        triangle = 0xFFD6388B
        clrs[clr.Text] = ImVec4(1, 1, 1, 1)
        clrs[clr.TextDisabled] = ImVec4(0.6, 0.6, 0.6, 1)
        clrs[clr.WindowBg] = ImVec4(0, 0, 0, 1)
        clrs[clr.ChildWindowBg] = ImVec4(0, 0, 0, 0)
        clrs[clr.PopupBg] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.Border] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.BorderShadow] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.FrameBg] = ImVec4(0.71, 0.01, 0.38, 0.71)
        clrs[clr.FrameBgHovered] = ImVec4(0.71, 0.01, 0.38, 0.59)
        clrs[clr.FrameBgActive] = ImVec4(0.71, 0.01, 0.38, 0.39)
        clrs[clr.TitleBg] = ImVec4(0.71, 0.01, 0.38, 0.82)
        clrs[clr.TitleBgActive] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.TitleBgCollapsed] = ImVec4(0.71, 0.01, 0.38, 0.67)
        clrs[clr.MenuBarBg] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.ScrollbarBg] = ImVec4(0, 0, 0, 1)
        clrs[clr.ScrollbarGrab] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.ScrollbarGrabHovered] = ImVec4(0.71, 0.01, 0.38, 0.78)
        clrs[clr.ScrollbarGrabActive] = ImVec4(0.71, 0.01, 0.38, 0.59)
        clrs[clr.ComboBg] = ImVec4(0.71, 0.01, 0.38, 0.78)
        clrs[clr.CheckMark] = ImVec4(1, 1, 1, 1)
        clrs[clr.SliderGrab] = ImVec4(0.18, 0.18, 0.18, 1)
        clrs[clr.SliderGrabActive] = ImVec4(0.26, 0.26, 0.26, 1)
        clrs[clr.Button] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.ButtonHovered] = ImVec4(0.71, 0.01, 0.38, 0.78)
        clrs[clr.ButtonActive] = ImVec4(0.71, 0.01, 0.38, 0.71)
        clrs[clr.Header] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.HeaderHovered] = ImVec4(0.71, 0.01, 0.38, 0.78)
        clrs[clr.HeaderActive] = ImVec4(0.71, 0.01, 0.38, 0.71)
        clrs[clr.Separator] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.SeparatorHovered] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.SeparatorActive] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.ResizeGrip] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.ResizeGripHovered] = ImVec4(0.71, 0.01, 0.38, 0.78)
        clrs[clr.ResizeGripActive] = ImVec4(0.71, 0.01, 0.38, 0.71)
        clrs[clr.CloseButton] = ImVec4(0, 0, 0, 1)
        clrs[clr.CloseButtonHovered] = ImVec4(0.29, 0.29, 0.29, 1)
        clrs[clr.CloseButtonActive] = ImVec4(0.77, 0.77, 0.77, 0.78)
        clrs[clr.PlotLines] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.PlotLinesHovered] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.PlotHistogram] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.PlotHistogramHovered] = ImVec4(0.71, 0.01, 0.38, 1)
        clrs[clr.TextSelectedBg] = ImVec4(0.26, 0.26, 0.26, 0.35)
        clrs[clr.ModalWindowDarkening] = ImVec4(0.2, 0.2, 0.2, 0.35)
    elseif styles == 3 then
        triangle = 0xFFD67200
        clrs[clr.Text] = ImVec4(1, 1, 1, 1)
        clrs[clr.TextDisabled] = ImVec4(0.6, 0.6, 0.6, 1)
        clrs[clr.WindowBg] = ImVec4(0, 0, 0, 1)
        clrs[clr.ChildWindowBg] = ImVec4(0, 0, 0, 0)
        clrs[clr.PopupBg] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.Border] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.BorderShadow] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.FrameBg] = ImVec4(0.85, 0.59, 0, 0.71)
        clrs[clr.FrameBgHovered] = ImVec4(0.85, 0.59, 0, 0.59)
        clrs[clr.FrameBgActive] = ImVec4(0.85, 0.59, 0, 0.39)
        clrs[clr.TitleBg] = ImVec4(0.85, 0.59, 0, 0.82)
        clrs[clr.TitleBgActive] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.TitleBgCollapsed] = ImVec4(0.85, 0.59, 0, 0.67)
        clrs[clr.MenuBarBg] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.ScrollbarBg] = ImVec4(0, 0, 0, 1)
        clrs[clr.ScrollbarGrab] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.ScrollbarGrabHovered] = ImVec4(0.85, 0.59, 0, 0.78)
        clrs[clr.ScrollbarGrabActive] = ImVec4(0.85, 0.59, 0, 0.59)
        clrs[clr.ComboBg] = ImVec4(0.85, 0.59, 0, 0.78)
        clrs[clr.CheckMark] = ImVec4(1, 1, 1, 1)
        clrs[clr.SliderGrab] = ImVec4(0.18, 0.18, 0.18, 1)
        clrs[clr.SliderGrabActive] = ImVec4(0.26, 0.26, 0.26, 1)
        clrs[clr.Button] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.ButtonHovered] = ImVec4(0.85, 0.59, 0, 0.78)
        clrs[clr.ButtonActive] = ImVec4(0.85, 0.59, 0, 0.71)
        clrs[clr.Header] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.HeaderHovered] = ImVec4(0.85, 0.59, 0, 0.78)
        clrs[clr.HeaderActive] = ImVec4(0.85, 0.59, 0, 0.71)
        clrs[clr.Separator] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.SeparatorHovered] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.SeparatorActive] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.ResizeGrip] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.ResizeGripHovered] = ImVec4(0.85, 0.59, 0, 0.78)
        clrs[clr.ResizeGripActive] = ImVec4(0.85, 0.59, 0, 0.71)
        clrs[clr.CloseButton] = ImVec4(0, 0, 0, 1)
        clrs[clr.CloseButtonHovered] = ImVec4(0.29, 0.29, 0.29, 1)
        clrs[clr.CloseButtonActive] = ImVec4(0.77, 0.77, 0.77, 0.78)
        clrs[clr.PlotLines] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.PlotLinesHovered] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.PlotHistogram] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.PlotHistogramHovered] = ImVec4(0.85, 0.59, 0, 1)
        clrs[clr.TextSelectedBg] = ImVec4(0.26, 0.26, 0.26, 0.35)
        clrs[clr.ModalWindowDarkening] = ImVec4(0.2, 0.2, 0.2, 0.35)
    end

    if not main_window_state.v then
        imgui.Process = false
    end

    if main_window_state.v then
        local sw, sh = getScreenResolution()

        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(600, 475), imgui.Cond.FirstUseEver)
        imgui.Begin(u8"Авто Пиар", main_window_state, imgui.WindowFlags.NoResize)

        -- Пиар в /vr
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8("Пиар в /vr")).x)/2)
        imgui.Text(u8"Пиар в /vr")
        if imgui.Checkbox("##1", vr_check) then
            cfg.interface.vr_checkbox = vr_check.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.SameLine(30)
        imgui.PushItemWidth(560)
        if imgui.InputText("##2", vr) then
            cfg.config.vr = vr.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.PushItemWidth(582)
        if imgui.SliderInt("##3", vr_slider, 1, 600, u8' %.0f с') then
            cfg.interface.vr_slider = vr_slider.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.Separator()

        -- Пиар в /fam
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8("Пиар в /fam")).x)/2)
        imgui.Text(u8"Пиар в /fam")
        if imgui.Checkbox("##4", fam_check) then
            cfg.interface.fam_checkbox = fam_check.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.SameLine(30)
        imgui.PushItemWidth(560)
        if imgui.InputText("##5", fam) then
            cfg.config.fam = fam.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.PushItemWidth(582)
        if imgui.SliderInt("##6", fam_slider, 1, 600, u8'%.0f с') then
            cfg.interface.fam_slider = fam_slider.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.Separator()

        -- Пиар в /j
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8("Пиар в /j")).x)/2)
        imgui.Text(u8"Пиар в /j")
        if imgui.Checkbox("##7", j_check) then
            cfg.interface.j_checkbox = j_check.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.SameLine(30)
        imgui.PushItemWidth(560)
        if imgui.InputText("##8", j) then
            cfg.config.j = j.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.PushItemWidth(582)
        if imgui.SliderInt("##9", j_slider, 1, 600, u8'%.0f с') then
            cfg.interface.j_slider = j_slider.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.Separator()

        -- Пиар в /s
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8("Пиар в /s")).x)/2)
        imgui.Text(u8"Пиар в /s")
        if imgui.Checkbox("##10", s_check) then
            cfg.interface.s_checkbox = s_check.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.SameLine(30)
        imgui.PushItemWidth(560)
        if imgui.InputText("##11", s) then
            cfg.config.s = s.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.PushItemWidth(582)
        if imgui.SliderInt("##12", s_slider, 1, 600, u8'%.0f с') then
            cfg.interface.s_slider = s_slider.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.Separator()

        -- Пиар в /ad
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8("Пиар в /ad")).x)/2)
        imgui.Text(u8"Пиар в /ad")
        if imgui.Checkbox("##13", ad_check) then
            cfg.interface.ad_checkbox = ad_check.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.SameLine(30)
        imgui.PushItemWidth(560)
        if imgui.InputText("##14", ad) then
            cfg.config.ad = ad.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.PushItemWidth(582)
        if imgui.SliderInt("##15", ad_slider, 1, 600, u8'%.0f с') then
            cfg.interface.ad_slider = ad_slider.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        if imgui.RadioButton(u8"Обычное объявление", ad_radiobutton, 1) then
            cfg.interface.ad_radiobutton = ad_radiobutton.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.SameLine(470)
        if imgui.RadioButton(u8"VIP объявление", ad_radiobutton, 2) then
            cfg.interface.ad_radiobutton = ad_radiobutton.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.Separator()

        -- Темы интерфейса
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8"Цветовая тема окна").x)/2)
        imgui.Text(u8"Цветовая тема окна")
        if imgui.Combo("##16", themes_combo, {u8"Синий стиль", u8"Зеленый стиль", u8"Розовый стиль", u8"Оранжевый стиль"}) then
            styles = themes_combo.v
            cfg.interface.theme_id = themes_combo.v
            inicfg.save(cfg, "AutoPiar.ini")
        end
        imgui.Separator()

        -- Кнопка запуска авто-пиара
        if imgui.Button(u8((enable and 'Остановить' or 'Запустить') .. ' авто-пиар'), imgui.ImVec2(582, 20))
                -- вместо or или
             then
            enable = not enable
            if enable then
                piar_vr1 = lua_thread.create(piar_vr)
                piar_fam2 = lua_thread.create(piar_fam)
                piar_j3 = lua_thread.create(piar_j)
                piar_s4 = lua_thread.create(piar_s)
                piar_ad5 = lua_thread.create(piar_ad)
            else
                if piar_vr1 then piar_vr1:terminate() end
                if piar_fam2 then piar_fam2:terminate() end
                if piar_j3 then piar_j3:terminate() end
                if piar_s4 then piar_s4:terminate() end
                if piar_ad5 then piar_ad5:terminate() end
            end
            if not vr_check.v and not fam_check.v and not j_check.v and not ad_check.v and not s_check.v then
                sampAddChatMessage("[AutoPiar]: {FFFFFF}Небыло выбрано ни одного варианта пиара!", triangle)
                enable = false
            else
                sampAddChatMessage(enable and "[AutoPiar]: {FFFFFF}Пиар активирован!" or "[AutoPiar]: {FFFFFF}Пиар деактивирован!", triangle)
                                -- тоже вместо or или
            end
        end
        imgui.End()
    end
end

function ev.onServerMessage(color, text)
    if text:find("%[%u+%] {%x+}[A-z0-9_]+%[" .. select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) .. "%]:.+") then
        finished = true
    end
    if text:find("^%[Ошибка%].*После последнего сообщения в этом чате нужно подождать") then
        lua_thread.create(function()
            wait(delay * 1000)
            sampSendChat("/vr " .. message)
            try = try + 1
        end)
        return false
    end
    if text:find("^Вы заглушены") or text:find("Для возможности повторной отправки сообщения в этот чат") then
        finished = true
    end
        --тоже так же
	end
