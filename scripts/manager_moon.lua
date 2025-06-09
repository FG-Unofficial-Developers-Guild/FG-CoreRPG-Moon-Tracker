--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
-- This array holds the string names for each moon phase.
local aMoonPhases = { -- String names for each moon phase
	'New Moon',
	'Evening Crescent',
	'First Quarter',
	'Waxing Gibbous',
	'Full Moon',
	'Waning Gibbous',
	'Last Quarter',
	'Morning Crescent',
}

local outputDate_old
local function outputDate_new(...)
	outputDate_old(...)

	local aMoons = getMoons()
	if aMoons then
		local nEpoch = DB.getValue('moons.epochday', 0)

		local nMonth = CalendarManager.getCurrentMonth()
		local nDay = CalendarManager.getCurrentDay()
		local days
		for i = 1, nMonth do
			if i == nMonth then
				days = nDay
			else
				days = CalendarManager.getDaysInMonth(i)
			end

			nEpoch = nEpoch + days
		end

		for _, moon in ipairs(aMoons) do
			local msg = { sender = '', font = 'chatfont', icon = 'portrait_gm_token', mode = 'story' }
			local sMoonName = DB.getValue(moon, 'name', '')
			local nPhase = calculatePhase(moon, nEpoch)
			local sPhaseName = getPhaseName(nPhase)
			msg.text = sMoonName .. "'s phase is " .. sPhaseName
			msg.icon = 'moonphase' .. tostring(nPhase)
			Comm.deliverChatMessage(msg)
		end
	end
end

---
--- This function gets the string name for the current moon phase.
---
function getPhaseName(nPhase)
	return aMoonPhases[nPhase]
end

---
--- This function is used to calculate the phases of the moon for every day in the current year.
---
function calculateEpochDay()
	-- This function is used to calculate how many days it has been from day 0 to the first day of the current year,
	-- which is used to track where the current moon phases are calculated from.
	-- nYear [number] (optional): The year to calculate the epoch for. Defaults to CalendarManager.getCurrentYear().
	-- nMonths [number] (optional): The number of months in the year. Defaults to CalendarManager.getMonthsInYear();
	function getEpochDay(nYear, nMonths)
		nYear = nYear or CalendarManager.getCurrentYear()
		nMonths = nMonths or CalendarManager.getMonthsInYear()

		local epoch = 0
		for nCurrentYear = 0, nYear - 1 do
			for nCurrentMonth = 1, nMonths do
				epoch = epoch + CalendarManager.getDaysInMonth(nCurrentMonth, nCurrentYear)
			end
		end
		return epoch
	end

	local nYear = CalendarManager.getCurrentYear()
	local nMonths = CalendarManager.getMonthsInYear()
	-- local nFirstDay = CalendarManager.getLunarDay(nYear, 1, 1);
	-- local nDaysInWeek = CalendarManager.getDaysInWeek();

	local epochyear = DB.getValue('moons.epochyear', 0)
	-- local epoch = DB.getValue("moons.epochday", 0);
	-- local aMoons = getMoons();

	if epochyear ~= nYear - 1 then
		local epoch = getEpochDay(nYear, nMonths)

		DB.setValue('moons.epochyear', 'number', nYear - 1)
		DB.setValue('moons.epochday', 'number', epoch)
	end

	-- for nCurrentMonth = 1, nMonths do
	-- for nCurrentDay = 1, CalendarManager.getDaysInMonth(nCurrentMonth) do
	-- epoch = epoch + 1;
	-- end
	-- end
end

---
--- This function gets an array filled with the moonlist database entries, sorted by period (ASC)
---
function getMoons()
	local tMoons = DB.getChildren('moons.moonlist')
	local aMoons = {}

	for _, v in pairs(tMoons) do
		table.insert(aMoons, v)
	end
	table.sort(aMoons, function(a, b)
		return DB.getChild(a, 'period').getValue() < DB.getChild(b, 'period').getValue()
	end)
	return aMoons
end

---
--- This function is used to sort two moon database nodes. It sorts first by period, then by name.
---
function sortMoons(a, b)
	local aPeriod = DB.getChild(a, 'period').getValue()
	local bPeriod = DB.getChild(b, 'period').getValue()
	if aPeriod == bPeriod then
		local aName = DB.getChild(a, 'name').getValue()
		local bName = DB.getChild(b, 'name').getValue()

		return aName > bName
	else
		return aPeriod > bPeriod
	end
end
---
--- This function calculates the current moon phase based on the epoch day provided
---
--- oMoon [object]: This is the database node for the moon who's phase is being calculated.
--- nEpoch [number]: This is the day (calculated from day 0) that the phase is being calculated for.
---
--- corrected by @Arnagus to apply full and new moon only on specific (or multiple) days and not equally to waning or waxing moon phases
---
function calculatePhase(oMoon, nEpoch)
	local cycle = DB.getChild(oMoon, 'period').getValue()
	local x = ((nEpoch - DB.getChild(oMoon, 'shift').getValue()) / cycle)
	local o = (DB.getChild(oMoon, 'duration').getValue() - 1) / 4
	local f = x - math.floor(x)
	local s = 1 / cycle
	--- calculations with normalized periods resulting in a single (or multiple with duration>1) day new/full moon and single day quarter moon
	if f < (0.00 + s + (o * s)) then
		--- A new moon
		return 1
	elseif f < (0.25 - s) then
		--- An evening crescent
		return 2
	elseif f < (0.25 + s) then
		--- A first quarter
		return 3
	elseif f < (0.50 - s - (o * s)) then
		--- A waxing gibbous
		return 4
	elseif f < (0.50 + s + (o * s)) then
		--- A full moon
		return 5
	elseif f < (0.75 - s) then
		--- A wanning gibbous
		return 6
	elseif f < (0.75 + s) then
		--- A last quarter
		return 7
	elseif f < (1.00 - s - (o * s)) then
		--- A morning cresent
		return 8
	else
		--- A new moon
		return 1
	end
	-- return math.floor(f*8) + 1;
end

function onInit()
	--- This function sets up the required database nodes for storing Moon data
	--- corrected by @mattekure to make moons public to players
	local function initializeDatabase()
		local nNode = DB.createNode('moons')
		DB.setPublic(nNode, true)
		DB.createNode('moons.epochday', 'number')
		DB.createNode('moons.epochyear', 'number')
		DB.createNode('moons.moonlist')
	end

	if Session.IsHost then
		initializeDatabase()
	end

	outputDate_old = CalendarManager.outputDate
	CalendarManager.outputDate = outputDate_new
end
