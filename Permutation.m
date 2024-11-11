function [] = Permutation(subjects, trialInfo, filePath)        

    min_ = -3.1416;
    max_ = 3.1416;

    subjects = dir(fullfile(filePath, "pilot*"));
    savenameInfo = fullfile(subjects.folder, subjects.name, 'tf', ['Attended_TFInfo.mat']);
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
            
    for sub_ = 1 : length(subjects)
        Avg_GFPVals, rho,
        display(subjects(sub_).name)
        subDir = fullfile(filePath, subjects(sub_).name);
        fileName = dir(fullfile(subDir, "*.vhdr"));
        fileName = fileName.name;
        resultDir = fullfile(subDir, 'circularCorrelation');
        if ~isdir(resultDir)
            mkdir(resultDir)
        end   
    
        savingFile = fullfile(resultDir, 'RhoNull_Distribution.mat');
        
        if (~isfile(savingFile))
            for randI = 1 : 10000   
                if randI == 1
                    randTFs = rand(trialInfo, 1);
                    randTFs = (max_-min_).*randTFs + min_;
                end
                [rhoR(sub_, randI), pvalR(sub_, randI)] = circ_corrcl(angle(randTFs), Avg_GFPVals);
            end                                   
        end               
    end   

    mean_Cross = [];
    for ranI2 = 1 : 10000000
        randArr = randi([1 10000], 1, length(subjects));
        CrossSubRhoVals = [];
        for sub_ = 1 : length(subjects)
            CrossSubRhoVals = [CrossSubRhoVals, rhoR(sub_, randArr(sub_))];
        end                    
        mean_Cross = [mean_Cross, mean(CrossSubRhoVals)];
    end
    save(savingFile, 'rhoR') 
end