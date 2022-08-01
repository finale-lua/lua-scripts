function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.52"
    finaleplugin.Date = "2022/08/01"
    finaleplugin.AdditionalMenuOptions = [[
        Tuplets Unhide
        ]]
    finaleplugin.AdditionalUndoText = [[
        Tuplets Unhide
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Unhide all tuplets in the current selection
    ]]
    finaleplugin.AdditionalPrefixes = [[
        tuplets_unhide = true
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.ScriptGroupName = "Tuplet visibility"
    finaleplugin.ScriptGroupDescription = "Hide or unhide all tuplets in the selected region"
    finaleplugin.Notes = [[
        This script creates two menu items that either `Hide` or `Unhide` 
        all tuplets in the selected region.
	]]
    return "Tuplets Hide", "Tuplets Hide", "Hide all tuplets in the current selection"
end

tuplets_unhide = tuplets_unhide or false

function tuplet_state()
    for entry in eachentry(finenv.Region()) do
        if entry.TupletStartFlag then
            for tuplet in each(entry:CreateTuplets()) do
                tuplet.Visible = tuplets_unhide
                tuplet:Save()
            end
        end
    end
end

tuplet_state()
