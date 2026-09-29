--[[ 
    RizzScript Hub - UI BloodMoon (Hitam Putih)
    Map: Mount Sumbing
    Author: RizzScript Hub
--]]

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Database Koordinat (Sudah Hardcoded)
local checkpoints = {
    Vector3.new(-334.58050537109375, 5.167461395263672, 33.887359619140625),   -- CP 1
    Vector3.new(-224.5961151123047, 441.16094970703125, 2142.396728515625),    -- CP 2
    Vector3.new(-426.72625732421875, 849.1610107421875, 3205.2958984375),      -- CP 3
    Vector3.new(41.53706359863281, 1269.1607666015625, 4043.316162109375),    -- CP 4
    Vector3.new(-1141.8299560546875, 1553.16064453125, 4899.7470703125),       -- CP 5
    Vector3.new(-940.3917846679688, 1926.4130859375, 5405.724609375)           -- CP 6
}

-- Mencegah duplikasi UI jika diexecute berkali-kali
if game.CoreGui:FindFirstChild("RizzScriptHub") then
    game.CoreGui.RizzScriptHub:Destroy()
end

-- Membuat UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RizzScriptHub"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Hitam gelap
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255) -- Border putih (Tema BloodMoon Hitam Putih)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.Size = UDim2.new(0, 350, 0, 0) -- Mulai dari 0 untuk animasi
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.Size = UDim2.new(0.7, 0, 1, 0)
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "RizzScript Hub - Mount Sumbing"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.TextSize = 12

local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TitleBar
MinBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
MinBtn.Position = UDim2.new(1, -65, 0, 10)
MinBtn.Size = UDim2.new(0, 20, 0, 20)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
MinBtn.TextSize = 14

local Container = Instance.new("ScrollingFrame")
Container.Parent = MainFrame
Container.Active = true
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0, 0, 0, 45)
Container.Size = UDim2.new(1, 0, 1, -50)
Container.CanvasSize = UDim2.new(0, 0, 0, 450)
Container.ScrollBarThickness = 4
Container.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Padding = UDim.new(0, 8)

-- Fungsi Animasi Muncul (Execute)
TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 350, 0, 400)}):Play()

-- Logika Teleport
local function teleportTo(pos)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- Komponen Pembuat Tombol
local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = Container
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 1
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    
    btn.MouseButton1Click:Connect(function()
        -- Animasi klik
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), TextColor3 = Color3.fromRGB(0,0,0)}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(25, 25, 25), TextColor3 = Color3.fromRGB(255,255,255)}):Play()
        callback()
    end)
    return btn
end

-- Fitur Auto TP (Toggle Mode)
local autoTog = false
local AutoBtn = CreateButton("Auto TP Mount Sumbing: OFF", function() end)

AutoBtn.MouseButton1Click:Connect(function()
    autoTog = not autoTog
    if autoTog then
        AutoBtn.Text = "Auto TP Mount Sumbing: ON (Running...)"
        AutoBtn.BorderColor3 = Color3.fromRGB(150, 150, 150)
        task.spawn(function()
            while autoTog do
                for i, cp in ipairs(checkpoints) do
                    if not autoTog then break end
                    teleportTo(cp)
                    task.wait(3) -- Delay 3 detik sesuai permintaan
                end
            end
        end)
    else
        AutoBtn.Text = "Auto TP Mount Sumbing: OFF"
        AutoBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

-- Spacer
local Spacer = Instance.new("Frame")
Spacer.Parent = Container
Spacer.BackgroundTransparency = 1
Spacer.Size = UDim2.new(1, 0, 0, 5)

-- Manual TP Buttons
for i, cp in ipairs(checkpoints) do
    CreateButton("Manual TP - Checkpoint " .. i, function()
        teleportTo(cp)
    end)
end

-- Spacer
local Spacer2 = Instance.new("Frame")
Spacer2.Parent = Container
Spacer2.BackgroundTransparency = 1
Spacer2.Size = UDim2.new(1, 0, 0, 5)

-- Website (Copy Link)
CreateButton("Copy Website Link", function()
    -- Menggunakan fungsi bawaan executor untuk menyalin ke clipboard
    if setclipboard then
        setclipboard("https://rizz-script-roblox.blogspot.com/") -- Ganti dengan link website kamu yang sebenarnya
        
        -- Notifikasi Roblox saat disalin
        game.StarterGui:SetCore("SendNotification", {
            Title = "RizzScript Hub",
            Text = "Link website berhasil disalin ke clipboard!",
            Duration = 3
        })
    end
end)

-- Sistem Minimize & Close
local isMinimized = false

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 350, 0, 40)}):Play()
        Container.Visible = false
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 350, 0, 400)}):Play()
        Container.Visible = true
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    autoTog = false -- Matikan Auto TP jika sedang jalan
    local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 350, 0, 0)})
    closeTween:Play()
    closeTween.Completed:Connect(function()
        ScreenGui:Destroy()
    end)
end)
