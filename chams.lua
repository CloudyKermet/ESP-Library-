return function()
    --[[
        Simple Always-On Chams (50% Transparent)
        - Highlights player models through walls
        - Team-colored fill
        - Team-check to skip teammates
    ]]--

    -- ============================================================
    -- SECTION 1: SERVICES & DEPENDENCIES
    -- ============================================================

    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer


    -- ============================================================
    -- SECTION 2: GLOBAL CONFIGURATION
    -- ============================================================
    -- Toggle each feature on/off at runtime via _G.Chams table.
    -- ============================================================

    _G.Chams = _G.Chams or {}
    _G.Chams.Enabled         = true   -- master toggle
    _G.Chams.TeamColored     = true   -- chams match the target player's team color
    _G.Chams.TeamCheck       = true   -- skip players on the same team as you


    -- ============================================================
    -- SECTION 3: LOCAL OVERRIDE SETTINGS
    -- ============================================================

    local Settings = {
        Color        = Color3.fromRGB(0, 255, 150),  -- fallback if TeamColored is off
        Transparency = 0.5,
    }


    -- ============================================================
    -- SECTION 4: STATE
    -- ============================================================

    local Chams = {}


    -- ============================================================
    -- SECTION 5: TEAM HELPERS
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
    -- SECTION 6: CHAM UTILITY
    -- ============================================================

    local function createCham(character, color)
        if Chams[character] then
            -- Update existing cham color
            Chams[character].FillColor = color
            return
        end

        local highlight = Instance.new("Highlight")
        highlight.Name                = "SimpleChams"
        highlight.Adornee             = character
        highlight.FillColor           = color
        highlight.FillTransparency    = Settings.Transparency
        highlight.OutlineTransparency = 1
        highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent              = character

        Chams[character] = highlight
    end

    local function removeCham(character)
        if Chams[character] then
            Chams[character]:Destroy()
            Chams[character] = nil
        end
    end


    -- ============================================================
    -- SECTION 7: ESP UPDATE LOGIC
    -- ============================================================

    local function updateChams()
        if not _G.Chams.Enabled then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end

            -- Team-check: skip if on the same team
            if _G.Chams.TeamCheck and isSameTeam(player, LocalPlayer) then
                if player.Character then
                    removeCham(player.Character)
                end
                continue
            end

            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local chamColor
                if _G.Chams.TeamColored then
                    chamColor = getPlayerColor(player)
                else
                    chamColor = Settings.Color
                end

                createCham(character, chamColor)
            end
        end
    end


    -- ============================================================
    -- SECTION 8: MAIN LOOP
    -- ============================================================

    RunService.Heartbeat:Connect(updateChams)


    -- ============================================================
    -- SECTION 9: CLEANUP
    -- ============================================================

    Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            removeCham(player.Character)
        end
    end)

    workspace.DescendantRemoving:Connect(function(desc)
        if desc:IsA("Model") and Chams[desc] then
            removeCham(desc)
        end
    end)


    -- ============================================================
    -- SECTION 10: CONFIRMATION
    -- ============================================================

end
