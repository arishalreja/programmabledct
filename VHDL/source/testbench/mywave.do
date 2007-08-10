onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/clk_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/clk_gen_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/gate_clk_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/rst_s
add wave -noupdate -format Literal -radix hexadecimal /tb_mdct/dati_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/idv_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/stbi_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/cyci_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/odv_s
add wave -noupdate -format Literal -radix hexadecimal /tb_mdct/dato_s
add wave -noupdate -format Literal -radix hexadecimal /tb_mdct/dcto_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/odv1_s
add wave -noupdate -format Literal -radix hexadecimal /tb_mdct/dcto1_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/testend_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/acko_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/wei_s
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/wbo/yot1/clk
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/wbo/yot1/rst
add wave -noupdate -format Literal -radix hexadecimal /tb_mdct/wbo/yot1/dcti
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/wbo/yot1/idv
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/wbo/yot1/odv
add wave -noupdate -format Literal -radix hexadecimal /tb_mdct/wbo/yot1/dcto
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/wbo/yot1/odv1
add wave -noupdate -format Literal -radix hexadecimal /tb_mdct/wbo/yot1/dcto1
add wave -noupdate -format Literal -radix hexadecimal /tb_mdct/wbo/yot2/data_in
add wave -noupdate -format Literal -radix hexadecimal /tb_mdct/wbo/yot2/data_out
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/wbo/yot2/wr
add wave -noupdate -format Logic -radix hexadecimal /tb_mdct/wbo/yot2/re
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2089047 ps} 0}
configure wave -namecolwidth 187
configure wave -valuecolwidth 98
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
WaveRestoreZoom {1896733 ps} {2338605 ps}
