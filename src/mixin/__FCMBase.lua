--  Author: Robert Patterson
--  Date: January 20, 2024
--[[
$module __FCMBase

## Summary of Modifications
- Add method _FallbackCall to gracefully allow skipping missing methods in earlier Lua versions
]] --
local mixin = require("library.mixin")
local mixin_helper = require("library.mixin_helper")

local class = {Methods = {}}
local methods = class.Methods


--[[
% _FallbackCall

Checks the existence of a class method before calling it. If the method exists, it returns
as expected. If the method does not exist, it returns the fallback_value. This function allows
a script to call a method that does not exist in earlier versions of Lua (specifically, in JW Lua)
and get a default return value in that case.

@ self (userdata) The class instance on which to call the method.
@ method_name (string) The name of the method to return.
@ fallback_value (any) The value that will be returned if the method does not exist. If this value is `nil`, the function returns `self`.
@ additional_parameters (...) The additional parameters of the method.
]]
function methods:_FallbackCall(method_name, fallback_value, ...)
    if not self[method_name] then
        if fallback_value ~= nil then
            return fallback_value
        end
        return self
    end
    
    return self[method_name](self, ...)
end

return class
