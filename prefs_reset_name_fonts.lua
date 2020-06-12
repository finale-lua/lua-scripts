function plugindef()
   -- This function and the 'finaleplugin' namespace
   -- are both reserved for the plug-in definition.
   finaleplugin.Author = "Robert Patterson"
   finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
   finaleplugin.Version = "1.0"
   finaleplugin.Date = "June 9, 2020"
   finaleplugin.CategoryTags = "Staff"
   finaleplugin.ParameterTypes = [[
Boolean
Boolean
]]
   finaleplugin.ParameterInitValues = [[
false
false
]]
   finaleplugin.ParameterDescriptions = [[
is for group name prefs
is for abbreviated name prefs
]]
   return "Reset Name Fonts", "Reset Name Fonts", "Reset group or staff name fonts to default."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local library = require("library")

function prefs_reset_name_fonts(is_for_group, is_for_abbreviated_names)
    local prefs_number = 0
    if is_for_group then
        if is_for_abbreviated_names then
            prefs_number = finale.FONTPREF_ABRVGROUPNAME
        else
            prefs_number = finale.FONTPREF_GROUPNAME
        end
    else
        if is_for_abbreviated_names then
            prefs_number = finale.FONTPREF_ABRVSTAFFNAME
        else
            prefs_number = finale.FONTPREF_STAFFNAME
        end
    end
    local font_info = finale.FCFontInfo()
    font_info:LoadFontPrefs(prefs_number)
    local items = nil
    if is_for_group then
        items = finale.FCGroups()
    else
        items = finale.FCStaves()
    end
    items:LoadAll()
    for item in each(items) do
        local text_block_id = 0
        if is_for_abbreviated_names then
            if 0 ~= item:GetAbbreviatedNameID() then
                text_block_id = item:GetAbbreviatedNameID()
            end
        else
            if 0 ~= item:GetFullNameID() then
                text_block_id = item:GetFullNameID()
            end
        end
        if (0 ~= text_block_id) then
            text_block = finale.FCTextBlock()
            if text_block:Load(text_block_id) then
                library.change_text_block_font (text_block, font_info)
                text_block:Save()
            end
        end
    end
end
    
local is_for_group = false
local is_for_abbreviated_names = true
local parameters = {...}
if parameters[1] then is_for_group = parameters[1] end
if parameters[2] then is_for_abbreviated_names = parameters[2] end

prefs_reset_name_fonts(is_for_group, is_for_abbreviated_names)
