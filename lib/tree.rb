module LocusTree
  # == Description
  #
  # The LocusTree::Tree class is similar to an R-Tree. It contains a collection
  # of nodes where the toplevel node covers the whole of a chromosome and the
  # bottom level nodes (level 0) correspond to single raw datapoints. Different
  # chromosomes cannot be part of the same tree (see LocusTree::Container).
  class Tree
    attr_accessor :container
    attr_accessor :chromosome, :chromosome_length, :nr_levels
    attr_accessor :levels
    attr_accessor :level_offsets

    def initialize(container, chr, chr_length, nr_levels)
      @container, @chromosome, @chromosome_length, @nr_levels = container, chr, chr_length, nr_levels
      @levels = Hash.new
    end

    def enclosing_node(start, stop)
      level_number = @levels.keys.max
      resolution_at_level = @container.base_size*(@container.nr_children**level_number)
      previous_start_bin = 0
      previous_level_number = level_number
      start_bin = (start-1).div(resolution_at_level)
      stop_bin = (stop-1).div(resolution_at_level)
      while start_bin == stop_bin and level_number > 0
        previous_start_bin = start_bin
        previous_level_number = level_number
        level_number -= 1
        resolution_at_level = @container.base_size*(@container.nr_children**level_number)
        start_bin = (start-1).div(resolution_at_level)
        stop_bin = (stop-1).div(resolution_at_level)
      end
      level = @levels[previous_level_number]
      return level.nodes(start,stop)[0]
    end
  end
end
