module LocusTree
  class Feature
    attr_accessor :chromosome, :start, :stop, :value

    def initialize(chr, start, stop, value)
      @chromosome, @start, @stop, @value = chr, start, stop, value
    end
  end
end
