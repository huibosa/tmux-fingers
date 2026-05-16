module Fingers
  # Display column count of strings/chars per UAX #11 East Asian Width.
  # Wide chars (CJK, fullwidth, emoji) → 2; control/combining → 0; rest → 1.
  module DisplayWidth
    WIDE_RANGES = [
      {0x1100, 0x115F},   # Hangul Jamo
      {0x2329, 0x232A},   # Angle brackets
      {0x2E80, 0x303E},   # CJK Radicals, Kangxi
      {0x3041, 0x33FF},   # Hiragana, Katakana, Bopomofo, CJK symbols
      {0x3400, 0x4DBF},   # CJK Unified Ideographs Extension A
      {0x4E00, 0x9FFF},   # CJK Unified Ideographs
      {0xA000, 0xA4CF},   # Yi Syllables / Radicals
      {0xAC00, 0xD7A3},   # Hangul Syllables
      {0xF900, 0xFAFF},   # CJK Compatibility Ideographs
      {0xFE30, 0xFE4F},   # CJK Compatibility Forms
      {0xFF00, 0xFF60},   # Fullwidth Forms
      {0xFFE0, 0xFFE6},   # Fullwidth Signs
      {0x1F300, 0x1F64F}, # Misc Symbols and Pictographs (emoji)
      {0x1F680, 0x1F6FF}, # Transport and Map Symbols
      {0x1F900, 0x1F9FF}, # Supplemental Symbols and Pictographs
      {0x20000, 0x2FFFD}, # CJK Extensions B–F
      {0x30000, 0x3FFFD}, # CJK Extension G
    ]

    ZERO_WIDTH_RANGES = [
      {0x0300, 0x036F},   # Combining Diacritical Marks
      {0x0483, 0x0489},   # Cyrillic combining
      {0x0591, 0x05BD},   # Hebrew points
      {0x05BF, 0x05BF},
      {0x05C1, 0x05C2},
      {0x05C4, 0x05C5},
      {0x05C7, 0x05C7},
      {0x0610, 0x061A},   # Arabic combining
      {0x064B, 0x065F},
      {0x0670, 0x0670},
      {0x06D6, 0x06DC},
      {0x06DF, 0x06E4},
      {0x06E7, 0x06E8},
      {0x06EA, 0x06ED},
      {0x0711, 0x0711},   # Syriac
      {0x0730, 0x074A},
      {0x07A6, 0x07B0},   # Thaana
      {0x07EB, 0x07F3},   # NKo
      {0x0816, 0x0819},   # Samaritan
      {0x081B, 0x0823},
      {0x0825, 0x0827},
      {0x0829, 0x082D},
      {0x0859, 0x085B},   # Mandaic
      {0x08D4, 0x0902},   # Arabic + Devanagari combining
      {0x093A, 0x093A},
      {0x093C, 0x093C},
      {0x0941, 0x0948},
      {0x094D, 0x094D},
      {0x0951, 0x0957},
      {0x0962, 0x0963},
      {0x1AB0, 0x1AFF},   # Combining Diacritical Marks Extended
      {0x1DC0, 0x1DFF},   # Combining Diacritical Marks Supplement
      {0x200B, 0x200F},   # ZWSP, ZWJ, ZWNJ, directional marks
      {0x202A, 0x202E},   # Bidi
      {0x2060, 0x206F},   # Word joiner, invisible operators
      {0x20D0, 0x20FF},   # Combining Marks for Symbols
      {0xFE00, 0xFE0F},   # Variation Selectors
      {0xFE20, 0xFE2F},   # Combining Half Marks
      {0xFEFF, 0xFEFF},   # BOM
      {0xFFF9, 0xFFFB},   # Interlinear annotation
      {0xE0100, 0xE01EF}, # Variation Selectors Supplement
    ]

    def self.of(char : Char) : Int32
      cp = char.ord
      # Tab counts as 1 column for the unexpanded line; tab expansion accounts
      # for the remaining columns separately (see Hinter#process_line).
      return 1 if cp == 0x09
      return 0 if cp < 0x20
      return 0 if cp >= 0x7F && cp < 0xA0
      return 0 if range_contains?(ZERO_WIDTH_RANGES, cp)
      return 2 if range_contains?(WIDE_RANGES, cp)
      1
    end

    def self.of(str : String) : Int32
      total = 0
      str.each_char { |c| total += of(c) }
      total
    end

    private def self.range_contains?(ranges, cp)
      low = 0
      high = ranges.size - 1
      while low <= high
        mid = (low + high) // 2
        r_low, r_high = ranges[mid]
        if cp < r_low
          high = mid - 1
        elsif cp > r_high
          low = mid + 1
        else
          return true
        end
      end
      false
    end
  end
end
