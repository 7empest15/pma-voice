local wasProximityDisabledFromOverride = false
disableProximityCycle = false
RegisterCommand('setvoiceintent', function(source, args)
	if GetConvarInt('voice_allowSetIntent', 1) == 1 then
		local intent = args[1]
		if intent == 'speech' then
			MumbleSetAudioInputIntent(`speech`)
		elseif intent == 'music' then
			MumbleSetAudioInputIntent(`music`)
		end
		LocalPlayer.state:set('voiceIntent', intent, true)
	end
end)
TriggerEvent('chat:addSuggestion', '/setvoiceintent', 'Sets the players voice intent', {
	{
		name = "intent",
		help = "speech is default and enables noise suppression & high pass filter, music disables both of these."
	},
})

-- TODO: Better implementation of this?
RegisterCommand('vol', function(_, args)
	if not args[1] then return end
	setVolume(tonumber(args[1]))
end)
TriggerEvent('chat:addSuggestion', '/vol', 'Sets the radio/phone volume', {
	{ name = "volume", help = "A range between 1-100 on how loud you want them to be" },
})

exports('setAllowProximityCycleState', function(state)
	type_check({ state, "boolean" })
	disableProximityCycle = state
end)

function setProximityState(proximityRange, isCustom)
	local voiceModeData = Cfg.voiceModes[mode]
	MumbleSetTalkerProximity(proximityRange + 0.0)
	LocalPlayer.state:set('proximity', {
		index = mode,
		distance = proximityRange,
		mode = isCustom and "Custom" or voiceModeData[2],
	}, true)
	sendUIMessage({
		-- JS expects this value to be - 1, "custom" voice is on the last index
		voiceMode = isCustom and #Cfg.voiceModes or mode - 1
	})
end

exports("overrideProximityRange", function(range, disableCycle)
	type_check({ range, "number" })
	setProximityState(range, true)
	if disableCycle then
		disableProximityCycle = true
		wasProximityDisabledFromOverride = true
	end
end)

exports("clearProximityOverride", function()
	local voiceModeData = Cfg.voiceModes[mode]
	setProximityState(voiceModeData[1], false)
	if wasProximityDisabledFromOverride then
		disableProximityCycle = false
	end
end)

RegisterCommand('cycleproximity', function()
	-- Proximity is either disabled, or manually overwritten.
	if GetConvarInt('voice_enableProximityCycle', 1) ~= 1 or disableProximityCycle then return end
	local newMode = mode + 1

	-- If we're within the range of our voice modes, allow the increase, otherwise reset to the first state
	if newMode <= #Cfg.voiceModes then
		mode = newMode
	else
		mode = 1
	end

	setProximityState(Cfg.voiceModes[mode][1], false)
	TriggerEvent('pma-voice:setTalkingMode', mode)

	local range = Cfg.voiceModes[mode][1]
	if Cfg.showProximityRadius then
		ShowTalkRadius(range)
	end

end, false)

local PreviewMarker = {
    active = false,
    endTime = 0,
    radius = 0
}

function ShowTalkRadius(radius)
    if not radius then return end
	type_check({ radius, "number" })
    PreviewMarker.active = false
    Wait(100)
    PreviewMarker.radius = radius
    PreviewMarker.endTime = GetGameTimer() + 2500
    PreviewMarker.active = true
    
    local ped = PlayerPedId()
    CreateThread(function()
        while PreviewMarker.active and GetGameTimer() < PreviewMarker.endTime do
            local pos = GetEntityCoords(ped)
            DrawMarker(1,
                pos.x, pos.y, pos.z - 0.95,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                radius * 2.0, radius * 2.0, 0.15,
                255, 10, 10, 80,
                false,
                false,
                2,
                false, nil, nil, false
            )
            Wait(0)
        end
        PreviewMarker.active = false
    end)
end

if gameVersion == 'fivem' then
	RegisterKeyMapping('cycleproximity', 'Cycle Proximity', 'keyboard', GetConvar('voice_defaultCycle', 'F11'))
end
