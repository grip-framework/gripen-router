require "spec"
require "../src/gripen_router"

abstract struct TestRouterPathParam
end

struct OneParam < TestRouterPathParam
end

struct OtherParam < TestRouterPathParam
end

struct ExampleGlobPath < TestRouterPathParam
  include Gripen::Router::GlobPath
end

def new_spec_router
  Gripen::Router::Node(TestRouterPathParam.class, Bool).new
end

describe Gripen::Router::Node do
  conflict_error = "expect merge! block yield on conflicts"

  it "adds a new node" do
    new_spec_router.add(["path"]) { true }
  end

  it "adds a new node with a path parameter" do
    new_spec_router.add [OneParam, "path"] { true }
  end

  it "finds a simple route" do
    router = new_spec_router
    router.add (["path"]) { true }
    action = router.find "path" { }
    action.should be_a Bool
  end

  it "finds a simple route starting with the delimiter" do
    router = new_spec_router
    router.add (["path"]) { true }
    action = router.find "/path", delimiter: '/' { }
    action.should be_a Bool
  end

  it "finds a route and yields path parameters" do
    router = new_spec_router
    router.add ([OneParam]) { true }
    param = value = nil
    action = router.find "path_param" do |k, v|
      param = k
      value = v
    end
    param.should eq OneParam
    value.should eq "path_param"
    action.should be_a Bool
  end

  it "raises for a route conflict with a path parameter" do
    router = new_spec_router
    router.add [OneParam, "path"] { true }
    ex = expect_raises Gripen::Router::Node::RouteConflict do
      router.add (["path"]) { true }
    end
    ex.message.as(String).should end_with OneParam.to_s
  end

  it "raises for a path parameter conflict" do
    router = new_spec_router
    router.add ["path", OneParam] { true }
    ex = expect_raises Gripen::Router::Node::PathParameterConflict do
      router.add ["path", OtherParam] { true }
    end
    ex.message.as(String).should contain OneParam.to_s
    ex.message.as(String).should end_with OneParam.to_s
  end

  it "finds a route with a glob path" do
    router = new_spec_router
    router.add ([ExampleGlobPath]) { true }
    param = value = nil
    action = router.find "/a/b/c" do |k, v|
      param = k
      value = v
    end
    param.should eq ExampleGlobPath
    value.should eq "a/b/c"
    action.should be_a Bool
  end

  describe "#merge!" do
    it "merges nodes from a router to another" do
      main_router = new_spec_router
      other_router = new_spec_router

      main_router.add ["test", "path", OneParam] { true }
      other_router.add ["test", "other_path", OtherParam] { true }

      main_router.merge!(other_router) { }
      action = main_router.find "test/other_path/param" { }
      action.should be_a Bool
    end

    it "conflicts with two same routes" do
      main_router = new_spec_router
      other_router = new_spec_router

      {main_router, other_router}.each &.add ["path", OneParam] { true }

      conflict = false
      main_router.merge! other_router do
        conflict = true
      end

      fail conflict_error if !conflict
    end
  end

  describe "#find" do
    it "finds a route" do
      router = new_spec_router
      router.add (["path"]) { true }
      action = router.find "path" { }
      action.should be_a Bool
    end
  end
end
