require "../tmux"
require "./hinter"
require "./state"
require "./action_runner"

module Fingers
  class View
    @hinter : Hinter
    @state : State
    @tmux : Tmux
    @mode : String

    def initialize(
      @hinter,
      @state,
      @tmux,
      @mode,
    )
    end

    def render
      begin
        hinter.run
      rescue e
        Log.fatal { e }
        request_exit!
      end
    end

    def process_input(input : String)
      command, *args = input.split(":")

      case command
      when "hint"
        char, modifier = args
        process_hint(char, modifier)
      when "exit"
        request_exit!
      when "toggle-help"
      when "toggle-multi-mode"
        process_multimode
      when "fzf"
        # soon
      end
    end

    private def process_hint(char, modifier)
      state.input += char
      state.modifier = modifier

      match = hinter.lookup(state.input)

      if match.nil?
        render
      else
        state.matched_target = match
        handle_match(match.not_nil!.text)
      end
    end

    private def process_multimode
      return if mode == "jump"

      prev_state = state.multi_mode
      state.multi_mode = !state.multi_mode
      current_state = state.multi_mode

      if prev_state == true && current_state == false
        state.result = state.multi_matches.join(' ')
        request_exit!
      end
    end

    private getter :hinter, :state, :tmux, :mode

    private def handle_match(match)
      if state.multi_mode
        state.multi_matches << match
        state.selected_hints << state.input
        state.input = ""
        render
      else
        state.result = match
        request_exit!
      end
    end

    private def request_exit!
      state.exiting = true
    end
  end
end
