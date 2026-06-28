clc;
close all;
clear;

Fs = 100e6;                    % Original ADC sampling rate: 100 MHz 
F_if = 20e6;                   % Target Intermediate Frequency (IF): 20 MHz 
F_interf = 35e6;               % Interference signal frequency: 35 MHz 
F_lo = 20e6;                   % DDS Local Oscillator frequency: 20 MHz 
Decimation_Rate = 10;          % Decimation factor M = 10 
Fs_new = Fs / Decimation_Rate; % Post-decimation sampling rate



