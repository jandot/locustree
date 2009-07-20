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

    belongs_to :tree
    has n, :nodes
  end
end