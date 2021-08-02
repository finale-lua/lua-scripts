# Style guide

1. [Introduction](#introduction)
2. [JW Lua](#jw-lua)
3. [Functions](#functions)
   1. [Run Functions](#run-functions)
   2. [Helper Functions](#helper-functions)
4. [Readability](#readability)
   1. [Line breaks and whitespace](#line-breaks-and-whitespace)
   2. [Indentation and Tab Size](#indentation-and-tab-size)
   3. [Spaces](#spaces)
   4. [Parenthesis](#parenthesis)
   5. [Quotations](#quotations)
   6. [Variables](#variables)
5. [Automated Styling with VS Code Linter](#automated-styling-with-vs-code-linter)
6. [Outro](#outro)

## Introduction

Hello, my name is CJ and I’m here to run you through some of the nitty-gritty of the preferred syntax I and my colleagues who develop for the JetStream Finale Controller project use. Knowing how to install and write code with JW Lua as well as being familiar with it’s classes is a prerequisite to this style guide and will not be covered. However, feel free to post in our JW Lua Facebook group if you have
any questions at all.

First off, and very importantly, I am a music composition major working as an engraver who’s only formal training in programming was three computer science courses in Python at Rice University via Coursera. Everything else has been learned through dissecting existing code and spending too many hours on stackoverflow.com. This document is intended to provide consistency in public JW Lua script development, it is not a reflection of best practices in the language of lua or a way to learn them. I am still learning, and will continue to learn.

Secondly, nobody’s perfect and I am constantly refactoring my own code to make it consistent with the syntax explained in this document. This is a living document and will be changed and updated as we go. I am malleable on the stances taken here, however, I will always weigh the cost of refactoring time. What started off as an interest in saving time and a fun little project between Robert Puff and myself has grown quite a bit with interest in JW Lua. Though the bottom line is if your code works, your code works, however folks who write code generally do like consistency and these will be some explicit instructions for consistency sake when committing your code to the public JW Lua Git Repository set up by Nick Mazuk.

Thirdly, for what it’s worth, I’m writing all of the code in Visual Studio Code with this Lua extension. I am using the Code Blocks chrome extension for this document with “gruvbox-dark” as the theme.

## JW Lua

JW Lua is a framework created by Jari Williamson for use in Finale. Since a PDK (Plug-in Developers Kit) is not publicly available for Finale. Jari, being one of the three remaining plug-in developers who owns the PDK, decided to essentially make his own wrapper for the PDK with a much more lightweight and simpler language: lua. JW Lua is a plug-in that creates plug-ins.

## Functions

All functions should be written in snake_case. This is a personal preference for two reasons: 1) I want to be able to distinguish what code that I or other people have written compared against JW Lua’s built in classes, methods, and properties, all of which use CamelCase and 2) I personally think it’s easier to read.

### Run Functions

Though not always necessary in a script, I just want to talk about a little bit of this philosophy if you choose to use Run and Helper functions. The purpose of a Run function is to provide a single execution point of a script. Run functions do not pass any arguments, that is a job reserved for the helper functions. It is also
important that run functions be global, they should never be local. Variables and other functions within your scripts should absolutely be local variables, but run functions must remain global.

Naming a run function should follow the structure of Macro -> micro.

Example: `dynamics_ffff_start()`

We begin by asking “What is the most macro thing about this function?” In most cases, this will be something in the JW Lua Development tab > Plug-in def… > “Category Tags”. In this specific case, it’s “dynamics”. Next we ask “what dynamic am I working with?” In this case it’s the ffff expression . Then we ask “what action is happening with this dynamic?” In this case we are placing it at the start of the
region.

So all together this run function name goes from category > what > action and that is how we get to `dynamics_ffff_start()`.

### Helper Functions

Helper functions are more standard: they can pass arguments, more than one can be used inside a run function, and most importantly, they should be written in a way that they could be used in other run functions - the principle of having DRY (Don’t Repeat Yourself) code is very important. Here is an example of the helper functions from the dynamics_ffff_start() run function.

```lua
function dynamics_ffff_start()
    find_dynamic({235}, first_expression, "fortissississimo (velocity = 127)")
    dynamic_region("Start")
end
```

The helper function naming syntax is less rigorous. Though it should be descriptive, it does not have to follow the Macro -> micro structure. In this example, there are two helper functions: `find_dynamic()` and `dynamic_region()`. Both of these helper functions are used in most of the dynamic category and pass arguments that make this possible. Below is the `find_dynamic()` helper function:

```lua
function find_dynamic(glyph_nums, table_name, description_text)
    local matching_glyphs = {}
    local exp_defs = finale.FCTextExpressionDefs()
    local exp_def = finale.FCTextExpressionDef()
    exp_defs:LoadAll()
    for exp in each(exp_defs) do
        local glyph_length = 0
        local exp_string = finale.FCString()
        exp_string.LuaString = ""
        for key, value in pairs(glyph_nums) do
            exp_string:AppendCharacter(value)
            glyph_length = glyph_length + 1
        end
        local current_string = exp:CreateTextString()
        current_string:TrimEnigmaTags()
        if glyph_length > 1 then
            if (current_string:GetCharacterAt(-1) == glyph_nums[2]) and
                (current_string:GetCharacterAt(0) == glyph_nums[1]) then
                table.insert(matching_glyphs, exp:GetItemNo())
            end
        else
            if current_string:GetCharacterAt(0) == glyph_nums[1] then
                table.insert(matching_glyphs, exp:GetItemNo())
            end
        end
    end
    if matching_glyphs[1] == nil then
        create_dynamic(glyph_nums, table_name, description_text)
    else
        exp_def:Load(matching_glyphs[1])
        table.insert(table_name, exp_def:GetItemNo())
    end
end
```

## Readability

Reading code should be like reading a book in my opinion. Let’s look at a few items within this function and other code that increase readability.

### Line breaks and whitespace

It should go without saying that after every declaration, a line break should occur. And generally, the less whitespace the better. However, I’ve been known to separate my loops and variables with an empty line between the two or between the end of one loop and the beginning of another. However, when loops within loops begin to occur, this can start to look ugly really quick, so I’ve tried to eliminate whitespace within functions. Whitespace should, however, exist between two functions regardless of context.

### Indentation and Tab Size

Though technically unnecessary for lua to execute correctly, I do like to adapt a bit of Python-esque syntax: I use indentation within functions and loops, and that indentation is set to be 4 (four) spaces. In VS Code, you can change the tab amount settings under File > Preferences > Settings and then search for “Tab Size”. The reason for 4 spaces is to match the “Development” tab in JW Lua so that copying and pasting between the two for testing doesn’t require reformatting the code.

### Spaces

Again, reading code is much easier when it is close to reading normal text (such as this). You’ll see spaces in the following examples:

- Either side of an equals sign and other operators
  - `local matching_glyphs = {}`
  - `matching_glyphs[1] == nil`
  - `glyph_length > 1`
- Either side of parentheses in boolean arguments with more than 1 test
  - `if ((current_string:GetCharacterAt(-1) == glyph_nums[2]) and (current_string:GetCharacterAt(0) == glyph_nums[1])) then)`
- Either side of boolean tests
  - `if matching_glyphs[1] == nil then`
- Between commas in lists, function arguments/parameters, and elsewhere.
  - `find_dynamic(glyph_nums, table_name, description_text)`
  - `table.insert(matching_glyphs, exp:GetItemNo())`
  - `local dyn_char = {150, 175, 184, 185, 112, 80, 70, 102, 196, 236}`

### Parenthesis

- Boolean tests with only a single test do not need parenthesis
  - `if matching_glyphs[1] == nil then`
- However, if more than one test is present, then parenthesis will be needed around each individual test:
  - `if (current_string:GetCharacterAt(-1) == glyph_nums[2]) and`
  - `(current_string:GetCharacterAt(0) == glyph_nums[1]) then`

### Quotations

- Another small break from what I see a lot is that I prefer double quotes (“) for wrapping strings instead of single quotes. Again, this comes from my hard-coded way of reading books instead of code first: the beginning of a quote or dialog always begins with double quotes, then quotes within quotes use single quotes.
  - `if direction_type == "far" then`

### Variables

While inside a helper function, variables are the most flexible of our syntax. As usual, if they use more than one word, then again, use snake_case and they  should generally be local variables.

- No acronyms in variable or function names.
  - It’s better to have a long name than it is to have an undecipherable
acronym for a shorter name.
    - When working on playback scripts, I had started off with hideous acronyms: `playback_AS_DB_RE()`. Any reasonable person would and frankly shouldn’t have any idea what that means. Though shorter and cleaner, it is not clear what that functionality is. Instead, the function name should be `playback_all_staves_from_document_beginning_to_region_end()`. Though longer, it reads easily and describes explicitly what is going to happen.
    - EVPU and ID are the only acronyms that are okay to have in a function or variable name
  - Abbreviations are okay for function and variable names
    - JW Lua already uses abbreviations across multiple classes for
methods and parameters
      - `notehead_mod:GetVerticalPos()`
    - It is also okay for variable name
      - `local str = finale.FCString()`
- No single character variable names
  - The exception I’m willing to make in this rule is when looping through a table while looping through another table. The first table should absolutely use snake_case, but the other table is allowed to have single character variable names.
  - If you have more than two loops, then the innermost loop should be the only one with single character variable names.

```lua
for key, value in pairs(first_table) do
    for k, v in pairs(value) do
        print(v)
    end
end
```

- Numbers in variable names
  - Again, not technically necessary for a successful run of the code, it is just a personal syntax choice. Numbers, in my opinion, should be reserved for indexing and calculations
  - `harmonics_touch_4()` should instead be written out as `harmonics_touch_four()`

## Automated Styling with VS Code Linter

If you'd like to take care of many of these style preferences automatically, consider using the VS Code extension [lua-linter](https://marketplace.visualstudio.com/items?itemName=dcr30.lualinter).

There are three quick steps:

1. Install the [lua-linter](https://marketplace.visualstudio.com/items?itemName=dcr30.lualinter) extension
2. Install `luac` if you haven't already
   1. On Mac with Homebrew: `brew install lua`
   2. Else: https://www.lua.org/download.html
3. Ensure the `luaconfig.config` file in this repo is in the same folder you are editing the Lua script in. If you are editing in this repo, the `luaconfig.config` file is included automatically.
4. Make sure the preference "Format on Save" is enabled in VS Code.

This linter will take care of these things every time you save a file:

- Spacing (white space)
- Double quotations
- Table styling
- And more

It will not correct any variable or function names.

## Outro

Thanks again for your interest in JW Lua. If you feel as if there’s anything missing in this guide or have any questions, comments, or concerns, feel free to reach out to me (CJ Garcia - CJGarciaMusic@gmail.com) or if you want help with your code please post to the [JW Lua Facebook group](https://www.facebook.com/groups/742277119576336) where many other talented folks will happily help guide your way.
