function feats = extractFeatures(window)
% window: 128 x 6 matrix [acc_x,acc_y,acc_z,gyro_x,gyro_y,gyro_z]
feats = [];
for col = 1:6
    signal = window(:, col);
    feats = [feats, mean(signal), std(signal), max(signal), min(signal), ...
        rms(signal), skewness(signal), kurtosis(signal), ...
        sum(signal.^2)]; % energy
end
end