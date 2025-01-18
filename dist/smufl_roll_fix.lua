function plugindef()
  finaleplugin.Author = "Jacob Winkler" 
  finaleplugin.Copyright = "©2022 Jacob Winkler"
  finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
  finaleplugin.Version = "1.0"
  finaleplugin.Date = "2022-07-24"
  finaleplugin.Notes = [[
The 'roll' articulation in Finale uses a glyph that is NOT part of the SMuFL standard (SMuFL uses rotated horizontal glyphs for arpeggios rather than MakeMusic's vertical glyph). Therefore, when using SMuFL fonts other than MakeMusic's (e.g. Bravura or Leland), 'roll' articulations get mapped to an incorrect glyph. 

This script will replace the font and character used by the rolled arpeggio articulation to use Finale Maestro, regardless of the default music font.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 The \u8216'roll\u8217' articulation in Finale uses a glyph that is NOT part of the SMuFL standard (SMuFL uses rotated horizontal glyphs for arpeggios rather than MakeMusic\u8217's vertical glyph). Therefore, when using SMuFL fonts other than MakeMusic\u8217's (e.g.\u160 ?Bravura or Leland), \u8216'roll\u8217' articulations get mapped to an incorrect glyph.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script will replace the font and character used by the rolled arpeggio articulation to use Finale Maestro, regardless of the default music font.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/smufl_roll_fix.hash"
  return "SMuFL: Fix roll", "SMuFL: Fix roll", "Fixes 'roll' articulations when converting from non-SMuFL to SMuFL fonts."
end
function roll_fix()
  local artics = finale.FCArticulationDefs()
  artics:LoadAll()
  for ad in each(artics) do
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
roll_fix()