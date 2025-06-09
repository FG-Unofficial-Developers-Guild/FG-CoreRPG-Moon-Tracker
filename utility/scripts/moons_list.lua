--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals addEntry

function addEntry(oMoon, nEpoch)
	local oWindow = self.createWindow()
	local phase = MoonManager.calculatePhase(oMoon, nEpoch)
	local name = MoonManager.getPhaseName(phase)
	oWindow['name'].setValue(name)
	oWindow['moonname'].setValue(DB.getChild(oMoon, 'name').getValue() or '')
	oWindow['phaseicon'].setIcon('moonphase' .. tostring(phase))
	return oWindow
end
