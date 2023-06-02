f = open("a.b","r")
j = open("32_to_16_bits_converted.mem","w")
for line in f:
    j.write(line[16:])
    j.write(line[0:16])
    j.write('\n')
f.close()
j.close()
