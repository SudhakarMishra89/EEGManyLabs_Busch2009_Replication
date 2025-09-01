function [rho, pval] = circularCorrelation_corrected(EEG, optimalTimeWindow, GFP_perTrial, filePath, name)
    %% Calculating circular-linear correlation between prestimulus phase and post-stimulus GFP
    
    resultDir = fullfile(filePath, 'circularCorrelation_corrected'); 
    if ~isdir(resultDir) 
        mkdir(resultDir) 
    end 
    
    % Load TF data
    savenameInfo = fullfile(filePath, 'tf', [name, '_TFInfo.mat']); 
    load(savenameInfo) 
    
    outfreqs = TFInfo.freqs; 
    outtimes = TFInfo.times; 
    
    % Find prestimulus time indices
    prestimIndices = find(outtimes < 0);
    
    % Get GFP at optimal time window for all trials
    GFP_optimal = GFP_perTrial(optimalTimeWindow, :);
    
    nChannels = EEG.nbchan;
    nFreqs = length(outfreqs);
    nPrestimTimes = length(prestimIndices);
    
    savenameRho = fullfile(resultDir, [name, '_rho_corrected.mat']);
    savenamePval = fullfile(resultDir, [name, '_pval_corrected.mat']);

    if ~ isfile(savenameRho)    
        rho = zeros(nChannels, nFreqs, nPrestimTimes);
        pval = zeros(nChannels, nFreqs, nPrestimTimes);
        
        for c = 1:nChannels
            fprintf('Processing channel %d of %d\n', c, nChannels);
            
            % Load TF data for this channel
            savenameTF = fullfile(filePath, 'tf', [name, '_TF_', num2str(c), '.mat']);
            tfValues = load(savenameTF);
            tf = tfValues.tf;
            
            for freq = 1:nFreqs
                for timeIdx = 1:nPrestimTimes
                    prestimTimePoint = prestimIndices(timeIdx);
                
                    % Extract phases for all trials at this time-frequency point
                    phases = angle(squeeze(tf(freq, prestimTimePoint, :)));
                    
                    % Compute circular-linear correlation
                    try
                        [rho(c, freq, timeIdx), pval(c, freq, timeIdx)] = circ_corrcl(phases, GFP_optimal');
                    catch
                        display('error')
                    end
                end
            end
        end
        
        % Save results
        save(savenameRho, 'rho');
        save(savenamePval, 'pval');
    else
        load(savenameRho)
        load(savenamePval)
    end
end