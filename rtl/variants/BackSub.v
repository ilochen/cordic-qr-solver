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
    reg signed [WORD_LENGTH-1:0] OutX1_r, OutX1_w;
    reg signed [WORD_LENGTH-1:0] OutX2_w, OutX2_r;
    reg signed [WORD_LENGTH-1:0] OutX3_w, OutX3_r;
    reg signed [WORD_LENGTH-1:0] OutX4_w, OutX4_r;
    reg ValidOut_w, ValidOut_r;

    reg signed [WORD_LENGTH-1:0] R11_r, R11_w;
    reg signed [WORD_LENGTH-1:0] R12_r, R12_w;
    reg signed [WORD_LENGTH-1:0] R13_r, R13_w;
    reg signed [WORD_LENGTH-1:0] R14_r, R14_w;
    reg signed [WORD_LENGTH-1:0] R22_r, R22_w;
    reg signed [WORD_LENGTH-1:0] R23_r, R23_w;
    reg signed [WORD_LENGTH-1:0] R24_r, R24_w;
    reg signed [WORD_LENGTH-1:0] R33_r, R33_w;
    reg signed [WORD_LENGTH-1:0] R34_r, R34_w;
    reg signed [WORD_LENGTH-1:0] R44_r, R44_w;

    reg signed [WORD_LENGTH-1:0] z1_r, z1_w;
    reg signed [WORD_LENGTH-1:0] z2_r, z2_w;
    reg signed [WORD_LENGTH-1:0] z3_r, z3_w;
    reg signed [WORD_LENGTH-1:0] z4_r, z4_w;

    reg signed [WORD_LENGTH-1:0] mA_r, mA_w;
    reg signed [WORD_LENGTH-1:0] mB_r, mB_w;
    reg signed [WORD_LENGTH-1:0] dA_r, dA_w;
    reg signed [WORD_LENGTH-1:0] dB_r, dB_w;

    wire signed [WORD_LENGTH-1:0] mC;
    wire signed [WORD_LENGTH-1:0] dC;

    assign OutX1 = OutX1_r;
    assign OutX2 = OutX2_r;
    assign OutX3 = OutX3_r;
    assign OutX4 = OutX4_r;
    assign ValidOut = ValidOut_r;

    MUL #(
        .WORD_LENGTH(WORD_LENGTH),
        .FRACTION_LENGTH(FRACTION_LENGTH)
    ) mul_inst (
        .A(mA_r),
        .B(mB_r),
        .C(mC)
    );

    DIV #(
        .WORD_LENGTH(WORD_LENGTH),
        .FRACTION_LENGTH(FRACTION_LENGTH)
    ) div_inst (
        .A(dA_r),
        .B(dB_r),
        .C(dC)
    );

    reg [3:0] cnt_i_r, cnt_i_w;
    reg [3:0] cnt_j_r, cnt_j_w;

    always @(*) begin
        cnt_i_w = cnt_i_r;
        OutX1_w = OutX1_r;
        OutX2_w = OutX2_r;
        OutX3_w = OutX3_r;
        OutX4_w = OutX4_r;
        R11_w = R11_r;
        R12_w = R12_r;
        R13_w = R13_r;
        R14_w = R14_r;
        R22_w = R22_r;
        R23_w = R23_r;
        R24_w = R24_r;
        R33_w = R33_r;
        R34_w = R34_r;
        R44_w = R44_r;
        z1_w = z1_r;
        z2_w = z2_r;
        z3_w = z3_r;
        z4_w = z4_r;
        case (cnt_i_r)
            4'd0: begin
                if (ValidIn) begin
                    cnt_i_w = cnt_i_r + 1;
                    R11_w = InData1;
                end
            end 
            4'd1: begin
                R12_w = InData1;
                cnt_i_w = cnt_i_r + 1;
            end
            4'd2: begin
                R13_w = InData1;
                R22_w = InData2;
                cnt_i_w = cnt_i_r + 1;
            end
            4'd3: begin
                R14_w = InData1;
                R23_w = InData2;
                cnt_i_w = cnt_i_r + 1;
            end
            4'd4: begin
                z1_w = InData1;
                R24_w = InData2;
                R33_w = InData3;
                cnt_i_w = cnt_i_r + 1;
            end
            4'd5: begin
                z2_w = InData2;
                R34_w = InData3;
                cnt_i_w = cnt_i_r + 1;
            end
            4'd6: begin
                z3_w = InData3;
                R44_w = InData4;
                cnt_i_w = cnt_i_r + 1;
            end
            4'd7: begin
                z4_w = InData4;
                cnt_i_w = cnt_i_r + 1;
            end
            4'd8: begin
                cnt_i_w = 0; // Reset counter for next iteration
            end
        endcase
    end

    always @(*) begin
        cnt_j_w = 0;
        mA_w = 0;
        mB_w = 0;
        dA_w = 0;
        dB_w = 0;
        ValidOut_w = 0;
        case (cnt_j_r)
            4'd0: begin
                if (cnt_i_r == 4'd8) begin
                    dA_w = z4_r;
                    dB_w = R44_r;
                    cnt_j_w = cnt_j_r + 1;
                end
            end
            4'd1: begin // dC = x4
                OutX4_w = dC;
                mA_w = dC;
                mB_w = R34_r;
                cnt_j_w = cnt_j_r + 1;
            end
            4'd2: begin // mC = R34 * x4
                dA_w = z3_r - mC;
                dB_w = R33_r;
                mA_w = OutX4_r;
                mB_w = R24_r;
                cnt_j_w = cnt_j_r + 1;
            end 
            4'd3: begin // dC = x3, mC = R24 * x4
                OutX3_w = dC;
                mA_w = dC;
                mB_w = R23_r;
                z2_w = z2_r - mC; // z2 - R24*x4
                cnt_j_w = cnt_j_r + 1;
            end
            4'd4: begin // mC = R23 * x3
                dA_w = z2_r - mC;
                dB_w = R22_r;
                mA_w = OutX4_r;
                mB_w = R14_r;
                cnt_j_w = cnt_j_r + 1;
            end
            4'd5: begin // dC = x2, mC = R14 * x4
                OutX2_w = dC;
                mA_w = OutX3_r;
                mB_w = R13_r;
                z1_w = z1_r - mC; // z1 - R14*x4
                cnt_j_w = cnt_j_r + 1;
            end
            4'd6: begin // mC = R13 * x3
                z1_w = z1_r - mC; // z1 - R14*x4 - R13*x3
                mA_w = OutX2_r;
                mB_w = R12_r;
                cnt_j_w = cnt_j_r + 1;
            end
            4'd7: begin // mC = R12 * x2
                dA_w = z1_r - mC; // z1 - R14*x4 - R13*x3 - R12*x2
                dB_w = R11_r;
                cnt_j_w = cnt_j_r + 1;
            end
            4'd8: begin // dC = x1
                OutX1_w = dC;
                cnt_j_w = cnt_j_r + 1;
            end
            4'd9: begin // Reset counters and outputs
                ValidOut_w = 1; // Indicate valid output
                cnt_j_w = 0; // Reset counter for next iteration
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_i_r <= 0;
            cnt_j_r <= 0;
            ValidOut_r <= 0;
            OutX1_r <= 0;
            OutX2_r <= 0;
            OutX3_r <= 0;
            OutX4_r <= 0;
            R11_r <= 0;
            R12_r <= 0;
            R13_r <= 0;
            R14_r <= 0;
            R22_r <= 0;
            R23_r <= 0;
            R24_r <= 0;
            R33_r <= 0;
            R34_r <= 0;
            R44_r <= 0;
            z1_r <= 0;
            z2_r <= 0;
            z3_r <= 0;
            z4_r <= 0;
            mA_r <= 0;
            mB_r <= 0;
            dA_r <= 0;
            dB_r <= 0;
        end else begin
            cnt_i_r <= cnt_i_w;
            cnt_j_r <= cnt_j_w;
            ValidOut_r <= ValidOut_w;
            OutX1_r <= OutX1_w;
            OutX2_r <= OutX2_w;
            OutX3_r <= OutX3_w;
            OutX4_r <= OutX4_w;
            R11_r <= R11_w;
            R12_r <= R12_w;
            R13_r <= R13_w;
            R14_r <= R14_w;
            R22_r <= R22_w;
            R23_r <= R23_w;
            R24_r <= R24_w;
            R33_r <= R33_w;
            R34_r <= R34_w;
            R44_r <= R44_w;
            z1_r <= z1_w;
            z2_r <= z2_w;
            z3_r <= z3_w;
            z4_r <= z4_w;
            mA_r <= mA_w;
            mB_r <= mB_w;
            dA_r <= dA_w;
            dB_r <= dB_w;
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