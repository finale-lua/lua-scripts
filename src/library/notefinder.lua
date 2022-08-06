--[[
$module Notefinder
]]
local notefinder = {}

--[[
% first_and_last_notes

Finds 

@ music_region (FCMusicRegion) The region to process.
: (endpoints) A table, where each index contains the .start_note and .end_note for each staff.
]]
function notefinder.first_and_last_notes(music_region)
    local endpoints = {}
    local endpoints_count = 0
    for working_staff = music_region:GetStartStaff(), music_region:GetEndStaff() do
        local notes = {}
        local count = 0
        music_region:SetStartStaff(working_staff)
        music_region:SetEndStaff(working_staff)
        --
        for e in eachentry(music_region) do
            if e:IsNote() then
                table.insert(notes, e)
                count = count + 1
            end
        end
        if count > 1 then
            endpoints_count = endpoints_count + 1
            local start_end = {start_note = notes[1], end_note = notes[count]}
            table.insert(endpoints, start_end)
        end
    end
    return endpoints
end

return notefinder