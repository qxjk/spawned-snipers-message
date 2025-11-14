_G.SniperSpawnNotifier = _G.SniperSpawnNotifier or {}
local Notifier = _G.SniperSpawnNotifier

Notifier._alive = Notifier._alive or 0
Notifier._last_announce_t = Notifier._last_announce_t or -100
Notifier._delay = 8

function Notifier:reset()
    self._alive = 0
    self._last_announce_t = -100
end

local function send_sniper_message(text)
    if managers.chat and tweak_data and tweak_data.system_chat_color then
        managers.chat:_receive_message(1, "System", text, tweak_data.system_chat_color)
    elseif managers.hud then
        managers.hud:show_hint({ text = text })
    end
end

function Notifier:announce()
    if not TimerManager or not TimerManager:game() then
        return
    end
    local t = TimerManager:game():time()
    if t < (self._last_announce_t + self._delay) then
        return
    end
    self._last_announce_t = t
    local text
    if self._alive <= 1 then
        text = "SNIPER INCOMING!"
    else
        text = "SNIPERS INCOMING!"
    end
    send_sniper_message(text)
end

function Notifier:on_sniper_death(unit_key, unit, damage_info)
    if self._alive and self._alive > 0 then
        self._alive = self._alive - 1
    end
end

function Notifier:register_sniper(unit)
    self._alive = (self._alive or 0) + 1
    local cd = unit:character_damage()
    if cd and cd.add_listener then
        local key = "SniperSpawnNotifier_" .. tostring(unit:key())
        cd:add_listener(key, "death", callback(self, self, "on_sniper_death", unit:key()))
    end
    self:announce()
end

if RequiredScript == "lib/units/enemies/cop/copbase" then
    Hooks:PostHook(CopBase, "post_init", "SniperSpawnNotifier_CopBasePostInit", function(self, ...)
        if not game_state_machine or not game_state_machine:current_state_name() then
            return
        end
        local state = game_state_machine:current_state_name()
        if type(state) ~= "string" or not state:find("ingame") then
            return
        end
        if self.has_tag and self:has_tag("sniper") and alive(self._unit) then
            Notifier:register_sniper(self._unit)
        end
    end)
elseif RequiredScript == "lib/setups/gamesetup" then
    Hooks:PostHook(GameSetup, "init_game", "SniperSpawnNotifier_ResetOnInitGame", function(self, ...)
        Notifier:reset()
    end)
end
