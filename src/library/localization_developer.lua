--[[
$module Localization for Developers

This library provides a set of localization services for developers of scripts to make localization
as simple as possible. It uses calls to OpenAI to automatically translate words and phrases.
]]

local localization_developer = {}

local client = require("library.client")
local library = require("library.general_library")
local openai = require("library.openai")

--[[
% create_localized_base_table

Creates and returns a table of localizable strings by searching the top-level script for
quoted strings. While this may be useful at user-runtime, the primary use case it targets
is as a developer tool to aid in the creation of a table to be embedded in the script.

The returned table is in this form:

```
{
    ["<found string>"] = "found-string",
    ... -- for every string found in the script
}

Only the top-level script is searched. This is the script at the path specified by finenv.Running

: (table) a table containing the found strings
]]
function localization_developer.create_localized_base_table()
    local retval = {}
    local file_path = library.calc_script_filepath()
    file_path = client.encode_with_client_codepage(file_path)
    local file = io.open(file_path, "r")
    if file then
        local file_content = file:read("all")
        local function extract_strings(file_content)
            local i = 1
            local length = #file_content
            return function()
                while i <= length do
                    local char = string.sub(file_content, i, i)
                    if char == "'" or char == '"' then
                        local quote = char
                        local str = quote
                        i = i + 1
                        while i <= length do
                            char = string.sub(file_content, i, i)
                            local escaped = false
                            if char == '\\' then
                                i = i + 1
                                char = string.sub(file_content, i, i)
                                if char == "n" then char = "\n" end
                                if char == "r" then char = "\r" end
                                if char == "t" then char = "\t" end
                                -- may need to add more escape codes here
                                escaped = true
                            end
                            str = str .. char
                            -- Check for the end of the quoted string
                            if not escaped and char == quote then
                                break
                            end
                            i = i + 1
                        end
                        i = i + 1
                        return str:sub(2, -2)
                    end
                    i = i + 1
                end
                -- End of file, return nil to terminate the loop
                return nil
            end
        end
        for found_string in extract_strings(file_content) do
            retval[found_string] = found_string
        end
        file:close()
    end
    return retval
end

local function make_flat_table_string(lang, t)
    local concat = {}
    table.insert(concat, "localization_" .. lang .. " = {\n")
    for k, v in pairsbykeys(t) do
        table.insert(concat, "    [\"" .. tostring(k) .. "\"] = \"" .. tostring(v) .. "\",\n")
    end
    table.insert(concat, "}\n")
    return table.concat(concat)
end

--[[
% create_localized_base_table_string

Creates and returns a string representing a lua table of localizable strings by searching the top-level script for
quoted strings. It then copies this string to the clipboard. The primary use case is to be
a developer tool to aid in the creation of a table to be embedded in the script.

The base table is the table that defines the keys for all other languages. For each item in the base table, the
key is always equal to the value. The base table can be in any language.

@ lang (string) the two-letter language code of the strings in the base table. This is used only to name the table.
: (string) A string containing a Lua-formatted table of all quoted strings in the script
]]
function localization_developer.create_localized_base_table_string(lang)
    local t = localization_developer.create_localized_base_table()
    finenv.UI():TextToClipboard(make_flat_table_string(lang, t))
    finenv.UI():AlertInfo("localization_base table copied to clipboard", "")
end

function localization_developer.translate_localized_table_string(source_table, source_lang, target_lang)
    local table_string = make_flat_table_string(source_lang, source_table)
    local prompt = [[
        I am working on localizing text for a program that prints and plays music. There may be musical
        terminology among the words and phrases that I would like you to translate, as follows.\n
    ]] .. "Here is a lua table of keys and values:\n\n```\n" .. table_string .. "\n```\n" ..
                        [[
                    Provide a string that is Lua source code of a table definition of a table that has the same keys
                    but with the values translated to languages specified by the code
                ]] .. target_lang .. ". The table name should be `localization_`" .. target_lang .. "`.\n" ..
                [[
                    Return only the Lua code without any commentary. There may or may not be musical terms
                    in the provided text. This information is provided for context if needed.
                ]]

    local success, result = openai.create_completion("gpt-4", prompt, 0.2, 30)
    if success then
        local retval = string.gsub(result.choices[1].message.content, "```", "")
        finenv.UI():TextToClipboard(retval)
        finenv.UI():AlertInfo("localization_" .. target_lang .. " table copied to clipboard", "")
    else
        finenv.UI():AlertError(result, "OpenAI Error")
    end
end

return localization_developer
