function [optimalTimeWindow, GFP_perTrial, maxAUC, AUC] = calculateGFP_withROC(EEG, Epoch_Events, condLabel, Epoch_labels, trialIndexCond, filePath)
    %% Calculate GFP per time point and find optimal window using ROC
        % Set up file saving and labels
    condIndx = strmatch(condLabel, Epoch_labels, "exact");
    eventCell = Epoch_Events{condIndx};

    switch condLabel
        case 'Attended'
            report = trialIndexCond.AttendedReport;
            savingFile_GFP = fullfile(filePath, "GFP_A.mat");
            savingFile = fullfile(filePath, "High_Perception_TimeRange_A.mat");
        case 'Unattended'
            report = trialIndexCond.UnAttendedReport;
            savingFile_GFP = fullfile(filePath, "GFP_U.mat");
            savingFile = fullfile(filePath, "High_Perception_TimeRange_U.mat");
        case 'Attended left'
            report = trialIndexCond.LAttendedReport;
            savingFile_GFP = fullfile(filePath, "GFP_AL.mat");
            savingFile = fullfile(filePath, "High_Perception_TimeRange_AL.mat");
        case 'Unattended left'
            report = trialIndexCond.RAttendedReport;
            savingFile_GFP = fullfile(filePath, "GFP_UL.mat");
            savingFile = fullfile(filePath, "High_Perception_TimeRange_UL.mat");
        case 'Attended right'
            report = trialIndexCond.LUnAttendedReport;
            savingFile_GFP = fullfile(filePath, "GFP_AR.mat");
            savingFile = fullfile(filePath, "High_Perception_TimeRange_AR.mat");
        case 'Unattended right'
            report = trialIndexCond.RUnAttendedReport;
            savingFile_GFP = fullfile(filePath, "GFP_UR.mat");
            savingFile = fullfile(filePath, "High_Perception_TimeRange_UR.mat");
        otherwise
            error('Unknown condition label: %s', condLabel);
    end

    % Define hit/miss labels (0 = miss, 1 = hit)
    hitMissLabels = zeros(EEG.trials, 1);
    hitMissLabels(report == 1) = 1;

    resultDir = fullfile(filePath, 'GFP_Analysis'); 
    if ~isdir(resultDir) 
        mkdir(resultDir) 
    end 
    
    % Calculate GFP per time point per trial
    nTrials = EEG.trials;
    nTimePoints = size(EEG.data, 2);
    nChannels = EEG.nbchan;
    
    % GFP = standard deviation across electrodes for each time point and trial
    GFP_perTrial = zeros(nTimePoints, nTrials);
    
    for trial = 1:nTrials
        for timePoint = 1:nTimePoints
            % GFP is SD of ERP across all electrodes at each time point
            GFP_perTrial(timePoint, trial) = std(EEG.data(:, timePoint, trial));
        end
    end
    
    % Find optimal time window using ROC analysis
    % Separate trials into hits and misses (you need to define this based on your behavioral data)
    % For now, assuming you have hit/miss labels
    
    timeVector = EEG.times; % Time vector in ms
    poststimIndices = find(timeVector > 0); % Poststimulus period
    
    % ROC analysis to find optimal time window
    maxAUC = 0;
    optimalTimeWindow = [];    
    for t = poststimIndices
%        Calculate AUC for discriminating hits vs misses using GFP
%        This requires behavioral data - implement based on your experiment
        [X, Y, T, AUC] = perfcurve(hitMissLabels, GFP_perTrial(t, :), 1);        
        if AUC > maxAUC
            maxAUC = AUC;
            optimalTimeWindow = t;
        end
    end

    AUC_Arr = [];
    for t = 1 : length(timeVector)
%        Calculate AUC for discriminating hits vs misses using GFP
%        This requires behavioral data - implement based on your experiment
        [X, Y, T, AUC] = perfcurve(hitMissLabels, GFP_perTrial(t, :), 1);
        AUC_Arr = [AUC_Arr, AUC];
        if AUC > maxAUC
            maxAUC = AUC;
            optimalTimeWindow = t;
        end
    end

    % Save results
    saveGFP = fullfile(resultDir, [condLabel, '_GFP_perTrial.mat']);
    save(saveGFP, 'GFP_perTrial', 'timeVector', 'optimalTimeWindow', 'AUC_Arr');
end