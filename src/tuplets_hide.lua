function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.51"
    finaleplugin.Date = "2022/06/20"
    finaleplugin.AdditionalMenuOptions = [[ Tuplets Unhide ]]
    finaleplugin.AdditionalUndoText = [[    Tuplets Unhide ]]
    finaleplugin.AdditionalPrefixes = [[    show_tuplets = true ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
		Hide all tuplets in the currently selected region. 
		RGPLua (0.62 and above) creates a companion menu item, Tuplets Unhide.
	]]
    return "Tuplets Hide", "Tuplets Hide", "Hide all tuplets in the current selection"
end

show_tuplets = show_tuplets or false

function tuplet_state()
    for entry in eachentry(finenv.Region()) do
        if entry.TupletStartFlag then
            for tuplet in each(entry:CreateTuplets()) do
                tuplet.Visible = show_tuplets
                tuplet:Save()
            end
        end
    end
end

tuplet_state()
