--  Author: Edward Koltun
--  Date: April 13, 2021
--[[
$module Page Size

A library for determining page sizes.
]] --
local page_size = {}
local utils = require("library.utils")

-- Dimensions must be in EVPUs and in portrait (ie width is always the shorter side)
local sizes = {}

-- Finale's standard sizes
sizes.A3 = {width = 3366, height = 4761}
sizes.A4 = {width = 2381, height = 3368}
sizes.A5 = {width = 1678, height = 2380}
sizes.B4 = {width = 2920, height = 4127}
sizes.B5 = {width = 1994, height = 2834}
sizes.Concert = {width = 2592, height = 3456}
sizes.Executive = {width = 2160, height = 2880}
sizes.Folio = {width = 2448, height = 3744}
sizes.Hymn = {width = 1656, height = 2376}
sizes.Legal = {width = 2448, height = 4032}
sizes.Letter = {width = 2448, height = 3168}
sizes.Octavo = {width = 1944, height = 3024}
sizes.Quarto = {width = 2448, height = 3110}
sizes.Statement = {width = 1584, height = 2448}
sizes.Tabloid = {width = 3168, height = 4896}

-- Other sizes

--[[
% get_dimensions

Returns the dimensions of the requested page size. Dimensions are in portrait.

@ size (string) The page size.
: (table) Has keys `width` and `height` which contain the dimensions in EVPUs.
]]
function page_size.get_dimensions(size)
    return utils.copy_table(sizes[size])
end

--[[
% is_size

Checks if the given size is defined.

@ size (string)
: (boolean) `true` if defined, `false` if not
]]
function page_size.is_size(size)
    return sizes[size] and true or false
end

--[[
% get_size

Determines the page size based on the given dimensions.

@ width (number) Page width in EVPUs.
@ height (number) Page height in EVPUs.
: (string|nil) Page size, or `nil` if no match.
]]
function page_size.get_size(width, height)
    -- If landscape, swap to portrait
    if height < width then
        local temp = height
        height = width
        width = temp
    end

    for size, dimensions in pairs(sizes) do
        if dimensions.width == width and dimensions.height == height then
            return size
        end
    end

    return nil
end

--[[
% get_page_size

Determines the page size of an `FCPage`.

@ page (FCPage)
: (string|nil) Page size, or `nil` if no match.
]]
function page_size.get_page_size(page)
    return page_size.get_size(page.Width, page.Height)
end

--[[
% set_page_size

Sets the dimensions of an `FCPage` to the given size. The existing page orientation will be preserved.

@ page (FCPage)
@ size (string)
]]
function page_size.set_page_size(page, size)
    if not sizes[size] then
        return
    end

    if page:IsPortrait() then
        page:SetWidth(sizes[size].width)
        page:SetHeight(sizes[size].height)
    else
        page:SetWidth(sizes[size].height)
        page:SetHeight(sizes[size].width)
    end
end

--[[
% pairs

Return an alphabetical order iterator that yields the following pairs:
`(string) size`
`(table) dimensions` => has keys `width` and `height` which contain the dimensions in EVPUs

: (function)
]]
local sizes_index
function page_size.pairs()
    if not sizes_index then
        sizes_index = {}
        for size in pairs(sizes) do
            table.insert(sizes_index, size)
        end

        table.sort(sizes_index)
    end

    local i = 0
    local iterator = function()
        i = i + 1
        if sizes_index[i] == nil then
            return nil
        else
            return sizes_index[i], sizes[sizes_index[i]]
        end
    end

    return iterator
end

return page_size
