function [] = NullDistribution_Shuffled(subjects, filePath, name)        

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

    if (~isfile(savingFile))  
        subjects = dir(fullfile(filePath, "pilot*"));        
        for sub_ = 1 : length(subjects)
            filePath_sub = fullfile(subjects(sub_).folder, subjects(sub_).name);
            SubRandCorrFile = fullfile(filePath_sub, [name '_RandomCorrelationV.mat']);
            SubRandCorPFile = fullfile(filePath_sub, [name '_RandomCorrelationP.mat']);

            if (~isfile(SubRandCorrFile))
                GFPFileName = fullfile(filePath_sub, 'circularCorrelation', savenameGFP);  
                load(GFPFileName)
                savingPath = fullfile(filePath_sub, 'tf');
    
                vectorizeFile = fullfile(savingPath, 'Vectorize_File.mat');
                if (~isfile(vectorizeFile))                
                    for c = 1:63 %EEG.nbchan                    
                        savenameTF = fullfile(savingPath, [name, '_TF_', num2str(c), '.mat']);
                        load(savenameTF)  
                        vect_tf = angle(tf(:));
                        if c == 1
                            tf_vect_arr = vect_tf;
                        else
                            tf_vect_arr = [tf_vect_arr, vect_tf];
                        end
                    end
        
                    tf_vect = single(tf_vect_arr(:));
                    save(vectorizeFile, 'tf_vect', '-v7.3');
                else
                    load(vectorizeFile)
                end
                random_indices = randperm(length(tf_vect));
                randomIntegers = randi([1, length(tf_vect)-600], 1, 10000);

                for randI = 1 : 10000  
                    %random_indices = randperm(length(tf_vect));
                    random_samples = tf_vect(random_indices(randomIntegers(randI):randomIntegers(randI)+length(Avg_GFPVals)-1));                
                    [rhoR(randI), pvalR(randI)] = circ_corrcl(random_samples, Avg_GFPVals);
                end        
                AllSub_rhoR(sub_, :) = rhoR;
                AllSub_rhoP(sub_, :) = pvalR;                
                save(SubRandCorrFile, 'rhoR')                
                save(SubRandCorPFile, 'pvalR')
            else
                AllSub_rhoR(sub_, :) = load(SubRandCorrFile);
                AllSub_rhoP(sub_, :) = load(SubRandCorPFile);
            end
        end  
        save(savingFile, 'AllSub_rhoR');
        save(savingPvalFile, 'AllSub_rhoP');
    else
        load(savingFile)
        load(savingPvalFile)
    end

    savingFile = fullfile(resultDir, [name '_AcrossSubjects_RhoNull_Distribution.mat']);
    if (~isfile(savingFile))  
        mean_Cross = [];
        for ranI2 = 1 : 10000000
            randArr = randi([1 10000], 1, length(subjects));
            CrossSubRhoVals = [];
            for sub_ = 1 : length(subjects)
                CrossSubRhoVals = [CrossSubRhoVals, AllSub_rhoR(sub_).rhoR(randArr(sub_))];
            end                    
            mean_Cross = [mean_Cross, mean(CrossSubRhoVals)];
        end    
        save(savingFile, 'mean_Cross');
    else
        load(savingFile)
    end
    
    subjects = dir(fullfile(filePath, "pilot*"));
    resultDir = fullfile(filePath, 'pValues');
    if ~isdir(resultDir)
        mkdir(resultDir)
    end

    % Since we have calculated the null distribution on the mean
    % correlations across subjects, I should calculate the original
    % correlation mean across subjects too.

    savingFile = fullfile(resultDir, [name '_pValues.mat']);
    savingFileFDR = fullfile(resultDir, [name '_pValues_FDR.mat']);

    if (~(isfile(savingFile) | isfile(savingFileFDR)))
    %if ((isfile(savingFile) | isfile(savingFileFDR)))
        for sub_ = 1 : length(subjects)
            filePath_sub = fullfile(subjects(sub_).folder, subjects(sub_).name);
            savingFile = fullfile(resultDir, ['pValue_', subjects(sub_).name, '.mat']);
            savenameInfo = fullfile(filePath_sub, 'tf', [name, '_TFInfo.mat']);
            load(savenameInfo)
        
            cycles = TFInfo.cycles;
            outfreqs = TFInfo.freqs;
            outtimes = TFInfo.times;
            srate = TFInfo.srate;
            events = TFInfo.events;
        
            timeStep = 2100/length(outtimes); % 2100 is the total length of the data. 
            timeArr = [-1200: timeStep: 900];
            PoststimTime = find(timeArr > 0);
            PrestimTime = PoststimTime(1)-1;      
    
            RhoFileName = fullfile(filePath_sub, 'circularCorrelation', savenameRho);
            display(filePath_sub)
            load(RhoFileName)
    
            nChannels = size(rho, 1);
            nFreq = size(rho, 2);
            nTimeP = size(rho, 3);
            if sub_ == 1
                allRhoValues = zeros(length(subjects), nChannels, nFreq, nTimeP);
            end
    
            for Chan_i = 1 : nChannels
                for Chan_Freq = 1 : nFreq
                    for Chan_Time = 1 : nTimeP
                        allRhoValues(sub_, Chan_i, Chan_Freq, Chan_Time) = rho(Chan_i, Chan_Freq, Chan_Time);
                    end
                end
            end
        end
    
        orig_meanRhoValues = squeeze(mean(allRhoValues, 1));    
        % Calculating p-values
        filePath_sub = fullfile(subjects(1).folder, subjects(1).name);
        savenameInfo = fullfile(filePath_sub, 'tf', [name, '_TFInfo.mat']);
        load(savenameInfo)
    
        cycles = TFInfo.cycles;
        outfreqs = TFInfo.freqs;
        outtimes = TFInfo.times;
        srate = TFInfo.srate;
        events = TFInfo.events;
    
        timeStep = 2100/length(outtimes); % 2100 is the total length of the data. 
        timeArr = [-1200: timeStep: 900];
        PoststimTime = find(timeArr > 0);
        PrestimTime = PoststimTime(1)-1;      
    
        RhoFileName = fullfile(filePath_sub, 'circularCorrelation', savenameRho);
        display(filePath_sub)
    
        load(RhoFileName)
    
        nChannels = size(rho, 1);
        nFreq = size(rho, 2);
        nTimeP = size(rho, 3);
        pValueArray = zeros(nChannels, nFreq, nTimeP);
    
        for Chan_i = 1 : nChannels
            for Chan_Freq = 1 : nFreq
                for Chan_Time = 1 : nTimeP
                    %pValueArray(Chan_i, Chan_Freq, Chan_Time) = sum(orig_meanRhoValues(Chan_i, Chan_Freq, Chan_Time) < mean_Cross)/length(mean_Cross);
                    pValueArray(Chan_i, Chan_Freq, Chan_Time) = sum(orig_meanRhoValues(Chan_i, Chan_Freq, ...
                        Chan_Time) < AllSub_rhoR(1).rhoR)/length(AllSub_rhoR(1).rhoR);
                end
            end
        end
        save(savingFile, 'pValueArray');
        fdr = mafdr(pValueArray(:), 'BHFDR', 1); 
        fdr_mat = reshape(fdr, nChannels, nFreq, nTimeP);
        save(savingFileFDR, 'fdr_mat');
        % Make a vector and then apply and then convert back to 3d matrix.
        % Check example matrix first.
    end
end