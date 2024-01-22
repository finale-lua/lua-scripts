export const requireRegex = new RegExp([
    /(?:^|[\W])/, // Begin at either the start of a line or the start of an identifier
    /(?:__original_)?require/, // Match require or __original_require (introduced in RGPLua 0.64)
    /[\s]*/, // Any number of whitespace characters are allowed between a function name and its arguments
    // Module. Match one single- or double-quoted string, optionally enclosed in parentheses, capturing only its contents
    /(?:"([\w.]+?)"|'([\w.]+?)'|\("([\w.]+?)"\)|\('([\w.]+?)'\))/,
].map(r => r.source).join(''),
    'iu'); // Flags

export const getImport = (line: string): { importedFile: string; isImport: boolean } => {
    const matches = line.match(requireRegex);
    return {
        importedFile: matches ? matches[1] || matches[2] || matches[3] || matches[4] : '',
        isImport: !!matches,
    };
}

const ignoreValues: string[] = ["luaosutils", "mime.core", "cjson", "lfs"]
const commentRegex = /^\s*--/

export const getAllImports = (file: string): string[] => {
    const imports: Set<string> = new Set()
    const lines = file.split('\n')
    for (const line of lines) {
        if (!line.match(commentRegex)) {
            const { isImport, importedFile } = getImport(line)
            if (isImport && !ignoreValues.includes(importedFile))
                imports.add(importedFile)
        }
    }
    return [...imports]
}
