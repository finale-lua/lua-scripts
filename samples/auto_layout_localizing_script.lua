function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.71
    finaleplugin.ExecuteHttpsCalls = true
end

local localization = require("library.localization")

--
-- this table was copied from "auto_layout.lua" for the purpose of translating it
--
localization.en =
{
    ["Action Button"] = "Action Button",
    ["Choices"] = "Choices",
    ["First Option"] = "First Option",
    ["Fourth Option"] = "Fourth Option",
    ["Left Checkbox Option 1"] = "Left Checkbox Option 1",
    ["Left Checkbox Option 2"] = "Left Checkbox Option 2",
    ["Menu"] = "Menu",
    ["Right Three-State Option"] = "Right Three-State Option",
    ["Second Option"] = "Second Option",
    ["Short "] = "Short ",
    ["Test Autolayout With Localisation"] = "Test Autolayout With Localisation",
    ["Third Option"] = "Third Option",
    ["This is long menu text "] = "This is long menu text ",
    ["This is long text choice "] = "This is long text choice ",
    ["This is longer option text "] = "This is longer option text ",
}

local ldev = require('library.localization_developer')
ldev.translate_localized_table_string(localization.en, "en", "en_GB")