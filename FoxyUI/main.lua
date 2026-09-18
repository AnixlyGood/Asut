-- // Foxy UI Library (Core Engine) - Upgraded Edition
-- Features: WindUI-style Notify, Config Manager, User Panel, Background

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Library = {
    WhitelistedUsers = {}
}

-- // Utility: File System Mock Overrides
local _isfolder = isfolder or function() return true end
local _makefolder = makefolder or function() end
local _writefile = writefile or function(path, data) warn("File saving not supported on this executor.") end
local _readfile = readfile or function() return "{}" end
local _listfiles = listfiles or function() return {} end
local _delfile = delfile or function() warn("File deletion not supported.") end

-- // Utility: Safe Clipboard Copy
local function SafeCopyToClipboard(text)
    if setclipboard then
        setclipboard(text)
    elseif toclipboard then
        toclipboard(text)
    else
        warn("Clipboard copying is not supported on your current executor.")
    end
end

-- // Utility: Instance Creator
local function Create(className, properties)
    local instance = Instance.new(className)
    
    if className == "TextBox" then
        instance.Text = ""
    end

    for k, v in pairs(properties or {}) do
        instance[k] = v
    end
    
    if (className == "TextLabel" or className == "TextButton" or className == "TextBox") then
        if properties.TextSize and properties.RichText ~= true then
            instance.TextScaled = true
            local constraint = Instance.new("UITextSizeConstraint")
            constraint.MaxTextSize = properties.TextSize
            constraint.MinTextSize = 6
            constraint.Parent = instance
        end
    end
    
    return instance
end

-- // Utility: Build search index for a card (cached)
local function BuildSearchIndex(card)
    local parts = {}
    for _, desc in ipairs(card:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            if desc.Text and desc.Text ~= "" then
                table.insert(parts, desc.Text:lower())
            end
        end
    end
    return table.concat(parts, " ")
end

-- // Utility: Smooth Tweening
local function Tween(instance, properties, duration)
    duration = duration or 0.25
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- // Utility: Micro-Interaction Bounce
local function AddBounce(button, scaleFactor)
    scaleFactor = scaleFactor or 0.96
    local scaleObj = button:FindFirstChild("UIScale") or Create("UIScale", {Parent = button, Scale = 1})
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween(scaleObj, {Scale = scaleFactor}, 0.15)
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween(scaleObj, {Scale = 1}, 0.15)
        end
    end)
    button.MouseLeave:Connect(function()
        Tween(scaleObj, {Scale = 1}, 0.15)
    end)
end

-- // Utility: Draggable
local function MakeDraggable(topbar, object)
    topbar.Active = true
    object.Active = true
    local dragging, dragInput, dragStart, startPos
    
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(object, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.08)
        end
    end)
end

local AccentColor = Color3.fromRGB(190, 140, 255)
local BackgroundColor = Color3.fromRGB(18, 18, 20)
local CardColor = Color3.fromRGB(24, 24, 27)
local HoverColor = Color3.fromRGB(35, 35, 40)
local TextColor = Color3.fromRGB(240, 240, 240)
local SubTextColor = Color3.fromRGB(150, 150, 150)

-- // THEME SYSTEM
local Themes = {
    Dark = {Accent = Color3.fromRGB(190, 140, 255), Background = Color3.fromRGB(18, 18, 20), Card = Color3.fromRGB(24, 24, 27), Hover = Color3.fromRGB(35, 35, 40), Text = Color3.fromRGB(240, 240, 240), SubText = Color3.fromRGB(150, 150, 150)},
    Light = {Accent = Color3.fromRGB(100, 100, 255), Background = Color3.fromRGB(240, 240, 245), Card = Color3.fromRGB(255, 255, 255), Hover = Color3.fromRGB(220, 220, 230), Text = Color3.fromRGB(20, 20, 30), SubText = Color3.fromRGB(100, 100, 120)},
    Midnight = {Accent = Color3.fromRGB(80, 150, 255), Background = Color3.fromRGB(10, 10, 30), Card = Color3.fromRGB(20, 20, 50), Hover = Color3.fromRGB(30, 30, 70), Text = Color3.fromRGB(220, 220, 255), SubText = Color3.fromRGB(130, 130, 180)},
    Ocean = {Accent = Color3.fromRGB(50, 200, 200), Background = Color3.fromRGB(15, 30, 40), Card = Color3.fromRGB(25, 50, 65), Hover = Color3.fromRGB(35, 70, 90), Text = Color3.fromRGB(220, 240, 255), SubText = Color3.fromRGB(130, 180, 200)},
    Sunset = {Accent = Color3.fromRGB(255, 100, 80), Background = Color3.fromRGB(30, 15, 20), Card = Color3.fromRGB(50, 25, 30), Hover = Color3.fromRGB(70, 35, 45), Text = Color3.fromRGB(255, 220, 220), SubText = Color3.fromRGB(200, 150, 150)},
    Forest = {Accent = Color3.fromRGB(60, 200, 100), Background = Color3.fromRGB(10, 25, 15), Card = Color3.fromRGB(15, 40, 25), Hover = Color3.fromRGB(25, 55, 35), Text = Color3.fromRGB(220, 255, 225), SubText = Color3.fromRGB(140, 200, 160)},
    Gold = {Accent = Color3.fromRGB(255, 200, 50), Background = Color3.fromRGB(25, 20, 10), Card = Color3.fromRGB(40, 32, 15), Hover = Color3.fromRGB(55, 45, 25), Text = Color3.fromRGB(255, 245, 220), SubText = Color3.fromRGB(200, 180, 130)},
    Crimson = {Accent = Color3.fromRGB(220, 50, 60), Background = Color3.fromRGB(20, 10, 12), Card = Color3.fromRGB(35, 18, 20), Hover = Color3.fromRGB(55, 25, 30), Text = Color3.fromRGB(255, 220, 220), SubText = Color3.fromRGB(200, 140, 140)},
    Amethyst = {Accent = Color3.fromRGB(170, 80, 255), Background = Color3.fromRGB(20, 12, 28), Card = Color3.fromRGB(35, 22, 50), Hover = Color3.fromRGB(55, 35, 75), Text = Color3.fromRGB(240, 220, 255), SubText = Color3.fromRGB(180, 150, 220)},
    Mint = {Accent = Color3.fromRGB(80, 220, 180), Background = Color3.fromRGB(15, 25, 22), Card = Color3.fromRGB(25, 40, 35), Hover = Color3.fromRGB(35, 60, 50), Text = Color3.fromRGB(220, 255, 245), SubText = Color3.fromRGB(150, 200, 180)},
}

local CurrentTheme = "Dark"

-- // Global Notification API
local GlobalNotifContainer

-- // Type colors (WindUI style)
local NotifTypeColors = {
    Success = Color3.fromRGB(80, 200, 120),
    Error = Color3.fromRGB(230, 80, 80),
    Warning = Color3.fromRGB(240, 180, 60),
    Info = Color3.fromRGB(100, 160, 240),
    Default = Color3.fromRGB(190, 140, 255),
}

function Library:Notify(options)
    if not GlobalNotifContainer then return end
    
    local title = options.Title or "Notification"
    local desc = options.Description or options.Content or ""
    local duration = options.Duration or 3
    local iconInput = options.Icon
    local notifType = options.Type or "Default"
    local canClose = options.CanClose ~= false
    local buttons = options.Buttons

    local typeColor = NotifTypeColors[notifType] or NotifTypeColors.Default

    local hasButtons = buttons and #buttons > 0
    local notifHeight = hasButtons and 108 or 68

    local Notif = Create("Frame", {
        Parent = GlobalNotifContainer,
        BackgroundColor3 = Color3.fromRGB(22, 22, 25),
        Size = UDim2.new(1, 0, 0, notifHeight),
        BackgroundTransparency = 1,
        ZIndex = 201,
        ClipsDescendants = true,
    })
    Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 10)})
    local Stroke = Create("UIStroke", {
        Parent = Notif, 
        Color = Color3.fromRGB(45, 45, 50), 
        Thickness = 1, 
        Transparency = 1
    })

    -- Colored left accent bar
    Create("Frame", {
        Parent = Notif,
        BackgroundColor3 = typeColor,
        Size = UDim2.new(0, 3, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 202,
        BorderSizePixel = 0,
    })

    -- Icon container
    local iconOffset = 15
    if iconInput then
        local iconFrame = Create("Frame", {
            Parent = Notif,
            BackgroundColor3 = typeColor,
            BackgroundTransparency = 0.88,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0, 13, 0, 13),
            ZIndex = 202,
        })
        Create("UICorner", {Parent = iconFrame, CornerRadius = UDim.new(0, 8)})
        
        local img = Create("ImageLabel", {
            Parent = iconFrame,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = iconInput,
            ImageColor3 = typeColor,
            ImageTransparency = 1,
            ZIndex = 203,
        })
        
        Tween(img, {ImageTransparency = 0}, 0.3)
        iconOffset = 55
    end

    local TitleText = Create("TextLabel", {
        Parent = Notif,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(240, 240, 240),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, iconOffset, 0, 14),
        Size = UDim2.new(1, -iconOffset - 40, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        ZIndex = 202,
    })

    local DescText = Create("TextLabel", {
        Parent = Notif,
        Text = desc,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(150, 150, 155),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, iconOffset, 0, 33),
        Size = UDim2.new(1, -iconOffset - 40, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 202,
    })

    -- Close button
    if canClose then
        local closeBtn = Create("TextButton", {
            Parent = Notif,
            Text = "✕",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(120, 120, 125),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(1, -28, 0, 12),
            TextTransparency = 1,
            AutoButtonColor = false,
            ZIndex = 203,
        })
        closeBtn.MouseEnter:Connect(function() 
            Tween(closeBtn, {TextColor3 = Color3.fromRGB(240, 240, 240)}, 0.15)
        end)
        closeBtn.MouseLeave:Connect(function() 
            Tween(closeBtn, {TextColor3 = Color3.fromRGB(120, 120, 125)}, 0.15)
        end)
        closeBtn.MouseButton1Click:Connect(function()
            Tween(Notif, {BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0)}, 0.3)
            Tween(Stroke, {Transparency = 1}, 0.3)
            Tween(TitleText, {TextTransparency = 1}, 0.3)
            Tween(DescText, {TextTransparency = 1}, 0.3)
            task.wait(0.3)
            Notif:Destroy()
        end)
        Tween(closeBtn, {TextTransparency = 0}, 0.3)
    end

    -- Buttons
    local buttonRefs = {}
    if hasButtons then
        local btnContainer = Create("Frame", {
            Parent = Notif,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -26, 0, 26),
            Position = UDim2.new(0, 13, 0, 70),
            ZIndex = 202,
        })
        Create("UIListLayout", {
            Parent = btnContainer,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        })

        for i, btnData in ipairs(buttons) do
            local isPrimary = (i == 1)
            local btn = Create("TextButton", {
                Parent = btnContainer,
                Text = btnData.Title or "Button",
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = isPrimary and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 220, 220),
                BackgroundColor3 = isPrimary and typeColor or Color3.fromRGB(38, 38, 42),
                Size = UDim2.new(0.5, -3, 1, 0),
                AutoButtonColor = false,
                TextTransparency = 1,
                BackgroundTransparency = 1,
                ZIndex = 203,
            })
            Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
            
            btn.MouseEnter:Connect(function() 
                Tween(btn, {BackgroundColor3 = isPrimary and typeColor:Lerp(Color3.new(1,1,1), 0.15) or Color3.fromRGB(50, 50, 55)}, 0.15) 
            end)
            btn.MouseLeave:Connect(function() 
                Tween(btn, {BackgroundColor3 = isPrimary and typeColor or Color3.fromRGB(38, 38, 42)}, 0.15) 
            end)
            
            btn.MouseButton1Click:Connect(function()
                if btnData.Callback then pcall(btnData.Callback) end
                Tween(Notif, {BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0)}, 0.25)
                Tween(Stroke, {Transparency = 1}, 0.25)
                Tween(TitleText, {TextTransparency = 1}, 0.25)
                Tween(DescText, {TextTransparency = 1}, 0.25)
                task.wait(0.25)
                Notif:Destroy()
            end)
            table.insert(buttonRefs, btn)
        end
    end

    Notif.Position = UDim2.new(1, 30, 0, 0)
    Tween(Notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.35)
    Tween(Notif, {BackgroundTransparency = 0}, 0.3)
    Tween(Stroke, {Transparency = 0.4}, 0.3)
    Tween(TitleText, {TextTransparency = 0}, 0.3)
    Tween(DescText, {TextTransparency = 0}, 0.3)
    for _, b in ipairs(buttonRefs) do
        Tween(b, {TextTransparency = 0, BackgroundTransparency = 0}, 0.3)
    end

    if duration > 0 then
        task.delay(duration, function()
            if Notif.Parent then
                Tween(Notif, {BackgroundTransparency = 1, Position = UDim2.new(1, 30, 0, 0)}, 0.35)
                Tween(Stroke, {Transparency = 1}, 0.35)
                Tween(TitleText, {TextTransparency = 1}, 0.35)
                Tween(DescText, {TextTransparency = 1}, 0.35)
                for _, b in ipairs(buttonRefs) do
                    Tween(b, {TextTransparency = 1, BackgroundTransparency = 1}, 0.35)
                end
                task.wait(0.35)
                Notif:Destroy()
            end
        end)
    end
end

function Library:CreateWindow(options)
    local hubName = "Foxy Ui Lib"
    local subText = "Made By Hypol-X"
    local subColor = AccentColor
    local sphTextToggle = false
    local sphWords = "FX"
    local sphImage = nil
    local topbarLogo = nil
    local logoSize = 32
    local sphIconSize = 26
    local backgroundImage = nil
    local backgroundTransparency = 0.5
    local userEnabled = false
    local userAnonymous = false
    local userSubtitle = "User"

    if type(options) == "table" then
        hubName = options.Title or hubName
        subText = options.Subtitle or subText
        subColor = options.SubtitleColor or subColor
        
        if options.SphereText ~= nil then
            sphTextToggle = options.SphereText
        end
        if options.SphereWords ~= nil then
            local wordList = string.split(tostring(options.SphereWords), " ")
            if #wordList > 2 then
                sphWords = wordList[1] .. " " .. wordList[2]
            else
                sphWords = tostring(options.SphereWords)
            end
        end
        
        sphImage = options.SphereImage
        topbarLogo = options.Logo
        logoSize = options.LogoSize or 32
        sphIconSize = options.SphereIconSize or 26
        backgroundImage = options.Background
        backgroundTransparency = options.BackgroundImageTransparency or 0.5
        
        if options.User then
            userEnabled = options.User.Enabled ~= false
            userAnonymous = options.User.Anonymous == true
            userSubtitle = options.User.Subtitle or "User"
        end
    elseif type(options) == "string" then
        hubName = options
    end

    local uniqueID = HttpService:GenerateGUID(false)
    local ScreenGui = Create("ScreenGui", {
        Name = "Foxy_UI_" .. uniqueID,
        Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })

    -- BACKGROUND IMAGE (WindUI style - full screen behind window)
    local BackgroundImageLabel = nil
    local BackgroundOverlay = nil
    if backgroundImage then
        BackgroundImageLabel = Create("ImageLabel", {
            Parent = ScreenGui,
            Name = "BackgroundImage",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Image = backgroundImage,
            ScaleType = Enum.ScaleType.Crop,
            ImageTransparency = 1,
            ZIndex = 0,
        })
        
        BackgroundOverlay = Create("Frame", {
            Parent = ScreenGui,
            Name = "BackgroundOverlay",
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 1,
        })
    end

    local NotifContainer = Create("Frame", {
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20),
        Position = UDim2.new(1, -340, 0, 10),
        ZIndex = 200,
        Active = false
    })
    Create("UIListLayout", {Parent = NotifContainer, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
    GlobalNotifContainer = NotifContainer

    local function SendPremiumNotification()
        Library:Notify({
            Title = "ACCESS DENIED",
            Description = "This is for whitelisted users only!",
            Icon = "rbxassetid://94997763389875",
            Type = "Error",
            Duration = 4,
        })
    end

    local InfoOverlay = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(5, 5, 8), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 150, Visible = false, Active = true})
    local InfoCard = Create("Frame", {Parent = InfoOverlay, BackgroundColor3 = Color3.fromRGB(16, 16, 20), Size = UDim2.new(0, 360, 0, 280), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 151, BackgroundTransparency = 1, ClipsDescendants = true})
    Create("UICorner", {Parent = InfoCard, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = InfoCard, Color = AccentColor, Thickness = 1.5, Transparency = 1})
    local InfoScale = Create("UIScale", {Parent = InfoCard, Scale = 0})

    local InfoHeader = Create("Frame", {Parent = InfoCard, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 152})
    local InfoTitle = Create("TextLabel", {Parent = InfoHeader, Text = "Feature Info", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 0), Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 152})
    local InfoCloseBtn = Create("TextButton", {Parent = InfoHeader, Text = "X", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(1, -40, 0, 0), ZIndex = 152, TextTransparency = 1})
    AddBounce(InfoCloseBtn)

    local InfoScroll = Create("ScrollingFrame", {Parent = InfoCard, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, -60), Position = UDim2.new(0, 20, 0, 50), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, ScrollBarImageColor3 = AccentColor, BorderSizePixel = 0, ZIndex = 152})
    local InfoLayout = Create("UIListLayout", {Parent = InfoScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
    local InfoDesc = Create("TextLabel", {Parent = InfoScroll, Text = "", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 152, TextTransparency = 1})
    local InfoExampleBox = Create("Frame", {Parent = InfoScroll, BackgroundColor3 = Color3.fromRGB(10, 10, 12), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 152})
    Create("UICorner", {Parent = InfoExampleBox, CornerRadius = UDim.new(0, 6)})
    Create("UIStroke", {Parent = InfoExampleBox, Color = Color3.fromRGB(40, 40, 45), Thickness = 1})
    local InfoExampleText = Create("TextLabel", {Parent = InfoExampleBox, Text = "", Font = Enum.Font.Code, TextSize = 12, TextColor3 = AccentColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 10), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 152, TextTransparency = 1})
    Create("UIPadding", {Parent = InfoExampleBox, PaddingBottom = UDim.new(0, 10)})

    InfoLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() InfoScroll.CanvasSize = UDim2.new(0, 0, 0, InfoLayout.AbsoluteContentSize.Y + 10) end)

    local function OpenInfoWindow(data)
        InfoTitle.Text = data.Title or "Information"
        InfoDesc.Text = data.Description or "No description provided."
        if data.Example then
            InfoExampleText.Text = data.Example
            InfoExampleBox.Visible = true
        else
            InfoExampleBox.Visible = false
        end
        InfoOverlay.Visible = true
        Tween(InfoOverlay, {BackgroundTransparency = 0.4}, 0.3)
        Tween(InfoCard, {BackgroundTransparency = 0}, 0.3)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 0.3}, 0.3)
        Tween(InfoScale, {Scale = 1}, 0.3)
        Tween(InfoTitle, {TextTransparency = 0}, 0.3)
        Tween(InfoCloseBtn, {TextTransparency = 0}, 0.3)
        Tween(InfoDesc, {TextTransparency = 0}, 0.3)
        if data.Example then Tween(InfoExampleText, {TextTransparency = 0}, 0.3) end
    end

    InfoCloseBtn.MouseButton1Click:Connect(function()
        Tween(InfoOverlay, {BackgroundTransparency = 1}, 0.3)
        Tween(InfoCard, {BackgroundTransparency = 1}, 0.3)
        Tween(InfoCard:FindFirstChild("UIStroke"), {Transparency = 1}, 0.3)
        Tween(InfoScale, {Scale = 0}, 0.3)
        Tween(InfoTitle, {TextTransparency = 1}, 0.3)
        Tween(InfoCloseBtn, {TextTransparency = 1}, 0.3)
        Tween(InfoDesc, {TextTransparency = 1}, 0.3)
        if InfoExampleBox.Visible then Tween(InfoExampleText, {TextTransparency = 1}, 0.3) end
        task.wait(0.3)
        InfoOverlay.Visible = false
    end)

    local function AddInfoIcon(parent, pos, data)
        if not data then return end
        local Btn = Create("TextButton", {Parent = parent, Text = "?", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(35, 35, 40), Size = UDim2.new(0, 16, 0, 16), Position = pos, AutoButtonColor = false, ZIndex = 5})
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(1, 0)})
        AddBounce(Btn)
        Btn.MouseEnter:Connect(function() Tween(Btn, {TextColor3 = TextColor, BackgroundColor3 = AccentColor}, 0.2) end)
        Btn.MouseLeave:Connect(function() Tween(Btn, {TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(35, 35, 40)}, 0.2) end)
        Btn.MouseButton1Click:Connect(function() OpenInfoWindow(data) end)
    end

    local MainFrame = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = BackgroundColor, Size = UDim2.new(0, 650, 0, 420), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true, BackgroundTransparency = 1, Active = true})
    local MainScale = Create("UIScale", {Parent = MainFrame, Scale = 0.8})
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = MainFrame, Color = Color3.fromRGB(40, 40, 45), Thickness = 1})
    Tween(MainScale, {Scale = 1}, 0.5)
    Tween(MainFrame, {BackgroundTransparency = 0}, 0.5)

    -- Animate Background image muncul
    if BackgroundImageLabel then
        BackgroundImageLabel.ImageTransparency = 1
        Tween(BackgroundImageLabel, {ImageTransparency = backgroundTransparency}, 0.8)
        BackgroundOverlay.BackgroundTransparency = 0.6
        Tween(BackgroundOverlay, {BackgroundTransparency = 0.4}, 0.8)
    end

    -- Floating Bottom Bar
    local BottomDragHitbox = Create("Frame", {Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(0, 350, 0, 30), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 145, Active = true})

    local FloatingBottomBar = Create("Frame", {Parent = BottomDragHitbox, BackgroundColor3 = CardColor, BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), ZIndex = 146})
    Create("UICorner", {Parent = FloatingBottomBar, CornerRadius = UDim.new(1, 0)})
    local BottomBarStroke = Create("UIStroke", {Parent = FloatingBottomBar, Color = Color3.fromRGB(50, 50, 55), Thickness = 1.2, Transparency = 0})

    MakeDraggable(BottomDragHitbox, MainFrame)

    RunService.RenderStepped:Connect(function()
        if MainFrame and MainFrame.Visible then
            BottomDragHitbox.Visible = true
            local currentScale = MainScale.Scale
            local frameHeight = MainFrame.Size.Y.Offset * currentScale
            local frameWidth = MainFrame.Size.X.Offset * currentScale
            
            BottomDragHitbox.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + (frameHeight / 2) + 20)
            BottomDragHitbox.Size = UDim2.new(0, frameWidth * 0.6, 0, 30 * currentScale)
            FloatingBottomBar.Size = UDim2.new(1, 0, 0, 6 * currentScale)
            FloatingBottomBar.Position = UDim2.new(0, 0, 0.5, -(3 * currentScale))
        else
            BottomDragHitbox.Visible = false
        end
    end)

    local TopBar = Create("Frame", {Parent = MainFrame, BackgroundColor3 = BackgroundColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 0), Active = true})
    MakeDraggable(TopBar, MainFrame)
    
    local titleOffsetX = 15
    if topbarLogo then
        local TopbarIcon = Create("ImageLabel", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(0, logoSize, 0, logoSize), Position = UDim2.new(0, 8, 0.5, -(logoSize / 2)), Image = topbarLogo, ScaleType = Enum.ScaleType.Fit})
        titleOffsetX = 8 + logoSize + 8
    end

    local TitleContainer = Create("Frame", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(0, 160, 1, 0), Position = UDim2.new(0, titleOffsetX, 0, 0)})
    local Title = Create("TextLabel", {Parent = TitleContainer, Text = hubName, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 5), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left})
    local Subtitle = Create("TextLabel", {Parent = TitleContainer, Text = subText, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = subColor, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Left})

    local SearchBar = Create("Frame", {Parent = TopBar, BackgroundColor3 = CardColor, Size = UDim2.new(0, 250, 0, 26), Position = UDim2.new(0, 180, 0.5, -13)})
    Create("UICorner", {Parent = SearchBar, CornerRadius = UDim.new(0, 6)})
    local SearchIcon = Create("ImageLabel", {Parent = SearchBar, BackgroundTransparency = 1, Image = "rbxassetid://6031154871", ImageColor3 = SubTextColor, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 8, 0.5, -7)})
    local SearchInput = Create("TextBox", {Parent = SearchBar, BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 30, 0, 0), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, PlaceholderText = "Search..", TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})

    local CloseBtn = Create("TextButton", {Parent = TopBar, Text = "X", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -35, 0, 0)})
    local MinBtn = Create("TextButton", {Parent = TopBar, Text = "—", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -65, 0, 0)})

    local Sidebar = Create("Frame", {Parent = MainFrame, BackgroundColor3 = BackgroundColor, BackgroundTransparency = 1, Size = UDim2.new(0, 160, 1, -40), Position = UDim2.new(0, 0, 0, 40), Active = true})

    local TabSearchBox = Create("TextBox", {Parent = Sidebar, BackgroundColor3 = CardColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 5), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, PlaceholderText = "Search tabs...", TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
    Create("UIPadding", {Parent = TabSearchBox, PaddingLeft = UDim.new(0, 8)})
    Create("UICorner", {Parent = TabSearchBox, CornerRadius = UDim.new(0, 4)})
    local TabSearchStroke = Create("UIStroke", {Parent = TabSearchBox, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
    
    local TabContainer = Create("ScrollingFrame", {Parent = Sidebar, BackgroundTransparency = 1, Size = UDim2.new(1, -15, 1, -40), Position = UDim2.new(0, 10, 0, 40), ScrollBarThickness = 0})
    Create("UIListLayout", {Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    
    Create("Frame", {Parent = MainFrame, BackgroundColor3 = Color3.fromRGB(40, 40, 45), BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, -40), Position = UDim2.new(0, 160, 0, 40)})

    local ContentArea = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -165, 1, -40), Position = UDim2.new(0, 165, 0, 40), Active = true})

    -- USER PANEL
    if userEnabled then
        local UserPanel = Create("Frame", {Parent = MainFrame, BackgroundColor3 = CardColor, Size = UDim2.new(0, 140, 0, 50), Position = UDim2.new(0, 10, 1, -60), ZIndex = 10})
        Create("UICorner", {Parent = UserPanel, CornerRadius = UDim.new(0, 8)})
        Create("UIStroke", {Parent = UserPanel, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
        
        local avatarImage = ""
        if not userAnonymous then
            avatarImage = "rbxthumb://type=AvatarHeadShot&id=" .. game.Players.LocalPlayer.UserId .. "&w=150&h=150"
        end
        
        local Avatar = Create("ImageLabel", {Parent = UserPanel, BackgroundColor3 = Color3.fromRGB(30, 30, 35), Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 8, 0.5, -18), Image = avatarImage, ZIndex = 11})
        Create("UICorner", {Parent = Avatar, CornerRadius = UDim.new(1, 0)})
        
        Create("TextLabel", {Parent = UserPanel, Text = userAnonymous and "Anonymous" or game.Players.LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 0, 14), Position = UDim2.new(0, 50, 0, 10), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 11})
        
        Create("TextLabel", {Parent = UserPanel, Text = userSubtitle, Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 0, 12), Position = UDim2.new(0, 50, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 11})
    end

    local Sphere = Create("ImageButton", {Parent = ScreenGui, BackgroundColor3 = BackgroundColor, BackgroundTransparency = 0.2, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, AutoButtonColor = false, ImageTransparency = 1, ClipsDescendants = true})
    Create("UICorner", {Parent = Sphere, CornerRadius = UDim.new(1, 0)})
    Create("UIStroke", {Parent = Sphere, Color = AccentColor, Thickness = 2})
    
    local SphereImageLabel = Create("ImageLabel", {Parent = Sphere, BackgroundTransparency = 1, Size = UDim2.new(0, sphIconSize, 0, sphIconSize), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Image = sphImage or "", ImageTransparency = 1, Visible = (not sphTextToggle and sphImage ~= nil)})
    local SphereTextLabel = Create("TextLabel", {Parent = Sphere, Text = sphWords, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = AccentColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), TextTransparency = 1, Visible = sphTextToggle})
    MakeDraggable(Sphere, Sphere)

    local Window = {CurrentTab = nil, Tabs = {}, Title = Title, AllCards = {}, MainFrame = MainFrame, CurrentTransparency = 0, ConfigElements = {}}

    function Window:SetTransparency(val)
        Window.CurrentTransparency = val
        if MainFrame.Visible then
            Tween(MainFrame, {BackgroundTransparency = val}, 0.3)
            Tween(FloatingBottomBar, {BackgroundTransparency = val > 0 and 0.2 or 0}, 0.3)
        end
    end

    function Window:SetTheme(themeName)
        local theme = Themes[themeName]
        if not theme then return end
        CurrentTheme = themeName
        
        Tween(MainFrame, {BackgroundColor3 = theme.Background}, 0.3)
        Tween(FloatingBottomBar, {BackgroundColor3 = theme.Card}, 0.3)
        
        for _, data in ipairs(Window.AllCards) do
            Tween(data.Card, {BackgroundColor3 = theme.Card}, 0.3)
        end
        
        for _, tabInfo in ipairs(Window.Tabs) do
            Tween(tabInfo.Button, {BackgroundColor3 = theme.Hover}, 0.3)
            Tween(tabInfo.Txt, {TextColor3 = theme.Text}, 0.3)
        end
        
        for _, desc in ipairs(MainFrame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                pcall(function()
                    if desc.TextColor3 == TextColor then
                        Tween(desc, {TextColor3 = theme.Text}, 0.3)
                    elseif desc.TextColor3 == SubTextColor then
                        Tween(desc, {TextColor3 = theme.SubText}, 0.3)
                    elseif desc.TextColor3 == AccentColor then
                        Tween(desc, {TextColor3 = theme.Accent}, 0.3)
                    end
                end)
            end
        end
        
        for _, desc in ipairs(MainFrame:GetDescendants()) do
            if desc:IsA("Frame") then
                pcall(function()
                    if desc.BackgroundColor3 == BackgroundColor then
                        Tween(desc, {BackgroundColor3 = theme.Background}, 0.3)
                    elseif desc.BackgroundColor3 == CardColor then
                        Tween(desc, {BackgroundColor3 = theme.Card}, 0.3)
                    elseif desc.BackgroundColor3 == HoverColor then
                        Tween(desc, {BackgroundColor3 = theme.Hover}, 0.3)
                    end
                end)
            end
        end
        
        Library:Notify({
            Title = "THEME",
            Description = "Theme: " .. themeName,
            Icon = "rbxassetid://10734910430",
            Type = "Info",
            Duration = 2
        })
    end

    MinBtn.MouseButton1Click:Connect(function()
        Tween(MainScale, {Scale = 0}, 0.4)
        Tween(MainFrame, {BackgroundTransparency = 1}, 0.4)
        Tween(FloatingBottomBar, {BackgroundTransparency = 1}, 0.4)
        Tween(BottomBarStroke, {Transparency = 1}, 0.4)
        task.wait(0.3)
        MainFrame.Visible = false
        BottomDragHitbox.Visible = false
        Sphere.Visible = true
        Tween(Sphere, {Size = UDim2.new(0, 50, 0, 50)}, 0.4)
        
        if not sphTextToggle and sphImage then
            Tween(SphereImageLabel, {ImageTransparency = 0}, 0.4)
        elseif sphTextToggle then
            Tween(SphereTextLabel, {TextTransparency = 0}, 0.4)
        end
    end)

    Sphere.MouseButton1Click:Connect(function()
        Tween(Sphere, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        
        if not sphTextToggle and sphImage then Tween(SphereImageLabel, {ImageTransparency = 1}, 0.3) end
        if sphTextToggle then Tween(SphereTextLabel, {TextTransparency = 1}, 0.3) end
        
        task.wait(0.2)
        Sphere.Visible = false
        MainFrame.Visible = true
        BottomDragHitbox.Visible = true
        Tween(MainScale, {Scale = 1}, 0.4)
        Tween(MainFrame, {BackgroundTransparency = Window.CurrentTransparency}, 0.4)
        Tween(FloatingBottomBar, {BackgroundTransparency = Window.CurrentTransparency > 0 and 0.2 or 0}, 0.4)
        Tween(BottomBarStroke, {Transparency = 0}, 0.4)
    end)

    local Popup = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 100, Visible = false, Active = true})
    local PopupCard = Create("Frame", {Parent = Popup, BackgroundColor3 = Color3.fromRGB(20, 20, 24), Size = UDim2.new(0, 320, 0, 160), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 101, BackgroundTransparency = 1, ClipsDescendants = false})
    Create("UICorner", {Parent = PopupCard, CornerRadius = UDim.new(0, 12)})
    local PopupScale = Create("UIScale", {Parent = PopupCard, Scale = 0.8})
    local PopupStroke = Create("UIStroke", {Parent = PopupCard, Color = Color3.fromRGB(50, 50, 55), Thickness = 1, Transparency = 1})
    local PopupTitle = Create("TextLabel", {Parent = PopupCard, Text = "Exit Application", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 25), ZIndex = 102, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center})
    local PopupText = Create("TextLabel", {Parent = PopupCard, Text = "Are you sure you want to close Foxy?", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 0, 55), ZIndex = 102, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true})
    local YesBtn = Create("TextButton", {Parent = PopupCard, Text = "Confirm", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = AccentColor, Size = UDim2.new(0, 125, 0, 36), Position = UDim2.new(0.5, 10, 0, 105), ZIndex = 102, BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false})
    Create("UICorner", {Parent = YesBtn, CornerRadius = UDim.new(0, 6)})
    AddBounce(YesBtn)
    local NoBtn = Create("TextButton", {Parent = PopupCard, Text = "Cancel", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(40, 40, 45), Size = UDim2.new(0, 125, 0, 36), Position = UDim2.new(0.5, -135, 0, 105), ZIndex = 102, BackgroundTransparency = 1, TextTransparency = 1, AutoButtonColor = false})
    Create("UICorner", {Parent = NoBtn, CornerRadius = UDim.new(0, 6)})
    AddBounce(NoBtn)

    CloseBtn.MouseButton1Click:Connect(function()
        Popup.Visible = true
        Tween(Popup, {BackgroundTransparency = 0.5}, 0.3)
        Tween(PopupCard, {BackgroundTransparency = 0}, 0.3)
        Tween(PopupScale, {Scale = 1}, 0.3)
        Tween(PopupStroke, {Transparency = 0}, 0.3)
        Tween(PopupTitle, {TextTransparency = 0}, 0.3)
        Tween(PopupText, {TextTransparency = 0}, 0.3)
        Tween(YesBtn, {BackgroundTransparency = 0, TextTransparency = 0}, 0.3)
        Tween(NoBtn, {BackgroundTransparency = 0, TextTransparency = 0}, 0.3)
    end)

    YesBtn.MouseButton1Click:Connect(function()
        Tween(Popup, {BackgroundTransparency = 1}, 0.3)
        Tween(PopupCard, {BackgroundTransparency = 1}, 0.3)
        Tween(PopupStroke, {Transparency = 1}, 0.3)
        Tween(PopupTitle, {TextTransparency = 1}, 0.3)
        Tween(PopupText, {TextTransparency = 1}, 0.3)
        Tween(YesBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        Tween(NoBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        Tween(MainScale, {Scale = 0.8}, 0.3)
        Tween(MainFrame, {BackgroundTransparency = 1}, 0.3)
        Tween(FloatingBottomBar, {BackgroundTransparency = 1}, 0.3)
        Tween(BottomBarStroke, {Transparency = 1}, 0.3)
        if BackgroundImageLabel then
            Tween(BackgroundImageLabel, {ImageTransparency = 1}, 0.3)
            Tween(BackgroundOverlay, {BackgroundTransparency = 1}, 0.3)
        end

        for _, desc in ipairs(MainFrame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then Tween(desc, {TextTransparency = 1}, 0.3) if desc.BackgroundTransparency < 1 then Tween(desc, {BackgroundTransparency = 1}, 0.3) end
            elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then Tween(desc, {ImageTransparency = 1}, 0.3)
            elseif desc:IsA("Frame") or desc:IsA("ScrollingFrame") then if desc.BackgroundTransparency < 1 then Tween(desc, {BackgroundTransparency = 1}, 0.3) end
            elseif desc:IsA("UIStroke") then Tween(desc, {Transparency = 1}, 0.3) end
        end
        task.wait(0.35)
        ScreenGui:Destroy()
    end)

    NoBtn.MouseButton1Click:Connect(function()
        Tween(Popup, {BackgroundTransparency = 1}, 0.3)
        Tween(PopupCard, {BackgroundTransparency = 1}, 0.3)
        Tween(PopupScale, {Scale = 0.8}, 0.3)
        Tween(PopupStroke, {Transparency = 1}, 0.3)
        Tween(PopupTitle, {TextTransparency = 1}, 0.3)
        Tween(PopupText, {TextTransparency = 1}, 0.3)
        Tween(YesBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        Tween(NoBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
        task.wait(0.3)
        Popup.Visible = false
    end)

    local resizeBtn = Create("TextButton", {Parent = MainFrame, Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -28, 1, -28), BackgroundColor3 = CardColor, Text = "↘", TextColor3 = AccentColor, Font = Enum.Font.GothamBlack, TextSize = 14, AutoButtonColor = false, ZIndex = 20})
    Create("UICorner", {Parent = resizeBtn, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = resizeBtn, Color = AccentColor, Thickness = 1, Transparency = 0.45})
    AddBounce(resizeBtn, 0.9)

    local resizing = false
    local resizeStart = nil
    local startSize = nil

    resizeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = MainFrame.Size
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newWidth = math.clamp(startSize.X.Offset + delta.X, 400, 1000)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, 300, 700)
            Tween(MainFrame, {Size = UDim2.new(0, newWidth, 0, newHeight)}, 0.05)
        end
    end)

    TabSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = TabSearchBox.Text:lower()
        for _, tabInfo in ipairs(Window.Tabs) do
            if query == "" or string.find(tabInfo.Txt.Text:lower(), query) then
                tabInfo.Button.Visible = true
            else
                tabInfo.Button.Visible = false
            end
        end
    end)

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchInput.Text:lower()
        if query == "" then
            for _, data in ipairs(Window.AllCards) do
                data.Card.Parent = data.OrigParent
                data.Card.Visible = true
            end
        else
            if not Window.CurrentTab or not Window.CurrentTab.CurrentPage then return end
            local activeLeft = Window.CurrentTab.CurrentPage.LeftCol
            local activeRight = Window.CurrentTab.CurrentPage.RightCol
            local placeLeft = true
            
            for _, data in ipairs(Window.AllCards) do
                local card = data.Card
                if data.Tab == Window.CurrentTab then
                    if not data.SearchIndex then
                        data.SearchIndex = BuildSearchIndex(card)
                    end
                    local match = string.find(data.SearchIndex, query, 1, true)
                    if match then
                        card.Parent = placeLeft and activeLeft or activeRight
                        placeLeft = not placeLeft
                        card.Visible = true
                    else
                        card.Visible = false
                    end
                else
                    card.Parent = data.OrigParent
                    card.Visible = true
                end
            end
        end
    end)

    function Window:CreateTab(tabName, isDefault, isLocked, icon)
        local isWhitelisted = false
        local player = game:GetService("Players").LocalPlayer
        if player then
            for _, allowedUser in ipairs(Library.WhitelistedUsers) do
                if player.Name == allowedUser or player.DisplayName == allowedUser then
                    isWhitelisted = true
                    break
                end
            end
        end

        local TabBtn = Create("TextButton", {Parent = TabContainer, Text = "", BackgroundColor3 = HoverColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), AutoButtonColor = false})
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
        AddBounce(TabBtn, 0.98)
        local Indicator = Create("Frame", {Name = "Indicator", Parent = TabBtn, BackgroundColor3 = isLocked and Color3.fromRGB(255, 215, 0) or AccentColor, Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)})
        Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1, 0)})
        
        local txtOffset = 15
        if icon then
            Create("ImageLabel", {Parent = TabBtn, Name = "TabIcon", BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 12, 0.5, -8), Image = icon, ImageColor3 = SubTextColor, ZIndex = 2})
            txtOffset = 36
        end
        
        local Txt = Create("TextLabel", {Parent = TabBtn, Text = tabName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, txtOffset, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})

        if isLocked then
            Create("ImageLabel", {Parent = TabBtn, Image = "rbxassetid://6031082533", ImageColor3 = Color3.fromRGB(255, 215, 0), BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -22, 0.5, -7)})
        end

        local TabContent = Create("Frame", {Parent = ContentArea, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false})
        local PageNav = Create("Frame", {Parent = TabContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35)})
        Create("UIListLayout", {Parent = PageNav, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 15), VerticalAlignment = Enum.VerticalAlignment.Center})
        local PageContainer = Create("Frame", {Parent = TabContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -35), Position = UDim2.new(0, 0, 0, 35)})

        local TabConfig = {Button = TabBtn, Content = TabContent, Indicator = Indicator, Txt = Txt, Pages = {}, CurrentPage = nil}
        table.insert(Window.Tabs, TabConfig)

        TabBtn.MouseButton1Click:Connect(function()
            if isLocked and not isWhitelisted then
                SendPremiumNotification()
                return
            end

            if Window.CurrentTab == TabConfig then return end
            
            if Window.CurrentTab then
                Tween(Window.CurrentTab.Button, {BackgroundTransparency = 1}, 0.2)
                Tween(Window.CurrentTab.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
                Tween(Window.CurrentTab.Txt, {TextColor3 = SubTextColor}, 0.2)
                
                local oldIcon = Window.CurrentTab.Button:FindFirstChild("TabIcon")
                if oldIcon then Tween(oldIcon, {ImageColor3 = SubTextColor}, 0.2) end
                
                Window.CurrentTab.Content.Visible = false
            end
            
            Window.CurrentTab = TabConfig
            TabConfig.Content.Visible = true
            
            TabConfig.Content.Position = UDim2.new(0, 0, 0, 15)
            Tween(TabConfig.Content, {Position = UDim2.new(0, 0, 0, 0)}, 0.35)

            Tween(TabBtn, {BackgroundTransparency = 0}, 0.2)
            Tween(Indicator, {Size = UDim2.new(0, 3, 0, 18)}, 0.3)
            Tween(Txt, {TextColor3 = TextColor}, 0.2)
            
            local currentIcon = TabBtn:FindFirstChild("TabIcon")
            if currentIcon then Tween(currentIcon, {ImageColor3 = TextColor}, 0.2) end

            if #TabConfig.Pages > 0 then
                local firstPage = TabConfig.Pages[1]
                if TabConfig.CurrentPage ~= firstPage then
                    if TabConfig.CurrentPage then
                        Tween(TabConfig.CurrentPage.Btn, {TextColor3 = SubTextColor}, 0)
                        Tween(TabConfig.CurrentPage.Highlight, {Size = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1}, 0)
                        TabConfig.CurrentPage.Scroll.Visible = false
                    end
                    TabConfig.CurrentPage = firstPage
                    firstPage.Scroll.Visible = true
                    
                    firstPage.Scroll.Position = UDim2.new(0, 5, 0, 15)
                    Tween(firstPage.Scroll, {Position = UDim2.new(0, 5, 0, 5)}, 0.35)

                    Tween(firstPage.Btn, {TextColor3 = TextColor}, 0)
                    Tween(firstPage.Highlight, {Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 0}, 0)
                end
            end
        end)

        function TabConfig:CreatePage(pageName)
            local PageBtn = Create("TextButton", {Parent = PageNav, Text = pageName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X})
            local PageHighlight = Create("Frame", {Parent = PageBtn, BackgroundColor3 = AccentColor, Size = UDim2.new(0, 0, 0, 2), Position = UDim2.new(0.5, 0, 1, -5), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1})
            local PageScroll = Create("ScrollingFrame", {Parent = PageContainer, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5), ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65), Visible = false, BorderSizePixel = 0})

            local LeftColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 1, 0)})
            local RightColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0)})
            
            local L_Layout = Create("UIListLayout", {Parent = LeftColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
            local R_Layout = Create("UIListLayout", {Parent = RightColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
            
            L_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() PageScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(L_Layout.AbsoluteContentSize.Y, R_Layout.AbsoluteContentSize.Y) + 20) end)
            R_Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() PageScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(L_Layout.AbsoluteContentSize.Y, R_Layout.AbsoluteContentSize.Y) + 20) end)

            local PageObj = {Scroll = PageScroll, Btn = PageBtn, Highlight = PageHighlight, Left = true, LeftCol = LeftColumn, RightCol = RightColumn}
            table.insert(TabConfig.Pages, PageObj)

            PageBtn.MouseButton1Click:Connect(function()
                if TabConfig.CurrentPage == PageObj then return end
                if TabConfig.CurrentPage then
                    Tween(TabConfig.CurrentPage.Btn, {TextColor3 = SubTextColor}, 0.2)
                    Tween(TabConfig.CurrentPage.Highlight, {Size = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 1}, 0.2)
                    TabConfig.CurrentPage.Scroll.Visible = false
                end
                TabConfig.CurrentPage = PageObj
                PageObj.Scroll.Visible = true
                
                PageObj.Scroll.Position = UDim2.new(0, 5, 0, 20)
                Tween(PageObj.Scroll, {Position = UDim2.new(0, 5, 0, 5)}, 0.35)

                Tween(PageBtn, {TextColor3 = TextColor}, 0.2)
                Tween(PageHighlight, {Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 0}, 0.3)
            end)

            if #TabConfig.Pages == 1 and not isLocked then
                TabConfig.CurrentPage = PageObj
                PageObj.Scroll.Visible = true
                PageBtn.TextColor3 = TextColor
                PageHighlight.Size = UDim2.new(1, 0, 0, 2)
                PageHighlight.BackgroundTransparency = 0
            end

            function PageObj:CreateSection(sectionName, icon)
                local targetColumn = PageObj.Left and LeftColumn or RightColumn
                PageObj.Left = not PageObj.Left

                local SectionContainer = Create("Frame", {Parent = targetColumn, BackgroundColor3 = CardColor, Size = UDim2.new(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true})
                Create("UICorner", {Parent = SectionContainer, CornerRadius = UDim.new(0, 6)})
                
                table.insert(Window.AllCards, {Card = SectionContainer, OrigParent = targetColumn, Tab = TabConfig, Page = PageObj, SearchIndex = nil})
                
                local titleOffset = 10
                if icon then
                    Create("ImageLabel", {Parent = SectionContainer, Name = "SectionIcon", BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0, 8), Image = icon, ImageColor3 = AccentColor, ZIndex = 2})
                    titleOffset = 30
                end
                
                Create("TextLabel", {Parent = SectionContainer, Text = sectionName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20 - titleOffset, 0, 30), Position = UDim2.new(0, titleOffset, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                local ItemContainer = Create("Frame", {Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y})
                Create("UIPadding", {Parent = ItemContainer, PaddingBottom = UDim.new(0, 10), PaddingTop = UDim.new(0, 5)})
                Create("UIListLayout", {Parent = ItemContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})

                local Elements = {}

                function Elements:AddButton(name, callback, infoData, icon)
                    local BtnFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30)})
                    local Btn = Create("TextButton", {Parent = BtnFrame, Text = "", BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), AutoButtonColor = false})
                    Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = Btn, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})

                    local iconOffset = 10
                    if icon then
                        Create("ImageLabel", {Parent = Btn, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 8, 0.5, -7), Image = icon, ImageColor3 = AccentColor})
                        iconOffset = 28
                    end

                    Create("TextLabel", {Parent = Btn, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -iconOffset - 10, 1, 0), Position = UDim2.new(0, iconOffset, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})

                    AddBounce(Btn)
                    Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = HoverColor}, 0.2) end)
                    Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = BackgroundColor}, 0.2) end)
                    Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
                    AddInfoIcon(BtnFrame, UDim2.new(1, -40, 0.5, -8), infoData)
                end

                function Elements:AddToggle(name, default, callback, infoData, icon)
                    local state = default or false
                    local TogFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24)})
                    
                    local iconOffset = 10
                    if icon then
                        Create("ImageLabel", {Parent = TogFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 10, 0.5, -8), Image = icon, ImageColor3 = AccentColor})
                        iconOffset = 32
                    end
                    
                    Create("TextLabel", {Parent = TogFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -60 - iconOffset, 1, 0), Position = UDim2.new(0, iconOffset, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    
                    local Lever = Create("TextButton", {Parent = TogFrame, Text = "", BackgroundColor3 = state and AccentColor or Color3.fromRGB(45, 45, 50), Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -46, 0.5, -9), AutoButtonColor = false})
                    Create("UICorner", {Parent = Lever, CornerRadius = UDim.new(1, 0)})
                    AddBounce(Lever)
                    
                    local Knob = Create("Frame", {Parent = Lever, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(0, 14, 0, 14), Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
                    Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})

                    local function internalSet(val)
                        state = val
                        Tween(Lever, {BackgroundColor3 = state and AccentColor or Color3.fromRGB(45, 45, 50)}, 0.3)
                        Tween(Knob, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.3)
                        if callback then callback(state) end
                    end

                    Lever.MouseButton1Click:Connect(function() internalSet(not state) end)
                    AddInfoIcon(TogFrame, UDim2.new(1, -70, 0.5, -8), infoData)
                    Window.ConfigElements[name] = {Set = internalSet, Get = function() return state end}
                end

                function Elements:AddDropdown(name, options, isMulti, callback, infoData, icon)
                    local selected = isMulti and {} or (options[1] or nil)
                    local dropped = false
                    local optionButtons = {}
                    local maxVisible = math.min(#options, 3)
                    local listHeight = maxVisible * 25
                    
                    local DropFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), ClipsDescendants = true})
                    
                    local iconOffset = 10
                    if icon then
                        Create("ImageLabel", {Parent = DropFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0, 0), Image = icon, ImageColor3 = AccentColor})
                        iconOffset = 30
                    end
                    
                    Create("TextLabel", {Parent = DropFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20 - iconOffset, 0, 15), Position = UDim2.new(0, iconOffset, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    
                    local MainBtn = Create("TextButton", {Parent = DropFrame, Text = isMulti and "Select Options..." or "Select...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 20), AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left})
                    Create("UIPadding", {Parent = MainBtn, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = MainBtn, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = MainBtn, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    AddBounce(MainBtn, 0.98)
                    local Arrow = Create("TextLabel", {Parent = MainBtn, Text = "▼", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -28, 0, 0)})

                    local SearchBox = Create("TextBox", {Parent = DropFrame, PlaceholderText = "Search...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = Color3.fromRGB(15, 15, 18), Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 50), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Visible = false})
                    Create("UIPadding", {Parent = SearchBox, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = SearchBox, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = SearchBox, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})

                    local ListFrame = Create("ScrollingFrame", {Parent = DropFrame, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, listHeight), Position = UDim2.new(0, 10, 0, 78), CanvasSize = UDim2.new(0, 0, 0, #options * 25), ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85), BorderSizePixel = 0})
                    Create("UICorner", {Parent = ListFrame, CornerRadius = UDim.new(0, 4)})
                    local DList = Create("UIListLayout", {Parent = ListFrame, SortOrder = Enum.SortOrder.LayoutOrder})

                    local function UpdateText()
                        if isMulti then
                            local txt = ""
                            for _, v in pairs(selected) do txt = txt .. v .. ", " end
                            MainBtn.Text = txt == "" and "Select Options..." or txt:sub(1, -3)
                        else
                            MainBtn.Text = selected or "Select..."
                        end
                    end

                    local function internalSet(v)
                        selected = v
                        UpdateText()
                        for _, btn in ipairs(optionButtons) do
                            local isSel = false
                            if isMulti then
                                isSel = table.find(selected, btn.Text) ~= nil
                            else
                                isSel = (selected == btn.Text)
                            end
                            Tween(btn, {TextColor3 = isSel and TextColor or SubTextColor}, 0.2)
                            Tween(btn:FindFirstChild("Frame"), {Size = isSel and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0)}, 0.2)
                        end
                        if callback then callback(selected) end
                    end

                    for _, opt in pairs(options) do
                        local isInitialSelected = (not isMulti and selected == opt)
                        local OptBtn = Create("TextButton", {Parent = ListFrame, Text = opt, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = isInitialSelected and TextColor or SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), AutoButtonColor = false})
                        Create("Frame", {Parent = OptBtn, BackgroundColor3 = AccentColor, Size = isInitialSelected and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0), BackgroundTransparency = 0.8})
                        table.insert(optionButtons, OptBtn)
                        
                        OptBtn.MouseButton1Click:Connect(function()
                            if isMulti then
                                if table.find(selected, opt) then
                                    table.remove(selected, table.find(selected, opt))
                                else
                                    table.insert(selected, opt)
                                end
                                internalSet(selected)
                            else
                                internalSet(opt)
                                dropped = false
                                Tween(Arrow, {Rotation = 0}, 0.3)
                                Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 50)}, 0.3)
                                SearchBox.Visible = false
                            end
                        end)
                    end
                    UpdateText()

                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = SearchBox.Text:lower()
                        for _, btn in ipairs(optionButtons) do
                            if q == "" or string.find(btn.Text:lower(), q) then btn.Visible = true else btn.Visible = false end
                        end
                    end)

                    DList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        ListFrame.CanvasSize = UDim2.new(0, 0, 0, DList.AbsoluteContentSize.Y)
                        if dropped then
                            local dynamicHeight = math.min(DList.AbsoluteContentSize.Y, listHeight)
                            local newOpenHeight = 50 + 32 + dynamicHeight
                            ListFrame.Size = UDim2.new(1, -20, 0, dynamicHeight)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, newOpenHeight)}, 0.1)
                        end
                    end)

                    MainBtn.MouseButton1Click:Connect(function()
                        dropped = not dropped
                        if dropped then
                            SearchBox.Visible = true
                            SearchBox.Text = ""
                            Tween(Arrow, {Rotation = 180}, 0.3)
                            local dynamicHeight = math.min(DList.AbsoluteContentSize.Y, listHeight)
                            local newOpenHeight = 50 + 32 + dynamicHeight
                            ListFrame.Size = UDim2.new(1, -20, 0, dynamicHeight)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, newOpenHeight)}, 0.3)
                        else
                            SearchBox.Visible = false
                            Tween(Arrow, {Rotation = 0}, 0.3)
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 50)}, 0.3)
                        end
                    end)
                    AddInfoIcon(DropFrame, UDim2.new(1, -25, 0, 0), infoData)
                    Window.ConfigElements[name] = {Set = internalSet, Get = function() return selected end}
                end

                function Elements:AddTextbox(name, placeholder, callback, infoData, icon)
                    local TxtFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50)})
                    
                    local iconOffset = 10
                    if icon then
                        Create("ImageLabel", {Parent = TxtFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0, 0), Image = icon, ImageColor3 = AccentColor})
                        iconOffset = 30
                    end
                    
                    Create("TextLabel", {Parent = TxtFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20 - iconOffset, 0, 15), Position = UDim2.new(0, iconOffset, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    local Input = Create("TextBox", {Parent = TxtFrame, PlaceholderText = placeholder or "Type here...", Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                    Create("UIPadding", {Parent = Input, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = Input, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = Input, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})

                    local function internalSet(v)
                        Input.Text = tostring(v)
                        if callback then callback(v) end
                    end

                    Input.FocusLost:Connect(function(enterPressed) internalSet(Input.Text) end)
                    AddInfoIcon(TxtFrame, UDim2.new(1, -25, 0, 0), infoData)
                    Window.ConfigElements[name] = {Set = internalSet, Get = function() return Input.Text end}
                end

                function Elements:AddColorPicker(name, defaultColor, callback, infoData, icon)
                    local color = defaultColor or Color3.fromRGB(255, 255, 255)
                    local h, s, v_hsv = color:ToHSV()
                    local dropped = false
                    
                    local CFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ClipsDescendants = true})
                    
                    local iconOffset = 10
                    if icon then
                        Create("ImageLabel", {Parent = CFrame, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0.5, -7), Image = icon, ImageColor3 = AccentColor})
                        iconOffset = 30
                    end
                    
                    Create("TextLabel", {Parent = CFrame, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -60 - iconOffset, 0, 30), Position = UDim2.new(0, iconOffset, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                    local DisplayBtn = Create("TextButton", {Parent = CFrame, Text = "", BackgroundColor3 = color, Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -40, 0.5, -8), AutoButtonColor = false})
                    Create("UICorner", {Parent = DisplayBtn, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = DisplayBtn, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8, Thickness = 1})
                    AddBounce(DisplayBtn)

                    local PickerArea = Create("Frame", {Parent = CFrame, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 140), Position = UDim2.new(0, 10, 0, 35)})
                    Create("UICorner", {Parent = PickerArea, CornerRadius = UDim.new(0, 4)})

                    local PickerClose = Create("TextButton", {Parent = PickerArea, Text = "X", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = SubTextColor, BackgroundColor3 = Color3.fromRGB(30, 20, 20), Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -22, 0, 4), ZIndex = 50, AutoButtonColor = false})
                    Create("UICorner", {Parent = PickerClose, CornerRadius = UDim.new(0, 4)})
                    AddBounce(PickerClose)
                    PickerClose.MouseButton1Click:Connect(function() dropped = false Tween(CFrame, {Size = UDim2.new(1, 0, 0, 30)}, 0.3) end)

                    local SVMap = Create("TextButton", {Parent = PickerArea, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), Size = UDim2.new(1, -45, 0, 90), Position = UDim2.new(0, 10, 0, 10), AutoButtonColor = false, Active = true})
                    Create("UICorner", {Parent = SVMap, CornerRadius = UDim.new(0, 4)})
                    
                    local WhiteGrad = Create("Frame", {Parent = SVMap, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2})
                    Create("UIGradient", {Parent = WhiteGrad, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Rotation = 0})
                    local BlackGrad = Create("Frame", {Parent = SVMap, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 3})
                    Create("UIGradient", {Parent = BlackGrad, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}), Rotation = 90})
                    
                    local SVRing = Create("Frame", {Parent = BlackGrad, Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1 - v_hsv, 0), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4})
                    Create("UICorner", {Parent = SVRing, CornerRadius = UDim.new(1, 0)})
                    Create("UIStroke", {Parent = SVRing, Color = Color3.new(0, 0, 0), Thickness = 1})

                    local HueSlider = Create("TextButton", {Parent = PickerArea, Text = "", Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 110), AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), Active = true})
                    Create("UICorner", {Parent = HueSlider, CornerRadius = UDim.new(0, 4)})
                    Create("UIGradient", {Parent = HueSlider, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))})})
                    local HueRing = Create("Frame", {Parent = HueSlider, Size = UDim2.new(0, 6, 0, 15), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1)})
                    Create("UICorner", {Parent = HueRing, CornerRadius = UDim.new(0, 2)})
                    Create("UIStroke", {Parent = HueRing, Color = Color3.new(0, 0, 0), Thickness = 1})

                    local function internalSet(hexString)
                        local s_check, c = pcall(function() return Color3.fromHex(hexString) end)
                        if s_check then
                            color = c
                            h, s, v_hsv = color:ToHSV()
                            DisplayBtn.BackgroundColor3 = color
                            SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                            SVRing.Position = UDim2.new(s, 0, 1 - v_hsv, 0)
                            HueRing.Position = UDim2.new(h, 0, 0.5, 0)
                            if callback then callback(color) end
                        end
                    end

                    local function UpdateColor()
                        color = Color3.fromHSV(h, s, v_hsv)
                        DisplayBtn.BackgroundColor3 = color
                        SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        if callback then callback(color) end
                    end

                    local draggingSV, draggingHue = false, false
                    
                    SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV = true if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = false end end end)
                    HueSlider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingHue = true if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = false end end end)
                    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV = false draggingHue = false if PageObj and PageObj.Scroll then PageObj.Scroll.ScrollingEnabled = true end end end)

                    UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            if draggingSV then
                                local relX = math.clamp((input.Position.X - SVMap.AbsolutePosition.X) / SVMap.AbsoluteSize.X, 0, 1)
                                local relY = math.clamp((input.Position.Y - SVMap.AbsolutePosition.Y) / SVMap.AbsoluteSize.Y, 0, 1)
                                s = relX
                                v_hsv = 1 - relY
                                SVRing.Position = UDim2.new(s, 0, 1 - v_hsv, 0)
                                UpdateColor()
                            elseif draggingHue then
                                local relX = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                                h = relX
                                HueRing.Position = UDim2.new(h, 0, 0.5, 0)
                                UpdateColor()
                            end
                        end
                    end)

                    DisplayBtn.MouseButton1Click:Connect(function() dropped = not dropped Tween(CFrame, {Size = UDim2.new(1, 0, 0, dropped and 185 or 30)}, 0.3) end)
                    AddInfoIcon(CFrame, UDim2.new(1, -65, 0, 7), infoData)
                    Window.ConfigElements[name] = {Set = internalSet, Get = function() return color:ToHex() end}
                end

                function Elements:AddConfigManager(folderName)
                    folderName = folderName or "NyxHub"
                    if not _isfolder(folderName) then _makefolder(folderName) end

                    local ManagerFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 280)})

                    Create("TextLabel", {Parent = ManagerFrame, Text = "Config Manager", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})

                    local SearchBox = Create("TextBox", {Parent = ManagerFrame, PlaceholderText = "Search config...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                    Create("UIPadding", {Parent = SearchBox, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = SearchBox, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = SearchBox, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})

                    local ConfigList = Create("ScrollingFrame", {Parent = ManagerFrame, BackgroundColor3 = Color3.fromRGB(15, 15, 18), Size = UDim2.new(1, -20, 0, 120), Position = UDim2.new(0, 10, 0, 62), ScrollBarThickness = 2, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0)})
                    Create("UICorner", {Parent = ConfigList, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = ConfigList, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                    local ListLayout = Create("UIListLayout", {Parent = ConfigList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
                    Create("UIPadding", {Parent = ConfigList, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

                    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        ConfigList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
                    end)

                    local NameInput = Create("TextBox", {Parent = ManagerFrame, PlaceholderText = "Config name...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 190), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                    Create("UIPadding", {Parent = NameInput, PaddingLeft = UDim.new(0, 8)})
                    Create("UICorner", {Parent = NameInput, CornerRadius = UDim.new(0, 4)})
                    Create("UIStroke", {Parent = NameInput, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})

                    local ButtonRow = Create("Frame", {Parent = ManagerFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 224)})
                    Create("UIListLayout", {Parent = ButtonRow, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})

                    local function CreateActionBtn(text, color, callback)
                        local btn = Create("TextButton", {Parent = ButtonRow, Text = text, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = color, Size = UDim2.new(0.33, -4, 1, 0), AutoButtonColor = false})
                        Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 4)})
                        AddBounce(btn)
                        btn.MouseButton1Click:Connect(callback)
                        return btn
                    end

                    local function RefreshConfigList()
                        for _, v in ipairs(ConfigList:GetChildren()) do
                            if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end
                        end
                        
                        local files = _listfiles(folderName)
                        if #files == 0 then
                            Create("TextLabel", {Parent = ConfigList, Text = "No configs found", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center})
                            return
                        end
                        
                        for _, filepath in ipairs(files) do
                            local rawName = filepath:match("([^/\\]+)%.json$")
                            if rawName then
                                local displayName = rawName
                                
                                local Row = Create("Frame", {Parent = ConfigList, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, 0, 0, 30)})
                                Create("UICorner", {Parent = Row, CornerRadius = UDim.new(0, 4)})
                                
                                Create("TextLabel", {Parent = Row, Text = displayName, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                                
                                local LoadBtn = Create("TextButton", {Parent = Row, Text = "Load", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(45, 120, 60), Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -48, 0.5, -10), AutoButtonColor = false})
                                Create("UICorner", {Parent = LoadBtn, CornerRadius = UDim.new(0, 4)})
                                AddBounce(LoadBtn)
                                
                                local DeleteBtn = Create("TextButton", {Parent = Row, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(180, 50, 50), Size = UDim2.new(0, 24, 0, 20), Position = UDim2.new(1, -24, 0.5, -10), AutoButtonColor = false})
                                Create("UICorner", {Parent = DeleteBtn, CornerRadius = UDim.new(0, 4)})
                                AddBounce(DeleteBtn)
                                
                                LoadBtn.MouseButton1Click:Connect(function()
                                    local s, data = pcall(function() return HttpService:JSONDecode(_readfile(filepath)) end)
                                    if s and type(data) == "table" then
                                        for k, v in pairs(data) do
                                            if Window.ConfigElements[k] and Window.ConfigElements[k].Set then
                                                Window.ConfigElements[k].Set(v)
                                            end
                                        end
                                        Library:Notify({Title = "Config Loaded", Description = displayName .. " berhasil di-load!", Icon = "rbxassetid://10723344270", Type = "Success", Duration = 3})
                                    end
                                end)
                                
                                DeleteBtn.MouseButton1Click:Connect(function()
                                    pcall(function() _delfile(filepath) end)
                                    RefreshConfigList()
                                    Library:Notify({Title = "Deleted", Description = displayName .. " dihapus!", Icon = "rbxassetid://10747362393", Type = "Info", Duration = 2})
                                end)
                            end
                        end
                    end

                    CreateActionBtn("Save", Color3.fromRGB(45, 120, 60), function()
                        local name = NameInput.Text
                        if name == "" then
                            Library:Notify({Title = "Error", Description = "Nama config kosong!", Icon = "rbxassetid://10709752996", Type = "Error"})
                            return
                        end
                        
                        local payload = {}
                        for k, el in pairs(Window.ConfigElements) do
                            if el.Get then payload[k] = el.Get() end
                        end
                        
                        local encoded = HttpService:JSONEncode(payload)
                        local finalPath = folderName .. "/" .. name .. ".json"
                        _writefile(finalPath, encoded)
                        RefreshConfigList()
                        Library:Notify({Title = "Saved", Description = "Config '" .. name .. "' tersimpan!", Icon = "rbxassetid://10734941499", Type = "Success", Duration = 3})
                    end)
                    
                    CreateActionBtn("Refresh", Color3.fromRGB(50, 100, 180), function()
                        RefreshConfigList()
                        Library:Notify({Title = "Refreshed", Description = "List config diupdate", Icon = "rbxassetid://10734933222", Type = "Info", Duration = 2})
                    end)
                    
                    CreateActionBtn("Clear", Color3.fromRGB(60, 60, 65), function()
                        NameInput.Text = ""
                    end)

                    RefreshConfigList()
                end

                return Elements
            end
            return PageObj
        end

        if isDefault then
            TabBtn.BackgroundTransparency = 0
            Indicator.Size = UDim2.new(0, 3, 0, 18)
            Txt.TextColor3 = TextColor
            TabContent.Visible = true
            Window.CurrentTab = TabConfig
        end
        return TabConfig
    end
    return Window
end

return Library