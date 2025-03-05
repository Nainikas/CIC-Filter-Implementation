clc; clear; close all;

% Sampling parameters
Fs = 80e6; % 80 MHz sampling frequency
T = 1/Fs;  % Sample period in seconds

% Define test frequencies
frequencies = [8e6, 16e6, 24e6]; % 8 MHz, 16 MHz, 24 MHz
filenames_input = {'sinewave_8MHz.txt', 'sinewave_16MHz.txt', 'sinewave_24MHz.txt'};
filenames_output = {'output_8MHz.txt', 'output_16MHz.txt', 'output_24MHz.txt'};

% CIC Filter Bit Widths
CI_SIZE = 18; % Input bit width
CO_SIZE = 30; % Output bit width

% Create figure for time-domain comparison
figure;
sgtitle('CIC Filter Input vs. Output (Time Domain)');

for i = 1:length(frequencies)
    % Load Input and Output Data
    input_data = load(filenames_input{i});
    output_data = load(filenames_output{i});

    % Normalize only if max value is nonzero
    if max(abs(input_data)) > 0
        input_data = input_data / max(abs(input_data)); % Normalize input
    end
    if max(abs(output_data)) > 0
        output_data = output_data / max(abs(output_data)); % Normalize output
    end

    % Ensure input and output have the same length
    min_length = min(length(input_data), length(output_data));
    input_data = input_data(1:min_length);
    output_data = output_data(1:min_length);

    % Convert to Microseconds
    t = (0:min_length-1) * T * 1e6; % Time in µs

    % Plot Input and Output Signals Separately in Subplots
    subplot(3, 1, i); % 3 rows, 1 column, subplot index i
    plot(t, input_data, 'b', 'LineWidth', 1.5, 'DisplayName', 'Input Sine Wave');
    hold on;
    plot(t, output_data, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Filtered Output');
    xlabel('Time (µs)');
    ylabel('Amplitude');
    title(sprintf('CIC Filter Time Response for %d MHz', frequencies(i)/1e6));
    legend;
    grid on;
end

disp('Input vs. output sine waves plotted.');
