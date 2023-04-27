vsim -gui work.testbench
restart -f -nolist -nowave -nobreak -nolog -novirtuals -noassertions -nofcovers -noatv

add wave -position end  sim:/testbench/sys/clk
add wave -position end  sim:/testbench/sys/reset_n
add wave -position end  sim:/testbench/sys/redundant
add wave -position end -radix "Unsigned" sim:/testbench/sys/program_address
add wave -position end  sim:/testbench/sys/program_data
add wave -position end  sim:/testbench/sys/data_write_en
add wave -position end -radix "Unsigned" sim:/testbench/sys/data_address
add wave -position end  sim:/testbench/sys/data_read
add wave -position end  sim:/testbench/sys/data_write

add wave -position end -color "Orange" sim:/testbench/sys/cpu/program_read
add wave -position end -color "Orange" -radix "Unsigned" sim:/testbench/sys/cpu/pc
add wave -position end -color "Orange" -radix "Unsigned" sim:/testbench/sys/cpu/data_address
add wave -position end -color "Orange" sim:/testbench/sys/cpu/data_read
add wave -position end -color "Orange" sim:/testbench/sys/cpu/data_write


add wave -position end -color "Violet Red" -radix "Unsigned" sim:/testbench/sys/cpu/if_id_next.pc
add wave -position end -color "Violet Red" sim:/testbench/sys/cpu/if_id_next.instruction

add wave -position end -color "Cyan" sim:/testbench/sys/cpu/id_ex_reg.control_alu_op
add wave -position end -color "Cyan" sim:/testbench/sys/cpu/id_ex_reg.register_file_data1
add wave -position end -color "Cyan" sim:/testbench/sys/cpu/id_ex_reg.register_file_data2
add wave -position end -color "Cyan" sim:/testbench/sys/cpu/id_ex_reg.sign_extended_immediate
add wave -position end -color "Cyan" sim:/testbench/sys/cpu/id_ex_reg.alu_control
add wave -position end -color "Cyan" sim:/testbench/sys/cpu/id_ex_reg.register_file_rs1
add wave -position end -color "Cyan" sim:/testbench/sys/cpu/id_ex_reg.register_file_rs2
add wave -position end -color "Cyan" sim:/testbench/sys/cpu/id_ex_reg.register_file_rd

add wave -position end -color "Orchid" sim:/testbench/sys/cpu/ex_mem_reg.control_mem_read
add wave -position end -color "Orchid" sim:/testbench/sys/cpu/ex_mem_reg.control_mem_write
add wave -position end -color "Orchid" sim:/testbench/sys/cpu/ex_mem_reg.control_reg_write
add wave -position end -color "Orchid" sim:/testbench/sys/cpu/ex_mem_reg.control_mem_to_reg
add wave -position end -color "Orchid" sim:/testbench/sys/cpu/ex_mem_reg.alu_result
add wave -position end -color "Orchid" sim:/testbench/sys/cpu/ex_mem_reg.register_file_data2
add wave -position end -color "Orchid" sim:/testbench/sys/cpu/ex_mem_reg.register_file_rd

add wave -position end -color "Blue" sim:/testbench/sys/cpu/mem_wb_reg.control_reg_write
add wave -position end -color "Blue" sim:/testbench/sys/cpu/mem_wb_reg.control_mem_to_reg
add wave -position end -color "Blue" sim:/testbench/sys/cpu/mem_wb_reg.memory_data
add wave -position end -color "Blue" sim:/testbench/sys/cpu/mem_wb_reg.alu_result
add wave -position end -color "Blue" sim:/testbench/sys/cpu/mem_wb_reg.register_file_rd

add wave -position end  sim:/testbench/sys/cpu/pc_src
add wave -position end -radix "Unsigned"  sim:/testbench/sys/cpu/pc_reg



add list \
sim:/testbench/sys/cpu/reg_file/registers 

run 5000ns

write list -window .main_pane.list.interior.cs.body {C:\Users\Penelope\Desktop\LU\2nd sem\ICP1 RISC-V\Modelsim\RISC-V OUTPUT}

run 5000ns

<<<<<<< HEAD
write list -window .main_pane.list.interior.cs.body {C:\Users\Penelope\Desktop\LU\2nd sem\ICP1 RISC-V\Modelsim\RISC-V OUTPUT}
=======
>>>>>>> refs/remotes/origin/main
