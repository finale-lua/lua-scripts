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

-- Get the selection
local region = finenv.Region()
-- Get the top and bottom staff
local top_staff = region.StartStaff
local bottom_staff = region.EndStaff

-- Make sure that the swap is valid
if top_staff < 1 or bottom_staff < 1 or top_staff == bottom_staff then
    return
end

-- Create a top region
local top_region = finale.FCMusicRegion()
top_region:SetRegion(region)
top_region.EndStaff = top_staff

-- Create a bottom region
local bottom_region = finale.FCMusicRegion()
bottom_region:SetRegion(region)
bottom_region.StartStaff = bottom_staff

-- Copy the music to clip files
top_region:CopyMusic()
bottom_region:CopyMusic()

-- Paste top contents to the bottom staff
top_region.StartStaff = bottom_staff
top_region.EndStaff = bottom_staff
top_region:PasteMusic()

-- Paste bottom contents to the top staff
bottom_region.StartStaff = top_staff
bottom_region.EndStaff = top_staff
bottom_region:PasteMusic()

-- Release the clip files
top_region:ReleaseMusic()
bottom_region:ReleaseMusic()

-- Make sure the original region is visually restored
region:SetInDocument()
