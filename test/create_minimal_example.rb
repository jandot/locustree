#!/usr/bin/ruby
f = File.open('minimal_example.bed.idx','wb')
f << ["LocusTree_v1"].pack("a*")
f << [19].pack("I")
f << ["minimal_example.bed"].pack("a*")
f << [279].pack("Q")
f << [5,2,2].pack("I*")
f << [1,4,127,175,199,215].pack("I2Q*")
f << [2,3,223,255,271].pack("I2Q*")
f << [279,307,319,331,343,355,367,379,415,427,439,451,479,491,519,531,543,555,583].pack("Q*")
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

