#!/usr/bin/ruby
f = File.open('minimal_example.bed.idx','wb')

# Part A of the header (see Google Document to see what this means)
f << ["LocusTree_v1"].pack("a*")
f << [19].pack("I")
f << ["minimal_example.bed"].pack("a*")
f << [287].pack("Q")
f << [5,2,2].pack("I*")

# Part B of the header
f << [1,28,4,135,183,207,223].pack("I3Q*")
f << [2,19,3,231,263,279].pack("I3Q*")

# Part C of the header
f << [287,315,327,339,351,363,375,387,423,435,447,459,487,499,527,539,551,563,591].pack("Q*")

# Data
f << [1,5,1,1,17,12345].pack("I5Q")
f << [6,10,0].pack("I*")
f << [11,15,0].pack("I*")
f << [16,20,0].pack("I*")
f << [21,25,0].pack("I*")
f << [26,28,0].pack("I*")
f << [1,10,0].pack("I*")
f << [11,20,2,1,39,23456,67890].pack("I5Q2")
f << [21,28,0].pack("I*")
f << [1,20,0].pack("I*")
f << [21,28,0].pack("I*")
f << [1,28,1,1,12,34567].pack("I5Q")
f << [1,5,0].pack("I*")
f << [6,10,1,1,5,45678].pack("I5Q")
f << [11,15,0].pack("I*")
f << [16,19,0].pack("I*")
f << [1,10,0].pack("I*")
f << [11,19,1,1,9,56789].pack("I5Q")
f << [1,19,0].pack("I*")
f.close

