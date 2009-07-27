module LocusTree
  # == Description
  #
  # The LocusTree::Level class describes a level in the tree. Level 0 corresponds
  # to the level of the leaf nodes.
  #
  class Level
    include DataMapper::Resource

    property :id, Integer, :serial => true
    property :tree_id, Integer
    property :number, Integer
    property :resolution, Integer # in bp/node
    property :node_ids, String

    belongs_to :tree

    def nodes
      chr = self.tree.chromosome
      return LocusTree::Node.all(:conditions => ["id LIKE '#{chr}.#{self.number.to_s}.%'"])
    end

    def aggregate
      nr = LocusTree::Node.count(:level_id => self.id)
      STDERR.puts "Got nr: " + nr.to_s
      pbar = ProgressBar.new(self.number.to_s, nr)
      nodes = self.nodes
      STDERR.puts "Got #{nodes.length.to_s} nodes"
      nodes.each do |node|
        pbar.inc
        node.aggregate
      end
      pbar.finish
    end
  end
end
