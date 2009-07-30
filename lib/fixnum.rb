class Fixnum
  def node_number(base_size, nr_children, level)
    return self.div(base_size).div(nr_children**level) + 1
  end
end