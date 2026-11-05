clc;
clear;
[x_solutions,A_matrices,y_vectors] = gen_qr_test_patterns(100);
save qr_test_patterns.mat x_solutions A_matrices y_vectors        % 儲存 .mat

function [X,A,Y] = gen_qr_test_patterns(N)
% 產生 N 組 {A,x,y}，並剔除 R(4,4)<0.05 的樣本
rng(0);                       % 重現性
cnt = 0;  X = {}; A = {}; Y = {};
while cnt < N
    x = randn(4,1);           % N(0,1)
    A_ = randn(4,4);
    [~,R] = qr(A_,0);
    if abs(R(4,4)) < 0.05, continue; end
    y = A_ * x;
    cnt = cnt + 1;
    X{cnt}=x;  A{cnt}=A_;  Y{cnt}=y;
end
end