module LocusTree
  # == Description
  #
  # The LocusTree::Level class describes a level in the tree. Level 0 corresponds
  # to the level of the leaf nodes.
  #
  class Level
    attr_accessor :tree, :number, :nr_nodes
    attr_accessor :node_offsets

    def initialize(tree, number, nr_nodes)
      @tree, @number, @nr_nodes = tree, number, nr_nodes
      @node_offsets = Array.new
    end

    def nodes(start = 0, stop = start)
      answer = Array.new
      resolution_at_level = @tree.container.base_size*(@tree.container.nr_children**@number)
      start_node = (start-1).div(resolution_at_level)
      stop_node = (stop-1).div(resolution_at_level)

#      STDERR.puts ['=====', @number, '=>', @node_offsets].flatten.join("\t")
      STDERR.puts "chr, level, nr_nodes, offset = " + @tree.chromosome.to_s + "\t" + @number.to_s + "\t" + @nr_nodes.to_s + "\t" + @node_offsets[start_node].to_s
#      if @node_offsets[start_node].nil?
#        STDERR.puts "===ERROR==="
#      else
      @tree.container.index_file.pos = @node_offsets[start_node]
      (stop_node - start_node + 1).times do
        node_byte_offset = @tree.container.index_file.pos
        STDERR.puts "node byte offset: " + node_byte_offset.to_s
        start, stop, total_count, count = @tree.container.index_file.read(16).unpack("I4")
        sum, min, max = nil, nil, nil
        feature_offsets = Array.new
        if total_count > 0
          if @tree.container.aggregate_flag == 1
            sum = @tree.container.index_file.read(4).unpack("I")[0]
          elsif @tree.container.aggregate_flag == 2
            min = @tree.container.index_file.read(4).unpack("I")[0]
          elsif @tree.container.aggregate_flag == 4
            max = @tree.container.index_file.read(4).unpack("I")[0]
          elsif @tree.container.aggregate_flag == 3
            sum, min = @tree.container.index_file.read(8).unpack("I2")
          elsif @tree.container.aggregate_flag == 5
            sum, max = @tree.container.index_file.read(8).unpack("I2")
          elsif @tree.container.aggregate_flag == 6
            min, max = @tree.container.index_file.read(8).unpack("I2")
          elsif @tree.container.aggregate_flag == 7
            sum, min, max = @tree.container.index_file.read(12).unpack("I3")
          end
          feature_offsets = @tree.container.index_file.read(count*8).unpack("Q*")
        end
        node = LocusTree::Node.new(self, start, stop, total_count, count, sum, min, max, feature_offsets)
#        STDERR.puts "The feature offsets: " + feature_offsets.join("\t")
        node.byte_offset = node_byte_offset
        answer.push node
#      end
      end
      return answer
    end
  end
end
