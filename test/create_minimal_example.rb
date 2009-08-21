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
f << [287,315,327,339,351,379,391,403,439,451,463,475,503,515,543,555,567,579,607].pack("Q*")

# Data
f << [1,5,1,1,17,22].pack("I5Q")       # 287 = byte offset of start of this line
f << [6,10,0].pack("I*")               # 315
f << [11,15,0].pack("I*")              # 327
f << [16,20,0].pack("I*")              # 339
f << [21,25,1,1,19,64].pack("I5Q")     # 351
f << [26,28,0].pack("I*")              # 379
f << [1,10,0].pack("I*")               # 391
f << [11,20,2,1,39,31,42].pack("I5Q2") # 403
f << [21,28,0].pack("I*")              # 439
f << [1,20,0].pack("I*")               # 451
f << [21,28,0].pack("I*")              # 463
f << [1,28,1,1,12,53].pack("I5Q")      # 475
f << [1,5,0].pack("I*")                # 503
f << [6,10,1,1,5,75].pack("I5Q")       # 515
f << [11,15,0].pack("I*")              # 543
f << [16,19,0].pack("I*")              # 555
f << [1,10,0].pack("I*")               # 567
f << [11,19,1,1,9,83].pack("I5Q")      # 579
f << [1,19,0].pack("I*")               # 607
f.close

