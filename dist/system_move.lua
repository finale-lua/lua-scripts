function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "2.0.1"
    finaleplugin.Date = "July 10, 2022"
    finaleplugin.CategoryTags = "System"
    finaleplugin.AuthorURL = "https://nickmazuk.com"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.AdditionalMenuOptions = [[
        Move System Down
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Moves the selected system down one space
    ]]
    finaleplugin.AdditionalPrefixes = [[
        move_direction = 1
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/system_move.hash"
    return "Move System Up", "Move System Up", "Moves the selected system up one space"
end
config = {
    move_amount = 24
}
function system_move(direction)
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local last_system = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local last_system_number = last_system:GetItemNo()
    for i = system_number, last_system_number, 1 do
        system = systems:GetItemAt(i - 1)
        system.SpaceAbove = system.SpaceAbove + (direction * config.move_amount)
        system:Save()
    end
end
move_direction = move_direction or -1
system_move(move_direction)
