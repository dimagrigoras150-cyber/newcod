script_name('MiningBTC Helper v3.3 Beta')
local imgui = require('mimgui')
local encoding = require('encoding')
local sampev = require("lib.samp.events")
local vkeys = require('vkeys')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Настройки и состояние
local active = false
local currentStep = 1
local currentHouse = 0
local totalBTC = 0 
local maxHouses = 15
local targetTime = nil
local isWaiting = false
local btcRate = 0
local gpu_indexes = {1, 2, 3, 4, 7, 8, 9, 10, 13, 14, 15, 16, 19, 20, 21, 22, 25, 26, 27, 28}
local techPhrases = {
    u8"Инициализация потоков...",
    u8"Синхронизация с блокчейном...",
    u8"Шифрование транзакции...",
    u8"Обработка BTC-сигнала...",
    u8"Выгрузка данных в облако...",
    u8"Проверка видеокарт..."
}

-- Переменные MIMGUI
local showMenu = imgui.new.bool(false)
-- Шрифт
local imgui_font = nil
imgui.OnInitialize(function()
    local config = imgui.ImFontConfig()
    config.GlyphRanges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    
    -- Путь к шрифту (agora.ttf должен лежать в папке moonloader)
    local fontPath = getWorkingDirectory() .. '\\agora.ttf' 
    
    if doesFileExist(fontPath) then
        -- Размер шрифта
        imgui_font = imgui.GetIO().Fonts:AddFontFromFileTTF(fontPath, 18, config) 
        imgui.GetIO().Fonts:Build()
    else
        sampAddChatMessage("{FF0000}[MiningBTC] ОШИБКА: agora.ttf не найден!", -1)
    end
end)

imgui.OnFrame(function() return showMenu[0] end, function(player)
    if imgui_font then imgui.PushFont(imgui_font) end 

    imgui.SetNextWindowPos(imgui.ImVec2(20, 350), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(400, 0), imgui.Cond.Always)

    -- [[ СТИЛИ ОКНА ]]
    local style = imgui.GetStyle()
    style.WindowRounding = 12.0
    style.WindowBorderSize = 1.5
    style.WindowPadding = imgui.ImVec2(20, 20)

    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.96))
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(1.0, 0.7, 0.0, 0.5))

    imgui.Begin("Mining Helper v3.3 Beta", showMenu, imgui.WindowFlags.NoDecoration)
        
        -- СОХРАНЯЕМ ПОЗИЦИЮ ДЛЯ ЗАГОЛОВКА
        local startPos = imgui.GetCursorScreenPos()
        local winWidth = imgui.GetWindowWidth()
        local draw = imgui.GetWindowDrawList()

        -- [[ 1. РИСУЕМ КРУГЛУЮ ИКОНКУ ( i ) В ПРАВОМ ВЕРХНЕМ УГЛУ ]]
        local iconX = startPos.x + winWidth - 50 -- Пододвинули ближе к краю
        local iconY = startPos.y -7             -- Опустили чуть ниже, чтобы была вровень с текстом
        
        -- Золотое кольцо
		local radius = 9
        draw:AddCircle(imgui.ImVec2(iconX + radius, iconY + radius), radius, 0xCC00AAFF, 20, 1.3) -- Толщина линии 1.2
        
        -- Буква i (центрируем внутри круга)
        imgui.SetCursorScreenPos(imgui.ImVec2(iconX + 6, iconY + 1)) 
        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.0, 0.8), "i")
        
        -- Зона наведения (невидимая кнопка)
        imgui.SetCursorScreenPos(imgui.ImVec2(iconX, iconY))
        imgui.InvisibleButton("##info_trigger", imgui.ImVec2(radius * 2, radius * 2))

        -- ТУЛТИП С ДАННЫМИ И ЗОЛОТОЙ ПОЛОСКОЙ
        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
                -- 1. ЗАГОЛОВОК ТУЛТИПА
                imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.0, 1.0), u8" ТЕКУЩИЙ КУРС:")
                
                -- [[ 2. ЗОЛОТАЯ ПОЛОСКА (ГРАДИЕНТ) ]]
                local drawT = imgui.GetWindowDrawList()
                local pT = imgui.GetCursorScreenPos()
                local wT = imgui.GetWindowWidth()
                -- Рисуем полоску (высота 2 пикселя, как и в основном окне)
                drawT:AddRectFilledMultiColor(imgui.ImVec2(pT.x, pT.y + 2), imgui.ImVec2(pT.x + wT - 10, pT.y + 4), 
                    0xFF00AAFF, 0x0000AAFF, 0x0000AAFF, 0xFF00AAFF)
                
                imgui.Dummy(imgui.ImVec2(0, 10)) -- Отступ после полоски

                -- 3. ДАННЫЕ ВАЛЮТЫ
                if btcRate > 0 then
                    imgui.Text(u8"Bitcoin: ") imgui.SameLine()
                    imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.5, 1.0), "$" .. btcRate)
                else
                    imgui.TextColored(imgui.ImVec4(1.0, 0.2, 0.2, 1.0), u8"Курс не загружен")
                end
                
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), u8"ГОРЯЧИЕ КЛАВИШИ:")
                imgui.Text(u8"F3 - Старт/Пауза")
                imgui.Text(u8"/freset - Сброс")
                imgui.Text(u8"/fwait [h] - Таймер")
            imgui.EndTooltip()
        end

        -- ВОЗВРАЩАЕМ КУРСОР И РИСУЕМ ЗАГОЛОВОК
        imgui.SetCursorScreenPos(startPos)
        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.0, 1.0), "Mining Helper v3.3 Beta")
        
        -- ЗОЛОТАЯ ПОЛОСКА (ГРАДИЕНТ)
        local p = imgui.GetCursorScreenPos()
        draw:AddRectFilledMultiColor(imgui.ImVec2(p.x, p.y + 5), imgui.ImVec2(p.x + winWidth - 40, p.y + 7), 
            0xFF00AAFF, 0x0000AAFF, 0x0000AAFF, 0xFF00AAFF)
        
        imgui.Dummy(imgui.ImVec2(0, 15)) 

        -- КОНТЕНТ
        imgui.Text(u8"Статус: ") imgui.SameLine()
        if active then 
            imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.0, 1.0), "RUNNING")
        else 
            imgui.TextColored(imgui.ImVec4(1.0, 0.2, 0.2, 1.0), "PAUSED") 
        end
        
        imgui.Spacing()
        imgui.Text(u8(string.format("Дом: %d/%d | Карта: %d/20", currentHouse, maxHouses, currentStep)))
        imgui.Text(u8"Собрано за сессию: ") imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.0, 1.0), tostring(totalBTC) .. " BTC")

        if btcRate > 0 then
            local totalUSD = math.floor(totalBTC * btcRate)
            imgui.Text(u8"Примерная прибыль: ") imgui.SameLine()
            imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.5, 1.0), "$" .. totalUSD)
        end

        imgui.Dummy(imgui.ImVec2(0, 10))

        -- [[ АНИМИРОВАННЫЙ ТАЙМЕР И СТАТУС ]]
        imgui.Separator()
        imgui.Spacing()

        if targetTime and not active then
            -- СОСТОЯНИЕ: ОЖИДАНИЕ ТАЙМЕРА
            local remaining = targetTime - os.time()
            if remaining > 0 then
                local h, m, s = math.floor(remaining / 3600), math.floor((remaining % 3600) / 60), remaining % 60
                imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.5, 1.0), u8"Ожидание старта: ")
                imgui.SameLine()
                imgui.Text(string.format("%02u:%02u:%02u", h, m, s))
                
                -- Пульсирующая полоска
                local wave = math.abs(math.sin(os.clock() * 2)) 
                local draw = imgui.GetWindowDrawList()
                local p = imgui.GetCursorScreenPos()
                draw:AddRectFilled(imgui.ImVec2(p.x, p.y + 2), imgui.ImVec2(p.x + (imgui.GetWindowWidth()-40) * wave, p.y + 4), 0xAA00AAFF)
                imgui.Dummy(imgui.ImVec2(0, 10)) -- ДОБАВИЛ СКОБКУ ТУТ )
            else targetTime = nil end

        elseif active then
            -- [[ УМНЫЙ ХАКЕРСКИЙ ЛОГЕР v3.3 ]]
            local draw = imgui.GetWindowDrawList()
            local winWidth = imgui.GetWindowWidth()
            
            -- Вычисляем индекс фразы (меняется каждые 3 секунды)
            local statusIndex = math.floor(os.clock() / 3.0) % (#techPhrases + 1) + 1
            local statusText = ""
            
            -- [[ ГЕНЕРАТОР КРЕАТИВНЫХ ОТЧЕТОВ ]]
            if statusIndex > #techPhrases then
                -- Список солидных фраз (выбираются по кругу)
                local variants = {
                    u8(string.format("Узел дома #%03d успешно взломан", currentHouse)),
                    u8(string.format("Синхронизация сектора #%d завершена", currentHouse)),
                    u8(string.format("Данные фермы #%d выгружены в сеть", currentHouse)),
                    u8(string.format("Объект #%d: Соединение стабильно", currentHouse))
                }
                -- Выбираем фразу в зависимости от времени (чтобы не мерцала)
                statusText = variants[math.floor(os.clock() / 5) % #variants + 1]
            else
                statusText = techPhrases[statusIndex]
            end

            -- Анимированные точки
            local dots = string.rep(".", math.floor(os.clock() * 2) % 4)
            imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.0, 1.0), statusText .. dots)
            
            -- АНИМАЦИЯ: СКАНИРУЮЩИЙ БЛИК
            local p = imgui.GetCursorScreenPos()
            local w = winWidth - 40
            local progress = (os.clock() % 2) / 2 
            
            -- Рисуем фон и бегущий блик
            draw:AddRectFilled(imgui.ImVec2(p.x, p.y + 2), imgui.ImVec2(p.x + w, p.y + 4), 0x22FFFFFF) 
            draw:AddRectFilled(imgui.ImVec2(p.x + (w * progress), p.y + 2), imgui.ImVec2(p.x + (w * progress) + 20, p.y + 4), 0xFF00AAFF) 
            
            imgui.Dummy(imgui.ImVec2(0, 10))
        else
            -- СОСТОЯНИЕ: ПОКОЙ
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.4, 0.4, 0.4, 1.0))
            imgui.Text(u8"Система в режиме ожидания")
            imgui.PopStyleColor()
        end

    imgui.End()
    imgui.PopStyleColor(2)
    if imgui_font then imgui.PopFont() end 
end)

function main()
    while not isSampAvailable() do wait(100) end
    
    -- Выводим строк в чат
    sampAddChatMessage("{FFD700}[MiningBTC] {FFFFFF}Скрипт v3.3 Beta загружен!", -1)
    sampAddChatMessage("{00FF00}F2 {FFFFFF}- скрыть меню | {00FF00}F3 {FFFFFF}- пауза/старт", -1)
    sampAddChatMessage("{00FF00}/fwait [часы] {FFFFFF}- запустить таймер", -1)
    sampAddChatMessage("{00FF00}/freset {FFFFFF}- сбросить прогресс и таймер", -1)

    sampRegisterChatCommand("fwait", startTimer)
    sampRegisterChatCommand("freset", function()
        currentStep, currentHouse, totalBTC, active, targetTime = 1, 0, 0, false, nil
        sampAddChatMessage("{FFD700}[MiningBTC] {FFFFFF}Прогресс и таймер сброшены.", -1)
    end)

    while true do
        wait(0)
        if isKeyJustPressed(vkeys.VK_F2) then
            showMenu[0] = not showMenu[0]
            imgui.ShowCursor = showMenu[0]
            
            if showMenu[0] then
                lua_thread.create(function()
                    sampSendChat('/phone')
                    sendcef('launchedApp|39') -- ID 39 - Курс валют в /phone
                    sampSendChat('/phone')
                end)
            end
        end
        if isKeyJustPressed(vkeys.VK_F3) then toggleMining() end
    end
end

function toggleMining()
    active = not active
    isWaiting = false
    if active then 
        sampAddChatMessage("{FFD700}[MiningBTC] {00FF00}Старт!", -1)
        sampProcessChatInput("/flashminer") 
    else
        sampAddChatMessage("{FFD700}[MiningBTC] {FF4444}Пауза.", -1)
    end
end

function startTimer(arg)
    local hours = tonumber(arg)
    if hours then
        targetTime = os.time() + (hours * 3600)
        lua_thread.create(function()
            wait(hours * 3600 * 1000)
            if not active then targetTime = nil toggleMining() end
        end)
    end
end

function processNextStep()
    lua_thread.create(function()
        isWaiting = true
        currentStep = currentStep + 1
        wait(200)
        if active then sampProcessChatInput("/flashminer") end
        wait(100)
        isWaiting = false
    end)
end

-- Логика чата
function sampev.onServerMessage(color, text)
    if not active then return end
    local cleanText = text:gsub('{......}', ''):lower()
    
    if cleanText:find("Выберите дом с майнинг") or 
       cleanText:find("минимум 1") or 
       cleanText:find("целыми частями") or
       cleanText:find("Вам был добавлен предмет") or
	   cleanText:find("Вы вывели") then
        
        if (cleanText:find("минимум 1") or cleanText:find("целыми частями")) and not isWaiting then
            processNextStep()
        end
        return false 
    end
end

-- Логика диалогов
function sampev.onShowDialog(id, style, title, button1, button2, text)
    local cleanTitle = title:gsub('{......}', '')

    -- [[ ТИХИЙ ПЕРЕХВАТ КУРСА ]]
    if cleanTitle:find("Курс валют") then
        local rateVal = text:match("Bitcoin %(BTC%):%s+%$([%d]+)")
        if rateVal then
            btcRate = tonumber(rateVal)
            -- МЫ УБРАЛИ ОТСЮДА sampAddChatMessage, чтобы не флудить в чат
            
            -- Автоматически закрываем диалог через 100мс
            lua_thread.create(function() 
                wait(100) 
                sampSendDialogResponse(id, 0, 0, "") 
            end)
            return false -- Скрываем окно от глаз
        end
    end

    -- Если скрипт на паузе, дальше ничего не делаем
    if not active then return end

    -- 1. Выбор дома
    if cleanTitle:find("Выбор") and not cleanTitle:find("видеокарт") then
        lua_thread.create(function() wait(100) sampSendDialogResponse(id, 1, currentHouse, "") end)
        return false 
    end

    -- 2. Выбор видеокарты
    if cleanTitle:find("видеокарт") then
        lua_thread.create(function()
            wait(125)
            if currentStep <= #gpu_indexes then
                sampSendDialogResponse(id, 1, gpu_indexes[currentStep], "")
            else
                currentHouse, currentStep = currentHouse + 1, 1
                if currentHouse < maxHouses then 
                    wait(125) 
                    sampProcessChatInput("/flashminer")
                else 
                    active = false 
                    sampAddChatMessage("{00FF00}[MiningBTC] Все дома обработаны! Работа завершена.", -1)
                end
            end
        end)
        return false 
    end

    -- 3. Сбор BTC
    if cleanTitle:find("Стойка №") then
        local btcVal = text:match("%(([%d%.]+)%s+BTC%)")
        lua_thread.create(function() 
            wait(200) 
            if btcVal and tonumber(btcVal) >= 1.0 then
                totalBTC = totalBTC + math.floor(tonumber(btcVal))
            end
            sampSendDialogResponse(id, 1, 1, "") 
        end)
        return false 
    end

    -- 4. Подтверждение прибыли
    if cleanTitle:find("прибыли") then
        lua_thread.create(function() wait(100) sampSendDialogResponse(id, 1, 0, "") end)
        return false 
    end
end 

function sendcef(str)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt16(bs, #str) 
    raknetBitStreamWriteString(bs, str)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end
