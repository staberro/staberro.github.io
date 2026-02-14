--[[
  ================================================================
  Taski 300lv vip+svip
  vBot / OTClientV8 - MemsoriaOTS 8.6
  ================================================================
]]


local SCRIPT_VERSION = "2.1.5"

-- GitHub auto-update LUA
local GITHUB_RAW_URL  = "https://raw.githubusercontent.com/staberro/staberro.github.io/main/memsoria300lvVIPsViP.lua"
local LOCAL_SCRIPT_PATH = "/bot/memsoria/memsoria300lvVIPsViP.lua"

--[[
  ================================================================
  AUTO-UPDATE WPT (WAYPOINTY) - INSTRUKCJA
  ================================================================
  1) Pliki WPT wrzucasz do repozytorium GitHub do folderu:
       /WPT/nazwa.cfg
     RAW np.:
       https://raw.githubusercontent.com/staberro/staberro.github.io/main/WPT/fury.cfg

  2) Lokalnie:
       C:\Users\panwo\AppData\Roaming\OTClientV8\otclientv8\bot\Amcia\cavebot_configs\nazwa.cfg
     w skrypcie (dla tego profilu):
       /bot/memsoria/cavebot_configs/nazwa.cfg

  3) Zeby WPT byl pobierany/aktualizowany:
     - dodajesz wpis do WPT_FILES.

  4) Przyklad: taskiVIPsVIP (JUZ DODANY):
     - GitHub:  WPT/taskiVIPsVIP.cfg
     - Lokalnie: cavebot_configs/taskiVIPsVIP.cfg
  ================================================================
]]

local WPT_FILES = {
    taskiVIPsVIP = {
        url  = "https://raw.githubusercontent.com/staberro/staberro.github.io/main/WPT/taskiVIPsVIP.cfg",
        path = "/bot/memsoria/cavebot_configs/taskiVIPsVIP.cfg"
    },
}


-- ============================================================
-- KONFIGURACJA
-- ============================================================

local KILL_TARGET_300  = 320
local KILL_TARGET_750  = 770
local NPC_DELAY        = 1500
local SPELL_CD         = 1000
local FURY_MIN_LEVEL   = 700


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
-- SPELLS
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
-- START COMMANDS
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
    S.phase = "init"
    S.taskIdx = 1
    S.startSent = false
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
-- AUTO SPELLS
-- ============================================================

local lastCast = 0

local autoSpellsMacro = macro(200, "Auto Spells", function()
    local target = g_game.getAttackingCreature()
    if not target or not target:isMonster() then return end

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
-- TASK SYSTEM / PHASE / BACKUP MACROS
-- ============================================================

local taskSystemMacro = macro(1000, "Task System", function()
    -- logika w onTextMessage
end)

local phaseCheckMacro = macro(5000, "Phase Check", function()
    local lvl = level()

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

    if S.phase == "init" then
        S.phase = "leveling"
        if lvl < 75 then
            print("[MT] Init: Lv < 75 -> hunt_rotworm")
            CaveBot.gotoLabel("hunt_rotworm")
        elseif lvl >= 75 and lvl < 150 then
            print("[MT] Init: Lv 75-149 -> hunt_dragon")
            CaveBot.gotoLabel("hunt_dragon")
        elseif lvl >= 150 and lvl < 300 then
            print("[MT] Init: Lv 150-299 -> hunt_demon")
            CaveBot.gotoLabel("hunt_demon")
        else
            S.phase = "tasks300"
            S.taskIdx = 1
            print("[MT] Init: Lv 300+ -> NpcTaski")
            CaveBot.gotoLabel("NpcTaski")
        end
        return
    end

    if S.phase == "leveling" then
        -- backup dla levelow 75+ (wymusza przelaczenie labela)
        if lvl >= 300 then
            S.phase = "tasks300"
            S.taskIdx = 1
            print("[MT] Backup: Lv 300! Ide po taski!")
            CaveBot.gotoLabel("NpcTaski")
        elseif lvl >= 150 then
            print("[MT] Backup: Lv " .. lvl .. " - zmieniam na hunt_demon!")
            CaveBot.gotoLabel("hunt_demon")
        elseif lvl >= 75 then
            print("[MT] Backup: Lv " .. lvl .. " - zmieniam na hunt_dragon!")
            CaveBot.gotoLabel("hunt_dragon")
        end
        return
    end

    if S.phase == "lvlgrind" then
        local nextIdx = S.taskIdx + 1
        local nextTask = TASKS_300[nextIdx]
        local reqLvl = nextTask and nextTask.reqLevel or FURY_MIN_LEVEL

        if lvl >= reqLvl then
            S.phase = "tasks300"
            S.taskIdx = nextIdx
            print("[MT] Level " .. lvl .. " osiagniety! Ide na: " .. TASKS_300[nextIdx].taskName)
            CaveBot.gotoLabel("back_to_npc_" .. (S.taskIdx - 1))
        end
        return
    end

    if S.phase == "report300" then
        S.phase = "tasks750"
        S.taskIdx = 1
        print("[MT] Faza 750 aktywna!")
        return
    end

    if S.phase == "report750" then
        S.phase = "done"
        print("[MT] *** WSZYSTKIE TASKI 750 DONE! GG! ***")
        return
    end
end)

local lvlBackupMacro = macro(15000, "Level Backup Check", function()
    if S.phase ~= "leveling" then return end
    local lvl = level()
    if lvl >= 300 then
        S.phase = "tasks300"
        S.taskIdx = 1
        CaveBot.gotoLabel("NpcTaski")
    end
end)


-- ============================================================
-- HELPERS
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
-- KILL DETECTION
-- ============================================================

onTextMessage(function(mode, text)
    local monsterName = extractMonster(text)
    if not monsterName then return end

    if S.phase == "tasks300" then
        local task = TASKS_300[S.taskIdx]
        if not task or monsterName ~= task.monster then return end

        S.kills300[S.taskIdx] = S.kills300[S.taskIdx] + 1
        local k = S.kills300[S.taskIdx]

        print(string.format("[MT] %s: %d/%d", task.taskName, k, KILL_TARGET_300))

        if k >= KILL_TARGET_300 then
            print("[MT] >>> DONE: " .. task.taskName .. " <<<")

            local nextIdx = S.taskIdx + 1
            if nextIdx <= #TASKS_300 then
                local nextTask = TASKS_300[nextIdx]
                if nextTask.reqLevel and level() < nextTask.reqLevel then
                    S.phase = "lvlgrind"
                    print(string.format("[MT] Potrzebujesz lv %d (masz %d). Grinduje na aktualnym respie!",
                        nextTask.reqLevel, level()))
                    return
                end
                S.taskIdx = nextIdx
                print("[MT] Nastepny: " .. TASKS_300[nextIdx].taskName)
                CaveBot.gotoLabel("back_to_npc_" .. (nextIdx - 1))
            else
                S.phase = "report300"
                print("[MT] === WSZYSTKIE TASKI 300 DONE! Ide raportowac! ===")
                CaveBot.gotoLabel("go_report_300")
            end
        end
        return
    end

    if S.phase == "lvlgrind" then
        return
    end

    if S.phase == "tasks750" then
        local task = TASKS_750[S.taskIdx]
        if not task or monsterName ~= task.monster then return end

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
-- LEVEL-UP SWITCH (tylko dla realtime lvlupow)
-- ============================================================

onTextMessage(function(mode, text)
    if S.phase ~= "leveling" then return end
    if not (text:find("You advanced") or text:find("advanced to")) then return end

    local lvl = level()

    if lvl >= 300 then
        S.phase = "tasks300"
        S.taskIdx = 1
        print("[MT] LvlUp: Lv " .. lvl .. "! Ide po taski!")
        CaveBot.gotoLabel("NpcTaski")
    elseif lvl >= 150 then
        print("[MT] LvlUp: Lv " .. lvl .. "! Przechodze na hunt_demon!")
        CaveBot.gotoLabel("hunt_demon")
    elseif lvl >= 75 then
        print("[MT] LvlUp: Lv " .. lvl .. "! Przechodze na hunt_dragon!")
        CaveBot.gotoLabel("hunt_dragon")
    end
end)


-- ============================================================
-- RESTART MESSAGE
-- ============================================================

local function showRestartInfo()
    modules.game_textmessage.displayGameMessage(
        "[MEGA TASK] Skrypt zaktualizowany - zrestartuj klienta/bota, aby wczytac nowa wersje."
    )
end


-- ============================================================
-- AUTO-UPDATE LUA + WPT
-- ============================================================

local function updateAllWpt()
    if not (HTTP and HTTP.get) then
        print("[MT] Brak HTTP.get - WPT update wylaczony.")
        return
    end

    for name, info in pairs(WPT_FILES) do
        if info.url ~= "" and info.path ~= "" then
            HTTP.get(info.url, function(data, err)
                if err or not data or data == "" then
                    print("[MT] WPT '" .. name .. "' blad pobierania: " .. tostring(err))
                    return
                end
                local ok, errMsg = pcall(function()
                    g_resources.writeFileContents(info.path, data)
                end)
                if not ok then
                    print("[MT] WPT '" .. name .. "' blad zapisu: " .. tostring(errMsg))
                    return
                end
                print("[MT] WPT '" .. name .. "' zaktualizowany.")
            end)
        end
    end
end

local function checkUpdate()
    if GITHUB_RAW_URL == "" then
        updateAllWpt()
        return
    end
    if not (HTTP and HTTP.get) then
        print("[MT] Brak HTTP.get - auto-update wylaczony.")
        return
    end

    HTTP.get(GITHUB_RAW_URL, function(data, err)
        if err or not data or data == "" then
            print("[MT] Blad pobierania z GitHuba: " .. tostring(err))
            return
        end

        local rv = data:match('SCRIPT_VERSION%s*=%s*"([^"]+)"')
        if not rv then
            print("[MT] Nie znaleziono SCRIPT_VERSION w pliku z GitHuba.")
            return
        end

        if rv == SCRIPT_VERSION then
            print("[MT] Wersja aktualna: " .. SCRIPT_VERSION)
            updateAllWpt()
            return
        end

        print("[MT] Znaleziono nowa wersje: " .. rv .. " (masz: " .. SCRIPT_VERSION .. ")")
        print("[MT] Probuje zapisac nowy skrypt do: " .. LOCAL_SCRIPT_PATH)

        local ok, errMsg = pcall(function()
            g_resources.writeFileContents(LOCAL_SCRIPT_PATH, data)
        end)

        if not ok then
            print("[MT] BLAD zapisu auto-update: " .. tostring(errMsg))
            return
        end

        print("[MT] Skrypt zaktualizowany do wersji " .. rv .. ". Zrestartuj klienta/bota, aby wczytac nowy plik.")
        showRestartInfo()
        updateAllWpt()
    end)
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
