--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals ColorManager.COLOR_CALENDAR_HOLIDAY ColorManager.COLOR_PRIMARY_FOREGROUND
if ColorManager and not ColorManager.COLOR_CALENDAR_HOLIDAY then
	ColorManager.COLOR_CALENDAR_HOLIDAY = "5A1E33" -- Replaceable Color: Calendar Background
end

-- luacheck: globals onEventsChanged buildEvents onDateChanged onYearChanged onCalendarChanged updateDisplay
-- luacheck: globals setSelectedDate onSetButtonPressed addLogEntryToSelected addLogEntry removeLogEntry
-- luacheck: globals list sub_buttons sub_date

local aEvents = {}
local nSelMonth = 0
local nSelDay = 0

function onInit()
	if super and super.onInit then
		super.onInit()
	end

	nSelMonth = DB.getValue("calendar.current.month", 0)
	nSelDay = DB.getValue("calendar.current.day", 0)

	DB.addHandler("calendar.log", "onChildUpdate", self.onEventsChanged)
	DB.addHandler("calendar.current.day", "onUpdate", self.onDateChanged)
	DB.addHandler("calendar.current.month", "onUpdate", self.onDateChanged)
	DB.addHandler("calendar.current.year", "onUpdate", self.onYearChanged)

	DB.addHandler("moons.moonlist", "onChildAdded", self.onMoonCountUpdated)
	DB.addHandler("moons.moonlist", "onChildDeleted", self.onMoonCountUpdated)
	--CalendarManager.registerChangeCallback(onCalendarChangedMoonTracker)

	self.buildEvents()
	self.onDateChanged()
end
function onClose()
	if super and super.onClose then super.onClose() end

	DB.removeHandler("calendar.log", "onChildUpdate", self.onEventsChanged)
	DB.removeHandler("calendar.current.day", "onUpdate", self.onDateChanged)
	DB.removeHandler("calendar.current.month", "onUpdate", self.onDateChanged)
	DB.removeHandler("calendar.current.year", "onUpdate", self.onYearChanged)

	DB.removeHandler("moons.moonlist", "onChildAdded", self.onMoonCountUpdated)
	DB.removeHandler("moons.moonlist", "onChildDeleted", self.onMoonCountUpdated)
end

local bEnableBuild = true
function onEventsChanged(bListChanged)
	if bListChanged then
		if bEnableBuild then
			self.buildEvents()
			self.updateDisplay()
		end
	end
end
function buildEvents()
	aEvents = {}

	for _, v in ipairs(DB.getChildList("calendar.log")) do
		local nYear = DB.getValue(v, "year", 0)
		local nMonth = DB.getValue(v, "month", 0)
		local nDay = DB.getValue(v, "day", 0)

		if not aEvents[nYear] then
			aEvents[nYear] = {}
		end
		if not aEvents[nYear][nMonth] then
			aEvents[nYear][nMonth] = {}
		end
		aEvents[nYear][nMonth][nDay] = v
	end
end

function onDateChanged()
	if super and super.onDateChanged then super.onDateChanged() end

	self.updateDisplay()
	list.scrollToCampaignDate()

	self.populateMoonPhaseDisplay()
end
function onYearChanged()
	list.rebuildCalendarWindows()
	self.onDateChanged()
end
function onCalendarChanged()
	list.rebuildCalendarWindows()
	self.setSelectedDate(DB.getValue("calendar.current.month", 0), DB.getValue("calendar.current.day", 0))

	MoonManager.calculateEpochDay()
	self.setMoonFrame()
	self.populateMoonPhaseDisplay()
end

function updateDisplay()
	if super and super.updateDisplay then super.updateDisplay() end

	local sCampaignEpoch = DB.getValue("calendar.current.epoch", 0)
	local nCampaignYear = DB.getValue("calendar.current.year", 0)
	local nCampaignMonth = DB.getValue("calendar.current.month", 0)
	local nCampaignDay = DB.getValue("calendar.current.day", 0)

	local sDate = CalendarManager.getDateString(sCampaignEpoch, nCampaignYear, nCampaignMonth, nCampaignDay, true, true)
	sub_date.subwindow.viewdate.setValue(sDate)

	if aEvents[nCampaignYear] and aEvents[nCampaignYear][nSelMonth] and aEvents[nCampaignYear][nSelMonth][nSelDay] then
		sub_buttons.subwindow.button_view.setVisible(true)
		sub_buttons.subwindow.button_addlog.setVisible(false)
	else
		sub_buttons.subwindow.button_view.setVisible(false)
		sub_buttons.subwindow.button_addlog.setVisible(true)
	end

	for _, v in pairs(list.getWindows()) do
		local nMonth = v.month.getValue()

		local bCampaignMonth = false
		local bLogMonth = false
		if nMonth == nCampaignMonth then
			bCampaignMonth = true
		end
		if nMonth == nSelMonth then
			bLogMonth = true
		end

		if bCampaignMonth then
			v.label_period.setColor(ColorManager.COLOR_CALENDAR_HOLIDAY)
		else
			v.label_period.setColor(ColorManager.COLOR_PRIMARY_FOREGROUND)
		end

		for _, y in pairs(v.list_days.getWindows()) do
			local nDay = y.day.getValue()
			if nDay > 0 then
				local nodeEvent = nil
				if
					aEvents[nCampaignYear]
					and aEvents[nCampaignYear][nMonth]
					and aEvents[nCampaignYear][nMonth][nDay]
				then
					nodeEvent = aEvents[nCampaignYear][nMonth][nDay]
				end

				local bHoliday = CalendarManager.isHoliday(nMonth, nDay)
				local bCurrDay = (bCampaignMonth and nDay == nCampaignDay)
				local bSelDay = (bLogMonth and nDay == nSelDay)

				y.setState(bCurrDay, bSelDay, bHoliday, nodeEvent)
			end
		end
	end
end

function setSelectedDate(nMonth, nDay)
	nSelMonth = nMonth
	nSelDay = nDay

	self.populateMoonPhaseDisplay(nMonth, nDay)

	self.updateDisplay()
	list.scrollToCampaignDate()
end
function onSetButtonPressed()
	if Session.IsHost then
		CalendarManager.setCurrentDay(nSelDay)
		CalendarManager.setCurrentMonth(nSelMonth)
	end
end

function addLogEntryToSelected()
	self.addLogEntry(nSelMonth, nSelDay)
end
function addLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear()

	local nodeEvent
	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		nodeEvent = aEvents[nYear][nMonth][nDay]
	elseif Session.IsHost then
		local nodeLog = DB.createNode("calendar.log")
		bEnableBuild = false
		nodeEvent = DB.createChild(nodeLog)

		DB.setValue(nodeEvent, "epoch", "string", DB.getValue("calendar.current.epoch", ""))
		DB.setValue(nodeEvent, "year", "number", nYear)
		DB.setValue(nodeEvent, "month", "number", nMonth)
		DB.setValue(nodeEvent, "day", "number", nDay)
		bEnableBuild = true

		self.onEventsChanged()
	end

	if nodeEvent then
		Interface.openWindow("advlogentry", nodeEvent)
	end
end
function removeLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear()

	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		local nodeEvent = aEvents[nYear][nMonth][nDay]

		local bDelete = false
		if Session.IsHost then
			bDelete = true
		end

		if bDelete then
			DB.deleteNode(nodeEvent)
		end
	end
end

---
--- This function populates the display with the moon phases for all defined moons for the day selected.
---

-- luacheck: globals populateMoonPhaseDisplay
function populateMoonPhaseDisplay(nMonth, nDay)
	nMonth = nMonth or nSelMonth
	nDay = nDay or nSelDay

	if self.sub_date.subwindow.moons and self.sub_date.subwindow.moons.closeAll then
		self.sub_date.subwindow.moons.closeAll()
	end
	if nSelMonth and nSelDay then
		local epoch = DB.getValue("moons.epochday", 0)
		local moons = MoonManager.getMoons()

		local days
		for i = 1, nMonth do
			if i == nMonth then
				days = nDay
			else
				days = CalendarManager.getDaysInMonth(i)
			end

			epoch = epoch + days
		end

		if self.sub_date.subwindow.moons and self.sub_date.subwindow.moons.addEntry then
			for _, m in ipairs(moons) do
				self.sub_date.subwindow.moons.addEntry(m, epoch)
			end
		end
	end
end

---
--- This function will set the bounds for the list frame and hide the moons frame when
--- there are no moons defined.
---

-- luacheck: globals setMoonFrame
function setMoonFrame()
	local hasMoons = false
	local moons = DB.getChildren("moons.moonlist")
	for _, v in pairs(moons) do -- luacheck: ignore
		hasMoons = true
		break
	end
	if hasMoons then
		self.list.setStaticBounds(25, 135, -30, -65)
		self.sub_date.subwindow.moons.setVisible(true)
	else
		self.list.setStaticBounds(25, 75, -30, -65)
		self.sub_date.subwindow.moons.setVisible(false)
	end
end

---
--- This function gets called whenever a moon is added or deleted to rebuild the calendar window.
---
-- luacheck: globals onMoonCountUpdated
function onMoonCountUpdated()
	setMoonFrame()
end
