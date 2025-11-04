module DELAYG #(
    parameter DEL_MODE = "",
    parameter DEL_VALUE = 1'b0
)(
    input A,
    output Z
);

`ifdef USE_ASAP7_CELLS
    BUFx2_ASAP7_75t_R  clk_buf (.A(A), .Y(Z));
    // BUFx3_ASAP7_75t_R  clk_buf (.A(A), .Y(Z));
    // BUFx4_ASAP7_75t_R  clk_buf (.A(A), .Y(Z));
`elsif USE_NANGATE45_CELLS
    CLKBUF_X1  clk_buf0 (.A(clk_final), .Z(O));
    // CLKBUF_X2  clk_buf0 (.A(clk_final), .Z(O));
    // CLKBUF_X3  clk_buf0 (.A(clk_final), .Z(O));
`elsif USE_SKY130HD_CELLS
    sky130_fd_sc_hd__clkbuf_1  clk_buf (.A(clk_final), .X(O));
    // sky130_fd_sc_hd__clkbuf_2  clk_buf (.A(clk_final), .X(O));
    // sky130_fd_sc_hd__clkbuf_4  clk_buf (.A(clk_final), .X(O));
    // sky130_fd_sc_hd__clkbuf_8  clk_buf (.A(clk_final), .X(O));
    // sky130_fd_sc_hd__clkbuf_16 clk_buf (.A(clk_final), .X(O));
`endif

endmodule
