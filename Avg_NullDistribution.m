function [] = Avg_NullDistribution(subjects, filePath, name)        

    min_ = -3.1416;
    max_ = 3.1416;

    AL_savenameRho = 'RHO_AL.mat';
    AL_savenameGFP = 'Avg_GFP_AL.mat';
    UL_savenameRho = 'RHO_UL.mat';
    UL_savenameGFP = 'Avg_GFP_UL.mat';
    AR_savenameRho = 'RHO_AR.mat';
    AR_savenameGFP = 'Avg_GFP_AR.mat';
    UR_savenameRho = 'RHO_UR.mat';
    UR_savenameGFP = 'Avg_GFP_UR.mat';

    resultDir = fullfile(filePath, 'NullDistribution');
    if ~isdir(resultDir)
        mkdir(resultDir)
    end

    savingFile = fullfile(resultDir, [name '_RhoNull_Distribution.mat']);
    if (~isfile(savingFile))  
        subjects = dir(fullfile(filePath, "pilot*"));
        for sub_ = 1 : length(subjects)
            filePath_sub = fullfile(subjects(sub_).folder, subjects(sub_).name);
            AL_GFPFileName = fullfile(filePath_sub, 'circularCorrelation', AL_savenameGFP);  
            AR_GFPFileName = fullfile(filePath_sub, 'circularCorrelation', AR_savenameGFP);
            UL_GFPFileName = fullfile(filePath_sub, 'circularCorrelation', UL_savenameGFP);
            UR_GFPFileName = fullfile(filePath_sub, 'circularCorrelation', UR_savenameGFP);

            AL_GFP = load(AL_GFPFileName);
            AR_GFP = load(AR_GFPFileName);
            UL_GFP = load(UL_GFPFileName);
            UR_GFP = load(UR_GFPFileName);            
            AL_GFP = AL_GFP.Avg_GFPVals;
            AR_GFP = AR_GFP.Avg_GFPVals;
            UL_GFP = UL_GFP.Avg_GFPVals;
            UR_GFP = UR_GFP.Avg_GFPVals;
            avg_cond_GFP = (AL_GFP+AR_GFP+UL_GFP+UR_GFP)/4;

            for randI = 1 : 10000   
                randTFs = rand(size(avg_cond_GFP));
                randTFs = (max_-min_).*randTFs + min_;
                [rhoR(sub_, randI), pvalR(sub_, randI)] = circ_corrcl(randTFs, avg_cond_GFP);
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

    if (~isfile(savingFile))
        for sub_ = 1 : length(subjects)
            filePath_sub = fullfile(subjects(sub_).folder, subjects(sub_).name);
            %savenameInfo = fullfile(filePath_sub, 'tf', [name, '_TFInfo.mat']);
            %load(savenameInfo)
        
            %cycles = TFInfo.cycles;
            %outfreqs = TFInfo.freqs;
            %outtimes = TFInfo.times;
            %srate = TFInfo.srate;
            %events = TFInfo.events;
        
            %timeStep = 2100/length(outtimes); % 2100 is the total length of the data. 
            %timeArr = [-1200: timeStep: 900];
            %PoststimTime = find(timeArr > 0);
            %PrestimTime = PoststimTime(1)-1;        

            AL_Rho = load(fullfile(filePath_sub, 'circularCorrelation', AL_savenameRho));
            AL_Rho = AL_Rho.rho;
            UL_Rho = load(fullfile(filePath_sub, 'circularCorrelation', UL_savenameRho));
            UL_Rho = UL_Rho.rho;
            AR_Rho = load(fullfile(filePath_sub, 'circularCorrelation', AR_savenameRho));
            AR_Rho = AR_Rho.rho;
            UR_Rho = load(fullfile(filePath_sub, 'circularCorrelation', UR_savenameRho));
            UR_Rho = UR_Rho.rho;
            avg_Rho_Val = (AL_Rho+UL_Rho+AR_Rho+UR_Rho)/4;

            nChannels = size(avg_Rho_Val, 1);
            nFreq = size(avg_Rho_Val, 2);
            nTimeP = size(avg_Rho_Val, 3);
            if sub_ == 1
                allRhoValues = zeros(length(subjects), nChannels, nFreq, nTimeP);
            end
    
            for Chan_i = 1 : nChannels
                for Chan_Freq = 1 : nFreq
                    for Chan_Time = 1 : nTimeP
                        allRhoValues(sub_, Chan_i, Chan_Freq, Chan_Time) = avg_Rho_Val(Chan_i, Chan_Freq, Chan_Time);
                    end
                end
            end
        end
    
        orig_meanRhoValues = squeeze(mean(allRhoValues, 1));    
        % Calculating p-values   
        nChannels = size(orig_meanRhoValues, 1);
        nFreq = size(orig_meanRhoValues, 2);
        nTimeP = size(orig_meanRhoValues, 3);
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