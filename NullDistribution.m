    function [] = NullDistribution(subjects, filePath, name)        

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

    savingFile = fullfile(resultDir, [name '_RhoNull_Distribution.mat']);
    if (~isfile(savingFile))  
        subjects = dir(fullfile(filePath, "pilot*"));
        for sub_ = 1 : length(subjects)
            filePath_sub = fullfile(subjects(sub_).folder, subjects(sub_).name);
            GFPFileName = fullfile(filePath_sub, 'circularCorrelation', savenameGFP);  
            load(GFPFileName)

            for randI = 1 : 10000   
                randTFs = rand(size(Avg_GFPVals));
                randTFs = (max_-min_).*randTFs + min_;
                [rhoR(sub_, randI), pvalR(sub_, randI)] = circ_corrcl(randTFs, Avg_GFPVals);
            end               
        end 
        save(savingFile, 'rhoR');
    else
        load(savingFile)
    end

    savingFile = fullfile(resultDir, [name '_AcrossSubjects_RhoNull_Distribution.mat']);
    if (~isfile(savingFile))  
        mean_Cross = [];
        for ranI2 = 1 : 10000000
            randArr = randi([1 10000], 1, length(subjects));
            CrossSubRhoVals = [];
            for sub_ = 1 : length(subjects)
                CrossSubRhoVals = [CrossSubRhoVals, rhoR(sub_, randArr(sub_))];
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

    %if (~(isfile(savingFile) | isfile(savingFileFDR)))
    if ((isfile(savingFile) | isfile(savingFileFDR)))
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
                    pValueArray(Chan_i, Chan_Freq, Chan_Time) = sum(orig_meanRhoValues(Chan_i, Chan_Freq, Chan_Time) < mean_Cross)/length(mean_Cross);
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