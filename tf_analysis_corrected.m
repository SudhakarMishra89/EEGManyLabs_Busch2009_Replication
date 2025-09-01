function [EEG] = tf_analysis_corrected(EEG, filePath, name)
    %% Time-Frequency analysis - Calculating time-frequency matrix using wavelet transform
    minfreq = 2; 
    maxfreq = 50; 
    frequencies = [minfreq maxfreq]; 
    cycles = [2 8]; 
    freqscale = 'linear'; 
    % Time window from -1200ms to +900ms as in original paper
    timesout = [-1.200:0.004:0.900]; 
    nfreqs = 25;    
    
    for c = 1:EEG.nbchan 
        savingPath = fullfile(filePath, 'tf'); 
        savenameTF = fullfile(savingPath, [name, '_TF_', num2str(c), '.mat']); 
        
        if ~exist(savingPath, 'dir') 
            mkdir(savingPath) 
        end 
        
        if ~ isfile(savenameTF)        
            data = squeeze(EEG.data(c,:,:));                
            
            [tf, outfreqs, outtimes] = timefreq(data, EEG.srate, ...
                'cycles', cycles, 'tlimits', [EEG.xmin EEG.xmax], ...
                'timesout', timesout, 'wletmethod', 'dftfilt3', ...
                'freqs', frequencies, 'freqscale', freqscale, 'nfreqs', nfreqs);       
            
            TFInfo.cycles = cycles; 
            TFInfo.freqs = outfreqs; 
            TFInfo.times = outtimes; 
            TFInfo.srate = EEG.srate; 
            TFInfo.events = EEG.event; 
            
            if c == 1 
                savename = fullfile(savingPath, [name, '_TFInfo.mat']); 
                save(savename, 'TFInfo'); 
            end 
            
            save(savenameTF, 'tf'); 
        end 
    end 
end