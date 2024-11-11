function [timeRange, timePeriod, maxI, noSamp, M] =  ROCAnal(EEG, Epoch_Events, condLabel, Epoch_labels, trialIndexCond, filePath) %EEG, eventCell
    
    condIndx = strmatch(condLabel, Epoch_labels, "exact");
    eventCell = Epoch_Events{condIndx};
    
    if strmatch({condLabel}, 'Attended', 'exact')
        report = trialIndexCond.AttendedReport;
        savingFile = fullfile(filePath, "High_Perception_TimeRange_A");
    elseif strmatch({condLabel}, 'Unattended', 'exact')
        report = trialIndexCond.UnAttendedReport;
        savingFile = fullfile(filePath, "High_Perception_TimeRange_U");
    elseif strmatch({condLabel}, 'Attended left', 'exact')
        report = trialIndexCond.LAttendedReport;
        savingFile = fullfile(filePath, "High_Perception_TimeRange_AL");
    elseif strmatch({condLabel}, 'Unattended left', 'exact')
        report = trialIndexCond.RAttendedReport;
        savingFile = fullfile(filePath, "High_Perception_TimeRange_UL");
    elseif strmatch({condLabel}, 'Attended right', 'exact')
        report = trialIndexCond.LUnAttendedReport;
        savingFile = fullfile(filePath, "High_Perception_TimeRange_AR");
    elseif strmatch({condLabel}, 'Unattended right', 'exact')
        report = trialIndexCond.RUnAttendedReport;
        savingFile = fullfile(filePath, "High_Perception_TimeRange_UR");
    end

    hit_trials = find(report==1);
    miss_trials = find(report==0);

    % I can fill it here.

    Percieved = repelem({'hits'}, EEG.trials);
    Percieved(miss_trials) = {'miss'};

    %ERP = squeeze(mean(EEG.data, 3));
    noSamp = fix((500/1000)*50); % No of samples in 50ms.
    GFP = [];    
    timePeriod = [];
    stimOnset = fix(1.2*EEG.srate);

    for trial_ = 1 : EEG.trials
        GFPCount = 1;
        for time_ = stimOnset : noSamp : EEG.pnts
            if time_+noSamp < EEG.pnts % Ramya & Sudhakar Changed here. 26/12 ; Earlier- time_+noSamp < EEG.pnts
                GFP(trial_, GFPCount) = mean(std(EEG.data(:, (time_:time_+noSamp), trial_)));
                GFPCount = GFPCount + 1;
                if trial_ == 1
                    timeInMS = (time_ / EEG.srate)*1000;
                    timePeriod = [timePeriod, timeInMS];
                end
            end
        end
    end

    AUC = [];
    for time_ = 1 : (GFPCount-1)
        min_ = min(GFP(:, time_));
        max_ = max(GFP(:, time_));
        
        %% Just checking the standard ways
%         P_hits = (GFP(:, time_) > (min_+max_)/2);            
%         P_miss = (GFP(:, time_) <= (min_+max_)/2);    
%         [X,Y,T,AUC] = perfcurve(Percieved, P_hits, 'hits');
        %%
    
        step_ = (min_-max_)/20;
        FPR = [];
        TPR = [];
        for ampThr = max_ : step_ : min_
            P_hits = find(GFP(:, time_) > ampThr);            
            P_miss = find(GFP(:, time_) <= ampThr);
            tp = 0;
            fn = 0;
            fp = 0;
            tn = 0;
            for ht = 1 : length(hit_trials) % For Actual Hits
                if any(hit_trials(ht) == P_hits)
                    tp = tp + 1;
                elseif any(hit_trials(ht) == P_miss)
                    fn = fn + 1;                    
                end
            end
            for ms = 1 : length(miss_trials) % For Actual Miss
                if any(miss_trials(ms) == P_hits)
                    fp = fp + 1;
                elseif any(miss_trials(ms) == P_miss)
                    tn = tn + 1;                    
                end                            
            end
            TPR = [TPR, tp/(tp+fn)];
            FPR = [FPR, fp/(fp+tn)];
        end
        AUC = [AUC, trapz(FPR, TPR)];
    end
    [M, maxI] = max(AUC);
    %timeFromOnset = (timePeriod(maxI) / EEG.srate)*1000 - 1200;
%     timeRange = [timePeriod(maxI) timePeriod(maxI+1)];
    
    if (maxI == 17)
        timeRange = [timePeriod(maxI) 2050];
    else
        timeRange = [timePeriod(maxI) timePeriod(maxI+1)];
    end
    % timePeriod and timeRange in milliseconds. Hence, subtract the time
    % before stimulus onset in milliseconds. I mean subtract
    % 1.2*1000=1200ms to get the time of highest perception.
    save(savingFile, 'timeRange');
end

%     Fill it where it is written "I can fill it here."
%     Ind_s_1 = strcmp({EEG.event.type}, {eventCell{1}});
%     if length(eventCell) > 1
%         Ind_s_2 = strcmp({EEG.event.type}, {eventCell{2}});
%         StimIdx = sort([find(Ind_s_1), find(Ind_s_2)]);
%     else
%         StimIdx = sort(find(Ind_s_1));
%     end
%     
%     hit_trials = [];
%     miss_trials = [];
%     noTrial = [];
%     trialNumber = 1;
%     for i = 1 : length(StimIdx)
%         if StimIdx(i)+1 <= length(EEG.event)
%             if strcmp(EEG.event(StimIdx(i)+1).type, 'S  2')
%                 v = [hit_trials trialNumber];
%                 trialNumber = trialNumber + 1;
%             elseif strcmp(EEG.event(StimIdx(i)+1).type, 'S 11')
%                 miss_trials = [miss_trials trialNumber];
%                 trialNumber = trialNumber + 1;
%             else
%                 disp('Nothing')
%                 disp(EEG.event(StimIdx(i)).type)
%                 disp(EEG.event(StimIdx(i)+1).type)
%                 noTrial = [noTrial trialNumber];
%                 trialNumber = trialNumber + 1;
% 
%             end        
%         end
%     end
%     
% %     AhitSc = zeros(length(hit_trials)+length(miss_trials), 1);
% %     AhitSc(hit_trials) = 1;
% %     AmissSc = zeros(length(hit_trials)+length(miss_trials), 1);
% %     AmissSc(miss_trials) = 1;    
% %     ActualScore = [AhitSc, AmissSc];