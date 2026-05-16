module Fingers
  abstract class Printer
    abstract def print(msg : String)
    abstract def flush
  end

  abstract class Formatter
    abstract def format(hint : String, highlight : String, selected : Bool, offset : Tuple(Int32, Int32) | Nil)
  end

  struct Target
    property text : String
    property hint : String
    property offset : Tuple(Int32, Int32)
    property source_pane_id : String

    def initialize(@text, @hint, @offset, @source_pane_id = "")
    end
  end

  struct PaneInput
    property lines : Array(String)
    property printer : Printer
    property pane_id : String
    property width : Int32

    def initialize(@lines, @printer, @pane_id, @width)
    end
  end
end
