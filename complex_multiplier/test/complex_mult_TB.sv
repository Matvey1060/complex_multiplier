module complex_mult_TB;

logic clk;
logic srst;
logic [17:0] data_a_i_i;
logic [17:0] data_a_q_i;
logic [17:0] data_b_i_i;
logic [17:0] data_b_q_i;
logic [17:0] data_i_o;
logic [17:0] data_q_o;

complex_mult_rounded uut (
    .clk_i(clk),
    .srst_i(srst),
    .data_a_i_i(data_a_i_i),
    .data_a_q_i(data_a_q_i),
    .data_b_i_i(data_b_i_i),
    .data_b_q_i(data_b_q_i),
    .data_i_o(data_i_o),
    .data_q_o(data_q_o)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    srst = 1;
    data_a_i_i = 0;
    data_a_q_i = 0;
    data_b_i_i = 0;
    data_b_q_i = 0;
    data_b_q_i = 0;
    data_q_o = 0;
    data_i_o = 0;
    #20;
    srst = 0;

    // Тест 1: (1 + j0) * (1.5 + j0) = 1.5 → 2
    data_a_i_i = 18'sh00001;  // 1.0 (18.0)
    data_b_i_i = 18'b01_1000000000000000;  // 1.5 (2.16)
    repeat(5) @(posedge clk);  // Ожидание 5 тактов (4 этапа + 1)
    #1;
    if (data_i_o !== 18'sh00002 || data_q_o !== 18'sh00000)
        $error("Test 1 Failed: i=%h, q=%h", data_i_o, data_q_o);

    // Тест 2: (-1 + j0) * (1.5 + j0) = -1.5 → -2
    data_a_i_i = 18'sh1FFFF;  // -1 (18.0)
    repeat(5) @(posedge clk);
    #1;
    if (data_i_o !== 18'sh1FFFE || data_q_o !== 18'sh00000)
        $error("Test 2 Failed: i=%h, q=%h", data_i_o, data_q_o);


end

endmodule