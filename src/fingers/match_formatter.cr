require "./config"
require "./display_width"
require "./types"

module Fingers
  class MatchFormatter < Fingers::Formatter
    def initialize(
      hint_style : String = Fingers.config.hint_style,
      highlight_style : String = Fingers.config.highlight_style,
      selected_hint_style : String = Fingers.config.selected_hint_style,
      selected_highlight_style : String = Fingers.config.selected_highlight_style,
      backdrop_style : String = Fingers.config.backdrop_style,
      hint_position : String = Fingers.config.hint_position,
      reset_sequence : String = "\e[0m"
    )
      @hint_style = hint_style
      @highlight_style = highlight_style
      @selected_hint_style = selected_hint_style
      @selected_highlight_style = selected_highlight_style
      @backdrop_style = backdrop_style
      @hint_position = hint_position
      @reset_sequence = reset_sequence
    end

    def format(hint : String, highlight : String, selected : Bool, offset : Tuple(Int32, Int32) | Nil)
      reset_sequence + before_offset(offset, highlight) +
        format_offset(selected, hint, within_offset(offset, highlight)) +
        after_offset(offset, highlight) + backdrop_style
    end

    private getter :hint_style, :highlight_style, :selected_hint_style, :selected_highlight_style, :hint_position, :reset_sequence, :backdrop_style

    private def before_offset(offset, highlight)
      return "" if offset.nil?
      start, _ = offset
      backdrop_style + highlight[0..(start - 1)]
    end

    private def within_offset(offset, highlight)
      return highlight if offset.nil?
      start, length = offset
      highlight[start..(start + length - 1)]
    end

    private def after_offset(offset, highlight)
      return "" if offset.nil?
      start, length = offset
      backdrop_style + highlight[(start + length)..]
    end

    private def format_offset(selected, hint, highlight)
      chopped_highlight = chop_highlight(hint, highlight)

      hint_pair = (selected ? selected_hint_style : hint_style) + hint
      highlight_pair = (selected ? selected_highlight_style : highlight_style) + chopped_highlight

      if hint_position == "right"
        highlight_pair + reset_sequence + hint_pair + reset_sequence
      else
        hint_pair + reset_sequence + highlight_pair + reset_sequence
      end
    end

    private def chop_highlight(hint, highlight)
      hint_w = DisplayWidth.of(hint)
      if hint_position == "right"
        chop_display_width_from_end(highlight, hint_w)
      else
        chop_display_width_from_start(highlight, hint_w)
      end
    rescue
      puts "failed for hint '#{hint}' and '#{highlight}'"
      ""
    end

    private def chop_display_width_from_start(highlight, hint_w)
      consumed_w = 0
      i = 0
      highlight.each_char do |char|
        break if consumed_w >= hint_w
        consumed_w += DisplayWidth.of(char)
        i += 1
      end
      " " * Math.max(consumed_w - hint_w, 0) + highlight[i..-1]
    end

    private def chop_display_width_from_end(highlight, hint_w)
      keep_w = DisplayWidth.of(highlight) - hint_w
      accumulated_w = 0
      i = 0
      highlight.each_char do |char|
        char_w = DisplayWidth.of(char)
        break if accumulated_w + char_w > keep_w
        accumulated_w += char_w
        i += 1
      end
      highlight[0...i] + " " * (keep_w - accumulated_w)
    end
  end
end
