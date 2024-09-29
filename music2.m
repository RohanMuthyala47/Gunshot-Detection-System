M = 6;
theta_mic = [0, 60, 120, 180, 240, 300];
theta_mic_rad = deg2rad(theta_mic);
r = 0.05; 
c = 343; 
theta_source = 120; 
theta_source_rad = deg2rad(theta_source);
f = 1000; 
lambda = c / f; 
steering_vector = @(theta) exp(-1i * 2 * pi * r / lambda * cos(theta_mic_rad - theta)).';
[gunshot_signal, fs_audio] = audioread('gunshot.wav'); 
fs = 10000; 
gunshot_signal = resample(gunshot_signal, fs, fs_audio);
t_duration = 0.1; 
num_samples = round(t_duration * fs);
if length(gunshot_signal) > num_samples
    gunshot_signal = gunshot_signal(1:num_samples);
else
    gunshot_signal = [gunshot_signal; zeros(num_samples - length(gunshot_signal), 1)];
end
SNR = 40; 
received_signals = zeros(M, length(gunshot_signal));

for mic = 1:M
    tau = r / c * cos(theta_mic_rad(mic) - theta_source_rad); 
    sample_delay = round(tau * fs);  
    shifted_signal = circshift(gunshot_signal, sample_delay); 
    received_signals(mic, :) = awgn(shifted_signal, SNR);
end

received_signals = received_signals / max(abs(received_signals(:)));
R = (received_signals * received_signals') / size(received_signals, 2);
[eigenvectors, eigenvalues] = eig(R);
[~, idx] = sort(diag(eigenvalues), 'descend');
eigenvectors = eigenvectors(:, idx);
noise_subspace = eigenvectors(:, 2:end);
theta_scan = 0:0.1:360; 
P_music = zeros(size(theta_scan));

for i = 1:length(theta_scan)
    steering = steering_vector(deg2rad(theta_scan(i)));
    P_music(i) = 1 / (steering' * (noise_subspace * noise_subspace') * steering);
end

P_music = abs(P_music) / max(abs(P_music));
figure;
plot(theta_scan, 10*log10(P_music), 'LineWidth', 2);
title('MUSIC Spectrum');
xlabel('Angle(deg)');
ylabel('Power (dB)');
grid on;
hold on;
plot(theta_source, max(10*log10(P_music)), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
legend('MUSIC Spectrum', 'True DoA');
