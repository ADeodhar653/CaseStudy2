 close all 
 clear all clc;

% Bipolar, Baseband PAM transmitter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Signal Generation
% INPUT:  none
% OUTPUT: binary data
temp      = 'ESE 471';
data      = text2bits(temp);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Modulation Scheme 
% INPUT: data
% OUPUT: modulated values, x
inputVec  = [0   1];
outputVec = [-1  1];
x         = lut(data, inputVec, outputVec);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Input Signal Parameters
Tp = 0.1; % Half of the pulse duration
samples_per_bit = 50; %Oversampling factor 
SPB = samples_per_bit;
dt = Tp / samples_per_bit; % Sampling period
Ts = .1 % Symbol period

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate sinc pulse
N = length(data); % Symbols per message 
Lp = 8;% % Duration of Pulse 





% Generate SRRC pulse
alpha = 0.5;%Roll of factor 

n = [(-N * Lp) : (N * Lp)] + 10^-9;

srrcPulse = (1 / sqrt(N)) * (sin(pi * (1 - alpha) * n / N) + ...
    (4 * alpha * n / N) .* cos(pi * (1 + alpha) * n / N)) ... 
    ./ (pi * n / N .* (1 - (4 * alpha * n / N).^2));
pulse = srrcPulse;
%pulse= sinc(t/Ts);

t = (0:(N*SPB+length(pulse)-2)) * dt - Tp*2*N;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Oversample and Multiply x with Pulse in Time Domain

UpSample_data = zeros(1, N * SPB);
for i = 1:N
    UpSample_data(SPB * (i - 1) + 1) = x(i);
end

y = zeros(1, N*SPB + length(pulse) - 1);
for i = 1:N
    i1 = SPB * (i - 1) + 1;
    i2 = i1 + length(pulse) - 1;
    y(i1:i2) = y(i1:i2) + UpSample_data(i1) * pulse;
end

% Plot original data
figure;
stem(data);
title('Original Data');
xlabel('Index');
ylabel('Value');

% Plot oversampled data (UpSample_data)
figure;
stem(UpSample_data);
title('Oversampled Data');
xlabel('Index');
ylabel('Value');

% Plot modulated signal (y)
figure;
plot(y);
title('Modulated Signal');
xlabel('Time');
ylabel('Amplitude');

fprintf('The size of y is %d x %d\n', size(y));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Upconvert 
wc = 2 * pi * 20; % 20Hz modulation
z = cos(wc*t(1:length(y)));
y = y .* z;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add in Noise
sigmaList = (0.2:0.2:1);
errorRateSlow = zeros(length(sigmaList));
errorRateFast = zeros(length(sigmaList));
for i = 1:length(sigmaList)
    sigma = sigmaList(i);

    %rSlow = y + sigma * randn(1, length(y)); % Add noise to sent signal
    
    % DownConvert
    rSlow = y.*z; 

    % Matched Filter acts like downsampling 
    rSlow = conv(rSlow,pulse); % Use the pulse as a filter for what we received

    % Plot received signal before matched filter
    figure;
    plot(rSlow);
    title('Received Signal Before Matched Filter');
    xlabel('Time');
    ylabel('Amplitude');

   % Bit Decisions 
    pulse_delay = floor(length(pulse) / 2);
    start_point = pulse_delay +1;

    sample_points = start_point : SPB : (start_point + SPB*(length(data)-1));
    sample_points = sample_points(sample_points <= length(rSlow));

    fprintf('The sample points are: ');
    disp(sample_points);

    data_out = 2 * (rSlow(sample_points) > 0) - 1;

    % Plot received signal after matched filter
    figure;
    plot(data_out);
    title('Received Signal After Matched Filter');
    xlabel('Time');
    ylabel('Amplitude');


    %Calculate Error Rate
    errorRateSlow(i) = sum(data_out ~= data(1:length(data_out))) / length(data_out);
    fprintf('Error rate: %.2f%%\n', errorRateSlow(i) * 100)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Translate to ascii text
% INPUT: Bits
% OUTPUT: Character vector, message_out
message_out = binvector2str(data_out)