--[[
    CircleButtonWindow
    A draggable circular button that toggles UI visibility with customizable images

    Usage:
    local CircleButton = loadstring(game:HttpGet('YOUR_URL'))()

    local button = CircleButton.new({
        Window = yourRayfieldWindow,  -- The Rayfield window to toggle
        Image = "rbxassetid://123456",  -- or Lucide icon name like "circle"
        Position = UDim2.new(0, 50, 0, 50),  -- Initial position
        Size = UDim2.new(0, 60, 0, 60),  -- Button size (default 60x60)
        DragEnabled = true,  -- Can the user drag the button?
        ToggleKey = Enum.KeyCode.RightShift,  -- Optional keybind to toggle
        AnimationStyle = "Spring",  -- "Spring", "Linear", "Exponential"
        Tooltip = "Click to toggle menu",  -- Optional hover text
        ZIndex = 999,  -- Render order
    })

    -- Methods:
    button:SetImage("rbxassetid://789012")  -- Change image
    button:SetImage("eye")  -- Use Lucide icon
    button:SetPosition(UDim2.new(0, 100, 0, 100))
    button:SetSize(UDim2.new(0, 80, 0, 80))
    button:SetVisible(true/false)
    button:SetTransparency(0.5)  -- 0-1
    button:Destroy()  -- Clean up
--]]

local CircleButtonWindow = {}
CircleButtonWindow.__index = CircleButtonWindow

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Lucide Icons loader (compatible with Rayfield's icon system)
local Icons = nil
local function loadIcons()
    if Icons then return Icons end
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Jayem122004/Cerberushub/main/main.lua"))()
    end)
    if success then
        Icons = result
    end
    return Icons
end

-- Resolve icon from various formats
local function resolveIcon(icon)
    if not icon or icon == "" then
        return nil
    end

    -- Direct rbxasset
    if type(icon) == "string" and (icon:find("rbxasset") or icon:find("http")) then
        return icon, nil, nil
    end

    -- Lucide icon name
    if type(icon) == "string" and not icon:find("%d") then
        local loaded = loadIcons()
        if loaded and loaded['48px'] then
            local sized = loaded['48px']
            local r = sized[icon:lower()]
            if r then
                local irs = Vector2.new(r[2][1], r[2][2])
                local iro = Vector2.new(r[3][1], r[3][2])
                return "rbxassetid://" .. r[1], iro, irs
            end
        end
    end

    -- Numeric asset ID
    if type(icon) == "number" then
        return "rbxassetid://" .. icon, nil, nil
    end

    -- String number
    if type(icon) == "string" and icon:match("^%d+$") then
        return "rbxassetid://" .. icon, nil, nil
    end

    return nil
end

-- Default configuration
local DEFAULT_CONFIG = {
    Window = nil,                    -- Target window to toggle (required)
    Image = "circle",                -- Default Lucide icon
    Position = UDim2.new(0, 20, 0, 20),  -- Top-left corner
    Size = UDim2.new(0, 60, 0, 60),  -- 60x60 circle
    DragEnabled = true,
    ToggleKey = nil,                 -- Optional keybind
    AnimationStyle = "Spring",
    Tooltip = nil,
    ZIndex = 999,
    BackgroundColor = Color3.fromRGB(40, 40, 40),
    ImageColor = Color3.fromRGB(255, 255, 255),
    HoverColor = Color3.fromRGB(60, 60, 60),
    PressedColor = Color3.fromRGB(80, 80, 80),
    StrokeColor = Color3.fromRGB(100, 100, 100),
    StrokeThickness = 2,
    ShadowEnabled = true,
    ShadowColor = Color3.fromRGB(0, 0, 0),
    ShadowTransparency = 0.6,
    CornerRadius = 1,                -- 1 = full circle
    AnimationSpeed = 0.3,
    HoverScale = 1.1,                -- Scale on hover
    PressScale = 0.95,               -- Scale on press
    StartVisible = true,               -- Button starts visible?
    WindowStartsVisible = true,      -- Window starts visible?
}

-- Animation presets
local ANIMATIONS = {
    Spring = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    Exponential = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
    Linear = TweenInfo.new(0.2, Enum.EasingStyle.Linear),
    Smooth = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

function CircleButtonWindow.new(config)
    config = config or {}
    local self = setmetatable({}, CircleButtonWindow)

    -- Merge config with defaults
    for key, value in pairs(DEFAULT_CONFIG) do
        self[key] = config[key] ~= nil and config[key] or value
    end

    -- Validate required
    if not self.Window then
        error("CircleButtonWindow: 'Window' parameter is required (pass your Rayfield window)")
    end

    -- State
    self._dragging = false
    self._dragOffset = Vector2.new(0, 0)
    self._hovering = false
    self._pressed = false
    self._windowVisible = self.WindowStartsVisible
    self._buttonVisible = self.StartVisible
    self._connections = {}
    self._destroyed = false

    -- Build UI
    self:_createUI()
    self:_setupInteractions()
    self:_setupKeybind()

    -- Initial state
    if not self.WindowStartsVisible then
        self:_hideWindow(false)
    end

    return self
end

function CircleButtonWindow:_createUI()
    -- ScreenGui
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "CircleButton_" .. tostring(math.random(100000, 999999))
    self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._screenGui.ResetOnSpawn = false
    self._screenGui.DisplayOrder = self.ZIndex

    -- Parent to appropriate location
    if gethui then
        self._screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(self._screenGui)
        self._screenGui.Parent = CoreGui
    else
        self._screenGui.Parent = CoreGui
    end

    -- Main button frame (circular)
    self._button = Instance.new("Frame")
    self._button.Name = "CircleButton"
    self._button.Size = self.Size
    self._button.Position = self.Position
    self._button.BackgroundColor3 = self.BackgroundColor
    self._button.BorderSizePixel = 0
    self._button.BackgroundTransparency = 0
    self._button.Active = true
    self._button.Parent = self._screenGui

    -- Corner radius (circle)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(self.CornerRadius, 0)
    corner.Parent = self._button

    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = self.StrokeColor
    stroke.Thickness = self.StrokeThickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = self._button
    self._stroke = stroke

    -- Shadow
    if self.ShadowEnabled then
        self._shadow = Instance.new("ImageLabel")
        self._shadow.Name = "Shadow"
        self._shadow.Size = UDim2.new(1, 20, 1, 20)
        self._shadow.Position = UDim2.new(0, -10, 0, -10)
        self._shadow.BackgroundTransparency = 1
        self._shadow.Image = "rbxassetid://5587865193"  -- Shadow asset
        self._shadow.ImageColor3 = self.ShadowColor
        self._shadow.ImageTransparency = self.ShadowTransparency
        self._shadow.ZIndex = -1
        self._shadow.Parent = self._button
    end

    -- Image label
    self._imageLabel = Instance.new("ImageLabel")
    self._imageLabel.Name = "Icon"
    self._imageLabel.Size = UDim2.new(0.6, 0, 0.6, 0)
    self._imageLabel.Position = UDim2.new(0.2, 0, 0.2, 0)
    self._imageLabel.BackgroundTransparency = 1
    self._imageLabel.ImageColor3 = self.ImageColor
    self._imageLabel.Parent = self._button

    -- Set initial image
    self:_updateImage()

    -- Tooltip
    if self.Tooltip then
        self:_createTooltip()
    end

    -- Visibility
    self._screenGui.Enabled = self._buttonVisible
end

function CircleButtonWindow:_createTooltip()
    self._tooltipFrame = Instance.new("Frame")
    self._tooltipFrame.Name = "Tooltip"
    self._tooltipFrame.Size = UDim2.new(0, 0, 0, 28)
    self._tooltipFrame.Position = UDim2.new(0.5, 0, 1, 8)
    self._tooltipFrame.AnchorPoint = Vector2.new(0.5, 0)
    self._tooltipFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    self._tooltipFrame.BorderSizePixel = 0
    self._tooltipFrame.BackgroundTransparency = 1
    self._tooltipFrame.Visible = false
    self._tooltipFrame.Parent = self._button

    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 6)
    tooltipCorner.Parent = self._tooltipFrame

    local tooltipStroke = Instance.new("UIStroke")
    tooltipStroke.Color = Color3.fromRGB(80, 80, 80)
    tooltipStroke.Thickness = 1
    tooltipStroke.Parent = self._tooltipFrame

    local tooltipText = Instance.new("TextLabel")
    tooltipText.Name = "Text"
    tooltipText.Size = UDim2.new(1, -16, 1, 0)
    tooltipText.Position = UDim2.new(0, 8, 0, 0)
    tooltipText.BackgroundTransparency = 1
    tooltipText.Text = self.Tooltip
    tooltipText.TextColor3 = Color3.fromRGB(240, 240, 240)
    tooltipText.TextSize = 12
    tooltipText.Font = Enum.Font.GothamMedium
    tooltipText.TextXAlignment = Enum.TextXAlignment.Center
    tooltipText.TextYAlignment = Enum.TextYAlignment.Center
    tooltipText.Parent = self._tooltipFrame

    self._tooltipText = tooltipText
end

function CircleButtonWindow:_updateImage()
    local img, rectOffset, rectSize = resolveIcon(self.Image)
    if img then
        self._imageLabel.Image = img
        if rectOffset then
            self._imageLabel.ImageRectOffset = rectOffset
        end
        if rectSize then
            self._imageLabel.ImageRectSize = rectSize
        end
    else
        -- Fallback: simple circle using UI corner
        self._imageLabel.Image = ""
        self._imageLabel.BackgroundColor3 = self.ImageColor
        self._imageLabel.BackgroundTransparency = 0.3
        local imgCorner = Instance.new("UICorner")
        imgCorner.CornerRadius = UDim.new(1, 0)
        imgCorner.Parent = self._imageLabel
    end
end

function CircleButtonWindow:_setupInteractions()
    -- Hover effects
    table.insert(self._connections, self._button.MouseEnter:Connect(function()
        if self._destroyed then return end
        self._hovering = true
        self:_animateHover()
        if self._tooltipFrame then
            self:_showTooltip()
        end
    end))

    table.insert(self._connections, self._button.MouseLeave:Connect(function()
        if self._destroyed then return end
        self._hovering = false
        self._pressed = false
        self:_animateUnhover()
        if self._tooltipFrame then
            self:_hideTooltip()
        end
    end))

    -- Click handling
    table.insert(self._connections, self._button.InputBegan:Connect(function(input, processed)
        if self._destroyed or processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self._pressed = true
            self._dragStartPos = input.Position
            self._dragStartButtonPos = self._button.Position
            self:_animatePress()
        end
    end))

    table.insert(self._connections, self._button.InputEnded:Connect(function(input, processed)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self._pressed = false
            self:_animateRelease()

            -- Check if it was a click (minimal movement) or drag
            if self._dragStartPos and (input.Position - self._dragStartPos).Magnitude < 10 then
                self:_toggleWindow()
            end

            self._dragging = false
            self._dragStartPos = nil
        end
    end))

    -- Dragging
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input, processed)
        if self._destroyed then return end
        if not self.DragEnabled then return end
        if self._pressed and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - self._dragStartPos
            if delta.Magnitude > 5 then
                self._dragging = true
            end
            if self._dragging then
                local newPos = UDim2.new(
                    self._dragStartButtonPos.X.Scale,
                    self._dragStartButtonPos.X.Offset + delta.X,
                    self._dragStartButtonPos.Y.Scale,
                    self._dragStartButtonPos.Y.Offset + delta.Y
                )
                self._button.Position = newPos
            end
        end
    end))

    -- Touch dragging
    table.insert(self._connections, UserInputService.TouchMoved:Connect(function(input, processed)
        if self._destroyed then return end
        if not self.DragEnabled then return end
        if self._pressed then
            local delta = input.Position - self._dragStartPos
            if delta.Magnitude > 5 then
                self._dragging = true
            end
            if self._dragging then
                local newPos = UDim2.new(
                    self._dragStartButtonPos.X.Scale,
                    self._dragStartButtonPos.X.Offset + delta.X,
                    self._dragStartButtonPos.Y.Scale,
                    self._dragStartButtonPos.Y.Offset + delta.Y
                )
                self._button.Position = newPos
            end
        end
    end))
end

function CircleButtonWindow:_animateHover()
    local tweenInfo = ANIMATIONS[self.AnimationStyle] or ANIMATIONS.Spring
    TweenService:Create(self._button, tweenInfo, {
        Size = UDim2.new(self.Size.X.Scale, self.Size.X.Offset * self.HoverScale, 
                          self.Size.Y.Scale, self.Size.Y.Offset * self.HoverScale),
        BackgroundColor3 = self.HoverColor
    }):Play()

    TweenService:Create(self._stroke, tweenInfo, {
        Thickness = self.StrokeThickness + 1
    }):Play()
end

function CircleButtonWindow:_animateUnhover()
    local tweenInfo = ANIMATIONS[self.AnimationStyle] or ANIMATIONS.Spring
    TweenService:Create(self._button, tweenInfo, {
        Size = self.Size,
        BackgroundColor3 = self.BackgroundColor
    }):Play()

    TweenService:Create(self._stroke, tweenInfo, {
        Thickness = self.StrokeThickness
    }):Play()
end

function CircleButtonWindow:_animatePress()
    local tweenInfo = ANIMATIONS[self.AnimationStyle] or ANIMATIONS.Spring
    TweenService:Create(self._button, tweenInfo, {
        Size = UDim2.new(self.Size.X.Scale, self.Size.X.Offset * self.PressScale, 
                          self.Size.Y.Scale, self.Size.Y.Offset * self.PressScale),
        BackgroundColor3 = self.PressedColor
    }):Play()
end

function CircleButtonWindow:_animateRelease()
    local targetSize = self._hovering and 
        UDim2.new(self.Size.X.Scale, self.Size.X.Offset * self.HoverScale, 
                  self.Size.Y.Scale, self.Size.Y.Offset * self.HoverScale) or self.Size
    local targetColor = self._hovering and self.HoverColor or self.BackgroundColor

    local tweenInfo = ANIMATIONS[self.AnimationStyle] or ANIMATIONS.Spring
    TweenService:Create(self._button, tweenInfo, {
        Size = targetSize,
        BackgroundColor3 = targetColor
    }):Play()
end

function CircleButtonWindow:_showTooltip()
    if not self._tooltipFrame then return end

    -- Measure text
    local textBounds = self._tooltipText.TextBounds
    self._tooltipFrame.Size = UDim2.new(0, textBounds.X + 20, 0, 28)

    self._tooltipFrame.Visible = true
    TweenService:Create(self._tooltipFrame, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.1
    }):Play()
    TweenService:Create(self._tooltipText, TweenInfo.new(0.2), {
        TextTransparency = 0
    }):Play()
end

function CircleButtonWindow:_hideTooltip()
    if not self._tooltipFrame then return end

    TweenService:Create(self._tooltipFrame, TweenInfo.new(0.15), {
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(self._tooltipText, TweenInfo.new(0.15), {
        TextTransparency = 1
    }):Play()

    task.delay(0.15, function()
        if not self._hovering then
            self._tooltipFrame.Visible = false
        end
    end)
end

function CircleButtonWindow:_toggleWindow()
    self._windowVisible = not self._windowVisible

    if self._windowVisible then
        self:_showWindow()
    else
        self:_hideWindow()
    end

    -- Update icon to reflect state (optional - shows open/closed eye or similar)
    self:_updateStateIcon()
end

function CircleButtonWindow:_showWindow(animate)
    animate = animate ~= false
    if self.Window and self.Window.Show then
        self.Window:Show()
    elseif self.Window and self.Window.Visible ~= nil then
        self.Window.Visible = true
    end

    -- Pulse animation on button
    if animate then
        local pulse = TweenService:Create(self._button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Size = UDim2.new(self.Size.X.Scale, self.Size.X.Offset * 1.2,
                            self.Size.Y.Scale, self.Size.Y.Offset * 1.2)
        })
        pulse:Play()
        pulse.Completed:Connect(function()
            TweenService:Create(self._button, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                Size = self._hovering and 
                    UDim2.new(self.Size.X.Scale, self.Size.X.Offset * self.HoverScale,
                              self.Size.Y.Scale, self.Size.Y.Offset * self.HoverScale) or self.Size
            }):Play()
        end)
    end
end

function CircleButtonWindow:_hideWindow(animate)
    animate = animate ~= false
    if self.Window and self.Window.Hide then
        self.Window:Hide()
    elseif self.Window and self.Window.Visible ~= nil then
        self.Window.Visible = false
    end
end

function CircleButtonWindow:_updateStateIcon()
    -- Optional: Change icon based on window state
    -- Could switch between "eye" and "eye-off" Lucide icons
    -- For now, we keep the same icon but could add this feature
end

function CircleButtonWindow:_setupKeybind()
    if not self.ToggleKey then return end

    local keyName = type(self.ToggleKey) == "string" and self.ToggleKey or self.ToggleKey.Name

    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if self._destroyed or processed then return end
        if input.KeyCode.Name == keyName then
            self:_toggleWindow()
        end
    end))
end

-- Public API Methods

function CircleButtonWindow:SetImage(newImage)
    self.Image = newImage
    self:_updateImage()
end

function CircleButtonWindow:SetPosition(position)
    self.Position = position
    TweenService:Create(self._button, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
        Position = position
    }):Play()
end

function CircleButtonWindow:SetSize(size)
    self.Size = size
    TweenService:Create(self._button, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
        Size = size
    }):Play()
end

function CircleButtonWindow:SetVisible(visible)
    self._buttonVisible = visible
    self._screenGui.Enabled = visible
end

function CircleButtonWindow:SetTransparency(transparency)
    TweenService:Create(self._button, TweenInfo.new(0.2), {
        BackgroundTransparency = transparency
    }):Play()
end

function CircleButtonWindow:SetWindowVisible(visible)
    self._windowVisible = visible
    if visible then
        self:_showWindow()
    else
        self:_hideWindow()
    end
end

function CircleButtonWindow:IsWindowVisible()
    return self._windowVisible
end

function CircleButtonWindow:GetButton()
    return self._button
end

function CircleButtonWindow:GetScreenGui()
    return self._screenGui
end

function CircleButtonWindow:Destroy()
    self._destroyed = true

    -- Disconnect all connections
    for _, connection in ipairs(self._connections) do
        if connection then
            pcall(function() connection:Disconnect() end)
        end
    end
    self._connections = {}

    -- Destroy UI
    if self._screenGui then
        self._screenGui:Destroy()
    end

    -- Clear references
    self._button = nil
    self._imageLabel = nil
    self._stroke = nil
    self._shadow = nil
    self._tooltipFrame = nil
    self._tooltipText = nil
    self._screenGui = nil
    self.Window = nil
end

-- Static utility: Create multiple buttons easily
function CircleButtonWindow.CreateMultiple(configs)
    local buttons = {}
    for _, config in ipairs(configs) do
        table.insert(buttons, CircleButtonWindow.new(config))
    end
    return buttons
end

return CircleButtonWindow
