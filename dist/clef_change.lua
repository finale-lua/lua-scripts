package.preload["library.client"] = package.preload["library.client"] or function()

    local client = {}
    local function to_human_string(feature)
        return string.gsub(feature, "_", " ")
    end
    local function requires_later_plugin_version(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. "which is only available in a later version of RGP Lua. Please update RGP Lua instead to use this script."
        end
        return "This script requires a later version of RGP Lua. Please update RGP Lua instead to use this script."
    end
    local function requires_rgp_lua(feature)
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which is not available on JW Lua. Please use RGP Lua instead to use this script."
        end
        return "This script requires RGP Lua, the successor of JW Lua. Please use RGP Lua instead to use this script."
    end
    local function requires_plugin_version(version, feature)
        if tonumber(version) <= 0.54 then
            if feature then
                return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua or JW Lua version " .. version ..
                           " or later. Please update your plugin to use this script."
            end
            return "This script requires RGP Lua or JW Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        if feature then
            return "This script uses " .. to_human_string(feature) .. " which requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
        end
        return "This script requires RGP Lua version " .. version .. " or later. Please update your plugin to use this script."
    end
    local function requires_finale_version(version, feature)
        return "This script uses " .. to_human_string(feature) .. ", which is only available on Finale " .. version .. " or later"
    end

    function client.get_raw_finale_version(major, minor, build)
        local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
        if build then
            retval = bit32.bor(retval, math.floor(build))
        end
        return retval
    end

    function client.get_lua_plugin_version()
        local num_string = tostring(finenv.MajorVersion) .. "." .. tostring(finenv.MinorVersion)
        return tonumber(num_string)
    end
    local features = {
        clef_change = {
            test = client.get_lua_plugin_version() >= 0.60,
            error = requires_plugin_version("0.58", "a clef change"),
        },
        ["FCKeySignature::CalcTotalChromaticSteps"] = {
            test = finenv.IsRGPLua and finale.FCKeySignature.__class.CalcTotalChromaticSteps,
            error = requires_later_plugin_version("a custom key signature"),
        },
        ["FCCategory::SaveWithNewType"] = {
            test = client.get_lua_plugin_version() >= 0.58,
            error = requires_plugin_version("0.58"),
        },
        ["finenv.QueryInvokedModifierKeys"] = {
            test = finenv.IsRGPLua and finenv.QueryInvokedModifierKeys,
            error = requires_later_plugin_version(),
        },
        ["FCCustomLuaWindow::ShowModeless"] = {
            test = finenv.IsRGPLua,
            error = requires_rgp_lua("a modeless dialog")
        },
        ["finenv.RetainLuaState"] = {
            test = finenv.IsRGPLua and finenv.RetainLuaState ~= nil,
            error = requires_later_plugin_version(),
        },
        smufl = {
            test = finenv.RawFinaleVersion >= client.get_raw_finale_version(27, 1),
            error = requires_finale_version("27.1", "a SMUFL font"),
        },
    }

    function client.supports(feature)
        if features[feature].test == nil then
            error("a test does not exist for feature " .. feature, 2)
        end
        return features[feature].test
    end

    function client.assert_supports(feature)
        local error_level = finenv.DebugEnabled and 2 or 0
        if not client.supports(feature) then
            if features[feature].error then
                error(features[feature].error, error_level)
            end

            error("Your Finale version does not support " .. to_human_string(feature), error_level)
        end
        return true
    end
    return client
end
package.preload["library.clef"] = package.preload["library.clef"] or function()

    local clef = {}
    local client = require("library.client")
    local clef_map = {
        treble = 0,
        alto = 1,
        tenor = 2,
        bass = 3,
        perc_old = 4,
        treble_8ba = 5,
        treble_8vb = 5,
        tenor_voice = 5,
        bass_8ba = 6,
        bass_8vb = 6,
        baritone = 7,
        baritone_f = 7,
        french_violin_clef = 8,
        baritone_c = 9,
        mezzo_soprano = 10,
        soprano = 11,
        percussion = 12,
        perc_new = 12,
        treble_8va = 13,
        bass_8va = 14,
        blank = 15,
        tab_sans = 16,
        tab_serif = 17
    }

    function clef.get_cell_clef(measure, staff_number)
        local cell_clef = -1
        local cell = finale.FCCell(measure, staff_number)
        local cell_frame_hold = finale.FCCellFrameHold()
        cell_frame_hold:ConnectCell(cell)
        if cell_frame_hold:Load() then
            if cell_frame_hold.IsClefList then
                cell_clef = cell_frame_hold:CreateFirstCellClefChange().ClefIndex
            else
                cell_clef = cell_frame_hold.ClefIndex
            end
        end
        return cell_clef
    end

    function clef.get_default_clef(first_measure, last_measure, staff_number)
        local staff = finale.FCStaff()
        local cell_clef = clef.get_cell_clef(first_measure - 1, staff_number)
        if cell_clef < 0 then
            cell_clef = clef.get_cell_clef(last_measure + 1, staff_number)
            if cell_clef < 0 then
                cell_clef = staff:Load(staff_number) and staff.DefaultClef or 0
            end
        end
        return cell_clef
    end

    function clef.set_measure_clef(first_measure, last_measure, staff_number, clef_index)
        client.assert_supports("clef_change")
        for measure = first_measure, last_measure do
            local cell = finale.FCCell(measure, staff_number)
            local cell_frame_hold = finale.FCCellFrameHold()
            local clef_change = cell_frame_hold:CreateFirstCellClefChange()
            clef_change:SetClefIndex(clef_index)
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
                cell_frame_hold:MakeCellSingleClef(clef_change)
                cell_frame_hold:SetClefIndex(clef_index)
                cell_frame_hold:Save()
            else
                cell_frame_hold:MakeCellSingleClef(clef_change)
                cell_frame_hold:SetClefIndex(clef_index)
                cell_frame_hold:SaveNew()
            end
        end
    end

    function clef.restore_default_clef(first_measure, last_measure, staff_number)
        client.assert_supports("clef_change")
        local default_clef = clef.get_default_clef(first_measure, last_measure, staff_number)
        clef.set_measure_clef(first_measure, last_measure, staff_number, default_clef)

    end

    function clef.process_clefs(mid_clefs)
        local clefs = {}
        local new_mid_clefs = finale.FCCellClefChanges()
        for mid_clef in each(mid_clefs) do
            table.insert(clefs, mid_clef)
        end
        table.sort(clefs, function (k1, k2) return k1.MeasurePos < k2.MeasurePos end)
        for k, mid_clef in ipairs(clefs) do
            new_mid_clefs:InsertCellClefChange(mid_clef)
            new_mid_clefs:SaveAllAsNew()
        end

        for i = new_mid_clefs.Count - 1, 1, -1 do
            local later_clef_change = new_mid_clefs:GetItemAt(i)
            local earlier_clef_change = new_mid_clefs:GetItemAt(i - 1)
            if later_clef_change.MeasurePos < 0 then
                new_mid_clefs:ClearItemAt(i)
                new_mid_clefs:SaveAll()
                goto continue
            end
            if earlier_clef_change.ClefIndex == later_clef_change.ClefIndex then
                new_mid_clefs:ClearItemAt(i)
                new_mid_clefs:SaveAll()
            end
            ::continue::
        end
        return new_mid_clefs
    end

    function clef.clef_change(clef_type, region)
        local clef_index = clef_map[clef_type]
        local cell_frame_hold = finale.FCCellFrameHold()
        local last_clef
        local last_staff = -1
        for cell_measure, cell_staff in eachcell(region) do
            local cell = finale.FCCell(region.EndMeasure, cell_staff)
            if cell_staff ~= last_staff then
                last_clef = cell:CalcClefIndexAt(region.EndMeasurePos)
                last_staff = cell_staff
            end
            cell = finale.FCCell(cell_measure, cell_staff)
            cell_frame_hold:ConnectCell(cell)
            if cell_frame_hold:Load() then
            end
            if  region:IsFullMeasureIncluded(cell_measure) then
                clef.set_measure_clef(cell_measure, cell_measure, cell_staff, clef_index)
                if not region:IsLastEndMeasure() then
                    cell = finale.FCCell(cell_measure + 1, cell_staff)
                    cell_frame_hold:ConnectCell(cell)
                    if cell_frame_hold:Load() then
                        cell_frame_hold:SetClefIndex(last_clef)
                        cell_frame_hold:Save()
                    else
                        cell_frame_hold:SetClefIndex(last_clef)
                        cell_frame_hold:SaveNew()
                    end
                end
            else
                local mid_measure_clefs = cell_frame_hold:CreateCellClefChanges()
                local new_mid_measure_clefs = finale.FCCellClefChanges()
                local mid_measure_clef = finale.FCCellClefChange()
                if not mid_measure_clefs then
                    mid_measure_clefs = finale.FCCellClefChanges()
                    mid_measure_clef:SetClefIndex(cell_frame_hold.ClefIndex)
                    mid_measure_clef:SetMeasurePos(0)
                    mid_measure_clef:Save()
                    mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    mid_measure_clefs:SaveAllAsNew()
                end
                if cell_frame_hold.Measure == region.StartMeasure and region.StartMeasure ~= region.EndMeasure then

                    for mid_clef in each(mid_measure_clefs) do
                        if mid_clef.MeasurePos < region.StartMeasurePos then
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        end
                    end

                    mid_measure_clef:SetClefIndex(clef_index)
                    mid_measure_clef:SetMeasurePos(region.StartMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()
                end
                if cell_frame_hold.Measure == region.EndMeasure and region.StartMeasure ~= region.EndMeasure then

                    for mid_clef in each(mid_measure_clefs) do
                        if mid_clef.MeasurePos == 0 then
                            mid_clef:SetClefIndex(clef_index)
                            mid_clef:Save()
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        elseif mid_clef.MeasurePos > region.EndMeasurePos then
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        end
                    end

                    mid_measure_clef:SetClefIndex(last_clef)
                    mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()
                end
                if cell_frame_hold.Measure == region.StartMeasure and region.StartMeasure == region.EndMeasure then
                    local last_clef = cell:CalcClefIndexAt(region.EndMeasurePos)
                    for mid_clef in each(mid_measure_clefs) do
                        if mid_clef.MeasurePos == 0 then
                            if region.StartMeasurePos == 0 then
                                mid_clef:SetClefIndex(clef_index)
                                mid_clef:Save()
                            end
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        elseif mid_clef.MeasurePos < region.StartMeasurePos or
                        mid_clef.MeasurePos > region.EndMeasurePos then
                            new_mid_measure_clefs:InsertCellClefChange(mid_clef)
                            new_mid_measure_clefs:SaveAllAsNew()
                        end
                    end

                    mid_measure_clef:SetClefIndex(clef_index)
                    mid_measure_clef:SetMeasurePos(region.StartMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()

                    mid_measure_clef:SetClefIndex(last_clef)
                    mid_measure_clef:SetMeasurePos(region.EndMeasurePos)
                    mid_measure_clef:Save()
                    new_mid_measure_clefs:InsertCellClefChange(mid_measure_clef)
                    new_mid_measure_clefs:SaveAllAsNew()
                end

                new_mid_measure_clefs = clef.process_clefs(new_mid_measure_clefs)

                if cell_frame_hold:Load() then
                    cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                    cell_frame_hold:Save()
                else
                    cell_frame_hold:SetCellClefChanges(new_mid_measure_clefs)
                    cell_frame_hold:SaveNew()
                end
            end
        end
    end
    return clef
end
function plugindef()


    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "2022-08-30"
    finaleplugin.RequireSelection = true
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.AdditionalMenuOptions = [[
    Clef 2: Bass
    Clef 3: Alto
    Clef 4: Tenor
    Clef 5: Tenor (Voice)
    Clef 6: Percussion
    ]]
    finaleplugin.AdditionalUndoText = [[
    Clef 2: Bass
    Clef 3: Alto
    Clef 4: Tenor
    Clef 5: Tenor (Voice)
    Clef 6: Percussion
    ]]
    finaleplugin.AdditionalDescriptions = [[
    Changes the selected region to bass clef
    Changes the selected region to alto clef
    Changes the selected region to tenor clef
    Changes the selected region to tenor voice (treble 8ba) clef
    Changes the selected region to percussion clef
    ]]
    finaleplugin.AdditionalPrefixes = [[
    clef_type = "bass"
    clef_type = "alto"
    clef_type = "tenor"
    clef_type = "tenor_voice"
    clef_type = "percussion"
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/clef_change.hash"
    return "Clef 1: Treble", "Clef 1: Treble", "Changes the selected region to treble clef"
end
clef_type = clef_type or "treble"
local clef = require("library.clef")
local region = finenv.Region()
region:SetCurrentSelection()
clef.clef_change(clef_type, region)