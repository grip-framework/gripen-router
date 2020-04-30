# Router which resolves route paths.
module Gripen::Router
  class Error < Exception
  end

  # Special path parameter, which takes the path segment and all remaing ones following it.
  module GlobPath
  end
end

require "./node"
