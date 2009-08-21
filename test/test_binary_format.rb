require 'test/unit'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class TestBinaryFormat < Test::Unit::TestCase
  def setup
    @container = LocusTree::Container.open(File.dirname(__FILE__) + '/minimal_example.bed.idx')
  end

  def test_trees
    trees = @container.trees.values
    assert_equal(2, trees.length)
    assert_equal('1', trees[0].chromosome)
    assert_equal('2', trees[1].chromosome)
    assert_equal(4, trees[0].nr_levels)
    assert_equal(3, trees[1].nr_levels)
    assert_equal(28, trees[0].chromosome_length)
    assert_equal(19, trees[1].chromosome_length)
  end

  def test_levels
    levels_chr1 = @container.trees['1'].levels.values
    assert_equal(6, levels_chr1[0].nr_nodes)
    assert_equal(6, levels_chr1[0].node_offsets.length)
    assert_equal(3, levels_chr1[1].nr_nodes)
    assert_equal(3, levels_chr1[1].node_offsets.length)
    assert_equal(2, levels_chr1[2].nr_nodes)
    assert_equal(2, levels_chr1[2].node_offsets.length)
    assert_equal(1, levels_chr1[3].nr_nodes)
    assert_equal(1, levels_chr1[3].node_offsets.length)
    assert_equal([287,315,327,339,351,379], levels_chr1[0].node_offsets)
    assert_equal([391,403,439], levels_chr1[1].node_offsets)
    assert_equal([451,463], levels_chr1[2].node_offsets)
    assert_equal([475], levels_chr1[3].node_offsets)

    levels_chr2 = @container.trees['2'].levels.values
    assert_equal(4, levels_chr2[0].nr_nodes)
    assert_equal(4, levels_chr2[0].node_offsets.length)
    assert_equal(2, levels_chr2[1].nr_nodes)
    assert_equal(2, levels_chr2[1].node_offsets.length)
    assert_equal(1, levels_chr2[2].nr_nodes)
    assert_equal(1, levels_chr2[2].node_offsets.length)
    assert_equal([503,515,543,555], levels_chr2[0].node_offsets)
    assert_equal([567,579], levels_chr2[1].node_offsets)
    assert_equal([607], levels_chr2[2].node_offsets)
  end

  def test_nodes
    level = @container.trees['2'].levels[2]
    node = level.nodes(5,5)[0]
    assert_equal([1,19,0], [node.start, node.stop, node.count])
    
    level = @container.trees['1'].levels[0]
    node = level.nodes(2,3)[0]
    assert_equal(1, node.feature_byte_offsets.length)

    level = @container.trees['1'].levels[2]
    node = level.nodes(2,3)[0]
    assert_equal(0, node.feature_byte_offsets.length)
  end
end
