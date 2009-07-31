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
  end
end
