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

`xmlelements()` feeds a `for` loop with child elements of a node in order. It feeds only elements that are direct descendants of the node and does not recurse. If the optional `nodename` string is supplied, it iterates only on nodes with that name.

Example:

```lua
local xml = tinyxml2.XMLDocument()
xml:LoadFile("myxml.xml")
for element in xmlelements(xml) do
   print ("Name: ", element:Name(), "Text: ", tostring(element:GetText()))
end
```

### xmlattributes(node)

`xmlattributes()` feeds a `for` loop with the attributes of an XMLElement. If the node passed in is not convertible to an XMLElement instance, it does nothing.

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

