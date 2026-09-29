--[[
    BALJITOT Hub - UI BloodMoon
    Map: Mount RAGNAR
    Author: BALJITOT

    FITUR:
    - 21 Checkpoint
    - Auto TP CP 1-21
    - Auto ResetSummit / Basecamp
    - Manual TP setiap CP
    - Minimize
    - Close
--]]

--==================================================
-- SERVICES
--==================================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CHECKPOINT DATABASE
--==================================================

local checkpoints = {

    Vector3.new(
        -356.9189758300781,
        19.57964515686035,
        110.0777816772461
    ), -- CP 1

    Vector3.new(
        -244.953857421875,
        107.08541107177734,
        107.88137817382812
    ), -- CP 2

    Vector3.new(
        20.29420280456543,
        264.2387390136719,
        472.74810791015625
    ), -- CP 3

    Vector3.new(
        194.5283660888672,
        369.0897216796875,
        398.6202087402344
    ), -- CP 4

    Vector3.new(
        399.28839111328125,
        413.7545166015625,
        501.48199462890625
    ), -- CP 5

    Vector3.new(
        424.6869201660156,
        460.9940490722656,
        625.0881958007812
    ), -- CP 6

    Vector3.new(
        371.43377685546875,
        494.15411376953125,
        751.5277709960938
    ), -- CP 7

    Vector3.new(
        500.3865661621094,
        351.4995422363281,
        279.7660827636719
    ), -- CP 8

    Vector3.new(
        831.9197387695312,
        604.30908203125,
        622.6732788085938
    ), -- CP 9

    Vector3.new(
        784.8890991210938,
        685.899169921875,
        669.663818359375
    ), -- CP 10

    Vector3.new(
        663.7881469726562,
        689.1882934570312,
        681.3658447265625
    ), -- CP 11

    Vector3.new(
        649.6347045898438,
        692.1765747070312,
        846.3955688476562
    ), -- CP 12

    Vector3.new(
        828.4799194335938,
        772.2919921875,
        895.9688110351562
    ), -- CP 13

    Vector3.new(
        1401.3212890625,
        842.2109375,
        584.2708740234375
    ), -- CP 14

    Vector3.new(
        1589.1361083984375,
        1030.12646484375,
        894.9366455078125
    ), -- CP 15

    Vector3.new(
        1559.0311279296875,
        1151.37841796875,
        930.5591430664062
    ), -- CP 16

    Vector3.new(
        1562.5233154296875,
        1173.7520751953125,
        1213.877197265625
    ), -- CP 17

    Vector3.new(
        1562.3768310546875,
        1285.6387939453125,
        1390.2508544921875
    ), -- CP 18

    Vector3.new(
        1139.4525146484375,
        1335.00048828125,
        1396.183837890625
    ), -- CP 19

    Vector3.new(
        750.677978515625,
        1110.154052734375,
        1772.443115234375
    ), -- CP 20

    Vector3.new(
        703.252930,
        1114.077026,
        2176.539062
    ), -- CP 21

}

--==================================================
-- CLEAN OLD UI
--==================================================

if game.CoreGui:FindFirstChild("RizzScriptHub") then
    game.CoreGui.RizzScriptHub:Destroy()
end

--==================================================
-- MAIN GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RizzScriptHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

--==================================================
-- MAIN FRAME
--==================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.Size = UDim2.new(0, 350, 0, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

--==================================================
-- TITLE BAR
--==================================================

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
TitleText.Text = "BALJITOT HUB - MOUNT RAGNAR"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left

--==================================================
-- CLOSE BUTTON
--==================================================

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.TextSize = 12

--==================================================
-- MINIMIZE BUTTON
--==================================================

local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TitleBar
MinBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
MinBtn.Position = UDim2.new(1, -65, 0, 10)
MinBtn.Size = UDim2.new(0, 20, 0, 20)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
MinBtn.TextSize = 14

--==================================================
-- CONTAINER
--==================================================

local Container = Instance.new("ScrollingFrame")
Container.Name = "Container"
Container.Parent = MainFrame
Container.Active = true
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0, 0, 0, 45)
Container.Size = UDim2.new(1, 0, 1, -50)
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
Container.ScrollBarThickness = 8
Container.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
Container.BorderSizePixel = 0

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Padding = UDim.new(0, 8)

--==================================================
-- TELEPORT FUNCTION
--==================================================

local function teleportTo(pos)

    local character = LocalPlayer.Character

    if not character then
        return false
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return false
    end

    root.CFrame = CFrame.new(pos)

    return true
end

--==================================================
-- RESET SUMMIT / BASECAMP
--==================================================

local function resetBasecamp()

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    local gui = PlayerGui:FindFirstChild("zaezannnGUI")

    if not gui then
        warn("[BALJITOT] zaezannnGUI tidak ditemukan")
        return false
    end

    local adminUI = gui:FindFirstChild("AdminCommandUI")

    if not adminUI then
        warn("[BALJITOT] AdminCommandUI tidak ditemukan")
        return false
    end

    local commandFrame = adminUI:FindFirstChild("CommandFrame")

    if not commandFrame then
        warn("[BALJITOT] CommandFrame tidak ditemukan")
        return false
    end

    local commandScroll =
        commandFrame:FindFirstChild("CommandTypeScroll")

    if not commandScroll then
        warn("[BALJITOT] CommandTypeScroll tidak ditemukan")
        return false
    end

    local resetButton =
        commandScroll:FindFirstChild("ResetSummit")

    if resetButton and resetButton:IsA("GuiButton") then

        resetButton:Activate()

        print("[BALJITOT] ResetSummit berhasil dipanggil")

        return true
    end

    warn("[BALJITOT] ResetSummit tidak ditemukan")

    return false
end

--==================================================
-- CREATE BUTTON
--==================================================

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

    btn.AutoButtonColor = false

    btn.MouseButton1Click:Connect(function()

        TweenService:Create(
            btn,
            TweenInfo.new(0.1),
            {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                TextColor3 = Color3.fromRGB(0, 0, 0)
            }
        ):Play()

        task.wait(0.1)

        TweenService:Create(
            btn,
            TweenInfo.new(0.1),
            {
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }
        ):Play()

        callback()

    end)

    return btn
end

--==================================================
-- AUTO TP
--==================================================

local autoTog = false
local autoRunning = false

local AutoBtn = CreateButton(
    "Auto TP Mount RAGNAR: OFF",
    function()
    end
)

AutoBtn.MouseButton1Click:Connect(function()

    autoTog = not autoTog

    if autoTog then

        if autoRunning then
            return
        end

        autoRunning = true

        AutoBtn.Text = "Auto TP Mount RAGNAR: ON"
        AutoBtn.BorderColor3 = Color3.fromRGB(150, 150, 150)

        task.spawn(function()

            while autoTog do

                --==================================
                -- CP 1 - CP 21
                --==================================

                for i, cp in ipairs(checkpoints) do

                    if not autoTog then
                        break
                    end

                    AutoBtn.Text =
                        "Running... CP " ..
                        tostring(i) ..
                        "/21"

                    teleportTo(cp)

                    -- Delay antar checkpoint
                    task.wait(5)

                end

                if not autoTog then
                    break
                end

                --==================================
                -- SELESAI CP 21
                -- RESET BASECAMP
                --==================================

                AutoBtn.Text =
                    "CP 21 selesai - RESET..."

                task.wait(2)

                local resetSuccess =
                    resetBasecamp()

                if resetSuccess then

                    AutoBtn.Text =
                        "Reset Basecamp berhasil"

                else

                    AutoBtn.Text =
                        "ResetSummit tidak ditemukan"

                end

                -- Tunggu proses reset
                task.wait(5)

                if not autoTog then
                    break
                end

                --==================================
                -- MULAI LAGI DARI CP 1
                --==================================

                AutoBtn.Text =
                    "Restart dari CP 1..."

                task.wait(4)

            end

            autoRunning = false

            if not autoTog then

                AutoBtn.Text =
                    "Auto TP Mount RAGNAR: OFF"

                AutoBtn.BorderColor3 =
                    Color3.fromRGB(255, 255, 255)

            end

        end)

    else

        AutoBtn.Text =
            "Auto TP Mount RAGNAR: OFF"

        AutoBtn.BorderColor3 =
            Color3.fromRGB(255, 255, 255)

    end

end)

--==================================================
-- SPACER
--==================================================

local Spacer = Instance.new("Frame")
Spacer.Parent = Container
Spacer.BackgroundTransparency = 1
Spacer.Size = UDim2.new(1, 0, 0, 5)

--==================================================
-- MANUAL TP
--==================================================

for i, cp in ipairs(checkpoints) do

    CreateButton(
        "Manual TP - Checkpoint " .. tostring(i),
        function()

            teleportTo(cp)

        end
    )

end

--==================================================
-- RESET MANUAL BUTTON
--==================================================

local Spacer2 = Instance.new("Frame")
Spacer2.Parent = Container
Spacer2.BackgroundTransparency = 1
Spacer2.Size = UDim2.new(1, 0, 0, 5)

CreateButton(
    "RESET BASECAMP / SUMMIT",
    function()

        local success = resetBasecamp()

        if success then

            AutoBtn.Text =
                "Reset Basecamp berhasil"

        end

    end
)

--==================================================
-- WEBSITE
--==================================================

CreateButton(
    "Copy Website Link",
    function()

        if setclipboard then

            setclipboard(
                "https://www.instagram.com/ariefwibowooo"
            )

            pcall(function()

                game.StarterGui:SetCore(
                    "SendNotification",
                    {
                        Title = "BALJITOT Hub",
                        Text = "Link berhasil disalin!",
                        Duration = 3
                    }
                )

            end)

        end

    end
)

--==================================================
-- MINIMIZE
--==================================================

local isMinimized = false

MinBtn.MouseButton1Click:Connect(function()

    isMinimized = not isMinimized

    if isMinimized then

        TweenService:Create(
            MainFrame,
            TweenInfo.new(
                0.4,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Size = UDim2.new(0, 350, 0, 40)
            }
        ):Play()

        Container.Visible = false

    else

        Container.Visible = true

        TweenService:Create(
            MainFrame,
            TweenInfo.new(
                0.4,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Size = UDim2.new(0, 350, 0, 400)
            }
        ):Play()

    end

end)

--==================================================
-- CLOSE
--==================================================

CloseBtn.MouseButton1Click:Connect(function()

    autoTog = false

    local closeTween = TweenService:Create(
        MainFrame,
        TweenInfo.new(
            0.4,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.In
        ),
        {
            Size = UDim2.new(0, 350, 0, 0)
        }
    )

    closeTween:Play()

    closeTween.Completed:Connect(function()

        if ScreenGui then
            ScreenGui:Destroy()
        end

    end)

end)

--==================================================
-- OPEN ANIMATION
--==================================================

TweenService:Create(
    MainFrame,
    TweenInfo.new(
        0.6,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    ),
    {
        Size = UDim2.new(0, 350, 0, 400)
    }
):Play()

print(
    "[BALJITOT] Loaded | 21 CP | Auto TP | Reset Basecamp"
)
