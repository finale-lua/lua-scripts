import type { Library } from './bundle'
import { bundleFile } from './bundle'

const library: Library = {
    articulation: {
        contents: `--[[
$module Articulation
]]
local BUNDLED_LIBRARY_VARIABLE_NAME = {}
function BUNDLED_LIBRARY_VARIABLE_NAME.method()
end`,
    },
    expression: {
        contents: `--[[
$module Articulation
]]
local BUNDLED_LIBRARY_VARIABLE_NAME = {}
function BUNDLED_LIBRARY_VARIABLE_NAME.method()
  -- does something
end`,
    },
}

it('bundles library if library exists', () => {
    const file = `
local library = require("library.articulation")
`

    const output = `
--[[
$module Articulation
]]
local library = {}
function library.method()
end
`
    expect(bundleFile(file, library)).toEqual(output)
})

it('works with multiple imports', () => {
    const file = `
local articulation = require("library.articulation")
local expression = require("library.expression")
`

    const output = `
--[[
$module Articulation
]]
local articulation = {}
function articulation.method()
end
--[[
$module Articulation
]]
local expression = {}
function expression.method()
  -- does something
end
`
    expect(bundleFile(file, library)).toEqual(output)
})
