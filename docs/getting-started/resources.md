# Resources

## Learning JW Lua

- [JW Lua start page](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jw_lua) is great if you're new to JW Lua
- [Script Programming in JW Lua](http://jwmusic.nu/jwplugins/wiki/doku.php?id=jwlua:development) is a great overview to JW Lua development
- [Finale PDK Framework](http://www.finaletips.nu/frameworkref/), which is how Finale connects to JW Lua
- [Coding in JW Lua](https://www.youtube.com/playlist?list=PLsFZ0c2Wsoy9ZF6a0ZihC_-SPf3FkOh8o), YouTube videos that introduce you to JW Lua even if you've never coded before

### Learning the underlying PDK framework

An early version of the C++ source code of the PDK Framework is available for [download here](http://finaletips.nu/index.php/download/category/21-plug-in-development). Unfortunately Makemusic has ceased permitting new developers to access the PDK, so building the PDK Framework does not serve much purpose without it. However, the source code may be useful as a reference for understanding how to use the Framework. (Much of the current source code is viewable in the PDK Framework documentation.)

Frequently when working with Finale, it is useful to discover which data structures the Finale program itself modifies when you make a change through the user interface. To that end there is a free Finale plugin that writes your document out to a simple text file.

The plugin's normal use case is to create a small file that illustrates what you are working on. Dump it to text before changing it with Finale and again after changing it. Then compare the two using any number of free text file comparison utilities. A common one is ```kDiff3```, which is available for Windows and macOS. (Links change, so the easiest way to find the current version is a search engine.) The plugin includes both the internal data structure and the corresponding PDK Framework class name if there is one.

You can [download it here](http://robertgpatterson.com/-fininfo/-downloads/download-free.html). Also available on the page is a free plugin to reorganize the script menu for JW Lua. See the page for more details. The sample file linked there arranges the scripts in this GitHub repository into a series of submenus.

## Learning Git and GitHub

- YouTube videos that introduce [Git](https://youtu.be/USjZcfj8yxE) and [GitHub](https://youtu.be/nhNq2kIvi9s)
- [Free, interactive course on using GitHub, created by GitHub](https://lab.github.com/githubtraining/introduction-to-github)