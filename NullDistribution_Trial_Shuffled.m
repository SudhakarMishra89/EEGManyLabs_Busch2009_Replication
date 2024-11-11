function [] = NullDistribution_Trial_Shuffled(subjects, filePath, name)        

    min_ = -3.1416;
    max_ = 3.1416;

    if strmatch(name,'Attended')
        savenameRho = 'RHO_A.mat';
        savenameGFP = 'Avg_GFP_A.mat';
    elseif strmatch(name,'UnAttended')
        savenameRho = 'RHO_U.mat';
        savenameGFP = 'Avg_GFP_U.mat';
    elseif strmatch(name,'Attended left')
        savenameRho = 'RHO_AL.mat';
        savenameGFP = 'Avg_GFP_AL.mat';
    elseif strmatch(name,'Unattended left')
        savenameRho = 'RHO_UL.mat';
        savenameGFP = 'Avg_GFP_UL.mat';
    elseif strmatch(name,'Attended right')
        savenameRho = 'RHO_AR.mat';
        savenameGFP = 'Avg_GFP_AR.mat';
    elseif strmatch(name,'Unattended right')
        savenameRho = 'RHO_UR.mat';
        savenameGFP = 'Avg_GFP_UR.mat';
    end

    resultDir = fullfile(filePath, 'NullDistribution');
    if ~isdir(resultDir)
        mkdir(resultDir)
    end
    savingFile = fullfile(resultDir, [name '_RandomCorrelationV_AllSub.mat']);
    savingPvalFile = fullfile(resultDir, [name '_RandomCorrelationP_AllSub.mat']);
    
    for randI = 1 : 10000
        vec = 1:600; % Example vector
        shuffledVec = vec(randperm(length(vec))); % Shuffle the vector
        v = reshape(shuffledVec, 600, 1);
        if randI == 1
            shuffledArr = v;
        else
            shuffledArr(:, randI) = v;
        end
    end

    if (isfile(savingFile))  
        subjects = dir(fullfile(filePath, "pilot*"));        
        for sub_ = 1 : length(subjects)
            filePath_sub = fullfile(subjects(sub_).folder, subjects(sub_).name);
            GFPFileName = fullfile(filePath_sub, 'circularCorrelation', savenameGFP);  
            load(GFPFileName)
            savingPath = fullfile(filePath_sub, 'tf');

            vectorizeFile = fullfile(savingPath, 'Vectorize_File.mat');
            if (~isfile(vectorizeFile))                
            %if (isfile(vectorizeFile))                
                for c = 1:63 %EEG.nbchan                    
                    savenameTF = fullfile(savingPath, [name, '_TF_', num2str(c), '.mat']);
                    load(savenameTF)  
                    tf = tf(:, 1:161, :); % from -600 ms to 0ms.
                    dim_tf = size(tf);
                    vect_tf = angle(reshape(tf, [1, dim_tf(1)*dim_tf(2), dim_tf(3)]));
                    if c == 1
                        tf_vect_arr = vect_tf;
                    else
                        tf_vect_arr = cat(1, tf_vect_arr, vect_tf);
                    end
                end
    
                %dim_ = size(tf_vect_arr);
                %tf_vect_arr = single(reshape(tf_vect_arr, [dim_(1)*dim_(2), dim_(3)]));
                save(vectorizeFile, 'tf_vect_arr', '-v7.3');
            % else
            %     load(vectorizeFile)
             end
        end
        
        totalCalculations = 25*161; % Frequency x time

        parpool
        for chanI = 1 : 63
            display(chanI)
            SubRandCorrFile = fullfile(filePath, strcat(name, '_RandomCorrelationV_', string(chanI),'.mat'));
            SubRandCorPFile = fullfile(filePath, strcat(name, '_RandomCorrelationP_', string(chanI),'.mat'));            
            %if ~ isfile(SubRandCorPFile)
            channel_rhoR = zeros(totalCalculations, length(subjects), 10000);
            channel_rhoP = zeros(totalCalculations, length(subjects), 10000);
            parfor timePoint = 1 : totalCalculations               
                AllSub_rhoR = zeros(length(subjects), 10000);
                AllSub_rhoP = zeros(length(subjects), 10000);
                tf_vect_arr_sub = zeros(2, totalCalculations, 600)
                for sub_ = 1 : length(subjects)
                    filePath_sub = fullfile(subjects(sub_).folder, subjects(sub_).name);                
                    GFPFileName = fullfile(filePath_sub, 'circularCorrelation', savenameGFP);  
                    Avg_GFPVals = load(GFPFileName);
                    Avg_GFPVals = Avg_GFPVals.Avg_GFPVals;
                    savingPath = fullfile(filePath_sub, 'tf');
                    vectorizeFile = fullfile(savingPath, 'Vectorize_File.mat');   
                    if timePoint == 1
                        tf_vect_arr = load(vectorizeFile);
                        tf_vect_arr = tf_vect_arr.tf_vect_arr;
                        dim_arr = size(tf_vect_arr);
%                         if sub_ == 1
%                             tf_vect_arr_sub = reshape(tf_vect_arr, 1, dim_arr(1), dim_arr(2));
%                         else
                            tf_vect_arr_sub(sub_, :, :) = tf_vect_arr(chanI, :, :); %reshape(tf_vect_arr, 1, dim_arr(1), dim_arr(2));
%                         end

                    end
                    rhoR = zeros(1, 10000);
                    pvalR = zeros(1, 10000);
                    for randI = 1 : 10000  
                        ShuffTrials = shuffledArr(:, randI);
                        shuffleVect = squeeze(tf_vect_arr_sub(sub_, timePoint, ShuffTrials));
                        %random_samples = tf_vect(random_indices(randomIntegers(randI):randomIntegers(randI)+length(Avg_GFPVals)-1));                
                        [rhoR(randI), pvalR(randI)] = circ_corrcl(shuffleVect, Avg_GFPVals);
                    end
                    AllSub_rhoR(sub_, :) = rhoR;
                    AllSub_rhoP(sub_, :) = pvalR;                
                end 
                channel_rhoR(timePoint, :, :) = AllSub_rhoR
                channel_rhoP(timePoint, :, :) = AllSub_rhoP
            end   
            save(SubRandCorrFile, 'channel_rhoR')                
            save(SubRandCorPFile, 'channel_rhoP')
        end
        %             else
        %                 display('Nothing')
        %                 %load(SubRandCorrFile)                
        %                 %load(SubRandCorPFile)
        %             end
                    
        %             savingFile = fullfile(resultDir, [name '_AcrossSubjects_RhoNull_Distribution_TimePoint', string(timePoint),'.mat']);
        %             if (~isfile(savingFile))  
        %                 mean_Cross = [];
        %                 for ranI2 = 1 : 10000000
        %                     randArr = randi([1 10000], 1, length(subjects));
        %                     CrossSubRhoVals = [];
        %                     for sub_ = 1 : length(subjects)
        %                         CrossSubRhoVals = [CrossSubRhoVals, AllSub_rhoR(sub_).rhoR(randArr(sub_))];
        %                     end                    
        %                     mean_Cross = [mean_Cross, mean(CrossSubRhoVals)];
        %                 end    
        %                 save(savingFile, 'mean_Cross');
        %             else
        %                 load(savingFile)
        %             end
        
        end
%         else
%             AllSub_rhoR(sub_, :) = load(SubRandCorrFile);
%             AllSub_rhoP(sub_, :) = load(SubRandCorPFile);
%         end
% 
%         save(savingFile, 'AllSub_rhoR');
%         save(savingPvalFile, 'AllSub_rhoP');


%     savingFile = fullfile(resultDir, [name '_AcrossSubjects_RhoNull_Distribution.mat']);
%     if (~isfile(savingFile))  
%         mean_Cross = [];
%         for ranI2 = 1 : 10000000
%             randArr = randi([1 10000], 1, length(subjects));
%             CrossSubRhoVals = [];
%             for sub_ = 1 : length(subjects)
%                 CrossSubRhoVals = [CrossSubRhoVals, AllSub_rhoR(sub_).rhoR(randArr(sub_))];
%             end                    
%             mean_Cross = [mean_Cross, mean(CrossSubRhoVals)];
%         end    
%         save(savingFile, 'mean_Cross');
%     else
%         load(savingFile)
%     end
%     
%     subjects = dir(fullfile(filePath, "pilot*"));
%     resultDir = fullfile(filePath, 'pValues');
%     if ~isdir(resultDir)
%         mkdir(resultDir)
%     end
% 
%     % Since we have calculated the null distribution on the mean
%     % correlations across subjects, I should calculate the original
%     % correlation mean across subjects too.
% 
%     savingFile = fullfile(resultDir, [name '_pValues.mat']);
%     savingFileFDR = fullfile(resultDir, [name '_pValues_FDR.mat']);
% 
%     if (~(isfile(savingFile) | isfile(savingFileFDR)))
%     %if ((isfile(savingFile) | isfile(savingFileFDR)))
%         for sub_ = 1 : length(subjects)
%             filePath_sub = fullfile(subjects(sub_).folder, subjects(sub_).name);
%             savingFile = fullfile(resultDir, ['pValue_', subjects(sub_).name, '.mat']);
%             savenameInfo = fullfile(filePath_sub, 'tf', [name, '_TFInfo.mat']);
%             load(savenameInfo)
%         
%             cycles = TFInfo.cycles;
%             outfreqs = TFInfo.freqs;
%             outtimes = TFInfo.times;
%             srate = TFInfo.srate;
%             events = TFInfo.events;
%         
%             timeStep = 2100/length(outtimes); % 2100 is the total length of the data. 
%             timeArr = [-1200: timeStep: 900];
%             PoststimTime = find(timeArr > 0);
%             PrestimTime = PoststimTime(1)-1;      
%     
%             RhoFileName = fullfile(filePath_sub, 'circularCorrelation', savenameRho);
%             display(filePath_sub)
%             load(RhoFileName)
%     
%             nChannels = size(rho, 1);
%             nFreq = size(rho, 2);
%             nTimeP = size(rho, 3);
%             if sub_ == 1
%                 allRhoValues = zeros(length(subjects), nChannels, nFreq, nTimeP);
%             end
%     
%             for Chan_i = 1 : nChannels
%                 for Chan_Freq = 1 : nFreq
%                     for Chan_Time = 1 : nTimeP
%                         allRhoValues(sub_, Chan_i, Chan_Freq, Chan_Time) = rho(Chan_i, Chan_Freq, Chan_Time);
%                     end
%                 end
%             end
%         end
%     
%         orig_meanRhoValues = squeeze(mean(allRhoValues, 1));    
%         % Calculating p-values
%         filePath_sub = fullfile(subjects(1).folder, subjects(1).name);
%         savenameInfo = fullfile(filePath_sub, 'tf', [name, '_TFInfo.mat']);
%         load(savenameInfo)
%     
%         cycles = TFInfo.cycles;
%         outfreqs = TFInfo.freqs;
%         outtimes = TFInfo.times;
%         srate = TFInfo.srate;
%         events = TFInfo.events;
%     
%         timeStep = 2100/length(outtimes); % 2100 is the total length of the data. 
%         timeArr = [-1200: timeStep: 900];
%         PoststimTime = find(timeArr > 0);
%         PrestimTime = PoststimTime(1)-1;      
%     
%         RhoFileName = fullfile(filePath_sub, 'circularCorrelation', savenameRho);
%         display(filePath_sub)
%     
%         load(RhoFileName)
%     
%         nChannels = size(rho, 1);
%         nFreq = size(rho, 2);
%         nTimeP = size(rho, 3);
%         pValueArray = zeros(nChannels, nFreq, nTimeP);
%     
%         for Chan_i = 1 : nChannels
%             for Chan_Freq = 1 : nFreq
%                 for Chan_Time = 1 : nTimeP
%                     %pValueArray(Chan_i, Chan_Freq, Chan_Time) = sum(orig_meanRhoValues(Chan_i, Chan_Freq, Chan_Time) < mean_Cross)/length(mean_Cross);
%                     pValueArray(Chan_i, Chan_Freq, Chan_Time) = sum(orig_meanRhoValues(Chan_i, Chan_Freq, ...
%                         Chan_Time) < AllSub_rhoR(1).rhoR)/length(AllSub_rhoR(1).rhoR);
%                 end
%             end
%         end
%         save(savingFile, 'pValueArray');
%         fdr = mafdr(pValueArray(:), 'BHFDR', 1); 
%         fdr_mat = reshape(fdr, nChannels, nFreq, nTimeP);
%         save(savingFileFDR, 'fdr_mat');
%         % Make a vector and then apply and then convert back to 3d matrix.
%         % Check example matrix first.
%     end
