module LocusTree
  # == Description
  #
  # The LocusTree::Level class describes a level in the tree. Level 0 corresponds
  # to the level of the leaf nodes.
  #
  class Level
    attr_accessor :tree, :number, :offset, :nr_nodes
    attr_accessor :node_offsets

    def initialize(tree, number, offset, nr_nodes)
      @tree, @number, @offset, @nr_nodes = tree, number, offset, nr_nodes
      @node_offsets = Array.new
    end

    def nodes(start = 0, stop = start)
      answer = Array.new
      resolution_at_level = @tree.container.base_size*(@tree.container.nr_children**@number)
      start_node = (start-1).div(resolution_at_level)
      stop_node = (stop-1).div(resolution_at_level)

      @tree.container.index_file.pos = @node_offsets[start_node]
      (stop_node - start_node + 1).times do
        start, stop, count = @tree.container.index_file.read(12).unpack("I3")
        flag, sum, min, max = 0, nil, nil, nil
        feature_offsets = Array.new
        if count > 0
          flag = @tree.container.index_file.read(4).unpack("I")[0]
          if flag == 1
            sum = @tree.container.index_file.read(4).unpack("I")[0]
          elsif flag == 2
            min = @tree.container.index_file.read(4).unpack("I")[0]
          elsif flag == 4
            max = @tree.container.index_file.read(4).unpack("I")[0]
          elsif flag == 3
            sum, min = @tree.container.index_file.read(8).unpack("I2")
          elsif flag == 5
            sum, max = @tree.container.index_file.read(8).unpack("I2")
          elsif flag == 6
            min, max = @tree.container.index_file.read(8).unpack("I2")
          elsif flag == 7
            sum, min, max = @tree.container.index_file.read(12).unpack("I3")
          end
          feature_offsets = @tree.container.index_file.read(count*8).unpack("Q*")
        end
        node = LocusTree::Node.new(self, start, stop, count, flag, sum, min, max, feature_offsets)
        answer.push node
      end
      return answer
    end
  end
end
