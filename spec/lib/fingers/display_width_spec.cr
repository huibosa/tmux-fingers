require "spec"
require "../../spec_helper.cr"
require "../../../src/fingers/display_width"

describe Fingers::DisplayWidth do
  describe ".of(Char)" do
    it "ASCII chars are width 1" do
      Fingers::DisplayWidth.of('a').should eq 1
      Fingers::DisplayWidth.of('Z').should eq 1
      Fingers::DisplayWidth.of(' ').should eq 1
    end

    it "control chars are width 0" do
      Fingers::DisplayWidth.of('\u{0000}').should eq 0
      Fingers::DisplayWidth.of('\u{001F}').should eq 0
      Fingers::DisplayWidth.of('\u{007F}').should eq 0
    end

    it "tab counts as 1 (expansion handled separately by hinter)" do
      Fingers::DisplayWidth.of('\t').should eq 1
    end

    it "CJK ideographs are width 2" do
      Fingers::DisplayWidth.of('中').should eq 2
      Fingers::DisplayWidth.of('文').should eq 2
      Fingers::DisplayWidth.of('日').should eq 2
    end

    it "fullwidth forms are width 2" do
      Fingers::DisplayWidth.of('\u{FF01}').should eq 2  # FULLWIDTH EXCLAMATION MARK
      Fingers::DisplayWidth.of('\u{FF1F}').should eq 2  # FULLWIDTH QUESTION MARK
    end

    it "Hangul syllables are width 2" do
      Fingers::DisplayWidth.of('한').should eq 2
      Fingers::DisplayWidth.of('글').should eq 2
    end

    it "basic emoji are width 2" do
      Fingers::DisplayWidth.of('🔥').should eq 2
      Fingers::DisplayWidth.of('🚀').should eq 2
    end

    it "Misc Symbols (U+2600–U+26FF) wide emoji are width 2" do
      Fingers::DisplayWidth.of('⛔').should eq 2  # U+26D4 NO ENTRY
      Fingers::DisplayWidth.of('⚡').should eq 2  # U+26A1 HIGH VOLTAGE
      Fingers::DisplayWidth.of('⌚').should eq 2  # U+231A WATCH
      Fingers::DisplayWidth.of('☔').should eq 2  # U+2614 UMBRELLA WITH RAIN DROPS
    end

    it "Misc Symbols and Arrows (U+2B00–U+2BFF) wide emoji are width 2" do
      Fingers::DisplayWidth.of('⭐').should eq 2  # U+2B50 STAR
      Fingers::DisplayWidth.of('⭕').should eq 2  # U+2B55 HEAVY LARGE CIRCLE
    end

    it "Symbols and Pictographs Extended-A (U+1FA70+) are width 2" do
      Fingers::DisplayWidth.of('🪐').should eq 2  # U+1FA90 RINGED PLANET
    end

    it "combining marks are width 0" do
      Fingers::DisplayWidth.of('\u{0300}').should eq 0  # COMBINING GRAVE ACCENT
      Fingers::DisplayWidth.of('\u{200B}').should eq 0  # ZWSP
    end

    it "Greek/Cyrillic letters are width 1 (was wrongly 0 under old heuristic)" do
      Fingers::DisplayWidth.of('α').should eq 1
      Fingers::DisplayWidth.of('Ж').should eq 1
    end
  end

  describe ".of(String)" do
    it "sums character widths" do
      Fingers::DisplayWidth.of("hello").should eq 5
      Fingers::DisplayWidth.of("").should eq 0
    end

    it "handles CJK strings" do
      Fingers::DisplayWidth.of("中文").should eq 4
      Fingers::DisplayWidth.of("你好世界").should eq 8
    end

    it "handles mixed CJK and ASCII" do
      Fingers::DisplayWidth.of("a中b").should eq 4
      Fingers::DisplayWidth.of("hello你好world").should eq 14  # 5 + 4 + 5
    end

    it "handles strings with control chars" do
      Fingers::DisplayWidth.of("a\u{0000}b").should eq 2
    end

    it "text-default emoji with VS-16 (emoji presentation) are width 2" do
      Fingers::DisplayWidth.of("⚠️").should eq 2   # U+26A0 + U+FE0F  WARNING SIGN
      Fingers::DisplayWidth.of("ℹ️").should eq 2   # U+2139 + U+FE0F  INFORMATION SOURCE
      Fingers::DisplayWidth.of("✔️").should eq 2   # U+2714 + U+FE0F  HEAVY CHECK MARK
    end

    it "bare text-default emoji (no VS-16) stay width 1" do
      Fingers::DisplayWidth.of("\u{26A0}").should eq 1  # ⚠ without variation selector
    end
  end
end
