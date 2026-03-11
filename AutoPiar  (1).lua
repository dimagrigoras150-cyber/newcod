script_name('Mining BTC Helper Final Fixed')
require("moonloader")
local sampev = require("lib.samp.events")
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- [[ НАСТРОЙКИ ]]
local active = false
local showMenu = true
local currentStep = 1
local currentHouse = 0
local totalBTC = 0.0
local maxHouses = 15
local delayMult = 1.0
local gpu_indexes = {1, 2, 3, 4, 7, 8, 9, 10, 13, 14, 15, 16, 19, 20, 21, 22, 25, 26, 27, 28}
local isWaiting = false

-- Инициализация шрифта
font = renderCreateFont("Arial", 10, 5)

function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage(u8:decode("{FFD700}[MiningBTC] {FFFFFF}Версия 12.1 готова!"), -1)
    sampAddChatMessage(u8:decode("{00FF00}F2 {FFFFFF}- скрыть меню | {00FF00}L {FFFFFF}- пауза/старт | {00FF00}/fwait [ч] {FFFFFF}- таймер"), -1)

    -- Регистрация команд
    sampRegisterChatCommand("fwait", startTimer)
    sampRegisterChatCommand("freset", function()
        currentStep = 1
        currentHouse = 0
        totalBTC = 0.0
        sampAddChatMessage(u8:decode("{FFD700}[MiningBTC] {FFFFFF}Прогресс сброшен к началу."), -1)
    end)

    while true do
        wait(0)
        if showMenu then
            local x, y = 10, 300 -- Базовые координаты
            local w, h = 360, 210 -- Размеры

            -- 1. ЭФФЕКТ СВЕЧЕНИЯ (рамка вокруг)
            renderDrawBox(x - 2, y - 2, w + 4, h + 4, 0x55FFAA00) -- Внешнее оранжевое свечение
            renderDrawBox(x - 1, y - 1, w + 2, h + 2, 0xFF332211) -- Темная кайма

            -- 2. ОСНОВНОЙ ФОН (Темный, почти как на скрине)
            renderDrawBox(x, y, w, h, 0xEE1A1310) 

            -- 3. ПОЛОСКА-АКЦЕНТ СВЕРХУ (Золотистая линия)
            renderDrawBox(x + 10, y + 40, w - 20, 1, 0x66FFCC00) 

            -- 4. ТЕКСТ (Заголовки и данные)
            renderFontDrawText(font, u8:decode("{FFCC00}Mining Helper v12.2 PRO"), x + 15, y + 10, 0xFFFFFFFF)
            
            renderFontDrawText(font, u8:decode("Статус: ") .. (active and "{00FF00}RUNNING" or "{FF4444}PAUSED"), x + 15, y + 50, 0xFFFFFFFF)
            renderFontDrawText(font, u8:decode("Дом: ") .. currentHouse .. "/" .. maxHouses .. u8:decode(" | Карта: ") .. currentStep .. "/20", x + 15, y + 75, 0xFFFFFFFF)
            renderFontDrawText(font, u8:decode("Собрано за сессию: {FFFF00}") .. string.format("%.4f BTC", totalBTC), x + 15, y + 100, 0xFFFFFFFF)

            -- ТАЙМЕР
            if targetTime and not active then
                local remaining = targetTime - os.time()
                if remaining > 0 then
                    local h, m, s = math.floor(remaining / 3600), math.floor((remaining % 3600) / 60), remaining % 60
                    local timerStr = string.format("Отложенный старт: %02d:%02d:%02d", h, m, s)
                    renderFontDrawText(font, u8:decode("{00FF00}" .. timerStr), x + 15, y + 130, 0xFFFFFFFF)
                else targetTime = nil end
            end

            -- НИЖНЯЯ ЧАСТЬ (Подсказки)
            renderFontDrawText(font, u8:decode("{AAAAAA}'L' - Пауза/Старт | /freset - Сброс"), x + 15, y + 175, 0xFFFFFFFF)
            
            -- 5. ЯРКИЙ АКЦЕНТ СНИЗУ (Свечение как на скрине)
            renderDrawBox(x + 20, y + h - 2, w - 40, 2, 0xAAFFCC00) 
        end

        if isKeyJustPressed(VK_F2) then showMenu = not showMenu end
        if isKeyJustPressed(VK_L) then toggleMining() end
    end
end

function toggleMining()
    active = not active
    isWaiting = false
    sampAddChatMessage(u8:decode("{FFD700}[MiningBTC] ") .. (active and "{00FF00}STARTED" or "{FF0000}STOPPED"), -1)
    if active then sampProcessChatInput("/flashminer") end
end

function startTimer(arg)
    local hours = tonumber(arg)
    if hours then
        targetTime = os.time() + (hours * 3600) -- Запоминаем время, когда надо начать
        lua_thread.create(function()
            sampAddChatMessage(u8:decode("{FFD700}[MiningBTC] {FFFFFF}Таймер запущен на ") .. hours .. u8:decode(" ч."), -1)
            wait(hours * 3600 * 1000)
            if not active then 
                targetTime = nil
                toggleMining() 
            end
        end)
    else
        sampAddChatMessage(u8:decode("{FF0000}[MiningBTC] {FFFFFF}Используйте: /fwait [часы]"), -1)
    end
end

-- [[ ЛОГИКА ЧАТА ]]
function sampev.onServerMessage(color, text)
    if not active then return end
    
    -- ГЛУБОКАЯ ОЧИСТКА: убираем все цвета и лишние символы
    local cleanText = text:gsub('{......}', ''):lower()
    
    -- 1. СЧИТАЕМ BTC (Новая логика поиска числа)
    -- Ищем конструкцию "вывели [число] BTC"
    local btcGain = cleanText:match("вывели%s+(%d+)%s+btc")
    if btcGain then 
        totalBTC = totalBTC + tonumber(btcGain) 
    end

    -- 2. СКРЫВАЕМ ФЛУД (Ошибка про 1 коин)
    -- Если в строке есть хоть намек на эту ошибку - удаляем её из чата
    if cleanText:find("выводить прибыль можно") or cleanText:find("минимум 1") or cleanText:find("целыми частями") then
        if not isWaiting then
            processNextStep() -- Запускаем переход к следующей карте
        end
        return false -- ЭТО ГАРАНТИРОВАННО СКРЫВАЕТ СТРОКУ
    end

    -- 3. ПЕРЕХОД ПОСЛЕ УСПЕХА
    if btcGain and not isWaiting then
        processNextStep()
    end
end

-- Вспомогательная функция перехода (чтобы не дублировать код)
function processNextStep()
    lua_thread.create(function()
        isWaiting = true
        currentStep = currentStep + 1
        wait(500) -- Turbo-задержка
        sampProcessChatInput("/flashminer") 
        wait(800)
        isWaiting = false
    end)
end

-- [[ ЛОГИКА ДИАЛОГОВ ]]
function sampev.onShowDialog(id, style, title, button1, button2, text)
    if not active then return end
    local cleanTitle = title:gsub('{......}', '')

    if cleanTitle:find(u8:decode("Выбор")) and not cleanTitle:find(u8:decode("видеокарт")) then
        lua_thread.create(function() wait(1000) sampSendDialogResponse(id, 1, currentHouse, "") end)
    end

    if cleanTitle:find(u8:decode("видеокарт")) then
        lua_thread.create(function()
            wait(1200)
            if currentStep <= #gpu_indexes then
                sampSendDialogResponse(id, 1, gpu_indexes[currentStep], "")
            else
                currentHouse = currentHouse + 1
                currentStep = 1
                if currentHouse < maxHouses then
                    wait(500)
                    sampProcessChatInput("/flashminer")
                else
                    active = false
                    sampAddChatMessage(u8:decode("{00FF00}[MiningBTC] Все дома пройдены!"), -1)
                end
            end
        end)
    end

    if cleanTitle:find(u8:decode("Стойка")) then
        lua_thread.create(function() wait(1000) sampSendDialogResponse(id, 1, 1, "") end)
    end
    if cleanTitle:find(u8:decode("прибыли")) then
        lua_thread.create(function() wait(800) sampSendDialogResponse(id, 1, 0, "") end)
    end
end
