function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        This script illustrates how to set up a data list control. The variables at the top
        deterimine its appearance and behavior.
    ]]
    return "0--data_list_control.lua"
end

if finenv.IsRGPLua and not finenv.ConsoleIsAvailable then
    require('mobdebug').start()
end

print(_VERSION)
print(finenv.LuaBridgeVersion)

local numcols = 3
local numrows = 6
local usecheckboxes = true
local showheader = true
local expandlast = true
local multiselect = true
local preselect_in_initwindow = false
local pre_select = {2, 4}
local pre_check = {1, 5}

local dlg = finale.FCCustomLuaWindow()
dlg:SetTitle(finale.FCString("Test DataList Control"))
local data_list = dlg:CreateDataList(0, 0)
data_list:SetWidth(600)
data_list:SetHeight(300)
data_list.UseCheckboxes = usecheckboxes
data_list.ShowHeader = showheader
data_list.ExpandLastColumn = expandlast
data_list.AlternatingBackgroundRowColors = true
data_list.AllowsMultipleSelection = multiselect
-- add columns
for c = 1, numcols do
    data_list:AddColumn(finale.FCString("Column " .. c), 90)
end
-- add rows
for r = 1, numrows do
    local row = data_list:CreateRow()
    for c = 1, numcols do
        row:GetItemAt(c - 1).LuaString = "RowCol [" .. r .. ", " .. c .. "]"
    end
end
-- pre-select
-- NOTE: pre-selection of rows is broken in 0.70. This code checks to see if
--      it has been fixed in a later version. For 0.70, rows should be pre-selected
--      inside an InitWindow function.
local function do_preselect()
    for _, rownum in ipairs(pre_select) do
        if rownum <= numrows then
            data_list:AddSelectedLine(rownum)
            print("select rownum " .. rownum)
        end
    end
    for _, rownum in ipairs(pre_check) do
        if usecheckboxes and rownum <= numrows then
            data_list:GetItemAt(rownum).Check = true
        end
    end
end
if not preselect_in_initwindow then
    do_preselect()
end
-- status controls
local y = 310
local y_inc = 16
local x = 0
local x_inc = 100
local x_sep = 10
local show_double_click = dlg:CreateStatic(x, y)
show_double_click:SetWidth(x_inc - x_sep)
x = x + x_inc
local show_kbd_command = dlg:CreateStatic(x, y)
show_kbd_command:SetWidth(90)
x = x + x_inc
local show_selection = dlg:CreateStatic(x, y)
show_selection:SetWidth(x_inc - x_sep)
x = x + x_inc
local show_checkbox = dlg:CreateStatic(x, y)
show_checkbox:SetWidth(x_inc - x_sep)
y = y + y_inc
-- manipulation controls
x = 0
x_inc = 70
local toggle_row_colors = dlg:CreateButton(x, y)
toggle_row_colors:SetText(finale.FCString("row colors"))
toggle_row_colors:SetWidth(x_inc - x_sep)
dlg:RegisterHandleControlEvent(toggle_row_colors, function(control)
    data_list.AlternatingBackgroundRowColors = not data_list.AlternatingBackgroundRowColors
    data_list:SetKeyboardFocus()
end)
x = x + x_inc
local select_row_random = dlg:CreateButton(x, y)
select_row_random:SetText(finale.FCString("random row"))
select_row_random:SetWidth(x_inc - x_sep)
dlg:RegisterHandleControlEvent(select_row_random, function(control)
    local random_row_index = math.floor(math.random() * numrows)
    data_list:SelectLine(random_row_index)
    data_list:SetKeyboardFocus()
end)
x = x + x_inc
local unsel_first = dlg:CreateButton(x, y)
unsel_first:SetText(finale.FCString("unsel 1st"))
unsel_first:SetWidth(x_inc - x_sep)
dlg:RegisterHandleControlEvent(unsel_first, function(control)
    for x = 0, data_list:GetCount() - 1 do
        if data_list:IsLineSelected(x) then
            data_list:UnselectLine(x)
            break
        end
    end
    data_list:SetKeyboardFocus()
end)
x = x + x_inc
local unsel_all = dlg:CreateButton(x, y)
unsel_all:SetText(finale.FCString("unsel all"))
unsel_all:SetWidth(x_inc - x_sep)
dlg:RegisterHandleControlEvent(unsel_all, function(control)
    data_list:UnselectAll()
    data_list:SetKeyboardFocus()
end)
x = x + x_inc
y = y + y_inc
-- registrations
local function on_item_selected()
    local index = data_list:GetSelectedLine()
    if index < 0 then
        show_double_click:SetText(finale.FCString("None"))
    else
        local row = data_list:GetItemAt(index)
        show_double_click:SetText(row:GetItemAt(0))
        if data_list.UseCheckboxes then
            row:SetCheck(not row:GetCheck())
        end
    end
end
dlg:RegisterHandleListDoubleClick(function(control)
    on_item_selected()
end)
dlg:RegisterHandleListEnterKey(function(control)
    on_item_selected()
    return true
end)
dlg:RegisterHandleKeyboardCommand(function(control, character)
    local charstr = utf8.char(character)
    show_kbd_command:SetText(finale.FCString(charstr))
    return charstr == "N" or charstr == "W" -- eat "N" and "W"
end)
dlg:RegisterHandleDataListSelect(function(control, line_index)
    show_selection:SetText(finale.FCString("selected " .. line_index .. "(" .. data_list:GetSelectedLine() .. ")"))
end)
if usecheckboxes then
    dlg:RegisterHandleDataListCheck(function(control, line_index, state)
        local state_str = state and "checked " or "unchecked "
        show_checkbox:SetText(finale.FCString(state_str .. line_index))
    end)
end
dlg:RegisterInitWindow(function()
    if preselect_in_initwindow then
        do_preselect()
    end
end)

dlg:CreateOkButton()
dlg:ExecuteModal(nil)

local checked_str = ""
local selected_str = ""
for x = 0, data_list:GetCount() - 1 do
    if data_list:IsLineSelected(x) then
        if #selected_str > 0 then
            selected_str = selected_str .. ", "
        end
        selected_str = selected_str .. x
    end
    local row = data_list:GetItemAt(x)
    if row.Check then
        if #checked_str > 0 then
            checked_str = checked_str .. ", "
        end
        checked_str = checked_str .. x
    end
end
if finenv.ConsoleIsAvailable then
    print("Checked Rows: " .. checked_str)
    print("Selected Rows: " .. selected_str)
else
    finenv.UI():AlertInfo("Checked: " .. checked_str .. "\nSelected: " .. selected_str, "Selected")
end
