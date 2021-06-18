function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "June 18, 2021"
    finaleplugin.CategoryTags = "Staff"
    return "Load SMuFL Engraving Defaults", "Load SMuFL Engraving Defaults", "Loads engraving defaults for the current SMuFL Default Music Font."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local luna = require("lunajson.lunajson")

local smufl_json_path = "/Library/Application Support/SMuFL/Fonts/"
if finenv.UI():IsOnWindows() then
    local common_programs_path = os.getenv("COMMONPROGRAMFILES") 
    smufl_json_path = common_programs_path .. "/SMuFL/Fonts/"
end

function smufl_load_engraving_defaults()
    local font_info = finale.FCFontInfo()
    font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    local font_json_path = smufl_json_path .. font_info.Name .. "/" .. font_info.Name .. ".json"
    local font_json_file = io.open(font_json_path, "r")
    if nil == font_json_file then
        finenv.UI():AlertError("The current Default Music Font is not a SMuFL font, or else the json file with its engraving defaults is not installed.", "Default Music Font is not SMuFL")
        return
    end
    local json = font_json_file:read("*all")
    io.close(font_json_file)
    local font_info = luna.decode(json)
    local defaults = ""
    for k, v in pairs(font_info.engravingDefaults) do
        defaults = defaults .. "\n" .. k .. ":" .. v
    end
    finenv.UI():AlertInfo(defaults, "info")
end

smufl_load_engraving_defaults()
