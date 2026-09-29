--[[
    BALJITOT PATH RECORDER
    REAL-TIME CP RECORDER + JUMP TRACKER + MERGE SYSTEM

    FITUR:
    - Record movement
    - Record posisi walaupun diam
    - Record jump
    - Real-time timestamp
    - Playback berdasarkan waktu record
    - Save config per CP
    - Auto save ke folder executor
    - Config list
    - Load config
    - Delete config
    - Merge beberapa config berdasarkan urutan
    - Save hasil merge
    - Play path
    - Loop + Basecamp

    Executor:
    Delta / Potassium
]]

--==================================================--
-- SERVICES
--==================================================--

local Players =
    game:GetService("Players")

local RunService =
    game:GetService("RunService")

local TweenService =
    game:GetService("TweenService")

local ReplicatedStorage =
    game:GetService("ReplicatedStorage")

local HttpService =
    game:GetService("HttpService")

local Player =
    Players.LocalPlayer

local PlayerGui =
    Player:WaitForChild("PlayerGui")

--==================================================--
-- SETTINGS
--==================================================--

-- Semakin kecil semakin detail.
local RECORD_RATE = 1 / 60

-- Jarak untuk dianggap sudah mencapai target.
local WAYPOINT_DISTANCE = 0.75

-- Jeda setelah reset basecamp.
local RESPAWN_WAIT = 3

-- Toleransi waktu playback.
local TIME_LOOKAHEAD = 0.015

-- Berapa frame maksimal yang boleh dilewati
-- dalam satu update playback.
local MAX_FRAME_SKIP = 1

local CONFIG_FOLDER =
    "BaljitotConfigs"

--==================================================--
-- FILE API
--==================================================--

local FileAPIAvailable =
    type(writefile) == "function"
    and type(readfile) == "function"

local FolderAPIAvailable =
    FileAPIAvailable
    and type(makefolder) == "function"
    and type(isfolder) == "function"
    and type(listfiles) == "function"

local Configs = {}

local selectedConfig = nil

--==================================================--
-- CONFIG FILE HELPERS
--==================================================--

local function ensureConfigFolder()

    if not FolderAPIAvailable then
        return false
    end

    local ok = pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
    end)

    return ok
end

local function sanitizeConfigName(name)

    name = tostring(name or "")

    name = string.gsub(name, "[\\/:*?\"<>|]", "_")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")

    if name == "" then
        name = "CP_" .. tostring(os.time())
    end

    name = string.gsub(name, "%.tas$", "")

    return name
end

local function getConfigPath(name)
    return CONFIG_FOLDER .. "/" ..
        sanitizeConfigName(name) .. ".tas"
end

local function serializeFrame(frame)

    if type(frame) ~= "table"
        or not frame.position then
        return nil
    end

    local p = frame.position

    return {
        x = tonumber(p.X) or 0,
        y = tonumber(p.Y) or 0,
        z = tonumber(p.Z) or 0,
        jump = frame.jump == true,
        time = tonumber(frame.time) or 0
    }
end

local function saveConfigFile(name, framesToSave)

    if not FileAPIAvailable then
        return false
    end

    if not ensureConfigFolder() then
        return false
    end

    local serialFrames = {}

    for i, frame in ipairs(framesToSave or {}) do

        local encodedFrame =
            serializeFrame(frame)

        if encodedFrame then
            serialFrames[i] = encodedFrame
        end

    end

    local payload = {
        version = 2,
        name = sanitizeConfigName(name),
        fps = 60,
        frames = serialFrames
    }

    local success = pcall(function()

        writefile(
            getConfigPath(name),
            HttpService:JSONEncode(payload)
        )

    end)

    return success
end

local function deserializeFrames(rawFrames)

    local result = {}

    if type(rawFrames) ~= "table" then
        return result
    end

    for _, frame in ipairs(rawFrames) do

        if type(frame) == "table" then

            local p = frame.position

            if type(p) == "table" then

                -- Format lama: position = {X,Y,Z}
                table.insert(result, {
                    position = Vector3.new(
                        tonumber(p.X) or tonumber(p.x) or 0,
                        tonumber(p.Y) or tonumber(p.y) or 0,
                        tonumber(p.Z) or tonumber(p.z) or 0
                    ),
                    jump = frame.jump == true,
                    time = tonumber(frame.time) or 0
                })

            elseif frame.x ~= nil or frame.y ~= nil or frame.z ~= nil then

                -- Format baru: x/y/z langsung di frame
                table.insert(result, {
                    position = Vector3.new(
                        tonumber(frame.x) or 0,
                        tonumber(frame.y) or 0,
                        tonumber(frame.z) or 0
                    ),
                    jump = frame.jump == true,
                    time = tonumber(frame.time) or 0
                })

            end

        end

    end

    table.sort(result, function(a, b)
        return (a.time or 0) < (b.time or 0)
    end)

    return result
end

local function loadSingleConfig(path)

    if not FileAPIAvailable
        or type(readfile) ~= "function" then
        return nil, nil
    end

    local success, decoded = pcall(function()

        return HttpService:JSONDecode(
            readfile(path)
        )

    end)

    if not success
        or type(decoded) ~= "table" then
        return nil, nil
    end

    local framesData = decoded.frames

    -- Dukungan untuk file yang langsung berisi array frames.
    if type(framesData) ~= "table" then
        framesData = decoded
    end

    local decodedFrames =
        deserializeFrames(framesData)

    local filename =
        tostring(path):match("([^/\\]+)$")
        or tostring(path)

    filename =
        string.gsub(filename, "%.tas$", "")

    local name =
        tostring(decoded.name or filename)

    return name, decodedFrames
end

local function loadConfigsFromFolder()

    Configs = {}

    if not FolderAPIAvailable then
        return false
    end

    if not ensureConfigFolder() then
        return false
    end

    local success, files =
        pcall(function()
            return listfiles(CONFIG_FOLDER)
        end)

    if not success or type(files) ~= "table" then
        return false
    end

    for _, path in ipairs(files) do

        local pathString = tostring(path)

        if pathString:lower():match("%.tas$") then

            local name, loadedFrames =
                loadSingleConfig(pathString)

            if name and loadedFrames
                and #loadedFrames > 0 then

                Configs[sanitizeConfigName(name)] =
                    loadedFrames

            end

        end

    end

    return true
end

local function saveConfigsToFile()

    -- Simpan semua config sebagai file .tas terpisah.
    if not FileAPIAvailable then
        return false
    end

    if not ensureConfigFolder() then
        return false
    end

    local allSaved = true

    for name, configFrames in pairs(Configs) do

        if not saveConfigFile(name, configFrames) then
            allSaved = false
        end

    end

    return allSaved
end

local function loadConfigsFromFile()
    return loadConfigsFromFolder()
end

local function deleteConfigFile(name)

    if not FileAPIAvailable
        or type(delfile) ~= "function" then
        return false
    end

    local path = getConfigPath(name)

    local exists = true

    if type(isfile) == "function" then
        local ok, result = pcall(function()
            return isfile(path)
        end)

        exists = ok and result == true
    end

    if not exists then
        return true
    end

    local success = pcall(function()
        delfile(path)
    end)

    return success
end

loadConfigsFromFile()

--==================================================--
-- STATE
--==================================================--

local recording = false
local playing = false
local looping = false

local frames = {}

local recordConnection = nil
local jumpConnection = nil
local playConnection = nil

local playToken = 0

local lastGrounded = true
local lastVerticalVelocity = 0
local jumpCooldown = 0

-- Event jump flag.
local jumpQueued = false

--==================================================--
-- MERGE QUEUE
--==================================================--

local MergeQueue = {}

--==================================================--
-- CHARACTER
--==================================================--

local function getCharacter()

    local character =
        Player.Character

    if not character then
        return nil, nil, nil
    end

    local humanoid =
        character:FindFirstChildOfClass(
            "Humanoid"
        )

    local root =
        character:FindFirstChild(
            "HumanoidRootPart"
        )

    return character, humanoid, root
end

--==================================================--
-- BASECAMP
--==================================================--

local function getResetRemote()

    local Remotes =
        ReplicatedStorage:FindFirstChild(
            "Remotes"
        )

    if not Remotes then

        warn(
            "BALJITOT: Remotes tidak ditemukan"
        )

        return nil
    end

    local ResetToBasecamp =
        Remotes:FindFirstChild(
            "ResetToBasecamp"
        )

    if not ResetToBasecamp then

        warn(
            "BALJITOT: ResetToBasecamp tidak ditemukan"
        )

        return nil
    end

    if not ResetToBasecamp:IsA(
        "RemoteEvent"
    ) then

        return nil
    end

    return ResetToBasecamp
end

local function resetToBasecamp()

    local remote =
        getResetRemote()

    if not remote then
        return false
    end

    local success =
        pcall(function()

            remote:FireServer()

        end)

    return success
end

--==================================================--
-- GUI CLEANUP
--==================================================--

local oldGui =
    PlayerGui:FindFirstChild(
        "BaljitotRecorder"
    )

if oldGui then
    oldGui:Destroy()
end

--==================================================--
-- SCREEN GUI
--==================================================--

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "BaljitotRecorder"

ScreenGui.ResetOnSpawn =
    false

ScreenGui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

ScreenGui.Parent =
    PlayerGui

--==================================================--
-- MAIN FRAME
--==================================================--

local MainFrame =
    Instance.new("Frame")

MainFrame.Name =
    "MainFrame"

MainFrame.Parent =
    ScreenGui

MainFrame.BackgroundColor3 =
    Color3.fromRGB(
        15,
        15,
        15
    )

MainFrame.BorderColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

MainFrame.BorderSizePixel = 2

MainFrame.Position =
    UDim2.new(
        0.5,
        -200,
        0.5,
        -300
    )

MainFrame.Size =
    UDim2.new(
        0,
        400,
        0,
        0
    )

MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

--==================================================--
-- TITLE BAR
--==================================================--

local TitleBar =
    Instance.new("Frame")

TitleBar.Parent =
    MainFrame

TitleBar.BackgroundColor3 =
    Color3.fromRGB(
        30,
        30,
        30
    )

TitleBar.Size =
    UDim2.new(
        1,
        0,
        0,
        40
    )

TitleBar.BorderSizePixel = 0

local TitleText =
    Instance.new("TextLabel")

TitleText.Parent =
    TitleBar

TitleText.BackgroundTransparency = 1

TitleText.Position =
    UDim2.new(
        0,
        10,
        0,
        0
    )

TitleText.Size =
    UDim2.new(
        0.75,
        0,
        1,
        0
    )

TitleText.Font =
    Enum.Font.GothamBold

TitleText.Text =
    "BALJITOT HUB - CP RECORDER"

TitleText.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

TitleText.TextSize = 13

TitleText.TextXAlignment =
    Enum.TextXAlignment.Left

--==================================================--
-- CLOSE
--==================================================--

local CloseBtn =
    Instance.new("TextButton")

CloseBtn.Parent =
    TitleBar

CloseBtn.BackgroundColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

CloseBtn.Position =
    UDim2.new(
        1,
        -35,
        0,
        10
    )

CloseBtn.Size =
    UDim2.new(
        0,
        20,
        0,
        20
    )

CloseBtn.Font =
    Enum.Font.GothamBold

CloseBtn.Text = "X"

CloseBtn.TextColor3 =
    Color3.fromRGB(
        0,
        0,
        0
    )

CloseBtn.TextSize = 12

--==================================================--
-- MINIMIZE
--==================================================--

local MinBtn =
    Instance.new("TextButton")

MinBtn.Parent =
    TitleBar

MinBtn.BackgroundColor3 =
    Color3.fromRGB(
        150,
        150,
        150
    )

MinBtn.Position =
    UDim2.new(
        1,
        -65,
        0,
        10
    )

MinBtn.Size =
    UDim2.new(
        0,
        20,
        0,
        20
    )

MinBtn.Font =
    Enum.Font.GothamBold

MinBtn.Text = "-"

MinBtn.TextColor3 =
    Color3.fromRGB(
        0,
        0,
        0
    )

MinBtn.TextSize = 14

--==================================================--
-- CONTAINER
--==================================================--

local Container =
    Instance.new("ScrollingFrame")

Container.Parent =
    MainFrame

Container.Active = true

Container.BackgroundTransparency = 1

Container.BorderSizePixel = 0

Container.Position =
    UDim2.new(
        0,
        0,
        0,
        45
    )

Container.Size =
    UDim2.new(
        1,
        0,
        1,
        -50
    )

Container.CanvasSize =
    UDim2.new(
        0,
        0,
        0,
        0
    )

Container.AutomaticCanvasSize =
    Enum.AutomaticSize.Y

Container.ScrollBarThickness = 8

Container.ScrollBarImageColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

local UIListLayout =
    Instance.new("UIListLayout")

UIListLayout.Parent =
    Container

UIListLayout.HorizontalAlignment =
    Enum.HorizontalAlignment.Center

UIListLayout.Padding =
    UDim.new(
        0,
        7
    )

--==================================================--
-- STATUS
--==================================================--

local Status =
    Instance.new("TextLabel")

Status.Parent =
    Container

Status.BackgroundTransparency = 1

Status.Size =
    UDim2.new(
        0.9,
        0,
        0,
        35
    )

Status.Font =
    Enum.Font.GothamBold

Status.Text =
    "STATUS: READY"

Status.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

Status.TextSize = 12

Status.TextWrapped = true

--==================================================--
-- BUTTON CREATOR
--==================================================--

local function CreateButton(
    text,
    callback
)

    local Button =
        Instance.new("TextButton")

    Button.Parent =
        Container

    Button.BackgroundColor3 =
        Color3.fromRGB(
            25,
            25,
            25
        )

    Button.BorderColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    Button.BorderSizePixel = 1

    Button.Size =
        UDim2.new(
            0.9,
            0,
            0,
            35
        )

    Button.Font =
        Enum.Font.GothamSemibold

    Button.Text =
        text

    Button.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    Button.TextSize = 12

    Button.MouseButton1Click:Connect(
        function()

            TweenService:Create(
                Button,
                TweenInfo.new(0.08),
                {
                    BackgroundColor3 =
                        Color3.fromRGB(
                            255,
                            255,
                            255
                        ),

                    TextColor3 =
                        Color3.fromRGB(
                            0,
                            0,
                            0
                        )
                }
            ):Play()

            task.wait(0.08)

            TweenService:Create(
                Button,
                TweenInfo.new(0.08),
                {
                    BackgroundColor3 =
                        Color3.fromRGB(
                            25,
                            25,
                            25
                        ),

                    TextColor3 =
                        Color3.fromRGB(
                            255,
                            255,
                            255
                        )
                }
            ):Play()

            callback(Button)

        end
    )

    return Button
end

--==================================================--
-- CONFIG NAME
--==================================================--

local ConfigTitle =
    Instance.new("TextLabel")

ConfigTitle.Parent =
    Container

ConfigTitle.BackgroundTransparency = 1

ConfigTitle.Size =
    UDim2.new(
        0.9,
        0,
        0,
        25
    )

ConfigTitle.Font =
    Enum.Font.GothamBold

ConfigTitle.Text =
    "CONFIG NAME"

ConfigTitle.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

ConfigTitle.TextSize = 12

local ConfigNameBox =
    Instance.new("TextBox")

ConfigNameBox.Parent =
    Container

ConfigNameBox.BackgroundColor3 =
    Color3.fromRGB(
        25,
        25,
        25
    )

ConfigNameBox.BorderColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

ConfigNameBox.BorderSizePixel = 1

ConfigNameBox.Size =
    UDim2.new(
        0.9,
        0,
        0,
        35
    )

ConfigNameBox.Font =
    Enum.Font.Gotham

ConfigNameBox.PlaceholderText =
    "Contoh: CP1"

ConfigNameBox.Text = ""

ConfigNameBox.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

ConfigNameBox.PlaceholderColor3 =
    Color3.fromRGB(
        130,
        130,
        130
    )

ConfigNameBox.TextSize = 12

--==================================================--
-- CONFIG LIST TITLE
--==================================================--

local ListTitle =
    Instance.new("TextLabel")

ListTitle.Parent =
    Container

ListTitle.BackgroundTransparency = 1

ListTitle.Size =
    UDim2.new(
        0.9,
        0,
        0,
        25
    )

ListTitle.Font =
    Enum.Font.GothamBold

ListTitle.Text =
    "CONFIG LIST"

ListTitle.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

ListTitle.TextSize = 12

--==================================================--
-- CONFIG LIST
--==================================================--

local ConfigList =
    Instance.new("ScrollingFrame")

ConfigList.Parent =
    Container

ConfigList.BackgroundColor3 =
    Color3.fromRGB(
        10,
        10,
        10
    )

ConfigList.BorderColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

ConfigList.BorderSizePixel = 1

ConfigList.Size =
    UDim2.new(
        0.9,
        0,
        0,
        130
    )

ConfigList.CanvasSize =
    UDim2.new(
        0,
        0,
        0,
        0
    )

ConfigList.AutomaticCanvasSize =
    Enum.AutomaticSize.Y

ConfigList.ScrollBarThickness = 6

local ConfigLayout =
    Instance.new("UIListLayout")

ConfigLayout.Parent =
    ConfigList

ConfigLayout.Padding =
    UDim.new(
        0,
        3
    )

ConfigLayout.HorizontalAlignment =
    Enum.HorizontalAlignment.Center

--==================================================--
-- REFRESH CONFIG LIST
--==================================================--

local refreshConfigList

refreshConfigList =
    function()

        for _, child in
            ipairs(
                ConfigList:GetChildren()
            ) do

            if child:IsA(
                "TextButton"
            )
            or child:IsA(
                "TextLabel"
            ) then

                child:Destroy()

            end

        end

        if next(Configs) == nil then

            selectedConfig = nil

            local Empty =
                Instance.new(
                    "TextLabel"
                )

            Empty.Parent =
                ConfigList

            Empty.BackgroundTransparency = 1

            Empty.Size =
                UDim2.new(
                    1,
                    0,
                    0,
                    30
                )

            Empty.Font =
                Enum.Font.Gotham

            Empty.Text =
                "Belum ada config"

            Empty.TextColor3 =
                Color3.fromRGB(
                    130,
                    130,
                    130
                )

            Empty.TextSize = 11

            return
        end

        if selectedConfig
            and not Configs[selectedConfig] then

            selectedConfig = nil

        end

        local names = {}

        for name in pairs(Configs) do

            table.insert(
                names,
                name
            )

        end

        table.sort(
            names,
            function(a, b)

                return string.lower(a)
                    <
                    string.lower(b)

            end
        )

        for _, name in
            ipairs(names) do

            local data =
                Configs[name]

            local count = 0

            if type(data) == "table" then
                count = #data
            end

            local Button =
                Instance.new(
                    "TextButton"
                )

            Button.Parent =
                ConfigList

            if selectedConfig == name then

                Button.BackgroundColor3 =
                    Color3.fromRGB(
                        70,
                        70,
                        70
                    )

            else

                Button.BackgroundColor3 =
                    Color3.fromRGB(
                        25,
                        25,
                        25
                    )

            end

            Button.BorderColor3 =
                Color3.fromRGB(
                    80,
                    80,
                    80
                )

            Button.BorderSizePixel = 1

            Button.Size =
                UDim2.new(
                    0.95,
                    0,
                    0,
                    30
                )

            Button.Font =
                Enum.Font.GothamSemibold

            Button.Text =
                name ..
                " [" ..
                tostring(count) ..
                " frames]"

            Button.TextColor3 =
                Color3.fromRGB(
                    255,
                    255,
                    255
                )

            Button.TextSize = 11

            Button.MouseButton1Click:Connect(
                function()

                    selectedConfig =
                        name

                    refreshConfigList()

                    Status.Text =
                        "STATUS: SELECTED [" ..
                        name ..
                        "]"

                end
            )

        end

    end

--==================================================--
-- MERGE QUEUE TITLE
--==================================================--

local MergeTitle =
    Instance.new("TextLabel")

MergeTitle.Parent =
    Container

MergeTitle.BackgroundTransparency = 1

MergeTitle.Size =
    UDim2.new(
        0.9,
        0,
        0,
        25
    )

MergeTitle.Font =
    Enum.Font.GothamBold

MergeTitle.Text =
    "MERGE QUEUE"

MergeTitle.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

MergeTitle.TextSize = 12

--==================================================--
-- MERGE LIST
--==================================================--

local MergeList =
    Instance.new("ScrollingFrame")

MergeList.Parent =
    Container

MergeList.BackgroundColor3 =
    Color3.fromRGB(
        10,
        10,
        10
    )

MergeList.BorderColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

MergeList.BorderSizePixel = 1

MergeList.Size =
    UDim2.new(
        0.9,
        0,
        0,
        110
    )

MergeList.CanvasSize =
    UDim2.new(
        0,
        0,
        0,
        0
    )

MergeList.AutomaticCanvasSize =
    Enum.AutomaticSize.Y

MergeList.ScrollBarThickness = 6

local MergeLayout =
    Instance.new("UIListLayout")

MergeLayout.Parent =
    MergeList

MergeLayout.Padding =
    UDim.new(
        0,
        3
    )

MergeLayout.HorizontalAlignment =
    Enum.HorizontalAlignment.Center

--==================================================--
-- REFRESH MERGE LIST
--==================================================--

local refreshMergeList

refreshMergeList =
    function()

        for _, child in
            ipairs(
                MergeList:GetChildren()
            ) do

            if child:IsA(
                "TextButton"
            )
            or child:IsA(
                "TextLabel"
            ) then

                child:Destroy()

            end

        end

        if #MergeQueue == 0 then

            local Empty =
                Instance.new(
                    "TextLabel"
                )

            Empty.Parent =
                MergeList

            Empty.BackgroundTransparency = 1

            Empty.Size =
                UDim2.new(
                    1,
                    0,
                    0,
                    30
                )

            Empty.Font =
                Enum.Font.Gotham

            Empty.Text =
                "Queue kosong"

            Empty.TextColor3 =
                Color3.fromRGB(
                    130,
                    130,
                    130
                )

            Empty.TextSize = 11

            return
        end

        for index, name in
            ipairs(
                MergeQueue
            ) do

            local Button =
                Instance.new(
                    "TextButton"
                )

            Button.Parent =
                MergeList

            Button.BackgroundColor3 =
                Color3.fromRGB(
                    25,
                    25,
                    25
                )

            Button.BorderColor3 =
                Color3.fromRGB(
                    80,
                    80,
                    80
                )

            Button.BorderSizePixel = 1

            Button.Size =
                UDim2.new(
                    0.95,
                    0,
                    0,
                    28
                )

            Button.Font =
                Enum.Font.GothamSemibold

            Button.Text =
                tostring(index) ..
                ". " ..
                tostring(name)

            Button.TextColor3 =
                Color3.fromRGB(
                    255,
                    255,
                    255
                )

            Button.TextSize = 11

            Button.MouseButton1Click:Connect(
                function()

                    table.remove(
                        MergeQueue,
                        index
                    )

                    refreshMergeList()

                    Status.Text =
                        "STATUS: REMOVED FROM QUEUE"

                end
            )

        end

    end

--==================================================--
-- ADD SELECTED TO MERGE
--==================================================--

CreateButton(
    "ADD SELECTED TO MERGE",
    function()

        if not selectedConfig then

            Status.Text =
                "STATUS: SELECT CONFIG FIRST"

            return
        end

        if not Configs[selectedConfig] then

            Status.Text =
                "STATUS: CONFIG NOT FOUND"

            return
        end

        table.insert(
            MergeQueue,
            selectedConfig
        )

        refreshMergeList()

        Status.Text =
            "STATUS: ADDED [" ..
            selectedConfig ..
            "] TO QUEUE"

    end
)

--==================================================--
-- CLEAR MERGE QUEUE
--==================================================--

CreateButton(
    "CLEAR MERGE QUEUE",
    function()

        MergeQueue = {}

        refreshMergeList()

        Status.Text =
            "STATUS: MERGE QUEUE CLEARED"

    end
)

--==================================================--
-- NORMALIZE FRAME
--==================================================--

local function normalizeFrame(frame)

    if not frame then
        return nil
    end

    if not frame.position then
        return nil
    end

    local p =
        frame.position

    return {

        position =
            Vector3.new(
                tonumber(p.X) or 0,
                tonumber(p.Y) or 0,
                tonumber(p.Z) or 0
            ),

        jump =
            frame.jump == true,

        time =
            tonumber(frame.time) or 0

    }

end

--==================================================--
-- MERGE CONFIGS
--==================================================--

local function mergeConfigs()

    if #MergeQueue < 1 then

        Status.Text =
            "STATUS: MERGE QUEUE EMPTY"

        return nil
    end

    local merged = {}

    local totalTime = 0

    for _, configName in
        ipairs(MergeQueue) do

        local config =
            Configs[configName]

        if config then

            local firstTime = nil
            local lastTime = 0

            for _, rawFrame in
                ipairs(config) do

                local frame =
                    normalizeFrame(
                        rawFrame
                    )

                if frame then

                    if firstTime == nil then
                        firstTime =
                            frame.time
                    end

                    lastTime =
                        frame.time

                    table.insert(
                        merged,
                        {

                            position =
                                frame.position,

                            jump =
                                frame.jump,

                            time =
                                totalTime +
                                math.max(
                                    0,
                                    frame.time -
                                    (firstTime or 0)
                                )

                        }
                    )

                end

            end

            if firstTime ~= nil then

                totalTime +=
                    math.max(
                        0,
                        lastTime -
                        firstTime
                    )

            end

        end

    end

    return merged
end

--==================================================--
-- MERGE BUTTON
--==================================================--

CreateButton(
    "MERGE CONFIGS",
    function()

        local merged =
            mergeConfigs()

        if not merged
            or #merged < 2 then

            Status.Text =
                "STATUS: MERGE RESULT INVALID"

            return
        end

        frames = merged

        local name =
            ConfigNameBox.Text

        name =
            string.gsub(
                name,
                "^%s+",
                ""
            )

        name =
            string.gsub(
                name,
                "%s+$",
                ""
            )

        if name == "" then

            name =
                "FULL_RUN"

        end

        Configs[name] =
            merged

        selectedConfig =
            name

        saveConfigsToFile()

        refreshConfigList()

        ConfigNameBox.Text = ""

        Status.Text =
            "STATUS: MERGED [" ..
            name ..
            "] - " ..
            tostring(
                #merged
            ) ..
            " FRAMES"

    end
)

--==================================================--
-- SAVE CURRENT RECORD
--==================================================--

CreateButton(
    "SAVE CURRENT AS CONFIG",
    function()

        if #frames < 2 then

            Status.Text =
                "STATUS: RECORD PATH FIRST"

            return
        end

        local name =
            ConfigNameBox.Text

        name =
            sanitizeConfigName(name)

        local copied = {}

        for i, frame in
            ipairs(frames) do

            local encoded =
                serializeFrame(frame)

            if encoded then

                copied[i] = {
                    position =
                        Vector3.new(
                            encoded.x,
                            encoded.y,
                            encoded.z
                        ),
                    jump = encoded.jump,
                    time = encoded.time
                }

            end

        end

        Configs[name] = copied
        selectedConfig = name

        local saved =
            saveConfigFile(name, copied)

        refreshConfigList()

        ConfigNameBox.Text = ""

        if saved then

            Status.Text =
                "STATUS: SAVED [" ..
                name ..
                "]"

        else

            Status.Text =
                "STATUS: SAVE FAILED - FILE API"

        end

    end
)

--==================================================--
-- LOAD CONFIG
--==================================================--

CreateButton(
    "LOAD SELECTED CONFIG",
    function()

        if not selectedConfig then

            Status.Text =
                "STATUS: SELECT CONFIG FIRST"

            return
        end

        if playing
            or recording then

            Status.Text =
                "STATUS: STOP ACTIVE ACTION FIRST"

            return
        end

        local config =
            Configs[selectedConfig]

        if not config then

            Status.Text =
                "STATUS: CONFIG NOT FOUND"

            selectedConfig = nil

            refreshConfigList()

            return
        end

        frames = {}

        for i, rawFrame in
            ipairs(config) do

            local frame =
                normalizeFrame(
                    rawFrame
                )

            if frame then

                frames[i] = {

                    position =
                        frame.position,

                    jump =
                        frame.jump,

                    time =
                        frame.time

                }

            end

        end

        Status.Text =
            "STATUS: LOADED [" ..
            selectedConfig ..
            "] - " ..
            tostring(
                #frames
            ) ..
            " FRAMES"

    end
)

--==================================================--
-- DELETE CONFIG
--==================================================--

CreateButton(
    "DELETE SELECTED CONFIG",
    function()

        if not selectedConfig then

            Status.Text =
                "STATUS: SELECT CONFIG FIRST"

            return
        end

        local name =
            selectedConfig

        Configs[name] = nil

        local deleted =
            deleteConfigFile(name)

        selectedConfig = nil

        refreshConfigList()

        if deleted then
            Status.Text =
                "STATUS: DELETED [" ..
                name ..
                "]"
        else
            Status.Text =
                "STATUS: DELETE FAILED [" ..
                name ..
                "]"
        end

    end
)

--==================================================--
-- REFRESH
--==================================================--

CreateButton(
    "REFRESH CONFIG LIST",
    function()

        loadConfigsFromFile()

        refreshConfigList()

        refreshMergeList()

        Status.Text =
            "STATUS: CONFIG LIST REFRESHED"

    end
)

--==================================================--
-- RECORD BUTTON
--==================================================--

local RecordBtn

RecordBtn =
    CreateButton(
        "RECORD PATH: OFF",
        function(button)

            if playing then

                Status.Text =
                    "STATUS: STOP PLAYBACK FIRST"

                return
            end

            if recording then

                recording = false

                if recordConnection then

                    recordConnection:Disconnect()

                    recordConnection = nil

                end

                if jumpConnection then

                    jumpConnection:Disconnect()

                    jumpConnection = nil

                end

                button.Text =
                    "RECORD PATH: OFF"

                Status.Text =
                    "STATUS: RECORD SAVED (" ..
                    tostring(
                        #frames
                    ) ..
                    " FRAMES)"

                return
            end

            frames = {}

            recording = true

            lastGrounded = true
            lastVerticalVelocity = 0
            jumpCooldown = 0
            jumpQueued = false

            button.Text =
                "RECORD PATH: ON"

            Status.Text =
                "STATUS: RECORDING..."

            local elapsed = 0
            local recordTime = 0

            --========================================--
            -- JUMP EVENT
            --========================================--

            local character,
                humanoid =
                getCharacter()

            if humanoid then

                jumpConnection =
                    humanoid.StateChanged:Connect(
                        function(
                            oldState,
                            newState
                        )

                            if not recording then
                                return
                            end

                            if newState ==
                                Enum.HumanoidStateType.Jumping then

                                local _, _, currentRoot =
                                    getCharacter()

                                if currentRoot then

                                    -- Simpan event jump langsung
                                    -- pada saat StateChanged terjadi.
                                    table.insert(
                                        frames,
                                        {
                                            position =
                                                currentRoot.Position,

                                            jump = true,

                                            time =
                                                recordTime
                                        }
                                    )

                                end

                            end

                        end
                    )

            end

            --========================================--
            -- HEARTBEAT
            --========================================--

            recordConnection =
                RunService.Heartbeat:Connect(
                    function(dt)

                        if not recording then
                            return
                        end

                        recordTime += dt
                        elapsed += dt

                        local character,
                            humanoid,
                            root =
                            getCharacter()

                        if not character
                            or not humanoid
                            or not root then

                            return
                        end

                        --================================--
                        -- JUMP DETECTION
                        --================================--

                        -- Jump utama direkam langsung dari
                        -- Humanoid.StateChanged. Di sini kita
                        -- hanya update status fisik karakter.

                        local grounded =
                            humanoid.FloorMaterial
                            ~= Enum.Material.Air

                        local velocityY =
                            root.AssemblyLinearVelocity.Y

                        lastGrounded =
                            grounded

                        lastVerticalVelocity =
                            velocityY

                        --================================--
                        -- RECORD
                        --================================--

                        if elapsed >= RECORD_RATE then

                            elapsed = 0

                            table.insert(
                                frames,
                                {

                                    position =
                                        root.Position,

                                    jump =
                                        false,

                                    time =
                                        recordTime

                                }
                            )

                        end

                    end
                )

        end
    )

--==================================================--
-- STOP RECORD
--==================================================--

CreateButton(
    "STOP RECORD",
    function()

        if not recording then

            Status.Text =
                "STATUS: NOT RECORDING"

            return
        end

        recording = false

        if recordConnection then

            recordConnection:Disconnect()

            recordConnection = nil

        end

        if jumpConnection then

            jumpConnection:Disconnect()

            jumpConnection = nil

        end

        RecordBtn.Text =
            "RECORD PATH: OFF"

        Status.Text =
            "STATUS: SAVED " ..
            tostring(
                #frames
            ) ..
            " FRAMES"

    end
)

--==================================================--
-- STOP MOVEMENT
--==================================================--

local function stopMovement()

    local _,
        humanoid =
        getCharacter()

    if humanoid then

        humanoid:Move(
            Vector3.zero,
            false
        )

        humanoid.AutoRotate =
            true

    end

end

--==================================================--
-- FIND FRAME BY TIME
--==================================================--

local function getFrameAtTime(
    playbackTime,
    currentIndex
)

    local total =
        #frames

    if total == 0 then
        return nil, currentIndex
    end

    local index =
        currentIndex

    local skipped =
        0

    while index < total
        and frames[index + 1]
        and frames[index + 1].time
            <= playbackTime + TIME_LOOKAHEAD do

        index += 1

        skipped += 1

        if skipped >= MAX_FRAME_SKIP then
            break
        end

    end

    local current =
        frames[index]

    local nextFrame =
        frames[
            math.min(
                index + 1,
                total
            )
        ]

    return current,
        index,
        nextFrame

end

--==================================================--
-- PLAY PATH
--==================================================--

local function playPath()

    if #frames < 2 then

        Status.Text =
            "STATUS: LOAD / RECORD PATH FIRST"

        return
    end

    if playing then
        return
    end

    playing = true

    playToken += 1

    local currentToken =
        playToken

    Status.Text =
        "STATUS: PLAYING..."

    local _,
        humanoid,
        root =
        getCharacter()

    if not humanoid
        or not root then

        playing = false

        return
    end

    humanoid.AutoRotate =
        true

    -- Pastikan waktu dimulai dari 0.
    local firstTime =
        frames[1].time or 0

    local playbackTime = 0

    local currentIndex = 1

    local lastJumpTime = -999

    local previousFrameTime =
        frames[1].time or 0

    --==============================================--
    -- PLAYBACK LOOP
    --==============================================--

    playConnection =
        RunService.RenderStepped:Connect(
            function(dt)

                if not playing
                    or currentToken ~= playToken then

                    if playConnection then

                        playConnection:Disconnect()

                        playConnection = nil

                    end

                    stopMovement()

                    return

                end

                local character,
                    currentHumanoid,
                    currentRoot =
                    getCharacter()

                if not character
                    or not currentHumanoid
                    or not currentRoot then

                    playing = false

                    if playConnection then

                        playConnection:Disconnect()

                        playConnection = nil

                    end

                    return

                end

                --====================================--
                -- REAL TIME
                --====================================--

                playbackTime += dt

                --====================================--
                -- END
                --====================================--

                local lastFrame =
                    frames[#frames]

                local lastTime =
                    lastFrame.time or 0

                if playbackTime >= lastTime then

                    -- Jalankan posisi terakhir sebentar
                    -- lalu selesai.

                    local finalPosition =
                        lastFrame.position

                    local currentPosition =
                        currentRoot.Position

                    local difference =
                        Vector3.new(
                            finalPosition.X,
                            currentPosition.Y,
                            finalPosition.Z
                        )
                        -
                        currentPosition

                    if difference.Magnitude
                        > WAYPOINT_DISTANCE then

                        currentHumanoid:Move(
                            difference.Unit,
                            false
                        )

                    else

                        currentHumanoid:Move(
                            Vector3.zero,
                            false
                        )

                        playing = false

                        if playConnection then

                            playConnection:Disconnect()

                            playConnection = nil

                        end

                        stopMovement()

                        Status.Text =
                            "STATUS: PATH COMPLETE"

                        return

                    end

                end

                --====================================--
                -- FRAME
                --====================================--

                local frame,
                    index,
                    nextFrame =
                    getFrameAtTime(
                        playbackTime +
                        firstTime,
                        currentIndex
                    )

                if not frame then
                    return
                end

                currentIndex =
                    index

                --====================================--
                -- JUMP EVENT
                --====================================--

                if frame.jump then

                    local now =
                        os.clock()

                    if now -
                        lastJumpTime
                        > 0.12 then

                        currentHumanoid.Jump = true

                        pcall(function()
                            currentHumanoid:ChangeState(
                                Enum.HumanoidStateType.Jumping
                            )
                        end)

                        lastJumpTime =
                            now

                    end

                end

                --====================================--
                -- TARGET POSITION
                --====================================--

                local target =
                    frame.position

                local targetPosition =
                    Vector3.new(
                        target.X,
                        currentRoot.Position.Y,
                        target.Z
                    )

                --====================================--
                -- INTERPOLATION
                --====================================--

                if nextFrame
                    and nextFrame ~= frame then

                    local t1 =
                        frame.time or 0

                    local t2 =
                        nextFrame.time or
                        t1 + RECORD_RATE

                    local duration =
                        math.max(
                            t2 - t1,
                            0.001
                        )

                    local localTime =
                        (
                            playbackTime +
                            firstTime -
                            t1
                        )

                    local alpha =
                        math.clamp(
                            localTime /
                            duration,
                            0,
                            1
                        )

                    local interpolated =
                        frame.position:Lerp(
                            nextFrame.position,
                            alpha
                        )

                    targetPosition =
                        Vector3.new(
                            interpolated.X,
                            currentRoot.Position.Y,
                            interpolated.Z
                        )

                end

                --====================================--
                -- MOVEMENT
                --====================================--

                local difference =
                    targetPosition -
                    currentRoot.Position

                local distance =
                    difference.Magnitude

                if distance > 0.05 then

                    local direction =
                        difference.Unit

                    currentHumanoid:Move(
                        direction,
                        false
                    )

                    local lookPosition =
                        currentRoot.Position +
                        direction

                    currentRoot.CFrame =
                        CFrame.lookAt(
                            currentRoot.Position,
                            lookPosition
                        )

                else

                    -- Jangan langsung lompat ke frame jauh.
                    -- Tetap Move zero agar frame diam ikut
                    -- direkam dan dimainkan.

                    currentHumanoid:Move(
                        Vector3.zero,
                        false
                    )

                end

                previousFrameTime =
                    frame.time or
                    previousFrameTime

            end
        )

end

--==================================================--
-- PLAY BUTTON
--==================================================--

CreateButton(
    "PLAY PATH",
    function()

        if recording then

            Status.Text =
                "STATUS: STOP RECORD FIRST"

            return
        end

        if playing then
            return
        end

        task.spawn(
            playPath
        )

    end
)

--==================================================--
-- LOOP
--==================================================--

local LoopBtn

LoopBtn =
    CreateButton(
        "LOOP: OFF",
        function(button)

            looping =
                not looping

            if looping then

                button.Text =
                    "LOOP: ON"

                button.BorderColor3 =
                    Color3.fromRGB(
                        150,
                        150,
                        150
                    )

                Status.Text =
                    "STATUS: LOOP ENABLED"

                task.spawn(
                    function()

                        while looping do

                            if #frames < 2 then

                                Status.Text =
                                    "STATUS: NO PATH"

                                looping =
                                    false

                                button.Text =
                                    "LOOP: OFF"

                                break
                            end

                            playPath()

                            while playing
                                and looping do

                                task.wait()

                            end

                            if not looping then
                                break
                            end

                            Status.Text =
                                "STATUS: RESETTING..."

                            local success =
                                resetToBasecamp()

                            if not success then

                                Status.Text =
                                    "STATUS: BASECAMP ERROR"

                                looping =
                                    false

                                button.Text =
                                    "LOOP: OFF"

                                break

                            end

                            task.wait(
                                RESPAWN_WAIT
                            )

                        end

                    end
                )

            else

                button.Text =
                    "LOOP: OFF"

                button.BorderColor3 =
                    Color3.fromRGB(
                        255,
                        255,
                        255
                    )

                Status.Text =
                    "STATUS: LOOP DISABLED"

            end

        end
    )

--==================================================--
-- STOP PLAYBACK
--==================================================--

CreateButton(
    "STOP PLAYBACK",
    function()

        playing = false
        looping = false

        playToken += 1

        if playConnection then

            playConnection:Disconnect()

            playConnection = nil

        end

        stopMovement()

        LoopBtn.Text =
            "LOOP: OFF"

        LoopBtn.BorderColor3 =
            Color3.fromRGB(
                255,
                255,
                255
            )

        Status.Text =
            "STATUS: STOPPED"

    end
)

--==================================================--
-- INFO
--==================================================--

local Info =
    Instance.new("TextLabel")

Info.Parent =
    Container

Info.BackgroundTransparency = 1

Info.Size =
    UDim2.new(
        0.9,
        0,
        0,
        105
    )

Info.Font =
    Enum.Font.Gotham

Info.Text =
    "RECORD: jalan + diam + jump.\n" ..
    "RECORD RATE: 60 Hz.\n" ..
    "PLAYBACK: mengikuti timestamp rekaman.\n" ..
    "SAVE: simpan CP sebagai config.\n" ..
    "ADD SELECTED: masukkan CP ke Merge Queue.\n" ..
    "Klik item queue untuk menghapusnya.\n" ..
    "MERGE: gabungkan sesuai urutan queue."

Info.TextColor3 =
    Color3.fromRGB(
        170,
        170,
        170
    )

Info.TextSize = 11

Info.TextWrapped = true

--==================================================--
-- FILE STATUS
--==================================================--

local FileStatus =
    Instance.new("TextLabel")

FileStatus.Parent =
    Container

FileStatus.BackgroundTransparency = 1

FileStatus.Size =
    UDim2.new(
        0.9,
        0,
        0,
        25
    )

FileStatus.Font =
    Enum.Font.Gotham

if FileAPIAvailable then

    FileStatus.Text =
        "FILE SAVE: ENABLED"

else

    FileStatus.Text =
        "FILE SAVE: NOT AVAILABLE"

end

FileStatus.TextColor3 =
    Color3.fromRGB(
        150,
        150,
        150
    )

FileStatus.TextSize = 10

--==================================================--
-- MINIMIZE
--==================================================--

local minimized = false

MinBtn.MouseButton1Click:Connect(
    function()

        minimized =
            not minimized

        if minimized then

            TweenService:Create(
                MainFrame,
                TweenInfo.new(0.35),
                {
                    Size =
                        UDim2.new(
                            0,
                            400,
                            0,
                            40
                        )
                }
            ):Play()

            Container.Visible =
                false

        else

            TweenService:Create(
                MainFrame,
                TweenInfo.new(0.35),
                {
                    Size =
                        UDim2.new(
                            0,
                            400,
                            0,
                            620
                        )
                }
            ):Play()

            Container.Visible =
                true

        end

    end
)

--==================================================--
-- CLOSE
--==================================================--

CloseBtn.MouseButton1Click:Connect(
    function()

        recording = false
        playing = false
        looping = false

        playToken += 1

        if recordConnection then

            recordConnection:Disconnect()

            recordConnection = nil

        end

        if jumpConnection then

            jumpConnection:Disconnect()

            jumpConnection = nil

        end

        if playConnection then

            playConnection:Disconnect()

            playConnection = nil

        end

        stopMovement()

        saveConfigsToFile()

        local tween =
            TweenService:Create(
                MainFrame,
                TweenInfo.new(0.35),
                {
                    Size =
                        UDim2.new(
                            0,
                            400,
                            0,
                            0
                        )
                }
            )

        tween:Play()

        tween.Completed:Connect(
            function()

                ScreenGui:Destroy()

            end
        )

    end
)

--==================================================--
-- INITIALIZE
--==================================================--

refreshConfigList()

refreshMergeList()

--==================================================--
-- OPEN
--==================================================--

TweenService:Create(
    MainFrame,
    TweenInfo.new(
        0.55,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    ),
    {
        Size =
            UDim2.new(
                0,
                400,
                0,
                620
            )
    }
):Play()

--==================================================--
-- CONSOLE
--==================================================--

print(
    "===================================="
)

print(
    "BALJITOT CP RECORDER LOADED"
)

print(
    "REAL TIME RECORDER: ON"
)

print(
    "RECORD RATE:",
    RECORD_RATE
)

print(
    "WAYPOINT DISTANCE:",
    WAYPOINT_DISTANCE
)

print(
    "FILE API:",
    FileAPIAvailable
)

print(
    "MERGE QUEUE:",
    #MergeQueue
)

print(
    "===================================="
)
