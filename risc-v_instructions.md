### R-type instruction description 

func7, rs2, and rs1 fields are all 5 bits wide, the func3 field is 3 bits wide, the rd field is 5 bits wide, and the opcode field is 7 bits wide.

| inst | func7  | rs2   | rs1 | func3 | rd  | opcode  |
| ---- | ------ | ----- | --- | ----- | --- | ------- |
| add  | 000000 | 00000 | rs1 | 000   | rd  | 0110011 |
| sub  | 010000 | 00000 | rs1 | 000   | rd  | 0110011 |
| and  | 000000 | rs2   | rs1 | 111   | rd  | 0110011 |
| sll  | 000000 | rs2   | rs1 | 001   | rd  | 0110011 |
| slt  | 000000 | rs2   | rs1 | 010   | rd  | 0110011 |
| sltu | 000000 | rs2   | rs1 | 011   | rd  | 0110011 |
| xor  | 000000 | rs2   | rs1 | 100   | rd  | 0110011 |
| srl  | 000000 | rs2   | rs1 | 101   | rd  | 0110011 |
| sra  | 010000 | rs2   | rs1 | 101   | rd  | 0110011 |
| or   | 000000 | rs2   | rs1 | 110   | rd  | 0110011 |



### I_type instruction description 

fence.i	12	0	001	0	000111 slti	12	1	010	rd	001001

| Instruction | imm[11:0]   | rs1 | funct3 | rd  | opcode  |
| ----------- | ----------- | --- | ------ | --- | ------- |
| addi        | I-immediate | rs1 | 000    | rd  | 0010011 |
| slli        | 0s+sham[4:0]| rs1 | 001    | rd  | 0010011 |
| slti        | I-immediate | rs1 | 010    | rd  | 0010011 |
| sltiu       | I-immediate | rs1 | 011    | rd  | 0010011 |
| xori        | I-immediate | rs1 | 100    | rd  | 0010011 |
| srli        | 0s+sham[4:0]| rs1 | 101    | rd  | 0010011 |
| srai        | shamt[4:0]  | rs1 | 101    | rd  | 0010011 |
| ori         | I-immediate | rs1 | 110    | rd  | 0010011 |
| andi        | I-immediate | rs1 | 111    | rd  | 0010011 |
| lb          | I-immediate | rs1 | 000    | rd  | 0000011 |
| lh          | I-immediate | rs1 | 001    | rd  | 0000011 |
| lw          | I-immediate | rs1 | 010    | rd  | 0000011 |
| lbu         | I-immediate | rs1 | 100    | rd  | 0000011 |
| lhu         | I-immediate | rs1 | 101    | rd  | 0000011 |
| jalr        | I-immediate | rs1 | 000    | rd  | 1100111 |


### B_type instruction description 

| instruction | imm[12][10:5] | rs2 | rs1 | func3 | imm[4:1][11] | opcode  |
| ----------- | ------------- | --- | --- | ----- | ------------ | ------- |
| beq         | imm[12][10:5] | rs2 | rs1 | 000   | imm[4:1][11] | 1100011 |
| bne         | imm[12][10:5] | rs2 | rs1 | 001   | imm[4:1][11] | 1100011 |
| blt         | imm[12][10:5] | rs2 | rs1 | 100   | imm[4:1][11] | 1100011 |
| bge         | imm[12][10:5] | rs2 | rs1 | 101   | imm[4:1][11] | 1100011 |
| bltu        | imm[12][10:5] | rs2 | rs1 | 110   | imm[4:1][11] | 1100011 |
| bgeu        | imm[12][10:5] | rs2 | rs1 | 111   | imm[4:1][11] | 1100011 |


### U_type instruction description 


| instruction | imm[31:12] | rd  | opcode  |
| ----------- | ---------- | --- | ------- |
| lui         | 20 bits    | rd  | 0110111 |





### S_type instruction description 

| instruction | imm[11:5] | rs2 | rs1 | func3 | imm[4:0] | opcode  |
| ----------- | --------- | --- | --- | ----- | -------- | ------- |
| sw          | 7 bits    | rs2 | rs1 | 010   | 5 bits   | 0100011 |



### compressed instuction opcode 00
| instruction | funct(15:13) | imm(12:10) | rs1(9:7) | imm(6,5)  | rd/rs2(4:2) | opcode(1,0) |
| ----------- | ------------ | ---------- | -------- | --------- | ----------- | ----------- |
| C.LW        | 010          | uimm[5:3]  | rs1      | uimm[2,6] | rd          | 00          |
| C.SW        | 110          | uimm[5:3]  | rs1      | uimm[2,6] | rs2         | 00          |


### compressed instuction opcode 01
| instruction | funct(15:13) | imm(12)   | rs1/rd(11:7) | imm/rs2(6:2) | opcode(1,0) |
| ----------- | ------------ | --------- | ------------ | ------------ | ----------- |
| C.ADDI      | 000          | nzimm[5]  | /= 0         | nzimm[4:0]   | 01          |
| C.LUI       | 000          | nzimm[17] | rd /= {0,2}  | nzimm[16:12] | 01          |
| C.LI        | 010          | imm[5]    | /= 0         | imm[4:0]     | 01          |
| C.SRLI      | 100          | nzimm[5]  | 00    rs1/rd | nzimm[4:0]   | 01          |
| C.SRAI      | 100          | nzimm[5]  | 01    rs1/rd | nzimm[4:0]   | 01          |
| C.ANDI      | 100          | imm[5]    | 10    rs1/rd | imm[5:0]     | 01          |
| C.SUB       | 100          | 0         | 11    rs1/rd | 00,rs2       | 01          |
| C.XOR       | 100          | 0         | 11    rs1/rd | 01,rs2       | 01          |
| C.OR        | 100          | 0         | 11    rs1/rd | 10,rs2       | 01          |
| C.AND       | 100          | 0         | 11    rs1/rd | 11,rs2       | 01          |


### compressed instuction opcode 11
| instruction | funct(15:13) | imm(12)   | rs1/rd(11:7) | imm/rs2(6:2) | opcode(1,0) |
| ----------- | ------------ | --------- | ------------ | ------------ | ----------- |
| C.SLLI      | 000          | nzuimm[5] | /= 0         | nzuimm[5:0]  | 10          |
| C.ADD       | 100          | 1         | /= 0         | /= 0         | 10          |





