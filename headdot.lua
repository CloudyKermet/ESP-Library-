return function()
    --[[
        Dynamic Head Circle ESP
        - Draws circles around player heads
        - Radius scales to match actual head size on screen
        - Distance-aware with minimum size fallback
        - Team-colored circles
        - Team-check to skip teammates
    ]]--

    -- ============================================================
    -- SECTION 1: SERVICES & DEPENDENCIES
    -- ============================================================

    local Players   = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera    = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer


    -- ============================================================
    -- SECTION 2: GLOBAL CONFIGURATION
    -- ============================================================
    -- Toggle each feature on/off at runtime via _G.HeadCircle table.
    -- All default to true.
    -- ============================================================

    _G.HeadCircle = _G.HeadCircle or {}
    _G.HeadCircle.Enabled         = true   -- master toggle
    _G.HeadCircle.TeamColored     = true   -- circles match the target player's team color
    _G.HeadCircle.TeamCheck       = true   -- skip players on the same team as you


    -- ============================================================
    -- SECTION 3: LOCAL OVERRIDE SETTINGS
    -- ============================================================
    -- These override _G values if you want hardcoded defaults.
    -- All set to nil so _G acts as the source of truth.
    -- ============================================================

    local Settings = {
        Color       = Color3.fromRGB(255, 50, 50),  -- fallback if TeamColored is off
        Thickness   = 2,
        Transparency = 1,
        Filled      = false,
        OffsetY     = -2,
    }


    -- ============================================================
    -- SECTION 4: STATE
    -- ============================================================

    local HeadCircles = {}


    -- ============================================================
    -- SECTION 5: DRAWING UTILITY
    -- ============================================================

    local function createCircle(color)
        local circle = Drawing.new("Circle")
        circle.Color       = color or Settings.Color
        circle.Thickness   = Settings.Thickness
        circle.Transparency = Settings.Transparency
        circle.Filled      = Settings.Filled
        circle.NumSides    = 64
        circle.Visible     = false
        return circle
    end


    -- ============================================================
    -- SECTION 6: TEAM HELPERS
    -- ============================================================

    local function getPlayerColor(player)
        -- Returns a Color3 from the player's TeamColor, or fallback if neutral/nil
        local teamColor = player.TeamColor
        if teamColor then
            return teamColor.Color
        end
        return Settings.Color
    end

    local function isSameTeam(playerA, playerB)
        -- True if both players are on the same team (non-neutral)
        if playerA.Neutral or playerB.Neutral then return false end
        if not playerA.Team or not playerB.Team then return false end
        return playerA.Team == playerB.Team
    end


    -- ============================================================
    -- SECTION 7: ESP UPDATE LOGIC
    -- ============================================================

    local function updateHeadESP(player)
        -- Skip local player
        if player == LocalPlayer then return end

        -- Team-check: skip if on the same team
        if _G.HeadCircle.TeamCheck and isSameTeam(player, LocalPlayer) then
            if HeadCircles[player] then
                HeadCircles[player].Visible = false
            end
            return
        end

        -- Check character exists
        local character = player.Character
        if not character then
            if HeadCircles[player] then
                HeadCircles[player].Visible = false
            end
            return
        end

        -- Check head + alive
        local head     = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChild("Humanoid")

        if not head or not humanoid or humanoid.Health <= 0 then
            if HeadCircles[player] then
                HeadCircles[player].Visible = false
            end
            return
        end

        -- Pick the color for this circle
        local circleColor
        if _G.HeadCircle.TeamColored then
            circleColor = getPlayerColor(player)
        else
            circleColor = Settings.Color
        end

        -- Lazy-create circle for this player
        if not HeadCircles[player] then
            HeadCircles[player] = createCircle(circleColor)
        else
            -- Update color each frame in case it changed
            HeadCircles[player].Color = circleColor
        end

        local circle = HeadCircles[player]

        -- Compute distance for potential scaling
        local headPos    = head.Position
        local cameraPos  = Camera.CFrame.Position
        local distance   = (headPos - cameraPos).Magnitude

        -- Project head center to screen
        local viewportPoint, onScreen = Camera:WorldToViewportPoint(headPos)
        if not onScreen or viewportPoint.Z < 0 then
            circle.Visible = false
            return
        end

        -- Dynamic radius — project an edge point to match head size
        local headRadius   = 0.7
        local edgePoint    = headPos + Camera.CFrame.RightVector * headRadius
        local edgeViewport = Camera:WorldToViewportPoint(edgePoint)

        local screenRadius = math.abs(viewportPoint.X - edgeViewport.X)
        screenRadius = math.clamp(screenRadius, 4, 30)

        -- Apply
        circle.Position = Vector2.new(viewportPoint.X, viewportPoint.Y + Settings.OffsetY)
        circle.Radius   = screenRadius
        circle.Visible  = true
    end


    -- ============================================================
    -- SECTION 8: MAIN LOOP
    -- ============================================================

    RunService.RenderStepped:Connect(function()
        if not _G.HeadCircle.Enabled then return end

        for _, player in ipairs(Players:GetPlayers()) do
            updateHeadESP(player)
        end
    end)


    -- ============================================================
    -- SECTION 9: CLEANUP
    -- ============================================================

    Players.PlayerRemoving:Connect(function(plr)
        if HeadCircles[plr] then
            HeadCircles[plr]:Remove()
            HeadCircles[plr] = nil
        end
    end)


    -- ============================================================
    -- SECTION 10: CONFIRMATION
    -- ============================================================
  
end
