require "./types"

module Fingers
  class State
    @matched_target : Fingers::Target?

    def initialize
      @show_help = false
      @multi_mode = false
      @input = ""
      @modifier = ""
      @selected_hints = [] of String
      @selected_matches = [] of String
      @multi_matches = [] of String
      @result = ""
      @exiting = false
      @matched_target = nil
    end

    property :show_help,
      :multi_mode,
      :input,
      :modifier,
      :selected_hints,
      :selected_matches,
      :multi_matches,
      :result,
      :exiting,
      :matched_target
  end
end
