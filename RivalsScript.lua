-- RivalsScript.lua
-- Main script for Rivals cheat system with Censura UI menu

local function loadModule(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("Failed to load module from " .. url .. ": " .. result)
        return nil
    end
    return result
end

-- Load modules from GitHub
local CensuraDev = loadModule("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua")
local Aimbot = loadModule("https://raw.githubusercontent.com/LxckStxp/RivalsMenu/main/Aimbot.lua")
local ESP = loadModule("https://raw.githubusercontent.com/LxckStxp/RivalsMenu/main/ESP.lua")
local Utils = loadModule("https://raw.githubusercontent.com/LxckStxp/RivalsMenu/main/Utils.lua")

-- Verify all modules loaded
if not (CensuraDev and Aimbot and ESP and Utils) then
    warn("One or more modules failed to load. Script execution halted.")
    return
end

-- Initialize the UI
local gui = CensuraDev.new("Rivals Cheats")
gui:Show()

-- Create instances of Aimbot and ESP
local aimbotInstance = Aimbot.new()
local espInstance = ESP.new()

-- Build the menu using CensuraDev
local aimbotToggle = gui:CreateToggle("Aimbot", false, function(state)
    if state then
        aimbotInstance:Enable()
    else
        aimbotInstance:Disable()
    end
end)

local aimbotFOVSlider = gui:CreateSlider("Aimbot FOV", 50, 300, 150, function(value)
    aimbotInstance:SetFOV(value)
end)

local espToggle = gui:CreateToggle("ESP", false, function(state)
    if state then
        espInstance:Enable()
    else
        espInstance:Disable()
    end
end)

local espTeamCheck = gui:CreateToggle("Team Check", true, function(state)
    espInstance:SetTeamCheck(state)
end)

local destroyButton = gui:CreateButton("Destroy", function()
    aimbotInstance:Destroy()
    espInstance:Destroy()
    Utils.Destroy()
    gui:Destroy()
end)

-- Cleanup function
local function destroyAll()
    aimbotInstance:Destroy()
    espInstance:Destroy()
    Utils.Destroy()
    gui:Destroy()
end

-- Handle cleanup on player removal
game.Players.LocalPlayer.CharacterRemoving:Connect(destroyAll)
game.Players.PlayerRemoving:Connect(function(player)
    if player == game.Players.LocalPlayer then
        destroyAll()
    end
end)
