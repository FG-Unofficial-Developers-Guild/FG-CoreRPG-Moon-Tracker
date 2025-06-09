--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals onButtonPress

local function onMoonTrackerConfigurationClosed()
	window.parentcontrol.window.populateMoonPhaseDisplay()
end

function onButtonPress()
	local oNode = DB.findNode('moons.moonlist')
	if oNode then
		local oWindow = Interface.openWindow('moontracker_configuration', oNode.getNodeName())
		oWindow.registerCloseCallback(onMoonTrackerConfigurationClosed)
		if oWindow and oWindow.name then
			oWindow.name.setFocus()
		end
	end
end
