require 'test/unit'
require 'enumerator'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

STORE_FILENAME = File.dirname(__FILE__) + '/data.store'

class BulkLoad < Test::Unit::TestCase
  def setup
    locus_tree = LocusContainer.new(2,3)
    locus_tree.bulk_load(File.dirname(__FILE__) + '/data/loci_with_values.gff')
    locus_tree.store(STORE_FILENAME)
    @loaded_loci = LocusContainer.load(STORE_FILENAME)
  end

  def test_levels
    assert_equal(20, @loaded_loci.trees['1'].nodes[0].length)
    assert_equal(7, @loaded_loci.trees['1'].nodes[1].length)
    assert_equal(3, @loaded_loci.trees['1'].nodes[2].length)
    assert_equal(1, @loaded_loci.trees['1'].nodes[3].length)
    assert_equal(3, @loaded_loci.trees['2'].nodes[0].length)
  end

  def teardown
    File.delete(STORE_FILENAME)
  end
end