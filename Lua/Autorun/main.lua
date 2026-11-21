if SERVER then return end

local ok, failed, package = pcall(function() return trygetpackage("OreRadar") end)
if not package then
    print("[OreRadar] Error: package path not found")
    return 
end

local Configs = {
    isEnabled = nil,
}

local ores = {}
local oreColor = Color.Red

local function getValueConfig(key, typeName, configKey)
    local ok, success, config = pcall(function()
        return ConfigService.TryGetConfig(SettingBase[typeName], package, key)
    end)
    
    if ok and success and config then
        Configs[configKey] = config.Value
        pcall(function()
            config.OnValueChanged.add(function(changed)
                local successChanged, current = pcall(function() return changed.Value end)
                if successChanged and current ~= nil then
                    Configs[configKey] = current
                    print(string.format("Config value '%s' successfully changed to %s!", key, tostring(current)))
                end
            end)
        end)
    else
        print("[OreRadar] Error: " .. key .. " (ok=" .. tostring(ok) .. ", success=" .. tostring(success) .. ")")
    end
end

getValueConfig("EnableOreRadar", "Boolean", "isEnabled")

local function getOres()
    for _, item in pairs(Item.ItemList) do
        if not item.Removed and item.HasTag("ore") or item.HasTag("plant") then
            table.insert(ores, item)
            item.ExternalHighlight = true 
            item.HighlightColor = oreColor
        end
    end
end

Hook.Add("roundStart", "OreRadarInit", function(instance, ptable)
    getOres()
end)

Hook.Patch("ClientOreRadarMarker", "Barotrauma.GUI", "Draw", function(instance, ptable)
    if not Game.RoundStarted or not Configs.isEnabled or not Character.Controlled then return end

    local sb = ptable["spriteBatch"]
    local cam = Game.GameScreen.Cam
    local refPos = Character.Controlled.WorldPosition

    if sb == nil or cam == nil then print("Error") return end

    for _, item in pairs(ores) do
        if item and not item.Removed and item.ParentInventory == nil then
            local dist = Vector2.Distance(refPos, item.WorldPosition)
            
            if dist < 6000 then
                local oreIcon = item.Sprite

                GUI.DrawIndicator(
                        sb,
                        item.WorldPosition,
                        cam,
                        150,
                        oreIcon,
                        Color.White,
                        true,
                        0.6
                )
            end
        end
    end
end, Hook.HookMethodType.After)