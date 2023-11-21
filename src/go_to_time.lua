function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.05"
    finaleplugin.Date = "2023/11/21"
    finaleplugin.CategoryTags = "Measures, Region, Selection"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        To navigate to a specific time in the current file, 
        enter the minutes and seconds in duration. 
        Either value can include decimal points. 
        Accelerandos and Rallentandos are not considered and only the 
        first tempo mark in each measure is evaluated. 
        These are assumed to take effect at the start of that measure.
    ]]
    return "Go To Time...", "Go To Time", "Navigate to a specific time in the current file"
end

function get_new_tempo(measure, beat, speed)
    for expression in each(measure:CreateExpressions()) do
        local exp_def = expression:CreateTextExpressionDef()
        if exp_def and (exp_def:IsPlaybackTempo()
            or exp_def.PlaybackType == finale.EXPPLAYTYPE_TEMPO) then
            local b = exp_def:GetPlaybackTempoDuration()
            local s = exp_def:GetPlaybackTempoValue()
            if b > 0 and s > 0 then -- valid tempo marking
                beat = b
                speed = s
                break -- only first one in each measure (for now)
            end
        end
    end
    return beat, speed
end

local function choose_target_time()
    local s = finale.FCString()
        local function fs(str)
            s.LuaString = tostring(str)
            return s
        end
    local dialog = finale.FCCustomLuaWindow()
    local x, y = 60, 0
    dialog:SetTitle(fs(plugindef()))
    local stat = dialog:CreateStatic(0, y)
        stat:SetText(fs("Go to measure starting at:"))
        stat:SetWidth(150)
    y = y + 18
    local min = dialog:CreateEdit(0, y)
        min:SetWidth(x - 10)
        min:SetText(fs("0"))
    local sec = dialog:CreateEdit(x, y)
        sec:SetWidth(x - 10)
        sec:SetText(fs("0"))
    y = y + 20
    stat = dialog:CreateStatic(0, y)
        stat:SetText(fs("minutes"))
        stat:SetWidth(x)
    stat = dialog:CreateStatic(x, y)
        stat:SetText(fs("seconds"))
        stat:SetWidth(x)
    y = y + 20
    local select = dialog:CreateCheckbox(0, y)
        select:SetWidth(150)
        select:SetText(fs("select matching measure"))
        select:SetCheck(1)
    local but = dialog:CreateOkButton()
    but:SetText(fs("GO"))
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)

    s_min = finale.FCString()
    min:GetText(s_min) -- get decimal minutes in (s_min)
    sec:GetText(s) -- get decimal seconds in (s)
    return ok,
        tonumber(s_min.LuaString),
        tonumber(s.LuaString),
        (select:GetCheck() == 1)
end

local function move_to_target(rgn, match_measure, select)
    finenv.UI():MoveToMeasure(match_measure, 0)
    if select then
        rgn.StartMeasure = match_measure
        rgn.EndMeasure = match_measure
        rgn.StartSlot = 1
        rgn.EndSlot = 1
        rgn:SetInDocument()
    end
end

local function find_matching_measure()
    local measure = finale.FCMeasure()
    local rgn = finale.FCMusicRegion()
    rgn:SetFullDocument()
    -- get tempo base prefs
    local pb_prefs = finale.FCPlaybackPrefs()
    pb_prefs:LoadFirst()
    local beat = pb_prefs.MetronomeBeat
    local speed = pb_prefs.MetronomeSpeed

    local ok, min, sec, select = choose_target_time()
    if not ok then return end -- user cancelled

    local target = min * 60 + sec
    local tally = 0
    local match_measure = 0

    -- measure tally duration loop
    for measure_num = 1, rgn.EndMeasure do
        if tally >= target then
            match_measure = measure_num -- all done
            break
        end
        -- move to end of measure
        measure:Load(measure_num)
        beat, speed = get_new_tempo(measure, beat, speed)
        local m_duration = (measure:GetDuration() * 60) / (beat * speed)
        tally = tally + m_duration
        if tally > target then
            match_measure = measure_num
            break
        end
    end
    if match_measure > 0 then -- found a matching measure
        move_to_target(rgn, match_measure, select)
    else
        local msg = "The target time of "
            .. string.format("[%02d:%05.2f]", min, sec)
            .. " is longer than the duration of the current score"
        finenv.UI():AlertInfo(msg, plugindef())
    end
end

find_matching_measure()
