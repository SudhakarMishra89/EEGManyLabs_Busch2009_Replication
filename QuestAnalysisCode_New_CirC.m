% EEGLAB history file generated on the 20-Apr-2023
% ------------------------------------------------
% Trigger Value 	Function
%         1	    START new block (Before pressing Enter)
%         2	    Post Flash Response Trigger     % Percieved
%         3	    Fixation Cross (Cue = 1; Flash = 0)
%         4	    Cue = 1; Flash = 1              % Attended left
%         5	    Cue = 1; Flash = 2              % Unattended left
%         6	    Fixation Cross (Cue = 2; Flash = 0)
%         7	    Cue = 2; Flash = 1              % Unattended right
%         8	    Cue = 2; Flash = 2              % attended right
%         9	    Cue = 1
%         10	Cue = 2
%         11	No Flash Reported               % Not Percieved
%         12	End of the Block

clc
clear all
close all

addpath('/home/cgswsn/Downloads/Niko Replication Study/eeglab2019_2_this')
filePath = '/home/cgswsn/Downloads/Niko Replication Study/Data';
prestimulus_Window = [-600 -200]; %[prestimulus_Window[1] -800]

circularCorr = 0; % 1 mean to do.
%behavPath = '/home/cgswsn/ReplicationStudy/Analysis Code_Old/Data/BehavioralData';
%filePath = '/home/cgswsn/ReplicationStudy/Analysis Code_Old/Data/ERP Check CRT';

frontoCentral = {'FC5', 'FC1', 'FC2', 'FC6', 'FC3', 'FC4'};
Posterior_Parietal = {'C1', 'Cz', 'C2', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4', 'P3', 'P1', 'Pz', 'P2', 'P4', 'PO3', 'POz', 'PO4'};
Epoch_labels = {'Hits', 'Miss', 'Attended', 'Unattended', 'Attended left', 'Unattended left', 'Attended right', 'Unattended right','Attended hits', 'Attended miss', 'Unattended hits', 'Unattended miss'};
Epoch_Events = {{'S  2'}, {'S 11'}, {'S  4', 'S  8'}, {'S  5', 'S  7'}, {'S  4'}, {'S  5'}, {'S  8'}, {'S  7'}, ...
    {'S  4', 'S  8', 'S  2'}, {'S  4', 'S  8', 'S 11'}, {'S  5', 'S  7', 'S  2'}, {'S  5', 'S  7', 'S 11'}};
%{'S  2', 'S  3', 'S  4', 'S  5', 'S  6', 'S  7', 'S  8', 'S 11'}
Omit_Events = {{'S 11'}, {'S  2'}, {}, {}, {'S 11'}, {'S  2'}, {'S 11'}, {'S  2'}};

subjects = dir(fullfile(filePath, "pilot*"));
for sub_ = 1 : length(subjects)
    display(subjects(sub_).name)
    subDir = fullfile(filePath, subjects(sub_).name);
    fileName = dir(fullfile(subDir, "*.vhdr"));
    fileName = fileName.name;
    %%
    % Extracting indexes from Behavioural Data
    behavDataFold = dir(fullfile(filePath, [subjects(sub_).name '*']));
    behavDataFold = fullfile(behavDataFold.folder, behavDataFold.name);
    BehLogFile = dir(fullfile(behavDataFold, '*.log'));
    logFile = tdfread(fullfile(behavDataFold, BehLogFile(1).name));
    stimResIndex = sort([find(logFile.Flash==1)' find(logFile.Flash==2)']);
    validIndex = find(logFile.Valid==1);
    LvalidIndex = find((logFile.Valid==1) & (logFile.Cue==1));
    RvalidIndex = find((logFile.Valid==1) & (logFile.Cue==2));
    InvalidIndex = find(logFile.Valid==2);
    LInvalidIndex = find((logFile.Valid==2) & (logFile.Cue==1));
    RInvalidIndex = find((logFile.Valid==2) & (logFile.Cue==2));    
    reportFlash = logFile.Report(stimResIndex);

    AttendedReport = logFile.Report(validIndex);
    UnAttendedReport = logFile.Report(InvalidIndex);        
    LAttendedReport = logFile.Report(LvalidIndex);
    RAttendedReport = logFile.Report(RvalidIndex);
    LUnAttendedReport = logFile.Report(LInvalidIndex);
    RUnAttendedReport = logFile.Report(RInvalidIndex);
    trialIndexCond = struct;
    trialIndexCond.AttendedReport = AttendedReport;
    trialIndexCond.UnAttendedReport = UnAttendedReport; 
    trialIndexCond.LAttendedReport = LAttendedReport;
    trialIndexCond.RAttendedReport = RAttendedReport;
    trialIndexCond.LUnAttendedReport = LUnAttendedReport; 
    trialIndexCond.RUnAttendedReport = RUnAttendedReport;
    save(fullfile(behavDataFold, "trialIndexCond.mat"), 'trialIndexCond');

    %%
    % File names to save files at different stage of preprocessing    
    temp_ = strsplit(fileName, '.vhdr');    
    filterFile = ['PreProcessed_Downsampled_filtered_' temp_{1} '.set'];            % To save filtered data
    channelRejFile = ['PreProcessed_Downsampled_filtered_ChanRej_' temp_{1} '.set'];% To save data after bad channel rejections
    ICAFile = ['PreProcessed_Downsampled_filtered_ChanRej_ICA_' temp_{1} '.set'];   % To save data After ICA components calculations
    ICAClassFile = ['PreProcessed_Downsampled_filtered_ChanRej_ICAClass_' temp_{1} '.set'];% 
    ICARejFile = ['PreProcessed_Downsampled_filtered_ChanRej_ICAClass_ICARej_' temp_{1} '.set'];% To save data after ICA components rejection
    ICALabelFile = ['PreProcessed_Downsampled_filtered_ChanRej_ICAClass_ICALabel_' temp_{1} '.set'];% To save data afer ICA components' labeling
    ICALabelFileRej = ['PreProcessed_Downsampled_filtered_ChanRej_ICAClass_ICALabel_Rej' temp_{1} '.set'];
    FinalPreprocessed = ['PreProcessed_Downsampled_filtered_ChanRej_FinalPreProcessed' temp_{1} '.set'];% To save final preprocessed data
    %%
    % Following files will have pre-processed event extracted eeg data.
    EEG_A_File = ['EEG_A_' temp_{1} '.set'];    % Attended 
    EEG_AH_File = ['EEG_AH_' temp_{1} '.set'];  % Attended Hits
    EEG_AM_File = ['EEG_AM_' temp_{1} '.set'];  % Attended Miss
    EEG_U_File = ['EEG_U_' temp_{1} '.set'];    % Unattended Hits
    EEG_UH_File = ['EEG_UH_' temp_{1} '.set'];  % Unattended Hits
    EEG_UM_File = ['EEG_UM_' temp_{1} '.set'];  % Unattended Miss
    EEG_AL_File = ['EEG_AL_' temp_{1} '.set'];  % Attended Left
    EEG_ALH_File = ['EEG_ALH_' temp_{1} '.set'];% Attended Left Hits
    EEG_ALM_File = ['EEG_ALM_' temp_{1} '.set'];% Attended Left Miss
    EEG_UL_File = ['EEG_UL_' temp_{1} '.set'];  % Unattended Left 
    EEG_ULH_File = ['EEG_ULH_' temp_{1} '.set'];% Unattended Left Hits
    EEG_ULM_File = ['EEG_ULM_' temp_{1} '.set'];% Unattended Left Miss
    EEG_AR_File = ['EEG_AR_' temp_{1} '.set'];  % Attended Right
    EEG_ARH_File = ['EEG_ARH_' temp_{1} '.set'];% Attended Right Hits
    EEG_ARM_File = ['EEG_ARM_' temp_{1} '.set'];% Attended Right Miss
    EEG_UR_File = ['EEG_UR_' temp_{1} '.set'];  % Unattended Right
    EEG_URH_File = ['EEG_URH_' temp_{1} '.set'];% Unattended Right Hits
    EEG_URM_File = ['EEG_URM_' temp_{1} '.set'];% Unattended Right Miss
    %%

    %validTrial = 1;

    %%
    % Preprocessing steps started
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    if ~ isfile(fullfile(subDir, filterFile)) %don't filter again if filtered alrady    
        EEG = pop_loadbv(subDir, fileName, [],...
           [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 ...
           26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 ...
           49 50 51 52 53 54 55 56 57 58 59 60 61 62 63]);        
        EEG = eeg_checkset( EEG ); % Just checking the eeglab structure
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 ); % Catching the processed EEG structure. 
        EEG = eeg_checkset( EEG );
        %pop_eegplot( EEG, 1, 1, 1); 

        % Resampling to 500 Hz
        [EEG] = pop_resample(EEG, 500);    

        % Plotting Frequency Domain Signal
        Fs = EEG.srate;
        y = EEG.data(1, :);
        ydft = fft(y);
        ydft = 2*ydft(1:ceil((length(y)+1)/2));
        freq = 0:Fs/length(y):Fs/2;
        ydft = ydft/(2*length(freq));
        figure; plot(freq(5:end),abs(ydft(5:end))), xlabel('frequency [Hz]')
        
        % Performing Bandpass Filtering
        EEG = pop_eegfiltnew(EEG, 'locutoff', 0.16, 'hicutoff', 100);       
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
        % Frequency Domain Signal
        Fs = EEG.srate;
        y = EEG.data(1, :);
        ydft = fft(y);
        ydft = 2*ydft(1:ceil((length(y)+1)/2));
        freq = 0:Fs/length(y):Fs/2;
        ydft = ydft/(2*length(freq));
        figure; plot(freq(5:end),abs(ydft(5:end))), xlabel('frequency [Hz]')        
        pop_saveset(EEG, 'filename', filterFile, 'filepath', subDir);

    else %if already filtered, load the filtered file.
        % Loading Filtered Data
        EEG = pop_loadset('filename', filterFile, 'filepath', subDir);
        EEG = eeg_checkset(EEG);
    end
    
    %% Provided by Niko Busch: Instead of thresholding based cleaning we did component based rejection.
    % EEG Cleaning Based on Thresholding
    %EEG = eeg_detrend(EEG); % https://github.com/widmann/erptools/blob/master/eeg_detrend.m
    %threshold = 75; % I have commented it
    %EEG = pop_eegthresh(EEG, 1, 1:EEG.nbchan, -threshold, threshold, EEG.xmin, EEG.xmax, 1, 0);% I have commented it
    %%

    % ICA to remove eye and muscle noise instead of using thresholding
    if ~ isfile(fullfile(subDir, ICAFile))
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'interrupt','on');
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        pop_saveset(EEG, 'filename', ICAFile, 'filepath', subDir);
    else
        % Loading data with ICA components calculated
        EEG = pop_loadset('filename', ICAFile, 'filepath', subDir);
        EEG = eeg_checkset(EEG);
    end
    
    eeglab redraw;
    
    % Using ICALabel to detect the artifacts and remove them automatically.
    if ~ isfile(fullfile(subDir, ICALabelFile))
        EEG = pop_iclabel(EEG, 'Default');
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = eeg_checkset( EEG );
        pop_saveset(EEG, 'filename', ICALabelFile, 'filepath', subDir);
    else
        % Loading data with labelled components
        EEG = pop_loadset('filename', ICALabelFile, 'filepath', subDir);
        EEG = eeg_checkset(EEG);
    end
    % pop_viewprops( EEG, 0, [1:63], {'freqrange', [0.5 45]}, {}, 1, 'ICLabel' )
    
    % Eye, muscle and channel noise components to reject
    keepComp = [];
    rejComp = [];
    for icaI = 1 : length(EEG.etc.ic_classification.ICLabel.classifications)
        [maxV, maxI] = max(EEG.etc.ic_classification.ICLabel.classifications(icaI, :));
        if (maxI == 1 || maxI == 7)
            keepComp = [keepComp, icaI];
        else
            disp(maxI)
            rejComp = [rejComp, icaI];
        end
    end
    
    % Remove the components with artifacts and reconstruct the eeg signal.
    EEG = pop_subcomp(EEG, rejComp);     
    pop_saveset(EEG, 'filename', ICALabelFileRej, 'filepath', subDir);
    eeglab redraw;   
 
    % Average Re-referencing
    EEG = pop_reref(EEG, []);
    EEG = eeg_checkset( EEG );
    pop_saveset(EEG, 'filename', FinalPreprocessed, 'filepath', subDir);
    eeglab redraw; % To project the current EEG structure into the EEGLab window.
    %%%%%%%% Pre-Processing ends here %%%%%%%%%%
    %%    
    % Extracting Events   
    EEG_Original = EEG;
    % Selecting Posterior Parietal channels only 
    Posterior_Parietal_Index = [];
    for i = 1 : EEG.nbchan
        if any(strcmp(Posterior_Parietal, EEG.chanlocs(i).labels))
            Posterior_Parietal_Index = [Posterior_Parietal_Index, i];
        end
    end
    
    EEG_PostParietal = pop_select(EEG, 'channel', Posterior_Parietal_Index);

    %% Extract EEG for Different Conditions
    afterPCARej = fullfile(subDir, 'afterPCARej');
    if ~isdir(afterPCARej)
        mkdir(afterPCARej)
    end
    if ~ isfile(fullfile(afterPCARej, ['PostPariet_', EEG_AH_File]))
        EEG_A = pop_epoch( EEG_PostParietal, Epoch_Events{3}, [-1.2 0.9], 'epochinfo', 'yes');        
        EEG_U = pop_epoch( EEG_PostParietal, Epoch_Events{4}, [-1.2 0.9], 'epochinfo', 'yes');        
        
        attendHit = find(trialIndexCond.AttendedReport==1);
        attendMiss = find(trialIndexCond.AttendedReport==0);
        UnattendHit = find(trialIndexCond.UnAttendedReport==1);
        UnattendMiss = find(trialIndexCond.UnAttendedReport==0);

        EEG_AH = pop_select( EEG_A, 'trial', attendHit);
        EEG_AH = pop_rmbase( EEG_AH, prestimulus_Window); % Removing baseline
        EEG_AM = pop_select( EEG_A, 'trial', attendMiss);
        EEG_AM = pop_rmbase( EEG_AM, prestimulus_Window); % Removing baseline
        EEG_UH = pop_select( EEG_U, 'trial', UnattendHit);
        EEG_UH = pop_rmbase( EEG_UH, prestimulus_Window); % Removing baseline
        EEG_UM = pop_select( EEG_U, 'trial', UnattendMiss); 
        EEG_UM = pop_rmbase( EEG_UM, prestimulus_Window); % Removing baseline

        EEG_A = pop_rmbase( EEG_A, prestimulus_Window); % Removing baseline
        % Saving eeg data with attended, attended hits and attended miss events
        pop_saveset(EEG_A, 'filename', ['PostPariet_', EEG_A_File], 'filepath', fullfile(afterPCARej));
        pop_saveset(EEG_AH, 'filename', ['PostPariet_', EEG_AH_File], 'filepath', fullfile(afterPCARej))
        pop_saveset(EEG_AM, 'filename', ['PostPariet_', EEG_AM_File], 'filepath', fullfile(afterPCARej))

        EEG_U = pop_rmbase( EEG_U, prestimulus_Window); % Removing baseline
        % Saving eeg data with un-attended, un-attended hits and un-attended miss events
        pop_saveset(EEG_U, 'filename', ['PostPariet_', EEG_U_File], 'filepath', fullfile(afterPCARej))
        pop_saveset(EEG_UH, 'filename', ['PostPariet_', EEG_UH_File], 'filepath', fullfile(afterPCARej))
        pop_saveset(EEG_UM, 'filename', ['PostPariet_', EEG_UM_File], 'filepath', fullfile(afterPCARej))
    else        
        EEG_AH = pop_loadset('filename', ['PostPariet_', EEG_AH_File], 'filepath', fullfile(afterPCARej));
        EEG_AM = pop_loadset('filename', ['PostPariet_', EEG_AM_File], 'filepath', fullfile(afterPCARej));        
        EEG_UH = pop_loadset('filename', ['PostPariet_', EEG_UH_File], 'filepath', fullfile(afterPCARej));
        EEG_UM = pop_loadset('filename', ['PostPariet_', EEG_UM_File], 'filepath', fullfile(afterPCARej));
    end
    %% ERP Study
    % [STUDY ALLEEG] = ERPAnalysis(1);
    % Here I have to save all the condition related EEG data structure in ALLEEG.
%     [EEG ALLEEG CURRENTSET] = eeg_retrieve(ALLEEG,1);
%     [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
%      [STUDY ALLEEG] = std_editset( STUDY, ALLEEG, 'name','ERP_Conditions','updatedat','off', ...
%          'commands',{ ...
%          {'index' 1 'load' 'D:\EEGManyLabs\Data\Pilot-sub-02\afterPCARej\EEG_AH_Pilot-02.set' 'subject' 'S01' 'condition' 'AH'} ...
%          {'index' 2 'load' 'D:\EEGManyLabs\Data\Pilot-sub-02\afterPCARej\EEG_AM_Pilot-02.set' 'subject' 'S01' 'condition' 'AM'} ...
%          {'index' 3 'load' 'D:\EEGManyLabs\Data\Pilot-sub-02\afterPCARej\EEG_UH_Pilot-02.set' 'subject' 'S01' 'condition' 'UH'} ...
%          {'index' 4 'load' 'D:\EEGManyLabs\Data\Pilot-sub-02\afterPCARej\EEG_UM_Pilot-02.set' 'subject' 'S01' 'condition' 'UM'} ...
%          {'index' 5 'load' 'D:\EEGManyLabs\Data\pilot01_7th_nov_after_resize\afterPCARej\EEG_AH_pilot01_7th_nov_after_resize.set' 'subject' 'S02' 'condition' 'AH'} ...
%          {'index' 6 'load' 'D:\EEGManyLabs\Data\pilot01_7th_nov_after_resize\afterPCARej\EEG_AM_pilot01_7th_nov_after_resize.set' 'subject' 'S02' 'condition' 'AM'} ...
%          {'index' 7 'load' 'D:\EEGManyLabs\Data\pilot01_7th_nov_after_resize\afterPCARej\EEG_UH_pilot01_7th_nov_after_resize.set' 'subject' 'S02' 'condition' 'UH'} ...
%          {'index' 8 'load' 'D:\EEGManyLabs\Data\pilot01_7th_nov_after_resize\afterPCARej\EEG_UM_pilot01_7th_nov_after_resize.set' 'subject' 'S02' 'condition' 'UM'}} );
% 
%     [STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, 'channels', 'interp', 'on', 'recompute','on','erp','on');
%     tmpchanlocs = ALLEEG(1).chanlocs; STUDY = std_erpplot(STUDY, ALLEEG, 'channels', { tmpchanlocs.labels }, 'plotconditions', 'together');
%     % 
%     STUDY = pop_erpparams(STUDY, 'timerange',[-200 800] ,'averagechan','on');
%     STUDY = std_erpplot(STUDY,ALLEEG,'channels',{'CP1' 'Pz' 'P3' 'P4' 'CP2' 'Cz' 'C1' 'CP3' 'P1' 'PO3' 'POz' 'PO4' 'P2' 'CPz' 'CP4' 'C2'}, 'design', 1);
%     STUDY = std_erpplot(STUDY,ALLEEG,'channels',{'CP1' 'Pz' 'P3' 'P4' 'CP2' 'Cz' 'C1' 'CP3' 'P1' 'PO3' 'POz' 'PO4' 'P2' 'CPz' 'CP4' 'C2'}, 'plotsubjects', 'on', 'design', 1 );
%     STUDY = pop_erpparams(STUDY, 'plotconditions','together');
%     STUDY = std_erpplot(STUDY,ALLEEG,'channels',{'CP1' 'Pz' 'P3' 'P4' 'CP2' 'Cz' 'C1' 'CP3' 'P1' 'PO3' 'POz' 'PO4' 'P2' 'CPz' 'CP4' 'C2'}, 'design', 1);
%     CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
    % eeglab redraw;
    
    %% ROC Analysis to get the time-window of maximum AUC
    % ROC analysis and calculation of correlation between phase angle and 
    % GFP should be done for 4 experimental conditions and for all channels     

    conditions = fullfile(subDir, 'Conditions');
    if ~isdir(conditions)
        mkdir(conditions)
    end

    EEG_A = pop_epoch( EEG_Original, Epoch_Events{3}, [-1.2 0.9], 'epochinfo', 'yes');    
    EEG_A = pop_rmbase( EEG_A, prestimulus_Window);
    EEG_AH = pop_select( EEG_A, 'trial', find(trialIndexCond.AttendedReport==1));
    EEG_AM = pop_select( EEG_A, 'trial', find(trialIndexCond.AttendedReport==0));
    pop_saveset(EEG_A, 'filename', EEG_A_File, 'filepath', conditions);
    pop_saveset(EEG_AH, 'filename', EEG_AH_File, 'filepath', conditions);
    pop_saveset(EEG_AM, 'filename', EEG_AM_File, 'filepath', conditions);

    EEG_U = pop_epoch( EEG_Original, Epoch_Events{4}, [-1.2 0.9], 'epochinfo', 'yes');
    EEG_U = pop_rmbase( EEG_U, prestimulus_Window);
    EEG_UH = pop_select( EEG_U, 'trial', find(trialIndexCond.UnAttendedReport==1));
    EEG_UM = pop_select( EEG_U, 'trial', find(trialIndexCond.UnAttendedReport==0));
    pop_saveset(EEG_U, 'filename', EEG_U_File, 'filepath', conditions);
    pop_saveset(EEG_UH, 'filename', EEG_UH_File, 'filepath', conditions);
    pop_saveset(EEG_UM, 'filename', EEG_UM_File, 'filepath', conditions);

    if ~ isfile(fullfile(conditions, EEG_ALH_File))
        EEG_AL = pop_epoch( EEG_Original, Epoch_Events{5}, [-1.2 0.9], 'epochinfo', 'yes');        
        EEG_UL = pop_epoch( EEG_Original, Epoch_Events{6}, [-1.2 0.9], 'epochinfo', 'yes');
        EEG_AR = pop_epoch( EEG_Original, Epoch_Events{7}, [-1.2 0.9], 'epochinfo', 'yes');
        EEG_UR = pop_epoch( EEG_Original, Epoch_Events{8}, [-1.2 0.9], 'epochinfo', 'yes');

        LattendHit = find(trialIndexCond.LAttendedReport==1);
        LattendMiss = find(trialIndexCond.LAttendedReport==0);     
        EEG_ALH = pop_select( EEG_AL, 'trial', LattendHit);
        EEG_ALH = pop_rmbase( EEG_ALH, prestimulus_Window);
        EEG_ALM = pop_select( EEG_AL, 'trial', LattendMiss);
        EEG_ALM = pop_rmbase( EEG_ALM, prestimulus_Window);
                
        RattendHit = find(trialIndexCond.RAttendedReport==1);
        RattendMiss = find(trialIndexCond.RAttendedReport==0);
        EEG_ARH = pop_select( EEG_AR, 'trial', RattendHit);
        EEG_ARH = pop_rmbase( EEG_ARH, prestimulus_Window);
        EEG_ARM = pop_select( EEG_AR, 'trial', RattendMiss);
        EEG_ARM = pop_rmbase( EEG_ARM, prestimulus_Window);

        LUnattendHit = find(trialIndexCond.LUnAttendedReport==1);
        LUnattendMiss = find(trialIndexCond.LUnAttendedReport==0);
        EEG_ULH = pop_select( EEG_UL, 'trial', LUnattendHit);
        EEG_ULH = pop_rmbase( EEG_ULH, prestimulus_Window);
        EEG_ULM = pop_select( EEG_UL, 'trial', LUnattendMiss);
        EEG_ULM = pop_rmbase( EEG_ULM, prestimulus_Window);
        
        RUnattendHit = find(trialIndexCond.RUnAttendedReport==1);
        RUnattendMiss = find(trialIndexCond.RUnAttendedReport==0);        
        EEG_URH = pop_select( EEG_UR, 'trial', RUnattendHit);
        EEG_URH = pop_rmbase( EEG_URH, prestimulus_Window);
        EEG_URM = pop_select( EEG_UR, 'trial', RUnattendMiss);
        EEG_URM = pop_rmbase( EEG_URM, prestimulus_Window);

        EEG_AL = pop_rmbase( EEG_AL, prestimulus_Window);
        pop_saveset(EEG_AL, 'filename', EEG_AL_File, 'filepath', conditions);
        pop_saveset(EEG_ALH, 'filename', EEG_ALH_File, 'filepath', conditions);
        pop_saveset(EEG_ALM, 'filename', EEG_ALM_File, 'filepath', conditions);
        
        EEG_UL = pop_rmbase( EEG_UL, prestimulus_Window);
        pop_saveset(EEG_UL, 'filename', EEG_UL_File, 'filepath', conditions);
        pop_saveset(EEG_ULH, 'filename', EEG_ULH_File, 'filepath', conditions);
        pop_saveset(EEG_ULM, 'filename', EEG_ULM_File, 'filepath', conditions);

        EEG_AR = pop_rmbase( EEG_AR, prestimulus_Window);
        pop_saveset(EEG_AR, 'filename', EEG_AR_File, 'filepath', conditions);;
        pop_saveset(EEG_ARH, 'filename', EEG_ARH_File, 'filepath', conditions);
        pop_saveset(EEG_ARM, 'filename', EEG_ARM_File, 'filepath', conditions);

        EEG_UR = pop_rmbase( EEG_UR, prestimulus_Window);
        pop_saveset(EEG_UR, 'filename', EEG_UR_File, 'filepath', conditions);
        pop_saveset(EEG_URH, 'filename', EEG_URH_File, 'filepath', conditions);
        pop_saveset(EEG_URM, 'filename', EEG_URM_File, 'filepath', conditions);

        trials_ = struct();
        trials_.A = EEG_A.trials;
        trials_.U = EEG_U.trials;
        trials_.AL = EEG_AL.trials;
        trials_.ALH = EEG_ALH.trials;
        trials_.ALM = EEG_ALM.trials;
        trials_.UL = EEG_UL.trials;
        trials_.ULH = EEG_ULH.trials;
        trials_.ULM = EEG_ULM.trials;
        trials_.AR = EEG_AR.trials;
        trials_.ARH = EEG_ARH.trials;
        trials_.ARM = EEG_ARM.trials;
        trials_.UR = EEG_UR.trials;
        trials_.URH = EEG_URH.trials;
        trials_.URM = EEG_URM.trials; 
        save(fullfile(subDir, 'Conditions', 'TrialsInfo'), 'trials_') 
        
    else
        EEG_AL = pop_loadset('filename', EEG_AL_File, 'filepath', conditions);
        EEG_ALH = pop_loadset('filename', EEG_ALH_File, 'filepath', conditions);
        EEG_ALM = pop_loadset('filename', EEG_ALM_File, 'filepath', conditions);
        
        EEG_UL = pop_loadset('filename', EEG_UL_File, 'filepath', conditions);
        EEG_ULH = pop_loadset('filename', EEG_ULH_File, 'filepath', conditions);
        EEG_ULM = pop_loadset('filename', EEG_ULM_File, 'filepath', conditions);

        EEG_AR = pop_loadset('filename', EEG_AR_File, 'filepath', conditions);
        EEG_ARH = pop_loadset('filename', EEG_ARH_File, 'filepath', conditions);
        EEG_ARM = pop_loadset('filename', EEG_ARM_File, 'filepath', conditions);

        EEG_UR = pop_loadset('filename', EEG_UR_File, 'filepath', conditions);
        EEG_URH = pop_loadset('filename', EEG_URH_File, 'filepath', conditions);
        EEG_URM = pop_loadset('filename', EEG_URM_File, 'filepath', conditions);
        load(fullfile(subDir, 'Conditions', 'TrialsInfo')) ;
    end

    %Epoch_labels = {'Hits', 'Miss', 'Attended', 'Unattended', 'Attended left', 'Unattended left', 'Attended right', 'Unattended right','Attended hits', 'Attended miss', 'Unattended hits', 'Unattended miss'};
    ROCFol = fullfile(subDir, 'ROCAnal');
    if ~isdir(ROCFol)
        mkdir(ROCFol)
    end
%     if (~isfile(fullfile(ROCFol, 'timeRange_A.mat')))
        [timeRange_A, timePeriod_A, maxI_A, noSamp_A, MaxAuc_A] = ROCAnal(EEG_A, Epoch_Events, 'Attended', Epoch_labels, trialIndexCond, ROCFol);
%         save(fullfile(ROCFol, 'timeRange_A'), 'timeRange_A') 
%         save(fullfile(ROCFol, 'timePeriod_A'), 'timePeriod_A') 
%         save(fullfile(ROCFol, 'maxI_A'), 'maxI_A') 
%         save(fullfile(ROCFol, 'noSamp_A'), 'noSamp_A') 
%         save(fullfile(ROCFol, 'MaxAuc_A'), 'MaxAuc_A')         
%     else
%         timeRange_A = load(fullfile(ROCFol, 'timeRange_A.mat')) ;
%         timePeriod_A = load(fullfile(ROCFol, 'timePeriod_A.mat')) ;
%         maxI_A = load(fullfile(ROCFol, 'maxI_A.mat')) ;
%         noSamp_A = load(fullfile(ROCFol, 'noSamp_A.mat')) ;
%         MaxAuc_A = load(fullfile(ROCFol, 'MaxAuc_A'))  ;
%     end
    [timeRange_U, timePeriod_U, maxI_U, noSamp_U, MaxAuc_U] = ROCAnal(EEG_U, Epoch_Events, 'Unattended', Epoch_labels, trialIndexCond, ROCFol);
    [timeRange_AL, timePeriod_AL, maxI_AL, noSamp_AL, MaxAuc_AL] = ROCAnal(EEG_AL, Epoch_Events, 'Attended left', Epoch_labels, trialIndexCond, ROCFol);
    [timeRange_UL, timePeriod_UL, maxI_UL, noSamp_UL, MaxAuc_UL] = ROCAnal(EEG_UL, Epoch_Events, 'Unattended left', Epoch_labels, trialIndexCond, ROCFol);
    [timeRange_AR, timePeriod_AR, maxI_AR, noSamp_AR, MaxAuc_AR] = ROCAnal(EEG_AR, Epoch_Events, 'Attended right', Epoch_labels, trialIndexCond, ROCFol);
    [timeRange_UR, timePeriod_UR, maxI_UR, noSamp_UR, MaxAuc_UR] = ROCAnal(EEG_UR, Epoch_Events, 'Unattended right', Epoch_labels, trialIndexCond, ROCFol);
    %% Time Frequency Analysis: To Calculate the relationship between phase and GFP
    EEG_A = tf_analysis_snippet(EEG_A, subDir, 'Attended');
    EEG_U = tf_analysis_snippet(EEG_U, subDir, 'Unattended');
    EEG_AL = tf_analysis_snippet(EEG_AL, subDir, 'Attended left');
    EEG_UL = tf_analysis_snippet(EEG_UL, subDir, 'Unattended left');
    EEG_AR = tf_analysis_snippet(EEG_AR, subDir, 'Attended right');
    EEG_UR = tf_analysis_snippet(EEG_UR, subDir, 'Unattended right');    
    
    % The circular correlation for attended and unattended should be done
    % between phase of fronto-central channels and GFP (calculate on all channels) from AUC.
  
    [Avg_GFPVals_A, rhoA] = circularCorrelation(EEG_A, timeRange_A, subDir, 'Attended');
    [Avg_GFPVals_U, rhoU] = circularCorrelation(EEG_U, timeRange_U, subDir, 'UnAttended');
    [Avg_GFPVals_AL, rhoAL] = circularCorrelation(EEG_AL, timeRange_AL, subDir, 'Attended left');
    [Avg_GFPVals_UL, rhoUL] = circularCorrelation(EEG_UL, timeRange_UL, subDir, 'Unattended left');
    [Avg_GFPVals_AR, rhoAR] = circularCorrelation(EEG_AR, timeRange_AR, subDir, 'Attended right');
    [Avg_GFPVals_UR, rhoUR] = circularCorrelation(EEG_UR, timeRange_UR, subDir, 'Unattended right');
end



%% Calculate significant corrlations for different conditions and for different channels
NullDistribution_Trial_Shuffled(subjects, filePath, 'Attended');
NullDistribution_Trial_Shuffled(subjects, filePath, 'UnAttended');
NullDistribution_Trial_Shuffled(subjects, filePath, 'Attended left');
NullDistribution_Trial_Shuffled(subjects, filePath, 'Unattended left');
NullDistribution_Trial_Shuffled(subjects, filePath, 'Attended right');
NullDistribution_Trial_Shuffled(subjects, filePath, 'Unattended right');

Avg_NullDistribution(subjects, filePath, 'Average');

%     phaseImpactGFP(EEG_A);
%     phaseImpactGFP(EEG_U);

% Correlations between the GFP at this time and prestimulus phase were first computed for each condition 
% (attended left, attended right, unattended left, unattended right) and channel separately and then averaged. 
% Across all channels, this analysis yielded strong correlations between prestimulus phase and poststimulus 
% GFP in a window from 4 to 10 Hz and−400 ms to−100 ms.
    
%findingOptimalTFPoint(filePath);

time_freq_Point = [-0.224 7.1]; 
if ~isfile(fullfile(filePath, 'BinnedPhaseGFP.mat'))
    for sub_ = 1 : length(subjects)
        display(subjects(sub_).name)
        subDir = fullfile(filePath, subjects(sub_).name);
        fileName = dir(fullfile(subDir, "*.vhdr"));
        temp_ = strsplit(fileName.name, '.vhdr');
        EEG_A_File = ['EEG_A_' temp_{1} '.set'];
        EEG_U_File = ['EEG_U_' temp_{1} '.set'];
        resDir = fullfile(filePath, 'PhaseImpactGFP');
    
        behavDataFold = dir(fullfile(filePath, [subjects(sub_).name '*']));
        behavDataFold = fullfile(behavDataFold.folder, behavDataFold.name);
        trialIndexCond = load(fullfile(behavDataFold, "trialIndexCond.mat"));
        trialIndexCond = trialIndexCond.trialIndexCond;
    
        if ~isdir(resDir)
            mkdir(resDir)
        end    
        conditions = fullfile(subDir, 'Conditions');
        saveArr = [];
        EEG_A = pop_loadset('filename', EEG_A_File, 'filepath', conditions);
        res_ = phaseImpactGFP(EEG_A, fullfile(subDir, 'tf'), time_freq_Point, 'Attended', frontoCentral, trialIndexCond, subjects(sub_).name, resDir);
        saveArr = [saveArr, res_];    
        EEG_U = pop_loadset('filename', EEG_U_File, 'filepath', conditions);
        res_ = phaseImpactGFP(EEG_U, fullfile(subDir, 'tf'), time_freq_Point, 'Unattended', frontoCentral, trialIndexCond, subjects(sub_).name, resDir);
        saveArr = [saveArr, res_];
        saveArr = saveArr';
        cond_ = [repmat({'Attended'}, size(res_,2), 1); repmat({'Unattended'}, size(res_,2), 1)];
        sub_C = [repmat({temp_{1,1}}, size(saveArr, 1), 1)];
        Table_ = table(saveArr(:, 1), saveArr(:, 2), saveArr(:, 3), cond_, sub_C, 'VariableNames', {'GFPAmp_CS', 'Hit_R', 'Phase', 'Conditions', 'Subjects'});    
    
        if sub_ == 1
            var = Table_;
        else
            var = [var; Table_];
        end
    end
    save(fullfile(filePath, 'BinnedPhaseGFP.mat'), 'var')
else
    load(fullfile(filePath, 'BinnedPhaseGFP.mat'))
end

AttendedIndex = [];
UnattendedIndex = [];

for i = 1 : size(var, 1)
    if strmatch(var.Conditions{i}, 'Attended', 'exact')
        AttendedIndex = [AttendedIndex, i];
    else
        UnattendedIndex = [UnattendedIndex, i];
    end
end
% Attended
att_phase = var.Phase(AttendedIndex);
phaseIdx = find(att_phase~=0);
att_phase = att_phase(phaseIdx);
att_GFP = var.GFPAmp_CS(AttendedIndex);
att_GFP = att_GFP(phaseIdx);
att_hit_R = var.Hit_R(AttendedIndex);
att_hit_R = att_hit_R(phaseIdx);

% Unattended
Uatt_phase = var.Phase(UnattendedIndex);
phaseIdx = find(Uatt_phase~=0);
Uatt_phase = Uatt_phase(phaseIdx);
Uatt_GFP = var.GFPAmp_CS(UnattendedIndex);
Uatt_GFP = Uatt_GFP(phaseIdx);
Uatt_hit_R = var.Hit_R(UnattendedIndex);
Uatt_hit_R = Uatt_hit_R(phaseIdx);

PhaseImpGFP_FTest(var, att_phase, att_GFP);
PhaseImpGFP_FTest(var, Uatt_phase, Uatt_GFP);
PhaseImpInteract(att_phase, Uatt_phase, att_GFP, Uatt_GFP);

PhaseImpGFP_FTest(var, att_phase, att_hit_R);
PhaseImpGFP_FTest(var, Uatt_phase, Uatt_hit_R);
PhaseImpInteract(att_phase, Uatt_phase, att_hit_R, Uatt_hit_R);

%phaseImpactGFP(EEG_AL, fullfile(subDir, 'tf'), trials_.AL, time_freq_Point, 'Attended left', frontoCentral, trialIndexCond);
%phaseImpactGFP(EEG_UL, fullfile(subDir, 'tf'), trials_.UL, time_freq_Point, 'Unattended left', frontoCentral, trialIndexCond);
%phaseImpactGFP(EEG_AR, fullfile(subDir, 'tf'), trials_.AR, time_freq_Point, 'Attended right', frontoCentral, trialIndexCond);
%phaseImpactGFP(EEG_UR, fullfile(subDir, 'tf'), trials_.UR, time_freq_Point, 'Unattended right', frontoCentral, trialIndexCond); 

% Calculate the average correlation value (averaged across conditions) for
% different channels across time-frequency points.

% different channles

%preStimPower()