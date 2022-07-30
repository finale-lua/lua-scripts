function plugindef()
  finaleplugin.Author = "Jacob Winkler" 
  finaleplugin.Copyright = "©2022 Jacob Winkler"
  finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
  finaleplugin.Version = "1.0"
  finaleplugin.Date = "2022-07-24"
  finaleplugin.Notes = [[
The rolled arpeggio articulation in Finale uses a glyph that is NOT part of the SMuFL standard (SMuFL uses rotated horizontal glyphs for arpeggios rather than MakeMusic's vertical glyph). Therefore, when using SMuFL fonts other than MakeMusic's (e.g. Bravura or Leland), rolled arpeggio articulations get mapped to an incorrect glyph. 

This script will replace the font and character used by the rolled arpeggio articulation to use Finale Maestro, regardless of the default music font.
    ]]
  return "SMuFL: Fix arpeggio", "SMuFL: Fix arpeggio", "Fixes arpeggio articulations when converting from non-SMuFL to SMuFL fonts."
end

function arpeggio_update()
  local artics = finale.FCArticulationDefs()
  artics:LoadAll()

  for ad in each(artics) do
    local char = ad:GetMainSymbolChar()
    local Maestro_roll = 103
    local SMuFL_roll = 63232
    local font = "Finale Maestro"
    if ad:GetMainSymbolChar() == Maestro_roll then
      ad:SetMainSymbolChar(SMuFL_roll)
      ad:SetFlippedSymbolChar(SMuFL_roll)
      ad:SetMainSymbolFont(font)
      ad:SetFlippedSymbolFont(font)
      ad:Save()
    end
  end
end

arpeggio_update()