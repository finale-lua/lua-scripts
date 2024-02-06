--  Author: Robert Patterson
--  Date: February 5, 2024
--[[
$module FCMCtrlComboBox

The PDK offers FCCtrlCombox which is an edit box with a pulldown menu attached. It has the following
features:

- It is an actual subclass of FCCtrlEdit, which means FCMCtrlComboBox is a subclass of FCMCtrlEdit.
- The text contents of the control does not have to match any of the pulldown values.

The PDK manages the pulldown values and selectied item well enough for our purposes. Furthermore, the order in
which you set text or set the selected item matters as to which one you'll end up with when the window
opens. The PDK takes the approach that setting text takes precedence over setting the selected item.
For that reason, this module (at least for now) does not manage those properties separately.

## Summary of Modifications
- Overrode `AddString` to allows Lua `string` or `number` in addition to `FCString`.
- Added `AddStrings` that accepts multiple arguments of `table`, `FCString`, Lua `string`, or `number`.
- Added localized versions `AddStringLocalized` and `AddStringsLocalized`.
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local class = {Methods = {}}
local methods = class.Methods

local temp_str = finale.FCString()

--[[
% AddString

**[Fluid] [Override]**

Override Changes:
- Accepts Lua `string` or `number` in addition to `FCString`.
- Hooks into control state preservation.

@ self (FCMCtrlPopup)
@ str (FCString | string | number)
]]

function methods:AddString(str)
    mixin_helper.assert_argument_type(2, str, "string", "number", "FCString")

    str = mixin_helper.to_fcstring(str, temp_str)
    self:AddString__(str)
end

--[[
% AddStringLocalized

**[Fluid]**

Localized version of `AddString`.

@ self (FCMControl)
@ key (string | FCString) The key into the localization table. If there is no entry in the appropriate localization table, the key is the text.
]]
methods.AddStringLocalized = mixin_helper.create_localized_proxy("AddString")

--[[
% AddStrings

**[Fluid]**

Adds multiple strings to the combobox.

@ self (FCMCtrlPopup)
@ ... (table, FCStrings | FCString | string | number)
]]
function methods:AddStrings(...)
    mixin_helper.process_string_arguments(self, mixin.FCMCtrlComboBox.AddString, ...)
end

--[[
% AddStrings

**[Fluid]**

Adds multiple localized strings to the combobox.

@ self (FCMCtrlPopup)
@ ... (table, FCStrings | FCString | string | number)
]]
function methods:AddStringsLocalized(...)
    mixin_helper.process_string_arguments(self, mixin.FCMCtrlComboBox.AddStringLocalized, ...)
end

return class
