import numpy as np

COMPRESSED = { "c.lw" : ["010",1,"00"],
               "c.sw":["110",1,"00"],
               "c.addi":["000",2,"01"],
               "c.lui":["000",2,"01"],
               "c.li":["010",2,"01"],
               "c.srli":["100",3,"01","00"],
               "c.srai":["100",3,"01","01"],
               "c.andi":["100",3,"01","10"],
               "c.sub":["100",4,"01","00"],
               "c.xor":["100",4,"01","01"],
               "c.or":["100",4,"01","10"],
               "c.and":["100",4,"01","11"],
               "c.slli":["000",5,"10"],
               "c.mv":["100",6,"10"],
               "c.add":["100",6,"10"]}

def COMP_TRANSLATE():
    f = open("compressed.txt", "r")
    binf = open("compressed_bin.mem","w")
    for instr_line in f:
        instr_clean = instr_line.replace(',',' ')[:-1]
        instr_clean = instr_clean.replace('\n',' ')
        instr_pieces = instr_clean.split(' ')
        if(len(instr_line)>1):
            ##binf.write(instr_pieces[0])
            ##print(instr_pieces)
            entry = COMPRESSED[instr_pieces[0]]       
            match entry[1]:
                case 1: #lw sw
                    rd_rs2 = np.binary_repr(int(instr_pieces[1][1:]),3)
                    rs1 = np.binary_repr(int(instr_pieces[2][1:]),3)
                    offst = np.binary_repr(int(instr_pieces[3]),5)
                    bini = entry[0] + offst[1:-1] + rs1 + offst[-1] + offst[0] + rd_rs2 + entry[2]                
                    #print(bini)
                case 2: #addi lui li
                    rs1_rd = np.binary_repr(int(instr_pieces[1][1:]),5)
                    nzimm = np.binary_repr(int(instr_pieces[2]),6)
                    if ( int(instr_pieces[2]) == 0 and ( instr_pieces[0]=="c.addi" or  instr_pieces[0]=="c.lui" )):
                        print( "WARNING: zero immediate for " + instr_pieces[0] )
                    if ( int(instr_pieces[1][1:]) == 0):
                        print( "WARNING: zero dest reg for " + instr_pieces[0] )
                    if ( int(instr_pieces[1][1:]) == 2 and instr_pieces[0]=="c.lui" ):
                        print( "WARNING: invalid dest reg for " + instr_pieces[0] )    
                    bini = entry[0] + nzimm[0] + rs1_rd + nzimm[1:] + entry[2]
                case 3: #srli srai andi
                    rs1_rd = np.binary_repr(int(instr_pieces[1][1:]),3)
                    shamt_imm = np.binary_repr(int(instr_pieces[2]),6)
                    if ( int(instr_pieces[2]) == 0 and ( instr_pieces[0]=="c.srli" or  instr_pieces[0]=="c.srai" )):
                        print( "WARNING: zero immediate for " + instr_pieces[0] )
                    bini = entry[0] + shamt_imm[0] + entry[3] + rs1_rd + shamt_imm[1:] + entry[2]
                case 4: #sub,xor,or,and
                    rs1_rd = np.binary_repr(int(instr_pieces[1][1:]),3)
                    rs2 = np.binary_repr(int(instr_pieces[2][1:]),3)
                    bini = entry[0] + "0" + "11" + rs1_rd + entry[3] + rs2 + entry[2]
                case 5: #slli
                    rs1_rd = np.binary_repr(int(instr_pieces[1][1:]),5)
                    shamt = np.binary_repr(int(instr_pieces[2]),6)
                    if(int(instr_pieces[2]) == 0):
                        print( "WARNING: zero immediate for " + instr_pieces[0] )
                    if(int(instr_pieces[1][1:]) == 0):
                        print( "WARNING: zero dest reg for " + instr_pieces[0] )
                    bini = entry[0] + shamt[0] + rs1_rd + shamt[1:] + entry[2]
                case 6: #mv add
                    rs1_rd = np.binary_repr(int(instr_pieces[1][1:]),5)
                    rs2 = np.binary_repr(int(instr_pieces[2][1:]),5)
                    if( instr_pieces[0] == "c.mv" ):
                        f4 = "1"
                    else:
                        f4 = "0"
                    if(int(instr_pieces[2][1:])==0):
                        print( "WARNING:rs2 = x0, invalid "+ instr_pieces[0])
                    bini = entry[0] + f4 + rs1_rd + rs2 + entry[2]
            print(bini)
            binf.write(bini)
            binf.write("\n")
    binf.close()
    f.close()
    return



COMP_TRANSLATE()    
