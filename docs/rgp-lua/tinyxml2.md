# tinyxml2

Starting with version 0.67 of _RGP Lua_, the `tinyxml2` framework is available to Lua scripts. You enable it by setting `finaleplugin.LoadTinyXML2 = true` in your `plugindef()` function. This causes _RGP Lua_ to load the class framework into the global namespace `tinyxml2`.

The original C++ documentation for `tinyxml2` is available here:  
[http://leethomason.github.io/tinyxml2/](http://leethomason.github.io/tinyxml2/)

The Lua implemenation differs from the original documentation as follows:

- Much as with the PDK Framework, technical limitations prevent some methods from being available in Lua. Also, the `XMLVisitor` and `XMLPrinter` classes are currently unavailable as well.
- Several of the `Set...` functions use C++ overloading that is not available in Lua. For Lua, each numerical setter is named parallel to its getter. For example, the setter `XMLAttribute.SetIntAttribute` corresponds to `XMLAttribute.IntAttribute`.
- Each of the classes has a `ClassName` method added that is not in the original documentation.
- The constructor for `XMLDocument` is a plain constructor with no arguments. There are properties to change the values that the C++ version accepts as optional arguments on the constructor. Compare:

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
local doc_with_settings = tinyxml2.XMLDocument()
doc_with_settings.ProcessEntities = false
doc_with_settings.WhitespaceMode = tinyxml2.COLLAPSE_WHITESPACE)
```

The latest version of the [RGP Lua Class Browser](https://github.com/finale-lua/rgplua-class-browser) provides a working example of a script that uses `tinyxml2`.

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

- If the input node has no attributes and no children, it returns a string (or optionally a number) containing the value of the node. Otherwise it returns a table.
- If the input node has attributes, the return table includes an embedded table with the `_attr` key that contains the attributes as key/value pairs.
- If the input node has child nodes, the return table includes all the child nodes from recursive calls to `xml2table`.
- If the input node has a value in addition to attributes and/or child nodes, the return table includes the value with the `_value` key.

The optional `options` parameter is a table with options to modify the behavior of `xml2table`. Currently only one option is supported:

- `usenumbers`: if this is set, then `xml2table` converts any values it can to numbers. Otherwise all values are strings.

Example:

```lua
local xml = tinyxml2.XMLDocument()
xml:LoadFile("myxml.xml")
local tab_with_numbers = xml2table(xml, { usenumbers = true })
local tab_with_strings = xml2table(xml)
```




