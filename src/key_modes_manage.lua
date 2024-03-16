function plugindef()
    finaleplugin.MinJWLuaVersion = 0.72
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.0"
    finaleplugin.Date = "March 12, 2024"
    finaleplugin.CategoryTags = "Key Signatures"
    finaleplugin.Notes = [[
    ]]
    return "Nonstandard Key Signatures...", "Nonstandard Key Signatures",
           "Manages Nonstandard Key Signatures. Allows view, modify, create, and delete."
end

-- luacheck: ignore 11./global_dialog

local mixin = require("library.mixin")

local key_mode_types =
{
    "Predefined",
    "Linear",
    "Nonlinear",
    "Microtone",
    "Other"
}

local linear_mode_types =
{
    "Ionian",
    "Dorian",
    "Phrygian",
    "Lydian",
    "Mixolydian",
    "Aeolian",
    "Locrian"
}

local note_names =
{
    "C",
    "D",
    "E",
    "F",
    "G",
    "A",
    "B"
}

local alteration_names =
{
    [-2] = "bb",
    [-1] = "b",
    [0] = "",
    [1] = "#",
    [2] = "x"
}

local function calc_key_mode_desc(key_mode)
    -- Use FCKeySignature because it populates defaults if needed.
    local key = key_mode:CreateKeySignature()
    local diatonic_steps = #key:CalcDiatonicStepsMap()
    local chromatic_steps = key:CalcTotalChromaticSteps()
    if chromatic_steps == 0 then chromatic_steps = 12 end
    local function get_type()
        if key_mode:IsPredefined() then
            return 1
        end
        if diatonic_steps ~= 7 then
            return 5
        end
        if chromatic_steps ~= 12 then
            return 4
        end
        return key_mode:IsLinear() and 2 or 3
    end
    local tonal_center = key_mode.TonalCenters[0] or 0
    local mode_type = key_mode_types[get_type()]
    if key:IsMajor() then
        return mode_type .. " Major"
    elseif key:IsMinor() then
        return mode_type .. " Minor"
    end
    local retval = mode_type
    if chromatic_steps ~= 12 then
        retval = retval .. " " .. chromatic_steps .. "-EDO"
    end
    if mode_type == "Other" then
        retval = retval .. "(" .. diatonic_steps .. " Steps)"
    elseif key_mode:IsLinear() and (mode_type == "Linear" or tonal_center ~= 0) then
        retval = retval .. " " .. linear_mode_types[(tonal_center % 7) + 1]
    elseif key_mode:IsNonLinear() then
        local notes = " " .. note_names[(tonal_center % 7) + 1] .. ":"
        local acci_amounts = key_mode.AccidentalAmounts
        local acci_order = key_mode.AccidentalOrder
        for x = 1, 7 do
            if not acci_amounts[x] or acci_amounts[x] == 0 then
                break
            end
            if not acci_order[x] then
                break
            end
            notes = notes .. " ".. note_names[(acci_order[x] % 7) + 1] .. tostring(alteration_names[acci_amounts[x]])
        end
        retval = retval .. notes
    end
    return retval
end

local function create_dialog_box()
    local dlg = mixin.FCXCustomLuaWindow()
        :SetTitle(plugindef():gsub("%.%.%.", ""))
    local popup = dlg:CreatePopup(0, 0, "keymodes")
        :DoAutoResizeWidth()
    local defs = finale.FCCustomKeyModeDefs()
    defs:LoadAll()
    for def in each(defs) do
        popup:AddString(calc_key_mode_desc(def))
    end
    dlg:CreateOkButton()
    dlg:CreateCancelButton()
    return dlg
end

local function key_modes_manage()
    global_dialog = global_dialog or create_dialog_box()
    global_dialog:ExecuteModal()
end

key_modes_manage()
