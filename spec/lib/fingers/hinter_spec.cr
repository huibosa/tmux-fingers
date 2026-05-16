require "spec"
require "../../spec_helper.cr"
require "../../../src/fingers/hinter"
require "../../../src/fingers/state"
require "../../../src/fingers/config"
require "../../../src/fingers/types"

record StateDouble, selected_hints : Array(String)

class TextOutput < ::Fingers::Printer
  def initialize
    @contents = ""
  end

  def print(msg)
    self.contents += msg
  end

  def flush
  end

  property :contents
end

def generate_lines
  input = 50.times.map do
    10.times.map do
      rand.to_s.split(".").last[0..15].rjust(16, '0')
    end.join(" ")
  end.join("\n")
end

def make_pane_input(input : String, width : Int32 = 100, pane_id : String = "%0") : Fingers::PaneInput
  Fingers::PaneInput.new(
    lines: input.split("\n"),
    printer: TextOutput.new,
    pane_id: pane_id,
    width: width,
  )
end

describe Fingers::Hinter do
  it "works in a grid of lines" do
    input = generate_lines
    pane_input = make_pane_input(input)

    patterns = Fingers::Config::BUILTIN_PATTERNS.values.to_a
    alphabet = "asdf".split("")

    hinter = Fingers::Hinter.new(
      pane_inputs: [pane_input],
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
    )
  end

  it "only highlights captured groups" do
    input = "
On branch ruby-rewrite-more-like-crystal-rewrite-amirite
Your branch is up to date with 'origin/ruby-rewrite-more-like-crystal-rewrite-amirite'.

Changes to be committed:
  (use \"git restore --staged <file>...\" to unstage)
        modified:   spec/lib/fingers/match_formatter_spec.cr

Changes not staged for commit:
  (use \"git add <file>...\" to update what will be committed)
  (use \"git restore <file>...\" to discard changes in working directory)
        modified:   .gitignore
        modified:   spec/lib/fingers/hinter_spec.cr
        modified:   spec/spec_helper.cr
        modified:   src/fingers/cli.cr
        modified:   src/fingers/dirs.cr
        modified:   src/fingers/match_formatter.cr
    "
    pane_input = make_pane_input(input)

    patterns = Fingers::Config::BUILTIN_PATTERNS.values.to_a
    patterns << "On branch (?<capture>.*)"
    alphabet = "asdf".split("")

    hinter = Fingers::Hinter.new(
      pane_inputs: [pane_input],
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
    )
  end

  it "only reuses hints when allow duplicates is false" do
    patterns = Fingers::Config::BUILTIN_PATTERNS.values.to_a
    alphabet = "asdf".split("")

    input = "
          modified:   src/fingers/cli.cr
          modified:   src/fingers/cli.cr
          modified:   src/fingers/cli.cr
    "

    hinter = Fingers::Hinter.new(
      pane_inputs: [make_pane_input(input)],
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      reuse_hints: false
    )

    hinter.run
  end

  it "can rerender when not reusing hints" do
    patterns = Fingers::Config::BUILTIN_PATTERNS.values.to_a
    alphabet = "asdf".split("")

    input = "
          modified:   src/fingers/cli.cr
          modified:   src/fingers/cli.cr
          modified:   src/fingers/cli.cr
    "

    hinter = Fingers::Hinter.new(
      pane_inputs: [make_pane_input(input)],
      patterns: patterns,
      state: ::Fingers::State.new,
      alphabet: alphabet,
      reuse_hints: false
    )

    hinter.run
    hinter.run
  end
end
