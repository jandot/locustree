require 'test/unit'
require 'enumerator'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class BulkLoad < Test::Unit::TestCase
  def setup
    @locus_tree = LocusContainer.new(2,3)
    @locus_tree.bulk_load(File.dirname(__FILE__) + '/data/loci_with_values.gff')
  end

  def test_levels
    assert_equal(20, @locus_tree.trees['1'].nodes[0].length)
    assert_equal(7, @locus_tree.trees['1'].nodes[1].length)
    assert_equal(3, @locus_tree.trees['1'].nodes[2].length)
    assert_equal(1, @locus_tree.trees['1'].nodes[3].length)
  end

  def test_depth
    assert_equal(3, @locus_tree.trees['1'].depth)
  end
end