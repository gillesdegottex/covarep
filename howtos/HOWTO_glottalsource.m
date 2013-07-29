% Short test script for running algorithms related to the glottal source
%
% License
%  This file is under the LGPL license,  you can
%  redistribute it and/or modify it under the terms of the GNU Lesser General 
%  Public License as published by the Free Software Foundation, either version 3 
%  of the License, or (at your option) any later version. This file is
%  distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
%  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
%  PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
%  details.
%
% This function is part of the Covarep project: http://covarep.github.io/covarep
%


clear all;

% Do check for version/toolbox
try
    load system_net_creak.mat
    ver_flag=1;
catch disp('Version or toolboxes do not support neural network object used in creaky voice detection')
    ver_flag=0;
end
    

% Settings
F0min = 80; % Minimum F0 set to 80 Hz
F0max = 500; % Maximum F0 set to 80 Hz
frame_shift = 10; % Frame shift in ms

% Load soundfile
[x,fs] = wavread('arctic_a0007.wav');

% Check the speech signal polarity
polarity = polarity_reskew(x,fs);
x=polarity*x;

% Extract the pitch and voicing information
[srh_f0,srh_vuv,srh_vuvc,srh_time] = pitch_srh(x,fs,F0min,F0max,frame_shift);

% Creaky probability estimation
if ver_flag==1
    [creak_pp,creak_bin] = detect_creaky_voice(x,fs); % Detect creaky voice
    creak=interp1(creak_bin(:,2),creak_bin(:,1),1:length(x));
    creak(creak<0.5)=0; creak(creak>=0.5)=1;
else creak=zeros(length(x),1);
    creak_pp=zeros(length(x),2);
    creak_pp(:,2)=1:length(x);
end

% GCI estimation
sd_gci = gci_sedreams(x,fs,median(srh_f0),1);        % SEDREAMS
se_gci = se_vq(x,fs,median(srh_f0),creak);           % SE-VQ

res = lpcresidual(x,25/1000*fs,5/1000*fs,fs/1000+2); % LP residual

m = mdq(res,fs,se_gci); % Maxima dispersion quotient measurement

ps = peakslope(x,fs);   % peakSlope extraction

gf_iaif = iaif_ola(x,fs);    % Glottal flow by the IAIF method

dgf_cc = complex_cepstrum(x,fs,sd_gci,srh_f0,srh_vuv); % Glottal flow derivative by the complex cesptrum-based method


% Plots
t=(0:length(x)-1)/fs;

fig(1) = subplot(511);
    plot(t,x, 'b');
    hold on
    plot(srh_time, srh_vuv, 'g');
    stem(sd_gci,ones(1,length(sd_gci))*-.1,'m');
    stem(se_gci,ones(1,length(se_gci))*-.1,'r');
    legend('Speech signal','Voicing (SRH)', 'GCI (SEDREAMS)','GCI (SE-VQ)');
    xlabel('Time [s]');
    ylabel('Amplitude');

fig(2) = subplot(512);
    plot(srh_time, srh_f0, 'r');
    legend('f0 (SRH)');
    xlabel('Time [s]');
    ylabel('Hz');

fig(3) = subplot(513);
    plot(t,x, 'b');
    hold on
    plot(ps(:,1), ps(:,2),'--b');
    plot(m(:,1),m(:,2),'m');
    legend('Speech signal','PeakSlope','MDQ');
    xlabel('Time [s]');

fig(4) = subplot(514);
    plot(t,x, 'b');
    hold on
    plot(t,norm(x)*gf_iaif./norm(gf_iaif), 'g');
    plot(creak_pp(:,2)/fs,creak_pp(:,1),'r')
    xlabel('Time [s]');
    ylabel('Amplitude');
    legend('Speech signal','Glottal flow (IAIF)','Creaky voice probability','Location','NorthWest');
    
    
fig(5) = subplot(515);
    plot(t,x, 'b');
    hold on
    plot(t,norm(x)*dgf_cc./norm(dgf_cc), 'r');    
    xlabel('Time [s]');
    ylabel('Amplitude');
    legend('Speech signal','Glottal flow derivative (CC)');
    

linkaxes(fig, 'x');
xlim([0 srh_time(end)]);
