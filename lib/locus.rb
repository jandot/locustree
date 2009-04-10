# To be used as mixin. Classes must provide @chromosome, @start and @stop.
module IsLocus
  attr_accessor :code
  
  def code
    if @code.nil?
      @code = [@chromosome.pad('0', 2), @start.to_s.pad('0', 9), @stop.to_s.pad('0', 9)].join('_')
    else
      return @code
    end
  end

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

  def contains?(other_locus)
    return false if self.chromosome != other_locus.chromosome

    if self.range.contains?(other_locus.range)
      return true
    end

    return false
  end

  def merge(other_locus)
    unless other_locus.class.include?(IsLocus) and other_locus.chromosome == self.chromosome
      raise ArgumentError, "Argument is not a Locus object"
    end

    new_locus = self.class.new
    new_locus.chromosome = self.chromosome
    new_range = self.range.merge(other_locus.range)
    new_locus.start = new_range.begin
    new_locus.stop = new_range.end
    return new_locus
  end

  def to_s
    return self.chromosome + ':' + self.range.to_s
  end

  def to_bed
    return ['chr' + self.chromosome, self.start, self.stop, self.class.name + '_' + self.id.to_s].join("\t")
  end

end

class Array
  # elements have to be of the same class (which implements IsLocus) and be on the same chromosome
  def merge
    if self.entries.collect{|e| e.class}.uniq.length > 1
      raise ArgumentError, "Not all elements of the same class"
    elsif ! self[0].class.include?(IsLocus)
      raise ArgumentError, "Elements must implement IsLocus"
    elsif self.entries.collect{|e| e.chromosome}.uniq.length > 1
      raise ArgumentError, "Not all elements are loci on the same chromosome"
    end

    new_locus = self[0].class.new
    new_locus.chromosome = self[0].chromosome
    new_locus.start = self.entries.collect{|e| e.start}.min
    new_locus.stop = self.entries.collect{|e| e.stop}.max
    return new_locus
  end
end