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

    const notesRegex = /(?<=finaleplugin.Notes = \[\[).*?(?=\]\])/ius;
    const match = input.match(notesRegex);

    if (match) {
        let notes = dedent(match[0]);
        notes = notes.replace(/^#{4,}/gm, '###')
        const templateFile = path.join(__dirname, "custom_template.rtf");
        
        /**
         * Default font sizes are:
         *         p   h1  h2  h3
         * pandoc  24  36  32  28
         * win     18  26  23  20
         * mac     24  32  29  26
         * 
         * The win p size is injected as a variable into the call to pandoc, and the 
         * other win sizes are replaced below. The mac sizes are injected, as a JSON
         * fragment, into the RTF comment field; utils.show_notes_dialog() can use
         * this to perform replacements.
         */
        const args = `
            -f markdown 
            -t rtf 
            --standalone 
            --template=${templateFile}
            -V basefont=fs18
            -V fontsizes="os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"
        `.trim().split(/\s+/);
        const pandocResult = spawnSync('pandoc', args, { input: notes, encoding: 'utf-8'});
        if (!pandocResult.error) {
            result = pandocResult.stdout.replace(/(?<=\\)fs\d\d/g, function(match: string) {
                switch(match) {
                    case 'fs36': return 'fs26';
                    case 'fs32': return 'fs23';
                    case 'fs28': return 'fs20';
                    default: return match;
                }
            })
            result = `    finaleplugin.RTFNotes = [[${result}]]`;
        }        
    }

    return result;
}