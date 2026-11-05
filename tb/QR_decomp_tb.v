`timescale 1ns / 1ps
`define CYCLE 7.5
`define HCYCLE 3.75

`ifdef SYN
    `include "tsmc13.v"
    `define SDF
    `define SDFFILE "./QR_decomp_syn.sdf"
`endif




module qr_decomp_tb;

    //create registers
    parameter INPUT_LENGTH = 25;
    parameter OUTPUT_LENGTH = 25;
    parameter TESTCASES = 100;
    parameter LENGTH = 20 * TESTCASES;

    reg clk;
    reg rst;

    //memory
    reg [INPUT_LENGTH-1:0] mem_A [0:LENGTH-1];

    //inputs
    reg [INPUT_LENGTH-1:0] A1;
    reg [INPUT_LENGTH-1:0] A2;
    reg [INPUT_LENGTH-1:0] A3;
    reg [INPUT_LENGTH-1:0] A4;
    reg ValidIn;

    //outputs
    wire signed [OUTPUT_LENGTH-1:0] X1;
    wire signed [OUTPUT_LENGTH-1:0] X2;
    wire signed [OUTPUT_LENGTH-1:0] X3;
    wire signed [OUTPUT_LENGTH-1:0] X4;
    wire ValidOut;


    integer i;
    integer j;
    real x1, x2, x3, x4;

    integer f1;
    real error = 0;

    //initialize dut
    qr_decomp #(
        .DATA_WIDTH(25)
    ) qr_decomp_inst (
        .clk(clk),
        .rst(rst),
        .InData1(A1),
        .InData2(A2),
        .InData3(A3),
        .InData4(A4),
        .InValid(ValidIn),
        .OutData1(X1),
        .OutData2(X2),
        .OutData3(X3),
        .OutData4(X4),
	    .OutValid(ValidOut)
    );

    `ifdef FSDB
    // waveform dump
    initial begin
       $fsdbDumpfile("qr_decomp.fsdb");
       $fsdbDumpvars(0, qr_decomp_tb, "+mda");
    end

    `endif

    initial begin
        `ifdef SDF
            $sdf_annotate(`SDFFILE, qr_decomp_inst);
        `endif
    end

    // generate reset
     initial begin
        rst = 0;
        #(`CYCLE*0.1);
        rst = 1;
        #(`CYCLE*2);
        rst = 0;
     end

    // Clock generation (starts after reset settles)
    initial begin
         #(`CYCLE*2);
        clk = 0;  // Let reset settle before toggling clock
        forever #(`HCYCLE) clk = ~clk;
    end

    initial begin
        ValidIn = 0;
        //load file
        A1 = 0;
        A2 = 0;
        A3 = 0;
        A4 = 0;
        $readmemb("./testcases.txt", mem_A);

        f1 = $fopen("./x_sol.txt", "w");
        //wait for reset
         #(`CYCLE*4);

        //start test
        A1 = mem_A[0];

        #(`CYCLE);
        A1 = mem_A[1];
        A2 = mem_A[4];

        #(`CYCLE);
        A1 = mem_A[2];
        A2 = mem_A[5];
        A3 = mem_A[8];
        A4 = 0;


        for(i = 0; i < TESTCASES - 1; i = i + 1) begin


            #(`CYCLE);
            A1 = mem_A[20*i + 3];
            A2 = mem_A[20*i + 6];
            A3 = mem_A[20*i + 9];
            A4 = mem_A[20*i + 12];

            #(`CYCLE);
            A1 = mem_A[20*i + 16];
            A2 = mem_A[20*i + 7];
            A3 = mem_A[20*i + 10];
            A4 = mem_A[20*i + 13];

            #(`CYCLE);
            A1 = mem_A[20*(i+1) + 0];
            A2 = mem_A[20*i + 17];
            A3 = mem_A[20*i + 11];
            A4 = mem_A[20*i + 14];

            #(`CYCLE);
            A1 = mem_A[20*(i+1) + 1];
            A2 = mem_A[20*(i+1) + 4];
            A3 = mem_A[20*i + 18];
            A4 = mem_A[20*i + 15];

            #(`CYCLE);
            A1 = mem_A[20*(i+1) + 2];
            A2 = mem_A[20*(i+1) + 5];
            A3 = mem_A[20*(i+1) + 8];
            A4 = mem_A[20*i + 19];

        end

        #(`CYCLE);
        A1 = mem_A[20 * (TESTCASES-1) + 3];
        A2 = mem_A[20 * (TESTCASES-1) + 6];
        A3 = mem_A[20 * (TESTCASES-1) + 9];
        A4 = mem_A[20 * (TESTCASES-1) + 12];

        #(`CYCLE);
        A1 = mem_A[20 * (TESTCASES-1) + 16];
        A2 = mem_A[20 * (TESTCASES-1) + 7];
        A3 = mem_A[20 * (TESTCASES-1) + 10];
        A4 = mem_A[20 * (TESTCASES-1) + 13];

        #(`CYCLE);
        A1 = 0;
        A2 = mem_A[20 * (TESTCASES-1) + 17];
        A3 = mem_A[20 * (TESTCASES-1) + 11];
        A4 = mem_A[20 * (TESTCASES-1) + 14];

        #(`CYCLE);
        A1 = 0;
        A2 = 0;
        A3 = mem_A[20 * (TESTCASES-1) + 18];
        A4 = mem_A[20 * (TESTCASES-1) + 15];

        #(`CYCLE);
        A1 = 0;
        A2 = 0;
        A3 = 0;
        A4 = mem_A[20 * (TESTCASES-1) + 19];

        #(`CYCLE*10);
	    $finish;
    end
    integer n = 0;
    real normalizer = 2**19;
    always@(negedge clk) begin
        if(ValidOut) begin
            n = n + 1;
            x1 = X1;
            x2 = X2;
            x3 = X3;
            x4 = X4;
            $display("Sol %d : x1: %f, x2: %f, x3: %f, x4: %f",n, x1/normalizer, x2/normalizer, x3/normalizer, x4/normalizer);
        end
    end
endmodule
