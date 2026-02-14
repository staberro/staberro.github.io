--[[
  ================================================================
  MEGA TASK SYSTEM v2.0
  vBot / OTClientV8 - Prywatny serwer 8.6
  ================================================================
  
  INSTALACJA:
  1. Wklej w Main > Edit w bocie
  2. Waypoints wgraj z pliku waypoints_config
  3. Wybierz vocacje przyciskiem
  4. Wlacz macro "Task System" i "Auto Spells"
  
  GITHUB AUTO-UPDATE:
  Skrypt sprawdza wersje przy starcie.
  Ustaw GITHUB_RAW_URL na swoj link do raw pliku na GitHubie.
  ================================================================
]]

-- ============================================================
-- WERSJA (zmien przy kazdej aktualizacji!)
-- ============================================================
local SCRIPT_VERSION = "2.0.0"

-- Ustaw na swoj GitHub raw URL (np. https://raw.githubusercontent.com/USER/REPO/main/mega_task_v2.lua)
-- Zostaw pusty jesli nie chcesz auto-update
local GITHUB_RAW_URL = ""
local GITHUB_WAYPOINTS_URL = ""

-- ============================================================
-- KONFIGURACJA OGOLNA
-- ============================================================

local KILL_BUFFER     = 320   -- ile zabic per task (300 + zapas 20)
local KILL_BUFFER_750 = 770   -- ile zabic per task 750 (750 + zapas 20)
local NPC_DELAY       = 1500  -- opoznienie miedzy msg do NPC (ms)
local SPELL_CD        = 1000  -- cooldown spelli (ms) - edytuj

-- Level wymagany po Super Fury zeby przejsc na Hellhoundy
local FURY_MIN_LEVEL = 700

-- ============================================================
-- TASKI - FAZA 300
-- ============================================================

local TASKS_300 = {
    [1]  = { monster = "super fury",          npcName = "Super Fury",          taskName = "Super Fury" },
    [2]  = { monster = "super hellhound",     npcName = "Super Hellhound",     taskName = "Super Hellhound",    reqLevel = FURY_MIN_LEVEL },
    [3]  = { monster = "old bog raider",      npcName = "Old Bog Raider",      taskName = "Old Bog Raider" },
    [4]  = { monster = "aladin",              npcName = "Aladin",              taskName = "Aladin" },
    [5]  = { monster = "swiateczny starzec",  npcName = "Swiateczny Starzec",  taskName = "Swiateczny Starzec" },
    [6]  = { monster = "christmas deer",      npcName = "Christmas Deer",      taskName = "Christmas Deer" },
    [7]  = { monster = "old sea serpent",     npcName = "Old Sea Serpent",     taskName = "Old Sea Serpent" },
    [8]  = { monster = "archaniol",           npcName = "Archaniol",           taskName = "Archaniol" },
    [9]  = { monster = "queen the rotes",     npcName = "Queen the Rotes",     taskName = "Queen the Rotes" },
    [10] = { monster = "martes 13",           npcName = "Martes 13",           taskName = "Martes 13" },
    [11] = { monster = "martes 16",           npcName = "Martes 16",           taskName = "Martes 16" },
    [12] = { monster = "cyrulik",             npcName = "Cyrulik",             taskName = "Cyrulik" },
    [13] = { monster = "piece of earth",      npcName = "Piece of Earth",      taskName = "Piece of Earth" },
}

-- ============================================================
-- TASKI - FAZA 750
-- ============================================================

local TASKS_750 = {
    [1]  = { monster = "arciere",             npcName = "Arciere",             taskName = "Arciere" },
    [2]  = { monster = "imbecile",            npcName = "Imbecile",            taskName = "Imbecile" },
    [3]  = { monster = "sarah",               npcName = "Sarah",               taskName = "Sarah" },
    [4]  = { monster = "jagoda",              npcName = "Jagoda",              taskName = "Jagoda" },
    [5]  = { monster = "the queen of dune",   npcName = "The Queen of Dune",   taskName = "The Queen of Dune" },
    [6]  = { monster = "crawler",             npcName = "Crawler",             taskName = "Crawler" },
    [7]  = { monster = "tempest",             npcName = "Tempest",             taskName = "Tempest" },
    [8]  = { monster = "poison scarab",       npcName = "Poison Scarab",       taskName = "Poison Scarab" },
    [9]  = { monster = "red arciere",         npcName = "Red Arciere",         taskName = "Red Arciere" },
    [10] = { monster = "the hunter",          npcName = "The Hunter",          taskName = "The Hunter" },
}

-- ============================================================
-- SYSTEM CZAROW (4 vocacje)
-- ============================================================

local SPELLS = {
    knight = {
        { minLevel = 650, spell = "holy shoot" },
        { minLevel = 150, spell = "sword dancing" },
    },
    paladin = {
        { minLevel = 650, spell = "holy shoot" },
        { minLevel = 150, spell = "exori beam" },
        { minLevel = 50,  spell = "exevo mas san" },
    },
    sorcerer = {
        { minLevel = 650, spell = "mega beam" },
        { minLevel = 150, spell = "utevo mega lux" },
        { minLevel = 55,  spell = "exevo gran mas vis" },
    },
    druid = {
        { minLevel = 650, spell = "mega beam" },
        { minLevel = 150, spell = "exana sound" },
        { minLevel = 60,  spell = "exevo gran mas frigo" },
    },
}

-- ============================================================
-- STORAGE (trwale dane miedzy sesjami)
-- ============================================================

if type(storage.mt2) ~= "table" then
    storage.mt2 = {
        kills300  = {},      -- liczniki killi faza 300
        kills750  = {},      -- liczniki killi faza 750
        phase     = "init",  -- init/leveling/tasks300/report300/tasks750/report750/done
        taskIdx   = 1,       -- aktualny indeks taska w fazie
        vocation  = "paladin",
        startSent = false,
        version   = SCRIPT_VERSION,
        lvlGrind  = false,   -- czy grinduje lvl po fury
    }
end

local S = storage.mt2

-- Init licznikow
for i = 1, #TASKS_300 do
    if S.kills300[i] == nil then S.kills300[i] = 0 end
end
for i = 1, #TASKS_750 do
    if S.kills750[i] == nil then S.kills750[i] = 0 end
end

-- ============================================================
-- AUTO-UPDATE Z GITHUB
-- ============================================================

local function checkGitHubVersion()
    if GITHUB_RAW_URL == "" then
        print("[MegaTask] GitHub URL nie ustawiony - pomijam update check")
        return
    end

    -- Probuj pobrac wersje z GitHub
    -- UWAGA: HTTP.get moze nie byc dostepne we wszystkich wersjach OTCv8
    -- Jesli nie dziala, zakomentuj ta sekcje
    if HTTP and HTTP.get then
        HTTP.get(GITHUB_RAW_URL, function(data, err)
            if err then
                print("[MegaTask] Nie mozna sprawdzic wersji GitHub: " .. tostring(err))
                return
            end
            -- Szukaj wersji w pliku
            local remoteVersion = data:match('SCRIPT_VERSION%s*=%s*"([^"]+)"')
            if remoteVersion and remoteVersion ~= SCRIPT_VERSION then
                print("[MegaTask] !!! NOWA WERSJA DOSTEPNA: " .. remoteVersion .. " (masz: " .. SCRIPT_VERSION .. ")")
                print("[MegaTask] !!! Pobierz nowa wersje z GitHub i wklej w Main > Edit")
                -- Mozna tez automatycznie zaladowac:
                -- Odkomentuj ponizej jesli chcesz auto-load
                -- loadstring(data)()
            else
                print("[MegaTask] Wersja aktualna: " .. SCRIPT_VERSION)
            end
        end)
    else
        print("[MegaTask] HTTP niedostepne - pomijam version check")
    end
end

-- ============================================================
-- KOMENDY STARTOWE
-- ============================================================

macro(3000, "Auto Start Cmds", function()
    if S.startSent then return end
    say("!bless")
    schedule(2000, function() say("!autoloot add:crystal coin") end)
    schedule(4000, function() say("!autoloot add:jagoda skin") end)
    schedule(6000, function() say("!autoloot add:violet skin") end)
    schedule(8000, function()
        S.startSent = true
        print("[MegaTask] Komendy startowe wyslane!")
    end)
end)

-- ============================================================
-- UI - PANEL BOTA
-- ============================================================

UI.Separator()
UI.Label("=== MEGA TASK SYSTEM v" .. SCRIPT_VERSION .. " ===")
UI.Separator()

-- --- VOCACJA ---
UI.Label("Vocacja:")
local vocLabel = UI.Label(">> " .. (S.vocation or "paladin"):upper())
vocLabel:setColor("#00FF00")

UI.Button("Knight", function()
    S.vocation = "knight"
    vocLabel:setText(">> KNIGHT")
    print("[MegaTask] Voc: Knight")
end)
UI.Button("Paladin", function()
    S.vocation = "paladin"
    vocLabel:setText(">> PALADIN")
    print("[MegaTask] Voc: Paladin")
end)
UI.Button("Sorcerer", function()
    S.vocation = "sorcerer"
    vocLabel:setText(">> SORCERER")
    print("[MegaTask] Voc: Sorcerer")
end)
UI.Button("Druid", function()
    S.vocation = "druid"
    vocLabel:setText(">> DRUID")
    print("[MegaTask] Voc: Druid")
end)

UI.Separator()

-- --- STATUS ---
local phaseLabel  = UI.Label("Faza: " .. (S.phase or "init"))
local taskLabel   = UI.Label("Task: -")
local killsLabel  = UI.Label("Kille: -")
local levelLabel  = UI.Label("Level: " .. level())
local grindLabel  = UI.Label("")

UI.Separator()

-- --- PRZYCISKI ---
UI.Button("Reset WSZYSTKO", function()
    for i = 1, #TASKS_300 do S.kills300[i] = 0 end
    for i = 1, #TASKS_750 do S.kills750[i] = 0 end
    S.phase = "init"
    S.taskIdx = 1
    S.startSent = false
    S.lvlGrind = false
    print("[MegaTask] PELNY RESET!")
end)

UI.Button("Reset aktywny task", function()
    if S.phase == "tasks300" and S.taskIdx <= #TASKS_300 then
        S.kills300[S.taskIdx] = 0
        print("[MegaTask] Reset: " .. TASKS_300[S.taskIdx].taskName)
    elseif S.phase == "tasks750" and S.taskIdx <= #TASKS_750 then
        S.kills750[S.taskIdx] = 0
        print("[MegaTask] Reset: " .. TASKS_750[S.taskIdx].taskName)
    end
end)

UI.Button("Pokaz postep (konsola)", function()
    print("========= TASKI 300 =========")
    for i, t in ipairs(TASKS_300) do
        local k = S.kills300[i] or 0
        local done = k >= KILL_BUFFER and "[DONE]" or ""
        print(string.format("  %d. %s: %d/%d %s", i, t.taskName, k, KILL_BUFFER, done))
    end
    print("========= TASKI 750 =========")
    for i, t in ipairs(TASKS_750) do
        local k = S.kills750[i] or 0
        local done = k >= KILL_BUFFER_750 and "[DONE]" or ""
        print(string.format("  %d. %s: %d/%d %s", i, t.taskName, k, KILL_BUFFER_750, done))
    end
end)

UI.Button("Wyslij !bless ponownie", function()
    S.startSent = false
end)

UI.Separator()

-- ============================================================
-- SYSTEM CZAROW - MACRO
-- ============================================================

local lastCast = 0

macro(200, "Auto Spells", function()
    local target = g_game.getAttackingCreature()
    if not target then return end
    if not target:isMonster() then return end

    local now = os.clock() * 1000
    if now - lastCast < SPELL_CD then return end

    local lvl = level()
    local voc = S.vocation or "paladin"
    local vocSpells = SPELLS[voc]
    if not vocSpells then return end

    for _, sp in ipairs(vocSpells) do
        if lvl >= sp.minLevel then
            say(sp.spell)
            lastCast = now
            return
        end
    end
end)

-- ============================================================
-- GLOWNA LOGIKA - DETEKCJA KILLI
-- ============================================================

local function getCurrentTaskInfo()
    if S.phase == "tasks300" then
        local t = TASKS_300[S.taskIdx]
        if t then return t, S.kills300, KILL_BUFFER, S.taskIdx end
    elseif S.phase == "tasks750" then
        local t = TASKS_750[S.taskIdx]
        if t then return t, S.kills750, KILL_BUFFER_750, S.taskIdx end
    end
    return nil
end

local function extractMonsterName(text)
    local textLow = text:lower()
    local name = nil

    -- "Loot of a super fury: ..."
    name = textLow:match("loot of an? (.-):")
    if not name then name = textLow:match("loot of (.-)%s*:") end

    -- "You killed a super fury."
    if not name then name = textLow:match("you killed an? (.-)%.") end
    if not name then name = textLow:match("you killed (.-)%.") end

    if name then return name:match("^%s*(.-)%s*$") end -- trim
    return nil
end

macro(1000, "Task System", function()
    -- puste macro - logika w onTextMessage i phase check
end)

onTextMessage(function(mode, text)
    -- Sprawdz czy system wlaczony
    -- (macro "Task System" musi byc ON)

    local task, killsTable, killTarget, idx = getCurrentTaskInfo()
    if not task then return end

    local monsterName = extractMonsterName(text)
    if not monsterName then return end

    -- Faza lvl grind po fury - licz wszystko ale nie przechodzraj dalej
    if S.lvlGrind then
        -- Nie liczymy, tylko grindujemy lvl
        return
    end

    -- Sprawdz czy mob pasuje do aktywnego taska
    if monsterName ~= task.monster then return end

    -- Zwieksz licznik
    killsTable[idx] = killsTable[idx] + 1
    local current = killsTable[idx]

    print(string.format("[MegaTask] %s: %d/%d", task.taskName, current, killTarget))

    -- Task zaliczony?
    if current >= killTarget then
        print(string.format("[MegaTask] >>> TASK DONE: %s <<<", task.taskName))

        -- Sprawdz czy to Super Fury i wymaga lvl 700
        if S.phase == "tasks300" and S.taskIdx == 1 then
            -- Super Fury skonczone - sprawdz level
            if level() < FURY_MIN_LEVEL then
                S.lvlGrind = true
                print(string.format("[MegaTask] Level %d/%d - grinduje dalej na Fury do lvl %d!",
                    level(), FURY_MIN_LEVEL, FURY_MIN_LEVEL))
                -- Zostaj na hunt_super_fury (nie przechodzisz dalej)
                return
            end
        end

        -- Przejdz do nastepnego taska lub do raportu
        if S.phase == "tasks300" then
            if S.taskIdx < #TASKS_300 then
                -- Jest nastepny task 300
                S.taskIdx = S.taskIdx + 1
                -- Sprawdz wymog levelu nastepnego taska
                local nextTask = TASKS_300[S.taskIdx]
                if nextTask.reqLevel and level() < nextTask.reqLevel then
                    S.lvlGrind = true
                    print(string.format("[MegaTask] Potrzebujesz lv %d! Grinduje dalej.", nextTask.reqLevel))
                    return
                end
                -- Idz do NPC wziac nastepny task
                print("[MegaTask] Nastepny task: " .. nextTask.taskName)
                CaveBot.gotoLabel("npc_take_" .. S.taskIdx)
            else
                -- Wszystkie 300-ki zrobione! Idz raportowac
                S.phase = "report300"
                print("[MegaTask] WSZYSTKIE TASKI 300 ZROBIONE! Ide raportowac!")
                CaveBot.gotoLabel("npc_report_all_300")
            end
        elseif S.phase == "tasks750" then
            if S.taskIdx < #TASKS_750 then
                S.taskIdx = S.taskIdx + 1
                print("[MegaTask] Nastepny task 750: " .. TASKS_750[S.taskIdx].taskName)
                CaveBot.gotoLabel("npc_take_750_" .. S.taskIdx)
            else
                S.phase = "done"
                print("[MegaTask] *** WSZYSTKIE TASKI ZALICZONE! GG! ***")
                CaveBot.gotoLabel("all_done")
            end
        end
    end
end)

-- ============================================================
-- PHASE CHECK - sprawdza level i faze co 5 sek
-- ============================================================

macro(5000, "Phase Check", function()
    local lvl = level()

    -- Aktualizuj UI
    levelLabel:setText("Level: " .. lvl)
    phaseLabel:setText("Faza: " .. S.phase)

    local task, killsTable, killTarget, idx = getCurrentTaskInfo()
    if task then
        local k = killsTable[idx] or 0
        taskLabel:setText("Task: " .. task.taskName)
        killsLabel:setText("Kille: " .. k .. "/" .. killTarget)
    else
        taskLabel:setText("Task: -")
        killsLabel:setText("Kille: -")
    end

    -- === INIT -> LEVELING ===
    if S.phase == "init" then
        S.phase = "leveling"
        if lvl < 75 then
            CaveBot.gotoLabel("hunt_rotworm")
        elseif lvl < 150 then
            CaveBot.gotoLabel("hunt_dragon")
        elseif lvl < 300 then
            CaveBot.gotoLabel("hunt_demon")
        else
            -- Juz ma 300+, przejdz do taskow
            S.phase = "tasks300"
            S.taskIdx = 1
            CaveBot.gotoLabel("npc_take_1")
        end
        return
    end

    -- === LEVELING ===
    if S.phase == "leveling" then
        if lvl >= 300 then
            S.phase = "tasks300"
            S.taskIdx = 1
            print("[MegaTask] Level 300 osiagniety! Zaczynam taski!")
            CaveBot.gotoLabel("NpcTaski")
            return
        end
        -- Sprawdz czy na dobrym respie
        if lvl >= 150 then
            grindLabel:setText("Grind: Demony (150-300)")
            -- CaveBot powinien byc na hunt_demon
        elseif lvl >= 75 then
            grindLabel:setText("Grind: Dragony (75-150)")
            -- Sprawdz czy trzeba przejsc z rotow na dragony
        else
            grindLabel:setText("Grind: Rotworms (8-75)")
        end
        return
    end

    -- === LVL GRIND (po Fury, przed Hellhound) ===
    if S.lvlGrind then
        grindLabel:setText(string.format("GRIND LVL: %d/%d", lvl, FURY_MIN_LEVEL))
        grindLabel:setColor("red")

        -- Sprawdz wymog levelu
        local neededLvl = FURY_MIN_LEVEL
        if S.phase == "tasks300" and S.taskIdx <= #TASKS_300 then
            local nextTask = TASKS_300[S.taskIdx]
            if nextTask and nextTask.reqLevel then
                neededLvl = nextTask.reqLevel
            end
        end

        if lvl >= neededLvl then
            S.lvlGrind = false
            grindLabel:setText("")
            print("[MegaTask] Level " .. lvl .. " osiagniety! Ide po nastepny task!")

            if S.phase == "tasks300" then
                -- Jesli jeszcze na Super Fury (task 1 done) -> idz do NPC po nastepny
                if S.taskIdx == 1 then
                    S.taskIdx = 2
                end
                CaveBot.gotoLabel("npc_take_" .. S.taskIdx)
            end
        end
        return
    end

    -- === LEVELING SWITCH (roty -> dragony -> demony) ===
    if S.phase == "leveling" then
        if lvl >= 150 and lvl < 300 then
            -- upewnij sie ze na demonach
        elseif lvl >= 75 and lvl < 150 then
            -- upewnij sie ze na dragonach
        end
    end
end)

-- ============================================================
-- LEVEL-UP DETECTION (zmiana respa przy levelowaniu)
-- ============================================================

onTextMessage(function(mode, text)
    if S.phase ~= "leveling" then return end

    -- Wykryj level up
    if text:find("You advanced") or text:find("advanced to") then
        local lvl = level()
        if lvl == 75 then
            print("[MegaTask] Level 75! Przechodzze na Dragony!")
            CaveBot.gotoLabel("RotEND")
        elseif lvl == 150 then
            print("[MegaTask] Level 150! Przechodzze na Demony!")
            -- Trzeba wyjsc z dragon respa
            -- Bot powinien dojsc do konca petli dragon i wtedy
            -- phase check przekieruje na demony
        end
    end
end)

-- Dodatkowe sprawdzenie levelu co 10 sek
macro(10000, "Level Switch Check", function()
    if S.phase ~= "leveling" then return end
    local lvl = level()

    if lvl >= 300 then
        S.phase = "tasks300"
        S.taskIdx = 1
        print("[MegaTask] Level 300! Zaczynam taski! Ide do NPC!")
        CaveBot.gotoLabel("NpcTaski")
    elseif lvl >= 150 then
        -- Powinien byc na demonach
        -- CaveBot.gotoLabel("hunt_demon") -- odkomentuj jesli nie przechodzi sam
    elseif lvl >= 75 then
        -- Powinien byc na dragonach
        -- CaveBot.gotoLabel("hunt_dragon") -- odkomentuj jesli nie przechodzi sam
    end
end)

-- ============================================================
-- NPC INTERACTION (CaveBot Extensions)
-- ============================================================

-- Extension: Bierze task u NPC
-- Uzycie w CaveBot: npcsay akcja
-- Ale lepiej zrobic jako Extension:

CaveBot.Extensions = CaveBot.Extensions or {}

-- Funkcja do brania taska (hi > nazwa > yes > nazwa > yes)
local function npcTakeTaskDialog(taskName)
    print("[NPC] Biore task: " .. taskName)
    NPC.say("hi")
    schedule(NPC_DELAY, function() NPC.say(taskName) end)
    schedule(NPC_DELAY * 2, function() NPC.say("yes") end)
    schedule(NPC_DELAY * 3, function() NPC.say(taskName) end)
    schedule(NPC_DELAY * 4, function() NPC.say("yes") end)
end

-- Funkcja do oddawania taska (hi > report > yes)
local function npcReportDialog()
    print("[NPC] Oddaje task (report)")
    NPC.say("hi")
    schedule(NPC_DELAY, function() NPC.say("report") end)
    schedule(NPC_DELAY * 2, function() NPC.say("yes") end)
end

-- ============================================================
-- CaveBot Extension: TAKE TASK (automatycznie bierze aktywny)
-- ============================================================

CaveBot.Extensions.autoTakeTask = {}
CaveBot.registerAction("autotake", "#00FF00", function(value, retries)
    if retries > 20 then return true end -- safety

    local taskIdx = tonumber(value) or S.taskIdx
    local taskList = nil
    local phase = S.phase

    if phase == "tasks300" or phase == "leveling" then
        taskList = TASKS_300
        if taskIdx > #taskList then return true end
    elseif phase == "tasks750" then
        taskList = TASKS_750
        if taskIdx > #taskList then return true end
    else
        return true
    end

    local task = taskList[taskIdx]
    if not task then return true end

    if retries == 0 then
        npcTakeTaskDialog(task.npcTaskName)
    end

    -- Czekaj na zakonczenie dialogu
    if retries < 8 then
        return "retry"
    end

    -- Dialog skonczony, idz na hunt
    if phase == "tasks300" then
        CaveBot.gotoLabel("hunt_" .. taskIdx)
    elseif phase == "tasks750" then
        CaveBot.gotoLabel("hunt_750_" .. taskIdx)
    end
    return true
end)

CaveBot.Extensions.autoTakeTask.setup = function()
    CaveBot.Editor.registerAction("autotake", "autotake", {
        value = "1",
        title = "Auto Take Task",
        description = "Nr taska do wzicia (lub auto)",
        multiline = false,
    })
end

-- ============================================================
-- CaveBot Extension: REPORT TASK
-- ============================================================

CaveBot.Extensions.autoReport = {}
CaveBot.registerAction("autoreport", "#FF6600", function(value, retries)
    if retries > 15 then return true end

    if retries == 0 then
        npcReportDialog()
    end

    if retries < 6 then
        return "retry"
    end

    return true
end)

CaveBot.Extensions.autoReport.setup = function()
    CaveBot.Editor.registerAction("autoreport", "autoreport", {
        value = "auto",
        title = "Auto Report Task",
        description = "Oddaje aktywny task",
        multiline = false,
    })
end

-- ============================================================
-- CaveBot Extension: REPORT ALL 300 + TAKE 750
-- ============================================================

-- Ta akcja raportuje WSZYSTKIE taski 300 po kolei
CaveBot.Extensions.reportAll300 = {}
CaveBot.registerAction("reportall300", "#FF0000", function(value, retries)
    if retries > 100 then return true end -- safety

    local reportIdx = tonumber(value) or 1

    -- Raportuj kazdy task z opoznieniem
    if retries == 0 then
        print("[MegaTask] Raportuje wszystkie taski 300...")
        -- Raportuj pierwszy
        npcReportDialog()
    end

    -- Nie potrzebujemy raportowac kazdego osobno
    -- na wiekszosci serwerow "report" oddaje aktywny task
    -- wiec robimy: hi > report > yes (powtorz 13 razy z delay)

    -- Na poczatku jeden report wystarczy bo server moze oddac wszystkie naraz
    -- Jesli nie - trzeba zrobic petle
    if retries < 6 then
        return "retry"
    end

    -- Po raporcie przejdz do fazy 750
    S.phase = "tasks750"
    S.taskIdx = 1
    print("[MegaTask] Raport done! Faza 750 aktywna!")
    return true
end)

CaveBot.Extensions.reportAll300.setup = function()
    CaveBot.Editor.registerAction("reportall300", "reportall300", {
        value = "1",
        title = "Report All 300",
        description = "Raportuje taski 300 i przechodzi do 750",
        multiline = false,
    })
end

-- ============================================================
-- INIT
-- ============================================================

print("================================================================")
print("  MEGA TASK SYSTEM v" .. SCRIPT_VERSION .. " ZALADOWANY!")
print("  Voc: " .. (S.vocation or "paladin"):upper())
print("  Faza: " .. S.phase)
print("  Spell CD: " .. SPELL_CD .. "ms")
print("================================================================")

-- Version check
checkGitHubVersion()

-- Pierwsza aktualizacja
schedule(2000, function()
    local task, killsTable, killTarget, idx = getCurrentTaskInfo()
    if task then
        print("[MegaTask] Aktywny: " .. task.taskName ..
              " (" .. (killsTable[idx] or 0) .. "/" .. killTarget .. ")")
    end
end)
