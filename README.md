[![Build FG-Usable File](https://github.com/FG-Unofficial-Developers-Guild/FG-CoreRPG-Moon-Tracker/actions/workflows/create-ext.yml/badge.svg)](https://github.com/FG-Unofficial-Developers-Guild/FG-CoreRPG-Moon-Tracker/actions/workflows/create-ext.yml) [![Luacheck](https://github.com/FG-Unofficial-Developers-Guild/FG-CoreRPG-Moon-Tracker/actions/workflows/luacheck.yml/badge.svg)](https://github.com/FG-Unofficial-Developers-Guild/FG-CoreRPG-Moon-Tracker/actions/workflows/luacheck.yml)

# Moon Tracker
This is an extension for Fantasy Grounds that improves upon the functionality for the built-in calendar function by allowing it to track the phases for the moons in your campaign. A new button has been added to the Calendar window for configuring the moons for your campaign. Clicking this button opens up a configuration window, allowing you to add as many moons for your campaign as you wish, defining their names, phase periods, and phase shift. Once configured, clicking on any day on the calendar will display the moon phases for that day in a new panel that has been added to the calendar window.

![Screenshot of Moon Tracker Windows and Chat Output](https://user-images.githubusercontent.com/1916835/128919380-d1e7ee91-311f-4529-bc8e-cbe439fdce91.png)

This extension is designed to work out-of-the-box for all campaigns that use one of the pre-build calendars. For rulesets that use a custom calendar that requires registering for the CalendarManager events registerChangeCallback, registerLunarDayHandler, or registerMonthVarHandler, this extension will also work with a bit of additional configuration. From within your ruleset you will need to make sure that the above registrations occur after the extension has been loaded. A good way to do this is to register the Interface.onDesktopInit event and to register your callbacks with the CalendarManager within this function.

# Basic tutorial:
1. Load extension into campaign
2. Open Calendar via button in upper right
3. Click icon of moon in upper left of calendar window (must already have a calendar set up)
4. Click edit and then add a moon (allows worlds with multiple moons--very cool!)
5. Close moons list and click a day on the calendar to see what the lunar phase is for that day

# Options:
* Period: how many solar days it takes to repeat the lunar cycle
* Duration: how long the full moon and new moon last (for things like lycanthropy that may only last a single night)
* Shift: move the entire lunar cycle forward/backward to align with other events like holidays

# Compatibility
This extension has been tested with [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) 4.1.13 (2022-01-05).
