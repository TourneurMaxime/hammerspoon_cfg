-- Hammerspoon

-- Setup
local MIN_WIDTH = 500
local MIN_HEIGHT = 300
myMenu = nil
hs.application.enableSpotlightForNameSearches(true)

local appsPathOnFrontScreen = {
    "/Applications/iTerm.app",
    "/Applications/Microsoft Excel.app",
    "/Applications/PhpStorm.app",
    "/Applications/Visual Studio Code.app",
    "/System/Applications/Messages.app",
    "/System/Applications/Réglages Système.app",
    "/System/Library/CoreServices/Centre de notifications.app",
    "/System/Library/CoreServices/NotificationCenter.app",
    "/Users/maximetourneur/Applications/Sharepoint.app",
}

local appsPathOnRightScreen = {
    "/Applications/Arc.app",
    "/Applications/Dia.app",
    "/Applications/ChatGPT.app",
    "/Applications/FileZilla.app",
    "/Applications/Postman.app",
    "/Applications/Web App.app",
    "/Users/maximetourneur/Applications/Le Chat - Mistral AI.app",
    "/Users/maximetourneur/Applications/Mammouth AI.app",
}

local excludedMaximizeAppsPath = {
    "/Applications/iTerm.app",
    "/Applications/Messenger.app",
    "/Applications/NotchNook.app",
    "/Applications/WhatsApp.app",
    "/Applications/Termius.app",
    "/System/Applications/Notes.app",
    "/System/Applications/Messages.app",
    "/System/Applications/Rappels.app",
    "/System/Applications/Reminders.app",
}

local excludedAutoMoveAppsPath = {
    "/Applications/DeepL.app",
    "/Applications/NotchNook.app",
    "/Applications/OneDrive.localized/OneDrive.app",
    "/Applications/Raycast.app",
    "/Applications/Shottr.app",
    "/System/Library/CoreServices/Centre de contrôle.app",
    "/System/Library/CoreServices/Control Center.app",
    "/System/Library/CoreServices/ControlCenter.app",
    "/System/Library/CoreServices/Dock.app",
    "/System/Library/CoreServices/Finder.app",
    "/System/Library/UserNotificationCenter.app",
}

-- Fonctions utilitaires
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

        if contains(excludedAutoMoveAppsPath, appPath) then goto continue end
        if contains(excludedAutoMoveAppsPath, app:name()) then goto continue end

        print("Organizing window: " .. win:title() .. " - " .. appPath)

        if contains(appsPathOnFrontScreen, appPath) then
            win:moveToScreen(frontScreen)
            -- Correction calibrage pour NotificationCenter
            if appPath == "/System/Library/CoreServices/NotificationCenter.app" or appPath == "/System/Library/CoreServices/Centre de notifications.app" then
                local screenFrame = frontScreen:frame()
                win:setFrame(screenFrame)
            end
        elseif contains(appsPathOnRightScreen, appPath) then
            win:moveToScreen(rightScreen)
        else
            win:moveToScreen(leftScreen)
        end
    ::continue::
    end
end

function maximizeWindows()
    for _, win in ipairs(hs.window.allWindows()) do
        local app = win:application()
        local appPath = getAppPath(app)
        if not contains(excludedMaximizeAppsPath, appPath) and win:isStandard() then
            print("Maximizing window: " .. win:title() .. " - " .. appPath)
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
myMenu = hs.menubar.new()
if myMenu then
    myMenu:setTitle("™")
    myMenu:setMenu({
        { title = "💾 Sauvegarder layout actuel", fn = saveCurrentLayout },
        { title = "⏮️ Restaurer layout sauvegardé", fn = restoreSavedLayout },
        { title = "-" },
        { title = "🔁 Organiser + Maximiser les fenêtres", fn = organizeAndMaximizeWindows },
        { title = "🔄 Organiser les fenêtres (cmd + shift + g)", fn = organizeWindows },
        { title = "🔼 Maximiser les fenêtres (cmd + shift + m)", fn = maximizeWindows },
        { title = "-" },
        { title = "♻️ Recharger la config Hammerspoon", fn = function() hs.reload() end },
        { title = "🛠️ Console Hammerspoon", fn = function() hs.openConsole(true) end },
        { title = "-" },
        { title = "⚙️ Configuration Hammerspoon (.lua)", fn = function() hs.execute("open " .. hs.configdir) end },
        { title = "❌ Quitter Hammerspoon", fn = function() hs.application.get("Hammerspoon"):kill() end },
    })
end

-- Raccourcis clavier
hs.hotkey.bind({ "cmd", "shift" }, "G", organizeWindows)
hs.hotkey.bind({ "cmd", "shift" }, "M", maximizeWindows)
hs.hotkey.bind({ "cmd", "alt" }, "R", function()
    hs.execute('shortcuts run "Reminder"', true)
end)

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
                    hs.application.get("NotchNook"):kill()
                    hs.timer.doAfter(0.5, function()
                        hs.application.launchOrFocus("/Applications/NotchNook.app")
                    end)
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
        appPath = getAppPath(win:application())
        print("Window created: " .. win:title() .. " - " .. appPath)
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

        if appPath == "/System/Library/Frameworks/Security.framework/Versions/A/MachServices/SecurityAgent.bundle" then
            win:close()
            return
        end

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
