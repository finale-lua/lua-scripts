import { injectExtras } from './inject-extras';

/**
 * Note: These tests don't pass on Windows, not entirely sure why.
 * But there are other tests in this package that don't pass on Windows either!
 * 
 * Also note that pandoc output is slightly different between Windows and Linux.
 * On Win, Headings include an \outlinelevel tag; this doesn't seem to be important.
 */

describe('injectExtras', () => {
    it('should inject HashURL and RTFNotes into the contents (with return)', () => {
        const name = 'test.lua';
        const contents = `
function plugindef()
    -- plugin definition goes here
    finaleplugin.Notes = [[
        # Header 1
    ]]
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;
        const expected = `
function plugindef()
    -- plugin definition goes here
    finaleplugin.Notes = [[
        # Header 1
    ]]
    finaleplugin.RTFNotes = [[
        {\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 \\fswiss Helvetica;}{\\f1 \\fmodern Courier New;}}
        {\\colortbl;\\red255\\green0\\blue0;\\red0\\green0\\blue255;}
        \\widowctrl\\hyphauto
        \\fs18
        {\\info{\\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 \\b \\fs26 Header 1\\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/test.hash"
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;

        const result = injectExtras(name, contents);

        expect(result).toEqual(expected);
    });

    it('should inject HashURL and RTFNotes into the contents (with items after)', () => {
        const name = 'test.lua';
        const contents = `
function plugindef()
    -- plugin definition goes here
    finaleplugin.Notes = [[
        # Header 1
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Unbeam Selected Region
    ]]
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;
        const expected = `
function plugindef()
    -- plugin definition goes here
    finaleplugin.Notes = [[
        # Header 1
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Unbeam Selected Region
    ]]
    finaleplugin.RTFNotes = [[
        {\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 \\fswiss Helvetica;}{\\f1 \\fmodern Courier New;}}
        {\\colortbl;\\red255\\green0\\blue0;\\red0\\green0\\blue255;}
        \\widowctrl\\hyphauto
        \\fs18
        {\\info{\\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 \\b \\fs26 Header 1\\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/test.hash"
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;

        const result = injectExtras(name, contents);

        expect(result).toEqual(expected);
    });

    it('should inject only HashURL into the contents (with return)', () => {
        const name = 'test.lua';
        const contents = `
function plugindef()
    -- plugin definition goes here
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;
        const expected = `
function plugindef()
    -- plugin definition goes here
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/test.hash"
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;

        const result = injectExtras(name, contents);

        expect(result).toEqual(expected);
    });

    it('should inject HashURL and RTFNotes into the contents (no return)', () => {
        const name = 'test.lua';
        const contents = `
function plugindef()
    finaleplugin.Notes = [[
        # Header 1
    ]]
    finaleplugin.RequireSelection = true
end

function testFunction()
    -- function definition goes here
end

return true
`;
        const expected = `
function plugindef()
    finaleplugin.Notes = [[
        # Header 1
    ]]
    finaleplugin.RequireSelection = true
    finaleplugin.RTFNotes = [[
        {\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 \\fswiss Helvetica;}{\\f1 \\fmodern Courier New;}}
        {\\colortbl;\\red255\\green0\\blue0;\\red0\\green0\\blue255;}
        \\widowctrl\\hyphauto
        \\fs18
        {\\info{\\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 \\b \\fs26 Header 1\\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/test.hash"
end

function testFunction()
    -- function definition goes here
end

return true
`;

        const result = injectExtras(name, contents);

        expect(result).toEqual(expected);
    });

    it('should inject HashURL and RTFNotes into the contents (more properties)', () => {
        const name = 'test.lua';
        const contents = `
function plugindef()
    finaleplugin.RequireSelection = true
    -- other options
    finaleplugin.Notes = [[
        This is a description of the plugin.
    ]]
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;
        const expected = `
function plugindef()
    finaleplugin.RequireSelection = true
    -- other options
    finaleplugin.Notes = [[
        This is a description of the plugin.
    ]]
    finaleplugin.RTFNotes = [[
        {\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 \\fswiss Helvetica;}{\\f1 \\fmodern Courier New;}}
        {\\colortbl;\\red255\\green0\\blue0;\\red0\\green0\\blue255;}
        \\widowctrl\\hyphauto
        \\fs18
        {\\info{\\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 This is a description of the plugin.\\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/test.hash"
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;

        const result = injectExtras(name, contents);

        expect(result).toEqual(expected);
    });

    it('should should handle complex Markdown', () => {
        const name = 'test.lua';
        const contents = `
function plugindef()
    finaleplugin.RequireSelection = true
    -- other options
    finaleplugin.Notes = [[
        # Heading one

        ## Heading two

        ### Heading three

        This is a regular paragraph with **Bold** and *Italic*.

        - Bullet 1
        - Bullet 2
        - Bullet 3

        1. Number 1
        2. Number 2
        3. Number 3

        This is a paragraph with \`inline code\`.

        \`\`\`
        function foo() {
            do_something()
        }
        \`\`\`
    ]]
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;
        const expected = `
function plugindef()
    finaleplugin.RequireSelection = true
    -- other options
    finaleplugin.Notes = [[
        # Heading one

        ## Heading two

        ### Heading three

        This is a regular paragraph with **Bold** and *Italic*.

        - Bullet 1
        - Bullet 2
        - Bullet 3

        1. Number 1
        2. Number 2
        3. Number 3

        This is a paragraph with \`inline code\`.

        \`\`\`
        function foo() {
            do_something()
        }
        \`\`\`
    ]]
    finaleplugin.RTFNotes = [[
        {\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 \\fswiss Helvetica;}{\\f1 \\fmodern Courier New;}}
        {\\colortbl;\\red255\\green0\\blue0;\\red0\\green0\\blue255;}
        \\widowctrl\\hyphauto
        \\fs18
        {\\info{\\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 \\b \\fs26 Heading one\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 \\b \\fs23 Heading two\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 \\b \\fs20 Heading three\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 This is a regular paragraph with {\\b Bold} and {\\i Italic}.\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa0 \\li360 \\fi-360 \\bullet \\tx360\\tab Bullet 1\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa0 \\li360 \\fi-360 \\bullet \\tx360\\tab Bullet 2\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa0 \\li360 \\fi-360 \\bullet \\tx360\\tab Bullet 3\\sa180\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa0 \\li360 \\fi-360 1.\\tx360\\tab Number 1\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa0 \\li360 \\fi-360 2.\\tx360\\tab Number 2\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa0 \\li360 \\fi-360 3.\\tx360\\tab Number 3\\sa180\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 This is a paragraph with {\\f1 inline code}.\\par}
        {\\pard \\sl264 \\slmult1 \\ql \\f0 \\sa180 \\li0 \\fi0 \\f1 function foo() \\{\\line
            do_something()\\line
        \\}\\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/test.hash"
    return "1", "2", "3"
end

function testFunction()
    -- function definition goes here
end

return true
`;

        const result = injectExtras(name, contents);

        expect(result).toEqual(expected);
    });

    it('should return the unaltered contents if the search criteria is not found', () => {
        const name = 'test.lua';
        const contents = `
      -- file contents go here
    `;

        const result = injectExtras(name, contents);

        expect(result).toEqual(contents);
    });
});
