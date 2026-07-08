return function()
    --[[
        Advanced Skeleton ESP (Better Pose Tracking)
        - Draws bone connections between body parts
        - Supports R15 and R6 rigs
        - Team-colored bones
        - Team-check to skip teammates
    ]]--

    -- ============================================================
    -- SECTION 1: SERVICES & DEPENDENCIES
    -- ============================================================

    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera     = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer


    -- ============================================================
    -- SECTION 2: GLOBAL CONFIGURATION
    -- ============================================================
    -- Toggle each feature on/off at runtime via _G.Skeleton table.
    -- All default to true.
    -- ============================================================

    _G.Skeleton = _G.Skeleton or {}
    _G.Skeleton.Enabled         = true   -- master toggle
    _G.Skeleton.TeamColored     = true   -- bones match the target player's team color
    _G.Skeleton.TeamCheck       = true   -- skip players on the same team as you


    -- ============================================================
    -- SECTION 3: LOCAL OVERRIDE SETTINGS
    -- ============================================================

    local Settings = {
        Color       = Color3.fromRGB(0, 255, 100),  -- fallback if TeamColored is off
        Thickness   = 2,
        Transparency = 1,
    }


    -- ============================================================
    -- SECTION 4: STATE
    -- ============================================================

    local SkeletonCache = {}


    -- ============================================================
    -- SECTION 5: DRAWING UTILITY
    -- ============================================================

    local function createSkeleton(color)
        local lines = {}
        for i = 1, 18 do
            local line = Drawing.new("Line")
            line.Color       = color or Settings.Color
            line.Thickness   = Settings.Thickness
            line.Transparency = Settings.Transparency
            line.Visible     = false
            table.insert(lines, line)
        end
        return lines
    end


    -- ============================================================
    -- SECTION 6: TEAM HELPERS
    -- ============================================================

    local function getPlayerColor(player)
        local teamColor = player.TeamColor
        if teamColor then
            return teamColor.Color
        end
        return Settings.Color
    end

    local function isSameTeam(playerA, playerB)
        if playerA.Neutral or playerB.Neutral then return false end
        if not playerA.Team or not playerB.Team then return false end
        return playerA.Team == playerB.Team
    end


    -- ============================================================
    -- SECTION 7: ESP UPDATE LOGIC
    -- ============================================================

    local function updateSkeleton(player)
        -- Skip local player
        if player == LocalPlayer then return end

        -- Team-check: skip if on the same team
        if _G.Skeleton.TeamCheck and isSameTeam(player, LocalPlayer) then
            if SkeletonCache[player] then
                for _, line in ipairs(SkeletonCache[player]) do
                    line.Visible = false
                end
            end
            return
        end

        -- Check character exists
        local character = player.Character
        if not character then
            if SkeletonCache[player] then
                for _, line in ipairs(SkeletonCache[player]) do
                    line.Visible = false
                end
            end
            return
        end

        -- Check alive
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            if SkeletonCache[player] then
                for _, line in ipairs(SkeletonCache[player]) do
                    line.Visible = false
                end
            end
            return
        end

        -- Pick the color for this skeleton
        local boneColor
        if _G.Skeleton.TeamColored then
            boneColor = getPlayerColor(player)
        else
            boneColor = Settings.Color
        end

        -- Lazy-create skeleton for this player
        if not SkeletonCache[player] then
            SkeletonCache[player] = createSkeleton(boneColor)
        else
            -- Update color each frame in case it changed
            for _, line in ipairs(SkeletonCache[player]) do
                line.Color = boneColor
            end
        end

        local lines = SkeletonCache[player]
        local index = 1

        local function connect(p1, p2)
            if not p1 or not p2 then return end
            local v1 = Camera:WorldToViewportPoint(p1.Position)
            local v2 = Camera:WorldToViewportPoint(p2.Position)

            if v1.Z < 0 or v2.Z < 0 then return end

            local line = lines[index]
            line.From    = Vector2.new(v1.X, v1.Y)
            line.To      = Vector2.new(v2.X, v2.Y)
            line.Visible = true
            index = index + 1
        end

        -- Get all relevant parts (supports R15 and R6)
        local head   = character:FindFirstChild("Head")
        local utorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        local ltorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
        local hrp    = character:FindFirstChild("HumanoidRootPart")

        -- Arms (full chain for better pose)
        local lua   = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
        local lla   = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm")
        local lhand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")

        local rua   = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
        local rla   = character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm")
        local rhand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")

        -- Legs (full chain)
        local lul   = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg")
        local lll   = character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("Left Leg")
        local lfoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")

        local rul   = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
        local rll   = character:FindFirstChild("RightLowerLeg") or character:FindFirstChild("Right Leg")
        local rfoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")

        -- Build Skeleton
        connect(head, utorso)          -- Head to Upper Torso
        connect(utorso, ltorso)        -- Upper to Lower Torso
        connect(utorso, hrp)           -- Torso to Root

        -- Left Arm
        connect(utorso, lua)
        connect(lua, lla)
        connect(lla, lhand)

        -- Right Arm
        connect(utorso, rua)
        connect(rua, rla)
        connect(rla, rhand)

        -- Left Leg
        connect(ltorso or hrp, lul)
        connect(lul, lll)
        connect(lll, lfoot)

        -- Right Leg
        connect(ltorso or hrp, rul)
        connect(rul, rll)
        connect(rll, rfoot)

        -- Hide unused lines
        for i = index, #lines do
            lines[i].Visible = false
        end
    end


    -- ============================================================
    -- SECTION 8: MAIN LOOP
    -- ============================================================

    RunService.RenderStepped:Connect(function()
        if not _G.Skeleton.Enabled then return end

        for _, player in ipairs(Players:GetPlayers()) do
            updateSkeleton(player)
        end
    end)


    -- ============================================================
    -- SECTION 9: CLEANUP
    -- ============================================================

    Players.PlayerRemoving:Connect(function(plr)
        if SkeletonCache[plr] then
            for _, line in ipairs(SkeletonCache[plr]) do
                line:Remove()
            end
            SkeletonCache[plr] = nil
        end
    end)


    -- ============================================================
    -- SECTION 10: CONFIRMATION
    -- ============================================================
end
