-- // Foxy UI Library (Simple Edition)
-- Fitur: Notify WindUI-style, User Panel, Config Manager, 6 Element

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Library = {WhitelistedUsers = {}}

local _isfolder = isfolder or function() return true end
local _makefolder = makefolder or function() end
local _writefile = writefile or function() warn("File saving not supported.") end
local _readfile = readfile or function() return "{}" end
local _listfiles = listfiles or function() return {} end
local _delfile = delfile or function() warn("File deletion not supported.") end

local function Create(c, p)
    local i = Instance.new(c)
    if c == "TextBox" then i.Text = "" end
    for k, v in pairs(p or {}) do i[k] = v end
    if c == "TextLabel" or c == "TextButton" or c == "TextBox" then
        if p.TextSize and p.RichText ~= true then
            i.TextScaled = true
            local con = Instance.new("UITextSizeConstraint")
            con.MaxTextSize = p.TextSize
            con.MinTextSize = 6
            con.Parent = i
        end
    end
    return i
end

local function Tween(inst, props, dur)
    dur = dur or 0.25
    local t = TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function Bounce(btn, sf)
    sf = sf or 0.96
    local s = btn:FindFirstChild("UIScale") or Create("UIScale", {Parent = btn, Scale = 1})
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            Tween(s, {Scale = sf}, 0.15)
        end
    end)
    btn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            Tween(s, {Scale = 1}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function() Tween(s, {Scale = 1}, 0.15) end)
end

local function Draggable(bar, obj)
    bar.Active = true
    obj.Active = true
    local drag, dIn, dStart, sPos
    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dStart = inp.Position
            sPos = obj.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    bar.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            dIn = inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if inp == dIn and drag then
            local d = inp.Position - dStart
            Tween(obj, {Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)}, 0.08)
        end
    end)
end

local AccentColor = Color3.fromRGB(200, 80, 90)
local BackgroundColor = Color3.fromRGB(22, 18, 20)
local CardColor = Color3.fromRGB(32, 26, 30)
local HoverColor = Color3.fromRGB(45, 36, 42)
local TextColor = Color3.fromRGB(245, 235, 240)
local SubTextColor = Color3.fromRGB(160, 145, 155)

local NotifColors = {
    Success = Color3.fromRGB(80, 200, 120),
    Error = Color3.fromRGB(230, 80, 80),
    Warning = Color3.fromRGB(240, 180, 60),
    Info = Color3.fromRGB(100, 160, 240),
    Default = AccentColor,
}

local NotifContainer

function Library:Notify(o)
    if not NotifContainer then return end
    local title = o.Title or "Notification"
    local desc = o.Description or ""
    local dur = o.Duration or 3
    local icon = o.Icon
    local typ = o.Type or "Default"
    local close = o.CanClose ~= false
    local btns = o.Buttons
    local color = NotifColors[typ] or NotifColors.Default
    local hasBtns = btns and #btns > 0
    local h = hasBtns and 108 or 68

    local N = Create("Frame", {Parent = NotifContainer, BackgroundColor3 = Color3.fromRGB(22, 22, 25), Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, ZIndex = 201, ClipsDescendants = true})
    Create("UICorner", {Parent = N, CornerRadius = UDim.new(0, 10)})
    local S = Create("UIStroke", {Parent = N, Color = Color3.fromRGB(45, 45, 50), Thickness = 1, Transparency = 1})

    Create("Frame", {Parent = N, BackgroundColor3 = color, Size = UDim2.new(0, 3, 1, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 202, BorderSizePixel = 0})

    local off = 15
    if icon then
        local iF = Create("Frame", {Parent = N, BackgroundColor3 = color, BackgroundTransparency = 0.88, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 13, 0, 13), ZIndex = 202})
        Create("UICorner", {Parent = iF, CornerRadius = UDim.new(0, 8)})
        local img = Create("ImageLabel", {Parent = iF, BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Image = icon, ImageColor3 = color, ImageTransparency = 1, ZIndex = 203})
        Tween(img, {ImageTransparency = 0}, 0.3)
        off = 55
    end

    local T = Create("TextLabel", {Parent = N, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, off, 0, 14), Size = UDim2.new(1, -off - 40, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 202})
    local D = Create("TextLabel", {Parent = N, Text = desc, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(150, 150, 155), BackgroundTransparency = 1, Position = UDim2.new(0, off, 0, 33), Size = UDim2.new(1, -off - 40, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 202})

    if close then
        local cb = Create("TextButton", {Parent = N, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(120, 120, 125), BackgroundTransparency = 1, Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -28, 0, 12), TextTransparency = 1, AutoButtonColor = false, ZIndex = 203})
        cb.MouseButton1Click:Connect(function()
            Tween(N, {BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0)}, 0.3)
            task.wait(0.3)
            N:Destroy()
        end)
        Tween(cb, {TextTransparency = 0}, 0.3)
    end

    if hasBtns then
        local bc = Create("Frame", {Parent = N, BackgroundTransparency = 1, Size = UDim2.new(1, -26, 0, 26), Position = UDim2.new(0, 13, 0, 70), ZIndex = 202})
        Create("UIListLayout", {Parent = bc, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)})
        for i, bd in ipairs(btns) do
            local isP = (i == 1)
            local b = Create("TextButton", {Parent = bc, Text = bd.Title or "Button", Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = isP and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 220, 220), BackgroundColor3 = isP and color or Color3.fromRGB(38, 38, 42), Size = UDim2.new(0.5, -3, 1, 0), AutoButtonColor = false, TextTransparency = 1, BackgroundTransparency = 1, ZIndex = 203})
            Create("UICorner", {Parent = b, CornerRadius = UDim.new(0, 6)})
            b.MouseButton1Click:Connect(function()
                if bd.Callback then pcall(bd.Callback) end
                Tween(N, {BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0)}, 0.25)
                task.wait(0.25)
                N:Destroy()
            end)
            Tween(b, {TextTransparency = 0, BackgroundTransparency = 0}, 0.3)
        end
    end

    N.Position = UDim2.new(1, 30, 0, 0)
    Tween(N, {Position = UDim2.new(0, 0, 0, 0)}, 0.35)
    Tween(N, {BackgroundTransparency = 0}, 0.3)
    Tween(S, {Transparency = 0.4}, 0.3)
    Tween(T, {TextTransparency = 0}, 0.3)
    Tween(D, {TextTransparency = 0}, 0.3)

    if dur > 0 then
        task.delay(dur, function()
            if N.Parent then
                Tween(N, {BackgroundTransparency = 1, Position = UDim2.new(1, 30, 0, 0)}, 0.35)
                task.wait(0.35)
                N:Destroy()
            end
        end)
    end
end

function Library:CreateWindow(options)
    local hubName = options.Title or "Foxy UI"
    local subText = options.Subtitle or "Made By Hypol-X"
    local subColor = options.SubtitleColor or AccentColor
    local userEnabled = false
    local userAnon = false
    local userSub = "User"

    if options.User then
        userEnabled = options.User.Enabled ~= false
        userAnon = options.User.Anonymous == true
        userSub = options.User.Subtitle or "User"
    end

    local ScreenGui = Create("ScreenGui", {
        Name = "FoxyUI_" .. HttpService:GenerateGUID(false),
        Parent = RunService:IsStudio() and Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    })

    NotifContainer = Create("Frame", {Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(0, 320, 1, -20), Position = UDim2.new(1, -340, 0, 10), ZIndex = 200, Active = false})
    Create("UIListLayout", {Parent = NotifContainer, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})

    local Main = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = BackgroundColor, Size = UDim2.new(0, 650, 0, 420), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true, Active = true})
    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = Main, Color = Color3.fromRGB(50, 40, 45), Thickness = 1})

    local Top = Create("Frame", {Parent = Main, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, 0, 0, 40), Active = true})
    Draggable(Top, Main)

    local iconOffset = 15
    if options.Logo then
        Create("ImageLabel", {Parent = Top, BackgroundTransparency = 1, Size = UDim2.new(0, options.LogoSize or 32, 0, options.LogoSize or 32), Position = UDim2.new(0, 8, 0.5, -(options.LogoSize or 32) / 2), Image = options.Logo, ScaleType = Enum.ScaleType.Fit})
        iconOffset = 8 + (options.LogoSize or 32) + 8
    end

    local TC = Create("Frame", {Parent = Top, BackgroundTransparency = 1, Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, iconOffset, 0, 0)})
    Create("TextLabel", {Parent = TC, Text = hubName, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 5), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left})
    Create("TextLabel", {Parent = TC, Text = subText, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = subColor, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Left})

    local CloseBtn = Create("TextButton", {Parent = Top, Text = "X", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -35, 0, 0)})
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Main, {BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    local Sidebar = Create("Frame", {Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(0, 160, 1, -40), Position = UDim2.new(0, 0, 0, 40)})
    local TabContainer = Create("ScrollingFrame", {Parent = Sidebar, BackgroundTransparency = 1, Size = UDim2.new(1, -15, 1, -10), Position = UDim2.new(0, 10, 0, 5), ScrollBarThickness = 0})
    Create("UIListLayout", {Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    Create("Frame", {Parent = Main, BackgroundColor3 = Color3.fromRGB(50, 40, 45), BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, -40), Position = UDim2.new(0, 160, 0, 40)})
    local Content = Create("Frame", {Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, -165, 1, -40), Position = UDim2.new(0, 165, 0, 40)})

    if userEnabled then
        local UP = Create("Frame", {Parent = Main, BackgroundColor3 = CardColor, Size = UDim2.new(0, 140, 0, 50), Position = UDim2.new(0, 10, 1, -60), ZIndex = 10})
        Create("UICorner", {Parent = UP, CornerRadius = UDim.new(0, 8)})
        Create("UIStroke", {Parent = UP, Color = Color3.fromRGB(50, 42, 46), Thickness = 1})
        local av = ""
        if not userAnon then av = "rbxthumb://type=AvatarHeadShot&id=" .. Players.LocalPlayer.UserId .. "&w=150&h=150" end
        local A = Create("ImageLabel", {Parent = UP, BackgroundColor3 = Color3.fromRGB(30, 30, 35), Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 8, 0.5, -18), Image = av, ZIndex = 11})
        Create("UICorner", {Parent = A, CornerRadius = UDim.new(1, 0)})
        Create("TextLabel", {Parent = UP, Text = userAnon and "Anonymous" or Players.LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 0, 14), Position = UDim2.new(0, 50, 0, 10), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 11})
        Create("TextLabel", {Parent = UP, Text = userSub, Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 0, 12), Position = UDim2.new(0, 50, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 11})
    end

    local W = {CurrentTab = nil, Tabs = {}, ConfigElements = {}, MainFrame = Main}

    function W:SetTransparency(v)
        Tween(Main, {BackgroundTransparency = v}, 0.3)
    end

    function W:SetTheme(n)
        -- Simple theme (cuma dark aja)
        Library:Notify({Title = "Theme", Description = "Theme: " .. n, Type = "Info", Duration = 2})
    end

    function W:OnClose(fn)
        CloseBtn.MouseButton1Click:Connect(function()
            if fn then pcall(fn) end
        end)
    end

    function W:CreateTab(name, isDef, isLocked, icon)
        local Btn = Create("TextButton", {Parent = TabContainer, Text = "", BackgroundColor3 = HoverColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), AutoButtonColor = false})
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
        Bounce(Btn, 0.98)
        local Ind = Create("Frame", {Parent = Btn, BackgroundColor3 = AccentColor, Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)})
        Create("UICorner", {Parent = Ind, CornerRadius = UDim.new(1, 0)})
        local off = 15
        if icon then
            Create("ImageLabel", {Parent = Btn, BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 12, 0.5, -8), Image = icon, ImageColor3 = SubTextColor})
            off = 36
        end
        local T = Create("TextLabel", {Parent = Btn, Text = name, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, off, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
        local C = Create("Frame", {Parent = Content, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false})
        local Scroll = Create("ScrollingFrame", {Parent = C, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5), ScrollBarThickness = 2, ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)})
        local L = Create("UIListLayout", {Parent = Scroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
        L:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Scroll.CanvasSize = UDim2.new(0, 0, 0, L.AbsoluteContentSize.Y + 20) end)

        local Tab = {Button = Btn, Content = C, Txt = T, Indicator = Ind}
        table.insert(W.Tabs, Tab)

        Btn.MouseButton1Click:Connect(function()
            if W.CurrentTab == Tab then return end
            if W.CurrentTab then
                Tween(W.CurrentTab.Button, {BackgroundTransparency = 1}, 0.2)
                Tween(W.CurrentTab.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
                Tween(W.CurrentTab.Txt, {TextColor3 = SubTextColor}, 0.2)
                W.CurrentTab.Content.Visible = false
            end
            W.CurrentTab = Tab
            C.Visible = true
            Tween(Btn, {BackgroundTransparency = 0}, 0.2)
            Tween(Ind, {Size = UDim2.new(0, 3, 0, 18)}, 0.3)
            Tween(T, {TextColor3 = TextColor}, 0.2)
        end)

        function Tab:CreateSection(secName, secIcon)
            local S = Create("Frame", {Parent = Scroll, BackgroundColor3 = CardColor, Size = UDim2.new(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true})
            Create("UICorner", {Parent = S, CornerRadius = UDim.new(0, 6)})
            local tOff = 10
            if secIcon then
                Create("ImageLabel", {Parent = S, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0, 8), Image = secIcon, ImageColor3 = AccentColor})
                tOff = 30
            end
            Create("TextLabel", {Parent = S, Text = secName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20 - tOff, 0, 30), Position = UDim2.new(0, tOff, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
            local IC = Create("Frame", {Parent = S, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y})
            Create("UIPadding", {Parent = IC, PaddingBottom = UDim.new(0, 10), PaddingTop = UDim.new(0, 5)})
            Create("UIListLayout", {Parent = IC, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
            local E = {}

            function E:AddButton(name, callback, infoData, icon)
                local F = Create("Frame", {Parent = IC, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30)})
                local B = Create("TextButton", {Parent = F, Text = "", BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), AutoButtonColor = false})
                Create("UICorner", {Parent = B, CornerRadius = UDim.new(0, 4)})
                Create("UIStroke", {Parent = B, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                local off = 10
                if icon then
                    Create("ImageLabel", {Parent = B, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 8, 0.5, -7), Image = icon, ImageColor3 = AccentColor})
                    off = 28
                end
                Create("TextLabel", {Parent = B, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -off - 10, 1, 0), Position = UDim2.new(0, off, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                Bounce(B)
                B.MouseEnter:Connect(function() Tween(B, {BackgroundColor3 = HoverColor}, 0.2) end)
                B.MouseLeave:Connect(function() Tween(B, {BackgroundColor3 = BackgroundColor}, 0.2) end)
                B.MouseButton1Click:Connect(function() if callback then callback() end end)
            end

            function E:AddToggle(name, default, callback, infoData, icon)
                local state = default or false
                local F = Create("Frame", {Parent = IC, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24)})
                local off = 10
                if icon then
                    Create("ImageLabel", {Parent = F, BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 10, 0.5, -8), Image = icon, ImageColor3 = AccentColor})
                    off = 32
                end
                Create("TextLabel", {Parent = F, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -60 - off, 1, 0), Position = UDim2.new(0, off, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                local L = Create("TextButton", {Parent = F, Text = "", BackgroundColor3 = state and AccentColor or Color3.fromRGB(45, 45, 50), Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -46, 0.5, -9), AutoButtonColor = false})
                Create("UICorner", {Parent = L, CornerRadius = UDim.new(1, 0)})
                Bounce(L)
                local K = Create("Frame", {Parent = L, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(0, 14, 0, 14), Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
                Create("UICorner", {Parent = K, CornerRadius = UDim.new(1, 0)})

                local function set(v)
                    state = v
                    Tween(L, {BackgroundColor3 = state and AccentColor or Color3.fromRGB(45, 45, 50)}, 0.3)
                    Tween(K, {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.3)
                    if callback then callback(state) end
                end
                L.MouseButton1Click:Connect(function() set(not state) end)
                W.ConfigElements[name] = {Set = set, Get = function() return state end}
            end

            function E:AddDropdown(name, opts, isMulti, callback, infoData, icon)
                local sel = isMulti and {} or (opts[1] or nil)
                local dropped = false
                local optBtns = {}
                local maxV = math.min(#opts, 3)
                local lH = maxV * 25
                local F = Create("Frame", {Parent = IC, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), ClipsDescendants = true})
                local off = 10
                if icon then
                    Create("ImageLabel", {Parent = F, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0, 0), Image = icon, ImageColor3 = AccentColor})
                    off = 30
                end
                Create("TextLabel", {Parent = F, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20 - off, 0, 15), Position = UDim2.new(0, off, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                local MB = Create("TextButton", {Parent = F, Text = isMulti and "Select..." or "Select...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 20), AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left})
                Create("UIPadding", {Parent = MB, PaddingLeft = UDim.new(0, 8)})
                Create("UICorner", {Parent = MB, CornerRadius = UDim.new(0, 4)})
                Create("UIStroke", {Parent = MB, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                local Ar = Create("TextLabel", {Parent = MB, Text = "▼", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -28, 0, 0)})
                local LF = Create("ScrollingFrame", {Parent = F, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, lH), Position = UDim2.new(0, 10, 0, 50), CanvasSize = UDim2.new(0, 0, 0, #opts * 25), ScrollBarThickness = 2, BorderSizePixel = 0})
                Create("UICorner", {Parent = LF, CornerRadius = UDim.new(0, 4)})
                Create("UIListLayout", {Parent = LF, SortOrder = Enum.SortOrder.LayoutOrder})

                local function upTxt()
                    if isMulti then
                        local t = ""
                        for _, v in pairs(sel) do t = t .. v .. ", " end
                        MB.Text = t == "" and "Select..." or t:sub(1, -3)
                    else
                        MB.Text = sel or "Select..."
                    end
                end

                local function set(v)
                    sel = v
                    upTxt()
                    for _, b in ipairs(optBtns) do
                        local isS = isMulti and table.find(sel, b.Text) ~= nil or (sel == b.Text)
                        Tween(b, {TextColor3 = isS and TextColor or SubTextColor}, 0.2)
                    end
                    if callback then callback(sel) end
                end

                for _, o in pairs(opts) do
                    local isI = (not isMulti and sel == o)
                    local OB = Create("TextButton", {Parent = LF, Text = o, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = isI and TextColor or SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), AutoButtonColor = false})
                    table.insert(optBtns, OB)
                    OB.MouseButton1Click:Connect(function()
                        if isMulti then
                            if table.find(sel, o) then table.remove(sel, table.find(sel, o)) else table.insert(sel, o) end
                            set(sel)
                        else
                            set(o)
                            dropped = false
                            Tween(Ar, {Rotation = 0}, 0.3)
                            Tween(F, {Size = UDim2.new(1, 0, 0, 50)}, 0.3)
                        end
                    end)
                end
                upTxt()

                MB.MouseButton1Click:Connect(function()
                    dropped = not dropped
                    if dropped then
                        Tween(Ar, {Rotation = 180}, 0.3)
                        Tween(F, {Size = UDim2.new(1, 0, 0, 50 + lH)}, 0.3)
                    else
                        Tween(Ar, {Rotation = 0}, 0.3)
                        Tween(F, {Size = UDim2.new(1, 0, 0, 50)}, 0.3)
                    end
                end)
                W.ConfigElements[name] = {Set = set, Get = function() return sel end}
            end

            function E:AddSlider(name, min, max, default, callback, infoData, icon)
                local val = default or min
                local F = Create("Frame", {Parent = IC, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 45)})
                local off = 10
                if icon then
                    Create("ImageLabel", {Parent = F, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0, 0), Image = icon, ImageColor3 = AccentColor})
                    off = 30
                end
                Create("TextLabel", {Parent = F, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20 - off, 0, 15), Position = UDim2.new(0, off, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                local VT = Create("TextLabel", {Parent = F, Text = tostring(val), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(0, 30, 0, 15), Position = UDim2.new(1, -40, 0, 0), TextXAlignment = Enum.TextXAlignment.Right})
                local TB = Create("Frame", {Parent = F, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 25)})
                Create("UICorner", {Parent = TB, CornerRadius = UDim.new(1, 0)})
                local F2 = Create("Frame", {Parent = TB, BackgroundColor3 = AccentColor, Size = UDim2.new((val - min) / (max - min), 0, 1, 0)})
                Create("UICorner", {Parent = F2, CornerRadius = UDim.new(1, 0)})
                local K = Create("Frame", {Parent = F2, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6)})
                Create("UICorner", {Parent = K, CornerRadius = UDim.new(1, 0)})

                local function set(v)
                    val = math.clamp(v, min, max)
                    VT.Text = tostring(val)
                    Tween(F2, {Size = UDim2.new((val - min) / (max - min), 0, 1, 0)}, 0.1)
                    if callback then callback(val) end
                end

                local drag = false
                K.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = true end end)
                UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = false end end)
                UserInputService.InputChanged:Connect(function(inp)
                    if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                        local pos = math.clamp((inp.Position.X - TB.AbsolutePosition.X) / TB.AbsoluteSize.X, 0, 1)
                        set(math.floor(min + ((max - min) * pos)))
                    end
                end)
                W.ConfigElements[name] = {Set = set, Get = function() return val end}
            end

            function E:AddTextbox(name, placeholder, callback, infoData, icon)
                local F = Create("Frame", {Parent = IC, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50)})
                local off = 10
                if icon then
                    Create("ImageLabel", {Parent = F, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0, 0), Image = icon, ImageColor3 = AccentColor})
                    off = 30
                end
                Create("TextLabel", {Parent = F, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20 - off, 0, 15), Position = UDim2.new(0, off, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                local I = Create("TextBox", {Parent = F, PlaceholderText = placeholder or "Type...", Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                Create("UIPadding", {Parent = I, PaddingLeft = UDim.new(0, 8)})
                Create("UICorner", {Parent = I, CornerRadius = UDim.new(0, 4)})
                local function set(v) I.Text = tostring(v) if callback then callback(v) end end
                I.FocusLost:Connect(function() set(I.Text) end)
                W.ConfigElements[name] = {Set = set, Get = function() return I.Text end}
            end

            function E:AddColorPicker(name, default, callback, infoData, icon)
                local color = default or Color3.fromRGB(255, 255, 255)
                local h, s, v = color:ToHSV()
                local dropped = false
                local F = Create("Frame", {Parent = IC, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ClipsDescendants = true})
                local off = 10
                if icon then
                    Create("ImageLabel", {Parent = F, BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 10, 0.5, -7), Image = icon, ImageColor3 = AccentColor})
                    off = 30
                end
                Create("TextLabel", {Parent = F, Text = name, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -60 - off, 0, 30), Position = UDim2.new(0, off, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                local DB = Create("TextButton", {Parent = F, Text = "", BackgroundColor3 = color, Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -40, 0.5, -8), AutoButtonColor = false})
                Create("UICorner", {Parent = DB, CornerRadius = UDim.new(0, 4)})
                Create("UIStroke", {Parent = DB, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8, Thickness = 1})
                Bounce(DB)

                local PA = Create("Frame", {Parent = F, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 140), Position = UDim2.new(0, 10, 0, 35)})
                Create("UICorner", {Parent = PA, CornerRadius = UDim.new(0, 4)})
                local SV = Create("TextButton", {Parent = PA, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), Size = UDim2.new(1, -20, 0, 90), Position = UDim2.new(0, 10, 0, 10), AutoButtonColor = false, Active = true})
                Create("UICorner", {Parent = SV, CornerRadius = UDim.new(0, 4)})
                local W1 = Create("Frame", {Parent = SV, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Create("UIGradient", {Parent = W1, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Rotation = 0})
                local B1 = Create("Frame", {Parent = SV, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0)})
                Create("UIGradient", {Parent = B1, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}), Rotation = 90})
                local SR = Create("Frame", {Parent = B1, Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1 - v, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Create("UICorner", {Parent = SR, CornerRadius = UDim.new(1, 0)})
                local HS = Create("TextButton", {Parent = PA, Text = "", Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 110), AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(255, 255, 255), Active = true})
                Create("UICorner", {Parent = HS, CornerRadius = UDim.new(0, 4)})
                Create("UIGradient", {Parent = HS, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))})})
                local HR = Create("Frame", {Parent = HS, Size = UDim2.new(0, 6, 0, 15), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                Create("UICorner", {Parent = HR, CornerRadius = UDim.new(0, 2)})

                local function upd()
                    color = Color3.fromHSV(h, s, v)
                    DB.BackgroundColor3 = color
                    SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    if callback then callback(color) end
                end

                local d1, d2 = false, false
                SV.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then d1 = true end end)
                HS.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then d2 = true end end)
                UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then d1 = false d2 = false end end)
                UserInputService.InputChanged:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        if d1 then
                            s = math.clamp((inp.Position.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
                            v = 1 - math.clamp((inp.Position.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
                            SR.Position = UDim2.new(s, 0, 1 - v, 0)
                            upd()
                        elseif d2 then
                            h = math.clamp((inp.Position.X - HS.AbsolutePosition.X) / HS.AbsoluteSize.X, 0, 1)
                            HR.Position = UDim2.new(h, 0, 0.5, 0)
                            upd()
                        end
                    end
                end)
                DB.MouseButton1Click:Connect(function() dropped = not dropped Tween(F, {Size = UDim2.new(1, 0, 0, dropped and 185 or 30)}, 0.3) end)
                W.ConfigElements[name] = {Set = function(hex) local ok, c = pcall(function() return Color3.fromHex(hex) end) if ok then color = c h, s, v = color:ToHSV() DB.BackgroundColor3 = color SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1) end end, Get = function() return color:ToHex() end}
            end

            function E:AddConfigManager(folderName)
                folderName = folderName or "FoxyConfig"
                if not _isfolder(folderName) then _makefolder(folderName) end
                local MF = Create("Frame", {Parent = IC, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 280)})
                Create("TextLabel", {Parent = MF, Text = "Config Manager", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                local SB = Create("TextBox", {Parent = MF, PlaceholderText = "Search...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                Create("UIPadding", {Parent = SB, PaddingLeft = UDim.new(0, 8)})
                Create("UICorner", {Parent = SB, CornerRadius = UDim.new(0, 4)})
                local CL = Create("ScrollingFrame", {Parent = MF, BackgroundColor3 = Color3.fromRGB(15, 15, 18), Size = UDim2.new(1, -20, 0, 120), Position = UDim2.new(0, 10, 0, 62), ScrollBarThickness = 2, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0)})
                Create("UICorner", {Parent = CL, CornerRadius = UDim.new(0, 4)})
                Create("UIStroke", {Parent = CL, Color = Color3.fromRGB(45, 45, 50), Thickness = 1})
                local LL = Create("UIListLayout", {Parent = CL, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
                Create("UIPadding", {Parent = CL, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
                LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() CL.CanvasSize = UDim2.new(0, 0, 0, LL.AbsoluteContentSize.Y + 10) end)
                local NI = Create("TextBox", {Parent = MF, PlaceholderText = "Config name...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 190), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false})
                Create("UIPadding", {Parent = NI, PaddingLeft = UDim.new(0, 8)})
                Create("UICorner", {Parent = NI, CornerRadius = UDim.new(0, 4)})
                local BR = Create("Frame", {Parent = MF, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 224)})
                Create("UIListLayout", {Parent = BR, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5)})

                local function AB(txt, col, cb)
                    local b = Create("TextButton", {Parent = BR, Text = txt, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = col, Size = UDim2.new(0.33, -4, 1, 0), AutoButtonColor = false})
                    Create("UICorner", {Parent = b, CornerRadius = UDim.new(0, 4)})
                    Bounce(b)
                    b.MouseButton1Click:Connect(cb)
                end

                local function RL()
                    for _, v in ipairs(CL:GetChildren()) do if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end end
                    local files = _listfiles(folderName)
                    if #files == 0 then
                        Create("TextLabel", {Parent = CL, Text = "No configs", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = SubTextColor, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Center})
                        return
                    end
                    for _, fp in ipairs(files) do
                        local rn = fp:match("([^/\\]+)%.json$")
                        if rn then
                            local R = Create("Frame", {Parent = CL, BackgroundColor3 = BackgroundColor, Size = UDim2.new(1, 0, 0, 30)})
                            Create("UICorner", {Parent = R, CornerRadius = UDim.new(0, 4)})
                            Create("TextLabel", {Parent = R, Text = rn, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = TextColor, BackgroundTransparency = 1, Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left})
                            local LB = Create("TextButton", {Parent = R, Text = "Load", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(45, 120, 60), Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -48, 0.5, -10), AutoButtonColor = false})
                            Create("UICorner", {Parent = LB, CornerRadius = UDim.new(0, 4)})
                            local DB = Create("TextButton", {Parent = R, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(180, 50, 50), Size = UDim2.new(0, 24, 0, 20), Position = UDim2.new(1, -24, 0.5, -10), AutoButtonColor = false})
                            Create("UICorner", {Parent = DB, CornerRadius = UDim.new(0, 4)})
                            LB.MouseButton1Click:Connect(function()
                                local s, data = pcall(function() return HttpService:JSONDecode(_readfile(fp)) end)
                                if s and type(data) == "table" then
                                    for k, v in pairs(data) do if W.ConfigElements[k] and W.ConfigElements[k].Set then W.ConfigElements[k].Set(v) end end
                                    Library:Notify({Title = "Config Loaded", Description = rn, Type = "Success", Duration = 3})
                                end
                            end)
                            DB.MouseButton1Click:Connect(function()
                                pcall(function() _delfile(fp) end)
                                RL()
                                Library:Notify({Title = "Deleted", Description = rn, Type = "Info", Duration = 2})
                            end)
                        end
                    end
                end

                AB("Save", Color3.fromRGB(45, 120, 60), function()
                    if NI.Text == "" then Library:Notify({Title = "Error", Description = "Nama config kosong!", Type = "Error"}) return end
                    local pl = {}
                    for k, el in pairs(W.ConfigElements) do if el.Get then pl[k] = el.Get() end end
                    _writefile(folderName .. "/" .. NI.Text .. ".json", HttpService:JSONEncode(pl))
                    RL()
                    Library:Notify({Title = "Saved", Description = NI.Text, Type = "Success", Duration = 3})
                end)
                AB("Refresh", Color3.fromRGB(50, 100, 180), function() RL() end)
                AB("Clear", Color3.fromRGB(60, 60, 65), function() NI.Text = "" end)
                RL()
            end

            return E
        end

        if isDef then
            Btn.BackgroundTransparency = 0
            Ind.Size = UDim2.new(0, 3, 0, 18)
            T.TextColor3 = TextColor
            C.Visible = true
            W.CurrentTab = Tab
        end
        return Tab
    end
    return W
end

return Library