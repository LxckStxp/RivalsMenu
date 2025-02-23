-- RivalsScript.lua
-- Main script for Rivals cheat system with enhanced Censura UI menu

local function loadModule(url)
    print("Attempting to load module from: " .. url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("Failed to load module from " .. url .. ": " .. result)
        return nil
    end
    print("Successfully loaded module from: " .. url)
    return result
end

print("Starting RivalsScript execution...")

-- Load modules from GitHub
local CensuraDev = loadModule("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua")
local Aimbot = loadModule("https://raw.githubusercontent.com/YourUsername/RivalsScript/main/Aimbot.lua")
local ESP = loadModule("https://raw.githubusercontent.com/YourUsername/RivalsScript/main/ESP.lua")
local Utils = loadModule("https://raw.githubusercontent.com/YourUsername/RivalsScript/main/Utils.lua")

-- Verify all modules loaded
if not (CensuraDev and Aimbot and ESP and Utils) then
    warn("One or more modules failed to load. Script execution halted.")
    return
end
print("All modules loaded successfully.")

-- Initialize the UI
print("Creating Censura UI...")
local gui = CensuraDev.new("Rivals Cheats")
print("Showing GUI...")
gui:Show()

-- Create instances of Aimbot and ESP
print("Initializing Aimbot instance...")
local aimbotInstance = Aimbot.new()
print("Initializing ESP instance...")
local espInstance = ESP.new()

-- Build the menu using CensuraDev
print("Creating UI elements...")

-- Aimbot Section
gui:CreateButton("Aimbot Options", function() end) -- Separator (non-functional label)

local aimbotToggle = gui:CreateToggle("Aimbot", false, function(state)
    print("Aimbot toggled: " .. tostring(state))
    if state then
        aimbotInstance:Enable()
    else
        aimbotInstance:Disable()
    end
end)

local aimbotFOVSlider = gui:CreateSlider("Aimbot FOV", 50, 300, 150, function(value)
    print("Aimbot FOV set to: " .. value)
    aimbotInstance:SetFOV(value)
end)

local aimbotSmoothToggle = gui:CreateToggle("Aimbot Smoothing", true, function(state)
    print("Aimbot smoothing toggled: " .. tostring(state))
    aimbotInstance:SetSmoothing(state)
end)

local aimbotSmoothnessSlider = gui:CreateSlider("Smoothness Factor", 0.05, 0.5, 0.1, function(value)
    print("Aimbot smoothness set to: " .. value)
    aimbotInstance:SetSmoothness(value)
end)

-- ESP Section
gui:CreateButton("ESP Options", function() end) -- Separator (non-functional label)

local espToggle = gui:CreateToggle("ESP", false, function(state)
    print("ESP toggled: " .. tostring(state))
    if state then
        espInstance:Enable()
    else
        espInstance:Disable()
    end
end)

local espTeamCheck = gui:CreateToggle("Team Check", true, function(state)
    print("ESP Team Check set to: " .. tostring(state))
    espInstance:SetTeamCheck(state)
end)

local espThroughWallsToggle = gui:CreateToggle("Through Walls", true, function(state)
    print("ESP Through Walls set to: " .. tostring(state))
    espInstance:SetThroughWalls(state)
end)

local espColorSliderR = gui:CreateSlider("ESP Color (R)", 0, 255, 255, function(value)
    print("ESP Color R set to: " .. value)
    local g = espColorSliderG:GetValue()
    local b = espColorSliderB:GetValue()
    espInstance:SetColor(Color3.fromRGB(value, g, b))
end)

local espColorSliderG = gui:CreateSlider("ESP Color (G)", 0, 255, 0, function(value)
    print("ESP Color G set to: " .. value)
    local r = espColorSliderR:GetValue()
    local b = espColorSliderB:GetValue()
    espInstance:SetColor(Color3.fromRGB(r, value, b))
end)

local espColorSliderB = gui:CreateSlider("ESP Color (B)", 0, 255, 0, function(value)
    print("ESP Color B set to: " .. value)
    local r = espColorSliderR:GetValue()
    local g = espColorSliderG:GetValue()
    espInstance:SetColor(Color3.fromRGB(r, g, value))
end)

-- Database Section
gui:CreateButton("Database Options", function() end) -- Separator (non-functional label)

local fullScanButton = gui:CreateButton("Force Full Scan", function()
    print("Forcing full database scan...")
    Utils.FullScan()
end)

-- Destroy Button
gui:CreateButton("Destroy Script", function()
    print("Destroying all components...")
    aimbotInstance:Destroy()
    espInstance:Destroy()
    Utils.Destroy()
    gui:Destroy()
end)

-- Cleanup function
local function destroyAll()
    print("Cleaning up all components...")
    aimbotInstance:Destroy()
    espInstance:Destroy()
    Utils.Destroy()
    gui:Destroy()
end

-- Handle cleanup on player removal
print("Setting up cleanup events...")
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    print("Character removing, triggering cleanup...")
    destroyAll()
end)
game.Players.PlayerRemoving:Connect(function(player)
    if player == game.Players.LocalPlayer then
        print("Player removing, triggering cleanup...")
        destroyAll()
    end
end)

print("RivalsScript execution completed.")
