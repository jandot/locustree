class Range
  def middle
    return (self.begin + self.end)/2
  end

  def size
    return self.end - self.begin + 1
  end

  def overlaps?(other_range)
    if self.include?(other_range.begin) or other_range.include?(self.begin)
      return true
    end

    return false
  end

  def contained_by?(other_range)
    if other_range.include?(self.begin) and other_range.include?(self.end)
      return true
    end

    return false
  end

  def contains?(other_range)
    if self.include?(other_range.begin) and self.include?(other_range.end)
      return true
    end

    return false
  end

  def overlap(other_range)
    return Range.new([self.begin, other_range.begin].max, [self.end, other_range.end].min)
  end

  #Note: you _can_ merge ranges that do not overlap. The region in between them will just
  # be added to that range.
  def merge(other_range)
    return Range.new([self.begin, other_range.begin].min, [self.end, other_range.end].max)
  end

  def percentage_overlap(other_range)
    if self.overlaps?(other_range)
      return self.overlap(other_range).size.to_f/self.size
    else
      return 0
    end
  end

  def minimum_reciprocal_overlap(other_range)
    return [self.percentage_overlap(other_range),other_range.percentage_overlap(self)].min
  end

  def distance(other_range)
    return 0 if self.overlaps?(other_range)
    if (self.begin > other_range.begin)
      return self.begin - other_range.end
    else
      return other_range.begin - self.end
    end
  end
end