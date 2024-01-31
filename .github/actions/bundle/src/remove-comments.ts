export const removeComments = (contents: string, trimWhitespace: boolean): string => {
    let result = contents
        .replace(/--\[\[[\s\S]*?\]\]/giu, '')
        .replace(/(?<!")--.*$/gimu, '');
    if (trimWhitespace) {
        result = result
            .replace(/\n\n+/gimu, '\n')
            .replace(/ *$/gimu, '');
    }        
    return result;
}
