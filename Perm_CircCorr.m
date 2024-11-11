function [] = Perm_CircCorr(subjects, Avg_GFPVals, rho, trialInfo, filePath, name)        

    min_ = -3.1416;
    max_ = 3.1416;

    subjects = dir(fullfile(filePath, "pilot*"));
    savenameInfo = fullfile(subjects.folder, subjects.name, 'tf', [name, '_TFInfo.mat']);
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

    for c = 1 : 63
        for freq_ = 1 : length(outfreqs)
            for time_ = 1 : PrestimTime                
                for sub_ = 1 : length(subjects)
                    display(subjects(sub_).name)
                    subDir = fullfile(filePath, subjects(sub_).name);
                    fileName = dir(fullfile(subDir, "*.vhdr"));
                    fileName = fileName.name;
                    resultDir = fullfile(subDir, 'circularCorrelation', 'RandomRho', name);
                    if ~isdir(resultDir)
                        mkdir(resultDir)
                    end   
                
                    savingFile = fullfile(resultDir, ['randomRho_Chan-', num2str(c), '_Freq-', num2str(freq_), '_Time-', num2str(time_), '.mat']);
                    
                    if (~isfile(savingFile))
                        for randI = 1 : 10000   
                            if randI == 1
                                randTFs = rand(length(outfreqs), PrestimTime, trialInfo);
                                randTFs = (max_-min_).*randTFs + min_;
                            end
    
                            tfS = squeeze(randTFs(freq_, time_, :));
                            [rhoR(sub_, randI), pvalR(sub_, randI)] = circ_corrcl(angle(tfS), Avg_GFPVals);
                        end
                        save(savingFile, 'rhoR')                        
                    end
                        %load(savingFile, 'rhoR')    
                end

                % Pick rho value randomly from rhoR for each channel, frequency and time. And, also for each subject
                
                mean_Cross = [];
                for ranI2 = 1 : 10000000
                    randArr = randi([1 10000], 1, length(subjects));
                    CrossSubRhoVals = [];
                    for sub_ = 1 : length(subjects)
                        CrossSubRhoVals = [CrossSubRhoVals, rhoR(sub_, randArr(sub_))];
                    end                    
                    mean_Cross = [mean_Cross, mean(CrossSubRhoVals)];
                end

                % Now find out how many values in mean_Cross are greater
                % than the rho value with the original data.
            end
        end 
    end       
end