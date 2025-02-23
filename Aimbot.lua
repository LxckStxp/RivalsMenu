-- Aimbot.lua
-- Aimbot functionality for Rivals with improved targeting and lock persistence

local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/RivalsScript/main/Utils.lua"))()
local Aimbot = {}
Aimbot.__index = Aimbot

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

function Aimbot.new()
    local self = setmetatable({}, Aimbot)
    self.Enabled = false
    self.FOV = 150          -- Default FOV (pixels)
    self.Smoothing = true   -- Default to smooth aiming
    self.Smoothness = 0.1   -- Default smoothing factor (0.05-0.5 range)
    self.Target = nil       -- Current locked target
    self.Connection = nil
    return self
end

function Aimbot:Enable()
    if self.Enabled then return end
    self.Enabled = true
    print("Aimbot enabled.")
    
    self.Connection = RunService.RenderStepped:Connect(function()
        if self.Enabled then
            self:Update()
        end
    end)
end

function Aimbot:Disable()
    self.Enabled = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    self.Target = nil -- Clear target when disabled
    print("Aimbot disabled.")
end

function Aimbot:SetFOV(value)
    self.FOV = math.clamp(value, 50, 300) -- Ensure value stays within UI range
    print("Aimbot FOV updated to: " .. self.FOV)
end

function Aimbot:SetSmoothing(state)
    self.Smoothing = state
    print("Aimbot smoothing set to: " .. tostring(state))
end

function Aimbot:SetSmoothness(value)
    self.Smoothness = math.clamp(value, 0.05, 0.5) -- Ensure value stays within UI range
    print("Aimbot smoothness updated to: " .. self.Smoothness)
end

function Aimbot:IsTargetValid(targetData)
    if not targetData or not targetData.Player or not targetData.Player.Character then
        return false
    end
    local humanoid = targetData.Humanoid
    local rootPart = targetData.RootPart
    return humanoid and humanoid.Health > 0 and rootPart and rootPart.Parent
end

function Aimbot:Update()
    local localPlayer = Players.LocalPlayer
    local camera = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local isKeyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if not isKeyPressed then
        self.Target = nil -- Release lock when key is lifted
        return
    end

    -- If we have a valid target, stick to it
    if self.Target and self:IsTargetValid(self.Target) then
        local character = self.Target.Player.Character
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
        local targetPart = head or torso -- Prioritize Head, then Torso
        if targetPart then
            local targetPos = camera:WorldToViewportPoint(targetPart.Position)
            if self.Smoothing then
                Utils.SmoothAim(camera, targetPos, self.Smoothness)
            else
                Utils.SnapAim(camera, targetPos)
            end
        end
        return
    end

    -- Find a new target if no valid lock exists
    local closestPlayer, closestDist = nil, self.FOV
    
    for _, data in pairs(Utils.GetPlayers()) do
        local player = data.Player
        if player ~= localPlayer then
            local character = player.Character
            if character then
                local head = character:FindFirstChild("Head")
                local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
                local targetPart = head or torso -- Prioritize Head, then Torso
                if targetPart then
                    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestPlayer = data
                        end
                    end
                end
            end
        end
    end
    
    if closestPlayer then
        self.Target = closestPlayer
        local character = closestPlayer.Player.Character
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
        local targetPart = head or torso
        if targetPart then
            local targetPos = camera:WorldToViewportPoint(targetPart.Position)
            if self.Smoothing then
                Utils.SmoothAim(camera, targetPos, self.Smoothness)
            else
                Utils.SnapAim(camera, targetPos)
            end
            print("Locked onto target: " .. closestPlayer.Player.Name)
        end
    end
end

function Aimbot:Destroy()
    self:Disable()
    self.Target = nil
    print("Aimbot instance destroyed.")
end

return Aimbot
