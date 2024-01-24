include_files = { "src/**/*.lua"}
exclude_files = {
    "mobdebug.lua",
}
globals = {
    "finale",
    "finenv",
    "finaleplugin",
    "coll2table",
    "dumpproperties",
    "each",
    "eachbackwards",
    "eachcell",
    "eachentry",
    "eachentrysaved",
    "eachstaff",
    "loadall",
    "loadallforregion",
    "pairsbykeys",
    "bit32",
    "utf8",
    "socket",
    "tinyxml2",
    "xmlelements",
    "xmlattributes",
    "prettyformatjson",
    "plugindef"
}
codes = true
unused = false
unused_args = false
ignore = { 
    "6..",   -- formatting
    "131",   -- Unused implicitly defined global variable
}
allow_defined = true