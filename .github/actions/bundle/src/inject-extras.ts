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

const inject = (plugindef: string, injection: string): string => {    
    if (injection) {
        const getLastIndex = (regex: RegExp): number => {
            let match, result = Infinity;
            while ((match = regex.exec(plugindef))) {
                result = match.index;
            }
            return result;
        }

        const endIndex = getLastIndex(/^(\s*)end(\s*)$/gm);
        const returnIndex = getLastIndex(/^(\s*)return/gm);        
        
        const index = Math.min(endIndex, returnIndex);
        return plugindef.slice(0, index) + injection + '\n' + plugindef.slice(index);
    } else {
        return plugindef;
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
         * 
         * We also add \sl264 \slmult1 to each paragraph to set line spacing 
         * to 110%. This works for both Mac and Win: 264 is 110% of 240, which
         * is the default font size of 12pt in twips, and \slmult1 tells RTF to          
         * interpret this as a multiple of whatever font size is currently in use.
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
            }).replace(/\\pard/g, '\\pard \\sl264 \\slmult1')

            result = `    finaleplugin.RTFNotes = [[${result}]]`;
        }        
    }

    return result;
}