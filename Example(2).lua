-- Studio: place a ModuleScript named Nocturne beside this LocalScript.
-- File-capable environments: place Nocturne(2).lua in the working directory.
local module = script and script.Parent and script.Parent:FindFirstChild("Nocturne")
local Library
if module and module:IsA("ModuleScript") then
    Library = require(module)
elseif type(readfile) == "function" and type(isfile) == "function" and isfile("Nocturne(2).lua") then
    Library = assert(loadstring(readfile("Nocturne(2).lua")))()
else
    Library = assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/tanchdenis/jopahack4/main/Nocturne%282%29.lua")))()
end

local Player = game:GetService("Players").LocalPlayer
local ROLE = "fallen"

local Window = Library:CreateWindow({
    Id = "Demo",
    Title = Player.Name,        -- bold name in the footer
    Subtitle = ROLE,            -- grey line under the name
    Avatar = "headshot",        -- avatar in the footer (or any rbxassetid / rbxthumb string)
    Width = 530,
    Height = 620,
    Animations = true,
    AnimationSpeed = 1,
    Font = "Tahoma XP",
    ColorGallery = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(103, 187, 117) },
})

-- Callbacks: put your own logic here. It stays silent so the footer keeps showing the role.
local function report(value) end

-- Temporary status text in the footer (used by the config buttons).
local function notify(text)
    Window:SetStatus(text)
    task.delay(2, function()
        if not Window.Destroyed then Window:SetStatus(ROLE) end
    end)
end

-- Rich tooltip shown from the (i) icon.
local function info(title, path, text, risky)
    return { Title = title, Path = path, Text = text, Risky = risky }
end

-- toggle(section, text, flag, color, {On=, Info=, Callback=})
local function toggle(section, text, flag, color, extra)
    extra = extra or {}
    local item = section:AddToggle({
        Text = text,
        Flag = flag,
        Default = extra.On,
        Info = extra.Info,
        Callback = extra.Callback or report,
    })
    if color then item:AddColorPicker({ Default = color, Flag = flag .. "Color", Callback = report }) end
    return item
end

local Assistance = Window:AddTab("assistance")
local Visuals = Window:AddTab("visuals")
local Settings = Window:AddTab("miscellaneous")

----------------------------------------------------------------------
-- assistance / left column
----------------------------------------------------------------------
local Models = Assistance:AddSection("players models", "Left", 246)

toggle(Models, "visible model", "visible", Color3.fromRGB(42, 24, 225), {
    On = true,
    Info = info("visible model", "assistance - players models", "Color and material settings for the visible model."),
})
Models:AddDropdown({ Text = "material", Values = { "3d", "2d", "flat" }, Flag = "material", Callback = report })
Models:AddSlider({ Text = "intensity", Min = 0, Max = 100, Default = 7, Suffix = "x", Flag = "intensity", Callback = report })

toggle(Models, "occluded model", "occluded", Color3.fromRGB(176, 20, 225), {
    On = true,
    Info = info("occluded model", "assistance - players models", "Color and material settings for the occluded model."),
})
Models:AddDropdown({ Text = "material", Values = { "2d", "3d", "flat" }, Flag = "secondaryMaterial", Callback = report })
Models:AddSlider({ Text = "intensity", Min = 0, Max = 100, Default = 7, Suffix = "x", Flag = "secondaryIntensity", Callback = report })

local function world(section, prefix)
    local path = "visuals - world modulation"

    local time = toggle(section, "time of day", prefix .. "time", nil, {
        Info = info("time of day", path, "Overrides the hour of the day with the value of the slider below."),
    })
    time:AddKeybind({ Mode = "Toggle", Flag = prefix .. "timeKey", Callback = report })
    section:AddSlider({
        Text = "hour", Min = 0, Max = 24, Default = 12, Step = 0.5, Flag = prefix .. "hour",
        Format = function(v) return string.format("%02d:%02d", math.floor(v), math.floor(v % 1 * 60)) end,
        Callback = report,
    })

    toggle(section, "bright night", prefix .. "night", nil, {
        Info = info("bright night", path, "Makes the night brighter by the amount set in brightness."),
    })
    section:AddSlider({ Text = "brightness", Min = 0, Max = 300, Default = 150, Suffix = "%", Flag = prefix .. "brightness", Callback = report })

    toggle(section, "stars", prefix .. "stars", nil, {
        Info = info("stars", path, "Changes the size and brightness of the stars in the night sky."),
    })
    section:AddSlider({ Text = "star size", Min = 0, Max = 500, Default = 300, Suffix = "%", Flag = prefix .. "starSize", Callback = report })
    section:AddSlider({ Text = "star brightness", Min = 0, Max = 500, Default = 300, Suffix = "%", Flag = prefix .. "starBrightness", Callback = report })

    toggle(section, "day sky", prefix .. "daySky", Color3.fromRGB(83, 66, 170), {
        Info = info("day sky", path, "Tints the sky during daytime with the chosen color. Pairs with night sky to color each half of the cycle separately.", "can be seen in screen recordings"),
    })
    toggle(section, "night sky", prefix .. "nightSky", Color3.fromRGB(48, 175, 125), {
        Info = info("night sky", path, "Tints the sky during nighttime with the chosen color. Pairs with day sky to color each half of the cycle separately.", "can be seen in screen recordings"),
    })
end

world(Assistance:AddSection("world modulation", "Left", 246), "main")

----------------------------------------------------------------------
-- assistance / right column
----------------------------------------------------------------------
local General -- created below, but the master toggle needs to reach it

local Master = Assistance:AddSection("players master", "Right", 144)
toggle(Master, "master", "master", nil, {
    Info = info("master", "assistance - players master", "Master switch for the general options below."),
    Callback = function(value)
        if General then General:SetEnabled(value) end
        report(value)
    end,
})
Master:AddSlider({ Text = "max distance", Min = 0, Max = 500, Default = 200, Suffix = "m", Flag = "distance", Callback = report })

General = Assistance:AddSection("general", "Right", 190)
General:AddDropdown({ Text = "bounding box", Values = { "2d", "3d", "cornered" }, Flag = "boxStyle", Callback = report,
    Info = info("bounding box", "assistance - general", "Selects the style of the bounding box.") })
for _, name in ipairs({ "name", "distance", "skeleton", "held item" }) do
    toggle(General, name, "general" .. name, Color3.new(1, 1, 1), {
        Info = name == "held item" and info("held item", "assistance - general", "Shows the item currently held.") or nil,
    })
end
General:SetEnabled(false) -- greyed out until master is on

local Extra = Assistance:AddSection("extra", "Right", 144)
local checkbox = toggle(Extra, "checkbox", "extra", Color3.new(1, 1, 1), {
    Info = info("checkbox", "assistance - extra", "A toggle with two colors and a key bind. Right click the key to change its mode."),
})
checkbox:AddColorPicker({ Default = Color3.fromRGB(103, 187, 117), Flag = "extraColor2", Callback = report })
checkbox:AddKeybind({ Mode = "Toggle", Flag = "extraKey", Callback = report }) -- right click: on hold / off hold / toggle / always on

----------------------------------------------------------------------
-- visuals
----------------------------------------------------------------------
for _, name in ipairs({ "characters", "animals" }) do
    local sub = Visuals:AddSubTab(name)
    local left = sub:AddSection(name .. " preview", "Left", 270)
    toggle(left, "enabled", name .. "Enabled", Color3.new(1, 1, 1))
    left:AddDropdown({ Text = "bounding box", Values = { "2d", "3d", "cornered" }, Flag = name .. "Box", Callback = report })
    left:AddSlider({ Text = "max distance", Min = 0, Max = 1000, Default = 200, Suffix = "m", Flag = name .. "Distance", Callback = report })
    local right = sub:AddSection(name .. " extra", "Right", 420)
    toggle(right, "health bar", name .. "Health")
    toggle(right, "name", name .. "Name", Color3.new(1, 1, 1))
end

local World = Visuals:AddSubTab("world")
local Category = World:AddSection("categories", "Left")
local worldMaster = World:AddSection("containers master", "Right", 120)
toggle(worldMaster, "master", "worldMaster")
worldMaster:AddSlider({ Text = "max distance", Min = 0, Max = 1000, Default = 200, Suffix = "m", Flag = "worldDistance", Callback = report })

world(World:AddSection("world modulation", "Left", 430), "world")

local WG = World:AddSection("general", "Right", 160)
WG:AddDropdown({ Text = "bounding box", Values = { "2d", "3d", "cornered" }, Icon = "grid", Flag = "worldBox", Callback = report })
toggle(WG, "name", "worldName")
toggle(WG, "distance", "worldDistanceLabel")
local health = toggle(WG, "health bar", "worldHealth", Color3.fromRGB(178, 100, 100))
health:AddColorPicker({ Text = "full health", Default = Color3.fromRGB(100, 178, 120), Flag = "worldHealthFull" })

local groups = {}
local names = {
    containers = { "crate", "military crate", "elite crate", "barrel", "oil barrel", "supply drop", "locked crate", "stash", "tool cupboard" },
    resources = { "stone ore", "metal ore", "sulfur ore", "tree", "hemp", "mushroom", "corn", "pumpkin", "wood pile" },
    items = { "weapons", "ammunition", "medical", "attire", "tools", "components", "explosives", "food", "blueprints" },
}
for _, category in ipairs({ "containers", "resources", "items" }) do
    local section = World:AddSection(category, "Right", 250)
    groups[category] = section
    for i, name in ipairs(names[category]) do
        toggle(section, name, category .. name, Color3.fromHSV(i / 12, 0.5, 0.65))
    end
    section:SetVisible(category == "containers")
end
Category:AddListbox({
    Values = { "containers", "resources", "items" },
    Height = 54,
    StatusColor = Color3.fromRGB(95, 150, 100),
    Flag = "category",
    Callback = function(value)
        for name, section in pairs(groups) do section:SetVisible(name == value) end
        worldMaster:SetTitle(value .. " master")
    end,
})

local Local = Visuals:AddSubTab("local")
local Skins = Local:AddSection("skin changer", "Left", 435)
toggle(Skins, "enabled", "skins")
local Detail = Local:AddSection("rock", "Right", 435)
toggle(Detail, "override", "override")
Detail:AddDropdown({ Text = "skin", Values = { "default", "army", "black", "red", "blue" }, Flag = "skin", Callback = report })
Skins:AddListbox({
    Values = { "rock", "stone hatchet", "hatchet", "salvaged axe", "pickaxe", "stone pickaxe", "salvaged icepick", "hammer", "salvaged hammer", "torch", "jackhammer", "chainsaw", "hoodie", "pants", "boots", "t-shirt", "longsleeve t-shirt", "shirt", "tank top", "shorts", "jacket" },
    Height = 365,
    Flag = "skinItem",
    Callback = function(value) Detail:SetTitle(value) end,
})

----------------------------------------------------------------------
-- miscellaneous
----------------------------------------------------------------------
local Interface = Settings:AddSection("interface", "Left")
Interface:AddColorPicker({ Text = "accent", Default = Window.Accent, Flag = "accent", Callback = function(c) Window:SetAccent(c) end })
Interface:AddLabel("Right Shift: show / hide")
Interface:AddButton({ Text = "unload", Callback = function() Window:Destroy() end })

local Config = Settings:AddSection("configuration", "Right")
Config:AddButton({ Text = "save default", Callback = function()
    local ok, err = Window:SaveConfig("default")
    notify(ok and "saved" or tostring(err))
end })
Config:AddButton({ Text = "load default", Callback = function()
    local ok, err = Window:LoadConfig("default", false)
    notify(ok and "loaded" or tostring(err))
end })
Config:AddLabel("UI demonstration.\nConnect your own callbacks.")

Assistance:Select()

return Window
