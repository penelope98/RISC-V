### R-type instruction description 

func7, rs2, and rs1 fields are all 5 bits wide, the func3 field is 3 bits wide, the rd field is 5 bits wide, and the opcode field is 7 bits wide.

| func7  | rs2   | rs1 | func3 | rd  | opcode | inst |
| ------ | ----- | --- | ----- | --- | ------ | ---- |
| 000000 | 00000 | rs1 | 000   | rd  | 011001 | add  |
| 010000 | 00000 | rs1 | 000   | rd  | 011001 | sub  |
| 000000 | rs2   | rs1 | 000   | rd  | 011001 | and  |
| 000000 | rs2   | rs1 | 001   | rd  | 011001 | sll  |
| 000000 | rs2   | rs1 | 010   | rd  | 011001 | slt  |
| 000000 | rs2   | rs1 | 011   | rd  | 011001 | sltu |
| 000000 | rs2   | rs1 | 100   | rd  | 011001 | xor  |
| 000000 | rs2   | rs1 | 101   | rd  | 011001 | srl  |
| 010000 | rs2   | rs1 | 101   | rd  | 011001 | sra  |
| 000000 | rs2   | rs1 | 110   | rd  | 011001 | or   |
|        |       |     |       |     |        |      |

