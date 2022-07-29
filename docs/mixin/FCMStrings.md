# FCMStrings

Summary of modifications:
- Methods that accept `FCString` now also accept Lua `string` and `number` (except for folder loading methods which do not accept `number`).
- Setters that accept `FCStrings` now also accept multiple arguments of `FCString`, Lua `string`, or `number`.

## Functions

- [AddCopy(self, str)](#addcopy)
- [AddCopies(self)](#addcopies)
- [CopyFrom(self)](#copyfrom)
- [Find(self, str)](#find)
- [FindNocase(self, str)](#findnocase)
- [LoadFolderFiles(self, folderstring)](#loadfolderfiles)
- [LoadSubfolders(self, folderstring)](#loadsubfolders)
- [InsertStringAt(self, str, index)](#insertstringat)

### AddCopy

```lua
fcmstrings.AddCopy(self, str)
```

**[Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `str` | `FCString\|string\|number` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | True on success. |

### AddCopies

```lua
fcmstrings.AddCopies(self)
```

**[Override]**
Same as `AddCopy`, but accepts multiple arguments so that multiple strings can be added at a time.

@ ... (FCStrings|FCString|string|number) `number`s will be cast to `string`

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if successful |

### CopyFrom

```lua
fcmstrings.CopyFrom(self)
```

**[Override]**
Accepts multiple arguments.

@ ... (FCStrings|FCString|string|number) `number`s will be cast to `string`

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if successful |

### Find

```lua
fcmstrings.Find(self, str)
```

**[Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `str` | `FCString\|string\|number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMString\\|nil` |  |

### FindNocase

```lua
fcmstrings.FindNocase(self, str)
```

**[Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `str` | `FCString\|string\|number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCMString\\|nil` |  |

### LoadFolderFiles

```lua
fcmstrings.LoadFolderFiles(self, folderstring)
```

**[Override]**
Accepts Lua `string` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `folderstring` | `FCString\|string` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | True on success. |

### LoadSubfolders

```lua
fcmstrings.LoadSubfolders(self, folderstring)
```

**[Override]**
Accepts Lua `string` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `folderstring` | `FCString\|string` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | True on success. |

### InsertStringAt

```lua
fcmstrings.InsertStringAt(self, str, index)
```

**[>= v0.59] [Fluid] [Override]**
Accepts Lua `string` and `number` in addition to `FCString`.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `self` | `FCMStrings` |  |
| `str` | `FCString\|string\|number` |  |
| `index` | `number` |  |
