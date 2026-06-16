debugX = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Cerberus Hub", -- Title of the Interface
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by Sirius",
   Theme = "Amethyst", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

-- Create Custom Toggle Button UI (Outside Window) - AFTER Window is created
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Create Screen Gui for Toggle Button
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "CerberusToggleGui"
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = PlayerGui

-- Create Circular Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "CircleToggleButton"
ToggleButton.Size = UDim2.new(0, 70, 0, 70)
ToggleButton.Position = UDim2.new(0, 20, 0, 20)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 30, 70)
ToggleButton.TextColor3 = Color3.fromRGB(200, 150, 255)
ToggleButton.TextSize = 28
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "📦"
ToggleButton.BorderSizePixel = 2
ToggleButton.BorderColor3 = Color3.fromRGB(150, 100, 200)
ToggleButton.Parent = ToggleGui

-- Add Circle Shape
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)  -- Makes it perfectly circular
corner.Parent = ToggleButton

-- Make Button Draggable (Only drag if mouse moves)
local dragging = false
local dragStart
local startPos
local isDragging = false

ToggleButton.InputBegan:Connect(function(input, gameProcessed)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging = true
      dragStart = input.Position
      startPos = ToggleButton.Position
      isDragging = false
   end
end)

ToggleButton.InputEnded:Connect(function(input, gameProcessed)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging = false
   end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
   if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
      local delta = input.Position - dragStart
      if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
         isDragging = true
         ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
      end
   end
end)

-- Toggle Window Function
local windowVisible = true
ToggleButton.MouseButton1Click:Connect(function()
   if not isDragging then
      windowVisible = not windowVisible
      
      -- Access the main UI element to toggle visibility
      if Window and Window.UI and Window.UI.Main then
         Window.UI.Main.Visible = windowVisible
      end
      
      -- Change button appearance on toggle
      if windowVisible then
         ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 30, 70)
         ToggleButton.Text = "📦"
      else
         ToggleButton.BackgroundColor3 = Color3.fromRGB(70, 50, 90)
         ToggleButton.Text = "✓"
      end
   end
end)

local Tab = Window:CreateTab("Tab Example", 4483362458) -- Title, Image

local Section = Tab:CreateSection("Section Example")

local Button = Tab:CreateButton({
   Name = "Button Example",
   Callback = function()
   -- The function that takes place when the button is pressed
   end,
})

--Notification Example
Rayfield:Notify({
   Title = "Notification Example",
   Content = "Cerberus Hub Loaded",
   Duration = 6.5,
})

Rayfield:LoadConfiguration()
