function [Avg_GFPVals, rho] = circularCorrelation(EEG, timeRange_A, filePath, name)
        
    resultDir = fullfile(filePath, 'circularCorrelation');
    if ~isdir(resultDir)
        mkdir(resultDir)
    end
    if strmatch(name,'Attended')
        savenameRho = fullfile(resultDir, 'RHO_A.mat');
        savenamePval = fullfile(resultDir, 'RHO_A_P.mat');
        savenameGFP = fullfile(resultDir, 'Avg_GFP_A.mat');
    elseif strmatch(name,'UnAttended')
        savenameRho = fullfile(resultDir, 'RHO_U.mat');
        savenamePval = fullfile(resultDir, 'RHO_U_P.mat');
        savenameGFP = fullfile(resultDir, 'Avg_GFP_U.mat');
    elseif strmatch(name,'Attended left')
        savenameRho = fullfile(resultDir, 'RHO_AL.mat');
        savenamePval = fullfile(resultDir, 'RHO_AL_P.mat');
        savenameGFP = fullfile(resultDir, 'Avg_GFP_AL.mat');
    elseif strmatch(name,'Unattended left')
        savenameRho = fullfile(resultDir, 'RHO_UL.mat');
        savenamePval = fullfile(resultDir, 'RHO_UL_P.mat');
        savenameGFP = fullfile(resultDir, 'Avg_GFP_UL.mat');
    elseif strmatch(name,'Attended right')
        savenameRho = fullfile(resultDir, 'RHO_AR.mat');
        savenamePval = fullfile(resultDir, 'RHO_AR_P.mat');
        savenameGFP = fullfile(resultDir, 'Avg_GFP_AR.mat');
    elseif strmatch(name,'Unattended right')
        savenameRho = fullfile(resultDir, 'RHO_UR.mat');
        savenamePval = fullfile(resultDir, 'RHO_UR_P.mat');
        savenameGFP = fullfile(resultDir, 'Avg_GFP_UR.mat');
    end
    
    min_ = -3.1416;
    max_ = 3.1416;
    
    savenameInfo = fullfile(filePath, 'tf', [name, '_TFInfo.mat']);
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

    rho = zeros(EEG.nbchan, length(outfreqs), PrestimTime);
    pval = zeros(EEG.nbchan, length(outfreqs), PrestimTime);
    sampStart = (timeRange_A*EEG.srate)/1000;

    if (~isfile(savenameGFP))
        GFPVals = zeros(EEG.trials, 1);
    
        for samp_ = sampStart(1): sampStart(2)
            Vals = std(EEG.data(:, samp_, :));   
            GFPVals = GFPVals + squeeze(Vals);
        end
        Avg_GFPVals = GFPVals/(sampStart(2)-sampStart(1));
        save(savenameGFP, 'Avg_GFPVals');
    else
        Avg_GFPVals = load(savenameGFP);
        Avg_GFPVals = Avg_GFPVals.Avg_GFPVals;
    end

    if (~isfile(savenameRho))    
        for c = 1:EEG.nbchan
            savename = fullfile(filePath, 'tf', [name, '_TF_', num2str(c)]);
            tf_ = load(savename);
    
            for freq_ = 1 : length(outfreqs)
                for time_ = 1 : PrestimTime
                    tfS = squeeze(tf_.tf(freq_, time_, :));
                    [rho(c, freq_, time_), pval(c, freq_, time_)] = circ_corrcl(angle(tfS), Avg_GFPVals);
                end
            end   
        end
        save(savenameRho, 'rho');  
        save(savenamePval, 'pval');
    else
        rho = load(savenameRho);        
    end
end
