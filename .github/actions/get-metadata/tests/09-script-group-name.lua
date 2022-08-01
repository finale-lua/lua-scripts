function plugindef()
    finaleplugin.ScriptGroupName = "Hairpin creator"
    finaleplugin.ScriptGroupDescription = "Create all sorts of hairpins"
    finaleplugin.AdditionalMenuOptions = [[
        Hairpin create unswell
        Hairpin create diminuendo
        Hairpin create swell
    ]]
    return "Hairpin create crescendo", "Hairpin create crescendo", "Hairpin create crescendo"
end
