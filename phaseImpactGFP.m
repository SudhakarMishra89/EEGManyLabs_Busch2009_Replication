function [saveArr] = phaseImpactGFP(EEG, filePath, time_freq_Point, name, selectedElectrodes, trialIndexCond, sub_N, resDir)

    %EEG_A, fullfile(subDir, 'tf'), trials_.A, time_freq_Point, 'Attended', frontoCentral, trialIndexCond)
   
    if strmatch({name}, 'Attended', 'exact')
        report = trialIndexCond.AttendedReport;
    elseif strmatch({name}, 'Unattended', 'exact')
        report = trialIndexCond.UnAttendedReport;
    elseif strmatch({name}, 'Attended left', 'exact')
        report = trialIndexCond.LAttendedReport;
    elseif strmatch({name}, 'Unattended left', 'exact')
        report = trialIndexCond.RAttendedReport;
    elseif strmatch({name}, 'Attended right', 'exact')
        report = trialIndexCond.LUnAttendedReport;
    elseif strmatch({name}, 'Unattended right', 'exact')
        report = trialIndexCond.RUnAttendedReport;
    end

    if EEG.trials ~= length(report)
        error('Number of trials mismatch')
    end
    minfreq = 2;
    maxfreq = 50;
    frequencies = [minfreq maxfreq];
    cycles = [2 8];
    freqscale = 'linear';
    timesout = [-0.800:0.004:0.800];
    nfreqs = 100;  

    % Assessing the magnitude of the attention effect on Prestimulus phase
    % Optimal time-frequency point: -224 ms, 7.1 Hz    
    % The exact impact of prestimulus phase on 
    load(fullfile(filePath, [name, '_TFInfo.mat']));
    %FInd = find(TFInfo.freqs>7 & TFInfo.freqs<7.5);
    [~, FInd] = min(abs(TFInfo.freqs-time_freq_Point(2)));
    [~, TInd] = min(abs(TFInfo.times-time_freq_Point(1)));
    noBins = 11;
    angleDist = [-3.14:(6.28/noBins):3.14]; %corners of the bins
    trials = zeros(noBins, EEG.trials);
    %angles = zeros(600,1);

    %% Averaging channel data first before doing the trial binning based on phase.
    %chanAvgData = squeeze(mean(EEG.data,1));
    %[tf_, outfreqs, outtimes] = timefreq(chanAvgData, EEG.srate, 'cycles', cycles, 'tlimits', ...
    %    [EEG.xmin EEG.xmax], 'timesout', timesout, 'wletmethod', 'dftfilt3', 'freqs', frequencies, ...
    %    'freqscale', freqscale, 'nfreqs', nfreqs); 
    %angles = squeeze(angle(tf_(FInd, TInd, :)));
    %% Averaging angles by calculating circular mean across channels (fronto-central channels) first and then doing the binning of trials
    angleArray = [];
    chanConsid = [];
    for chanId = 1:length(selectedElectrodes)
        chanNo = find(strcmp(selectedElectrodes{chanId}, {EEG.chanlocs.labels}));
        chanConsid(chanId) = chanNo;
        ang = load(fullfile(filePath, [name, '_TF_', num2str(chanNo), '.mat']));
        if chanId == 1
            angleArray = angle(squeeze(ang.tf(FInd, TInd, :)))';
        else
            angleArray = [angleArray ; angle(squeeze(ang.tf(FInd, TInd, :)))'];
        end        
    end
    chanConsid = sort(chanConsid);
    Avg_angles = circ_mean(angleArray);
    [N,edges,bin] = histcounts(Avg_angles, angleDist);
    GFPAmp = [];
    
    postStimSamples = fix(1300 * (EEG.srate/1000)); %Q. 1.3 second from starting (not stimulus onset) I have taken random here. Where in the post-stimulus window should I do selection for the GFP calculation
    % poststimulus I am taking 100 ms (as per the ROC based analysis depicted in fig. 3 of the main article. Because for the trial pooling analysis the poststimulus duration is not mentioned anywhere in the text)
    % Taking 50 ms window for the GFP.
    hit_R = [];
    for bin_ = 1 : noBins
        binIndexes = find(bin==bin_);

        %% Read the GFP value which came out of AUC where GFP was calculated
        % for all channels
        ERP_Selected_Trials = mean(EEG.data(chanConsid, postStimSamples:(postStimSamples+25), find(bin==bin_)),3);
        GFP_ = mean(std(ERP_Selected_Trials));
        Avg_GFP = mean(GFP_);
        GFPAmp(bin_) = Avg_GFP; % std across channels then mean of GFP values across signal and across trials.
        %%
        % Hit Rate:
        hit_R(bin_) = sum(report(binIndexes)==1)/length(binIndexes);
        %trials(bin_, find(angles>centers(bin_) & angles<centers(bin_+1))) = 1;
        %find(counts(bin_,:))) = trials(bin_, find(counts(bin_,:))) + 1;
    end

    binCenters = [];
    for i = 1 : noBins
        binCenters = [binCenters, (edges(i)+edges(i+1))/2];
    end
    
    [maxV, maxI] = max(GFPAmp);    
    alignedPhase = binCenters - binCenters(maxI);
    
    % Recalculate the angle value if they are beyond the -pi or pi.
    % Subtract them from 2*pi.
    for p=1:length(alignedPhase)
        if  alignedPhase(p)>3.14
            alignedPhase(p)=6.28-alignedPhase(p);
        elseif alignedPhase(p)<-3.14
            alignedPhase(p)=alignedPhase(p)+6.28;
        end
    end    
    NbinCenters = circshift(alignedPhase, 6-maxI);
    hit_R = circshift(hit_R, (6-maxI));
    hit_R = hit_R/mean(hit_R);
    GFPAmp_CS = circshift(GFPAmp, (6-maxI));
    GFPAmp_CS = GFPAmp_CS/mean(GFPAmp_CS);
    
    %% Calculate phase x attention interaction    
    saveArr = [GFPAmp_CS;hit_R;NbinCenters];
    save(fullfile(resDir, [sub_N, '_', name, '.mat']), 'saveArr')
    mean(GFPAmp)
    mean(hit_R)
end