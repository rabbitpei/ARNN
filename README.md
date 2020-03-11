ARNN
Run ARNN algorithm:

sample_code_ARNN.m

Test the ARNN Robustness:

Robust_test.m

prediction results show:

Movie1: typhoon prediction,

Movie2: traffic prediction

Note:

For windspeed dataset, unzip the compressed files first, then

cat scale_windspeed_PARTa* > scale_windspeed_a.txt

M = dlmread('scale_windspeed_a.txt');

save('scale_windspeed_a.mat', M);
