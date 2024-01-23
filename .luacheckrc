-- luacheck: ignore 131
include_files = { "src/**/*.lua"}
exclude_files = {
    "mobdebug.lua",
    "src/lunajson/**/*.lua",
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
ignore = { 
    "6..",   -- formatting
}
allow_defined_top = true