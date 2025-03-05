clc; clear; close all;

% Sampling parameters
Fs = 80e6; % 80 MHz sampling frequency
T = 1/Fs;  % Sample period

% Define test frequencies
frequencies = [8e6, 16e6, 24e6]; % 8 MHz, 16 MHz, 24 MHz

for f = frequencies
    % Determine the exact number of cycles for periodic sampling
    num_cycles = lcm(Fs, f) / f; % LCM ensures exact periodicity
    N = num_cycles * Fs / f; % Total samples needed
    
    t = (0:N-1) * T; % Time vector
    signal = sin(2 * pi * f * t); % Generating sine wave

    % Save to text file with one value per line (no delimiter)
    filename = sprintf('sinewave_%dMHz.txt', f/1e6);
    fid = fopen(filename, 'w'); % Open file for writing
    fprintf(fid, '%.6f\n', signal); % Write one value per line
    fclose(fid); % Close file

    % Plot signal
    figure;
    plot(t * 1e6, signal, '-o');
    xlabel('Time (µs)');
    ylabel('Amplitude');
    title(sprintf('%d MHz Sine Wave', f/1e6));
    grid on;
end

disp('Files generated with floating-point values.');
