function [EEG] =  tf_analysis_snippet(EEG, filePath, name)
    %% Run TF analysis.
    minfreq = 2;
    maxfreq = 50;
    frequencies = [minfreq maxfreq];
    cycles = [2 8];
    freqscale = 'linear';
    timesout = [-0.800:0.004:0.800];
    nfreqs = 25;    
    
    for c = 1:EEG.nbchan
        %c = channels(chan)
        %fprintf( 'Processing channel %d of %d\n', chan, length(channels));
        savingPath = fullfile(filePath, 'tf');
        savenameTF = fullfile(savingPath, [name, '_TF_', num2str(c), '.mat']);
        if ~exist(savingPath, 'dir')
            mkdir(savingPath)
        end

        if ~ isfile(savenameTF)        
            data = squeeze( EEG.data(c,:,:) );                
            datalength = size(data,1);
        
            tf = [];
            [tf, outfreqs, outtimes] = timefreq(data, EEG.srate, 'cycles', cycles, 'tlimits', ...
                [EEG.xmin EEG.xmax], 'timesout', timesout, 'wletmethod', 'dftfilt3', 'freqs', frequencies, ...
                'freqscale', freqscale, 'nfreqs', nfreqs);       
        
            TFInfo.cycles = cycles;
            TFInfo.freqs = outfreqs;
            TFInfo.times = outtimes;
            TFInfo.srate = EEG.srate;
            TFInfo.events = EEG.event;
                    
            fprintf('Saving results to disk.\n');   
            if c == 1
                savename = fullfile(savingPath, [name, '_TFInfo.mat']);
                save( savename, 'TFInfo');
            end
            
            display(savenameTF)
            save( savenameTF, 'tf'); % The size of tf here is freq X time X nTrials
        end
    
    end
end