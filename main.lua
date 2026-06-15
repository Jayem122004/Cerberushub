debugX = true

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/Jayem122004/Cerberushub/main/main.lua'))()

local Window = Rayfield:CreateWindow({
   Name = "Cerberus Hub", -- Title of the Interface
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Cerberus Hub is loading", -- First thing users see, use if you need to do some long loading processes and want to inform the user about it
   LoadingSubtitle = "Unknown Developer", -- Second thing users see, also good for long loading processes
   Theme = "Amethyst", -- Cooler palette for Cerberus Hub

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

local Tab = Window:CreateTab("Tab Example", 4483362458) -- Title, Image

local Section = Tab:CreateSection("Section Example")

local Button = Tab:CreateButton({
   Name = "Button Example",
   Callback = function()
      -- The function that takes place when the button is pressed
   end,
})

local WindowToggle = Tab:CreateButton({
   Name = "Toggle Rayfield Window",
   Callback = function()
      if Rayfield:IsVisible() then
         Rayfield:SetVisibility(false)
      else
         Rayfield:SetVisibility(true)
      end
   end,
})

--Notification Example
Rayfield:Notify({
   Title = "Notification Example",
   Content = "Cerberus Hub Loaded",
   Duration = 6.5,
})

Rayfield:LoadConfiguration()
