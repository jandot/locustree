module LocusTree
  # == Description
  #
  # The LocusTree::Tree class is similar to an R-Tree. It contains a collection
  # of nodes where the toplevel node covers the whole of a chromosome and the
  # bottom level nodes (level 0) correspond to single raw datapoints. Different
  # chromosomes cannot be part of the same tree (see LocusTree::Container).
  class Tree
    include DataMapper::Resource

    property :id, Integer, :serial => true
    property :container_id, Integer
    property :chromosome, String
    property :max_level, Integer
    belongs_to :container
    has n, :levels

    def top_level
      return self.levels.sort_by{|l| l.number}[-1]
    end

    def aggregate
      self.levels.sort_by{|l| l.number}.each do |level|
        level.aggregate
      end
    end

#    # == Description
#    #
#    # Returns the root node.
#    #
#    # == Usage
#    #
#    #   tree.root
#    #
#    # ---
#    # *Arguments*:: none
#    # *Returns*:: Node object
#    def root
#      return Node.first(:id => self.root_id)
#    end

#    # == Description
#    #
#    # Searches to tree for a locus.
#    #
#    # == Usage
#    #
#    #   tree.search(Locus.new('1', 1, 5000), 1)
#    #
#    # ---
#    # *Arguments*:
#    # * _locus_ (required):: locus to search for. E.g. Locus.new('1', 1, 5000)
#    # * _search_level_ (optional):: level to collect nodes from (default = 0)
#    # * _start_node_ (optional):: node to start search from (default = root node)
#    # *Returns*:: Array of Node objects
#    def search(locus, search_level = 0, start_node = self.root)
#      if start_node == self.root
#        @positive_nodes = Array.new
#      end
#
#      if search_level == self.depth
#        @positive_nodes = [self.root]
#        return @positive_nodes
#      end
#
#      start_node.children.each do |child_node|
#        if child_node.locus.overlaps?(locus)
#          if child_node.level.number > search_level
#            self.search(locus, search_level, child_node)
#          else
#            @positive_nodes.push(child_node)
#          end
#        else
#        end
#      end
#      return @positive_nodes
#    end



    # == Description
    #
    # Prints out the tree
    #
    # == Usage
    #
    #   puts tree.to_s
    #
    # ---
    # *Arguments*:: none
    # *Returns*:: String
    def to_s
      output = Array.new
      output.push self.chromosome.to_s
      self.levels.each do |level|
        output.push "\t" + level.number.to_s + "\t" + level.resolution.to_s
        level.nodes.each do |node|
          output.push "\t\t" + node.start.to_s + "\t" + node.stop.to_s
        end
      end
      return output.join("\n")
    end
  end
end
