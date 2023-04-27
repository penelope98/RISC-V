### R-type instruction description 

func7, rs2, and rs1 fields are all 5 bits wide, the func3 field is 3 bits wide, the rd field is 5 bits wide, and the opcode field is 7 bits wide.

| inst | func7  | rs2   | rs1 | func3 | rd  | opcode |
| ---- | ------ | ----- | --- | ----- | --- | ------ |
| add  | 000000 | 00000 | rs1 | 000   | rd  | 011001 |
| sub  | 010000 | 00000 | rs1 | 000   | rd  | 011001 |
| and  | 000000 | rs2   | rs1 | 000   | rd  | 011001 |
| sll  | 000000 | rs2   | rs1 | 001   | rd  | 011001 |
| slt  | 000000 | rs2   | rs1 | 010   | rd  | 011001 |
| sltu | 000000 | rs2   | rs1 | 011   | rd  | 011001 |
| xor  | 000000 | rs2   | rs1 | 100   | rd  | 011001 |
| srl  | 000000 | rs2   | rs1 | 101   | rd  | 011001 |
| sra  | 010000 | rs2   | rs1 | 101   | rd  | 011001 |
| or   | 000000 | rs2   | rs1 | 110   | rd  | 011001 |


### I_type instruction description 



fence.i	12	0	001	0	000111 slti	12	1	010	rd	001001

| Instruction | imm[11:0]   | rs1 | funct3 | rd  | opcode |
| ----------- | ----------- | --- | ------ | --- | ------ |
| addi        | I-immediate | rs1 | 0x0    | rd  | 0x13   |
| slli        | shamt[4:0]  | rs1 | 0x1    | rd  | 0x13   |
| slti        | I-immediate | rs1 | 0x2    | rd  | 0x13   |
| sltiu       | I-immediate | rs1 | 0x3    | rd  | 0x13   |
| xori        | I-immediate | rs1 | 0x4    | rd  | 0x13   |
| srli        | shamt[4:0]  | rs1 | 0x5    | rd  | 0x13   |
| srai        | shamt[4:0]  | rs1 | 0x5    | rd  | 0x13   |
| ori         | I-immediate | rs1 | 0x6    | rd  | 0x13   |
| andi        | I-immediate | rs1 | 0x7    | rd  | 0x13   |
| lb          | I-immediate | rs1 | 0x0    | rd  | 0x03   |
| lh          | I-immediate | rs1 | 0x1    | rd  | 0x03   |
| lw          | I-immediate | rs1 | 0x2    | rd  | 0x03   |
| lbu         | I-immediate | rs1 | 0x4    | rd  | 0x03   |
| lhu         | I-immediate | rs1 | 0x5    | rd  | 0x03   |
| jalr        | I-immediate | rs1 | 0x0    | rd  | 0x67   |


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


| instruction | imm[31:12] | rd  | opcode |
| ----------- | ---------- | --- | ------ |
| lui         | 20 bits    | rd  | 01101  |




### S_type instruction description 

| instruction | imm[11:5] | rs2 | rs1 | func3 | imm[4:0] | opcode |
| ----------- | --------- | --- | --- | ----- | -------- | ------ |
| sw          | 7 bits    | rs2 | rs1 | 010   | 5 bits   | 00011  |



