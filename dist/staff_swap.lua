function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.MinFinaleVersion = "2012"
    finaleplugin.Author = "Jari Williamson"
    finaleplugin.Version = "0.01"
    finaleplugin.Notes = [[
        Swap the music on two different staves. Just create a selection, and the music on the
        top staff of the selection will be swapped with the music on the bottom staff of that
        selection.
    ]]
    return "Swap Staves", "Swap Staves", "Swaps the top and bottom of the selected staves"
end
local region = finenv.Region()
local top_staff = region.StartStaff
local bottom_staff = region.EndStaff
if top_staff < 1 or bottom_staff < 1 or top_staff == bottom_staff then
    return
end
local top_region = finale.FCMusicRegion()
top_region:SetRegion(region)
top_region.EndStaff = top_staff
local bottom_region = finale.FCMusicRegion()
bottom_region:SetRegion(region)
bottom_region.StartStaff = bottom_staff
top_region:CopyMusic()
bottom_region:CopyMusic()
top_region.StartStaff = bottom_staff
top_region.EndStaff = bottom_staff
top_region:PasteMusic()
bottom_region.StartStaff = top_staff
bottom_region.EndStaff = top_staff
bottom_region:PasteMusic()
top_region:ReleaseMusic()
bottom_region:ReleaseMusic()
region:SetInDocument()
