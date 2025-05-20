-- Hammerspoon configuration file
-- This file is executed when Hammerspoon starts

-- Initialization global variables
hs.application.enableSpotlightForNameSearches(true)

local MIN_WIDTH = 500
local MIN_HEIGHT = 300

local appsPathOnFrontScreen = {
    "/Applications/App.app",
    "/System/Applications/App.app",
    "/Users/your_user_name/Applications/App.app",
}

local appsPathOnRightScreen = {
    "/Applications/App.app",
    "/System/Applications/App.app",
    "/Users/your_user_name/Applications/App.app",
}

local excludedMaximizeAppsPath = {
    "/Applications/App.app",
    "/System/Applications/App.app",
    "/Users/your_user_name/Applications/App.app",
}

local excludedAutoMoveAppsPath = {
    "/Applications/App.app",
    "/System/Applications/App.app",
    "/Users/your_user_name/Applications/App.app",
}

-- Functions
local function contains(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

local function getAppPath(app)
    return app and app:path() or nil
end

function getScreenConfigID()
    local ids = {}
    for _, screen in ipairs(hs.screen.allScreens()) do
        table.insert(ids, screen:getUUID())
    end
    table.sort(ids)
    return table.concat(ids, "_")
end

function getRequiredApps()
    local required = {}
    for _, path in ipairs(appsPathOnFrontScreen) do table.insert(required, path) end
    for _, path in ipairs(appsPathOnRightScreen) do table.insert(required, path) end
    return required
end

function organizeWindows()
    local screens = hs.screen.allScreens()
    if #screens < 3 then return end

    table.sort(screens, function(a, b)
        return a:position() < b:position()
    end)

    local frontScreen = screens[2]
    local leftScreen = screens[1]
    local rightScreen = screens[3]

    for _, win in ipairs(hs.window.allWindows()) do
        local app = win:application()
        local appPath = getAppPath(app)
        if contains(appsPathOnFrontScreen, appPath) then
            win:moveToScreen(frontScreen)
        elseif contains(appsPathOnRightScreen, appPath) then
            win:moveToScreen(rightScreen)
        else
            win:moveToScreen(leftScreen)
        end
    end
end

function maximizeWindows()
    for _, win in ipairs(hs.window.allWindows()) do
        local app = win:application()
        local appPath = getAppPath(app)
        if not contains(excludedMaximizeAppsPath, appPath) and win:isStandard() then
            win:maximize()
        end
    end
end

function organizeAndMaximizeWindows()
    local screens = hs.screen.allScreens()
    if #screens >= 3 then
        organizeWindows()
    end
    maximizeWindows()
end

function saveCurrentLayout()
    local configID = getScreenConfigID()
    local layout = {}

    for _, win in ipairs(hs.window.allWindows()) do
        if win:isStandard() then
            local app = win:application()
            local appPath = getAppPath(app)
            local frame = win:frame()
            local screenName = win:screen():name()
            table.insert(layout, {
                app = appPath,
                frame = { x = frame.x, y = frame.y, w = frame.w, h = frame.h },
                screen = screenName
            })
        end
    end

    local allLayouts = hs.settings.get("savedLayouts") or {}
    allLayouts[configID] = layout
    hs.settings.set("savedLayouts", allLayouts)
end

function restoreSavedLayout()
    local configID = getScreenConfigID()
    local allLayouts = hs.settings.get("savedLayouts") or {}
    local layout = allLayouts[configID]

    if not layout then return end

    for _, entry in ipairs(layout) do
        local app = hs.application.get(entry.app)
        if app then
            local win = app:mainWindow()
            if win then
                for _, screen in ipairs(hs.screen.allScreens()) do
                    if screen:name() == entry.screen then
                        win:moveToScreen(screen)
                        win:setFrame(entry.frame)
                        break
                    end
                end
            end
        end
    end
end

-- Menu Hammerspoon
myMenu = nil
myMenu = hs.menubar.new()
if myMenu then
    myMenu:setTitle("™") -- Set the title of the menu bar item
    myMenu:setMenu({
        { title = "💾 Save actual layout", fn = saveCurrentLayout },
        { title = "⏮️ Restore saved layout", fn = restoreSavedLayout },
        { title = "-" },
        { title = "🔁 Organize + Maximize windows", fn = organizeAndMaximizeWindows },
        { title = "🔄 Organize windows (cmd + shift + g)", fn = organizeWindows },
        { title = "🔼 Maximize windows (cmd + shift + m)", fn = maximizeWindows },
        { title = "-" },
        { title = "♻️ Reload Hammerspoon config", fn = function() hs.reload() end },
        { title = "🛠️ Hammerspoon Console", fn = function() hs.openConsole(true) end },
        { title = "-" },
        { title = "❌ Quit Hammerspoon", fn = function() hs.application.get("Hammerspoon"):kill() end },
    })
end

-- Hotkeys
hs.hotkey.bind({ "cmd", "shift" }, "G", organizeWindows)
hs.hotkey.bind({ "cmd", "shift" }, "M", maximizeWindows)

-- Watchers
function startCaffeinateWatcher()
    hs.caffeinate.watcher.new(function(event)
        local relevantEvents = {
            [hs.caffeinate.watcher.systemDidWake] = true,
            [hs.caffeinate.watcher.sessionDidBecomeActive] = true,
            [hs.caffeinate.watcher.sessionDidResignActive] = true,
            [hs.caffeinate.watcher.displayDidWake] = true,
            [hs.caffeinate.watcher.screensDidUnlock] = true,
            [hs.caffeinate.watcher.screensDidWake] = true,
        }

        if relevantEvents[event] then
            organizeAndMaximizeWindows()
        end
    end):start()
end

function startScreenWatcher()
    local previousScreenConfig = getScreenConfigID()

    screenWatcherTimer = hs.timer.doEvery(3, function()
        local ok, err = pcall(function()
            local currentScreenConfig = getScreenConfigID()
            if currentScreenConfig ~= previousScreenConfig then
                previousScreenConfig = currentScreenConfig

                if #hs.screen.allScreens() >= 3 then
                    organizeAndMaximizeWindows()
                end
            end
        end)
    end)
end

appLaunchWatcher = nil
function startAppLaunchWatcher()
    local function handleAppEvent(appName, eventType, app)
        if eventType == hs.application.watcher.launched then
            hs.timer.doAfter(0.5, function()
                local win = app:mainWindow()
                if not win then return end
                local frame = win:frame()
                if frame.w < MIN_WIDTH or frame.h < MIN_HEIGHT then return end
                
                if contains(excludedAutoMoveAppsPath, getAppPath(app)) then return end
                if contains(excludedAutoMoveAppsPath, app:name()) then return end

                local screens = hs.screen.allScreens()
                if #screens < 3 then return end

                table.sort(screens, function(a, b)
                    return a:position() < b:position()
                end)

                local appPath = getAppPath(app)
                local frontScreen = screens[2]
                local leftScreen = screens[1]
                local rightScreen = screens[3]

                if contains(appsPathOnFrontScreen, appPath) then
                    win:moveToScreen(frontScreen)
                elseif contains(appsPathOnRightScreen, appPath) then
                    win:moveToScreen(rightScreen)
                else
                    win:moveToScreen(leftScreen)
                end
            end)
        end
    end

    appLaunchWatcher = hs.application.watcher.new(handleAppEvent)
    appLaunchWatcher:start()
end

function startWindowCreationWatcher()
    hs.window.filter.new(nil):subscribe(hs.window.filter.windowCreated, function(win, appName)
        if not win then return end

        local frame = win:frame()
        if frame.w < MIN_WIDTH or frame.h < MIN_HEIGHT then return end
        
        local app = win:application()
        local appPath = getAppPath(app)
        if not appPath then return end
        
        if contains(excludedAutoMoveAppsPath, appPath) then return end
        if contains(excludedAutoMoveAppsPath, app:name()) then return end

        local screens = hs.screen.allScreens()
        if #screens < 3 then return end

        table.sort(screens, function(a, b)
            return a:position() < b:position()
        end)

        local frontScreen = screens[2]
        local leftScreen = screens[1]
        local rightScreen = screens[3]

        if contains(appsPathOnFrontScreen, appPath) then
            win:moveToScreen(frontScreen)
        elseif contains(appsPathOnRightScreen, appPath) then
            win:moveToScreen(rightScreen)
        else
            win:moveToScreen(leftScreen)
        end
    end)
end

startWindowCreationWatcher()
startAppLaunchWatcher()
startScreenWatcher()
startCaffeinateWatcher()