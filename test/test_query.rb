require 'test/unit'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class TestQuery < Test::Unit::TestCase
  def setup
    @container = LocusTree::Container.open(File.dirname(__FILE__) + '/minimal_example.bed.idx')
  end

  # Get node for single position
  def test_get_node_single_position_no_features
    node = @container.get_node('1',7,0)
    assert_equal([6,10,0,0,nil], [node.start, node.stop, node.count, node.flag, node.sum])
    assert_equal([], node.feature_byte_offsets)
  end

  def test_get_node_single_position_one_feature
    node = @container.get_node('1',1,0)
    assert_equal([1,5,1,1,17], [node.start, node.stop, node.count, node.flag, node.sum])
    assert_equal([22], node.feature_byte_offsets)
  end

  def test_get_node_single_position_multiple_features
    node = @container.get_node('1',15,1)
    assert_equal([11,20,2,1,39], [node.start, node.stop, node.count, node.flag, node.sum])
    assert_equal([31,42], node.feature_byte_offsets)
  end

  # Get nodes for range
  def test_get_node_range_no_features
    nodes = @container.get_nodes('1',12,27,0)
    assert_equal(4, nodes.length)
    assert_equal([11,15,0], [nodes[0].start, nodes[0].stop, nodes[0].flag])
    assert_equal([16,20,0], [nodes[1].start, nodes[1].stop, nodes[1].flag])
    assert_equal([21,25,0], [nodes[2].start, nodes[2].stop, nodes[2].flag])
    assert_equal([26,28,0], [nodes[3].start, nodes[3].stop, nodes[3].flag])
  end

  def test_get_node_range_one_feature
    nodes = @container.get_nodes('2',3,14,0)
    assert_equal(3, nodes.length)
    assert_equal([1,5,0], [nodes[0].start, nodes[0].stop, nodes[0].flag])
    assert_equal([6,10,1,1,5,[64]], [nodes[1].start, nodes[1].stop, nodes[1].count, nodes[1].flag, nodes[1].sum, nodes[1].feature_byte_offsets])
    assert_equal([11,15,0], [nodes[2].start, nodes[2].stop, nodes[2].flag])
  end

  def test_get_node_range_multiple_features
    nodes = @container.get_nodes('1',5,25,1)
    assert_equal(3, nodes.length)
    assert_equal([1,10,0], [nodes[0].start, nodes[0].stop, nodes[0].flag])
    assert_equal([11,20,2,1,39,[31,42]], [nodes[1].start, nodes[1].stop, nodes[1].count, nodes[1].flag, nodes[1].sum, nodes[1].feature_byte_offsets])
    assert_equal([21,28,0], [nodes[2].start, nodes[2].stop, nodes[2].flag])
  end

  # Get enclosing node
  def test_get_enclosing_node
    node = @container.get_enclosing_node('1', 12, 16)
    assert_equal(1, node.level.number)
    assert_equal([11,20,2,1], [node.start, node.stop, node.count, node.flag])
  end
end
