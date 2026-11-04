module qr_decomp #(
    parameter DATA_WIDTH = 22
) (
    input clk,
    input rst,
    input signed [DATA_WIDTH-1:0] InData1,
    input signed [DATA_WIDTH-1:0] InData2,
    input signed [DATA_WIDTH-1:0] InData3,
    input signed [DATA_WIDTH-1:0] InData4,
    input InValid,
    output signed [DATA_WIDTH-1:0] OutData1,
    output signed [DATA_WIDTH-1:0] OutData2,
    output signed [DATA_WIDTH-1:0] OutData3,
    output signed [DATA_WIDTH-1:0] OutData4,
    output OutValid
);

    //---------- register declaration ----------
    // delay units
    reg signed [DATA_WIDTH-1:0] delay1_w, delay1_r, delay2_w, delay2_r, delay3_w, delay3_r, delay4_w, delay4_r;
    // inputs
    reg signed [DATA_WIDTH-1:0] in1_w, in1_r, in2_w, in2_r, in3_w, in3_r, in4_w, in4_r;


    //---------- wire declaration ----------
    wire signed [DATA_WIDTH-1:0] partial_product_x [0:5]; // partial products for the systolic array
    wire signed [DATA_WIDTH-1:0] partial_product_y [0:5]; // partial products for the systolic array
    wire outvalid [0:5]; // valid output for each cordic stage

    // --------- combinational logic ---------
    always @(*) begin
        in1_w = InData1;
        in2_w = InData2;
        in3_w = InData3;
        in4_w = InData4;

        delay1_w = in1_r;
        delay2_w = partial_product_y[0];
        delay3_w = partial_product_y[3];
        delay4_w = partial_product_y[5];

        // // assign the output data
        // OutData1 = partial_product_x[2];
        // OutData2 = partial_product_x[4];
        // OutData3 = partial_product_x[5];
        // OutData4 = delay4_r;

        // // if any of the last cordic stages is valid, the output is valid
        // OutValid = outvalid[5] | outvalid[4] | outvalid[2]; // valid output only if the last cordic stage is valid
    end

    //---------- sequential logic ----------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset all registers
            delay1_r <= 0;
            delay2_r <= 0;
            delay3_r <= 0;
            delay4_r <= 0;
            in1_r <= 0; // reset input registers
            in2_r <= 0; 
            in3_r <= 0;
            in4_r <= 0;

        end else begin
            // update the delay registers
            delay1_r <= delay1_w;
            delay2_r <= delay2_w;
            delay3_r <= delay3_w;
            delay4_r <= delay4_w;
            // update the input registers
            in1_r <= in1_w;
            in2_r <= in2_w;
            in3_r <= in3_w;
            in4_r <= in4_w;
        end
    end

    //---------- cordic systolic array ----------
    cordic #(
        .INPUT_LENGTH(DATA_WIDTH),
        .WORD_LENGTH(DATA_WIDTH),
        .STAGES(18),
        .RESET_CNT(4)
    ) cordic_inst_1_1 (
        .clk(clk),
        .rst(rst),
        .Valid_In(delay1_r != 0), // valid input only if the input is non-zero
        .InX(delay1_r),
        .InY(in2_r),
        .Valid_Out(outvalid[0]),
        .OutX(partial_product_x[0]),
        .OutY(partial_product_y[0])
    );

    cordic #(
        .INPUT_LENGTH(DATA_WIDTH),
        .WORD_LENGTH(DATA_WIDTH),
        .STAGES(18),
        .RESET_CNT(4)
    ) cordic_inst_1_2 (
        .clk(clk),
        .rst(rst),
        .Valid_In(outvalid[0]), // valid input only if the first cordic output valid
        .InX(partial_product_x[0]),
        .InY(in3_r),
        .Valid_Out(outvalid[1]),
        .OutX(partial_product_x[1]),
        .OutY(partial_product_y[1])
    );

    cordic #(
        .INPUT_LENGTH(DATA_WIDTH),
        .WORD_LENGTH(DATA_WIDTH),
        .STAGES(18),
        .RESET_CNT(4)
    ) cordic_inst_1_3 (
        .clk(clk),
        .rst(rst),
        .Valid_In(outvalid[1]), // valid input only if the second cordic output is non-zero
        .InX(partial_product_x[1]),
        .InY(in4_r),
        .Valid_Out(outvalid[2]),
        .OutX(partial_product_x[2]),
        .OutY(partial_product_y[2])
    );

    cordic #(
        .INPUT_LENGTH(DATA_WIDTH),
        .WORD_LENGTH(DATA_WIDTH),
        .STAGES(18),
        .RESET_CNT(4)
    ) cordic_inst_2_2 (
        .clk(clk),
        .rst(rst),
        .Valid_In(delay2_r != 0), // valid input only if the second delay input is non-zero
        .InX(delay2_r),
        .InY(partial_product_y[1]),
        .Valid_Out(outvalid[3]),
        .OutX(partial_product_x[3]),
        .OutY(partial_product_y[3])
    );

    cordic #(
        .INPUT_LENGTH(DATA_WIDTH),
        .WORD_LENGTH(DATA_WIDTH),
        .STAGES(18),
        .RESET_CNT(4)
    ) cordic_inst_2_3 (
        .clk(clk),
        .rst(rst),
        .Valid_In(outvalid[3]), // valid input only if the forth cordic output is non-zero
        .InX(partial_product_x[3]),
        .InY(partial_product_y[2]),
        .Valid_Out(outvalid[4]),
        .OutX(partial_product_x[4]),
        .OutY(partial_product_y[4])
    );

    cordic #(
        .INPUT_LENGTH(DATA_WIDTH),
        .WORD_LENGTH(DATA_WIDTH),
        .STAGES(18),
        .RESET_CNT(3)
    ) cordic_inst_3_3 (
        .clk(clk),
        .rst(rst),
        .Valid_In(delay3_r != 0), // valid input only if the third cordic output is non-zero
        .InX(delay3_r),
        .InY(partial_product_y[4]),
        .Valid_Out(outvalid[5]),
        .OutX(partial_product_x[5]),
        .OutY(partial_product_y[5])
    );

    //---------- back substitution ----------
    BackSub #(
        .WORD_LENGTH(DATA_WIDTH),
        .FRACTION_LENGTH(19)
    ) back_sub_inst (
        .clk(clk),
        .rst(rst),
        .InData1(partial_product_x[2]),
        .InData2(partial_product_x[4]),
        .InData3(partial_product_x[5]),
        .InData4(delay4_r),
        .ValidIn(outvalid[5] | outvalid[4] | outvalid[2]),
        .OutX1(OutData1),
        .OutX2(OutData2),
        .OutX3(OutData3),
        .OutX4(OutData4),
        .ValidOut(OutValid)
    );
endmodule


module cordic #(
    parameter INPUT_LENGTH = 22,
    parameter WORD_LENGTH = 22,
    parameter STAGES = 18,
    parameter RESET_CNT = 4
) (
    input clk,
    input rst,
    input Valid_In,
    input signed [INPUT_LENGTH-1:0] InX,
    input signed [INPUT_LENGTH-1:0] InY,
    output Valid_Out,
    output signed [WORD_LENGTH-1:0] OutX,
    output signed [WORD_LENGTH-1:0] OutY
);

    //---------- register declaration ----------

    //pipeline registers at each stage => total of STAGES+1 registers
    reg signed [WORD_LENGTH-1:0] X_w [0:STAGES], X_r [0:STAGES], Y_w [0:STAGES], Y_r [0:STAGES];
    wire signed [WORD_LENGTH-1:0] X_out[0:STAGES-1], Y_out[0:STAGES-1];
    reg [STAGES-1:0] dir_w, dir_r; // direction of rotation
    wire [STAGES-1:0] dir;
    reg mode_w, mode_r; // mode of operation (rotation or vectoring)

    // counter for valid out flag
    reg flipped_w, flipped_r;
    // valid out flag
    reg valid_out_w, valid_out_r;

    reg [2:0] cnt_w, cnt_r; // counter for reset


    //---------- output assignments ----------
    wire signed [2*WORD_LENGTH-1:0] temp_outx;
    assign temp_outx = (X_r[STAGES] * $signed(25'b0000001001101101110100111))>>>19; //0.6072529 in fixed point representation
    assign OutX = temp_outx[WORD_LENGTH-1:0];
    wire signed [2*WORD_LENGTH-1:0] temp_outy;
    assign temp_outy = (Y_r[STAGES] * $signed(25'b0000001001101101110100111))>>>19;
    assign OutY = (mode_r) ? temp_outy[WORD_LENGTH-1:0] : 0;
    assign Valid_Out = mode_r;


    // initial stage quadrant conversion
    // map second and third quadrants to first and fourth quadrants
    always @(*) begin
        if(mode_r) begin
            if(flipped_r) begin
                X_w[0] = -InX;
                Y_w[0] = -InY;
            end else begin
                X_w[0] = InX;
                Y_w[0] = InY;
            end
            flipped_w = flipped_r;
        end else if(Valid_In) begin
            case({InY[WORD_LENGTH-1], InX[WORD_LENGTH-1]})
                2'b01: begin // second quadrant -> fourth quadrant
                    X_w[0] = -InX;
                    Y_w[0] = -InY;
                    flipped_w = 1;
            end
                2'b11: begin // third quadrant -> first quadrant
                    X_w[0] = -InX;
                    Y_w[0] = -InY; 
            flipped_w = 1;
                end
                default: begin // first and fourth quadrants do not need conversion
                    X_w[0] = InX;
                    Y_w[0] = InY;
            flipped_w = 0;
                end
            endcase
        end else begin
            flipped_w = 0;
            // if not valid, clear the previous values
            X_w[0] = 0;
            Y_w[0] = 0;
        end
        if (cnt_r >= RESET_CNT) begin
            flipped_w = 0; // reset flipped flag after STAGES iterations
        end
        
    end


    // N stage rotation
    genvar g;
    generate
        for (g = 0; g < STAGES; g = g + 1) begin : cordic_stage
            // shift add module
            shift_add #(
                .INPUT_LENGTH(WORD_LENGTH),
                .OUTPUT_LENGTH(WORD_LENGTH),
                .ITERATIONS(g)
            ) shift_add_inst (
                .InX(X_r[g]),
                .InY(Y_r[g]),
                .mode(mode_r),
                .dir_saved(dir_r[g]),
                .OutX(X_out[g]),
                .OutY(Y_out[g]),
                .dir(dir[g])
            );
        end
    endgenerate

    // theta accumulation
    integer i;


    // combinational 
    always @(*) begin

        // counter logic
        if(Valid_In) begin
            mode_w = 1;
            if (cnt_r < RESET_CNT) begin
                // reset the counter after STAGES iterations
                cnt_w = cnt_r + 1;
            end else begin
                cnt_w = 0; // reset the counter
                mode_w = 0;
            end
        end else begin
            if (cnt_r < RESET_CNT) begin
                // reset the counter after STAGES iterations
                mode_w = mode_r; // maintain previous mode
            end else begin
                mode_w = 0;
            end
            cnt_w = 0;
        end

        X_r[0] = X_w[0];
        Y_r[0] = Y_w[0];
        for ( i = 0; i < STAGES-1; i = i + 1) begin
            // assign the output of the last stage to the input of the next stage
            X_w[i+1] = X_out[i];
            Y_w[i+1] = Y_out[i];
            X_r[i+1] = X_w[i+1];
            Y_r[i+1] = Y_w[i+1];
            if (cnt_r < 4) begin
                dir_w[i] = dir[i];
            end else begin
                dir_w[i] = 0;
            end
        end
        dir_w[STAGES-1] = dir[STAGES-1];
        X_w[STAGES] = X_out[STAGES-1];
        Y_w[STAGES] = Y_out[STAGES-1];

        Y_r[STAGES] = Y_w[STAGES];

    end


    // sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            X_r[STAGES] <= 0;
            // Y_r[STAGES] <= 0;
            for (i = 0; i < STAGES; i = i + 1) begin
                dir_r[i] <= 0;
            end
            mode_r <= 0; // reset mode
            flipped_r <= 0;
            cnt_r <= 0;
        end else begin
            X_r[STAGES] <= X_w[STAGES];
            // Y_r[STAGES] <= Y_w[STAGES];
            for (i = 0; i < STAGES; i = i + 1) begin
                dir_r[i] <= dir_w[i];
            end
            mode_r <= mode_w; // update mode
            flipped_r <= flipped_w;
            cnt_r <= cnt_w; // update counter
        end
    end
endmodule



// shift add module
module shift_add #(
    parameter INPUT_LENGTH = 16,
    parameter OUTPUT_LENGTH = 16,
    parameter ITERATIONS = 1
) (
    input signed [INPUT_LENGTH-1:0] InX,
    input signed [INPUT_LENGTH-1:0] InY,
    input mode,
    input dir_saved,
    output signed [OUTPUT_LENGTH-1:0] OutX,
    output signed [OUTPUT_LENGTH-1:0] OutY,
    output dir
);
    // Shift and add logic here

    // at the i-th iteration, shift the input by i bits
    wire signed [OUTPUT_LENGTH-1:0] shiftedX = InX >>> ITERATIONS;
    wire signed [OUTPUT_LENGTH-1:0] shiftedY = InY >>> ITERATIONS;
    // if vectoring mode:
    // add/subtract the shifted values based on Y
    // if Y is positive clockwise, else counterclockwise
    // X should always increase, Y should always decrease

    // if rotation mode:
    // add/subtract the shifted values based on the saved direction

    wire control; // control signal for addition or subtraction
    // if mode is 0 vectoring
    // if mode is 1 rotation
    assign control = (mode) ? dir_saved : InY[INPUT_LENGTH-1];

    assign OutX = (control) ? InX - shiftedY : InX + shiftedY;
    assign OutY = (control) ? InY + shiftedX : InY - shiftedX;

    // direction of rotation
    assign dir = control; // 1 for clockwise, 0 for counterclockwise
endmodule

module BackSub #(
    parameter WORD_LENGTH = 22,
    parameter FRACTION_LENGTH = 19
) (
    input clk,
    input rst,
    input signed [WORD_LENGTH-1:0] InData1,
    input signed [WORD_LENGTH-1:0] InData2,
    input signed [WORD_LENGTH-1:0] InData3,
    input signed [WORD_LENGTH-1:0] InData4,
    input ValidIn,

    output signed [WORD_LENGTH-1:0] OutX1,
    output signed [WORD_LENGTH-1:0] OutX2,
    output signed [WORD_LENGTH-1:0] OutX3,
    output signed [WORD_LENGTH-1:0] OutX4,
    output ValidOut
);
    reg AorB_w, AorB_r; // 1 for store at A calculate B, 0 for store at B calculate A

    reg signed [WORD_LENGTH-1:0] OutX1A_w, OutX1A_r;
    reg signed [WORD_LENGTH-1:0] OutX2A_w, OutX2A_r;
    reg signed [WORD_LENGTH-1:0] OutX3A_w, OutX3A_r;
    reg signed [WORD_LENGTH-1:0] OutX4A_w, OutX4A_r;
    reg signed [WORD_LENGTH-1:0] OutX1B_w, OutX1B_r;
    reg signed [WORD_LENGTH-1:0] OutX2B_w, OutX2B_r;
    reg signed [WORD_LENGTH-1:0] OutX3B_w, OutX3B_r;
    reg signed [WORD_LENGTH-1:0] OutX4B_w, OutX4B_r;
    reg ValidOut_w, ValidOut_r;

    reg signed [WORD_LENGTH-1:0] R11A_r, R11A_w;
    reg signed [WORD_LENGTH-1:0] R12A_r, R12A_w;
    reg signed [WORD_LENGTH-1:0] R13A_r, R13A_w;
    reg signed [WORD_LENGTH-1:0] R14A_r, R14A_w;
    reg signed [WORD_LENGTH-1:0] R22A_r, R22A_w;
    reg signed [WORD_LENGTH-1:0] R23A_r, R23A_w;
    reg signed [WORD_LENGTH-1:0] R24A_r, R24A_w;
    reg signed [WORD_LENGTH-1:0] R33A_r, R33A_w;
    reg signed [WORD_LENGTH-1:0] R34A_r, R34A_w;
    reg signed [WORD_LENGTH-1:0] R44A_r, R44A_w;
    reg signed [WORD_LENGTH-1:0] R11B_r, R11B_w;
    reg signed [WORD_LENGTH-1:0] R12B_r, R12B_w;
    reg signed [WORD_LENGTH-1:0] R13B_r, R13B_w;
    reg signed [WORD_LENGTH-1:0] R14B_r, R14B_w;
    reg signed [WORD_LENGTH-1:0] R22B_r, R22B_w;
    reg signed [WORD_LENGTH-1:0] R23B_r, R23B_w;
    reg signed [WORD_LENGTH-1:0] R24B_r, R24B_w;
    reg signed [WORD_LENGTH-1:0] R33B_r, R33B_w;
    reg signed [WORD_LENGTH-1:0] R34B_r, R34B_w;
    reg signed [WORD_LENGTH-1:0] R44B_r, R44B_w;

    reg signed [WORD_LENGTH-1:0] z1A_r, z1A_w;
    reg signed [WORD_LENGTH-1:0] z2A_r, z2A_w;
    reg signed [WORD_LENGTH-1:0] z3A_r, z3A_w;
    reg signed [WORD_LENGTH-1:0] z4A_r, z4A_w;
    reg signed [WORD_LENGTH-1:0] z1B_r, z1B_w;
    reg signed [WORD_LENGTH-1:0] z2B_r, z2B_w;
    reg signed [WORD_LENGTH-1:0] z3B_r, z3B_w;
    reg signed [WORD_LENGTH-1:0] z4B_r, z4B_w;

    reg signed [WORD_LENGTH-1:0] m1A;
    reg signed [WORD_LENGTH-1:0] m1B;
    reg signed [WORD_LENGTH-1:0] m2A;
    reg signed [WORD_LENGTH-1:0] m2B;
    reg signed [WORD_LENGTH-1:0] m3A;
    reg signed [WORD_LENGTH-1:0] m3B;

    reg signed [WORD_LENGTH-1:0] dA;
    reg signed [WORD_LENGTH-1:0] dB;

    wire signed [WORD_LENGTH-1:0] m1C;
    wire signed [WORD_LENGTH-1:0] m2C;
    wire signed [WORD_LENGTH-1:0] m3C;
    wire signed [WORD_LENGTH-1:0] dC;

    assign OutX1 = (AorB_r) ? OutX1B_r : OutX1A_r;
    assign OutX2 = (AorB_r) ? OutX2B_r : OutX2A_r;
    assign OutX3 = (AorB_r) ? OutX3B_r : OutX3A_r;
    assign OutX4 = (AorB_r) ? OutX4B_r : OutX4A_r;
    assign ValidOut = ValidOut_r;

    MUL #(
        .WORD_LENGTH(WORD_LENGTH),
        .FRACTION_LENGTH(FRACTION_LENGTH)
    ) mul_inst_1 (
        .A(m1A),
        .B(m1B),
        .C(m1C)
    );

    MUL #(
        .WORD_LENGTH(WORD_LENGTH),
        .FRACTION_LENGTH(FRACTION_LENGTH)
    ) mul_inst_2 (
        .A(m2A),
        .B(m2B),
        .C(m2C)
    );

    MUL #(
        .WORD_LENGTH(WORD_LENGTH),
        .FRACTION_LENGTH(FRACTION_LENGTH)
    ) mul_inst_3 (
        .A(m3A),
        .B(m3B),
        .C(m3C)
    );

    DIV #(
        .WORD_LENGTH(WORD_LENGTH),
        .FRACTION_LENGTH(FRACTION_LENGTH)
    ) div_inst (
        .A(dA),
        .B(dB),
        .C(dC)
    );

    reg [3:0] cnt_i_r, cnt_i_w;
    // reg [3:0] cnt_j_r, cnt_j_w;

    reg start_flag_r, start_flag_w; // flag to indicate the start of the computation

    always @(*) begin
        cnt_i_w = cnt_i_r;
        AorB_w = AorB_r;
        ValidOut_w = 0;

        R11A_w = R11A_r;
        R12A_w = R12A_r;
        R13A_w = R13A_r;
        R14A_w = R14A_r;
        R22A_w = R22A_r;
        R23A_w = R23A_r;
        R24A_w = R24A_r;
        R33A_w = R33A_r;
        R34A_w = R34A_r;
        R44A_w = R44A_r;

        z1A_w = z1A_r;
        z2A_w = z2A_r;
        z3A_w = z3A_r;
        z4A_w = z4A_r;

        R11B_w = R11B_r;
        R12B_w = R12B_r;
        R13B_w = R13B_r;
        R14B_w = R14B_r;
        R22B_w = R22B_r;
        R23B_w = R23B_r;
        R24B_w = R24B_r;
        R33B_w = R33B_r;
        R34B_w = R34B_r;
        R44B_w = R44B_r;

        z1B_w = z1B_r;
        z2B_w = z2B_r;
        z3B_w = z3B_r;
        z4B_w = z4B_r;

        m1A = 0;
        m2A = 0;
        m3A = 0;
        m1B = 0;
        m2B = 0;
        m3B = 0;
        dA = 0;
        dB = 0; 

        OutX1A_w = OutX1A_r;
        OutX2A_w = OutX2A_r;
        OutX3A_w = OutX3A_r;
        OutX4A_w = OutX4A_r;

        OutX1B_w = OutX1B_r;
        OutX2B_w = OutX2B_r;
        OutX3B_w = OutX3B_r;
        OutX4B_w = OutX4B_r;

        start_flag_w = start_flag_r; // reset start flag
        case (cnt_i_r)
            4'd0: begin
                if (ValidIn || start_flag_r) begin
                    cnt_i_w = cnt_i_r + 1;
                    if (AorB_r) begin 
                        // store at A
                        R11A_w = InData1;
                        // calculate B
                        dA = z4B_r;
                        dB = R44B_r;
                        OutX4B_w = dC;
                    end else begin
                        // store at B
                        R11B_w = InData1;
                        // calculate A
                        dA = z4A_r;
                        dB = R44A_r;
                        OutX4A_w = dC;
                    end
                    // R11_w = InData1;
                end
            end 
            4'd1: begin
                cnt_i_w = cnt_i_r + 1;
                if (AorB_r) begin
                    // store at A
                    R12A_w = InData1;
                    R22A_w = InData2;
                    // calculate B
                    m1A = OutX4B_r;
                    m1B = R34B_r;
                    dA = z3B_r - m1C;
                    dB = R33B_r;
                    OutX3B_w = dC;
                end else begin
                    // store at B
                    R12B_w = InData1;
                    R22B_w = InData2;
                    // calculate A
                    m1A = OutX4A_r;
                    m1B = R34A_r;
                    dA = z3A_r - m1C;
                    dB = R33A_r;
                    OutX3A_w = dC;
                end
                // R12_w = InData1;
		        // R22_w = InData2;
            end
            4'd2: begin // dC = x3
                cnt_i_w = cnt_i_r + 1;
                if (AorB_r) begin
                    // store at A
                    R13A_w = InData1;
                    R23A_w = InData2;
                    R33A_w = InData3;
                    // calculate B
                    m1A = OutX3B_r;
                    m1B = R23B_r;
                    m2A = OutX4B_r;
                    m2B = R24B_r;
                    dA = z2B_r - m1C - m2C;
                    dB = R22B_r;
                    OutX2B_w = dC;
                end else begin
                    // store at B
                    R13B_w = InData1;
                    R23B_w = InData2;
                    R33B_w = InData3;
                    // calculate A
                    m1A = OutX3A_r;
                    m1B = R23A_r;
                    m2A = OutX4A_r;
                    m2B = R24A_r;
                    dA = z2A_r - m1C - m2C;
                    dB = R22A_r;
                    OutX2A_w = dC;
                end
                // R13_w = InData1;
                // R23_w = InData2;
		        // R33_w = InData3;
            end
            4'd3: begin
                cnt_i_w = cnt_i_r + 1;
                start_flag_w = 1; // set start flag to indicate the start of the computation
                if(start_flag_r) begin
                    // reset the start flag after the first iteration
                    ValidOut_w = 1;
                end
                if (AorB_r) begin
                    // store at A
                    R14A_w = InData1;
                    R24A_w = InData2;
                    R34A_w = InData3;
                    R44A_w = InData4;
                    // calculate B
                    m1A = OutX2B_r;
                    m1B = R12B_r;
                    m2A = OutX3B_r;
                    m2B = R13B_r;
                    m3A = OutX4B_r;
                    m3B = R14B_r;
                    dA = z1B_r - m1C - m2C - m3C;
                    dB = R11B_r;
                    OutX1B_w = dC;
                end else begin
                    // store at B
                    R14B_w = InData1;
                    R24B_w = InData2;
                    R34B_w = InData3;
                    R44B_w = InData4;
                    // calculate A
                    m1A = OutX2A_r;
                    m1B = R12A_r;
                    m2A = OutX3A_r;
                    m2B = R13A_r;
                    m3A = OutX4A_r;
                    m3B = R14A_r;
                    dA = z1A_r - m1C - m2C - m3C;
                    dB = R11A_r;
                    OutX1A_w = dC;
                end
                // R14_w = InData1;
                // R24_w = InData2;
                // R34_w = InData3;
                // R44_w = InData4;
            end
            4'd4: begin
                cnt_i_w = 0;
                AorB_w = ~AorB_r; // toggle AorB for next iteration
                if (AorB_r) begin // store at A
                    z1A_w = InData1;
                    z2A_w = InData2;
                    z3A_w = InData3;
                    z4A_w = InData4;
                end else begin // store at B
                    z1B_w = InData1;
                    z2B_w = InData2;
                    z3B_w = InData3;
                    z4B_w = InData4;
                end
                // z1_w = InData1;
                // z2_w = InData2;
                // z3_w = InData3;
		        // z4_w = InData4;
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_i_r <= 0;
            ValidOut_r <= 0;
            OutX1A_r <= 0;
            OutX2A_r <= 0;
            OutX3A_r <= 0;
            OutX4A_r <= 0;
            OutX1B_r <= 0;
            OutX2B_r <= 0;
            OutX3B_r <= 0;
            OutX4B_r <= 0;
            AorB_r <= 0;
            R11A_r <= 0;
            R12A_r <= 0;
            R13A_r <= 0;
            R14A_r <= 0;
            R22A_r <= 0;
            R23A_r <= 0;
            R24A_r <= 0;
            R33A_r <= 0;
            R34A_r <= 0;
            R44A_r <= 0;
            R11B_r <= 0;
            R12B_r <= 0;
            R13B_r <= 0;
            R14B_r <= 0;
            R22B_r <= 0;
            R23B_r <= 0;
            R24B_r <= 0;
            R33B_r <= 0;
            R34B_r <= 0;
            R44B_r <= 0;
            z1A_r <= 0;
            z2A_r <= 0;
            z3A_r <= 0;
            z4A_r <= 0;
            z1B_r <= 0;
            z2B_r <= 0;
            z3B_r <= 0;
            z4B_r <= 0;
            start_flag_r <= 0; // reset start flag
        end else begin
            cnt_i_r <= cnt_i_w;
            ValidOut_r <= ValidOut_w;
            OutX1A_r <= OutX1A_w;
            OutX2A_r <= OutX2A_w;
            OutX3A_r <= OutX3A_w;
            OutX4A_r <= OutX4A_w;
            OutX1B_r <= OutX1B_w;
            OutX2B_r <= OutX2B_w;
            OutX3B_r <= OutX3B_w;
            OutX4B_r <= OutX4B_w;
            AorB_r <= AorB_w;
            R11A_r <= R11A_w;
            R12A_r <= R12A_w;
            R13A_r <= R13A_w;
            R14A_r <= R14A_w;
            R22A_r <= R22A_w;
            R23A_r <= R23A_w;
            R24A_r <= R24A_w;
            R33A_r <= R33A_w;
            R34A_r <= R34A_w;
            R44A_r <= R44A_w;
            R11B_r <= R11B_w;
            R12B_r <= R12B_w;
            R13B_r <= R13B_w;
            R14B_r <= R14B_w;
            R22B_r <= R22B_w;
            R23B_r <= R23B_w;
            R24B_r <= R24B_w;
            R33B_r <= R33B_w;
            R34B_r <= R34B_w;
            R44B_r <= R44B_w;
            z1A_r <= z1A_w;
            z2A_r <= z2A_w;
            z3A_r <= z3A_w;
            z4A_r <= z4A_w;
            z1B_r <= z1B_w;
            z2B_r <= z2B_w;
            z3B_r <= z3B_w;
            z4B_r <= z4B_w;
            start_flag_r <= start_flag_w; // update start flag
        end
    end
endmodule

module MUL #(
    parameter WORD_LENGTH = 22,
    parameter FRACTION_LENGTH = 19
) (
    input signed [WORD_LENGTH-1:0] A,
    input signed [WORD_LENGTH-1:0] B,
    output signed [WORD_LENGTH-1:0] C
);
    wire signed [2*WORD_LENGTH-1:0] P = A * B; // Multiply inputs
    assign C = P[FRACTION_LENGTH-1]                // 0.5LSB
           ? (P[(2*WORD_LENGTH)-4:FRACTION_LENGTH] + 1)   // round up
           :  P[(2*WORD_LENGTH)-4:FRACTION_LENGTH];       // truncate
endmodule

module DIV #(
    parameter WORD_LENGTH = 22,
    parameter FRACTION_LENGTH = 19
) (
    input signed [WORD_LENGTH-1:0] A,
    input signed [WORD_LENGTH-1:0] B,
    output signed [WORD_LENGTH-1:0] C
);
    wire signed [FRACTION_LENGTH + WORD_LENGTH-1:0] A_ext = {A, {(FRACTION_LENGTH){1'b0}}}; // Extend A

    assign C = (B != 0) ? A_ext / B : 0; // Avoid division by zero
endmodule
