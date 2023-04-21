# FCMStrings

## Summary of Modifications
- Setters that accept `FCString` also accept a Lua `string`.
- Methods that returned a boolean to indicate success/failure now throw an error instead.
- Added polyfill for `CopyFromStringTable`.
- Added `CreateStringTable` method.

## Functions

- [AddCopy(self, str)](#addcopy)
- [AddCopies(self)](#addcopies)
- [Find(self, str)](#find)
- [FindNocase(self, str)](#findnocase)
- [LoadFolderFiles(self, folderstring)](#loadfolderfiles)
- [LoadSubfolders(self, folderstring)](#loadsubfolders)
- [LoadSymbolFonts(self)](#loadsymbolfonts)
- [LoadSystemFontNames(self)](#loadsystemfontnames)
- [InsertStringAt(self, str, index)](#insertstringat)
- [CopyFromStringTable(self, strings)](#copyfromstringtable)
- [CreateStringTable(self)](#createstringtable)

### AddCopy

```lua
fcmstrings.AddCopy(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L33)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Accepts Lua `string` and `number` in addition to `FCString`.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `str` | `FCString \| string \| number` |  |

### AddCopies

```lua
fcmstrings.AddCopies(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L47)

Same as `AddCopy`, but accepts multiple arguments so that multiple values can be added at a time.

@ ... (FCStrings | FCString | string | number) `number`s will be cast to `string`

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |

### Find

```lua
fcmstrings.Find(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L73)

**[Override]**

Override Changes:
- Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `str` | `FCString \| string \| number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMString \\| nil` |  |

### FindNocase

```lua
fcmstrings.FindNocase(self, str)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L91)

**[Override]**

Override Changes:
- Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `str` | `FCString \| string \| number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMString \\| nil` |  |

### LoadFolderFiles

```lua
fcmstrings.LoadFolderFiles(self, folderstring)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L109)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Accepts Lua `string` in addition to `FCString`.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `folderstring` | `FCString \| string` |  |

### LoadSubfolders

```lua
fcmstrings.LoadSubfolders(self, folderstring)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L127)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Accepts Lua `string` in addition to `FCString`.
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `folderstring` | `FCString \| string` |  |

### LoadSymbolFonts

```lua
fcmstrings.LoadSymbolFonts(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L143)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |

### LoadSystemFontNames

```lua
fcmstrings.LoadSystemFontNames(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L157)

**[Breaking Change] [Fluid] [Override]**

Override Changes:
- Throws an error instead of returning a boolean for success/failure.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |

### InsertStringAt

```lua
fcmstrings.InsertStringAt(self, str, index)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L174)

**[>= v0.59] [Fluid] [Override]**

Override Changes:
- Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `str` | `FCString \| string \| number` |  |
| `index` | `number` |  |

### CopyFromStringTable

```lua
fcmstrings.CopyFromStringTable(self, strings)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L194)

**[Fluid] [Polyfill]**

Polyfills `FCStrings.CopyFromStringTable` for earlier RGP/JWLua versions.

*Note: This method can also be called statically with a non-mixin `FCStrings` object.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings \| FCStrings` |  |
| `strings` | `table` |  |

### CreateStringTable

```lua
fcmstrings.CreateStringTable(self)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/refs/heads/master/src/mixin/FCMStrings.lua#L220)

Creates a table of Lua `string`s from the `FCString`s in this collection.

*Note: This method can also be called statically with a non-mixin `FCStrings` object.*

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings \| FCStrings` |  |

| Return type | Description |
| ----------- | ----------- |
| `table` |  |
