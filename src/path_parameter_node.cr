# Path parameter node.
class Gripen::Router::PathParameterNode(P, A) < Gripen::Router::Node(P, A)
  getter parameter : P

  protected def initialize(@parameter : P)
  end

  protected def handle_glob?(full_path : String, byte_position : Int32, & : P, String ->)
    if glob? @parameter
      yield @parameter, full_path.byte_slice(byte_position, full_path.bytesize - byte_position)
    end
  end

  private def glob?(path : GlobPath.class)
    true
  end

  private def glob?(path)
    false
  end
end
