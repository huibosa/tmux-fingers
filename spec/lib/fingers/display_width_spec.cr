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
  end
end
