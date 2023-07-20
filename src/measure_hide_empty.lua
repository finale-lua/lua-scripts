function plugindef()
    finaleplugin.RequireScore = true
    finaleplugin.RequireSelection = true
    finaleplugin.RequireDocument = true
    finaleplugin.MinJWLuaVersion = 0.65
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "2023-06-26"
    finaleplugin.Id = "4aebe066-d648-4111-b8b3-22ac2420c37d"
    finaleplugin.RevisionNotes = [[
        v1.0.1      First public release
                    Apply to to consecutive measures at once
        v0.9.6      Fix bug with single staff style
        v0.9.5      Simplify: Finale combines assignments for us
        v0.9.4      Minimum dialog width
        v0.9.3      Fix table index bug
                    Use both adjacent assignments if available
        v0.9.2      Reuse adjacent staff style assignments
                    Pick from multiple "Hide Staff" staff styles
        v0.9.1      First internal version
    ]]
    finaleplugin.Notes = [[
        This script will apply a "Hide Staff" staff style to any full measures in
        the selected region of the active score/part that do not have any entries. 
        If you have more than one "Hide Staff" staff style defined, you can pick 
        the one you want to use.
    ]]

    return "Hide Empty Measures", "Hide Empty Measures",
        "Applies a \"Hide Staff\" staff style to empty measures."
end


local function pick_style(styles)
    if #styles == 0 then
        finenv.UI():AlertInfo('No "Hide Staff" staff style found.', "Error")
        return
    elseif #styles == 1 then
        return styles[1][1]
    end

    local function make_str(str)
        local s = finale.FCString()
        s.LuaString = str
        return s
    end

    local dialog = finale.FCCustomWindow()
    dialog:SetTitle(make_str('Select "Hide Staff" Style'))

    local group = dialog:CreateRadioButtonGroup(0, 0, #styles)
    local labels = finale.FCStrings()
    local max_width = 175
    for _, style in ipairs(styles) do
        labels:AddCopy(make_str(style[2]))
        max_width = math.max(max_width, style[2]:len() * 6)
    end
    group:SetText(labels)
    group:SetWidth(max_width)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        return styles[group:GetSelectedItem() + 1][1]
    end
end

local function get_hide_staff_style_id()
    local hide_staff_styles = {}
    for def in loadall(finale.FCStaffStyleDefs()) do
        local str = finale.FCString()
        def:GetName(str)
        if str.LuaString:find("Hide Staff") then
            table.insert(hide_staff_styles, { def.ItemNo, str.LuaString })
        end
    end

    return pick_style(hide_staff_styles)
end

local function hide_empty_measures()
    local hide_staff_style_id = get_hide_staff_style_id()
    if not hide_staff_style_id then
        return
    end

    local current_staff = nil
    local assigns_for_staff = finale.FCStaffStyleAssigns()
    local region = finenv.Region()

    local function measure_is_hidden(m)
        for a in each (assigns_for_staff) do
            if a.StartMeasure <= m and a.EndMeasure >= m
                    and a.StyleID == hide_staff_style_id then
                return true
            end
        end
    end

    local function is_candidate_measure(m)
        if region:IsMeasureIncluded(m) and not measure_is_hidden(m) then
            local cell = finale.FCCell(m, current_staff)
            return not cell:CalcContainsEntries()
        end
    end

    for m, s in eachcell(region) do
        if current_staff ~= s then
            assigns_for_staff:LoadAllForItem(s)
            current_staff = s
        end

        if is_candidate_measure(m) then
            local start_measure = m
            local end_measure = m
            local function next_measure() return end_measure + 1 end

            while is_candidate_measure(next_measure()) do
                end_measure = next_measure()
            end

            local assign = finale.FCStaffStyleAssign()
            assign.StyleID = hide_staff_style_id
            assign.StartMeasure = start_measure
            assign.EndMeasure = end_measure
            assign:SaveNew(s)

            assigns_for_staff:LoadAllForItem(s)
        end
    end
end


hide_empty_measures()