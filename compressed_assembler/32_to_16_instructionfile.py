f = open("instructionmem1.mem","r")
j = open("instructionmem2_div.mem","w")
for line in f:
    j.write(line[16:])
    j.write(line[0:16])
    j.write('\n')
f.close()
j.close()
