--[[
  ================================================================
  Taski 300lv vip+svip
  vBot / OTClientV8 - MemsoriaOTS 8.6
  ================================================================
  
  LOGIKA:
  1. Levelowanie: roty(8-75) > dragony(75-150) > demony(150-300)
  2. Przy NPC: bierze WSZYSTKIE 13 taskow 300 NARAZ
  3. Hunt po kolei: fury > hellhound > bog raider > ... > piece of earth
  4. Po fury: grinduje dalej az do lv 700
  5. Po zakonczeniu 13 taskow: wraca do NPC > report > yes
  6. Bierze WSZYSTKIE 10 taskow 750 NARAZ
  7. Hunt po kolei: arciere > imbecile > ... > the hunter
  8. Report > done
  ================================================================
]]

local SCRIPT_VERSION = "2.2"

-- GitHub auto-update (ustaw swoj URL lub zostaw pusty)
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/staberro/staberro.github.io/main/memsoria300lvVIPsViP.lua"
-- ============================================================
-- KONFIGURACJA
-- ============================================================

local KILL_TARGET_300  = 320   -- 300 + zapas
local KILL_TARGET_750  = 770   -- 750 + zapas
local NPC_DELAY        = 1500
local SPELL_CD         = 1000  -- cooldown spelli (ms)
local FURY_MIN_LEVEL   = 700   -- min lvl po fury zeby isc dalej

-- ============================================================
-- TASKI
-- ============================================================

local TASKS_300 = {
    [1]  = { monster = "super fury",          taskName = "Super Fury",          reqLevel = nil },
    [2]  = { monster = "super hellhound",     taskName = "Super Hellhound",     reqLevel = FURY_MIN_LEVEL },
    [3]  = { monster = "old bog raider",      taskName = "Old Bog Raider" },
    [4]  = { monster = "aladin",              taskName = "Aladin" },
    [5]  = { monster = "swiateczny starzec",  taskName = "Swiateczny Starzec" },
    [6]  = { monster = "christmas deer",      taskName = "Christmas Deer" },
    [7]  = { monster = "old sea serpent",     taskName = "Old Sea Serpent" },
    [8]  = { monster = "archaniol",           taskName = "Archaniol" },
    [9]  = { monster = "queen the rotes",     taskName = "Queen the Rotes" },
    [10] = { monster = "martes 13",           taskName = "Martes 13" },
    [11] = { monster = "martes 16",           taskName = "Martes 16" },
    [12] = { monster = "cyrulik",             taskName = "Cyrulik" },
    [13] = { monster = "piece of earth",      taskName = "Piece of Earth" },
}

local TASKS_750 = {
    [1]  = { monster = "arciere",             taskName = "Arciere" },
    [2]  = { monster = "imbecile",            taskName = "Imbecile" },
    [3]  = { monster = "sarah",               taskName = "Sarah" },
    [4]  = { monster = "jagoda",              taskName = "Jagoda" },
    [5]  = { monster = "the queen of dune",   taskName = "The Queen of Dune" },
    [6]  = { monster = "crawler",             taskName = "Crawler" },
    [7]  = { monster = "tempest",             taskName = "Tempest" },
    [8]  = { monster = "poison scarab",       taskName = "Poison Scarab" },
    [9]  = { monster = "red arciere",         taskName = "Red Arciere" },
    [10] = { monster = "the hunter",          taskName = "The Hunter" },
}

-- ============================================================
-- CZARY (4 vocacje)
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
-- STORAGE
-- ============================================================

if type(storage.mt) ~= "table" then
    storage.mt = {
        kills300  = {},
        kills750  = {},
        phase     = "init",
        taskIdx   = 1,
        vocation  = "paladin",
        startSent = false,
    }
end

local S = storage.mt

for i = 1, #TASKS_300 do
    if S.kills300[i] == nil then S.kills300[i] = 0 end
end
for i = 1, #TASKS_750 do
    if S.kills750[i] == nil then S.kills750[i] = 0 end
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
        print("[MT] Komendy startowe wyslane!")
    end)
end)

-- ============================================================
-- UI
-- ============================================================

UI.Separator()
UI.Label("=== MEGA TASK v" .. SCRIPT_VERSION .. " ===")
UI.Separator()

-- Proiesja
UI.Label("Profesja:")
local vocLabel = UI.Label(">> " .. (S.vocation or "paladin"):upper())
vocLabel:setColor("#00FF00")

UI.Button("Knight", function()
    S.vocation = "knight"; vocLabel:setText(">> KNIGHT")
end)
UI.Button("Paladin", function()
    S.vocation = "paladin"; vocLabel:setText(">> PALADIN")
end)
UI.Button("Sorcerer", function()
    S.vocation = "sorcerer"; vocLabel:setText(">> SORCERER")
end)
UI.Button("Druid", function()
    S.vocation = "druid"; vocLabel:setText(">> DRUID")
end)

UI.Separator()

local phaseLabel = UI.Label("Faza: " .. (S.phase or "init"))
local taskLabel  = UI.Label("Task: -")
local killsLabel = UI.Label("Kille: -")
local lvlLabel   = UI.Label("Level: " .. level())

UI.Separator()

UI.Button("Reset WSZYSTKO", function()
    for i = 1, #TASKS_300 do S.kills300[i] = 0 end
    for i = 1, #TASKS_750 do S.kills750[i] = 0 end
    S.phase = "init"; S.taskIdx = 1; S.startSent = false
    print("[MT] PELNY RESET!")
end)

UI.Button("Reset aktywny task", function()
    if S.phase == "tasks300" and TASKS_300[S.taskIdx] then
        S.kills300[S.taskIdx] = 0
        print("[MT] Reset: " .. TASKS_300[S.taskIdx].taskName)
    elseif S.phase == "tasks750" and TASKS_750[S.taskIdx] then
        S.kills750[S.taskIdx] = 0
        print("[MT] Reset: " .. TASKS_750[S.taskIdx].taskName)
    end
end)

UI.Button("Pokaz postep", function()
    print("========= TASKI 300 =========")
    for i, t in ipairs(TASKS_300) do
        local k = S.kills300[i] or 0
        local st = k >= KILL_TARGET_300 and "DONE" or (i == S.taskIdx and S.phase == "tasks300" and "<<< AKTYWNY" or "")
        print(string.format("  %2d. %-22s %d/%d %s", i, t.taskName, k, KILL_TARGET_300, st))
    end
    print("========= TASKI 750 =========")
    for i, t in ipairs(TASKS_750) do
        local k = S.kills750[i] or 0
        local st = k >= KILL_TARGET_750 and "DONE" or (i == S.taskIdx and S.phase == "tasks750" and "<<< AKTYWNY" or "")
        print(string.format("  %2d. %-22s %d/%d %s", i, t.taskName, k, KILL_TARGET_750, st))
    end
end)

UI.Button("Wyslij !bless", function()
    S.startSent = false
end)

UI.Separator()

-- ============================================================
-- AUTO SPELE
-- ============================================================

local lastCast = 0

macro(200, "Auto Spells", function()
    local target = g_game.getAttackingCreature()
    if not target then return end
    if not target:isMonster() then return end

    local now = os.clock() * 1000
    if now - lastCast < SPELL_CD then return end

    local vocSpells = SPELLS[S.vocation or "paladin"]
    if not vocSpells then return end

    local lvl = level()
    for _, sp in ipairs(vocSpells) do
        if lvl >= sp.minLevel then
            say(sp.spell)
            lastCast = now
            return
        end
    end
end)

-- ============================================================
-- POMOCNICZE GOWNO
-- ============================================================

local function extractMonster(text)
    local t = text:lower()
    local name = t:match("loot of an? (.-):")
              or t:match("loot of (.-)%s*:")
              or t:match("you killed an? (.-)%.")
              or t:match("you killed (.-)%.")
    if name then return name:match("^%s*(.-)%s*$") end
    return nil
end

-- ============================================================
-- GLOWNE MACRO - TASK SYSTEM CHUJ WIE
-- ============================================================

macro(1000, "Task System", function()
    -- puste - logika w onTextMessage czy cos
end)

-- ============================================================
-- DETEKCJA KILLI CHYBa XD
-- ============================================================

onTextMessage(function(mode, text)
    local monsterName = extractMonster(text)
    if not monsterName then return end

    -- === FAZA TASKi 300vOL ===
    if S.phase == "tasks300" then
        local task = TASKS_300[S.taskIdx]
        if not task then return end

        if monsterName ~= task.monster then return end

        S.kills300[S.taskIdx] = S.kills300[S.taskIdx] + 1
        local k = S.kills300[S.taskIdx]

        print(string.format("[MT] %s: %d/%d", task.taskName, k, KILL_TARGET_300))

        if k >= KILL_TARGET_300 then
            print("[MT] >>> DONE: " .. task.taskName .. " <<<")

            -- Sprawdz wymog levelu NASTEPNEGO taska cwelu
            local nextIdx = S.taskIdx + 1
            if nextIdx <= #TASKS_300 then
                local nextTask = TASKS_300[nextIdx]
                if nextTask.reqLevel and level() < nextTask.reqLevel then
                    -- Trzeba grindowac lvl cipo (np. po fury -> lvl 700)
                    S.phase = "lvlgrind"
                    print(string.format("[MT] Potrzebujesz lv %d (masz %d). Grinduje na aktualnym respie!",
                        nextTask.reqLevel, level()))
                    -- Zostaje na obecnym hunt - NIE przechodzi dalej
                    -- gotolabel w CaveBot dalej krecikolko na hunt_X
                    return
                end
                -- Nastepny task
                S.taskIdx = nextIdx
                print("[MT] Nastepny: " .. TASKS_300[nextIdx].taskName)
                CaveBot.gotoLabel("back_to_npc_" .. (nextIdx - 1))
            else
                -- Wszystkie 300-ki done! Idz raportowac
                S.phase = "report300"
                print("[MT] === WSZYSTKIE TASKI 300 DONE! Ide raportowac! ===")
                CaveBot.gotoLabel("go_report_300")
            end
        end
        return
    end

    -- === FAZA LVL GRINDa jak kas z memsori przez crisa (po fury, czeka na lv 700) ===
    if S.phase == "lvlgrind" then
        -- Nie liczymy killi, tylko grindujemy
        -- Phase check macro sprawdza lvl
        return
    end

    -- === FAZA TASKS 750 ===
    if S.phase == "tasks750" then
        local task = TASKS_750[S.taskIdx]
        if not task then return end

        if monsterName ~= task.monster then return end

        S.kills750[S.taskIdx] = S.kills750[S.taskIdx] + 1
        local k = S.kills750[S.taskIdx]

        print(string.format("[MT] %s: %d/%d", task.taskName, k, KILL_TARGET_750))

        if k >= KILL_TARGET_750 then
            print("[MT] >>> DONE: " .. task.taskName .. " <<<")

            local nextIdx = S.taskIdx + 1
            if nextIdx <= #TASKS_750 then
                S.taskIdx = nextIdx
                print("[MT] Nastepny 750: " .. TASKS_750[nextIdx].taskName)
                CaveBot.gotoLabel("back_750_" .. (nextIdx - 1))
            else
                S.phase = "report750"
                print("[MT] === WSZYSTKIE TASKI 750 DONE! Ide raportowac! ===")
                CaveBot.gotoLabel("go_report_750")
            end
        end
        return
    end
end)

-- ============================================================
-- PHASE CHECK (co 5 sek) [chyba co 5] xD
-- ============================================================

macro(5000, "Phase Check", function()
    local lvl = level()

    -- UI update
    lvlLabel:setText("Level: " .. lvl)
    phaseLabel:setText("Faza: " .. S.phase)

    if S.phase == "tasks300" and TASKS_300[S.taskIdx] then
        local t = TASKS_300[S.taskIdx]
        taskLabel:setText("Task: " .. t.taskName)
        killsLabel:setText("Kille: " .. S.kills300[S.taskIdx] .. "/" .. KILL_TARGET_300)
    elseif S.phase == "tasks750" and TASKS_750[S.taskIdx] then
        local t = TASKS_750[S.taskIdx]
        taskLabel:setText("Task: " .. t.taskName)
        killsLabel:setText("Kille: " .. S.kills750[S.taskIdx] .. "/" .. KILL_TARGET_750)
    elseif S.phase == "lvlgrind" then
        local nextTask = TASKS_300[S.taskIdx + 1]
        local reqLvl = nextTask and nextTask.reqLevel or FURY_MIN_LEVEL
        taskLabel:setText("GRIND LVL: " .. lvl .. "/" .. reqLvl)
        taskLabel:setColor("red")
        killsLabel:setText("Grinduje do wymaganego levelu")
    else
        taskLabel:setText("Task: -")
        killsLabel:setText("Kille: -")
    end

    -- === INIT O ILE MOZNA TO TAK NAZWAC XD===
    if S.phase == "init" then
        S.phase = "leveling"
        if lvl < 75 then
            CaveBot.gotoLabel("hunt_rotworm")
        elseif lvl < 150 then
            CaveBot.gotoLabel("hunt_dragon")
        elseif lvl < 300 then
            CaveBot.gotoLabel("hunt_demon")
        else
            S.phase = "tasks300"
            S.taskIdx = 1
            CaveBot.gotoLabel("NpcTaski")
        end
        return
    end

    -- === LEVELING ===
    if S.phase == "leveling" then
        if lvl >= 300 then
            S.phase = "tasks300"
            S.taskIdx = 1
            print("[MT] Level 300! Ide po taski!")
            CaveBot.gotoLabel("NpcTaski")
        end
        return
    end

    -- === LVL GRINDing (np. po fury, czeka na 700) ===
    if S.phase == "lvlgrind" then
        local nextIdx = S.taskIdx + 1
        local nextTask = TASKS_300[nextIdx]
        local reqLvl = nextTask and nextTask.reqLevel or FURY_MIN_LEVEL

        if lvl >= reqLvl then
            S.phase = "tasks300"
            S.taskIdx = nextIdx
            print("[MT] Level " .. lvl .. " osiagniety! Ide na: " .. TASKS_300[nextIdx].taskName)
            CaveBot.gotoLabel("back_to_npc_" .. S.taskIdx - 1)
        end
        return
    end

    -- === REPORT 300 -> TASKS 750 ===
    if S.phase == "report300" then
        -- CaveBot jest na npc_report_all_300 i wykonuje npcsay
        -- Po zakonczeniu dialogu NPC, CaveBot przechodzi dalej
        -- do npc_take_all_750 (jest nastepny label w waypoints)
        -- Ustawiamy faze na tasks750
        -- Niespimy lecymy
        S.phase = "tasks750"
        S.taskIdx = 1
        print("[MT] Faza 750 aktywna!")
        return
    end

    -- === REPORT 750 -> DONE ===
    if S.phase == "report750" then
        S.phase = "done"
        print("[MT] *** WSZYSTKO ZROBIONE! GG! ***")
        return
    end
end)

-- ============================================================
-- LEVEL-UP SWITCH (roty -> dragony -> demony)
-- ============================================================

onTextMessage(function(mode, text)
    if S.phase ~= "leveling" then return end
    if not (text:find("You advanced") or text:find("advanced to")) then return end

    local lvl = level()
    if lvl == 75 then
        print("[MT] Lv 75! Przechodzze na Dragony!")
        CaveBot.gotoLabel("RotEND")
    elseif lvl == 150 then
        print("[MT] Lv 150! Przechodzze na Demony!")
        -- Trzeba dojsc do konca petli dragon, potem wyjsc
        -- Alternatywnie: CaveBot.gotoLabel("hunt_demon")
    elseif lvl >= 300 then
        S.phase = "tasks300"
        S.taskIdx = 1
        print("[MT] Lv 300! Ide po taski!")
        CaveBot.gotoLabel("NpcTaski")
    end
end)

-- Backup check co 15 sek (na wypadek gdyby level-up msg nie zadzialalal)
macro(15000, "Level Backup Check", function()
    if S.phase ~= "leveling" then return end
    local lvl = level()
    if lvl >= 300 then
        S.phase = "tasks300"
        S.taskIdx = 1
        CaveBot.gotoLabel("NpcTaski")
    end
end)

-- ============================================================
-- GITHUB VERSION CHECK MAM NADZIEJE ZE DZIALA XD
-- ============================================================

local function checkUpdate()
    if GITHUB_RAW_URL == "" then return end
    if HTTP and HTTP.get then
        HTTP.get(GITHUB_RAW_URL, function(data, err)
            if err then return end
            local rv = data:match('SCRIPT_VERSION%s*=%s*"([^"]+)"')
            if rv and rv ~= SCRIPT_VERSION then
                print("[MT] !!! NOWA WERSJA: " .. rv .. " (masz: " .. SCRIPT_VERSION .. ")")
            else
                print("[MT] Wersja aktualna: " .. SCRIPT_VERSION)
            end
        end)
    end
end

-- ============================================================
-- INIT
-- ============================================================

print("================================================================")
print("  MEGA TASK SYSTEM v" .. SCRIPT_VERSION)
print("  Voc: " .. (S.vocation or "paladin"):upper())
print("  Faza: " .. S.phase .. " | Task idx: " .. S.taskIdx)
print("  Spell CD: " .. SPELL_CD .. "ms (zmien na gorze)")
print("================================================================")

checkUpdate()
