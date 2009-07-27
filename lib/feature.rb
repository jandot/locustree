module LocusTree
  class Feature
    include DataMapper::Resource

    property :id, Integer, :serial => true
    property :node_id, String
    property :chr, String
    property :start, Integer
    property :stop, Integer
    property :value, Float

    belongs_to :node
  end
end