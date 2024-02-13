import { spawnSync } from 'child_process'
import { format } from 'date-fns'

const plugindefRegex = /^function\s+plugindef.*?^end/ms;
const luaProlog = 'finaleplugin = {}'
const luaParserScript = `
    local json = require ('lunajson')
    local function stringify(s) return tostring(s or '') end

    local name, undo_text, short_description = plugindef()
    local result = { 
        name = stringify(name), 
        undoText = stringify(undo_text),
        shortDescription = stringify(short_description),
        author = {
            name = stringify(finaleplugin.Author),
            email = stringify(finaleplugin.AuthorEmail),
            website = stringify(finaleplugin.AuthorURL)
        },
        scriptGroupName = stringify(finaleplugin.ScriptGroupName),
        scriptGroupDescription = stringify(finaleplugin.ScriptGroupDescription),
        version = stringify(finaleplugin.Version),
        copyright = stringify(finaleplugin.Copyright),
        id = stringify(finaleplugin.Id),
        minJWLuaVersion = stringify(finaleplugin.MinJWLuaVersion),
        maxJWLuaVersion = stringify(finaleplugin.MaxJWLuaVersion),
        minFinaleVersion = stringify(finaleplugin.MinFinaleVersion),
        maxFinaleVersion = stringify(finaleplugin.MaxFinaleVersion),
        categories = stringify(finaleplugin.CategoryTags),
        date = stringify(finaleplugin.Date),
        requireScore = finaleplugin.RequireScore or false,
        requireSelection = finaleplugin.RequireSelection or false,
        noStore = finaleplugin.NoStore or false,
        notes = stringify(finaleplugin.Notes),
        revisionNotes = stringify(finaleplugin.RevisionNotes),
        menuItems = stringify(finaleplugin.AdditionalMenuOptions),
    }
    print(json.encode(result))
`
const toArray = (input: string) => {
    input = input.trim()
    if (input === '') 
        return []
    else
        return input.split('\n').map(s => s.trim())
}

// Make sure that Max/MinJWLuaVersion is a string with two decimals
const twoDecimals = (input: string) => {
    return input ? Number.parseFloat(input).toFixed(2) : input
}


export const parseMetadata = (contents: string): any => {
    const plugindefMatch = contents.match(plugindefRegex)
    if (plugindefMatch) {
        const plugindef = plugindefMatch[0].replace(/^[ \t]+/gm, '')
        const args = [ '-e', `${luaProlog} ${plugindef} ${luaParserScript}` ]
        const result = spawnSync('lua', args);

        if (!result.error) {
            const md = JSON.parse(result.stdout.toString())

            // comma or space delimited string to array
            md.categories = md.categories == ''
                ? []
                : md.categories.split(/[, ]+/)

            if (md.date != '')
                md.date = format(new Date(md.date), 'yyyy-MM-dd')

            md.minJWLuaVersion = twoDecimals(md.minJWLuaVersion)
            md.maxJWLuaVersion = twoDecimals(md.maxJWLuaVersion)
            md.notes = md.notes.trim()
            md.revisionNotes = toArray(md.revisionNotes)
            md.menuItems = toArray(md.menuItems)   
            md.menuItems.push(md.name)

            // use group attributes if appropriate
            if (md.menuItems.length > 1) {
                if (md.scriptGroupName)
                    md.name = md.scriptGroupName
                if (md.scriptGroupDescription)
                  md.shortDescription = md.scriptGroupDescription
            }

            md.menuItems = md.menuItems.sort()
            return md;
        }
    }

    return null
}
