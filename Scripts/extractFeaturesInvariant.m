function feats = extractFeaturesInvariant(window)
% window: 128 x 6 matrix [acc_x,acc_y,acc_z,gyro_x,gyro_y,gyro_z]

acc = window(:, 1:3);
gyro = window(:, 4:6);

accMag = sqrt(sum(acc.^2, 2));
gyroMag = sqrt(sum(gyro.^2, 2));

feats = [];

feats = [feats, mean(accMag), std(accMag), max(accMag), min(accMag), ...
    rms(accMag), skewness(accMag), kurtosis(accMag), sum(accMag.^2)];

feats = [feats, mean(gyroMag), std(gyroMag), max(gyroMag), min(gyroMag), ...
    rms(gyroMag), skewness(gyroMag), kurtosis(gyroMag), sum(gyroMag.^2)];

for col = 1:6
    signal = window(:, col);
    feats = [feats, std(signal), rms(signal)];
end
end