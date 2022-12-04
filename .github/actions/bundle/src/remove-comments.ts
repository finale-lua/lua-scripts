export const removeComments = (contents: string): string => {
    return contents
        .replace(/--\[\[[\s\S]*?\]\]/giu, '')
        .replace(/(?<!")--.*$/gimu, '')
        .replace(/\n\n+/gimu, '\n')
        .replace(/ *$/gimu, '')
}
