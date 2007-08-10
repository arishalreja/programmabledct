onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Literal -radix hexadecimal /testbench/memory/mem_core/data
add wave -noupdate -format Literal -radix hexadecimal /testbench/wbo/yot2/data
add wave -noupdate -format Literal -radix hexadecimal /testbench/mydata
add wave -noupdate -format Logic -radix hexadecimal /testbench/clk_i
add wave -noupdate -format Logic -radix hexadecimal /testbench/reset
add wave -noupdate -format Logic /testbench/halt
add wave -noupdate -format Logic -radix hexadecimal /testbench/int
add wave -noupdate -format Logic /testbench/flag
add wave -noupdate -format Logic -radix hexadecimal /testbench/stbo_proc
add wave -noupdate -format Logic -radix hexadecimal /testbench/cyco_proc
add wave -noupdate -format Literal -radix hexadecimal /testbench/adro_proc
add wave -noupdate -format Literal -radix hexadecimal /testbench/dati_proc
add wave -noupdate -format Literal -radix hexadecimal /testbench/dato_proc
add wave -noupdate -format Logic -radix hexadecimal /testbench/weo_proc
add wave -noupdate -format Logic -radix hexadecimal /testbench/acki_proc
add wave -noupdate -format Logic /testbench/stbi_mem
add wave -noupdate -format Literal -radix hexadecimal /testbench/adri_mem
add wave -noupdate -format Logic /testbench/cyci_mem
add wave -noupdate -format Literal -radix hexadecimal /testbench/dati_mem
add wave -noupdate -format Literal -radix hexadecimal /testbench/dato_mem
add wave -noupdate -format Logic /testbench/wei_mem
add wave -noupdate -format Logic -radix hexadecimal /testbench/chip_sel
add wave -noupdate -format Logic /testbench/stbi_dct
add wave -noupdate -format Logic /testbench/cyci_dct
add wave -noupdate -format Literal -radix decimal /testbench/dati_dct
add wave -noupdate -format Literal -radix decimal /testbench/dato_dct
add wave -noupdate -format Logic -radix hexadecimal /testbench/wei_dct
add wave -noupdate -format Logic -radix hexadecimal /testbench/acko_dct
add wave -noupdate -format Literal -radix hexadecimal /testbench/q_pc
add wave -noupdate -format Literal -radix hexadecimal /testbench/q_opc
add wave -noupdate -format Literal -radix hexadecimal /testbench/q_imm
add wave -noupdate -format Literal -radix hexadecimal /testbench/q_cyc
add wave -noupdate -format Logic -radix hexadecimal /testbench/q_we_rr
add wave -noupdate -format Logic -radix hexadecimal /testbench/q_we_ll
add wave -noupdate -format Literal -radix hexadecimal /testbench/q_we_sp
add wave -noupdate -format Literal -radix hexadecimal /testbench/q_cat
add wave -noupdate -format Literal -radix hexadecimal /testbench/q_rr
add wave -noupdate -format Literal -radix hexadecimal /testbench/q_ll
add wave -noupdate -format Literal -radix hexadecimal /testbench/q_sp
add wave -noupdate -format Literal /testbench/clk_counter
add wave -noupdate -format Logic /testbench/gate_clk_s
add wave -noupdate -format Logic /testbench/rst_s
add wave -noupdate -format Logic /testbench/idv_s
add wave -noupdate -format Logic /testbench/odv_s
add wave -noupdate -format Literal /testbench/dcto_s
add wave -noupdate -format Logic /testbench/odv1_s
add wave -noupdate -format Literal /testbench/dcto1_s
add wave -noupdate -format Logic /testbench/testend_s
add wave -noupdate -format Literal /testbench/input_data
add wave -noupdate -format Literal /testbench/dati
add wave -noupdate -format Literal /testbench/tga_o
add wave -noupdate -format Logic /testbench/weo_proc
add wave -noupdate -format Logic /testbench/acko_dct
add wave -noupdate -format Literal /testbench/dati_dct
add wave -noupdate -format Literal /testbench/dato_dct
add wave -noupdate -format Logic /testbench/wei_dct
add wave -noupdate -format Logic /testbench/acko_mem
add wave -noupdate -format Logic /testbench/chip_sel
add wave -noupdate -format Literal /testbench/dato_inpimage
add wave -noupdate -format Literal /testbench/adro_inpimage
add wave -noupdate -format Logic /testbench/stbo_inpimage
add wave -noupdate -format Logic /testbench/weo_inpimage
add wave -noupdate -format Literal /testbench/lastmem
add wave -noupdate -format Literal /testbench/mydato
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {877267220 ps} 0}
configure wave -namecolwidth 226
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {0 ps} {399294273 ps}
