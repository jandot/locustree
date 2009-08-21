require 'test/unit'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class TestRelationships < Test::Unit::TestCase
  def setup
    @container = LocusTree::Container.open(File.dirname(__FILE__) + '/minimal_example.bed.idx')
  end

  def test_get_parent
    node = @container.get_node('1',7,0)
    parent_node = node.parent_node
    assert_equal([1,10,0], [parent_node.start, parent_node.stop, parent_node.count])
  end

  def test_get_parent_at_top_level
    node = @container.get_node('1',7,3)
    assert_equal(nil, node.parent_node)
  end

  def test_get_children
    node = @container.get_node('1',15,1)
    child_nodes = node.child_nodes
    assert_equal(2, child_nodes.length)
    assert_equal([11,15,0], [child_nodes[0].start, child_nodes[0].stop, child_nodes[0].count])
    assert_equal([16,20,0], [child_nodes[1].start, child_nodes[1].stop, child_nodes[1].count])
  end

  def test_get_children_at_bottom_level
    node = @container.get_node('1',7,0)
    assert_equal([], node.child_nodes)
  end
end
