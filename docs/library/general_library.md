# Library

## Functions

- [group_overlaps_region(staff_group, region)](#group_overlaps_region)
- [group_is_contained_in_region(staff_group, region)](#group_is_contained_in_region)
- [staff_group_is_multistaff_instrument(staff_group)](#staff_group_is_multistaff_instrument)
- [get_selected_region_or_whole_doc()](#get_selected_region_or_whole_doc)
- [get_first_cell_on_or_after_page(page_num)](#get_first_cell_on_or_after_page)
- [get_top_left_visible_cell()](#get_top_left_visible_cell)
- [get_top_left_selected_or_visible_cell()](#get_top_left_selected_or_visible_cell)
- [is_default_measure_number_visible_on_cell(meas_num_region, cell, staff_system, current_is_part)](#is_default_measure_number_visible_on_cell)
- [is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)](#is_default_number_visible_and_left_aligned)
- [update_layout(from_page, unfreeze_measures)](#update_layout)
- [get_current_part()](#get_current_part)
- [get_page_format_prefs()](#get_page_format_prefs)
- [get_smufl_font_list()](#get_smufl_font_list)
- [get_smufl_metadata_file(font_info)](#get_smufl_metadata_file)
- [is_font_smufl_font(font_info)](#is_font_smufl_font)
- [simple_input(title, text)](#simple_input)
- [is_finale_object(object)](#is_finale_object)
- [system_indent_set_to_prefs(system, page_format_prefs)](#system_indent_set_to_prefs)
- [calc_script_name(include_extension)](#calc_script_name)

### group_overlaps_region

```lua
library.group_overlaps_region(staff_group, region)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L17)

Returns true if the input staff group overlaps with the input music region, otherwise false.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `staff_group` | `FCGroup` |  |
| `region` | `FCMusicRegion` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### group_is_contained_in_region

```lua
library.group_is_contained_in_region(staff_group, region)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L49)

Returns true if the entire input staff group is contained within the input music region.
If the start or end staff are not visible in the region, it returns false.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `staff_group` | `FCGroup` |  |
| `region` | `FCMusicRegion` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### staff_group_is_multistaff_instrument

```lua
library.staff_group_is_multistaff_instrument(staff_group)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L67)

Returns true if the entire input staff group is a multistaff instrument.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `staff_group` | `FCGroup` |  |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### get_selected_region_or_whole_doc

```lua
library.get_selected_region_or_whole_doc()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L86)

Returns a region that contains the selected region if there is a selection or the whole document if there isn't.
SIDE-EFFECT WARNING: If there is no selected region, this function also changes finenv.Region() to the whole document.

| Return type | Description |
| ----------- | ----------- |
| `FCMusicRegion` |  |

### get_first_cell_on_or_after_page

```lua
library.get_first_cell_on_or_after_page(page_num)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L102)

Returns the first FCCell at the top of the input page. If the page is blank, it returns the first cell after the input page.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `page_num` | `number` |  |

| Return type | Description |
| ----------- | ----------- |
| `FCCell` |  |

### get_top_left_visible_cell

```lua
library.get_top_left_visible_cell()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L132)

Returns the topmost, leftmost visible FCCell on the screen, or the closest possible estimate of it.

| Return type | Description |
| ----------- | ----------- |
| `FCCell` |  |

### get_top_left_selected_or_visible_cell

```lua
library.get_top_left_selected_or_visible_cell()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L149)

If there is a selection, returns the topmost, leftmost cell in the selected region.
Otherwise returns the best estimate for the topmost, leftmost currently visible cell.

| Return type | Description |
| ----------- | ----------- |
| `FCCell` |  |

### is_default_measure_number_visible_on_cell

```lua
library.is_default_measure_number_visible_on_cell(meas_num_region, cell, staff_system, current_is_part)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L168)

Returns true if measure numbers for the input region are visible on the input cell for the staff system.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `meas_num_region` | `FCMeasureNumberRegion` |  |
| `cell` | `FCCell` |  |
| `staff_system` | `FCStaffSystem` |  |
| `current_is_part` | `boolean` | true if the current view is a linked part, otherwise false |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### is_default_number_visible_and_left_aligned

```lua
library.is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L197)

Returns true if measure number for the input cell is visible and left-aligned.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `meas_num_region` | `FCMeasureNumberRegion` |  |
| `cell` | `FCCell` |  |
| `system` | `FCStaffSystem` |  |
| `current_is_part` | `boolean` | true if the current view is a linked part, otherwise false |
| `is_for_multimeasure_rest` | `boolean` | true if the current cell starts a multimeasure rest |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### update_layout

```lua
library.update_layout(from_page, unfreeze_measures)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L231)

Updates the page layout.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `from_page` (optional) | `number` | page to update from, defaults to 1 |
| `unfreeze_measures` (optional) | `boolean` | defaults to false |

### get_current_part

```lua
library.get_current_part()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L247)

Returns the currently selected part or score.

| Return type | Description |
| ----------- | ----------- |
| `FCPart` |  |

### get_page_format_prefs

```lua
library.get_page_format_prefs()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L260)

Returns the default page format prefs for score or parts based on which is currently selected.

| Return type | Description |
| ----------- | ----------- |
| `FCPageFormatPrefs` |  |

### get_smufl_font_list

```lua
library.get_smufl_font_list()
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L302)

Returns table of installed SMuFL font names by searching the directory that contains
the .json files for each font. The table is in the format:

```lua
<font-name> = "user" | "system"
```

| Return type | Description |
| ----------- | ----------- |
| `table` | an table with SMuFL font names as keys and values "user" or "system" |

### get_smufl_metadata_file

```lua
library.get_smufl_metadata_file(font_info)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L341)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `font_info` (optional) | `FCFontInfo` | if non-nil, the font to search for; if nil, search for the Default Music Font |

| Return type | Description |
| ----------- | ----------- |
| `file handle\\|nil` |  |

### is_font_smufl_font

```lua
library.is_font_smufl_font(font_info)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L366)

| Input | Type | Description |
| ----- | ---- | ----------- |
| `font_info` (optional) | `FCFontInfo` | if non-nil, the font to check; if nil, check the Default Music Font |

| Return type | Description |
| ----------- | ----------- |
| `boolean` |  |

### simple_input

```lua
library.simple_input(title, text)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L395)

Creates a simple dialog box with a single 'edit' field for entering values into a script, similar to the old UserValueInput command. Will automatically resize the width to accomodate longer strings.

: string

| Input | Type | Description |
| ----- | ---- | ----------- |
| `title` (optional) | `string` | the title of the input dialog box |
| `text` (optional) | `string` | descriptive text above the edit field |

### is_finale_object

```lua
library.is_finale_object(object)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L448)

Attempts to determine if an object is a Finale object through ducktyping

| Input | Type | Description |
| ----- | ---- | ----------- |
| `object` | `__FCBase` |  |

| Return type | Description |
| ----------- | ----------- |
| `bool` |  |

### system_indent_set_to_prefs

```lua
library.system_indent_set_to_prefs(system, page_format_prefs)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L463)

Sets the system to match the indentation in the page preferences currently in effect. (For score or part.)
The page preferences may be provided optionally to avoid loading them for each call.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `system` | `FCStaffSystem` |  |
| `page_format_prefs` (optional) | `FCPageFormatPrefs` | page format preferences to use, if supplied. |

| Return type | Description |
| ----------- | ----------- |
| `boolean` | `true` if the system was successfully updated. |

### calc_script_name

```lua
library.calc_script_name(include_extension)
```

[View source](https://github.com/finale-lua/lua-scripts/tree/master/src/library/general_library.lua#L488)

Returns the running script name, with or without extension.

| Input | Type | Description |
| ----- | ---- | ----------- |
| `include_extension` (optional) | `boolean` | Whether to include the file extension in the return value: `false` if omitted |

| Return type | Description |
| ----------- | ----------- |
| `string` | The name of the current running script. |
