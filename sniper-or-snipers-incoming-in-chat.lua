SniperSpawnNotifier = SniperSpawnNotifier or { alive = 0, last_announce = -100, delay = 8 }
local SSN = SniperSpawnNotifier

local function msg(text)
    if managers.chat then
        managers.chat:_receive_message(1, "WARNING", text, Color.red)
    elseif managers.hud then
        managers.hud:show_hint({text = text})
    end
end

function SSN:reset()
    self.alive, self.last_announce = 0, -100
end

function SSN:announce()
    local g = TimerManager and TimerManager:game()
    if not g then return end
    local t = g:time()
    if t < self.last_announce + self.delay then return end
    self.last_announce = t
    msg(self.alive <= 1 and "SNIPER INCOMING!" or "SNIPERS INCOMING!")
end

local function reg(unit)
    SSN.alive = SSN.alive + 1
    local cd = unit:character_damage()
    if cd and cd.add_listener then
        cd:add_listener("SniperSpawnNotifier_" .. tostring(unit:key()), "death", function()
            if SSN.alive > 0 then
                SSN.alive = SSN.alive - 1
            end
        end)
    end
    SSN:announce()
end

if RequiredScript == "lib/units/enemies/cop/copbase" then
    Hooks:PostHook(CopBase, "post_init", "SniperSpawnNotifier_CopBasePostInit", function(self)
        local s = game_state_machine and game_state_machine:current_state_name()
        if not s or not s:find("ingame") then return end
        if self.has_tag and self:has_tag("sniper") and alive(self._unit) then
            reg(self._unit)
        end
    end)
elseif RequiredScript == "lib/setups/gamesetup" then
    Hooks:PostHook(GameSetup, "init_game", "SniperSpawnNotifier_ResetOnInitGame", function()
        SSN:reset()
    end)
end
