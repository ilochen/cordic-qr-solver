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
    output reg signed [DATA_WIDTH-1:0] OutData1,
    output reg signed [DATA_WIDTH-1:0] OutData2,
    output reg signed [DATA_WIDTH-1:0] OutData3,
    output reg signed [DATA_WIDTH-1:0] OutData4,
    output reg OutValid
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

    // assign the output data
    OutData1 = partial_product_x[2];
    OutData2 = partial_product_x[4];
    OutData3 = partial_product_x[5];
    OutData4 = delay4_r;

    // if any of the last cordic stages is valid, the output is valid
    OutValid = outvalid[5] | outvalid[4] | outvalid[2]; // valid output only if the last cordic stage is valid
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
    .STAGES(18)
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
    .STAGES(18)
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
    .STAGES(18)
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
    .STAGES(18)
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
    .STAGES(18)
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
    .STAGES(18)
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


endmodule


module cordic #(
    parameter INPUT_LENGTH = 22,
    parameter WORD_LENGTH = 22,
    parameter STAGES = 18
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
    end else begin
        mode_w = mode_r; // maintain previous mode
    end

    X_r[0] = X_w[0];
    Y_r[0] = Y_w[0];
    for ( i = 0; i < STAGES-1; i = i + 1) begin
        // assign the output of the last stage to the input of the next stage
        X_w[i+1] = X_out[i];
        Y_w[i+1] = Y_out[i];
        X_r[i+1] = X_w[i+1];
        Y_r[i+1] = Y_w[i+1];
	dir_w[i] = dir[i];
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
    end else begin
        X_r[STAGES] <= X_w[STAGES];
        // Y_r[STAGES] <= Y_w[STAGES];
        for (i = 0; i < STAGES; i = i + 1) begin
            dir_r[i] <= dir_w[i];
        end
        mode_r <= mode_w; // update mode
	flipped_r <= flipped_w;
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
