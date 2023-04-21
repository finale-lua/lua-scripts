import { injectExtras } from './inject-extras';

describe('injectExtras', () => {
    it('should inject the HashURL string into the contents', () => {
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

    it('should inject the HashURL string into the contents', () => {
        const name = 'test.lua';
        const contents = `
function plugindef()
    finaleplugin.RequireSelection = true
end

function testFunction()
    -- function definition goes here
end

return true
`;
        const expected = `
function plugindef()
    finaleplugin.RequireSelection = true
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

    it('should inject the HashURL string into the contents', () => {
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
