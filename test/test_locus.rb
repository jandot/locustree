require 'test/unit'
require 'enumerator'

require File.dirname(__FILE__) + '/../lib/locus_tree.rb'

class Feature
  include IsLocus
  attr_accessor :chromosome, :start, :stop
end

class LocusTest < Test::Unit::TestCase
  def setup
    @feature_a = Feature.new
    @feature_a.chromosome, @feature_a.start, @feature_a.stop = '1', 1, 1000
    @feature_b = Feature.new
    @feature_b.chromosome, @feature_b.start, @feature_b.stop = '1', 800, 1200
    @feature_c = Feature.new
    @feature_c.chromosome, @feature_c.start, @feature_c.stop = '10', 800, 1200
    @feature_d = Feature.new
    @feature_d.chromosome, @feature_d.start, @feature_d.stop = '1', 500, 900
    @feature_e = Feature.new
    @feature_e.chromosome, @feature_e.start, @feature_e.stop = '1', 9999, 99999
    @feature_f = Feature.new
    @feature_f.chromosome, @feature_f.start, @feature_f.stop = '1', 1500, 5000
  end

  def test_overlap
    assert_equal(true, @feature_a.overlaps?(@feature_b))
    assert_equal(true, @feature_b.overlaps?(@feature_a))
    assert_equal(false, @feature_a.overlaps?(@feature_c))
    assert_equal(false, @feature_c.overlaps?(@feature_a))
    assert_equal(false, @feature_b.overlaps?(@feature_c))
    assert_equal(false, @feature_c.overlaps?(@feature_b))

    assert_equal(true, @feature_a.range.overlaps?(@feature_c.range))
  end

  def test_containment
    assert_equal(true, @feature_a.contains?(@feature_d))
    assert_equal(false, @feature_b.contains?(@feature_d))
    assert_equal(true, @feature_d.contained_by?(@feature_a))
    assert_equal(false, @feature_d.contained_by?(@feature_b))
  end

  def test_merge
    feature_g = @feature_a.merge(@feature_b)
    assert_equal('1', feature_g.chromosome)
    assert_equal(1, feature_g.start)
    assert_equal(1200, feature_g.stop)

    feature_h = @feature_a.merge(@feature_e)
    assert_equal('1', feature_h.chromosome)
    assert_equal(1, feature_h.start)
    assert_equal(99999, feature_h.stop)

    assert_raise(ArgumentError) { @feature_a.merge('abcd')}
    assert_raise(ArgumentError) { @feature_a.merge(@feature_c)}

    feature_i = [@feature_a, @feature_e, @feature_f].merge
    assert_equal('1', feature_i.chromosome)
    assert_equal(1, feature_i.start)
    assert_equal(99999, feature_i.stop)
    assert_raise(ArgumentError) { [@feature_a, @feature_b, 'abcd'].merge}
    assert_raise(ArgumentError) { ['abcd', 'efgh','ijkl'].merge}
    assert_raise(ArgumentError) { [@feature_a, @feature_c].merge}
  end
end