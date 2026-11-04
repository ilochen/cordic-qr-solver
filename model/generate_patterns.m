% Reproducible, well-conditioned systems for dsp_final.m
rng(7);
A_matrices = cell(1,100); y_vectors = cell(1,100);
for i=1:100
    A = 0.5*randn(4); A = A + diag(sum(abs(A),2)+1);
    A_matrices{i} = A; y_vectors{i} = randn(4,1);
end
save('qr_test_patterns.mat','A_matrices','y_vectors');
