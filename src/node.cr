# Nodes are used to create route paths.
#
# A a tree of nodes is made by assigning children nodes to given paths.
#
# An action can be attached to a node.
#
# `P` is the path parameter type and `A` the route action type.
class Gripen::Router::Node(P, A)
  class PathParameterConflict < Error
  end

  class RouteConflict < Error
  end

  # A node can either lead to other path nodes or a single path parameter, which will catch all possible path values.
  getter children : Hash(String, Node(P, A)) | PathParameterNode(P, A) | Nil = nil

  # Action associated to the node.
  getter action : A? = nil

  private def check_glob(children, full_path : String, byte_offset : Int32)
    if children.is_a? PathParameterNode(P, A)
      children.handle_glob? full_path, byte_offset do |param, string|
        yield children.action, param, string
      end
    end
  end

  # Finds a `A` action, and yields each `P` path parameter with its `String` value.
  def find(full_path : String, delimiter : Char | String = '/', & : P, String ->) : A?
    node = self

    byte_offset = full_path.starts_with?(delimiter) ? delimiter.bytesize : 0

    check_glob @children, full_path, byte_offset do |action, param, string|
      yield param, string
      return action
    end

    byte_offset = 0

    full_path.split delimiter do |path|
      byte_offset += path.bytesize
      if path.empty?
        byte_offset += delimiter.bytesize
        next
      end

      case children = node.children
      when PathParameterNode(P, A)
        yield children.parameter, path
        node = children
      when Hash(String, Node(P, A))
        node = children[path]?
      else
        node = nil
      end

      return if !node
      check_glob node.children, full_path, byte_offset do |action, param, string|
        yield param, string
        return action
      end

      byte_offset += delimiter.bytesize
    end
    node.action
  end

  # Adds a route, yields if there is no action and returns the action `T`.
  #
  # Any conflict will raise an error.
  def add(path : Array(P | String), &action : -> A) : A
    if path.empty?
      node_action = @action || action.call
      @action = node_action
      return node_action
    end

    case current_path = path.shift
    when P
      children = check_path_parameter_conflict PathParameterNode(P, A).new(current_path)
      children.add path, &action
    when String
      case children = @children
      when PathParameterNode(P, A)
        raise RouteConflict.new "Cannot add route #{current_path} because of existing path parameter #{children.parameter}"
      else
        children ||= Hash(String, Node(P, A)).new
        child = children.fetch current_path do
          children[current_path] = Node(P, A).new
        end
        @children = children
        child.add path, &action
      end
    else
      raise Error.new "Unreachable path type: #{current_path}"
    end
  end

  private def check_path_parameter_conflict(path_parameter : PathParameterNode(P, A)) : PathParameterNode(P, A)
    case children = @children
    when PathParameterNode(P, A)
      # A same paramater path node already exists
      if path_parameter.parameter == children.parameter
        return children
      end
      raise PathParameterConflict.new(
        "Cannot add path parameter #{path_parameter.parameter} because of existing different path parameter #{children.parameter}")
    when Hash(String, Node(P, A))
      raise PathParameterConflict.new "Cannot add path parameter #{path_parameter.parameter} because of existing routes #{children.keys}"
    else
      @children = path_parameter
    end
  end

  # Merges nodes to this one. Yield the existing and the other action in case of a conflict.
  #
  # Any other conflict will raise an error.
  def merge!(other : Node(P, A), &block : A, A ->)
    if other_action = other.action
      if action = @action
        yield action, other_action
      else
        @action = other_action
      end
    end

    case other_children = other.children
    when Hash(String, Node(P, A))
      case children = @children
      when PathParameterNode(P, A)
        raise RouteConflict.new "Cannot add routes #{other_children.keys} because of existing path parameter #{children.parameter}"
      when Hash(String, Node(P, A))
        other_children.each do |path, other_node|
          next if !other_node
          if children.has_key? path
            children[path].merge! other_node, &block
          else
            children[path] = other_node
          end
        end
      else
        @children = other_children
      end
    when PathParameterNode(P, A)
      children = check_path_parameter_conflict other_children
      children.merge! other_children, &block
    else # No children
    end
  end

  # Returns each path in the node tree.
  def each_path(&block : Array(P | String), A ->)
    each_path Array(P | String).new, &block
  end

  protected def each_path(path_prefix : Array(P | String), &block : Array(P | String), A ->)
    if action = @action
      block.call path_prefix, action
    end

    case children = @children
    when PathParameterNode(P, A)
      children.each_path path_prefix.dup.push(children.parameter), &block
    when Hash(String, Node(P, A))
      children.each do |path, node|
        node.each_path path_prefix.dup.push(path), &block
      end
    else # no children
    end
  end
end

require "./path_parameter_node"
