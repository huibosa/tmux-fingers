require "../../spec_helper"
require "../../../src/fingers/action_runner"

def make_test_pane(pane_id : String, pane_current_path : String = "/tmp/source") : Tmux::Pane
  Tmux::Pane.from_json(
    %({"pane_id":"#{pane_id}","window_id":"@0","pane_width":80,"pane_height":24,) +
    %("pane_left":0,"pane_top":0,"pane_current_path":"#{pane_current_path}",) +
    %("pane_in_mode":false,"scroll_position":null,"window_zoomed_flag":false,"pane_tty":"/dev/pts/0"})
  )
end

def make_action_runner(
  active_pane : Tmux::Pane,
  source_pane : Tmux::Pane,
  modifier : String = "shift",
  mode : String = "default",
  match : String = "/tmp/foo",
  shift_action : String | Nil = ":paste:",
) : Fingers::ActionRunner
  Fingers::ActionRunner.new(
    modifier: modifier,
    match: match,
    hint: "a",
    active_pane: active_pane,
    source_pane: source_pane,
    offset: nil,
    mode: mode,
    main_action: nil,
    ctrl_action: nil,
    alt_action: nil,
    shift_action: shift_action,
  )
end

describe Fingers::ActionRunner do
  describe "#paste" do
    it "targets the active pane, not the source pane" do
      active = make_test_pane("%42")
      source = make_test_pane("%99")
      runner = make_action_runner(active_pane: active, source_pane: source)

      cmd = runner.paste

      cmd.should contain("%42")
      cmd.should_not contain("%99")
    end

    it "returns a tmux paste-buffer command for the active pane" do
      active = make_test_pane("%5")
      source = make_test_pane("%6")
      runner = make_action_runner(active_pane: active, source_pane: source)

      cmd = runner.paste

      cmd.should contain("paste-buffer")
      cmd.should contain("%5")
    end

    it "uses active pane even when source and active differ" do
      active = make_test_pane("%10", "/tmp/active")
      source = make_test_pane("%20", "/tmp/source")
      runner = make_action_runner(active_pane: active, source_pane: source)

      cmd = runner.paste

      cmd.should contain("%10")
      cmd.should_not contain("%20")
    end
  end
end
