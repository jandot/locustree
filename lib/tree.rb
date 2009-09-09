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

    def map_feature(outfile, start, stop, value, offset)
      start = start.to_i
      stop = stop.to_i
      level_number = @nr_levels - 1 #((Math.log(@chromosome_length) - Math.log(@container.base_size)).to_f/Math.log(@container.nr_children)).floor + 1
      resolution_at_level = @container.base_size*(@container.nr_children**level_number)
      start_bin_nr = (start-1).div(resolution_at_level)
      stop_bin_nr = (stop-1).div(resolution_at_level)
      bin_start = start_bin_nr * resolution_at_level + 1

      enclosing_nodes = Array.new
      until level_number == -1 or start_bin_nr < stop_bin_nr
        enclosing_nodes.push([[@chromosome, level_number, start_bin_nr].join(":"), @chromosome, bin_start, [bin_start + resolution_at_level - 1, @chromosome_length].min, 1, value].join("\t"))

        level_number -= 1
        resolution_at_level = @container.base_size*(@container.nr_children**level_number)
        start_bin_nr = (start-1).div(resolution_at_level)
        stop_bin_nr = (stop-1).div(resolution_at_level)
        bin_start = start_bin_nr * resolution_at_level + 1
      end
      smallest = enclosing_nodes.pop
      outfile.puts enclosing_nodes.join("\n") unless enclosing_nodes.length == 0
      outfile.puts smallest + "\t" + offset.to_s
    end

    def enclosing_node(start, stop)
      level_number = @levels.keys.max
      resolution_at_level = @container.base_size*(@container.nr_children**level_number)
      previous_start_bin = 0
      previous_level_number = level_number
      start_bin = (start-1).div(resolution_at_level)
      stop_bin = (stop-1).div(resolution_at_level)
      while start_bin == stop_bin and level_number >= 0
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
