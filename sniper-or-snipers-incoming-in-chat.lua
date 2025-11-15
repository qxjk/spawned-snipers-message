SniperSpawnNotifier = SniperSpawnNotifier or { alive = 0, last_announce = -100, delay = 0.25, next_scan = 0 }
local SSN = SniperSpawnNotifier

local function msg(text)
    if managers.chat then
        managers.chat:_receive_message(1, "WARNING", text, Color.red)
    elseif managers.hud then
        managers.hud:show_hint({ text = text })
    end
end

function SSN:reset()
    self.alive, self.last_announce, self.next_scan = 0, -100, 0
end

function SSN:announce()
    local game = TimerManager and TimerManager:game()
    if not game then return end
    local t = game:time()
    if t < self.last_announce + self.delay then return end
    self.last_announce = t
    msg(self.alive <= 1 and "SNIPER INCOMING!" or "SNIPERS INCOMING!")
end

local function is_sniper_unit(unit)
    if not alive(unit) then
        return false
    end
    local base = unit:base()
    if not base then
        return false
    end
    return base.has_tag and base:has_tag("sniper") or false
end

function SSN:scan()
    local game = TimerManager and TimerManager:game()
    if not game then return end

    local t = game:time()
    if t < self.next_scan then return end
    self.next_scan = t + 0.25

    if not Global.game_settings or not Global.game_settings.level_id then return end

    local em = managers.enemy
    if not em then return end

    local all = em:all_enemies()
    if not all then return end

    local count = 0
    for _, data in pairs(all) do
        if is_sniper_unit(data.unit) then
            count = count + 1
        end
    end

    if count > self.alive then
        self.alive = count
        self:announce()
    else
        self.alive = count
    end
end

if RequiredScript == "lib/setups/gamesetup" then
    Hooks:PostHook(GameSetup, "init_game", "GameSetupInitGameReset", function()
        SSN:reset()
    end)

    Hooks:PostHook(GameSetup, "update", "GameSetupUpdateScan", function()
        SSN:scan()
    end)
end
