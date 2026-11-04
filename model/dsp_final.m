clear;
clc; 
close all;
%% load input test pattern
%load("input_patterns.mat");
load("qr_test_patterns.mat");
% load("input_patterns_updated.mat");


%% Fixed-point config for saving
save_wordLength = 25;
save_fracLength = 19;
T_save = numerictype(1, save_wordLength, save_fracLength);
F_save = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Wrap', ...
                'ProductMode', 'SpecifyPrecision', 'ProductWordLength', save_wordLength, 'ProductFractionLength', save_fracLength, ...
                'SumMode', 'SpecifyPrecision', 'SumWordLength', save_wordLength, 'SumFractionLength', save_fracLength);
fileID = fopen('testcases.txt', 'w');
for i = 1 : length(A_matrices)
    % Convert and write y
    A = A_matrices{1,i};
    y = y_vectors{1,i};
    
    % Convert and write A
    A_fixed = fi(reshape(A.', [], 1), T_save, F_save);
    A_bin = arrayfun(@(v) bin(v), A_fixed, 'UniformOutput', false);
    for k = 1:length(A_bin)
        fprintf(fileID, '%s\n', A_bin{k});
    end
    
    y_fixed = fi(y(:), T_save, F_save);
    y_bin = arrayfun(@(v) bin(v), y_fixed, 'UniformOutput', false);
    for k = 1:length(y_bin)
        fprintf(fileID, '%s\n', y_bin{k});
    end
end
fclose(fileID);


%% bittrue model
N = 18;
wordLength = 25;
fracLength = 19;

error = zeros(length(A_matrices),1);

x_fix = [];

for i = 1:length(A_matrices)
    A = A_matrices{1,i};
    y = y_vectors{1,i};
    
    %cycle 1 cordic
    [A(1,1), A(2,1), rotation_dir_1] = cordic_vector(A(1,1), A(2,1), N, wordLength, fracLength);
    
    %cycle 2 cordic
    [A(1,2), A(2,2)] = cordic_rotation(A(1,2), A(2,2), N, rotation_dir_1, wordLength, fracLength);
    [A(1,1), A(3,1), rotation_dir_2] = cordic_vector(A(1,1), A(3,1), N, wordLength, fracLength);
    
    
    %cycle 3 cordic
    [A(1,3), A(2,3)] = cordic_rotation(A(1,3), A(2,3), N, rotation_dir_1, wordLength, fracLength);
    [A(1,2), A(3,2)] = cordic_rotation(A(1,2), A(3,2), N, rotation_dir_2, wordLength, fracLength);
    [A(1,1), A(4,1), rotation_dir_3] = cordic_vector(A(1,1), A(4,1), N, wordLength, fracLength);
    
    [A(2,2), A(3,2), rotation_dir_4] = cordic_vector(A(2,2), A(3,2), N, wordLength, fracLength);
    %cycle 4 cordic
    [A(1,4), A(2,4)] = cordic_rotation(A(1,4), A(2,4), N, rotation_dir_1, wordLength, fracLength);
    [A(1,3), A(3,3)] = cordic_rotation(A(1,3), A(3,3), N, rotation_dir_2, wordLength, fracLength);
    [A(1,2), A(4,2)] = cordic_rotation(A(1,2), A(4,2), N, rotation_dir_3, wordLength, fracLength);
    
    [A(2,3), A(3,3)] = cordic_rotation(A(2,3), A(3,3), N, rotation_dir_4, wordLength, fracLength);
    [A(2,2), A(4,2), rotation_dir_5] = cordic_vector(A(2,2), A(4,2), N, wordLength, fracLength);
    
    %cycle 5 cordic
    [y(1), y(2)] = cordic_rotation(y(1), y(2), N, rotation_dir_1, wordLength, fracLength);
    [A(1,4), A(3,4)] = cordic_rotation(A(1,4), A(3,4), N, rotation_dir_2, wordLength, fracLength);
    [A(1,3), A(4,3)] = cordic_rotation(A(1,3), A(4,3), N, rotation_dir_3, wordLength, fracLength);
    
    [A(2,4), A(3,4)] = cordic_rotation(A(2,4), A(3,4), N, rotation_dir_4, wordLength, fracLength);
    [A(2,3), A(4,3)] = cordic_rotation(A(2,3), A(4,3), N, rotation_dir_5, wordLength, fracLength);
    
    [A(3,3), A(4,3), rotation_dir_6] = cordic_vector(A(3,3), A(4,3), N, wordLength, fracLength);
    
    %cycle 6 cordic
    [y(1), y(3)] = cordic_rotation(y(1), y(3), N, rotation_dir_2, wordLength, fracLength);
    [A(1,4), A(4,4)] = cordic_rotation(A(1,4), A(4,4), N, rotation_dir_3, wordLength, fracLength);
    
    [y(2), y(3)] = cordic_rotation(y(2), y(3), N, rotation_dir_4, wordLength, fracLength);
    [A(2,4), A(4,4)] = cordic_rotation(A(2,4), A(4,4), N, rotation_dir_5, wordLength, fracLength);
    
    [A(3,4), A(4,4)] = cordic_rotation(A(3,4), A(4,4), N, rotation_dir_6, wordLength, fracLength);
    
    %cycle 7
    [y(1), y(4)] = cordic_rotation(y(1), y(4), N, rotation_dir_3, wordLength, fracLength);
    
    [y(2), y(4)] = cordic_rotation(y(2), y(4), N, rotation_dir_5, wordLength, fracLength);
    
    [y(3), y(4)] = cordic_rotation(y(3), y(4), N, rotation_dir_6, wordLength, fracLength);

    x_bittrue = zeros(4,1);
    
    wordLength_div = 18;
    fracLength_div = 12;
    T = numerictype(1, wordLength_div, fracLength_div);
    F = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Wrap', ...
                   'ProductMode', 'SpecifyPrecision', 'ProductWordLength', wordLength_div, 'ProductFractionLength', fracLength_div, ...
                   'SumMode', 'SpecifyPrecision', 'SumWordLength', wordLength_div, 'SumFractionLength', fracLength_div);
    
    
    x_bittrue(4) = fi(y(4)/A(4,4), T, F);
 
    x_bittrue(3) = fi((y(3)-A(3,4)*x_bittrue(4))/A(3,3) , T, F);

    
    x_bittrue(2) = fi((y(2)-A(2,3)*x_bittrue(3)-A(2,4)*x_bittrue(4))/A(2,2) , T, F);
    
    x_bittrue(1) =  fi((y(1)-A(1,2)*x_bittrue(2) -A(1,3)*x_bittrue(3)-A(1,4)*x_bittrue(4))/A(1,1) , T, F);
    
    x_true = x_solutions{1,i};
    
    error(i) = sqrt(sum((x_true-x_bittrue).^2)/4);
    % fprintf("%d : %f, %f, %f, %f\n", i, x_bittrue(1), x_bittrue(2), x_bittrue(3), x_bittrue(4));
    x_fix = [x_fix; x_bittrue.'];
end

max_error = max(error);
figure();
plot((1:length(error)), error);
xlabel('test index');
ylabel('error');
title('bit true vs. floating point')
%%
x_rtl = [
    [0.256348, 0.316650, 0.138428, 0.107666],
    [0.191162, 1.143311, -1.754883, -0.415527],
    [0.777344, 0.502930, 0.231201, 0.457764],
    [-2.964600, 0.953125, -0.507080, 0.240723]
];
error = zeros(length(A_matrices),1);
x_rtl = x_rtl.';
x_fix = x_fix.';
for i = 1: length(A_matrices)
    error(i) = sqrt(sum((x_rtl(i)-x_bittrue(i)).^2)/4);
end
figure();
plot((1:length(error)), error);
title('rtl result vs. bit ture');
xlabel('test index');
ylabel('error');
%% Quantization of N
error_N = zeros(5,1);
for N = (15:19)
    error = Quantize_N(N, A_matrices, y_vectors, x_solutions);
    error_N(N-14) = max(error);
end
figure();
plot((15:19), error_N);
yline(10^-3, 'r--', '10^{-3}');
legend('Max Error', '10^{-3}');
xlabel('N');
ylabel('Max Error');
title('Max Error vs N');

%% Quantization of Cordic WL
error_Cordic_WL = zeros(5,1);
for Cordic_WL = (22:26)
    error = Quantize_Cordic_WL(18, Cordic_WL, A_matrices, y_vectors, x_solutions);
    error_Cordic_WL(Cordic_WL-21) = max(error);
end
figure();
plot((22:26), error_Cordic_WL);
yline(10^-3, 'r--', '10^{-3}');
legend('Max Error', '10^{-3}');
xlabel('Cordic Word Length');
ylabel('Max Error');
title('Max Error vs Cordic Word Length');

%% Quantization of MUL/DIV WL
error_MULDIV_WL = zeros(5,1);
for MULDIV_WL = (15:25)
    error = Quantize_MULDIV_WL(18, 25, MULDIV_WL, A_matrices, y_vectors, x_solutions);
    error_MULDIV_WL(MULDIV_WL-14) = max(error);
end
figure();
plot((15:25), error_MULDIV_WL);
yline(10^-3, 'r--', '10^{-3}');
legend('Max Error', '10^{-3}');
xlabel('MULDIV Word Length');
ylabel('Max Error');
title('Max Error vs MULDIV Word Length');

%% Cordic module

function [x_out, y_out, rotation_dir] = cordic_vector(x_in, y_in, N, wordLength, fracLength)

    % Define fixed-point type and math
    T = numerictype(1, wordLength, fracLength);
    F = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Wrap', ...
               'ProductMode', 'SpecifyPrecision', 'ProductWordLength', wordLength, 'ProductFractionLength', fracLength, ...
               'SumMode', 'SpecifyPrecision', 'SumWordLength', wordLength, 'SumFractionLength', fracLength);

    % Convert x, y to fixed-point
    x_fp = fi(x_in, T, F);
    y_fp = fi(y_in, T, F);
    rotation_dir = zeros(N+1,1);


    % Run CORDIC
    x_reg = x_fp;
    y_reg = y_fp;
    if x_reg < 0            
        rotation_dir(1) = 1;
        x_reg = - x_reg;
        y_reg = - y_reg;
    end   

    csd = 1;
    for i = 0:(N-1)
        csd = csd*sqrt(1 + 2^(-2*i));
    end
    csd = 1/csd;

    for i = 1:(N)
        if y_reg > 0
            rotation_dir(i + 1) = 1;
            x_new = x_reg + bitsra(y_reg, i-1);
            y_new = y_reg - bitsra(x_reg, i-1);
        else
            rotation_dir(i + 1) = 0;
            x_new = x_reg - bitsra(y_reg, i-1);
            y_new = y_reg + bitsra(x_reg, i-1);
        end
        x_reg = fi(x_new, T, F);
        y_reg = fi(y_new, T, F);
    end
    x_out = fi(x_reg*csd, T, F);
    y_out = fi(y_reg*csd, T, F);
end

function [x_out, y_out, rotation_dir] = cordic_vector_float(x_in, y_in, N)
    rotation_dir = zeros(N+1,1);
    % Run CORDIC
    x_reg = x_in;
    y_reg = y_in;
    if x_reg < 0            
        rotation_dir(1) = 1;
        x_reg = - x_reg;
        y_reg = - y_reg;
    end   

    csd = 1;
    for i = 0:(N-1)
        csd = csd*sqrt(1 + 2^(-2*i));
    end
    csd = 1/csd;

    for i = 1:(N)
        if y_reg > 0
            rotation_dir(i + 1) = 1;
            x_new = x_reg + bitsra(y_reg, i-1);
            y_new = y_reg - bitsra(x_reg, i-1);
        else
            rotation_dir(i + 1) = 0;
            x_new = x_reg - bitsra(y_reg, i-1);
            y_new = y_reg + bitsra(x_reg, i-1);
        end
        x_reg = x_new;
        y_reg = y_new;
    end
    x_out = x_reg*csd;
    y_out = y_reg*csd;
end

function [x_out, y_out] = cordic_rotation(x_in, y_in, N, rotation_dir, wordLength, fracLength)

    % Define fixed-point type and math
    T = numerictype(1, wordLength, fracLength);
    F = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Wrap', ...
               'ProductMode', 'SpecifyPrecision', 'ProductWordLength', wordLength, 'ProductFractionLength', fracLength, ...
               'SumMode', 'SpecifyPrecision', 'SumWordLength', wordLength, 'SumFractionLength', fracLength);

    % Convert x, y to fixed-point
    x_fp = fi(x_in, T, F);
    y_fp = fi(y_in, T, F);

    % Run CORDIC
    x_reg = x_fp;
    y_reg = y_fp;
    if rotation_dir(1) == 1
        x_reg = - x_reg;
        y_reg = - y_reg;
    end

    csd = 1;
    for i = 0:(N-1)
        csd = csd*sqrt(1 + 2^(-2*i));
    end
    csd = 1/csd;

    for i = 1:(N)
        if rotation_dir(i + 1) == 1
            x_new = x_reg + bitsra(y_reg, i-1);
            y_new = y_reg - bitsra(x_reg, i-1);
        else
            x_new = x_reg - bitsra(y_reg, i-1);
            y_new = y_reg + bitsra(x_reg, i-1);
        end
        x_reg = fi(x_new, T, F);
        y_reg = fi(y_new, T, F);
    end
    x_out = fi(x_reg*csd, T, F);
    y_out = fi(y_reg*csd, T, F);
end

function [x_out, y_out] = cordic_rotation_float(x_in, y_in, N, rotation_dir)
    % Run CORDIC
    x_reg = x_in;
    y_reg = y_in;
    if rotation_dir(1) == 1
        x_reg = - x_reg;
        y_reg = - y_reg;
    end

    csd = 1;
    for i = 0:(N-1)
        csd = csd*sqrt(1 + 2^(-2*i));
    end
    csd = 1/csd;

    for i = 1:(N)
        if rotation_dir(i + 1) == 1
            x_new = x_reg + bitsra(y_reg, i-1);
            y_new = y_reg - bitsra(x_reg, i-1);
        else
            x_new = x_reg - bitsra(y_reg, i-1);
            y_new = y_reg + bitsra(x_reg, i-1);
        end
        x_reg = x_new;
        y_reg = y_new;
    end
    x_out = x_reg*csd;
    y_out = y_reg*csd;
end

%% Quantize N
function [error] = Quantize_N(N, A_matrices, y_vectors, x_solutions)
    error = zeros(length(A_matrices),1);

    for i = 1:length(A_matrices)
        A = A_matrices{1,i};
        y = y_vectors{1,i};
        
        %cycle 1 cordic
        [A(1,1), A(2,1), rotation_dir_1] = cordic_vector_float(A(1,1), A(2,1), N);
        
        %cycle 2 cordic
        [A(1,2), A(2,2)] = cordic_rotation_float(A(1,2), A(2,2), N, rotation_dir_1);
        [A(1,1), A(3,1), rotation_dir_2] = cordic_vector_float(A(1,1), A(3,1), N);
        
        
        %cycle 3 cordic
        [A(1,3), A(2,3)] = cordic_rotation_float(A(1,3), A(2,3), N, rotation_dir_1);
        [A(1,2), A(3,2)] = cordic_rotation_float(A(1,2), A(3,2), N, rotation_dir_2);
        [A(1,1), A(4,1), rotation_dir_3] = cordic_vector_float(A(1,1), A(4,1), N);
        
        [A(2,2), A(3,2), rotation_dir_4] = cordic_vector_float(A(2,2), A(3,2), N);
        %cycle 4 cordic
        [A(1,4), A(2,4)] = cordic_rotation_float(A(1,4), A(2,4), N, rotation_dir_1);
        [A(1,3), A(3,3)] = cordic_rotation_float(A(1,3), A(3,3), N, rotation_dir_2);
        [A(1,2), A(4,2)] = cordic_rotation_float(A(1,2), A(4,2), N, rotation_dir_3);
        
        [A(2,3), A(3,3)] = cordic_rotation_float(A(2,3), A(3,3), N, rotation_dir_4);
        [A(2,2), A(4,2), rotation_dir_5] = cordic_vector_float(A(2,2), A(4,2), N);
        
        %cycle 5 cordic
        [y(1), y(2)] = cordic_rotation_float(y(1), y(2), N, rotation_dir_1);
        [A(1,4), A(3,4)] = cordic_rotation_float(A(1,4), A(3,4), N, rotation_dir_2);
        [A(1,3), A(4,3)] = cordic_rotation_float(A(1,3), A(4,3), N, rotation_dir_3);
        
        [A(2,4), A(3,4)] = cordic_rotation_float(A(2,4), A(3,4), N, rotation_dir_4);
        [A(2,3), A(4,3)] = cordic_rotation_float(A(2,3), A(4,3), N, rotation_dir_5);
        
        [A(3,3), A(4,3), rotation_dir_6] = cordic_vector_float(A(3,3), A(4,3), N);
        
        %cycle 6 cordic
        [y(1), y(3)] = cordic_rotation_float(y(1), y(3), N, rotation_dir_2);
        [A(1,4), A(4,4)] = cordic_rotation_float(A(1,4), A(4,4), N, rotation_dir_3);
        
        [y(2), y(3)] = cordic_rotation_float(y(2), y(3), N, rotation_dir_4);
        [A(2,4), A(4,4)] = cordic_rotation_float(A(2,4), A(4,4), N, rotation_dir_5);
        
        [A(3,4), A(4,4)] = cordic_rotation_float(A(3,4), A(4,4), N, rotation_dir_6);
        
        %cycle 7
        [y(1), y(4)] = cordic_rotation_float(y(1), y(4), N, rotation_dir_3);
        
        [y(2), y(4)] = cordic_rotation_float(y(2), y(4), N, rotation_dir_5);
        
        [y(3), y(4)] = cordic_rotation_float(y(3), y(4), N, rotation_dir_6);
        
        %% backsubstitution
        x_bittrue = zeros(4,1);
        
        x_bittrue(4) = y(4)/A(4,4);
        
        x_bittrue(3) = (y(3)-A(3,4)*x_bittrue(4))/A(3,3);
        
        x_bittrue(2) = (y(2)-A(2,3)*x_bittrue(3)-A(2,4)*x_bittrue(4))/A(2,2);
        
        x_bittrue(1) =  (y(1)-A(1,2)*x_bittrue(2) -A(1,3)*x_bittrue(3)-A(1,4)*x_bittrue(4))/A(1,1);
        
        x_true = x_solutions{1,i};
        
        error(i) = sqrt(sum((x_true-x_bittrue).^2)/4);
    end
end

%% Quantize Cordic WL
function [error] = Quantize_Cordic_WL(N, Cordic_WL, A_matrices, y_vectors, x_solutions)
    wordLength = Cordic_WL;
    fracLength = Cordic_WL - 6;

    error = zeros(length(A_matrices),1);

    for i = 1:length(A_matrices)
        A = A_matrices{1,i};
        y = y_vectors{1,i};
        
        %cycle 1 cordic
        [A(1,1), A(2,1), rotation_dir_1] = cordic_vector(A(1,1), A(2,1), N, wordLength, fracLength);
        
        %cycle 2 cordic
        [A(1,2), A(2,2)] = cordic_rotation(A(1,2), A(2,2), N, rotation_dir_1, wordLength, fracLength);
        [A(1,1), A(3,1), rotation_dir_2] = cordic_vector(A(1,1), A(3,1), N, wordLength, fracLength);
        
        
        %cycle 3 cordic
        [A(1,3), A(2,3)] = cordic_rotation(A(1,3), A(2,3), N, rotation_dir_1, wordLength, fracLength);
        [A(1,2), A(3,2)] = cordic_rotation(A(1,2), A(3,2), N, rotation_dir_2, wordLength, fracLength);
        [A(1,1), A(4,1), rotation_dir_3] = cordic_vector(A(1,1), A(4,1), N, wordLength, fracLength);
        
        [A(2,2), A(3,2), rotation_dir_4] = cordic_vector(A(2,2), A(3,2), N, wordLength, fracLength);
        %cycle 4 cordic
        [A(1,4), A(2,4)] = cordic_rotation(A(1,4), A(2,4), N, rotation_dir_1, wordLength, fracLength);
        [A(1,3), A(3,3)] = cordic_rotation(A(1,3), A(3,3), N, rotation_dir_2, wordLength, fracLength);
        [A(1,2), A(4,2)] = cordic_rotation(A(1,2), A(4,2), N, rotation_dir_3, wordLength, fracLength);
        
        [A(2,3), A(3,3)] = cordic_rotation(A(2,3), A(3,3), N, rotation_dir_4, wordLength, fracLength);
        [A(2,2), A(4,2), rotation_dir_5] = cordic_vector(A(2,2), A(4,2), N, wordLength, fracLength);
        
        %cycle 5 cordic
        [y(1), y(2)] = cordic_rotation(y(1), y(2), N, rotation_dir_1, wordLength, fracLength);
        [A(1,4), A(3,4)] = cordic_rotation(A(1,4), A(3,4), N, rotation_dir_2, wordLength, fracLength);
        [A(1,3), A(4,3)] = cordic_rotation(A(1,3), A(4,3), N, rotation_dir_3, wordLength, fracLength);
        
        [A(2,4), A(3,4)] = cordic_rotation(A(2,4), A(3,4), N, rotation_dir_4, wordLength, fracLength);
        [A(2,3), A(4,3)] = cordic_rotation(A(2,3), A(4,3), N, rotation_dir_5, wordLength, fracLength);
        
        [A(3,3), A(4,3), rotation_dir_6] = cordic_vector(A(3,3), A(4,3), N, wordLength, fracLength);
        
        %cycle 6 cordic
        [y(1), y(3)] = cordic_rotation(y(1), y(3), N, rotation_dir_2, wordLength, fracLength);
        [A(1,4), A(4,4)] = cordic_rotation(A(1,4), A(4,4), N, rotation_dir_3, wordLength, fracLength);
        
        [y(2), y(3)] = cordic_rotation(y(2), y(3), N, rotation_dir_4, wordLength, fracLength);
        [A(2,4), A(4,4)] = cordic_rotation(A(2,4), A(4,4), N, rotation_dir_5, wordLength, fracLength);
        
        [A(3,4), A(4,4)] = cordic_rotation(A(3,4), A(4,4), N, rotation_dir_6, wordLength, fracLength);
        
        %cycle 7
        [y(1), y(4)] = cordic_rotation(y(1), y(4), N, rotation_dir_3, wordLength, fracLength);
        
        [y(2), y(4)] = cordic_rotation(y(2), y(4), N, rotation_dir_5, wordLength, fracLength);
        
        [y(3), y(4)] = cordic_rotation(y(3), y(4), N, rotation_dir_6, wordLength, fracLength);
        
        %% backsubstitution
        x_bittrue = zeros(4,1);
        
        x_bittrue(4) = y(4)/A(4,4);
        
        x_bittrue(3) = (y(3)-A(3,4)*x_bittrue(4))/A(3,3);
        
        x_bittrue(2) = (y(2)-A(2,3)*x_bittrue(3)-A(2,4)*x_bittrue(4))/A(2,2);
        
        x_bittrue(1) =  (y(1)-A(1,2)*x_bittrue(2) -A(1,3)*x_bittrue(3)-A(1,4)*x_bittrue(4))/A(1,1);
        
        x_true = x_solutions{1,i};
        
        error(i) = sqrt(sum((x_true-x_bittrue).^2)/4);
    end
end

%% Quantize MULDIV WL
function [error] = Quantize_MULDIV_WL(N, Cordic_WL, MULDIV_WL, A_matrices, y_vectors, x_solutions)
    wordLength = Cordic_WL;
    fracLength = Cordic_WL - 6;

    error = zeros(length(A_matrices),1);

    for i = 1:length(A_matrices)
        A = A_matrices{1,i};
        y = y_vectors{1,i};
        
        %cycle 1 cordic
        [A(1,1), A(2,1), rotation_dir_1] = cordic_vector(A(1,1), A(2,1), N, wordLength, fracLength);
        
        %cycle 2 cordic
        [A(1,2), A(2,2)] = cordic_rotation(A(1,2), A(2,2), N, rotation_dir_1, wordLength, fracLength);
        [A(1,1), A(3,1), rotation_dir_2] = cordic_vector(A(1,1), A(3,1), N, wordLength, fracLength);
        
        
        %cycle 3 cordic
        [A(1,3), A(2,3)] = cordic_rotation(A(1,3), A(2,3), N, rotation_dir_1, wordLength, fracLength);
        [A(1,2), A(3,2)] = cordic_rotation(A(1,2), A(3,2), N, rotation_dir_2, wordLength, fracLength);
        [A(1,1), A(4,1), rotation_dir_3] = cordic_vector(A(1,1), A(4,1), N, wordLength, fracLength);
        
        [A(2,2), A(3,2), rotation_dir_4] = cordic_vector(A(2,2), A(3,2), N, wordLength, fracLength);
        %cycle 4 cordic
        [A(1,4), A(2,4)] = cordic_rotation(A(1,4), A(2,4), N, rotation_dir_1, wordLength, fracLength);
        [A(1,3), A(3,3)] = cordic_rotation(A(1,3), A(3,3), N, rotation_dir_2, wordLength, fracLength);
        [A(1,2), A(4,2)] = cordic_rotation(A(1,2), A(4,2), N, rotation_dir_3, wordLength, fracLength);
        
        [A(2,3), A(3,3)] = cordic_rotation(A(2,3), A(3,3), N, rotation_dir_4, wordLength, fracLength);
        [A(2,2), A(4,2), rotation_dir_5] = cordic_vector(A(2,2), A(4,2), N, wordLength, fracLength);
        
        %cycle 5 cordic
        [y(1), y(2)] = cordic_rotation(y(1), y(2), N, rotation_dir_1, wordLength, fracLength);
        [A(1,4), A(3,4)] = cordic_rotation(A(1,4), A(3,4), N, rotation_dir_2, wordLength, fracLength);
        [A(1,3), A(4,3)] = cordic_rotation(A(1,3), A(4,3), N, rotation_dir_3, wordLength, fracLength);
        
        [A(2,4), A(3,4)] = cordic_rotation(A(2,4), A(3,4), N, rotation_dir_4, wordLength, fracLength);
        [A(2,3), A(4,3)] = cordic_rotation(A(2,3), A(4,3), N, rotation_dir_5, wordLength, fracLength);
        
        [A(3,3), A(4,3), rotation_dir_6] = cordic_vector(A(3,3), A(4,3), N, wordLength, fracLength);
        
        %cycle 6 cordic
        [y(1), y(3)] = cordic_rotation(y(1), y(3), N, rotation_dir_2, wordLength, fracLength);
        [A(1,4), A(4,4)] = cordic_rotation(A(1,4), A(4,4), N, rotation_dir_3, wordLength, fracLength);
        
        [y(2), y(3)] = cordic_rotation(y(2), y(3), N, rotation_dir_4, wordLength, fracLength);
        [A(2,4), A(4,4)] = cordic_rotation(A(2,4), A(4,4), N, rotation_dir_5, wordLength, fracLength);
        
        [A(3,4), A(4,4)] = cordic_rotation(A(3,4), A(4,4), N, rotation_dir_6, wordLength, fracLength);
        
        %cycle 7
        [y(1), y(4)] = cordic_rotation(y(1), y(4), N, rotation_dir_3, wordLength, fracLength);
        
        [y(2), y(4)] = cordic_rotation(y(2), y(4), N, rotation_dir_5, wordLength, fracLength);
        
        [y(3), y(4)] = cordic_rotation(y(3), y(4), N, rotation_dir_6, wordLength, fracLength);
        
        %% backsubstitution
        x_bittrue = zeros(4,1);
        
        wordLength_div = MULDIV_WL;
        fracLength_div = MULDIV_WL - 6;
        T = numerictype(1, wordLength_div, fracLength_div);
        F = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Wrap', ...
                    'ProductMode', 'SpecifyPrecision', 'ProductWordLength', wordLength_div, 'ProductFractionLength', fracLength_div, ...
                    'SumMode', 'SpecifyPrecision', 'SumWordLength', wordLength_div, 'SumFractionLength', fracLength_div);
        
        
        x_bittrue(4) = fi(y(4)/A(4,4), T, F);
        
        x_bittrue(3) = fi((y(3)-A(3,4)*x_bittrue(4))/A(3,3) , T, F);
        
        x_bittrue(2) = fi((y(2)-A(2,3)*x_bittrue(3)-A(2,4)*x_bittrue(4))/A(2,2) , T, F);
        
        x_bittrue(1) =  fi((y(1)-A(1,2)*x_bittrue(2) -A(1,3)*x_bittrue(3)-A(1,4)*x_bittrue(4))/A(1,1) , T, F);
        
        x_true = x_solutions{1,i};
        
        error(i) = sqrt(sum((x_true-x_bittrue).^2)/4);
    end
end