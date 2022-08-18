export const removeComments = (contents: string): string => {
    return contents
        .replace(/--\[\[[^\]]*\]\]/giu, '')
        .replace(/--.*$/gimu, '')
        .replace(/\n\n+/gimu, '\n')
        .replace(/ *$/gimu, '')
}
