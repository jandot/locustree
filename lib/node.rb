module LocusTree
  # == Description
  #
  # The LocusTree::Node class describes a single node of the tree. A node
  # contains a number of child-nodes (between Container.min_children and
  # Container.max_children). There are 3 types of nodes: (1) leaf-nodes are
  # at the raw data-level, (2) index nodes are nodes that contain other nodes,
  # and the (3) root node is the index node at the top of the tree, which is
  # not contained in any other node.
  #
  class Node
    attr_accessor :level, :start, :stop, :total_count, :count, :sum, :min, :max
    attr_accessor :feature_byte_offsets
    attr_accessor :byte_offset

    def initialize(level, start, stop, total_count = 0, count = 0, sum = nil, min = nil, max = nil, feature_byte_offsets = [])
      @level, @start, @stop, @total_count, @count, @sum, @min, @max, @feature_byte_offsets = level, start, stop, total_count, count, sum, min, max, feature_byte_offsets
    end

    def to_s
      return [@level.tree.chromosome, @level.number, @start, @stop, @count, @flag, @sum, @min, @max, @feature_byte_offsets].join("\t")
    end

    def parent_node
      return nil if @level.tree.nr_levels == @level.number + 1

      parent_level_number = @level.number + 1
      parent_node = @level.tree.container.get_node(@level.tree.chromosome, @start + @level.tree.container.base_size.div(2), parent_level_number)
      return parent_node
    end

    def child_nodes
      return [] if @level.number == 0

      child_level_number = @level.number - 1
      return @level.tree.container.get_nodes(@level.tree.chromosome, @start, @stop, child_level_number)
    end

    def add_feature(feature_offset, value)
#      STDERR.puts "DEBUG: " + @byte_offset.to_s
      @total_count += 1
      @sum = ( @sum.nil? ) ? value : @sum + value
      unless feature_offset.nil?
        @count += 1
        @feature_byte_offsets.push(feature_offset)
      end
      self.save
    end

    def save
      @level.tree.container.index_file.pos = @byte_offset
#      [@start, @stop, @total_count, @count, @sum].each do |f|
#        STDERR.puts f.class.to_s
#      end
#      @feature_byte_offsets.each do |f|
#        STDERR.puts f.class.to_s
#      end
      @level.tree.container.index_file << [@start, @stop, @total_count, @count, @sum, @feature_byte_offsets].flatten.pack("I5Q*")
    end
  end
end
