-- https://github.com/Miqueas/GTK-Examples/tree/main/lua/gtk3
-- https://nooo37.github.io/wau/examples/foreign_toplevel_manager.lua.html

local lgi = require("lgi")
local Gtk = lgi.require("Gtk", "3.0")

-- Function to parse a .desktop file and extract key-value pairs
local function parseDesktopFile(filePath)
    local desktopData = {}

    local file, err = io.open(filePath, "r")
    if not file then
        return nil, "Failed to open file: " .. err
    end

    for line in file:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line and line:find('=') then
            local key, value = line:match("^(.-)=(.*)$")
            if key and value then
                desktopData[key] = value
            end
        end
    end

    file:close()
    return desktopData
end

-- Function to get the icon from a .desktop file based on StartupWMClass
local function getIconForWMClass(wmClass)
    -- Retrieve XDG_DATA_DIRS from environment variable
    local xdgDataDirs = os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
    local directories = {}
    for dir in xdgDataDirs:gmatch("[^:]+") do
        table.insert(directories, dir .. "/applications")
    end

    -- Search each directory
    for _, desktopDir in ipairs(directories) do
        local handle = io.popen('find "' .. desktopDir .. '" -name "*.desktop"')
        if handle then
            for filePath in handle:lines() do
                local data, parseErr = parseDesktopFile(filePath)
                if data then
                    if data["StartupWMClass"] == wmClass then
                        handle:close()
                        return data["Icon"] -- Return the icon name if found
                    end
                else
                    print("Error parsing file: " .. parseErr)
                end
            end
            handle:close()
        end
    end

    return nil -- Return nil if no matching WMClass was found
end

local appID = "fr.stilic.kiwbar"
local app = Gtk.Application({ application_id = appID })

function app:on_startup()
    local win = Gtk.ApplicationWindow({
        application = self,
        default_width = 400,
        default_height = 400,
        decorated = false
    })

    local wmClassToFind = "Vesktop" -- Replace with the WMClass you want to find
    local iconName = getIconForWMClass(wmClassToFind)
    if not iconName then
        print("Icon not found for: " .. wmClassToFind)
        app:quit()
    end

    local image = Gtk.Image({ visible = true, icon_name = iconName, pixel_size = 32 })

    win:add(image)
end

function app:on_activate()
    self.active_window:present()
end

return app:run(arg)
