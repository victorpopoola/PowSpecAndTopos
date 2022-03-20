%% Code written by [REDACTED] for their 3rd Year Research Project in [REDACTED]'s laboratory

% This code allows for the calculation of the average pow spec across the
% head and the average topoplots for a group of 10-sec epochs. It also
% returns the absolute band power within each band for every epoch.

% For it to work, DO NOT RUN THE ENTIRE PIPELINE – you must just run
% particular sections of the code (from *loading in the epoch* to *adding
% it to your averaging variable*) multiple times.

% Once every epoch in the group has been added to the averaging variables,
% you can produce your outputs.

% This code works particularly well on a machine with limited processing
% power (i.e., it cannot load in an entire recording at once). It does,
% however, take a lot of manual labour to individually load in each of
% these epochs. It is a trade-off.

%% First, set up fieldtrip and load up ya layout

% Fieldtrip setup:

clc; %clears command window
clear; %clears all variables from workspace
close all; %closes all fieldtrip figures open

addpath '/Users/victorpopoola/fieldtrip-20210616' % the folder where ft_preprocessing.m exists
ft_defaults;

% loading up ya layout:
cfg = [];
load('/Volumes/VICTORPROJ/FHS_2021_Michaelmas/layout_perf1020.mat', 'layout_perf1020');
cfg.layout = layout_perf1020;
% layout should be 2D, and consist of electrodes labelled in the 10-20
% format

%% Load in your epoch of interest (minimal filtering and detrending)
% to do this: first, let's load in our epoch of interest:
cfg = []; 
cd '/Volumes/VICTORPROJ/FHS_2021_Michaelmas/Pt_10_11'
cfg.dataset = '101121_Rec1_PainDRG - 20211110T110216.DATA.Poly5'; % the only line to change per patient. occurs twice in this script
cfg.channel = {'ExG1', 'ExG2', 'ExG3', 'ExG4', 'ExG5', 'ExG6', 'ExG7', 'ExG8', 'ExG9', 'ExG10', 'ExG11', 'ExG12', 'ExG13', 'ExG14', 'ExG15', 'ExG16', 'ExG17', 'ExG18', 'ExG19', 'ExG20', 'ExG21', 'ExG22', 'ExG23'};
numOfSecs = 3546; % insert the number of seconds at which the 10-sec epoch starts
cfg.trl = [(numOfSecs)*2048 (numOfSecs+10)*2048 0]; %% [beg end offset] in samples. time in seconds * 2048 = sample number. 20 mins = 1200 secs = sample no. 2457600. 10 secs later = 20480 samples later.
rawData = ft_preprocessing(cfg);

% change the labels to 10-20 system so they work with layout
tempElectrodes(1,:) = {'Fp1', 'Fpz', 'Fp2', 'F7', 'F3', 'Fz', 'F4', 'F8', 'M1', 'T7', 'C3', 'Cz', 'C4', 'T8', 'M2', 'P7', 'P3', 'Pz', 'P4', 'P8', 'O1', 'Oz', 'O2'};
rawData.label = tempElectrodes';
% general demeaning and detrending:
cfg = [];
cfg.demean     = 'yes';
cfg.detrend    = 'yes';
cfg.polyremoval = 'yes';
cfg.polyorder = 1;
detrendedData = ft_preprocessing(cfg,rawData);
% filtering to allow all frequencies:
cfg = [];
cfg.hpfilter = 'yes' ; 
cfg.hpfreq = 0.2;
cfg.hpfiltord = 3;
cfg.lpfilter = 'yes';
cfg.lpfreq = 180;
cfg.bsfilter = 'yes';
cfg.bsfreq = [49 51; 99 100; 149 151];
filteredData = ft_preprocessing(cfg, detrendedData);

%% Quick visualisation to check epoch is usable

preprocData = filteredData;
cfg = [];
cfg.channel = 'all';
cfg.viewmode = 'vertical';
cfg.continuous = 'yes';
cfg.blocksize = 10;
artif = ft_databrowser(cfg, preprocData);

% at this point, remove any unusable / empty channels. enter them in the
% code below:
badChannels2 = {'EEG' '-Fp1' '-Fp2' '-Fpz' '-F8' '-F7' '-Fz'}; % bad channels for patient 1011
cfg = [];
cfg.channel = badChannels2;
preprocData = ft_selectdata(cfg, preprocData);

% visualise the channels you're keeping:
cfg = [];
cfg.channel = 'all';
cfg.viewmode = 'vertical';
cfg.continuous = 'yes';
cfg.blocksize = 10;
artif = ft_databrowser(cfg, preprocData);

%% Band definitions: delta(0.1-4Hz), theta(4-7Hz), alpha(8-12Hz), beta(13-30Hz), gamma(30-100Hz)

%% Frequency investigations: calculating absolute band power and producing a pow spec

% notes:
% DON'T average the time series of electrodes in a region, as this cancels
% activity!! instead, average the power spectra themselves.



%%%% creating average power spectra across the head between 0 and 45Hz:

cfg = [];
cfg.length  = 4; % cutting up data into 4sec periods
cfg.overlap = 0.5; % Welsh's method. fyi 0.5 is a proportion, not number of secs
cutUpData4s    = ft_redefinetrial(cfg, preprocData);
cfg = [];
cfg.output  = 'pow';
cfg.channel = 'all';
cfg.method  = 'mtmfft';
cfg.taper   = 'hanning';
cfg.foi     = 0.5:0.25:45; % steps of 0.25 because 1/timewin = freq resolution
allFrequencyFFT   = ft_freqanalysis(cfg, cutUpData4s);
% this variable contains a powspctrm for each channel.
% now to average across all of the electrodes/channels across the head:
cfg = [];
cfg.channel = {'all'};
cfg.frequency = [0.2 45]; % can look at the whole spectrum (0.2-100Hz) or zoom in!
cfg.avgoverchan = 'yes'; % averaging the powspecs of multiple channels!
wholeHeadPowSpec = ft_selectdata(cfg, allFrequencyFFT);

%%%% calculating bandpower PER EPOCH using rectangle estimates on the powspec:
%delta:
output{1,1} = bandpower(wholeHeadPowSpec.powspctrm, wholeHeadPowSpec.freq, [0.5 4], 'psd'); % - POWER estimate
%theta:
output{1,2} = bandpower(wholeHeadPowSpec.powspctrm, wholeHeadPowSpec.freq, [4 7], 'psd'); % - POWER estimate
%alpha:
output{1,3} = bandpower(wholeHeadPowSpec.powspctrm, wholeHeadPowSpec.freq, [8 12], 'psd'); % - POWER estimate
%beta:
output{1,4} = bandpower(wholeHeadPowSpec.powspctrm, wholeHeadPowSpec.freq, [13 30], 'psd'); % - POWER estimate
%gamma:
output{1,5} = bandpower(wholeHeadPowSpec.powspctrm, wholeHeadPowSpec.freq, [30 45], 'psd'); % - POWER estimate

% outputting the results of these calculations:
output

%% THE AVERAGING VARIABLE:

% here, for every epoch put into this pipeline, you must individually add
% it to this averaging variable. this variable thus stores the power
% spectra of every epoch, and will later allow for the production of
% epoch-averaged power spectra.

toAvgPostExp20HzTrial = vertcat(toAvgPostExp20HzTrial, wholeHeadPowSpec); % for grand average
toPlotPostExp20HzTrial = vertcat(toPlotPostExp20HzTrial, wholeHeadPowSpec.powspctrm); % for plotting

% NB:
% to erase a line, check the workspace for the number of the row you'll
% delete (if ur deleting the last row, the number is the matrix height).
% CHANGE THE averaging variable as applicable:
toAvgPostExp20HzTrial{3,:} = []; % for grand average
toAvgPostExp20HzTrial = toAvgPostExp20HzTrial(~cellfun(@isempty, toAvgPostExp20HzTrial));
toPlotPostExp20HzTrial(3,:) = []; % for plotting


% now go onto the next epoch and go back to loading your epoch in!

%% Now, using the averaging variable, you sum all of the power spectra to create a grand average:
% once you've added all of your epoch power spectra to the matrix, grand
% average them using the below code:
cfg = [];
cfg.parameter = 'powspctrm';
postExp20HzGrandAvg = ft_freqgrandaverage(cfg, toAvgPostExp20HzTrial{:,1});

%% you should save this variable as it took quite a while to make.
% you can then load it later if anything goes wrong.

cd '/Volumes/VICTORPROJ/FHS_2021_Michaelmas/Pt_10_11' %changes the current folder
save('AffectiveFallsRun.mat', 'postExp20HzGrandAvg');


%%  PLOTTING:

% plotting all the pow spec of all trials, with an AVG powspec on top:
figure;
hold on;
plot(postExp20HzGrandAvg.freq, cell2mat(toPlotPostExp20HzTrial(:,1)), 'color', [0,0,0]+0.65, 'LineWidth', 1); %plots all the powpsctrm data in the row of the specified electrode
h2 = plot(postExp20HzGrandAvg.freq, postExp20HzGrandAvg.powspctrm, 'k', 'LineWidth', 2.5);
legend(h2, 'AVG power spectrum');
xlabel('Frequency (Hz)');
ylabel('Power spectral density (uV^2/Hz)');













%% Script PART 2

% This section works just like the first, but instead produces
% epoch-averaged topoplots.




%% Topoplots

%%%% first gotta make the time-freq data in preparation for the freq
%%%% analyses, in anticipation of the topoplots . 

% load in your first topo epoch here:
cfg = []; 
cd '/Volumes/VICTORPROJ/FHS_2021_Michaelmas/Pt_10_11'
cfg.dataset = '101121_Rec1_PainDRG - 20211110T110216.DATA.Poly5'; % the only line to change per patient. occurs twice in this script
cfg.channel = {'ExG1', 'ExG2', 'ExG3', 'ExG4', 'ExG5', 'ExG6', 'ExG7', 'ExG8', 'ExG9', 'ExG10', 'ExG11', 'ExG12', 'ExG13', 'ExG14', 'ExG15', 'ExG16', 'ExG17', 'ExG18', 'ExG19', 'ExG20', 'ExG21', 'ExG22', 'ExG23'};
% specify epoch:
numOfSecs2 = 5647;
cfg.trl = [(numOfSecs2)*2048 (numOfSecs2+10)*2048 0];
toTopoRawData = ft_preprocessing(cfg);
tempElectrodes(1,:) = {'Fp1', 'Fpz', 'Fp2', 'F7', 'F3', 'Fz', 'F4', 'F8', 'M1', 'T7', 'C3', 'Cz', 'C4', 'T8', 'M2', 'P7', 'P3', 'Pz', 'P4', 'P8', 'O1', 'Oz', 'O2'};
toTopoRawData.label = tempElectrodes';
cfg = [];
cfg.demean     = 'yes';
cfg.detrend    = 'yes';
cfg.polyremoval = 'yes';
cfg.polyorder = 1;
toTopoDetrendedData = ft_preprocessing(cfg,toTopoRawData);
cfg = [];
cfg.hpfilter = 'yes' ; 
cfg.hpfreq = 0.2;
cfg.hpfiltord = 3;
cfg.lpfilter = 'yes';
cfg.lpfreq = 180;
cfg.bsfilter = 'yes';
cfg.bsfreq = [49 51; 99 100; 149 151];
toTopoFilteredData = ft_preprocessing(cfg, toTopoDetrendedData);
toTopoPreprocData = toTopoFilteredData;
cfg = [];
cfg.channel = badChannels2; % channels to remove (and keep)
toTopoPreprocData = ft_selectdata(cfg, toTopoPreprocData);



% now create the TFR for the relevant band, before saving the result into
% an averaging variable.

%time-freq data for delta:
cfg = [];
cfg.hpfilter = 'yes' ; 
cfg.hpfreq = 0.1;
cfg.hpfiltord = 3;
cfg.lpfilter = 'yes';
cfg.lpfreq = 4;
cfg.bsfilter = 'yes';
cfg.bsfreq = [49 51; 99 100; 149 151];
deltaData = ft_preprocessing(cfg, toTopoPreprocData);
cfg = [];
cfg.method = 'mtmconvol';
cfg.output = 'pow';
cfg.taper = 'hanning';
cfg.foi = [0.5:0.035:4]; % analysing 0.1 to 4 Hz in 100 steps. !! 0.1 gave an error when plotting
cfg.t_ftimwin = 7./cfg.foi; % setting up window length such that there are 7 cycles of each freq
cfg.tapsmofrq = 1; % the amount of spectral smoothing on the tapers. 1Hz is fine
cfg.toi = 0:0.00244141:5; % time window slides in steps of 0.0024s (5s divided by 2048 sampling rate)
% also note that cfg.toi is the line to modify if you want to move along
% the epoch.
deltaTFRhann = ft_freqanalysis(cfg, deltaData);

%time-freq data for theta:
cfg = [];
cfg.hpfilter = 'yes' ; 
cfg.hpfreq = 4;
cfg.hpfiltord = 3;
cfg.lpfilter = 'yes';
cfg.lpfreq = 7;
cfg.bsfilter = 'yes';
cfg.bsfreq = [49 51; 99 100; 149 151];
thetaData = ft_preprocessing(cfg, toTopoPreprocData);
cfg = [];
cfg.method = 'mtmconvol';
cfg.output = 'pow';
cfg.taper = 'hanning';
cfg.foi = [4:0.03:7]; % 4 to 7 in 100 steps
cfg.t_ftimwin = 7./cfg.foi; % setting up window length such that there are 7 cycles of each freq
cfg.tapsmofrq = 1; % the amount of spectral smoothing on the tapers
cfg.toi = 0:0.00244141:5; % time window slides in steps of 0.0024s (5s divided by 2048 sampling rate)
thetaTFRhann = ft_freqanalysis(cfg, thetaData);

%time-freq data for alpha:
cfg = [];
cfg.hpfilter = 'yes' ; 
cfg.hpfreq = 8;
cfg.hpfiltord = 3;
cfg.lpfilter = 'yes';
cfg.lpfreq = 12;
cfg.bsfilter = 'yes';
cfg.bsfreq = [49 51; 99 100; 149 151];
alphaData = ft_preprocessing(cfg, toTopoPreprocData);
cfg = [];
cfg.method = 'mtmconvol';
cfg.output = 'pow';
cfg.taper = 'hanning';
cfg.foi = [8:0.04:12]; 
cfg.t_ftimwin = 7./cfg.foi; % setting up window length such that there are 7 cycles of each freq
cfg.tapsmofrq = 1; % the amount of spectral smoothing on the tapers
cfg.toi = 0:0.00244141:5; % time window slides in steps of 0.0024s (5s divided by 2048 sampling rate)
alphaTFRhann = ft_freqanalysis(cfg, alphaData);

%time-freq data for beta:
cfg = [];
cfg.hpfilter = 'yes' ; 
cfg.hpfreq = 13;
cfg.hpfiltord = 3;
cfg.lpfilter = 'yes';
cfg.lpfreq = 30;
cfg.bsfilter = 'yes';
cfg.bsfreq = [49 51; 99 100; 149 151];
betaData = ft_preprocessing(cfg, toTopoPreprocData);
cfg = [];
cfg.method = 'mtmconvol';
cfg.output = 'pow';
cfg.taper = 'hanning';
cfg.foi = [13:0.17:30]; 
cfg.t_ftimwin = 7./cfg.foi; % setting up window length such that there are 7 cycles of each freq
cfg.tapsmofrq = 1; % the amount of spectral smoothing on the tapers
cfg.toi = 0:0.00244141:5; % time window slides in steps of 0.0024s (5s divided by 2048 sampling rate)
betaTFRhann = ft_freqanalysis(cfg, betaData);

%time-freq data for gamma:
cfg = [];
cfg.hpfilter = 'yes' ; 
cfg.hpfreq = 30;
cfg.hpfiltord = 3;
cfg.lpfilter = 'yes';
cfg.lpfreq = 100;
cfg.bsfilter = 'yes';
cfg.bsfreq = [49 51; 99 100; 149 151];
gammaData = ft_preprocessing(cfg, toTopoPreprocData);
cfg = [];
cfg.method = 'mtmconvol';
cfg.output = 'pow';
cfg.taper = 'hanning';
cfg.foi = [30:0.7:45];
cfg.t_ftimwin = 7./cfg.foi; % setting up window length such that there are 7 cycles of each freq
cfg.tapsmofrq = 1; % the amount of spectral smoothing on the tapers
cfg.toi = 0:0.00244141:5; % time window slides in steps of 0.0024s (5s divided by 2048 sampling rate)
gammaTFRhann = ft_freqanalysis(cfg, gammaData);




%% AVERAGING VARIABLE:


% first, create your averaging variables. this time, you need one per frequency
% band.
postExp20HzDeltaTopoTrials = {}; postExp20HzThetaTopoTrials = {}; postExp20HzAlphaTopoTrials = {}; postExp20HzBetaTopoTrials = {}; postExp20HzGammaTopoTrials = {}; 
% this line^ should only be run once - all it does it create the averaging
% variable!

% now this is where, for each epoch, you add your time-freq data to the
% averaging variable:
postExp20HzDeltaTopoTrials = vertcat(postExp20HzDeltaTopoTrials, deltaTFRhann);
postExp20HzThetaTopoTrials = vertcat(postExp20HzThetaTopoTrials, thetaTFRhann);
postExp20HzAlphaTopoTrials = vertcat(postExp20HzAlphaTopoTrials, alphaTFRhann);
postExp20HzBetaTopoTrials = vertcat(postExp20HzBetaTopoTrials, betaTFRhann);
postExp20HzGammaTopoTrials = vertcat(postExp20HzGammaTopoTrials, gammaTFRhann);


% now go onto next epoch and back up to loading in your topo epoch!

%% if you need to delete some entries:
% to erase a line, check the workspace for the number of the row you'll
% delete (if ur deleting the last row, the number is the matrix height).
% CHANGE THE averaging variable as applicable:

trialToDelete = 32;
postExp20HzDeltaTopoTrials{trialToDelete,:} = []; 
postExp20HzDeltaTopoTrials = postExp20HzDeltaTopoTrials(~cellfun(@isempty, postExp20HzDeltaTopoTrials));
postExp20HzThetaTopoTrials{trialToDelete,:} = []; 
postExp20HzThetaTopoTrials = postExp20HzThetaTopoTrials(~cellfun(@isempty, postExp20HzThetaTopoTrials));
postExp20HzAlphaTopoTrials{trialToDelete,:} = []; 
postExp20HzAlphaTopoTrials = postExp20HzAlphaTopoTrials(~cellfun(@isempty, postExp20HzAlphaTopoTrials));
postExp20HzBetaTopoTrials{trialToDelete,:} = []; 
postExp20HzBetaTopoTrials = postExp20HzBetaTopoTrials(~cellfun(@isempty, postExp20HzBetaTopoTrials));
postExp20HzGammaTopoTrials{trialToDelete,:} = []; 
postExp20HzGammaTopoTrials = postExp20HzGammaTopoTrials(~cellfun(@isempty, postExp20HzGammaTopoTrials));


%% once you've gone through all of your epochs:

% calculate the your epoch-averaged topoplot in each band!

    cfg = [];
    postExp20HzDeltaTopoAvg = ft_freqgrandaverage(cfg, postExp20HzDeltaTopoTrials{:,1});
    cfg = [];
    postExp20HzThetaTopoAvg = ft_freqgrandaverage(cfg, postExp20HzThetaTopoTrials{:,1});
    cfg = [];
    postExp20HzAlphaTopoAvg = ft_freqgrandaverage(cfg, postExp20HzAlphaTopoTrials{:,1});
    cfg = [];
    postExp20HzBetaTopoAvg = ft_freqgrandaverage(cfg, postExp20HzBetaTopoTrials{:,1});
    cfg = [];
    postExp20HzGammaTopoAvg = ft_freqgrandaverage(cfg, postExp20HzGammaTopoTrials{:,1});
    
    
%% saving some stuff:

% again, should probably save some stuff as this took a while to make

%% PLOTTING the average topoplot in your specified band:

    % delta:
    cfg = [];
    cfg.marker       = 'on';
    cfg.colorbar     = 'yes';
    layout_perf1020.label(1:23,1) = {'Fp1'; 'Fpz'; 'Fp2'; 'F7'; 'F3'; 'Fz'; 'F4'; 'F8'; 'M1'; 'T7'; 'C3'; 'Cz'; 'C4'; 'T8'; 'M2'; 'P7'; 'P3'; 'Pz'; 'P4'; 'P8'; 'O1'; 'Oz'; 'O2'};
    cfg.layout       = layout_perf1020;
    figure
    ft_topoplotTFR(cfg, postExp20HzDeltaTopoAvg);
    title('Delta Topoplot');
    % theta:
    cfg = [];
    cfg.marker       = 'on';
    cfg.colorbar     = 'yes';
    layout_perf1020.label(1:23,1) = {'Fp1'; 'Fpz'; 'Fp2'; 'F7'; 'F3'; 'Fz'; 'F4'; 'F8'; 'M1'; 'T7'; 'C3'; 'Cz'; 'C4'; 'T8'; 'M2'; 'P7'; 'P3'; 'Pz'; 'P4'; 'P8'; 'O1'; 'Oz'; 'O2'};
    cfg.layout       = layout_perf1020;
    figure
    ft_topoplotTFR(cfg, postExp20HzThetaTopoAvg);
    title('Theta Topoplot');
    % alpha:
    cfg = [];
    cfg.marker       = 'on';
    cfg.colorbar     = 'yes';
    layout_perf1020.label(1:23,1) = {'Fp1'; 'Fpz'; 'Fp2'; 'F7'; 'F3'; 'Fz'; 'F4'; 'F8'; 'M1'; 'T7'; 'C3'; 'Cz'; 'C4'; 'T8'; 'M2'; 'P7'; 'P3'; 'Pz'; 'P4'; 'P8'; 'O1'; 'Oz'; 'O2'};
    cfg.layout       = layout_perf1020;
    figure
    ft_topoplotTFR(cfg, postExp20HzAlphaTopoAvg);
    title('Alpha Topoplot');
    % beta:
    cfg = [];
    cfg.marker       = 'on';
    cfg.colorbar     = 'yes';
    layout_perf1020.label(1:23,1) = {'Fp1'; 'Fpz'; 'Fp2'; 'F7'; 'F3'; 'Fz'; 'F4'; 'F8'; 'M1'; 'T7'; 'C3'; 'Cz'; 'C4'; 'T8'; 'M2'; 'P7'; 'P3'; 'Pz'; 'P4'; 'P8'; 'O1'; 'Oz'; 'O2'};
    cfg.layout       = layout_perf1020;
    figure
    ft_topoplotTFR(cfg, postExp20HzBetaTopoAvg);
    title('Beta Topoplot');
    % gamma:
    cfg = [];
    cfg.marker       = 'on';
    cfg.colorbar     = 'yes';
    layout_perf1020.label(1:23,1) = {'Fp1'; 'Fpz'; 'Fp2'; 'F7'; 'F3'; 'Fz'; 'F4'; 'F8'; 'M1'; 'T7'; 'C3'; 'Cz'; 'C4'; 'T8'; 'M2'; 'P7'; 'P3'; 'Pz'; 'P4'; 'P8'; 'O1'; 'Oz'; 'O2'};
    cfg.layout       = layout_perf1020;
    figure
    ft_topoplotTFR(cfg, postExp20HzGammaTopoAvg);
    title('Gamma Topoplot');


% change ft_topoplot to ft_singleplotTFR to plot TFRs if you like

