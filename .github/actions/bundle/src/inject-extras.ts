import { getFileParts } from './helpers'
import { spawnSync } from 'child_process';
import dedent from 'dedent-js';
import path from 'path';

export const injectExtras = (name: string, contents: string): string => {
    const parts = getFileParts(contents);

    if (parts.plugindef) {
        if (!parts.plugindef.includes('finaleplugin.RTFNotes'))
            parts.plugindef = inject(parts.plugindef, getRTFNotes(parts.plugindef));
        parts.plugindef = inject(parts.plugindef, getHashURL(name));
    }
    
    return parts.prolog + parts.plugindef + parts.epilog;
}

const inject = (contents: string, injection: string): string => {
    if (injection) {
        const returnRegex = /^(\s*)return/gm;
        const endRegex = /^(\s*)*end/gm;

        const returnMatch = returnRegex.exec(contents);
        const endMatch = endRegex.exec(contents);

        const index = Math.min(
            returnMatch ? returnMatch.index : Infinity,
            endMatch ? endMatch.index : Infinity
        );
        return contents.slice(0, index) + injection + '\n' + contents.slice(index);
    } else {
        return contents;
    }
}

const getHashURL = (name: string): string => {
    const strippedName = name.split('.').slice(0, -1).join('');
    return `    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/${strippedName}.hash"`;
}

const getRTFNotes = (input: string): string => {    
    let result = '';

    const notesRegex = /(?<=finaleplugin.Notes = \[\[).*(?=\]\])/ius;
    const match = input.match(notesRegex);

    if (match) {
        const notes = dedent(match[0]);
        const templateFile = path.join(__dirname, "custom_template.rtf");
        const args = [ '-f', 'markdown', '-t', 'rtf', '-s', `--template=${templateFile}` ];
        const pandocResult = spawnSync('pandoc', args, { input: notes, encoding: 'utf-8'});
        if (!pandocResult.error) {
            result = pandocResult.stdout.replace(/fs28/g, 'fs24')
                .replace(/fs32/g, 'fs28')
                .replace(/fs36/g, 'fs32');
            result = `    finaleplugin.RTFNotes = [[${result}]]`;
        }        
    }

    return result;
}