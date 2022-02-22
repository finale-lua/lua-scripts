--[[
$module FCMCtrlSwitcher
]]
local mixin = require("library.mixin")
local library = require("library.general_library")

local private = setmetatable({}, {__mode = "k"})
local props = {}

local temp_str = finale.FCString()


--[[
% Init

**[Internal]**

@ self (FCMCtrlSwitcher)
]]
function props:Init()
    private[self] = private[self] or {Index = {}}
end

--[[
% AddPage

**[Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

@ self (FCMCtrlSwitcher)
@ str (FCString|string|number)
]]
function props:AddPage(str)
    mixin.assert_argument(str, {"string", "number", "FCString"}, 2)

    if type(str) ~= "userdata" then
        temp_str.LuaString = tostring(str)
        str = temp_str
    end

    self:AddPage_(str)
    table.insert(private[self].Index, str.LuaString)
end

--[[
% SetSelectedPageText

**[Fluid]**
Set the selected page by its text. If the page is not found, an error will be thrown.

@ self (FCMCtrlSwitcher)
@ str (FCString|string|number) Text of page to select. Must be an exact match.
]]
function props:SetSelectedPageText(text)
    mixin.assert_argument(text, {"string", "number", "FCString"}, 2)

    text = type(str) ~= "userdata" and text.LuaString or tostring(text)

    for k, v in ipairs(private[self].Index) do
        if v == text then
            self:SetSelectedPage(k - 1)
            return
        end
    end

    error("No page named '" .. text  .. "'", 2)
end


return props