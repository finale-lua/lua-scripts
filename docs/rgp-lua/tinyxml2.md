# tinyxml2

Starting with version 0.67 of _RGP Lua_, the `tinyxml2` framework is available to Lua scripts in the global namespace `tinyxml2`.

The original C++ documentation for `tinyxml2` is available here:  
[http://leethomason.github.io/tinyxml2/](http://leethomason.github.io/tinyxml2/)

That documentaion is somewhat sparse. You can get fuller explanations from [ChatGPT](https://chat.openai.com/). A question like, "What is the purpose of the processEntities and whitespaceMode parameters when contructing tinyxml2.XMLDocument?" yields quite helpful results. (However, the results are not always 100% accurate, so use them with your brain turned on.)

## API differences

The Lua implemenation differs from the original documentation as follows:

- Much as with the PDK Framework, technical limitations prevent some methods from being available in Lua.
- An example is `XMLNode::SetUserData`. Due to memory handling incompatibilities between Lua and C++ this is not implemented for Lua. You can perhaps use a parallel Lua table if you need to track user data per node.
- Many of the `Set...` or `Push...` functions use C++ overloading that is not available in Lua. For Lua, each numerical setter is named parallel to its getter. For example, the setter `XMLAttribute.SetIntAttribute` corresponds to `XMLAttribute.IntAttribute`.
- Each of the classes has a `ClassName` method added that is not in the original documentation.
- `XMLPrinter` is available for memory buffer printing only. If you need to write to a file, use `io.write` to write the `CStr` of the `XMLPrinter` to the file.
- `XMLDocument` defines `XMLDocument::Clear` as a close function with Lua 5.4+. That means you can use the Lua `<close>` keyword to specify that the document is cleared immediately on any exit path from the block in which it is defined.

```lua
local xml <close> = tinyxml2.XMLDocument()
```

- Similarly `XMLPrinter` defines `XMLPrinter::ClearBuffer` as a close function with Lua 5.4.
- The Lua constructors for `XMLDocument` and `XMLPrinter` are only available for the default values. 

C++

```c++
tinyxml2::XMLDocument doc_with_defaults;
//
tinyxml2::XMLDocument doc_with_settings(false, tinyxml2::COLLAPSE_WHITESPACE);
```

Lua:

```lua
local doc_with_defaults = tinyxml2.XMLDocument()
--
local doc_with_settings -- not currently possible
```

The latest version of the [RGP Lua Class Browser](https://github.com/finale-lua/rgplua-class-browser) provides a working example of a script that uses `tinyxml2`.

## Built-in functions for XML

When _RGP Lua_ loads the `tinyxml2` library, it also loads the following built-in functions to facilitate iterating xml.

### xmlelements(node [, nodename])

`xmlelements()` feeds a `for` loop with child elements of a node. It feeds only elements that are direct descendants of the node and does not recurse. If the optional `nodename` string is supplied, it iterates only on nodes with that name.

Example:

```lua
local xml = tinyxml2.XMLDocument()
xml:LoadFile("myxml.xml")
for element in xmlelements(xml) do
   print ("Name: ", element:Name(), "Text: ", tostring(element:GetText()))
end
```

### xmlattributes(node)

`xmlattributes()` feeds a `for` loop with the attributes of an XMLElement. If the node passed in is not convertible to an XMLElement instance, it does not do anything.

Example:

```lua
local xml = tinyxml2.XMLDocument()
xml:LoadFile("myxml.xml")
for element in xmlelements(xml) do
	for attr in xmlattributes(element) do
	   print ("Name: ", attr:Name(), "Text: ",attr:Value())
	end
end
```

### xml2table(node [, options])

`xml2table()` converts a node to a value or a Lua table. The return is as follows:

- If the input node has no value, attributes, or children, the function returns `nil`.
- If the input node has no attributes and no children, the function returns the value of the node. Otherwise it returns a table.
- If the input node has attributes, the return table includes an embedded table with the `_attr` key that contains the attributes as key/value pairs.
- If the input node has child nodes, the return table includes all the nested child nodes from recursive calls to `xml2table`.
- If the input node has a value in addition to attributes and/or child nodes, the return table includes the value with the `_value` key.

The optional `options` parameter is a table with options to modify the behavior of `xml2table`. The following options are supported:

- `stringsonly`: By default, `xml2table` converts any values it can to numbers or booleans. This option overrides that behavior (if true) and returns all values as strings.
- `boolyesno`: By default, the values `true` and `false` identify boolean values. Setting this option to true causes `xml2table` to identify booleans with `yes` and `no` instead. If `stringsonly` is true, this value is ignored.

Example:

```lua
local xml = tinyxml2.XMLDocument()
xml:LoadFile("myxml.xml")
local tab_with_typed_values = xml2table(xml)
local tab_with_string_values = xml2table(xml, { stringsonly = true })
local tab_with_yesno_bools = xml2table(xml, { boolyesno = true })
```

### table2xml(table, node [, options])

`table2xml()` embeds a Lua table inside an XMLNode. Typically this node will either be an `XMLElement` instance or an `XMLDocument` instance. If it is not an `XMLElement`, the function returns an error if the Lua table contains anything but sub-tables.

`xml2table` returns `nil` if no errors occurred or else an error message describing the error.

The goal of `table2xml` is to reverse the result of `xml2table()`, but there are some limitations.

- The order of elements in the final XML is not guaranteed. If your schema specifies an order of elements at higher levels, you can still use this function at the lower levels where order does not matter.
- If a key of `_attr` is encountered, its value must be a table. These are inserted as attributes of the element. If the value is not a table, the function returns an error message.
- If a key of `_value` is encountered, its value must be a string, a number, or a boolean. These are inserted as the text of the element. If its value is not one of those, the function returns an error message.
- If a value is a subtable and the subtable is enumerable, the subtable's members are inserted as sibling child nodes.
- If a value is a subtable and the subtable is not enumerable, the subtable itself is inserted as a child node.
- If a value is a function or a userdata item, the function returns an error message.

The optional `options` parameter is a table with options the same as for `xml2table`. However, the `stringsonly` option is unused by `table2xml`.

Example:

```lua
-- assume 'my_table' is a Lua table containing data to encode:
local xml = tinyxml2.XMLDocument()
local result = table2xml(my_table, xml)
if result then
   print(error)
else
   xml:SaveFile("myxmlout.xml")
end 	
```


