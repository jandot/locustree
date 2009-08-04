module LocusTree
  # == Description
  #
  # The LocusTree::Tree class is similar to an R-Tree. It contains a collection
  # of nodes where the toplevel node covers the whole of a chromosome and the
  # bottom level nodes (level 0) correspond to single raw datapoints. Different
  # chromosomes cannot be part of the same tree (see LocusTree::Container).
  class Tree
    attr_accessor :container
    attr_accessor :chromosome, :nr_levels
    attr_accessor :levels

    def initialize(container, chr, nr_levels)
      @container, @chromosome, @nr_levels = container, chr, nr_levels
      @levels = Hash.new
    end
  end
end
