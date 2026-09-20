local SETTINGS = {
    Enabled = true,
    Mode = "Cycle",
    CycleLengthSeconds = 240,
    DayLengthSeconds = 160,
    NightLengthSeconds = 160,
    Warmth = 0.88,
    VFXIntensity = 0.72,
    SunSize = 90,
    MoonSize = 76,
    CelestialDistance = 1800,
    CelestialOrigin = {X = 0, Y = 0, Z = 0},
    GeographicLatitude = 23.5,
    WeatherDensity = 1,
    SnowFallSpeed = 5,
    SnowFallSpeedVariance = 2,
    SnowSize = 0.24,
    RainFallSpeed = 100,
    RainFallSpeedVariance = 15,
    RainSizeWidth = 0.065,
    RainSizeLength = 2.1,
    FireRainFallSpeed = 34,
    FireRainFallSpeedVariance = 8,
    FireRainSizeWidth = 0.09,
    FireRainSizeLength = 0.9,
    StarFallSpeed = 46,
    StarFallSpeedVariance = 14,
    StarFallSize = 0.18,
    StarTailLength = 1.75,
    ThunderChance = 0.7,
    ThunderSoundIds = {
        131300621,
        9120017499,
        9120018088,
        9120019553
    },
    WindStrength = 3,
    WindDirectionDegrees = 18,
    MaxWeatherParts = 480,
    Modifiers = {
        Cloudy = false,
        Rain = false,
        Snow = false,
        FireRain = false,
        StarFall = false
    },
    ModeSettings = {
        Cycle = {
            StartTime = 7.2,
            HazeStrength = 1,
            GlowStrength = 1,
            SunScale = 1,
            MoonScale = 1,
            StarDensity = 1
        },
        Day = {
            MinTime = 7.5,
            MaxTime = 16.5,
            HazeStrength = 0.85,
            GlowStrength = 0.9,
            SunScale = 1,
            MoonScale = 1,
            StarDensity = 0
        },
        Night = {
            CenterTime = 0,
            TimeSwing = 2.5,
            HazeStrength = 0.8,
            GlowStrength = 0.8,
            SunScale = 1,
            MoonScale = 1.15,
            StarDensity = 1
        },
        GoldenHour = {
            ClockTime = 16.8,
            HazeStrength = 1,
            GlowStrength = 1.15,
            SunScale = 1.4,
            MoonScale = 1,
            StarDensity = 0
        },
        Overcast = {
            ClockTime = 12,
            HazeStrength = 1,
            GlowStrength = 0.35,
            SunScale = 1,
            MoonScale = 1,
            StarDensity = 0,
            CloudCover = 0.96,
            CloudDensity = 0.9
        },
        Storm = {
            ClockTime = 16,
            HazeStrength = 1,
            GlowStrength = 0.5,
            SunScale = 1,
            MoonScale = 1,
            StarDensity = 0,
            CloudCover = 0.99,
            CloudDensity = 1,
            Lightning = true,
            LightningMinSeconds = 10,
            LightningMaxSeconds = 24,
            LightningStrength = 0.7
        },
        Moonlight = {
            ClockTime = 0.5,
            HazeStrength = 1,
            GlowStrength = 1.15,
            SunScale = 1,
            MoonScale = 1.9,
            StarDensity = 1.2
        },
        Sunset = {
            ClockTime = 17.5,
            HazeStrength = 1,
            GlowStrength = 1.2,
            SunScale = 2.1,
            MoonScale = 1,
            StarDensity = 0
        }
    },
    UIEnabled = true,
    ToggleKey = "F8",
    LockLighting = true,
    DisableOtherPostEffects = false,
    HideOtherClouds = false
}

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
assert(player, "KOOL vfx must run in a LocalScript.")

local playerGui = player:WaitForChild("PlayerGui")
local playerScripts = player:WaitForChild("PlayerScripts")

for _, child in ipairs(playerScripts:GetChildren()) do
    if child.Name == "KOOL_VFX" and child ~= script then
        local shutdown = child:FindFirstChild("Shutdown")
        if shutdown and shutdown:IsA("BindableFunction") then
            pcall(function()
                shutdown:Invoke()
            end)
        end
        pcall(function()
            child:Destroy()
        end)
    end
end

for _, child in ipairs(playerGui:GetChildren()) do
    if child.Name == "KOOL_VFX_UI" then
        child:Destroy()
    end
end

for _, child in ipairs(workspace:GetChildren()) do
    if child.Name == "KOOL_VFX_Celestials" or child.Name == "KOOL_VFX_Weather" then
        child:Destroy()
    end
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = deepCopy(item)
    end
    return result
end

local function noGreen(color)
    return Color3.new(color.R, math.min(color.G, math.max(color.R, color.B)), color.B)
end

local function C(r, g, b)
    return Color3.fromRGB(r, math.min(g, math.max(r, b)), b)
end

local function lerp(a, b, t)
    return noGreen(a:Lerp(b, math.clamp(t, 0, 1)))
end

local function smooth(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local DEFAULTS = deepCopy(SETTINGS)
local draft = deepCopy(SETTINGS)

local MODES = {
    {key = "Cycle", title = "DAY / NIGHT CYCLE", description = "Sunrise, day, golden hour, sunset, twilight and night."},
    {key = "Day", title = "DAY", description = "Bright daylight. A moving sun that never sets. No moon."},
    {key = "Night", title = "NIGHT", description = "A cratered moon, stars and gentle cool nighttime light."},
    {key = "GoldenHour", title = "GOLDEN HOUR", description = "Golden sunlight, soft long shadows and warm sun rays."},
    {key = "Overcast", title = "OVERCAST", description = "Thick clouds, soft gray-blue light and subtle mist."},
    {key = "Storm", title = "STORM", description = "Dark blue storm clouds, cold fog and visible lightning."},
    {key = "Moonlight", title = "MOONLIGHT", description = "A large silver moon, deep shadows, stars and a soft halo."},
    {key = "Sunset", title = "SUNSET", description = "A large orange sun with pink-purple skies. It never sets."}
}

local modeLookup = {}
local modeAliases = {}

for _, item in ipairs(MODES) do
    modeLookup[item.key] = item
    modeAliases[string.lower(item.key)] = item.key
    modeAliases[string.lower(item.title):gsub("[^%a]", "")] = item.key
end

modeAliases.daynight = "Cycle"
modeAliases.daynightcycle = "Cycle"
modeAliases.custom = "Day"

local modifierNames = {
    {key = "Cloudy", text = "CLOUDY"},
    {key = "Rain", text = "RAIN"},
    {key = "Snow", text = "SNOW"},
    {key = "FireRain", text = "FIRE RAIN"},
    {key = "StarFall", text = "STAR FALL"}
}

local gui
local main
local content
local pageLabel
local titleLabel
local subtitleLabel
local statusLabel
local presetBox
local backButton
local nextButton
local startButton
local previewButton
local shortcutLabel
local uiScale
local controller
local navItems = {}

local uiConnections = {}
local pageConnections = {}
local connections = {}
local runtimeConnections = {}
local pageScope = false
local page = 1
local alive = true
local active = false
local previewing = false
local configuring = true
local initialized = false
local applying = false
local repairQueued = false
local configDirty = false
local resetRequested = false
local capturingHotkey = false
local hotkeyCaptureConnection = nil

local owned = {}
local originalLighting = {}
local displacedObjects = {}
local disabledPostEffects = {}
local disabledCloudObjects = {}
local displacedSkyObjects = {}
local effectRecords = {}
local textBoxMouseBehavior = nil
local textBoxMouseIconEnabled = true

local celestialFolder
local weatherFolder
local cloudObject
local sun
local moon
local stars = {}
local drops = {}
local geometrySignature
local weatherSignature
local weatherCenter
local weatherHalfSize = Vector3.new(54, 38, 54)
local weatherBoxSize = weatherHalfSize * 2
local weatherCenterOffset = Vector3.new(0, 16, 0)
local modeClock = 7.2
local dayPhase = 0
local nightPhase = 0
local currentClock = 12
local lastMode
local lightingAccumulator = 0
local auditAccumulator = 0
local lightningTimer = 12
local lightningAge = -1
local lightningFlash = 0
local lightningSignature
local lightningPattern = "double"
local lightningStrikeScale = 1
local thunderQueue = {}
local thunderSounds = {}
local thunderPoolIndex = 0
local random = Random.new()
local currentState
local renderPage

local function disconnectAll(list)
    for _, connection in ipairs(list) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(list)
end

local function connect(signal, callback, list)
    if not signal or type(callback) ~= "function" then
        return nil
    end
    local ok, connection = pcall(function()
        return signal:Connect(callback)
    end)
    if not ok or not connection then
        return nil
    end
    local target = list or connections
    target[#target + 1] = connection
    return connection
end

local function uiConnect(signal, callback)
    return connect(signal, callback, pageScope and pageConnections or uiConnections)
end

local function running()
    return alive and initialized and (active or previewing)
end

local function getConfig()
    return previewing and draft or SETTINGS
end

local function make(className, props, parent)
    local object = Instance.new(className)
    for property, value in pairs(props or {}) do
        pcall(function()
            object[property] = value
        end)
    end
    object.Parent = parent
    return object
end

local function round(object, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius)}, object)
end

local function stroke(object, color, thickness, transparency)
    return make("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    }, object)
end

local function gradient(object, a, b, rotation)
    return make("UIGradient", {
        Color = ColorSequence.new(a, b),
        Rotation = rotation or 45
    }, object)
end

local function label(parent, text, position, size, font, textSize, color)
    return make("TextLabel", {
        Position = position,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or C(32, 63, 83),
        TextTransparency = 0,
        Font = font or Enum.Font.Gotham,
        TextSize = textSize or 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, parent)
end

local function button(parent, text, position, size)
    local b = make("TextButton", {
        Size = size or UDim2.fromOffset(150, 42),
        Position = position or UDim2.new(),
        BackgroundColor3 = C(234, 246, 253),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = C(31, 64, 87),
        TextTransparency = 0,
        TextStrokeTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        AutoButtonColor = false,
        Active = true,
        Selectable = true,
        ZIndex = 20
    }, parent)

    round(b, 16)
    stroke(b, C(168, 207, 230), 1.2, 0.06)

    uiConnect(b.MouseEnter, function()
        if b.Parent then
            local selected = b:GetAttribute("KOOL_Selected") == true
            TweenService:Create(
                b,
                TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = selected and C(77, 151, 202) or C(225, 242, 252)}
            ):Play()
        end
    end)

    uiConnect(b.MouseLeave, function()
        if b.Parent then
            local selected = b:GetAttribute("KOOL_Selected") == true
            TweenService:Create(
                b,
                TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = selected and C(86, 161, 212) or C(234, 246, 253)}
            ):Play()
        end
    end)

    return b
end

local function setSelectedButton(b, selected)
    if not b then
        return
    end

    b:SetAttribute("KOOL_Selected", selected == true)
    b.BackgroundColor3 = selected and C(86, 161, 212) or C(234, 246, 253)
    b.TextColor3 = selected and C(255, 255, 255) or C(31, 64, 87)
    b.TextTransparency = 0

    local outline = b:FindFirstChildOfClass("UIStroke")
    if outline then
        outline.Color = selected and C(58, 126, 175) or C(168, 207, 230)
        outline.Transparency = selected and 0 or 0.06
        outline.Thickness = selected and 1.5 or 1.2
    end
end

local function slider(parent, y, value, callback, title, formatter)
    local card = make("Frame", {
        Position = UDim2.new(0, 12, 0, y),
        Size = UDim2.new(1, -24, 0, 68),
        BackgroundColor3 = C(241, 249, 254),
        BorderSizePixel = 0
    }, parent)
    round(card, 18)
    stroke(card, C(213, 231, 242), 1, 0.08)

    label(card, title, UDim2.new(0, 14, 0, 10), UDim2.new(1, -150, 0, 18), Enum.Font.GothamSemibold, 11, C(47, 85, 112))

    local valuePill = make("Frame", {
        Position = UDim2.new(1, -124, 0, 8),
        Size = UDim2.fromOffset(110, 22),
        BackgroundColor3 = C(225, 241, 251),
        BorderSizePixel = 0
    }, card)
    round(valuePill, 11)

    local valueLabel = label(valuePill, "", UDim2.new(0, 0, 0, 0), UDim2.new(1, -10, 1, 0), Enum.Font.GothamBold, 11, C(42, 121, 169))
    valueLabel.Position = UDim2.new(0, 6, 0, 0)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local hitbox = make("TextButton", {
        Position = UDim2.new(0, 14, 0, 32),
        Size = UDim2.new(1, -28, 0, 24),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = 24
    }, card)

    local track = make("Frame", {
        Position = UDim2.new(0, 0, 0.5, -5),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = C(212, 230, 241),
        BorderSizePixel = 0,
        ZIndex = 21
    }, hitbox)
    round(track, 8)

    local fill = make("Frame", {
        Size = UDim2.new(math.clamp(value, 0, 1), 0, 1, 0),
        BackgroundColor3 = C(116, 186, 230),
        BorderSizePixel = 0,
        ZIndex = 22
    }, track)
    round(fill, 8)

    local knob = make("Frame", {
        Size = UDim2.fromOffset(20, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(math.clamp(value, 0, 1), 0, 0.5, 0),
        BackgroundColor3 = C(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 23
    }, track)
    round(knob, 10)
    stroke(knob, C(98, 167, 210), 1.3)

    local dragging = false
    local touchInput

    local function display(alpha)
        valueLabel.Text = formatter and formatter(alpha) or string.format("%.0f%%", alpha * 100)
    end

    local function setAlpha(alpha)
        alpha = math.clamp(alpha, 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        callback(alpha)
        display(alpha)
        configDirty = previewing
    end

    local function fromInput(input)
        if track.AbsoluteSize.X > 0 then
            setAlpha((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
        end
    end

    display(value)

    uiConnect(hitbox.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            touchInput = input.UserInputType == Enum.UserInputType.Touch and input or nil
            fromInput(input)
        end
    end)

    uiConnect(UserInputService.InputChanged, function(input)
        if dragging and ((touchInput and input == touchInput) or (not touchInput and input.UserInputType == Enum.UserInputType.MouseMovement)) then
            fromInput(input)
        end
    end)

    uiConnect(UserInputService.InputEnded, function(input)
        if input == touchInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            touchInput = nil
        end
    end)
end

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function getModeOptions(cfg, mode)
    local settings = cfg and cfg.ModeSettings
    local selectedMode = mode or (cfg and cfg.Mode)
    local options = settings and settings[selectedMode]

    if type(options) ~= "table" then
        local defaults = DEFAULTS.ModeSettings[selectedMode]
        options = type(defaults) == "table" and defaults or DEFAULTS.ModeSettings.Cycle
    end

    return options
end

local function getModifiers(cfg)
    local modifiers = cfg and cfg.Modifiers
    return type(modifiers) == "table" and modifiers or DEFAULTS.Modifiers
end

local numericBounds = {
    CycleLengthSeconds = {60, 900},
    DayLengthSeconds = {60, 900},
    NightLengthSeconds = {60, 900},
    Warmth = {0, 1},
    VFXIntensity = {0, 1},
    SunSize = {20, 240},
    MoonSize = {20, 240},
    CelestialDistance = {800, 12000},
    GeographicLatitude = {-45, 45},
    WeatherDensity = {0, 1.5},
    SnowFallSpeed = {1, 250},
    SnowFallSpeedVariance = {0, 100},
    SnowSize = {0.08, 0.5},
    RainFallSpeed = {1, 250},
    RainFallSpeedVariance = {0, 100},
    RainSizeWidth = {0.03, 0.5},
    RainSizeLength = {0.3, 8},
    FireRainFallSpeed = {1, 250},
    FireRainFallSpeedVariance = {0, 100},
    FireRainSizeWidth = {0.03, 0.5},
    FireRainSizeLength = {0.3, 8},
    StarFallSpeed = {1, 250},
    StarFallSpeedVariance = {0, 100},
    StarFallSize = {0.08, 0.5},
    StarTailLength = {0.3, 8},
    ThunderChance = {0, 1},
    WindStrength = {0, 30},
    WindDirectionDegrees = {0, 360},
    MaxWeatherParts = {100, 800},
    X = {-1000000, 1000000},
    Y = {-1000000, 1000000},
    Z = {-1000000, 1000000},
    StartTime = {0, 23.999},
    MinTime = {7, 11.5},
    MaxTime = {12.5, 17},
    CenterTime = {0, 24},
    TimeSwing = {0, 3},
    ClockTime = {0, 24},
    HazeStrength = {0, 2},
    GlowStrength = {0, 2},
    SunScale = {0.5, 3},
    MoonScale = {0.5, 3},
    StarDensity = {0, 1.5},
    CloudCover = {0.65, 1},
    CloudDensity = {0.5, 1},
    LightningMinSeconds = {5, 90},
    LightningMaxSeconds = {5, 120},
    LightningStrength = {0, 1}
}

local function sanitizeInto(destination, source)
    for key, defaultValue in pairs(destination) do
        local value = source[key]
        if type(defaultValue) == "table" and type(value) == "table" then
            sanitizeInto(defaultValue, value)
        elseif type(defaultValue) == "number" and finite(value) then
            local bounds = numericBounds[key]
            destination[key] = bounds and math.clamp(value, bounds[1], bounds[2]) or value
        elseif type(defaultValue) == "boolean" and type(value) == "boolean" then
            destination[key] = value
        end
    end
end

local function presetData()
    local data = deepCopy(draft)
    data.Version = 10
    return data
end

local function encodePreset()
    local ok, result = pcall(function()
        return HttpService:JSONEncode(presetData())
    end)
    return ok and result or ""
end

local function applyPresetString(text)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(text)
    end)

    if not ok or type(data) ~= "table" then
        return false, "Invalid preset JSON."
    end

    local source = type(data.Settings) == "table" and data.Settings or data
    local mode = source.Mode

    if type(mode) == "string" then
        mode = modeAliases[string.lower(mode):gsub("[^%a]", "")]
    elseif mode == nil then
        mode = DEFAULTS.Mode
    end

    if not mode or not modeLookup[mode] then
        return false, "Unknown lighting mode."
    end

    local restored = deepCopy(DEFAULTS)
    sanitizeInto(restored, source)
    restored.Mode = mode

    if type(source.ToggleKey) == "string" and Enum.KeyCode[source.ToggleKey] then
        restored.ToggleKey = source.ToggleKey
    end


    restored.ModeSettings.GoldenHour.ClockTime = math.clamp(restored.ModeSettings.GoldenHour.ClockTime, 16, 17.25)
    restored.ModeSettings.Sunset.ClockTime = math.clamp(restored.ModeSettings.Sunset.ClockTime, 17.1, 17.65)
    restored.ModeSettings.Overcast.ClockTime = math.clamp(restored.ModeSettings.Overcast.ClockTime, 9, 15)
    restored.ModeSettings.Storm.ClockTime = math.clamp(restored.ModeSettings.Storm.ClockTime, 13, 17)
    restored.ModeSettings.Moonlight.ClockTime = math.clamp(restored.ModeSettings.Moonlight.ClockTime, 0, 3)
    restored.ModeSettings.Night.CenterTime = math.clamp(restored.ModeSettings.Night.CenterTime, 0, 2)
    restored.ModeSettings.Storm.LightningMaxSeconds = math.max(
        restored.ModeSettings.Storm.LightningMinSeconds,
        restored.ModeSettings.Storm.LightningMaxSeconds
    )

    draft = restored
    return true, "Preset loaded. All saved settings restored."
end

local function valuesMatch(a, b)
    if a == b then
        return true
    end
    if type(a) == "number" and type(b) == "number" then
        return math.abs(a - b) < 0.00005
    end
    if typeof(a) == "Color3" and typeof(b) == "Color3" then
        return math.abs(a.R - b.R) < 0.0003
            and math.abs(a.G - b.G) < 0.0003
            and math.abs(a.B - b.B) < 0.0003
    end
    return false
end

local function writeProperties(object, properties)
    if not object then
        return
    end
    for property, value in pairs(properties) do
        pcall(function()
            if not valuesMatch(object[property], value) then
                object[property] = value
            end
        end)
    end
end

local basePalette = {
    ambient = C(110, 135, 162),
    outdoor = C(167, 190, 215),
    shadow = C(50, 65, 91),
    tint = C(244, 249, 255),
    horizon = C(181, 211, 244),
    lowerSky = C(120, 177, 232),
    zenith = C(65, 129, 211),
    atmosphere = C(188, 213, 238),
    decay = C(113, 148, 186),
    sunColor = C(255, 231, 177),
    moonColor = C(204, 220, 249),
    cloudColor = C(229, 236, 246),
    brightness = 2.35,
    exposure = 0.08,
    density = 0.19,
    haze = 0.8,
    glare = 0.12,
    contrast = 0.055,
    saturation = 0.025,
    correctionBrightness = 0,
    bloom = 0.2,
    bloomSize = 28,
    bloomThreshold = 1.15,
    rays = 0.035,
    raySpread = 0.62,
    softness = 0.38,
    diffuse = 0.6,
    specular = 0.8,
    fogStart = 350,
    fogEnd = 6500,
    cloudCover = 0.18,
    cloudDensity = 0.32,
    sunVisibility = 1,
    moonVisibility = 0,
    stars = 0,
    horizonGlow = 0.07,
    warmthWeight = 1,
    night = 0,
    rayLength = 3.3
}

local function palette(overrides)
    local result = deepCopy(basePalette)
    for key, value in pairs(overrides) do
        result[key] = typeof(value) == "Color3" and noGreen(value) or value
    end
    return result
end

local palettes = {
    Day = palette({}),
    Dawn = palette({
        ambient = C(113, 104, 139),
        outdoor = C(163, 143, 168),
        shadow = C(56, 46, 76),
        tint = C(255, 233, 219),
        horizon = C(255, 169, 106),
        lowerSky = C(217, 146, 168),
        zenith = C(100, 110, 184),
        atmosphere = C(221, 183, 173),
        decay = C(110, 81, 124),
        sunColor = C(255, 183, 91),
        cloudColor = C(220, 186, 187),
        brightness = 1.6,
        exposure = -0.02,
        density = 0.23,
        haze = 1.7,
        glare = 0.22,
        rays = 0.065,
        bloom = 0.27,
        horizonGlow = 0.21,
        sunVisibility = 0.85,
        moonVisibility = 0.08,
        stars = 0.09,
        rayLength = 5
    }),
    GoldenHour = palette({
        ambient = C(115, 94, 77),
        outdoor = C(191, 160, 116),
        shadow = C(69, 55, 67),
        tint = C(255, 232, 203),
        horizon = C(255, 183, 75),
        lowerSky = C(247, 190, 123),
        zenith = C(119, 155, 207),
        atmosphere = C(244, 202, 146),
        decay = C(161, 108, 88),
        sunColor = C(255, 183, 64),
        cloudColor = C(250, 213, 163),
        brightness = 2.6,
        exposure = 0.02,
        density = 0.24,
        haze = 2.1,
        glare = 0.38,
        contrast = 0.085,
        saturation = 0.075,
        bloom = 0.34,
        bloomSize = 38,
        rays = 0.095,
        raySpread = 0.83,
        softness = 0.68,
        diffuse = 0.56,
        specular = 0.83,
        fogStart = 250,
        fogEnd = 4800,
        cloudCover = 0.2,
        cloudDensity = 0.35,
        horizonGlow = 0.25,
        rayLength = 6.2
    }),
    Sunset = palette({
        ambient = C(105, 77, 97),
        outdoor = C(179, 122, 104),
        shadow = C(57, 40, 75),
        tint = C(255, 219, 191),
        horizon = C(255, 124, 54),
        lowerSky = C(231, 113, 155),
        zenith = C(110, 77, 163),
        atmosphere = C(240, 159, 122),
        decay = C(123, 74, 137),
        sunColor = C(255, 127, 34),
        cloudColor = C(231, 150, 152),
        brightness = 2.05,
        exposure = -0.015,
        density = 0.245,
        haze = 2.25,
        glare = 0.42,
        contrast = 0.095,
        saturation = 0.1,
        bloom = 0.36,
        bloomSize = 42,
        bloomThreshold = 1.08,
        rays = 0.105,
        raySpread = 0.88,
        softness = 0.62,
        diffuse = 0.5,
        specular = 0.74,
        fogStart = 220,
        fogEnd = 4600,
        cloudCover = 0.16,
        cloudDensity = 0.32,
        horizonGlow = 0.34,
        rayLength = 7.3
    }),
    Twilight = palette({
        ambient = C(59, 59, 93),
        outdoor = C(84, 83, 132),
        shadow = C(27, 28, 55),
        tint = C(215, 216, 250),
        horizon = C(195, 108, 144),
        lowerSky = C(119, 91, 158),
        zenith = C(43, 57, 112),
        atmosphere = C(130, 124, 177),
        decay = C(57, 57, 104),
        sunColor = C(255, 112, 52),
        cloudColor = C(114, 103, 146),
        brightness = 0.85,
        exposure = -0.12,
        density = 0.23,
        haze = 1.5,
        glare = 0.04,
        contrast = 0.08,
        saturation = 0.015,
        bloom = 0.19,
        rays = 0,
        softness = 0.5,
        diffuse = 0.44,
        specular = 0.55,
        sunVisibility = 0,
        moonVisibility = 0.65,
        stars = 0.45,
        horizonGlow = 0.18,
        warmthWeight = 0.3,
        night = 0.65,
        fogEnd = 4600
    }),
    Night = palette({
        ambient = C(37, 45, 72),
        outdoor = C(63, 77, 109),
        shadow = C(15, 21, 41),
        tint = C(216, 229, 255),
        horizon = C(61, 79, 133),
        lowerSky = C(34, 45, 91),
        zenith = C(14, 23, 55),
        atmosphere = C(105, 129, 178),
        decay = C(34, 45, 83),
        cloudColor = C(86, 101, 132),
        brightness = 0.8,
        exposure = -0.14,
        density = 0.205,
        haze = 0.85,
        glare = 0,
        contrast = 0.075,
        saturation = -0.035,
        bloom = 0.18,
        bloomSize = 25,
        rays = 0,
        softness = 0.46,
        diffuse = 0.38,
        specular = 0.55,
        fogStart = 300,
        fogEnd = 5200,
        cloudCover = 0.1,
        cloudDensity = 0.25,
        sunVisibility = 0,
        moonVisibility = 1,
        stars = 1,
        horizonGlow = 0.045,
        warmthWeight = 0.07,
        night = 1
    }),
    Moonlight = palette({
        ambient = C(20, 29, 49),
        outdoor = C(52, 70, 103),
        shadow = C(9, 15, 31),
        tint = C(200, 223, 255),
        horizon = C(65, 87, 134),
        lowerSky = C(26, 43, 84),
        zenith = C(9, 17, 43),
        atmosphere = C(117, 144, 187),
        decay = C(29, 44, 83),
        moonColor = C(207, 231, 255),
        cloudColor = C(69, 88, 121),
        brightness = 1.12,
        exposure = -0.22,
        density = 0.235,
        haze = 1.25,
        glare = 0,
        contrast = 0.13,
        saturation = -0.075,
        bloom = 0.26,
        bloomSize = 36,
        bloomThreshold = 1.04,
        rays = 0,
        softness = 0.35,
        diffuse = 0.3,
        specular = 0.74,
        fogStart = 210,
        fogEnd = 4200,
        cloudCover = 0.08,
        cloudDensity = 0.24,
        sunVisibility = 0,
        moonVisibility = 1,
        stars = 1,
        horizonGlow = 0.075,
        warmthWeight = 0.025,
        night = 1
    }),
    Overcast = palette({
        ambient = C(120, 132, 145),
        outdoor = C(148, 159, 173),
        shadow = C(100, 111, 126),
        tint = C(227, 236, 243),
        horizon = C(161, 177, 190),
        lowerSky = C(132, 150, 169),
        zenith = C(102, 121, 145),
        atmosphere = C(182, 195, 206),
        decay = C(123, 142, 160),
        cloudColor = C(169, 179, 190),
        brightness = 0.45,
        exposure = 0.06,
        density = 0.29,
        haze = 1.7,
        glare = 0,
        contrast = -0.055,
        saturation = -0.21,
        bloom = 0.07,
        bloomSize = 20,
        bloomThreshold = 1.4,
        rays = 0.001,
        raySpread = 0.25,
        softness = 1,
        diffuse = 0.72,
        specular = 0.32,
        fogStart = 160,
        fogEnd = 3400,
        cloudCover = 0.96,
        cloudDensity = 0.9,
        sunVisibility = 0.075,
        moonVisibility = 0,
        stars = 0,
        horizonGlow = 0.035,
        warmthWeight = 0.18
    }),
    Storm = palette({
        ambient = C(22, 32, 53),
        outdoor = C(52, 70, 98),
        shadow = C(9, 15, 31),
        tint = C(191, 212, 247),
        horizon = C(108, 139, 186),
        lowerSky = C(37, 58, 96),
        zenith = C(12, 24, 47),
        atmosphere = C(80, 106, 150),
        decay = C(22, 39, 72),
        cloudColor = C(28, 42, 65),
        brightness = 0.22,
        exposure = -0.28,
        density = 0.33,
        haze = 2.8,
        glare = 0,
        contrast = 0.22,
        saturation = -0.32,
        bloom = 0.14,
        bloomSize = 30,
        bloomThreshold = 1.15,
        rays = 0,
        raySpread = 0.25,
        softness = 0.34,
        diffuse = 0.3,
        specular = 0.92,
        fogStart = 75,
        fogEnd = 2100,
        cloudCover = 0.99,
        cloudDensity = 1,
        sunVisibility = 0,
        moonVisibility = 0,
        stars = 0,
        horizonGlow = 0.16,
        warmthWeight = 0,
        night = 0.85
    })
}

local cycleStops = {
    {0, "Night"},
    {4.5, "Night"},
    {5.55, "Twilight"},
    {6.5, "Dawn"},
    {8.2, "Day"},
    {15.2, "Day"},
    {16.65, "GoldenHour"},
    {17.6, "Sunset"},
    {18.55, "Twilight"},
    {20.2, "Night"},
    {24, "Night"}
}

local function colorState(clock)
    clock %= 24
    for index = 1, #cycleStops - 1 do
        local a = cycleStops[index]
        local b = cycleStops[index + 1]
        if clock >= a[1] and clock <= b[1] then
            local t = smooth((clock - a[1]) / (b[1] - a[1]))
            local first = palettes[a[2]]
            local second = palettes[b[2]]
            local result = {}
            for key, value in pairs(first) do
                if typeof(value) == "Color3" then
                    result[key] = lerp(value, second[key], t)
                else
                    result[key] = value + (second[key] - value) * t
                end
            end
            return result
        end
    end
    return deepCopy(palettes.Night)
end

local function getClock(cfg)
    local mode = modeLookup[cfg and cfg.Mode] and cfg.Mode or "Cycle"
    local options = getModeOptions(cfg, mode)

    if mode == "Cycle" then
        return modeClock % 24
    elseif mode == "Day" then
        local middle = (options.MinTime + options.MaxTime) * 0.5
        return middle + (options.MaxTime - options.MinTime) * 0.5 * math.sin(dayPhase * math.pi * 2)
    elseif mode == "Night" then
        return (options.CenterTime + options.TimeSwing * math.sin(nightPhase * math.pi * 2)) % 24
    end

    return options.ClockTime % 24
end

local function getState(cfg)
    local state
    if cfg.Mode == "Cycle" then
        state = colorState(currentClock)
    else
        state = deepCopy(palettes[cfg.Mode] or palettes.Day)
    end

    local options = getModeOptions(cfg)
    local modifiers = getModifiers(cfg)

    if options.CloudCover then
        state.cloudCover = options.CloudCover
        state.cloudDensity = options.CloudDensity
    end

    local cloudAmount = modifiers.Cloudy and 0.42 or 0

    if modifiers.Rain then
        cloudAmount = math.max(cloudAmount, 0.25)
        state.specular = math.max(state.specular, 0.87)
        state.haze += 0.2
    end

    if cloudAmount > 0 then
        if cfg.Mode ~= "Storm" then
            local dim = 1 - state.night * 0.65
            state.ambient = lerp(state.ambient, C(111, 123, 142), cloudAmount * dim)
            state.outdoor = lerp(state.outdoor, C(133, 145, 163), cloudAmount * dim)
            state.tint = lerp(state.tint, C(220, 233, 244), cloudAmount)
            state.atmosphere = lerp(state.atmosphere, C(154, 173, 193), cloudAmount * 0.7)
            state.softness = math.max(state.softness, 0.68)
        end

        state.brightness *= 1 - cloudAmount * 0.55
        state.sunVisibility *= 1 - cloudAmount * 0.8
        state.rays *= math.max(0, 1 - cloudAmount * 1.4)
        state.stars *= math.max(0, 1 - cloudAmount * 1.1)
        state.cloudCover = math.max(state.cloudCover, modifiers.Cloudy and 0.76 or 0.55)
        state.cloudDensity = math.max(state.cloudDensity, modifiers.Cloudy and 0.7 or 0.55)
        state.density += cloudAmount * 0.045
    end

    if modifiers.Snow then
        state.tint = lerp(state.tint, C(224, 239, 255), cfg.Mode == "Storm" and 0.04 or 0.15)
        state.density += 0.018
        state.haze += 0.15
        state.cloudCover = math.max(state.cloudCover, 0.38)
    end

    if modifiers.FireRain then
        state.tint = lerp(state.tint, C(255, 216, 194), cfg.Mode == "Storm" and 0.05 or 0.12)
        state.horizon = lerp(state.horizon, C(225, 97, 60), cfg.Mode == "Storm" and 0.08 or 0.18)
    end

    for key, value in pairs(state) do
        if typeof(value) == "Color3" then
            state[key] = noGreen(value)
        end
    end

    return state
end

local function resetTime(cfg)
    local cycleOptions = getModeOptions(cfg, "Cycle")
    modeClock = finite(cycleOptions.StartTime) and cycleOptions.StartTime or DEFAULTS.ModeSettings.Cycle.StartTime
    dayPhase = 0
    nightPhase = 0
    currentClock = getClock(cfg)
    lastMode = cfg.Mode
    lightningAge = -1
    lightningFlash = 0
    lightningSignature = nil

    local stormOptions = cfg.ModeSettings and cfg.ModeSettings.Storm

    if type(stormOptions) == "table" then
        local minimum = finite(stormOptions.LightningMinSeconds) and math.max(5, stormOptions.LightningMinSeconds) or 5
        local maximum = finite(stormOptions.LightningMaxSeconds) and math.max(minimum, stormOptions.LightningMaxSeconds) or math.max(minimum, 24)
        lightningTimer = random:NextNumber(minimum, maximum)
    else
        lightningTimer = 12
    end
end

local function advanceTime(dt, cfg)
    if cfg.Mode == "Cycle" then
        local ratio = cfg.DayLengthSeconds / (cfg.DayLengthSeconds + cfg.NightLengthSeconds)
        local remaining = dt

        while remaining > 0.00001 do
            local t = modeClock % 24
            local daylight = t >= 6 and t < 18
            local duration = cfg.CycleLengthSeconds * (daylight and ratio or 1 - ratio)
            local rate = 12 / math.max(duration, 1)
            local boundary = t < 6 and 6 or t < 18 and 18 or 24
            local needed = (boundary - t) / rate

            if remaining < needed then
                modeClock = t + remaining * rate
                remaining = 0
            else
                modeClock = boundary % 24
                remaining -= needed
            end
        end
    elseif cfg.Mode == "Day" then
        dayPhase = (dayPhase + dt / cfg.DayLengthSeconds) % 1
    elseif cfg.Mode == "Night" then
        nightPhase = (nightPhase + dt / cfg.NightLengthSeconds) % 1
    end

    currentClock = getClock(cfg)
end

local function makeWorldPart(name, parent, material)
    return make("Part", {
        Name = name,
        Anchored = true,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        CastShadow = false,
        Material = material or Enum.Material.Neon,
        Transparency = 1,
        Size = Vector3.one
    }, parent)
end

local function makeEffect(className, name)
    local record = {
        className = className,
        name = name,
        object = nil,
        properties = {}
    }
    effectRecords[#effectRecords + 1] = record
    return record
end

local atmosphereRecord
local colorRecord
local bloomRecord
local raysRecord
local dofRecord
local skySuppressorRecord
local function ensureRecord(record)
    local object = record.object

    if object and object.Parent == Lighting then
        return object
    end

    if object then
        local ok = pcall(function()
            object.Parent = Lighting
        end)
        if ok and object.Parent == Lighting then
            return object
        end
    end

    object = Instance.new(record.className)
    object.Name = record.name
    owned[object] = true
    object.Parent = Lighting
    record.object = object

    connect(object.Changed, function()
        if initialized and not applying and getConfig().LockLighting then
            repairQueued = true
        end
    end, runtimeConnections)

    return object
end

local function manageForeignObjects(cfg)
    for _, child in ipairs(Lighting:GetChildren()) do
        if not owned[child] then
            if child:IsA("Sky") then
                if not displacedSkyObjects[child] then
                    displacedSkyObjects[child] = Lighting
                end
                pcall(function()
                    child.Parent = nil
                end)
            elseif child:IsA("Atmosphere") then
                if not displacedObjects[child] then
                    displacedObjects[child] = Lighting
                end
                child.Parent = nil
            elseif child:IsA("PostEffect") and cfg.DisableOtherPostEffects then
                if disabledPostEffects[child] == nil then
                    disabledPostEffects[child] = child.Enabled
                end
                child.Enabled = false
            end
        end
    end

    if not cfg.DisableOtherPostEffects then
        for object, enabled in pairs(disabledPostEffects) do
            pcall(function()
                object.Enabled = enabled
            end)
            disabledPostEffects[object] = nil
        end
    end

    local modifiers = getModifiers(cfg)
    local hideClouds = cfg.HideOtherClouds
        or cfg.Mode == "Overcast"
        or cfg.Mode == "Storm"
        or modifiers.Cloudy

    local terrain = workspace:FindFirstChildOfClass("Terrain")

    if terrain and hideClouds then
        for _, object in ipairs(terrain:GetChildren()) do
            if object:IsA("Clouds") and object ~= cloudObject and not owned[object] then
                if disabledCloudObjects[object] == nil then
                    disabledCloudObjects[object] = object.Enabled
                end
                object.Enabled = false
            end
        end
    elseif not hideClouds then
        for object, enabled in pairs(disabledCloudObjects) do
            pcall(function()
                object.Enabled = enabled
            end)
            disabledCloudObjects[object] = nil
        end
    end
end

local function createCelestial(kind)
    local model = make("Model", {Name = "KOOL_VFX_" .. kind}, celestialFolder)
    local result = {
        model = model,
        body = nil,
        halos = {},
        craters = {},
        rays = {}
    }

    if kind == "Moon" then
        local body = makeWorldPart("MoonBody", model)
        body.Shape = Enum.PartType.Ball
        result.body = body

        for index = 1, 4 do
            local halo = makeWorldPart("MoonHalo" .. index, model)
            halo.Shape = Enum.PartType.Ball
            result.halos[index] = halo
        end

        local craterData = {
            {-0.31, 0.31, 0.2},
            {0.3, 0.17, 0.16},
            {0.13, -0.35, 0.14},
            {-0.39, -0.26, 0.12},
            {0.48, -0.27, 0.09},
            {0.13, 0.56, 0.085},
            {-0.04, 0.04, 0.11},
            {-0.61, 0.04, 0.07},
            {0.57, 0.35, 0.065},
            {-0.22, -0.6, 0.06}
        }

        for index, data in ipairs(craterData) do
            local rim = makeWorldPart("CraterRim" .. index, model)
            rim.Shape = Enum.PartType.Ball

            local inset = makeWorldPart("Crater" .. index, model)
            inset.Shape = Enum.PartType.Ball

            result.craters[index] = {
                rim = rim,
                inset = inset,
                data = data
            }
        end
    else
        local body = makeWorldPart("SunBody", model, Enum.Material.Neon)
        body.Shape = Enum.PartType.Ball
        result.body = body
    end

    return result
end

local function createCelestials()
    if celestialFolder then
        owned[celestialFolder] = nil
        pcall(function()
            celestialFolder:Destroy()
        end)
        celestialFolder = nil
    end

    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "KOOL_VFX_Celestials"
            or child.Name == "KOOL_VFX_Sun"
            or child.Name == "KOOL_VFX_Moon" then
            pcall(function()
                child:Destroy()
            end)
        end
    end

    celestialFolder = make("Folder", {Name = "KOOL_VFX_Celestials"}, workspace)
    owned[celestialFolder] = true

    sun = createCelestial("Sun")
    moon = createCelestial("Moon")

    table.clear(stars)
    geometrySignature = nil

    local seeded = Random.new(871263)
    local starFolder = make("Folder", {Name = "WorldStars"}, celestialFolder)

    for index = 1, 180 do
        local azimuth = seeded:NextNumber(0, math.pi * 2)
        local y = seeded:NextNumber(0.1, 0.995)
        local horizontal = math.sqrt(1 - y * y)
        local part = makeWorldPart("Star" .. index, starFolder)

        part.Shape = Enum.PartType.Ball
        part.Color = lerp(C(181, 210, 255), C(255, 247, 220), seeded:NextNumber())

        stars[index] = {
            part = part,
            direction = Vector3.new(math.cos(azimuth) * horizontal, y, math.sin(azimuth) * horizontal),
            size = seeded:NextNumber(0.00075, 0.0016),
            visibility = seeded:NextNumber(0.65, 1),
            phase = seeded:NextNumber(0, math.pi * 2)
        }
    end

end

local function rebuildClouds()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then
        return
    end

    if cloudObject and cloudObject.Parent == terrain then
        return
    end

    if cloudObject then
        owned[cloudObject] = nil
        pcall(function()
            cloudObject:Destroy()
        end)
    end

    cloudObject = make("Clouds", {
        Name = "KOOL_VFX_Clouds",
        Enabled = true,
        Cover = 0.18,
        Density = 0.32,
        Color = C(229, 236, 246)
    }, terrain)

    owned[cloudObject] = true
end

local function updateClouds(state)
    rebuildClouds()
    if cloudObject then
        writeProperties(cloudObject, {
            Enabled = state.cloudCover > 0,
            Cover = math.clamp(state.cloudCover, 0, 1),
            Density = math.clamp(state.cloudDensity, 0, 1),
            Color = lerp(state.cloudColor, C(201, 220, 255), lightningFlash * 0.62)
        })
    end
end

local function getWeatherCenter()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.CFrame.Position + weatherCenterOffset
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        return root.Position + weatherCenterOffset
    end

    return weatherCenter or weatherCenterOffset
end

local function wrapAxis(value, center, halfSize, size)
    if value < center - halfSize or value >= center + halfSize then
        return center + ((value - center + halfSize) % size) - halfSize
    end
    return value
end

local function wrapWorldPosition(position, center)
    return Vector3.new(
        wrapAxis(position.X, center.X, weatherHalfSize.X, weatherBoxSize.X),
        wrapAxis(position.Y, center.Y, weatherHalfSize.Y, weatherBoxSize.Y),
        wrapAxis(position.Z, center.Z, weatherHalfSize.Z, weatherBoxSize.Z)
    )
end

local function makeWeatherDrop(kind, index, cfg)
    local part = makeWorldPart(
        "KOOL_VFX_" .. kind,
        weatherFolder,
        kind == "FireRain" and Enum.Material.Neon or Enum.Material.SmoothPlastic
    )

    part.Shape = (kind == "Snow" or kind == "StarFall") and Enum.PartType.Ball or Enum.PartType.Block

    local width
    local length
    local baseSpeed
    local variance

    if kind == "Snow" then
        width = math.clamp(cfg.SnowSize, 0.08, 0.5)
        length = width * 0.79
        baseSpeed = math.clamp(cfg.SnowFallSpeed, 1, 250)
        variance = math.clamp(cfg.SnowFallSpeedVariance, 0, 100)
    elseif kind == "StarFall" then
        width = math.clamp(cfg.StarFallSize, 0.08, 0.5)
        length = math.clamp(cfg.StarTailLength, 0.3, 8)
        baseSpeed = math.clamp(cfg.StarFallSpeed, 1, 250)
        variance = math.clamp(cfg.StarFallSpeedVariance, 0, 100)
    elseif kind == "FireRain" then
        width = math.clamp(cfg.FireRainSizeWidth, 0.03, 0.5)
        length = math.clamp(cfg.FireRainSizeLength, 0.3, 8)
        baseSpeed = math.clamp(cfg.FireRainFallSpeed, 1, 250)
        variance = math.clamp(cfg.FireRainFallSpeedVariance, 0, 100)
    else
        width = math.clamp(cfg.RainSizeWidth, 0.03, 0.5)
        length = math.clamp(cfg.RainSizeLength, 0.3, 8)
        baseSpeed = math.clamp(cfg.RainFallSpeed, 1, 250)
        variance = math.clamp(cfg.RainFallSpeedVariance, 0, 100)
    end

    part.Size = kind == "Snow" and Vector3.new(width, length, width)
        or kind == "StarFall" and Vector3.new(width, width, width)
        or Vector3.new(width, length, width)

    local speedFactor = random:NextNumber(-1, 1)
    local speed = math.clamp(
        baseSpeed + speedFactor * variance,
        1,
        250
    )

    local worldPos = weatherCenter + Vector3.new(
        random:NextNumber(-weatherHalfSize.X, weatherHalfSize.X),
        random:NextNumber(-weatherHalfSize.Y, weatherHalfSize.Y),
        random:NextNumber(-weatherHalfSize.Z, weatherHalfSize.Z)
    )

    local velocity = Vector3.new(0, -speed, 0)

    local alpha = 0.65 + cfg.VFXIntensity * 0.35

    part.Position = worldPos
    part.Color = kind == "Snow" and C(241, 248, 255)
        or kind == "FireRain" and C(255, 130, 45)
        or kind == "StarFall" and C(255, 229, 142)
        or C(199, 221, 255)

    part.Transparency = 1 - (kind == "Snow" and 0.9 or kind == "FireRain" and 0.85 or kind == "StarFall" and 0.92 or 0.72) * alpha

    local light
    local tailA
    local tailB
    local sparkleA
    local sparkleB
    if kind == "StarFall" then
        part.Material = Enum.Material.Neon
        tailA = makeWorldPart("StarTailA", weatherFolder, Enum.Material.Neon)
        tailA.Shape = Enum.PartType.Block
        tailB = makeWorldPart("StarTailB", weatherFolder, Enum.Material.Neon)
        tailB.Shape = Enum.PartType.Block
        sparkleA = makeWorldPart("StarSparkA", weatherFolder, Enum.Material.Neon)
        sparkleA.Shape = Enum.PartType.Block
        sparkleB = makeWorldPart("StarSparkB", weatherFolder, Enum.Material.Neon)
        sparkleB.Shape = Enum.PartType.Block
    end

    if kind == "FireRain" and index <= 12 then
        light = make("PointLight", {
            Color = C(255, 119, 49),
            Range = 8,
            Brightness = 0.6 * alpha,
            Shadows = false
        }, part)
    elseif kind == "StarFall" and index <= 18 then
        light = make("PointLight", {
            Color = C(255, 215, 120),
            Range = 10,
            Brightness = 0.95 * alpha,
            Shadows = false
        }, part)
    end

    return {
        part = part,
        light = light,
        tailA = tailA,
        tailB = tailB,
        sparkleA = sparkleA,
        sparkleB = sparkleB,
        kind = kind,
        worldPos = worldPos,
        velocity = velocity,
        seed = random:NextNumber(0, math.pi * 2),
        speed = speed,
        baseSpeed = baseSpeed,
        speedVariance = variance,
        speedFactor = speedFactor,
        width = width,
        length = length
    }
end

local function rebuildWeather(cfg)
    if weatherFolder then
        owned[weatherFolder] = nil
        weatherFolder:Destroy()
    end

    table.clear(drops)

    weatherFolder = make("Folder", {Name = "KOOL_VFX_Weather"}, workspace)
    owned[weatherFolder] = true
    weatherCenter = getWeatherCenter()

    local modifiers = getModifiers(cfg)
    local maxParts = math.floor(math.clamp(
        finite(cfg.MaxWeatherParts) and cfg.MaxWeatherParts or 480,
        100,
        800
    ) + 0.5)

    local densityScale = math.clamp(cfg.WeatherDensity, 0, 1.5) * (0.65 + cfg.VFXIntensity * 0.35)
    local kinds = {
        {name = "Rain", base = 220, cost = 1},
        {name = "Snow", base = 150, cost = 1},
        {name = "FireRain", base = 110, cost = 1.15},
        {name = "StarFall", base = 72, cost = 5}
    }

    local totalCost = 0
    for _, info in ipairs(kinds) do
        if modifiers[info.name] and densityScale > 0.0001 then
            info.desired = math.max(1, math.floor(info.base * densityScale + 0.5))
            totalCost += info.desired * info.cost
        else
            info.desired = 0
        end
    end

    local scale = totalCost > maxParts and (maxParts / totalCost) or 1

    for _, info in ipairs(kinds) do
        if info.desired > 0 then
            local count = math.max(1, math.floor(info.desired * scale + 0.5))
            for index = 1, count do
                drops[#drops + 1] = makeWeatherDrop(info.name, index, cfg)
            end
        end
    end
end

local function ensureWeather(cfg)
    local modifiers = getModifiers(cfg)
    local signature = table.concat({
        tostring(modifiers.Rain),
        tostring(modifiers.Snow),
        tostring(modifiers.FireRain),
        tostring(modifiers.StarFall),
        tostring(math.floor(math.clamp(cfg.WeatherDensity, 0, 1.5) * 10 + 0.5)),
        string.format("%.1f", cfg.VFXIntensity),
        tostring(math.floor(math.clamp(cfg.MaxWeatherParts or 480, 100, 800) + 0.5))
    }, "|")

    if signature ~= weatherSignature or not weatherFolder or not weatherFolder.Parent then
        weatherSignature = signature
        rebuildWeather(cfg)
    end
end

local function updateWeather(dt, cfg)
    if not weatherFolder or not weatherFolder.Parent or #drops == 0 then
        return
    end

    local nextCenter = getWeatherCenter()
    local previousCenter = weatherCenter or nextCenter
    local envelopeMovement = nextCenter - previousCenter

    local teleported = math.abs(envelopeMovement.X) > weatherHalfSize.X * 1.5
        or math.abs(envelopeMovement.Z) > weatherHalfSize.Z * 1.5
        or math.abs(envelopeMovement.Y) > weatherHalfSize.Y * 1.5

    weatherCenter = nextCenter

    local now = os.clock()
    local alpha = 0.65 + cfg.VFXIntensity * 0.35

    for _, drop in ipairs(drops) do
        local part = drop.part

        if part and part.Parent then
            if teleported then
                drop.worldPos += envelopeMovement
            end

            local currentWidth
            local currentLength
            local currentBaseSpeed
            local currentVariance

            if drop.kind == "Snow" then
                currentWidth = math.clamp(cfg.SnowSize, 0.08, 0.5)
                currentLength = currentWidth * 0.79
                currentBaseSpeed = math.clamp(cfg.SnowFallSpeed, 1, 250)
                currentVariance = math.clamp(cfg.SnowFallSpeedVariance, 0, 100)
            elseif drop.kind == "StarFall" then
                currentWidth = math.clamp(cfg.StarFallSize, 0.08, 0.5)
                currentLength = math.clamp(cfg.StarTailLength, 0.3, 8)
                currentBaseSpeed = math.clamp(cfg.StarFallSpeed, 1, 250)
                currentVariance = math.clamp(cfg.StarFallSpeedVariance, 0, 100)
            elseif drop.kind == "FireRain" then
                currentWidth = math.clamp(cfg.FireRainSizeWidth, 0.03, 0.5)
                currentLength = math.clamp(cfg.FireRainSizeLength, 0.3, 8)
                currentBaseSpeed = math.clamp(cfg.FireRainFallSpeed, 1, 250)
                currentVariance = math.clamp(cfg.FireRainFallSpeedVariance, 0, 100)
            else
                currentWidth = math.clamp(cfg.RainSizeWidth, 0.03, 0.5)
                currentLength = math.clamp(cfg.RainSizeLength, 0.3, 8)
                currentBaseSpeed = math.clamp(cfg.RainFallSpeed, 1, 250)
                currentVariance = math.clamp(cfg.RainFallSpeedVariance, 0, 100)
            end

            drop.width = currentWidth
            drop.length = currentLength
            drop.baseSpeed = currentBaseSpeed
            drop.speedVariance = currentVariance
            drop.speed = math.clamp(
                currentBaseSpeed + drop.speedFactor * currentVariance,
                1,
                250
            )

            part.Size = drop.kind == "StarFall" and Vector3.new(currentWidth, currentWidth, currentWidth) or Vector3.new(currentWidth, currentLength, currentWidth)

            local windStrength = math.clamp(
                finite(cfg.WindStrength) and cfg.WindStrength or 0,
                0,
                30
            )
            local windAngle = math.rad(
                finite(cfg.WindDirectionDegrees) and cfg.WindDirectionDegrees or 0
            )
            local gust = 0.72
                + 0.18 * math.sin(now * 0.55 + drop.seed)
                + 0.10 * math.sin(now * 1.37 + drop.seed * 0.43)
            local wind = Vector3.new(
                math.cos(windAngle) * windStrength * gust,
                0,
                math.sin(windAngle) * windStrength * gust
            )

            local velocity

            if drop.kind == "Snow" then
                velocity = Vector3.new(
                    math.sin(now * 0.8 + drop.seed) * 0.65,
                    -drop.speed,
                    math.cos(now * 0.65 + drop.seed) * 0.45
                ) + wind * 0.62
            elseif drop.kind == "StarFall" then
                velocity = Vector3.new(
                    math.sin(now * 1.6 + drop.seed) * 2.2,
                    -drop.speed,
                    math.cos(now * 1.2 + drop.seed) * 1.7
                ) + wind * 1.28
            elseif drop.kind == "FireRain" then
                velocity = Vector3.new(0, -drop.speed, 0) + wind * 1.12
            else
                velocity = Vector3.new(0, -drop.speed, 0) + wind
            end

            drop.velocity = velocity
            drop.worldPos += velocity * dt
            drop.worldPos = wrapWorldPosition(drop.worldPos, weatherCenter)

            if drop.kind == "Snow" then
                part.Color = C(241, 248, 255)
                part.Transparency = 1 - 0.9 * alpha
                part.Position = drop.worldPos
            elseif drop.kind == "StarFall" then
                local shimmer = 0.5 + 0.5 * math.sin(now * 8 + drop.seed)
                local tailDirection = drop.velocity.Magnitude > 0.05 and (-drop.velocity.Unit) or Vector3.yAxis
                local tailLength = math.max(0.45, currentLength)
                part.Color = lerp(C(255, 214, 110), C(255, 244, 196), shimmer * 0.55)
                part.Transparency = 1 - 0.93 * alpha
                part.Position = drop.worldPos

                local sparkleScale = currentWidth * (2.6 + shimmer * 0.55)
                local sparkleThickness = math.max(0.035, currentWidth * 0.28)
                if drop.sparkleA and drop.sparkleA.Parent then
                    drop.sparkleA.Color = part.Color
                    drop.sparkleA.Transparency = 0.08 + (1 - alpha) * 0.25
                    drop.sparkleA.Size = Vector3.new(sparkleThickness, sparkleScale, sparkleThickness)
                    drop.sparkleA.CFrame = CFrame.new(drop.worldPos) * CFrame.Angles(0, 0, math.rad(45 + math.sin(now * 1.8 + drop.seed) * 8))
                end

                if drop.sparkleB and drop.sparkleB.Parent then
                    drop.sparkleB.Color = lerp(part.Color, C(255, 249, 224), 0.35)
                    drop.sparkleB.Transparency = 0.16 + (1 - alpha) * 0.25
                    drop.sparkleB.Size = Vector3.new(sparkleScale * 0.72, sparkleThickness, sparkleThickness)
                    drop.sparkleB.CFrame = CFrame.new(drop.worldPos) * CFrame.Angles(0, 0, math.rad(-45 - math.cos(now * 1.55 + drop.seed) * 8))
                end

                if drop.tailA and drop.tailA.Parent then
                    drop.tailA.Color = lerp(C(255, 210, 118), C(255, 244, 198), shimmer * 0.35)
                    drop.tailA.Transparency = 0.22
                    drop.tailA.Size = Vector3.new(math.max(0.05, currentWidth * 0.78), math.max(0.05, currentWidth * 0.78), tailLength * 0.9)
                    local centerA = drop.worldPos + tailDirection * (tailLength * 0.42)
                    drop.tailA.CFrame = CFrame.lookAt(centerA, drop.worldPos)
                end

                if drop.tailB and drop.tailB.Parent then
                    drop.tailB.Color = lerp(C(255, 231, 164), C(255, 248, 222), shimmer * 0.25)
                    drop.tailB.Transparency = 0.48
                    drop.tailB.Size = Vector3.new(math.max(0.04, currentWidth * 0.52), math.max(0.04, currentWidth * 0.52), tailLength * 1.32)
                    local centerB = drop.worldPos + tailDirection * (tailLength * 0.95)
                    drop.tailB.CFrame = CFrame.lookAt(centerB, drop.worldPos)
                end

                if drop.light then
                    drop.light.Color = part.Color
                    drop.light.Brightness = (0.85 + shimmer * 0.45) * alpha
                end
            elseif drop.kind == "FireRain" then
                part.Color = C(255, 119 + math.floor(math.sin(now * 6 + drop.seed) * 24), 45)
                part.Transparency = 1 - 0.85 * alpha
                part.CFrame = CFrame.new(drop.worldPos) * CFrame.Angles(0, 0, math.rad(7))

                if drop.light then
                    drop.light.Brightness = (0.65 + math.sin(now * 7 + drop.seed) * 0.2) * alpha
                end
            else
                part.Color = cfg.Mode == "Storm"
                    and lerp(C(169, 198, 237), C(232, 243, 255), lightningFlash * 0.65)
                    or C(199, 221, 255)

                part.Transparency = 1 - 0.72 * alpha
                part.CFrame = CFrame.new(drop.worldPos) * CFrame.Angles(0, 0, math.rad(1.7))
            end
        end
    end
end

local function clearThunderQueue()
    table.clear(thunderQueue)

    for _, sound in ipairs(thunderSounds) do
        pcall(function()
            sound:Stop()
        end)
    end
end

local function ensureThunderPool()
    if #thunderSounds > 0 then
        return
    end

    for index = 1, 3 do
        local sound = make("Sound", {
            Name = "KOOL_VFX_Thunder" .. index,
            Volume = 0,
            PlaybackSpeed = 1,
            Looped = false
        }, SoundService)

        owned[sound] = true
        thunderSounds[index] = sound
    end
end

local function queueThunder(cfg, strikeStrength, delaySeconds)
    local ids = cfg and cfg.ThunderSoundIds

    if type(ids) ~= "table" or #ids == 0 then
        return
    end

    thunderQueue[#thunderQueue + 1] = {
        at = os.clock() + math.clamp(delaySeconds or 0.25, 0.05, 1.5),
        strength = math.clamp(strikeStrength or 1, 0.2, 1.3)
    }
end

local function processThunderQueue(cfg)
    if #thunderQueue == 0 then
        return
    end

    local now = os.clock()
    local ids = cfg and cfg.ThunderSoundIds

    if type(ids) ~= "table" or #ids == 0 then
        table.clear(thunderQueue)
        return
    end

    ensureThunderPool()

    for index = #thunderQueue, 1, -1 do
        local event = thunderQueue[index]

        if now >= event.at then
            table.remove(thunderQueue, index)

            local assetId = ids[random:NextInteger(1, #ids)]
            if type(assetId) == "number" or type(assetId) == "string" then
                thunderPoolIndex = thunderPoolIndex % #thunderSounds + 1
                local sound = thunderSounds[thunderPoolIndex]
                local intensity = finite(cfg.VFXIntensity) and math.clamp(cfg.VFXIntensity, 0, 1) or 0.72
                local stormOptions = getModeOptions(cfg, "Storm")
                local lightningStrength = finite(stormOptions.LightningStrength)
                    and math.clamp(stormOptions.LightningStrength, 0, 1)
                    or 0.7
                local volume = (0.24 + event.strength * 0.42)
                    * (0.72 + lightningStrength * 0.28)
                    * (0.72 + intensity * 0.28)
                    * random:NextNumber(0.90, 1.04)

                pcall(function()
                    sound:Stop()
                    sound.SoundId = "rbxassetid://" .. tostring(assetId)
                    sound.Volume = math.clamp(volume, 0.08, 0.82)
                    sound.PlaybackSpeed = random:NextNumber(0.93, 1.07)
                    sound.TimePosition = 0
                    sound:Play()
                end)
            end
        end
    end
end

local function beginLightningStrike(cfg, force)
    local options = getModeOptions(cfg, "Storm")
    local strength = finite(options.LightningStrength)
        and math.clamp(options.LightningStrength, 0, 1)
        or DEFAULTS.ModeSettings.Storm.LightningStrength

    if options.Lightning ~= true or strength <= 0 then
        return false
    end

    local chance = finite(cfg.ThunderChance) and math.clamp(cfg.ThunderChance, 0, 1) or 0.7
    if not force and random:NextNumber() > chance then
        return false
    end

    local roll = random:NextNumber()

    if roll < 0.16 then
        lightningPattern = "distant"
        lightningStrikeScale = random:NextNumber(0.48, 0.68)
    elseif roll < 0.38 then
        lightningPattern = "single"
        lightningStrikeScale = random:NextNumber(0.78, 0.96)
    elseif roll < 0.88 then
        lightningPattern = "double"
        lightningStrikeScale = random:NextNumber(0.88, 1.05)
    else
        lightningPattern = "strong"
        lightningStrikeScale = random:NextNumber(1.04, 1.18)
    end

    lightningAge = 0

    local delaySeconds
    if lightningPattern == "distant" then
        delaySeconds = random:NextNumber(0.55, 0.95)
    elseif lightningPattern == "strong" then
        delaySeconds = random:NextNumber(0.08, 0.28)
    else
        delaySeconds = random:NextNumber(0.16, 0.62)
    end

    queueThunder(cfg, lightningStrikeScale * strength, delaySeconds)
    return true
end

local function updateLightning(dt, cfg)
    local options = getModeOptions(cfg, "Storm")
    lightningFlash = 0

    if cfg.Mode ~= "Storm"
        or not options.Lightning
        or not finite(options.LightningStrength)
        or options.LightningStrength <= 0 then
        lightningAge = -1
        lightningSignature = nil
        clearThunderQueue()
        return
    end

    processThunderQueue(cfg)

    local minimum = math.max(5, finite(options.LightningMinSeconds) and options.LightningMinSeconds or 10)
    local maximum = math.max(minimum, finite(options.LightningMaxSeconds) and options.LightningMaxSeconds or 24)
    local thunderChance = finite(cfg.ThunderChance) and math.clamp(cfg.ThunderChance, 0, 1) or 0.7
    local signature = string.format("%.3f|%.3f|%.3f", minimum, maximum, thunderChance)

    if signature ~= lightningSignature then
        lightningSignature = signature
        lightningTimer = random:NextNumber(minimum, maximum)
    end

    lightningTimer -= dt

    if lightningTimer <= 0 and lightningAge < 0 then
        beginLightningStrike(cfg, false)
        lightningTimer = random:NextNumber(minimum, maximum)
    end

    if lightningAge >= 0 then
        local flash

        if lightningPattern == "single" then
            flash = math.clamp(1 - lightningAge / 0.16, 0, 1)
        elseif lightningPattern == "distant" then
            flash = math.clamp(1 - lightningAge / 0.24, 0, 1) * 0.72
        elseif lightningPattern == "strong" then
            local first = math.clamp(1 - lightningAge / 0.12, 0, 1)
            local second = math.max(0, 1 - math.abs(lightningAge - 0.20) / 0.085) * 0.82
            local third = math.max(0, 1 - math.abs(lightningAge - 0.34) / 0.10) * 0.48
            flash = math.max(first, second, third)
        else
            local first = math.clamp(1 - lightningAge / 0.14, 0, 1)
            local second = math.max(0, 1 - math.abs(lightningAge - 0.24) / 0.11) * 0.72
            flash = math.max(first, second)
        end

        lightningFlash = math.clamp(
            flash * options.LightningStrength * lightningStrikeScale,
            0,
            1.2
        )

        lightningAge += dt

        local duration = lightningPattern == "strong" and 0.52
            or lightningPattern == "double" and 0.42
            or lightningPattern == "distant" and 0.30
            or 0.22

        if lightningAge > duration then
            lightningAge = -1
        end
    end
end

local function getSunAppearance(cfg, state)
    local options = getModeOptions(cfg)
    local visible = cfg.Mode ~= "Storm"
        and cfg.Mode ~= "Night"
        and cfg.Mode ~= "Moonlight"
        and state.sunVisibility > 0.025

    if not visible then
        return false, 0
    end

    local angularSize = math.clamp(2.6 * (cfg.SunSize / 90) * options.SunScale, 0.7, 8)

    if cfg.Mode == "Overcast" then
        angularSize = math.clamp(angularSize * 0.42, 0.65, 1.6)
    elseif cfg.Mode == "Cycle" then
        angularSize *= 0.65 + 0.35 * math.clamp(state.sunVisibility, 0, 1)
    end

    local direction = Lighting:GetSunDirection()
    if direction.Y > 0 and (cfg.Mode == "Day" or cfg.Mode == "GoldenHour" or cfg.Mode == "Sunset") then
        local elevation = math.deg(math.asin(math.clamp(direction.Y, -1, 1)))
        angularSize = math.min(angularSize, math.max(0.65, elevation * 1.8))
    end

    return true, angularSize
end

local function updateLightingTargets()
    if not running() then
        return
    end

    local cfg = getConfig()
    local state = getState(cfg)
    local options = getModeOptions(cfg)
    local intensity = finite(cfg.VFXIntensity) and math.clamp(cfg.VFXIntensity, 0, 1) or DEFAULTS.VFXIntensity
    local effectScale = 0.25 + intensity * 0.75
    local warmth = (cfg.Warmth - 0.5) * state.warmthWeight
    local tint = state.tint

    if warmth >= 0 then
        tint = lerp(tint, C(255, 226, 193), warmth * 0.18)
    else
        tint = lerp(tint, C(211, 231, 255), -warmth * 0.2)
    end

    local ambient = state.ambient
    local outdoor = state.outdoor

    if warmth > 0 then
        ambient = lerp(ambient, C(171, 134, 111), warmth * 0.12)
        outdoor = lerp(outdoor, C(230, 184, 129), warmth * 0.14)
    end

    ambient = lerp(ambient, C(198, 217, 250), lightningFlash * 0.7)
    outdoor = lerp(outdoor, C(230, 240, 255), lightningFlash * 0.8)

    applying = true

    writeProperties(Lighting, {
        ClockTime = currentClock,
        GeographicLatitude = cfg.GeographicLatitude,
        Brightness = state.brightness * (0.94 + intensity * 0.1) + lightningFlash * 4,
        ExposureCompensation = state.exposure + lightningFlash * 0.4,
        Ambient = ambient,
        OutdoorAmbient = outdoor,
        ColorShift_Top = lerp(C(0, 0, 0), state.sunColor, state.sunVisibility * (0.12 + cfg.Warmth * 0.14)),
        ColorShift_Bottom = lerp(C(0, 0, 0), state.shadow, 0.2),
        GlobalShadows = true,
        ShadowSoftness = state.softness,
        EnvironmentDiffuseScale = state.diffuse,
        EnvironmentSpecularScale = state.specular,
        FogColor = state.horizon,
        FogStart = state.fogStart,
        FogEnd = state.fogEnd
    })

    local showSun, sunAngularSize = getSunAppearance(cfg, state)

    atmosphereRecord.properties = {
        Color = noGreen(state.atmosphere),
        Decay = noGreen(state.decay),
        Density = math.clamp(state.density * (0.82 + 0.18 * options.HazeStrength), 0.08, 0.37),
        Haze = math.clamp(state.haze * options.HazeStrength * (0.55 + intensity * 0.45), 0, 4),
        Glare = math.clamp(state.glare * options.GlowStrength * effectScale, 0, 0.65),
        Offset = 0.12
    }

    colorRecord.properties = {
        Enabled = true,
        Brightness = state.correctionBrightness,
        Contrast = math.clamp(state.contrast * (0.65 + intensity * 0.35), -0.1, 0.28),
        Saturation = math.clamp(state.saturation + warmth * 0.035, -0.45, 0.15),
        TintColor = noGreen(tint)
    }

    bloomRecord.properties = {
        Enabled = intensity > 0.001,
        Intensity = math.clamp(state.bloom * intensity * options.GlowStrength, 0, 0.65),
        Size = state.bloomSize,
        Threshold = state.bloomThreshold
    }

    raysRecord.properties = {
        Enabled = showSun and state.rays > 0.002 and state.sunVisibility > 0.1 and intensity > 0.001,
        Intensity = math.clamp(state.rays * intensity * options.GlowStrength, 0, 0.14),
        Spread = state.raySpread
    }

    dofRecord.properties = {
        Enabled = false,
        FarIntensity = 0,
        NearIntensity = 0,
        FocusDistance = 60,
        InFocusRadius = 60
    }

    skySuppressorRecord.properties = {
        CelestialBodiesShown = false,
        SkyboxBk = "",
        SkyboxDn = "",
        SkyboxFt = "",
        SkyboxLf = "",
        SkyboxRt = "",
        SkyboxUp = "",
        SunTextureId = "",
        MoonTextureId = "",
        SunAngularSize = 0,
        MoonAngularSize = 0,
        StarCount = 0
    }

    for _, record in ipairs(effectRecords) do
        writeProperties(ensureRecord(record), record.properties)
    end

    updateClouds(state)
    applying = false
    currentState = state
end

local function worldOrigin(cfg)
    local origin = cfg.CelestialOrigin
    return Vector3.new(origin.X, origin.Y, origin.Z)
end

local function aboveHorizon(direction, minimum)
    minimum = math.clamp(minimum, 0.025, 0.4)

    if direction.Y >= minimum then
        return direction
    end

    local flat = Vector3.new(direction.X, 0, direction.Z)
    if flat.Magnitude < 0.001 then
        flat = Vector3.new(-1, 0, 0)
    end

    return flat.Unit * math.sqrt(1 - minimum * minimum) + Vector3.yAxis * minimum
end

local function updateSkyGeometry(cfg, state)
    local origin = worldOrigin(cfg)
    local distance = cfg.CelestialDistance
    local signature = tostring(origin) .. "|" .. tostring(distance)

    if geometrySignature ~= signature then
        geometrySignature = signature

        for _, star in ipairs(stars) do
            star.part.Position = origin + star.direction * distance * 1.38
            local size = distance * star.size
            star.part.Size = Vector3.new(size, size, size)
        end
    end

    local options = getModeOptions(cfg)
    local starDensity = finite(options.StarDensity) and options.StarDensity or 0
    local starCount = math.floor(#stars * math.clamp(starDensity / 1.5, 0, 1))
    local now = os.clock()

    for index, star in ipairs(stars) do
        local alpha = index <= starCount
            and state.stars * star.visibility * (0.91 + 0.09 * math.sin(now * 0.65 + star.phase))
            or 0

        star.part.Transparency = 1 - math.clamp(alpha, 0, 1)
    end
end

local function positionCelestial(object, kind, direction, diameter, visibility, cfg, state)
    local origin = worldOrigin(cfg)
    local position = origin + direction * cfg.CelestialDistance
    local referenceUp = math.abs(direction:Dot(Vector3.yAxis)) > 0.98 and Vector3.zAxis or Vector3.yAxis
    local frame = CFrame.lookAt(position, origin, referenceUp)
    local options = getModeOptions(cfg)
    local radius = diameter * 0.5

    visibility = math.clamp(visibility, 0, 1)

    if kind == "Moon" then
        local color = state.moonColor

        object.body.CFrame = frame
        object.body.Size = Vector3.new(diameter, diameter, diameter)
        object.body.Color = color
        object.body.Transparency = 1 - visibility

        for index, halo in ipairs(object.halos) do
            local scale = 1.1 + index * 0.22
            local alpha = visibility * cfg.VFXIntensity * options.GlowStrength * (0.032 / index)

            halo.CFrame = frame
            halo.Size = Vector3.one * diameter * scale
            halo.Color = C(151, 190, 247)
            halo.Transparency = 1 - math.clamp(alpha, 0, 0.09)
        end

        for _, crater in ipairs(object.craters) do
            local data = crater.data

            local localNormal = Vector3.new(
                data[1],
                data[2],
                -math.sqrt(math.max(0.01, 1 - data[1] * data[1] - data[2] * data[2]))
            )

            local normal = frame:VectorToWorldSpace(localNormal).Unit
            local surface = position + normal * radius * 0.991
            local craterFrame = CFrame.lookAt(surface, surface + normal, frame.UpVector)
            local size = diameter * data[3]

            crater.rim.CFrame = craterFrame
            crater.rim.Size = Vector3.new(size * 1.09, size * 0.92, diameter * 0.025)
            crater.rim.Color = lerp(color, C(123, 145, 176), 0.38)
            crater.rim.Transparency = 1 - visibility * 0.9

            crater.inset.CFrame = craterFrame + normal * diameter * 0.009
            crater.inset.Size = Vector3.new(size * 0.81, size * 0.68, diameter * 0.018)
            crater.inset.Color = lerp(color, C(105, 126, 160), 0.57)
            crater.inset.Transparency = 1 - visibility * 0.94
        end
    else
        object.body.CFrame = frame
        object.body.Size = Vector3.new(diameter, diameter, diameter)
        object.body.Color = state.sunColor
        object.body.Transparency = 1 - visibility
    end
end

local function updateCelestials()
    if not running() or not currentState then
        return
    end

    if not celestialFolder
        or not celestialFolder.Parent
        or not sun
        or not moon
        or not sun.body
        or not sun.body.Parent
        or not moon.body
        or not moon.body.Parent then
        createCelestials()
    end

    local cfg = getConfig()
    local state = currentState
    local options = getModeOptions(cfg)
    local sunDiameter = cfg.SunSize * options.SunScale
    local moonDiameter = cfg.MoonSize * options.MoonScale
    local sunDirection = Lighting:GetSunDirection()
    local moonDirection = Lighting:GetMoonDirection()
    local sunVisibility = state.sunVisibility
    local moonVisibility = state.moonVisibility

    if cfg.Mode == "Day"
        or cfg.Mode == "GoldenHour"
        or cfg.Mode == "Sunset"
        or cfg.Mode == "Overcast"
        or cfg.Mode == "Storm" then
        moonVisibility = 0
    else
        sunVisibility *= smooth((sunDirection.Y + 0.015) / 0.075)
    end

    if cfg.Mode == "Night" or cfg.Mode == "Moonlight" then
        moonDirection = aboveHorizon(moonDirection, moonDiameter / (2 * cfg.CelestialDistance) + 0.06)
        sunVisibility = 0
    else
        moonVisibility *= smooth((moonDirection.Y + 0.015) / 0.1)
    end

    if cfg.Mode == "Storm" then
        sunVisibility = 0
    end

    positionCelestial(sun, "Sun", sunDirection, sunDiameter, sunVisibility, cfg, state)
    positionCelestial(moon, "Moon", moonDirection, moonDiameter, moonVisibility, cfg, state)
    updateSkyGeometry(cfg, state)
end

local function releaseRuntime()
    if not initialized then
        return
    end

    initialized = false
    applying = true
    disconnectAll(runtimeConnections)

    for object in pairs(owned) do
        pcall(function()
            object:Destroy()
        end)
    end
    table.clear(owned)

    for object, parent in pairs(displacedObjects) do
        pcall(function()
            if object.Parent == nil then
                object.Parent = parent
            end
        end)
    end

    for object, enabled in pairs(disabledPostEffects) do
        pcall(function()
            object.Enabled = enabled
        end)
    end

    for object, enabled in pairs(disabledCloudObjects) do
        pcall(function()
            object.Enabled = enabled
        end)
    end

    for object, parent in pairs(displacedSkyObjects) do
        pcall(function()
            if object.Parent == nil then
                object.Parent = parent
            end
        end)
    end

    for property, value in pairs(originalLighting) do
        pcall(function()
            Lighting[property] = value
        end)
    end

    table.clear(displacedObjects)
    table.clear(disabledPostEffects)
    table.clear(disabledCloudObjects)
    table.clear(displacedSkyObjects)
    table.clear(originalLighting)
    clearThunderQueue()
    table.clear(thunderSounds)
    thunderPoolIndex = 0

    table.clear(effectRecords)
    table.clear(stars)
    table.clear(drops)

    celestialFolder = nil
    weatherFolder = nil
    cloudObject = nil
    sun = nil
    moon = nil
    currentState = nil
    geometrySignature = nil
    weatherSignature = nil
    weatherCenter = nil
    lastMode = nil
    lightningAge = -1
    lightningFlash = 0
    lightningSignature = nil
    lightningPattern = "double"
    lightningStrikeScale = 1
    repairQueued = false
    configDirty = false
    resetRequested = false
    applying = false
end

local function ensureInitialized()
    if initialized then
        return
    end

    initialized = true
    applying = true

    for _, property in ipairs({
        "ClockTime",
        "GeographicLatitude",
        "Brightness",
        "ExposureCompensation",
        "Ambient",
        "OutdoorAmbient",
        "ColorShift_Top",
        "ColorShift_Bottom",
        "GlobalShadows",
        "ShadowSoftness",
        "EnvironmentDiffuseScale",
        "EnvironmentSpecularScale",
        "FogColor",
        "FogStart",
        "FogEnd",
        "Technology"
    }) do
        pcall(function()
            originalLighting[property] = Lighting[property]
        end)
    end

    manageForeignObjects(getConfig())

    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)

    atmosphereRecord = makeEffect("Atmosphere", "KOOL_VFX_Atmosphere")
    colorRecord = makeEffect("ColorCorrectionEffect", "KOOL_VFX_Color")
    bloomRecord = makeEffect("BloomEffect", "KOOL_VFX_Bloom")
    raysRecord = makeEffect("SunRaysEffect", "KOOL_VFX_SunRays")
    dofRecord = makeEffect("DepthOfFieldEffect", "KOOL_VFX_DOF")
    skySuppressorRecord = makeEffect("Sky", "KOOL_VFX_SkySuppressor")

    createCelestials()
    rebuildClouds()
    resetTime(getConfig())

    connect(Lighting.Changed, function(property)
        if running() and not applying and getConfig().LockLighting and originalLighting[property] ~= nil then
            repairQueued = true
        end
    end, runtimeConnections)

    connect(Lighting.ChildAdded, function(child)
        if not initialized or applying or not child:IsA("Sky") then
            return
        end

        if not displacedSkyObjects[child] then
            displacedSkyObjects[child] = Lighting
        end

        pcall(function()
            child.Parent = nil
        end)
    end, runtimeConnections)

    applying = false
end

local function refreshRuntime(reset)
    ensureInitialized()

    local cfg = getConfig()

    if reset or lastMode ~= cfg.Mode then
        resetTime(cfg)
    else
        currentClock = getClock(cfg)
    end

    applying = true
    manageForeignObjects(cfg)
    applying = false

    ensureWeather(cfg)
    updateLightingTargets()
    updateCelestials()
    updateWeather(0, cfg)

    configDirty = false
    resetRequested = false
end

local function setStatus(text)
    if statusLabel then
        statusLabel.Text = text
    end
end

local function updatePreviewButton()
    if previewButton then
        previewButton.Text = previewing and "PREVIEW: ON" or "PREVIEW: OFF"
        setSelectedButton(previewButton, previewing)
        previewButton.Visible = configuring
    end
end

local function startPreview(reset)
    if not alive or not configuring then
        return false
    end

    local hadActiveRuntime = active
    previewing = true

    local ok, message = pcall(function()
        refreshRuntime(reset)
    end)

    if not ok then
        previewing = false

        if hadActiveRuntime then
            local restored = pcall(function()
                refreshRuntime(true)
            end)

            if not restored then
                active = false
                pcall(releaseRuntime)
            end
        else
            pcall(releaseRuntime)
        end

        updatePreviewButton()
        setStatus("Preview failed safely: " .. tostring(message))
        return false
    end

    updatePreviewButton()
    local selected = modeLookup[draft.Mode]
    setStatus("Previewing " .. (selected and selected.title or "DAY") .. ". START keeps these settings.")
    return true
end

local function stopPreview()
    previewing = false

    if active then
        local ok, message = pcall(function()
            refreshRuntime(true)
        end)

        if ok then
            setStatus("Preview off. Your active settings are unchanged.")
        else
            active = false
            pcall(releaseRuntime)
            setStatus("Preview stopped, but active settings could not be restored: " .. tostring(message))
        end
    else
        pcall(releaseRuntime)
        setStatus("Preview off. Original world lighting restored.")
    end

    updatePreviewButton()
end

local function activate()
    local previousSettings = deepCopy(SETTINGS)
    local previousActive = active

    SETTINGS = deepCopy(draft)
    SETTINGS.Enabled = true
    draft.Enabled = true
    active = true
    previewing = false
    configuring = false

    local ok, message = pcall(function()
        refreshRuntime(true)
    end)

    if not ok then
        SETTINGS = previousSettings
        previewing = false
        configuring = true

        if previousActive then
            active = true
            local restored = pcall(function()
                refreshRuntime(true)
            end)

            if not restored then
                active = false
                pcall(releaseRuntime)
            end
        else
            active = false
            pcall(releaseRuntime)
        end

        page = 1
        if renderPage then
            renderPage()
        end
        setStatus("Could not start KOOL vfx safely: " .. tostring(message))
        return false
    end

    page = 5

    if renderPage then
        renderPage()
    end

    if shortcutLabel then
        shortcutLabel.Text = "TOGGLE  •  " .. (SETTINGS.ToggleKey or "F8")
    end

    updatePreviewButton()
    setStatus("KOOL vfx is live. Press " .. (SETTINGS.ToggleKey or "F8") .. " to hide or show this panel.")
    return true
end

local function reconfigure()
    draft = deepCopy(SETTINGS)
    configuring = true
    previewing = false
    page = 1

    renderPage()
    updatePreviewButton()
    setStatus("Your live settings stay active until you preview or press START.")
end

local function restoreTextBoxInput()
    if textBoxMouseBehavior then
        pcall(function()
            UserInputService.MouseBehavior = textBoxMouseBehavior
        end)
    end

    pcall(function()
        UserInputService.MouseIconEnabled = textBoxMouseIconEnabled
    end)

    textBoxMouseBehavior = nil
end

local function buildUiShell()
    gui = make("ScreenGui", {
        Name = "KOOL_VFX_UI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999
    }, playerGui)

    main = make("Frame", {
        Size = UDim2.fromOffset(820, 730),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = C(246, 252, 255),
        BorderSizePixel = 0
    }, gui)

    round(main, 34)
    stroke(main, C(222, 239, 249), 1.5, 0.04)
    gradient(main, C(236, 248, 255), C(250, 253, 255), 90)
    uiScale = make("UIScale", {Scale = 1}, main)
    main.Visible = true

    local rail = make("Frame", {
        Position = UDim2.fromOffset(18, 18),
        Size = UDim2.fromOffset(174, 694),
        BackgroundColor3 = C(232, 246, 253),
        BorderSizePixel = 0
    }, main)
    round(rail, 27)
    stroke(rail, C(210, 233, 245), 1.2, 0.04)

    local brand = label(
        rail,
        "KOOL vfx",
        UDim2.new(0, 18, 0, 18),
        UDim2.new(1, -36, 0, 34),
        Enum.Font.GothamBlack,
        25,
        C(28, 64, 88)
    )

    label(
        rail,
        "sky + weather studio",
        UDim2.new(0, 18, 0, 51),
        UDim2.new(1, -36, 0, 20),
        Enum.Font.GothamMedium,
        10,
        C(99, 132, 153)
    )

    local divider = make("Frame", {
        Position = UDim2.new(0, 18, 0, 86),
        Size = UDim2.new(1, -36, 0, 1),
        BackgroundColor3 = C(205, 229, 242),
        BorderSizePixel = 0
    }, rail)

    local navData = {
        {"SKY", "Pick the world mood"},
        {"TIME", "Set the celestial pace"},
        {"LIGHT", "Tune atmosphere + glow"},
        {"WEATHER", "Mix world-space effects"},
        {"FINISH", "Save and launch"}
    }

    table.clear(navItems)
    for index, data in ipairs(navData) do
        local nav = make("TextButton", {
            Position = UDim2.new(0, 12, 0, 104 + (index - 1) * 70),
            Size = UDim2.new(1, -24, 0, 58),
            BackgroundColor3 = C(240, 250, 255),
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Active = true,
            Selectable = true
        }, rail)
        round(nav, 18)

        local indicator = make("Frame", {
            Position = UDim2.new(0, 0, 0.5, -15),
            Size = UDim2.fromOffset(4, 30),
            BackgroundColor3 = C(92, 169, 216),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        }, nav)
        round(indicator, 4)

        local navTitle = label(
            nav,
            data[1],
            UDim2.new(0, 15, 0, 9),
            UDim2.new(1, -30, 0, 18),
            Enum.Font.GothamBold,
            11,
            C(58, 92, 114)
        )

        local navSub = label(
            nav,
            data[2],
            UDim2.new(0, 15, 0, 27),
            UDim2.new(1, -30, 0, 19),
            Enum.Font.GothamMedium,
            9,
            C(109, 138, 156)
        )

        navItems[index] = {button = nav, indicator = indicator, title = navTitle, sub = navSub}

        uiConnect(nav.Activated, function()
            if active and not configuring and index ~= 5 then
                draft = deepCopy(SETTINGS)
                configuring = true
                previewing = false
            end
            page = index
            renderPage()
        end)

        uiConnect(nav.MouseEnter, function()
            if nav.Parent and page ~= index then
                TweenService:Create(nav, TweenInfo.new(0.12), {BackgroundTransparency = 0.15}):Play()
            end
        end)

        uiConnect(nav.MouseLeave, function()
            if nav.Parent and page ~= index then
                TweenService:Create(nav, TweenInfo.new(0.12), {BackgroundTransparency = 0.45}):Play()
            end
        end)
    end

    local statusPill = make("Frame", {
        Position = UDim2.new(0, 14, 1, -104),
        Size = UDim2.new(1, -28, 0, 42),
        BackgroundColor3 = C(244, 251, 255),
        BorderSizePixel = 0
    }, rail)
    round(statusPill, 17)
    stroke(statusPill, C(216, 235, 246), 1, 0.08)

    shortcutLabel = label(
        statusPill,
        "TOGGLE  •  " .. (SETTINGS.ToggleKey or "F8"),
        UDim2.new(0, 10, 0, 0),
        UDim2.new(1, -20, 1, 0),
        Enum.Font.GothamSemibold,
        10,
        C(101, 132, 151)
    )
    shortcutLabel.TextXAlignment = Enum.TextXAlignment.Center

    label(
        rail,
        "client-side • reversible",
        UDim2.new(0, 14, 1, -48),
        UDim2.new(1, -28, 0, 20),
        Enum.Font.GothamMedium,
        9,
        C(124, 150, 166)
    ).TextXAlignment = Enum.TextXAlignment.Center

    pageLabel = label(
        main,
        "STEP 1 OF 5",
        UDim2.new(0, 218, 0, 22),
        UDim2.new(0, 180, 0, 18),
        Enum.Font.GothamBold,
        10,
        C(91, 136, 166)
    )

    titleLabel = label(
        main,
        "What should the sky do?",
        UDim2.new(0, 218, 0, 42),
        UDim2.new(1, -390, 0, 38),
        Enum.Font.GothamBlack,
        25,
        C(29, 63, 85)
    )

    subtitleLabel = label(
        main,
        "Pick a lighting mode, then preview it live.",
        UDim2.new(0, 220, 0, 79),
        UDim2.new(1, -430, 0, 24),
        Enum.Font.GothamMedium,
        11,
        C(91, 122, 143)
    )

    previewButton = button(main, "PREVIEW: OFF", UDim2.new(1, -166, 0, 42), UDim2.fromOffset(136, 38))
    previewButton.TextSize = 11
    previewButton.ZIndex = 100

    local contentShell = make("Frame", {
        Position = UDim2.fromOffset(206, 118),
        Size = UDim2.fromOffset(596, 520),
        BackgroundColor3 = C(252, 254, 255),
        BorderSizePixel = 0
    }, main)
    round(contentShell, 28)
    stroke(contentShell, C(222, 239, 248), 1.15, 0.05)

    content = make("Frame", {
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 1, -24),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, contentShell)

    local footer = make("Frame", {
        Position = UDim2.fromOffset(206, 650),
        Size = UDim2.fromOffset(596, 62),
        BackgroundColor3 = C(242, 249, 253),
        BorderSizePixel = 0
    }, main)
    round(footer, 23)
    stroke(footer, C(220, 237, 246), 1, 0.06)

    statusLabel = label(
        footer,
        "Nothing is active yet. Pick a mode to preview it.",
        UDim2.new(0, 16, 0, 8),
        UDim2.new(1, -240, 1, -16),
        Enum.Font.GothamMedium,
        10,
        C(86, 117, 137)
    )

    backButton = button(footer, "BACK", UDim2.new(1, -220, 0.5, -18), UDim2.fromOffset(94, 36))
    nextButton = button(footer, "NEXT", UDim2.new(1, -114, 0.5, -18), UDim2.fromOffset(94, 36))

    uiConnect(previewButton.Activated, function()
        if previewing then
            stopPreview()
        else
            startPreview(false)
        end
    end)

    uiConnect(backButton.Activated, function()
        if page > 1 then
            page -= 1
            renderPage()
        end
    end)

    uiConnect(nextButton.Activated, function()
        if page < 5 then
            page += 1
            renderPage()
        end
    end)
end

local function infoCard(y, height, heading, text)
    local frame = make("Frame", {
        Position = UDim2.new(0, 12, 0, y),
        Size = UDim2.new(1, -24, 0, height),
        BackgroundColor3 = C(242, 249, 253),
        BorderSizePixel = 0
    }, content)

    round(frame, 22)
    stroke(frame, C(220, 236, 245), 1, 0.08)

    label(
        frame,
        heading,
        UDim2.new(0, 16, 0, 10),
        UDim2.new(1, -32, 0, 23),
        Enum.Font.GothamBold,
        12,
        C(50, 93, 119)
    )

    label(
        frame,
        text,
        UDim2.new(0, 16, 0, 36),
        UDim2.new(1, -32, 1, -44),
        Enum.Font.GothamMedium,
        11,
        C(86, 117, 136)
    )

    return frame
end

local function modeCard(item, index)
    local selected = draft.Mode == item.key
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)

    local card = make("TextButton", {
        Position = UDim2.new(column * 0.5, column == 0 and 12 or 6, 0, row * 82),
        Size = UDim2.new(0.5, -18, 0, 74),
        BackgroundColor3 = C(255, 255, 255),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, content)

    round(card, 16)

    card.BackgroundColor3 = selected and C(90, 163, 214) or C(241, 249, 254)

    stroke(
        card,
        selected and C(255, 255, 255) or C(208, 227, 239),
        selected and 1.8 or 1.0,
        selected and 0 or 0.08
    )

    label(
        card,
        item.title,
        UDim2.new(0, 12, 0, 8),
        UDim2.new(1, -24, 0, 18),
        Enum.Font.GothamSemibold,
        11,
        selected and C(255, 255, 255) or C(24, 61, 86)
    )

    label(
        card,
        item.description,
        UDim2.new(0, 12, 0, 28),
        UDim2.new(1, -24, 0, 40),
        Enum.Font.GothamMedium,
        9,
        selected and C(244, 251, 255) or C(74, 104, 124)
    )

    if selected then
        local bar = make("Frame", {
            Position = UDim2.new(0, 12, 1, -6),
            Size = UDim2.new(1, -24, 0, 3),
            BackgroundColor3 = C(255, 255, 255),
            BorderSizePixel = 0
        }, card)
        round(bar, 3)
    end

    uiConnect(card.Activated, function()
        local changed = draft.Mode ~= item.key
        draft.Mode = item.key
        startPreview(changed)
        renderPage()
    end)
end

local function renderQuestion1()
    titleLabel.Text = "What should the sky do?"
    subtitleLabel.Text = "Eight lighting modes. Click any card for a live world preview."

    for index, item in ipairs(MODES) do
        modeCard(item, index)
    end

    infoCard(
        334,
        145,
        "SELECTED: " .. (modeLookup[draft.Mode] and modeLookup[draft.Mode].title or "DAY"),
        "Eight tuned lighting modes share the same stable runtime. The sun, moon, stars and world-space weather stay independent from the camera, while PREVIEW OFF cleanly restores your live setup or original world."
    )
end

local function renderQuestion2()
    titleLabel.Text = "How fast should time move?"
    subtitleLabel.Text = "Cycle duration controls total speed. Day and night lengths control its balance."

    slider(content, 12, 1 - (draft.CycleLengthSeconds - 60) / 840, function(alpha)
        draft.CycleLengthSeconds = 900 - alpha * 840
    end, "FULL DAY / NIGHT CYCLE", function(alpha)
        return string.format("%ds", math.floor(900 - alpha * 840 + 0.5))
    end)

    slider(content, 102, 1 - (draft.DayLengthSeconds - 60) / 840, function(alpha)
        draft.DayLengthSeconds = 900 - alpha * 840
    end, "DAY LENGTH / DAY SUN LOOP", function(alpha)
        return string.format("%ds", math.floor(900 - alpha * 840 + 0.5))
    end)

    slider(content, 192, 1 - (draft.NightLengthSeconds - 60) / 840, function(alpha)
        draft.NightLengthSeconds = 900 - alpha * 840
    end, "NIGHT LENGTH / NIGHT MOON LOOP", function(alpha)
        return string.format("%ds", math.floor(900 - alpha * 840 + 0.5))
    end)

    infoCard(
        280,
        111,
        "HOW TIMING WORKS",
        "In Cycle, day/night lengths set the daylight-to-darkness ratio inside the full cycle duration. In Day and Night, they control the celestial loop speed. Golden Hour, Overcast, Storm, Moonlight and Sunset stay permanent."
    )

    infoCard(
        406,
        73,
        "NO HORIZON JUMPS",
        "Day uses a smooth daylight sun path. Permanent Sunset keeps its sun near the horizon instead of advancing into night."
    )
end

local function renderQuestion3()
    titleLabel.Text = "How should the light feel?"
    local selectedMode = modeLookup[draft.Mode] or modeLookup.Day
    subtitleLabel.Text = selectedMode.title .. " has its own atmosphere, shadows and color palette."

    local options = getModeOptions(draft)

    slider(content, 4, draft.Warmth, function(alpha)
        draft.Warmth = alpha
    end, "WARMTH")

    slider(content, 76, draft.VFXIntensity, function(alpha)
        draft.VFXIntensity = alpha
    end, "VFX INTENSITY")

    slider(content, 148, options.HazeStrength / 2, function(alpha)
        options.HazeStrength = alpha * 2
    end, "THIS MODE: FOG / HAZE", function(alpha)
        return string.format("%.2fx", alpha * 2)
    end)

    slider(content, 220, options.GlowStrength / 2, function(alpha)
        options.GlowStrength = alpha * 2
    end, "THIS MODE: GLOW / RAYS", function(alpha)
        return string.format("%.2fx", alpha * 2)
    end)

    if draft.Mode == "GoldenHour" or draft.Mode == "Sunset" then
        local low = draft.Mode == "Sunset" and 17.1 or 16
        local high = draft.Mode == "Sunset" and 17.65 or 17.25

        slider(content, 292, (options.ClockTime - low) / (high - low), function(alpha)
            options.ClockTime = low + alpha * (high - low)
        end, "THIS MODE: SUN POSITION", function(alpha)
            local value = low + alpha * (high - low)
            return string.format("%02d:%02d", math.floor(value), math.floor(value % 1 * 60))
        end)
    elseif draft.Mode == "Night" or draft.Mode == "Moonlight" then
        slider(content, 292, (options.MoonScale - 0.5) / 2.5, function(alpha)
            options.MoonScale = 0.5 + alpha * 2.5
        end, "THIS MODE: MOON SIZE", function(alpha)
            return string.format("%.2fx", 0.5 + alpha * 2.5)
        end)
    elseif draft.Mode == "Overcast" or draft.Mode == "Storm" then
        slider(content, 292, (options.CloudCover - 0.65) / 0.35, function(alpha)
            options.CloudCover = 0.65 + alpha * 0.35
        end, "THIS MODE: CLOUD COVER", function(alpha)
            return string.format("%.0f%%", (0.65 + alpha * 0.35) * 100)
        end)
    elseif draft.Mode == "Cycle" then
        slider(content, 292, options.StartTime / 24, function(alpha)
            options.StartTime = math.min(23.999, alpha * 24)
            resetRequested = previewing
        end, "CYCLE: START TIME", function(alpha)
            local value = math.min(23.999, alpha * 24)
            return string.format("%02d:%02d", math.floor(value), math.floor(value % 1 * 60))
        end)
    else
        slider(content, 292, (options.SunScale - 0.5) / 2.5, function(alpha)
            options.SunScale = 0.5 + alpha * 2.5
        end, "THIS MODE: SUN SIZE", function(alpha)
            return string.format("%.2fx", 0.5 + alpha * 2.5)
        end)
    end

    local preview = make("Frame", {
        Position = UDim2.new(0, 12, 0, 377),
        Size = UDim2.new(1, -24, 0, 102),
        BackgroundColor3 = C(255, 255, 255),
        BorderSizePixel = 0
    }, content)

    round(preview, 20)

    local state = draft.Mode == "Cycle" and palettes.Sunset or (palettes[draft.Mode] or palettes.Day)
    preview.BackgroundColor3 = state.horizon

    label(
        preview,
        selectedMode.title,
        UDim2.new(0, 18, 0, 16),
        UDim2.new(1, -36, 0, 27),
        Enum.Font.GothamBlack,
        17,
        C(255, 255, 255)
    )

    label(
        preview,
        "Every mode keeps its own haze, glow and celestial settings in your preset.",
        UDim2.new(0, 18, 0, 49),
        UDim2.new(1, -36, 0, 38),
        Enum.Font.GothamSemibold,
        11,
        C(246, 250, 255)
    )
end

local function scrollInfoCard(parent, y, height, heading, text)
    local frame = make("Frame", {
        Position = UDim2.new(0, 12, 0, y),
        Size = UDim2.new(1, -24, 0, height),
        BackgroundColor3 = C(242, 249, 253),
        BorderSizePixel = 0
    }, parent)

    round(frame, 22)
    stroke(frame, C(220, 236, 245), 1, 0.08)

    label(
        frame,
        heading,
        UDim2.new(0, 16, 0, 10),
        UDim2.new(1, -32, 0, 23),
        Enum.Font.GothamBold,
        11,
        C(57, 98, 125)
    )

    label(
        frame,
        text,
        UDim2.new(0, 16, 0, 35),
        UDim2.new(1, -32, 1, -43),
        Enum.Font.GothamSemibold,
        10,
        C(83, 115, 136)
    )

    return frame
end

local function boundedSlider(parent, y, value, minimum, maximum, callback, title, formatter)
    local safeMinimum = math.min(minimum, maximum)
    local safeMaximum = math.max(minimum, maximum)
    local span = math.max(safeMaximum - safeMinimum, 0.000001)
    local safeValue = finite(value) and math.clamp(value, safeMinimum, safeMaximum) or safeMinimum

    slider(
        parent,
        y,
        (safeValue - safeMinimum) / span,
        function(alpha)
            callback(safeMinimum + alpha * span)
        end,
        title,
        function(alpha)
            local current = safeMinimum + alpha * span
            return formatter and formatter(current) or tostring(current)
        end
    )

    return y + 84
end

local function renderQuestion4()
    titleLabel.Text = "Which modifiers should run?"
    subtitleLabel.Text = "Mix world-space weather effects, or leave them off. Weather tuning appears only when its modifier is enabled."

    local scroll = make("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = C(102, 169, 212),
        ScrollBarImageTransparency = 0.18,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true,
        Active = true
    }, content)

    local y = 10

    for index, item in ipairs(modifierNames) do
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        local selected = draft.Modifiers[item.key]

        local b = button(
            scroll,
            item.text .. (selected and "  ON" or "  OFF"),
            UDim2.new(column * 0.5, column == 0 and 12 or 6, 0, y + row * 62),
            UDim2.new(0.5, -18, 0, 52)
        )

        setSelectedButton(b, selected)

        uiConnect(b.Activated, function()
            draft.Modifiers[item.key] = not draft.Modifiers[item.key]

            if previewing then
                startPreview(false)
            end

            renderPage()
        end)
    end

    y += math.ceil(#modifierNames / 2) * 62 + 18

    y = boundedSlider(
        scroll,
        y,
        draft.WeatherDensity,
        0,
        1.5,
        function(value)
            draft.WeatherDensity = value
        end,
        "WEATHER DENSITY",
        function(value)
            return string.format("%.0f%%", value * 100)
        end
    )

    if draft.Modifiers.Rain or draft.Modifiers.Snow or draft.Modifiers.FireRain or draft.Modifiers.StarFall then
        y = boundedSlider(
            scroll,
            y,
            draft.WindStrength,
            0,
            30,
            function(value)
                draft.WindStrength = value
            end,
            "WIND STRENGTH",
            function(value)
                return string.format("%.1f studs/s", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.WindDirectionDegrees,
            0,
            360,
            function(value)
                draft.WindDirectionDegrees = value
            end,
            "WIND DIRECTION",
            function(value)
                return string.format("%.0f deg", value)
            end
        )
    end

    local function addWeatherHeading(text)
        label(
            scroll,
            text,
            UDim2.new(0, 24, 0, y + 2),
            UDim2.new(1, -48, 0, 20),
            Enum.Font.GothamBlack,
            12,
            C(54, 101, 132)
        )
        y += 29
    end

    if draft.Modifiers.Rain then
        addWeatherHeading("RAIN TUNING")

        y = boundedSlider(
            scroll,
            y,
            draft.RainFallSpeed,
            1,
            250,
            function(value)
                draft.RainFallSpeed = value
            end,
            "RAIN FALL SPEED",
            function(value)
                return string.format("%.0f studs/s", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.RainFallSpeedVariance,
            0,
            100,
            function(value)
                draft.RainFallSpeedVariance = value
            end,
            "RAIN SPEED VARIANCE",
            function(value)
                return string.format("±%.0f", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.RainSizeWidth,
            0.03,
            0.5,
            function(value)
                draft.RainSizeWidth = value
            end,
            "RAIN DROP WIDTH",
            function(value)
                return string.format("%.3f", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.RainSizeLength,
            0.3,
            8,
            function(value)
                draft.RainSizeLength = value
            end,
            "RAIN DROP LENGTH",
            function(value)
                return string.format("%.2f", value)
            end
        )
    end

    if draft.Modifiers.Snow then
        addWeatherHeading("SNOW TUNING")

        y = boundedSlider(
            scroll,
            y,
            draft.SnowFallSpeed,
            1,
            250,
            function(value)
                draft.SnowFallSpeed = value
            end,
            "SNOW FALL SPEED",
            function(value)
                return string.format("%.0f studs/s", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.SnowFallSpeedVariance,
            0,
            100,
            function(value)
                draft.SnowFallSpeedVariance = value
            end,
            "SNOW SPEED VARIANCE",
            function(value)
                return string.format("±%.0f", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.SnowSize,
            0.08,
            0.5,
            function(value)
                draft.SnowSize = value
            end,
            "SNOW SIZE",
            function(value)
                return string.format("%.2f", value)
            end
        )
    end

    if draft.Modifiers.FireRain then
        addWeatherHeading("FIRE RAIN TUNING")

        y = boundedSlider(
            scroll,
            y,
            draft.FireRainFallSpeed,
            1,
            250,
            function(value)
                draft.FireRainFallSpeed = value
            end,
            "FIRE RAIN FALL SPEED",
            function(value)
                return string.format("%.0f studs/s", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.FireRainFallSpeedVariance,
            0,
            100,
            function(value)
                draft.FireRainFallSpeedVariance = value
            end,
            "FIRE RAIN SPEED VARIANCE",
            function(value)
                return string.format("±%.0f", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.FireRainSizeWidth,
            0.03,
            0.5,
            function(value)
                draft.FireRainSizeWidth = value
            end,
            "FIRE RAIN WIDTH",
            function(value)
                return string.format("%.3f", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.FireRainSizeLength,
            0.3,
            8,
            function(value)
                draft.FireRainSizeLength = value
            end,
            "FIRE RAIN LENGTH",
            function(value)
                return string.format("%.2f", value)
            end
        )
    end

    if draft.Modifiers.StarFall then
        addWeatherHeading("STAR FALL TUNING")

        y = boundedSlider(
            scroll,
            y,
            draft.StarFallSpeed,
            1,
            250,
            function(value)
                draft.StarFallSpeed = value
            end,
            "STAR FALL SPEED",
            function(value)
                return string.format("%.0f studs/s", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.StarFallSpeedVariance,
            0,
            100,
            function(value)
                draft.StarFallSpeedVariance = value
            end,
            "STAR SPEED VARIANCE",
            function(value)
                return string.format("±%.0f", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.StarFallSize,
            0.08,
            0.5,
            function(value)
                draft.StarFallSize = value
            end,
            "STAR SIZE",
            function(value)
                return string.format("%.2f", value)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            draft.StarTailLength,
            0.3,
            8,
            function(value)
                draft.StarTailLength = value
            end,
            "STAR TAIL LENGTH",
            function(value)
                return string.format("%.2f", value)
            end
        )
    end

    if draft.Mode == "Storm" then
        local options = draft.ModeSettings.Storm

        y += 5

        local lightning = button(
            scroll,
            options.Lightning and "LIGHTNING: ON" or "LIGHTNING: OFF",
            UDim2.new(0, 12, 0, y),
            UDim2.new(1, -24, 0, 42)
        )

        setSelectedButton(lightning, options.Lightning)

        uiConnect(lightning.Activated, function()
            options.Lightning = not options.Lightning
            configDirty = previewing
            renderPage()
        end)

        y += 56

        y = boundedSlider(
            scroll,
            y,
            options.LightningStrength,
            0,
            1,
            function(value)
                options.LightningStrength = value
            end,
            "LIGHTNING STRENGTH",
            function(value)
                return string.format("%.0f%%", value * 100)
            end
        )

        y = boundedSlider(
            scroll,
            y,
            options.LightningMinSeconds,
            5,
            60,
            function(value)
                options.LightningMinSeconds = value
                options.LightningMaxSeconds = math.min(value * 2.4, 120)
            end,
            "LIGHTNING INTERVAL",
            function(value)
                local maximum = math.min(value * 2.4, 120)
                return string.format("%d–%ds", math.floor(value + 0.5), math.floor(maximum + 0.5))
            end
        )

        if options.Lightning then
            y = boundedSlider(
                scroll,
                y,
                draft.ThunderChance,
                0,
                1,
                function(value)
                    draft.ThunderChance = value
                end,
                "THUNDER CHANCE",
                function(value)
                    return string.format("%.0f%%", value * 100)
                end
            )

            local testLightning = button(
                scroll,
                "TEST LIGHTNING",
                UDim2.new(0, 12, 0, y + 2),
                UDim2.new(1, -24, 0, 42)
            )
            testLightning.Font = Enum.Font.GothamSemibold

            uiConnect(testLightning.Activated, function()
                if not previewing then
                    startPreview(false)
                end

                if previewing then
                    beginLightningStrike(draft, true)
                    lightningTimer = random:NextNumber(
                        math.max(5, options.LightningMinSeconds),
                        math.max(options.LightningMinSeconds, options.LightningMaxSeconds)
                    )
                    setStatus("Test lightning fired.")
                end
            end)

            y += 56
        end
    end

    local names = {}

    for _, item in ipairs(modifierNames) do
        if draft.Modifiers[item.key] then
            names[#names + 1] = item.text
        end
    end

    if #names == 0 then
        y += 4
        scrollInfoCard(
            scroll,
            y,
            106,
            "SELECTED MODIFIERS",
            "NO MODIFIERS"
        )
        y += 125
    else
        y += 5
        scrollInfoCard(
            scroll,
            y,
            106,
            "SELECTED MODIFIERS",
            table.concat(names, "  •  ")
        )
        y += 125
    end

    scrollInfoCard(
        scroll,
        y,
        110,
        "WORLD-SPACE WEATHER",
        "Rain, Snow, Fire Rain and Star Fall spawn around you, then move through absolute world positions. Walking or rotating the camera does not drag the drops along with your view."
    )

    y += 122

    scroll.CanvasPosition = Vector2.zero
end

local function renderFinal()
    titleLabel.Text = active and not configuring and "KOOL vfx is live." or "One last thing."

    subtitleLabel.Text = active and not configuring
        and "Save your preset, load another, or reconfigure your setup."
        or "Save this complete preset so you can paste it next time."

    local summary = make("Frame", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 0, 130),
        BackgroundColor3 = C(238, 250, 255),
        BorderSizePixel = 0
    }, content)

    round(summary, 18)

    local mods = {}

    for _, item in ipairs(modifierNames) do
        if draft.Modifiers[item.key] then
            mods[#mods + 1] = item.text
        end
    end

    local function summaryLine(text, y, color)
        label(
            summary,
            text,
            UDim2.new(0, 16, 0, y),
            UDim2.new(1, -32, 0, 24),
            Enum.Font.GothamBold,
            11,
            color
        )
    end

    local summaryMode = modeLookup[draft.Mode] or modeLookup.Day
    summaryLine("MODE    " .. summaryMode.title, 10)

    summaryLine(string.format(
        "CYCLE  %ds     DAY  %ds     NIGHT  %ds",
        math.floor(draft.CycleLengthSeconds + 0.5),
        math.floor(draft.DayLengthSeconds + 0.5),
        math.floor(draft.NightLengthSeconds + 0.5)
    ), 36)

    summaryLine(string.format(
        "WARMTH  %.0f%%     VFX  %.0f%%     WEATHER  %.0f%%",
        draft.Warmth * 100,
        draft.VFXIntensity * 100,
        draft.WeatherDensity * 100
    ), 62)

    summaryLine(
        "MODIFIERS    " .. (#mods > 0 and table.concat(mods, ", ") or "None"),
        88,
        C(75, 114, 139)
    )

    local scroll = make("ScrollingFrame", {
        Position = UDim2.new(0, 12, 0, 145),
        Size = UDim2.new(1, -24, 0, 128),
        BackgroundColor3 = C(246, 252, 255),
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = C(102, 169, 212),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    }, content)

    round(scroll, 16)
    stroke(scroll, C(180, 222, 239), 1.1)

    presetBox = make("TextBox", {
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.new(1, -25, 0, 110),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = encodePreset(),
        PlaceholderText = "Paste a KOOL vfx preset here",
        TextColor3 = C(37, 64, 82),
        PlaceholderColor3 = C(128, 160, 177),
        Font = Enum.Font.RobotoMono,
        TextSize = 10,
        TextWrapped = true,
        ClearTextOnFocus = false,
        MultiLine = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, scroll)

    uiConnect(presetBox.Focused, function()
        textBoxMouseBehavior = UserInputService.MouseBehavior
        textBoxMouseIconEnabled = UserInputService.MouseIconEnabled
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)

    uiConnect(presetBox.FocusLost, function()
        restoreTextBoxInput()
    end)

    local copy = button(
        content,
        "COPY PRESET",
        UDim2.new(0, 12, 0, 289),
        UDim2.new(0.5, -18, 0, 42)
    )

    local load = button(
        content,
        "LOAD PRESET",
        UDim2.new(0.5, 6, 0, 289),
        UDim2.new(0.5, -18, 0, 42)
    )

    local hotkeyBtn = button(
        content,
        "TOGGLE KEY:  " .. (SETTINGS.ToggleKey or "F8"),
        UDim2.new(0, 12, 0, 340),
        UDim2.new(1, -24, 0, 42)
    )
    hotkeyBtn.TextSize = 13

    uiConnect(hotkeyBtn.Activated, function()
        if capturingHotkey then
            if hotkeyCaptureConnection then
                pcall(function()
                    hotkeyCaptureConnection:Disconnect()
                end)
                hotkeyCaptureConnection = nil
            end
            capturingHotkey = false
            hotkeyBtn.Text = "TOGGLE KEY:  " .. (SETTINGS.ToggleKey or "F8")
            return
        end

        capturingHotkey = true
        hotkeyBtn.Text = "PRESS A KEY…"

        hotkeyCaptureConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end

            local key = input.KeyCode

            if key == Enum.KeyCode.Escape or key == Enum.KeyCode.Unknown then
                if hotkeyCaptureConnection then
                    pcall(function()
                        hotkeyCaptureConnection:Disconnect()
                    end)
                    hotkeyCaptureConnection = nil
                end
                capturingHotkey = false
                hotkeyBtn.Text = "TOGGLE KEY:  " .. (SETTINGS.ToggleKey or "F8")
                if shortcutLabel then
                    shortcutLabel.Text = "TOGGLE  •  " .. (SETTINGS.ToggleKey or "F8")
                end
                return
            end

            SETTINGS.ToggleKey = key.Name
            draft.ToggleKey = key.Name

            if hotkeyCaptureConnection then
                pcall(function()
                    hotkeyCaptureConnection:Disconnect()
                end)
                hotkeyCaptureConnection = nil
            end

            capturingHotkey = false
            hotkeyBtn.Text = "TOGGLE KEY:  " .. key.Name
            if shortcutLabel then
                shortcutLabel.Text = "TOGGLE  •  " .. key.Name
            end
            setStatus("Toggle key set to " .. key.Name)
        end)
    end)

    startButton = button(
        content,
        active and not configuring and "RECONFIGURE KOOL vfx" or "START KOOL vfx",
        UDim2.new(0, 12, 0, 397),
        UDim2.new(1, -24, 0, 57)
    )

    startButton.TextSize = 18
    startButton.Font = Enum.Font.GothamSemibold
    setSelectedButton(startButton, true)

    if active and not configuring then
        local stop = button(
            content,
            "STOP VFX / RESTORE WORLD",
            UDim2.new(0, 12, 0, 465),
            UDim2.new(1, -24, 0, 25)
        )

        stop.TextSize = 10

        uiConnect(stop.Activated, function()
            active = false
            previewing = false
            configuring = true

            releaseRuntime()
            page = 1
            renderPage()

            setStatus("KOOL vfx stopped. Original world lighting restored.")
        end)
    end

    uiConnect(copy.Activated, function()
        local text = encodePreset()
        presetBox.Text = text

        local copied = false
        if type(setclipboard) == "function" then
            copied = pcall(setclipboard, text)
        end

        if copied then
            setStatus("Complete preset copied.")
        else
            presetBox:CaptureFocus()
            presetBox.CursorPosition = #text + 1
            presetBox.SelectionStart = 1
            setStatus("Preset selected. Use Ctrl+C or your device's Copy action.")
        end
    end)

    uiConnect(load.Activated, function()
        local previousSettings = deepCopy(SETTINGS)
        local previousDraft = deepCopy(draft)
        local success, message = applyPresetString(presetBox.Text)

        if success then
            if active and not configuring then
                SETTINGS = deepCopy(draft)
                SETTINGS.Enabled = true
                previewing = false

                local applied, runtimeError = pcall(function()
                    refreshRuntime(true)
                end)

                if not applied then
                    SETTINGS = previousSettings
                    draft = previousDraft
                    local restored = pcall(function()
                        refreshRuntime(true)
                    end)

                    if not restored then
                        active = false
                        pcall(releaseRuntime)
                    end

                    success = false
                    message = "Preset was valid, but runtime apply failed safely: " .. tostring(runtimeError)
                end
            else
                if not startPreview(true) then
                    draft = previousDraft
                    success = false
                    message = "Preset was valid, but preview could not start safely."
                end
            end

            renderPage()
        end

        setStatus(message)
    end)

    uiConnect(startButton.Activated, function()
        if active and not configuring then
            reconfigure()
        else
            activate()
        end
    end)
end

renderPage = function()
    if not content or not alive then
        return
    end

    restoreTextBoxInput()
    disconnectAll(pageConnections)

    if hotkeyCaptureConnection then
        pcall(function()
            hotkeyCaptureConnection:Disconnect()
        end)
        hotkeyCaptureConnection = nil
    end
    capturingHotkey = false

    for _, child in ipairs(content:GetChildren()) do
        child:Destroy()
    end

    presetBox = nil
    startButton = nil
    pageScope = true

    local pageOk, pageError = pcall(function()
        if page == 1 then
            renderQuestion1()
        elseif page == 2 then
            renderQuestion2()
        elseif page == 3 then
            renderQuestion3()
        elseif page == 4 then
            renderQuestion4()
        else
            renderFinal()
        end
    end)

    pageScope = false

    if not pageOk then
        disconnectAll(pageConnections)
        for _, child in ipairs(content:GetChildren()) do
            child:Destroy()
        end
        label(
            content,
            "This setup page hit an error, but KOOL vfx is still alive.\n" .. tostring(pageError),
            UDim2.new(0, 18, 0, 18),
            UDim2.new(1, -36, 0, 120),
            Enum.Font.GothamMedium,
            12,
            C(45, 73, 93)
        )
        setStatus("A setup page failed safely instead of locking the UI.")
    end

    local liveMode = modeLookup[SETTINGS.Mode] or modeLookup.Cycle
    local draftMode = modeLookup[draft.Mode] or modeLookup.Cycle

    pageLabel.Text = active and not configuring and "LIVE  •  " .. liveMode.title
        or page < 5 and string.format("STEP %d OF 5", page)
        or "READY  •  " .. draftMode.title

    if shortcutLabel then
        shortcutLabel.Text = "TOGGLE  •  " .. (SETTINGS.ToggleKey or "F8")
    end

    backButton.Visible = configuring and page > 1
    nextButton.Visible = configuring and page < 5

    local livePage = active and not configuring and 5 or page
    for index, item in ipairs(navItems) do
        local selected = index == livePage
        item.button.BackgroundTransparency = selected and 0 or 0.45
        item.button.BackgroundColor3 = selected and C(213, 238, 251) or C(240, 250, 255)
        item.indicator.BackgroundTransparency = selected and 0 or 1
        item.title.TextColor3 = selected and C(35, 93, 129) or C(58, 92, 114)
        item.sub.TextColor3 = selected and C(76, 123, 151) or C(109, 138, 156)
    end

    updatePreviewButton()
end

local function cleanup()
    if not alive then
        return
    end

    active = false
    previewing = false
    releaseRuntime()
    alive = false

    if hotkeyCaptureConnection then
        pcall(function()
            hotkeyCaptureConnection:Disconnect()
        end)
        hotkeyCaptureConnection = nil
    end

    restoreTextBoxInput()

    disconnectAll(pageConnections)
    disconnectAll(uiConnections)
    disconnectAll(connections)

    if gui then
        gui:Destroy()
        gui = nil
    end

    shortcutLabel = nil
    table.clear(navItems)

    if controller then
        controller:Destroy()
        controller = nil
    end
end

controller = make("Folder", {Name = "KOOL_VFX"}, playerScripts)

local shutdown = make("BindableFunction", {Name = "Shutdown"}, controller)
shutdown.OnInvoke = cleanup

connect(controller.AncestryChanged, function(_, parent)
    if parent == nil and alive then
        cleanup()
    end
end)

connect(script.Destroying, cleanup)

connect(UserInputService.InputBegan, function(input, processed)
    if processed or not gui then
        return
    end
    if capturingHotkey then
        return
    end
    local toggleKey = Enum.KeyCode[SETTINGS.ToggleKey or "F8"]
    if toggleKey and input.KeyCode == toggleKey then
        main.Visible = not main.Visible
    end
end)

connect(RunService.RenderStepped, function(dt)
    if not alive then
        return
    end

    if uiScale then
        local camera = workspace.CurrentCamera
        if camera then
            local viewport = camera.ViewportSize
            local scale = math.clamp(
                math.min((viewport.X - 24) / 820, (viewport.Y - 24) / 730),
                0.68,
                1
            )

            if math.abs(uiScale.Scale - scale) > 0.001 then
                uiScale.Scale = scale
            end
        end
    end

    if not running() then
        return
    end

    local frameDt = math.max(0, dt)
    local simulationDt = math.min(frameDt, 0.25)
    local cfg = getConfig()

    if configDirty or resetRequested or lastMode ~= cfg.Mode then
        refreshRuntime(resetRequested or lastMode ~= cfg.Mode)
        cfg = getConfig()
    end

    advanceTime(simulationDt, cfg)

    local previousFlash = lightningFlash
    updateLightning(frameDt, cfg)

    lightingAccumulator += simulationDt

    if lightingAccumulator >= 0.075
        or lightningFlash > 0
        or previousFlash > 0
        or (repairQueued and cfg.LockLighting) then
        lightingAccumulator = 0
        repairQueued = false

        updateLightingTargets()
        updateCelestials()
    end

    updateWeather(simulationDt, cfg)

    auditAccumulator += simulationDt

    if auditAccumulator >= 0.75 then
        auditAccumulator = 0

        applying = true
        manageForeignObjects(cfg)
        applying = false

        ensureWeather(cfg)

        local damaged = not celestialFolder or not celestialFolder.Parent

        for _, record in ipairs(effectRecords) do
            if not record.object or record.object.Parent ~= Lighting then
                damaged = true
                break
            end
        end

        if damaged or cfg.LockLighting then
            updateLightingTargets()
            updateCelestials()
        end
    end
end)

if SETTINGS.UIEnabled then
    buildUiShell()
    renderPage()
else
    activate()
end