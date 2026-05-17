require "../huffman"
require "./config"
require "./match_formatter"
require "./types"
require "./display_width"

module Fingers
  class Hinter
    CLEAR_SEQ = "\e[H\e[J"
    HIDE_CURSOR_SEQ = "\e[?25l"

    @formatter : Formatter
    @patterns : Array(String)
    @alphabet : Array(String)
    @pattern : Regex | Nil
    @hints : Array(String) | Nil
    @n_matches : Int32 | Nil
    @reuse_hints : Bool
    @current_printer : Printer | Nil
    @current_pane_id : String
    @current_width : Int32

    def initialize(
      pane_inputs : Array(PaneInput),
      state : Fingers::State,
      patterns = Fingers.config.patterns,
      alphabet = Fingers.config.alphabet,
      huffman = Huffman.new,
      formatter = ::Fingers::MatchFormatter.new,
      reuse_hints = false
    )
      @pane_inputs = pane_inputs
      @target_by_hint = {} of String => Target
      @target_by_text = {} of String => Target
      @state = state
      @formatter = formatter
      @huffman = huffman
      @patterns = patterns
      @alphabet = alphabet
      @reuse_hints = reuse_hints
      @current_printer = nil
      @current_pane_id = ""
      @current_width = 0
    end

    def run
      regenerate_hints!

      @pane_inputs.each do |pane_input|
        @current_printer = pane_input.printer
        @current_pane_id = pane_input.pane_id
        @current_width = pane_input.width
        lines = pane_input.lines

        pane_input.printer.print(CLEAR_SEQ + HIDE_CURSOR_SEQ)

        if lines.empty?
          pane_input.printer.flush
          next
        end

        lines[0..-2].each_with_index { |line, index| process_line(line, index, "\n") }
        process_line(lines[-1], lines.size - 1, "")

        pane_input.printer.flush
      end
    end

    def lookup(hint) : Target | Nil
      target_by_hint.fetch(hint) { nil }
    end

    # private

    private getter :hints,
      :hints_by_text,
      :offsets_by_hint,
      :input,
      :lookup_table,
      :state,
      :formatter,
      :huffman,
      :patterns,
      :alphabet,
      :reuse_hints,
      :target_by_hint,
      :target_by_text,
      :pane_inputs

    def output : Printer
      @current_printer.not_nil!
    end

    def width : Int32
      @current_width
    end

    def process_line(line, line_index, ending)
      tab_positions = tab_positions_for(line)
      result = line.gsub(pattern) { |_m| replace($~, line_index) }
      initial_length = result.size
      result = expand_tabs(result, tab_positions)
      tab_correction = result.size - initial_length

      result = Fingers.config.backdrop_style + result
      display_w = Fingers::DisplayWidth.of(line)
      padding_amount = (width - display_w - tab_correction)
      padding = padding_amount > 0 ? " " * padding_amount : ""
      output.print(result + padding + ending)
    end

    def pattern : Regex
      @pattern ||= Regex.new("(#{patterns.join('|')})")
    end

    def hints : Array(String)
      return @hints.as(Array(String)) if !@hints.nil?

      regenerate_hints!

      @hints.as(Array(String))
    end

    def regenerate_hints!
      @hints = huffman.generate_hints(alphabet: alphabet.clone, n: n_matches)
      @target_by_hint.clear
      @target_by_text.clear
    end

    def replace(match, line_index)
      text = match[0]

      captured_text = captured_text_for_match(match)
      relative_capture_offset = relative_capture_offset_for_match(match, captured_text)

      absolute_offset = {
        line_index,
        match.begin(0) + (relative_capture_offset ? relative_capture_offset[0] : 0)
      }

      hint = hint_for_text(captured_text)

      # hint is longer than highlighted text, put it back in hint stack
      if DisplayWidth.of(hint) > DisplayWidth.of(captured_text)
        hints.push(hint)
        return text
      end

      build_target(captured_text, hint, absolute_offset)

      if !state.input.empty? && !hint.starts_with?(state.input)
        return text
      end

      formatter.format(
        hint: hint,
        highlight: text,
        selected: state.selected_hints.includes?(hint),
        offset: relative_capture_offset
      )
    end

    def captured_text_for_match(match)
      match["match"]? || match[0]
    end

    def hint_for_text(text)
      return pop_hint! unless reuse_hints

      target = target_by_text[text]?

      if target.nil?
        return pop_hint!
      end

      target.hint
    end

    def pop_hint! : String
      hint = hints.pop?

      if hint.nil?
        raise "Too many matches"
      end

      hint
    end

    def relative_capture_offset_for_match(match, captured_text)
      return nil unless match["match"]?

      match_start, match_end = {match.begin(0), match.end(0)}
      capture_start, capture_end = find_capture_offset(match).not_nil!
      {capture_start - match_start, captured_text.size}
    end

    def build_target(text, hint, offset)
      target = Target.new(text, hint, offset, @current_pane_id)

      target_by_hint[hint] = target
      target_by_text[text] = target

      target
    end

    def find_capture_offset(match : Regex::MatchData) : Tuple(Int32, Int32) | Nil
      index = capture_indices.find { |i| match[i]? }

      return nil unless index

      {match.begin(index), match.end(index)}
    end

    getter capture_indices : Array(Int32) do
      pattern.name_table.compact_map { |k, v| v == "match" ? k : nil }
    end

    def n_matches : Int32
      return @n_matches.as(Int32) if !@n_matches.nil?

      if reuse_hints
        @n_matches = count_unique_matches
      else
        @n_matches = count_matches
      end
    end

    def count_unique_matches
      match_set = Set(String).new

      pane_inputs.each do |pane_input|
        pane_input.lines.each do |line|
          line.scan(pattern) do |match|
            match_set.add(captured_text_for_match(match))
          end
        end
      end

      @n_matches = match_set.size

      match_set.size
    end

    def count_matches
      result = 0

      pane_inputs.each do |pane_input|
        pane_input.lines.each do |line|
          line.scan(pattern) do |match|
            result += 1
          end
        end
      end

      result
    end

    def tab_positions_for(line)
      positions = [] of Int32
      offset = 0

      loop do
        index = line.index("\t", offset)

        break unless index
        positions << index
        offset = index + 1
      end

      positions
    end

    def expand_tabs(line, tab_positions)
      correction = 0
      line.gsub(/\t/) do |_|
        tab_position = tab_positions.shift?
        next "\t" unless tab_position
        spaces = 8 - ((tab_position + correction) % 8)
        correction += spaces - 1
        " " * spaces
      end
    end
  end
end
