vsim -gui work.testbench
restart -f -nolist -nowave -nobreak -nolog -novirtuals -noassertions -nofcovers -noatv

add wave -position end  sim:/testbench/clk
add wave -position end  sim:/testbench/reset_n
add wave -position end  sim:/testbench/input_data
add wave -position end  sim:/testbench/input_pin



add list \
sim:/testbench/sys/prog_mem/ram






run 5000ns

write list -window .main_pane.list.interior.cs.body {C:\Users\Penelope\Desktop\LU\2nd sem\ICP1 RISC-V\Modelsim\RISC-V OUTPUT}

run 5000ns

