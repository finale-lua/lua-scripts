function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.NoStore = true
    finaleplugin.ExecuteExternalCode = true
    finaleplugin.ExecuteHttpsCalls = true
    finaleplugin.HandlesUndo = true
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.ExecuteHttpsCalls = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "September 22, 2023"
    finaleplugin.CategoryTags = "Lyrics"
    finaleplugin.Notes = [[
        Uses the OpenAI online api as a chatbot. One reason you might use this instead
        of the free ChatGPT site is to be able to pose questions to GPT-4 without paying
        the monthly subscription.

        You must have a OpenAI account and internet connection. You will
        need your API Key, which can be obtained as follows:

        - Login to your OpenAI account at openai.com.
        - Select API and then click on Personal
        - You will see an option to create an API Key.
        - You must keep your API Key secure. Do not share it online.

        To configure your OpenAI account, enter your API Key in the prefix
        when adding the script to RGP Lua. If you want OpenAI to be available in
        any script, you can add your key to the System Prefix instead.

        Your prefix should include this line of code:

        ```
        openai_api_key = "<your secure api key>"
        ```

        It is important to enclose the API Key you got from OpenAI in quotes as shown
        above.

        The first time you use the script, RGP Lua will prompt you for permission
        to post data to the openai.com server. You can choose Allow Always to suppress
        that prompt in the future.

        The OpenAI service is not free, but each request is very
        light (using ChatGPT 3.5) and small jobs only cost fractions of a cent.
        Check the pricing at the OpenAI site.
    ]]
    return "OpenAI ChatBot...", "OpenAI ChatBot",
        "Post questions to OpenAI language models using your OpenAI account."
end

local mixin = require("library.mixin")
local openai = require("library.openai")

require("mobdebug").start()

local models =
{
    ["GPT-3.5"] = "gpt-3.5-turbo",
    ["GPT-4"] = "gpt-4"
}

local https_session

local function send_prompt()
    if not global_dialog then return end
    local temperature = 0.7 -- ToDo: make this configurable
    local model = finale.FCString()
    local dlg = global_dialog
    dlg:GetControl("model"):GetSelectedString(model)
    local prompt = finale.FCString()
    dlg:GetControl("prompt"):GetText(prompt):SetEnable(false)
    dlg:GetControl("go"):SetEnable(false)
    https_session = openai.create_completion(models[model.LuaString], prompt.LuaString, temperature, function(success, result)
        if not https_session then return end
        https_session = nil
        dlg:GetControl("prompt"):SetEnable(true)
        dlg:GetControl("go"):SetEnable(true)
        if success then
            result = result.choices[1].message.content
        else
            result = "ERROR: "..result
        end
        local response = dlg:GetControl("response")
        result = result .. "\n===\n"
        local newtext = finale.FCString()
        response:GetText(newtext)
        newtext:AppendString(finale.FCString(result))
        response:SetText(newtext)
        local total_range = finale.FCRange()
        dlg:GetControl("prompt"):GetTotalTextRange(total_range)
        dlg:GetControl("prompt"):SetSelection(total_range)
        dlg:GetControl("prompt"):SetKeyboardFocus()
    end)
end

local function create_dialog()
    local dlg = mixin.FCXCustomLuaWindow():SetTitle("OpenAI ChatBot")
    local current_y = 0
    local model_popup = dlg:CreatePopup(0, current_y, "model")
        :SetWidth(90)
    for k, _ in pairsbykeys(models) do
        model_popup:AddString(k)
    end
    model_popup:SetSelectedItem(1) -- counting from zero: GPT-4 is the default.
    dlg:CreateButton(100, current_y):SetText("New Chat")
        :SetWidth(90)
        :AddHandleCommand(function(control)
            control:GetParent():GetControl("prompt"):SetText("")
            control:GetParent():GetControl("response"):SetText("")
        end)
    current_y = current_y + 30
    local chatbox_height = 275
    local chatbox_width = 800
    dlg:CreateEditText(0, current_y, "prompt")
        :SetWidth(chatbox_width)
        :SetHeight(chatbox_height)
     --   :SetFont(finale.FCFontInfo("Helvetica", 11))
    current_y = current_y + chatbox_height + 10
    dlg:CreateEditText(0, current_y, "response")
        :SetWidth(chatbox_width)
        :SetHeight(chatbox_height)
        :SetReadOnly(true)
     --   :SetFont(finale.FCFontInfo("Helvetica", 11))
    dlg:CreateOkButton("go"):SetText("Go")
    dlg:RegisterHandleOkButtonPressed(send_prompt)
    dlg:CreateCancelButton():SetText("Close")
    return dlg
end

local function openai_chat()
    if not global_dialog then
        global_dialog = create_dialog()
    end
    global_dialog:RunModeless()
end

openai_chat()
