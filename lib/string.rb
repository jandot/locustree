class String
  def pad(filler, len)
    if self.length < len
      output = self
      (len - self.length).times do
        output = filler + output
      end
      return output
    else
      return self
    end
  end
end