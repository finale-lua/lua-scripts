function plugindef()
  finaleplugin.Author = "Jacob Winkler"
  finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
  finaleplugin.Version = "1.0"
  finaleplugin.Date = "2024-01-27"
  finaleplugin.HandlesUndo = true
  finaleplugin.RequireSelection = true
  return "Note Filter...", "Note Filter", "Deletes notes above or below a specified note"
end

local note_entry = require("library.note_entry")
local configuration = require("library.configuration")
local str = finale.FCString()

config = {
  above_below = "below",
  pitch_string = "C4"
}

local script_name = "pitch_filter"
configuration.get_user_settings(script_name, config, true)

local function simple_input(title, text)
  local return_value = finale.FCString()
  local min_width = 160
  --
  local function format_ctrl(ctrl, h, w, st)
    ctrl:SetHeight(h)
    ctrl:SetWidth(w)
    str.LuaString = st
    ctrl:SetText(str)
  end -- function format_ctrl
--
  local title_width = string.len(title) * 6 + 54
  if title_width > min_width then min_width = title_width end
  local text_width = string.len(text) * 6
  if text_width > min_width then min_width = text_width end
--
  str.LuaString = title
  local dialog = finale.FCCustomLuaWindow()
  dialog:SetTitle(str)
  local descr = dialog:CreateStatic(0, 0)
  format_ctrl(descr, 16, min_width, text)
  local below_check = dialog:CreateCheckbox(70, 0)
  str.LuaString = "Below"
  below_check:SetText(str)
  local above_check = dialog:CreateCheckbox(120, 0)
  str.LuaString = "Above"
  above_check:SetText(str)
  local input_edit = dialog:CreateEdit(180, -3)
  format_ctrl(input_edit, 20, 30, config.pitch_string)
  dialog:CreateOkButton()
  dialog:CreateCancelButton()
--
  local function set_checkboxes()
    if config.above_below == "below" then
      below_check:SetCheck(1)
      above_check:SetCheck(0)
    else
      below_check:SetCheck(0)
      above_check:SetCheck(1)
    end
  end

  set_checkboxes()

  local function callback(ctrl)
    if ctrl:GetControlID() == below_check:GetControlID() then
      if below_check:GetCheck() == 1 then
        config.above_below = "below"
      else
        config.above_below = "above"
      end
      set_checkboxes()
    elseif ctrl:GetControlID() == above_check:GetControlID() then
      if above_check:GetCheck() == 1 then
        config.above_below = "above"
      else
        config.above_below = "below"
      end
      set_checkboxes()
    end
  end -- callback
--
  dialog:RegisterHandleCommand(callback)

--
  if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
    input_edit:GetText(return_value)
    config.pitch_string = return_value.LuaString
    str.LuaString = "Filter Notes "..config.above_below.." "..return_value.LuaString
    configuration.save_user_settings(script_name, config)
    finenv.StartNewUndoBlock(str.LuaString, false)
    return return_value.LuaString
  end

end -- function simple_input

local function expand_rests() -- inspired by Carl Vine
  local i = 0
  while i < 4 do
    local delete_next = false
    for e in eachentrysaved(finenv.Region()) do
      local measure = finale.FCMeasure()
      measure:Load(e.Measure)
      local timesig = measure:GetTimeSignature()
      local compound = timesig:IsCompound()
      if e:IsRest() and compound == false then
        if delete_next then -- last note was expanded
          e.Duration = 0
          delete_next = false -- start again
        elseif e.Duration < finale.HALF_NOTE then
          if e.MeasurePos % finale.HALF_NOTE == 0 and e:Next():IsRest() then
            e.Duration = e.Duration + e:Next().Duration
            delete_next = true
          elseif e.Duration < finale.QUARTER_NOTE then
            if e.MeasurePos % finale.QUARTER_NOTE == 0 and e:Next():IsRest() then
              e.Duration = e.Duration + e:Next().Duration
              delete_next = true
            elseif e.Duration < finale.NOTE_8TH then
              if e.MeasurePos % finale.NOTE_8TH == 0 and e:Next():IsRest() then
                e.Duration = e.Duration + e:Next().Duration
                delete_next = true
              elseif e.Duration < finale.NOTE_16TH then
                if e.MeasurePos % finale.NOTE_16TH == 0 and e:Next():IsRest() then
                  e.Duration = e.Duration + e:Next().Duration
                  delete_next = true
                end
              end
            end
          end
        end
      end
    end
    i = i + 1
  end
end

local function pitch_to_midi(pitch)
  local pitch_table = { "C", "D", "E", "F", "G", "A", "B" }
  local midi_table = {0, 2, 4, 5, 7, 9, 11}
  local length = (string.len(pitch))
  local octave = string.sub(pitch, -1)
  local pitch_name = string.sub(pitch, 1, length-1)
  local pitch_base = string.sub(pitch_name, 1, 1)
  pitch_base = string.upper(pitch_base)
  local midi_note = 0
  local alter = 0
--
  if string.len(pitch_name) == 2 then
    local accidental = string.sub(pitch_name, -1)
    if accidental == "#" then
      alter = 1
    elseif accidental == "b" then
      alter = -1
    end
  end
  for i in pairs(pitch_table) do
    if pitch_table[i] == pitch_base then
      midi_note = midi_table[i] + alter + (12 * octave) + 12
    end
  end
  return midi_note
end -- pitch_to_midi()

local function filter_keyswitch()
  --
  str.LuaString = "Filter notes"
--
  local pitch = simple_input("Note Filter v"..finaleplugin.Version,str.LuaString)

  if nil == pitch then
    goto bypass
  end

  local note_filter = pitch_to_midi(pitch)
  for entry in eachentrysaved(finenv.Region()) do
    if entry:IsNote() then
      if entry.Count > 1 then
        local process_entry = 1
        while process_entry == 1 do
          local lowest_note = entry:CalcLowestNote(nil)
          local highest_note = entry:CalcHighestNote(nil)
          if lowest_note then
            if lowest_note:CalcMIDIKey() < note_filter and config.above_below == "below" then
              note_entry.delete_note(lowest_note)
            elseif highest_note:CalcMIDIKey() > note_filter and config.above_below == "above" then
              note_entry.delete_note(highest_note)
            else
              process_entry = 0
            end
          else
            process_entry = 0
          end
        end
      else
        for note in each(entry) do
          if (note:CalcMIDIKey() < note_filter and config.above_below == "below") or
          (note:CalcMIDIKey() > note_filter  and config.above_below == "above") then
            note_entry.delete_note(note)
          end
        end
      end
    end
  end
  expand_rests()
  ::bypass::
end -- filter keyswitch

filter_keyswitch()