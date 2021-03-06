--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
local aEvents = {};
local nSelMonth = 0;
local nSelDay = 0;

---
--- This function has been modified to add some new event handlers.
---
function onInit()
	DB.addHandler('calendar.log', 'onChildUpdate', onEventsChanged);
	buildEvents();

	DB.addHandler('moons.moonlist', 'onChildAdded', onMoonCountUpdated);
	DB.addHandler('moons.moonlist', 'onChildDeleted', onMoonCountUpdated);

	CalendarManager.registerChangeCallback(onCalendarChangedMoonTracker);
	nSelMonth = currentmonth.getValue();
	nSelDay = currentday.getValue();

	onDateChanged();
end

---
--- This function has been modified to remove the new handlers added in the onInit() function.
---
function onClose()
	DB.removeHandler('calendar.log', 'onChildUpdate', onEventsChanged);
	DB.removeHandler('moons.moonlist', 'onChildAdded', onMoonCountUpdated);
	DB.removeHandler('moons.moonlist', 'onChildDeleted', onMoonCountUpdated);
end

function buildEvents()
	aEvents = {};

	for _, v in pairs(DB.getChildren('calendar.log')) do
		local nYear = DB.getValue(v, 'year', 0);
		local nMonth = DB.getValue(v, 'month', 0);
		local nDay = DB.getValue(v, 'day', 0);

		if not aEvents[nYear] then aEvents[nYear] = {}; end
		if not aEvents[nYear][nMonth] then aEvents[nYear][nMonth] = {}; end
		aEvents[nYear][nMonth][nDay] = v;
	end
end

local bEnableBuild = true;
function onEventsChanged(bListChanged)
	if bListChanged then
		if bEnableBuild then
			buildEvents();
			updateDisplay();
		end
	end
end

function setSelectedDate(nMonth, nDay)
	nSelMonth = nMonth;
	nSelDay = nDay;

	updateDisplay();
	populateMoonPhaseDisplay(nMonth, nDay);

	list.scrollToCampaignDate();
end

function addLogEntryToSelected() addLogEntry(nSelMonth, nSelDay); end

function addLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear();

	local nodeEvent;
	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		nodeEvent = aEvents[nYear][nMonth][nDay];
	elseif Session.IsHost then
		local nodeLog = DB.createNode('calendar.log');
		bEnableBuild = false;
		nodeEvent = nodeLog.createChild();

		DB.setValue(nodeEvent, 'epoch', 'string', DB.getValue('calendar.current.epoch', ''));
		DB.setValue(nodeEvent, 'year', 'number', nYear);
		DB.setValue(nodeEvent, 'month', 'number', nMonth);
		DB.setValue(nodeEvent, 'day', 'number', nDay);
		bEnableBuild = true;

		onEventsChanged();
	end

	if nodeEvent then Interface.openWindow('advlogentry', nodeEvent); end
end

function removeLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear();

	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		local nodeEvent = aEvents[nYear][nMonth][nDay];

		local bDelete = false;
		if Session.IsHost then bDelete = true; end

		if bDelete then nodeEvent.delete(); end
	end
end

function onSetButtonPressed()
	if Session.IsHost then
		CalendarManager.setCurrentDay(nSelDay);
		CalendarManager.setCurrentMonth(nSelMonth);
	end
end

function onDateChanged()
	updateDisplay();
	local nMonth = currentmonth.getValue();
	local nDay = currentday.getValue();
	populateMoonPhaseDisplay(nMonth, nDay);
	list.scrollToCampaignDate();
end

function onYearChanged()
	list.rebuildCalendarWindows();
	onDateChanged();
end

---
--- This function has been modified to add calls to the functions
--- MoonManager.calculateEpochDay() and setMoonFrame(),
---
function onCalendarChanged()
	list.rebuildCalendarWindows();
	setSelectedDate(currentmonth.getValue(), currentday.getValue());
	MoonManager.calculateEpochDay();
	setMoonFrame();
	local nMonth = currentmonth.getValue();
	local nDay = currentday.getValue();
	populateMoonPhaseDisplay(nMonth, nDay);
end

function updateDisplay()
	local sCampaignEpoch = currentepoch.getValue();
	local nCampaignYear = currentyear.getValue();
	local nCampaignMonth = currentmonth.getValue();
	local nCampaignDay = currentday.getValue();

	local sDate = CalendarManager.getDateString(sCampaignEpoch, nCampaignYear, nCampaignMonth, nCampaignDay, true, true);
	viewdate.setValue(sDate);

	if aEvents[nCampaignYear] and aEvents[nCampaignYear][nSelMonth] and aEvents[nCampaignYear][nSelMonth][nSelDay] then
		button_view.setVisible(true);
		button_addlog.setVisible(false);
	else
		button_view.setVisible(false);
		button_addlog.setVisible(true);
	end

	for _, v in pairs(list.getWindows()) do
		local nMonth = v.month.getValue();

		local bCampaignMonth = false;
		local bLogMonth = false;
		if nMonth == nCampaignMonth then bCampaignMonth = true; end
		if nMonth == nSelMonth then bLogMonth = true; end

		if bCampaignMonth then
			v.label_period.setColor('5A1E33');
		else
			v.label_period.setColor('000000');
		end

		for _, y in pairs(v.list_days.getWindows()) do
			local nDay = y.day.getValue();
			if nDay > 0 then
				local nodeEvent = nil;
				if aEvents[nCampaignYear] and aEvents[nCampaignYear][nMonth] and aEvents[nCampaignYear][nMonth][nDay] then
					nodeEvent = aEvents[nCampaignYear][nMonth][nDay];
				end

				local bHoliday = CalendarManager.isHoliday(nMonth, nDay);
				local bCurrDay = (bCampaignMonth and nDay == nCampaignDay);
				local bSelDay = (bLogMonth and nDay == nSelDay);

				y.setState(bCurrDay, bSelDay, bHoliday, nodeEvent);
			end
		end
	end
end

---
--- This function populates the display with the moon phases for all defined moons for the day selected.
---
function populateMoonPhaseDisplay(nMonth, nDay)
	nMonth = nMonth or nSelMonth;
	nDay = nDay or nSelDay;

	if self.moons and self.moons.closeAll then self.moons.closeAll(); end
	if nSelMonth and nSelDay then
		local epoch = DB.getValue('moons.epochday', 0);
		local moons = MoonManager.getMoons();

		local days;
		for i = 1, nMonth do
			if i == nMonth then
				days = nDay;
			else
				days = CalendarManager.getDaysInMonth(i);
			end

			epoch = epoch + days;
		end

		if self.moons and self.moons.addEntry then for _, m in ipairs(moons) do self.moons.addEntry(m, epoch); end end

	end
end

---
--- This function will set the bounds for the list frame and hide the moons frame when
--- there are no moons defined.
---
function setMoonFrame()
	local hasMoons = false;
	local moons = DB.getChildren('moons.moonlist');
	for _, v in pairs(moons) do -- luacheck: ignore
		hasMoons = true;
		break
	end
	if hasMoons then
		self.list.setStaticBounds(25, 135, -30, -65);
		self.moons.setVisible(true);
	else
		self.list.setStaticBounds(25, 75, -30, -65);
		self.moons.setVisible(false);
	end
end

---
--- This function gets called whenever a moon is added or deleted to rebuild the calendar window.
---
function onMoonCountUpdated() setMoonFrame(); end
