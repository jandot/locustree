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
    include DataMapper::Resource

    property :id, String, :key => true #:serial => true
    property :level_id, Integer
    property :start, Integer
    property :stop, Integer
    property :value, Float
    property :child_ids, String

    belongs_to :level
    has n, :features

#    # == Description
#    #
#    # Returns the locus covered by this node.
#    #
#    # == Usage
#    #
#    #   node.locus
#    #
#    # ---
#    # *Arguments*:: none
#    # *Returns*:: Locus object
#    def locus
#      if @locus.nil?
#        @locus = Locus.new(self.chromosome, self.start, self.stop)
#      end
#      return @locus
#    end

    def children
      answer = Array.new
      self.child_ids.split(/,/).each do |child_id|
        answer.push(self.class.first(:id => child_id))
      end
      return answer
    end

    # == Description
    #
    # Returns the children of this node.
    #
    # == Usage
    #
    #   node.children
    #
    # ---
    # *Arguments*:: none
    # *Returns*:: Array of Node objects
    def children_in_range(start, stop)
      chr = self.level.tree.chromosome
      level_nr = self.level.number - 1

      bin_size = self.level.tree.container.nr_children
      answer = Array.new
      first_node_nr = start.divmod(bin_size**(level_nr))[0] + 1
      last_node_nr = stop.divmod(bin_size**(level_nr))[0] + 1

      (first_node_nr..last_node_nr).each do |nr|
        answer.push(self.class.first(:id => [chr, level_nr, nr].join('.')))
      end
      return answer
    end

    def to_s
      return self.level.tree.chromosome + ':' + self.start.to_s + '..' + self.stop.to_s
    end

    def aggregate
      count = 0
      unless self.level.number == 1
        self.children.each do |child|
          count += child.value
        end
      end
      count += LocusTree::Feature.count(:node_id => self.id)
      self.value = count
      self.save
    end
  end
end
