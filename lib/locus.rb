# To be used as mixin. Classes must provide @chromosome, @start and @stop.
class IsLocus
  attr_accessor :chromosome, :start, :stop
  attr_accessor :range
  attr_accessor :as_string
  
  def range
    return Range.new(self.start, self.stop)
  end

  def overlaps?(other_locus)
    return false if self.chromosome != other_locus.chromosome

    if self.range.overlaps?(other_locus.range)
      return true
    end

    return false
  end

  def contained_by?(other_locus)
    return false if self.chromosome != other_locus.chromosome

    if self.range.contained_by?(other_locus.range)
      return true
    end

    return false
  end

#  def contains?(other_locus)
#    return false if self.chromosome != other_locus.chromosome
#
#    if self.range.contains?(other_locus.range)
#      return true
#    end
#
#    return false
#  end
#
#  def merge(other_locus)
#    unless other_locus.class == Locus and other_locus.chromosome == self.chromosome
#      raise ArgumentError, "Argument is not a Locus object"
#    end
#
#    new_range = self.range.merge(other_locus.range)
#    new_locus = self.class.new(self.chromosome, new_range.begin, new_range.end)
#    return new_locus
#  end
#
#  def to_s
#    return self.chromosome + ':' + self.range.to_s
#  end
#
#  def to_bed
#    return ['chr' + self.chromosome, self.start, self.stop, self.class.name + '_' + self.id.to_s].join("\t")
#  end

end

#class Array
#  def merge
#    if self.collect{|e| e.class}.uniq.length > 1
#      raise ArgumentError, "Not all elements of the same class"
#    elsif not self[0].class == Locus
#      raise ArgumentError, "Elements must be Locus"
#    elsif self.collect{|e| e.chromosome}.uniq.length > 1
#      raise ArgumentError, "Not all elements are loci on the same chromosome"
#    end
#
#    new_locus = Locus.new(self[0].chromosome, self.collect{|e| e.start}.min, self.collect{|e| e.stop}.max)
#    return new_locus
#  end
#end