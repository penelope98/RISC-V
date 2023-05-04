### R-type instruction description 

func7, rs2, and rs1 fields are all 5 bits wide, the func3 field is 3 bits wide, the rd field is 5 bits wide, and the opcode field is 7 bits wide.

| inst | func7  | rs2   | rs1 | func3 | rd  | opcode  |
| ---- | ------ | ----- | --- | ----- | --- | ------- |
| add  | 000000 | 00000 | rs1 | 000   | rd  | 0011001 |
| sub  | 010000 | 00000 | rs1 | 000   | rd  | 0011001 |
| and  | 000000 | rs2   | rs1 | 000   | rd  | 0011001 |
| sll  | 000000 | rs2   | rs1 | 001   | rd  | 0011001 |
| slt  | 000000 | rs2   | rs1 | 010   | rd  | 0011001 |
| sltu | 000000 | rs2   | rs1 | 011   | rd  | 0011001 |
| xor  | 000000 | rs2   | rs1 | 100   | rd  | 0011001 |
| srl  | 000000 | rs2   | rs1 | 101   | rd  | 0011001 |
| sra  | 010000 | rs2   | rs1 | 101   | rd  | 0011001 |
| or   | 000000 | rs2   | rs1 | 110   | rd  | 0011001 |



### I_type instruction description 

fence.i	12	0	001	0	000111 slti	12	1	010	rd	001001

| Instruction | imm[11:0]   | rs1 | funct3 | rd  | opcode  |
| ----------- | ----------- | --- | ------ | --- | ------- |
| addi        | I-immediate | rs1 | 000    | rd  | 0001101 |
| slli        | shamt[4:0]  | rs1 | 001    | rd  | 0001101 |
| slti        | I-immediate | rs1 | 010    | rd  | 0001101 |
| sltiu       | I-immediate | rs1 | 011    | rd  | 0001101 |
| xori        | I-immediate | rs1 | 100    | rd  | 0001101 |
| srli        | shamt[4:0]  | rs1 | 101    | rd  | 0001101 |
| srai        | shamt[4:0]  | rs1 | 101    | rd  | 0001101 |
| ori         | I-immediate | rs1 | 110    | rd  | 0001101 |
| andi        | I-immediate | rs1 | 111    | rd  | 0001101 |
| lb          | I-immediate | rs1 | 000    | rd  | 0000011 |
| lh          | I-immediate | rs1 | 001    | rd  | 0000011 |
| lw          | I-immediate | rs1 | 010    | rd  | 0000011 |
| lbu         | I-immediate | rs1 | 100    | rd  | 0000011 |
| lhu         | I-immediate | rs1 | 101    | rd  | 0000011 |
| jalr        | I-immediate | rs1 | 000    | rd  | 1000011 |


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



### compressed instuction
| instruction  | funct6 | rd/rs1 | func2 | rs2         | opcode |
| ------------ | ------ | ------ | ----- | ----------- | ------ |
| C.FLD        | 011    | t      | 00    | aqrl        | 00     |
| C.LW         | 010    | t      | 00    | aqrl        | 00     |
| C.FLW        | 011    | t      | 01    | aqrl        | 00     |
| C.FSD        | 011    | t      | 00    | aqrl        | 01     |
| C.SW         | 010    | t      | 00    | aqrl        | 01     |
| C.FSW        | 011    | t      | 01    | aqrl        | 01     |
| C.NOP        | 000    | 0      | 00    | 0           | 01     |
| C.ADDI       | 000    | t      | 00    | imm[5:0]    | 10     |
| C.JAL        | 000    | t      | 01    | imm[8:0]    | 10     |
| C.LI         | 000    | t      | 10    | imm[5:0]    | 10     |
| C.ADDI16SP   | 000    | t      | 11    | nzuimm[8:4] | 10     |
| C.LUI        | 000    | t      | 11    | imm[17:12]  | 10     |
| C.SRLI_RV32I | 000    | t      | 10    | shamt[4:0]  | 10     |
| C.SRAI_RV32I | 010    | t      | 10    | shamt[4:0]  | 10     |
| C.ANDI       | 100    | t      | 10    | imm[5:0]    | 10     |
| C.SUB        | 000    | t      | 00    | rs2         | 11     |
| C.XOR        | 100    | t      | 00    | rs2         | 11     |
| C.OR         | 010    | t      | 00    | rs2         | 11     |
| C.AND        | 110    | t      | 00    | rs2         | 11     |
| C.SUBW       | 000    | t      | 01    | rs2         | 11     |
| C.ADDW       | 000    | t      | 00    | rs2         | 11     |
| C.J          | 000    | t      | 01    | offset[8:1] | 11     |
| C.ADDI4SPN   | 000    | t      | 00    | nzuimm[9:2] | 00     |
| C.BEQZ       | 000    | t      | 00    | offset[8:1] | 11     |
| C.BNEZ       | 001    | t      | 00    | offset[8:1] | 11     |











