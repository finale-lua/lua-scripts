export const injectExtras = (name: string, contents: string): string => {
    const functionRegex = /^(\s*)function\s+plugindef/gm;
    const notesRegex = /^(\s*)finaleplugin\.Notes/gm;
    const returnRegex = /^(\s*)return/gm;
    const endRegex = /^(\s*)*end/gm;

    const functionMatch = functionRegex.exec(contents);
    if (functionMatch) {
        const functionIndex = functionMatch.index;

        const notesMatch = notesRegex.exec(contents.substring(functionIndex));
        const returnMatch = returnRegex.exec(contents.substring(functionIndex));
        const endMatch = endRegex.exec(contents.substring(functionIndex));

        const index = Math.min(
            notesMatch ? notesMatch.index : Infinity,
            returnMatch ? returnMatch.index : Infinity,
            endMatch ? endMatch.index : Infinity
        );

        const strippedName = name.split('.').slice(0, -1).join('');

        const injection = `    finaleplugin.HashURL = \"https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/${strippedName}.hash\"`;

        const injectedContents = contents.slice(0, functionIndex + index) + injection + '\n' + contents.slice(functionIndex + index);

        return injectedContents;
    }

    return contents;
}
