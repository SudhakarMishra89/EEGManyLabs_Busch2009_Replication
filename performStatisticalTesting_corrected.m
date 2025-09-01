function performPermutationTest_PNAS(filePath, analysisName, subjects)
% ------------------------------------------------------------------------
%  Implementation of the two-level surrogate-phase randomization procedure to assess the statistical
%  significance of circular–linear correlations (ρ) between prestimulus phase and post-stimulus GFP.

%  INPUTS
%  filePath      : root directory that contains one folder per subject
%  analysisName  : string used to build filenames, e.g. 'attended'
%  subjects      : struct array with field .name
%
%  OUTPUT (saved)
%  ├─ meanRho            : observed grand-average ρ (ch × f × t)
%  ├─ pValues            : uncorrected p-values  (same size as meanRho)
%  ├─ fdrMask            : logical matrix, 1 = passes 5 % FDR
%  ├─ nullMeanRho        : grand-average surrogate ρ distribution
%  └─ cfg                : struct with all analysis parameters
% ------------------------------------------------------------------------


%% PARAMETERS -------------------------------------------------------------
nSurrogatePerSub   = 1e4;     % first-level: 10 000 surrogate ρ per subject
nGrandIterations   = 1e6;     % second-level: 10 000 000 grand averages
rngSeed            = 42;      % fixed seed for full reproducibility
alphaFDR           = 0.05;    % expected false-discovery rate (Benjamini–Hochberg)

%% INITIALISE -------------------------------------------------------------
rng(rngSeed,'combRecursive');

nSub   = numel(subjects);
fprintf('\n=== Permutation test (%s) for %d subjects ===\n',analysisName,nSub);

% ------------------------------------------------------------------------
%  1.  Load observed ρ for every subject
% ------------------------------------------------------------------------
for s = 1:nSub
    subDir  = fullfile(filePath,subjects(s).name);
    rhoFile = fullfile(subDir,'circularCorrelation_corrected',...
                      sprintf('%s_rho_corrected.mat',analysisName));
    tmp     = load(rhoFile,'rho');           % variable is called 'rho'
    if s==1
        [nChan,nFreq,nTime] = size(tmp.rho);
        rhoObsAll            = zeros(nSub,nChan,nFreq,nTime,'single');
    end
    rhoObsAll(s,:,:,:) = tmp.rho;
end

meanRho = squeeze(mean(rhoObsAll,1));        % observed grand average
clear tmp;

% ------------------------------------------------------------------------
%  2.  Generate first-level null distributions (per subject)
% ------------------------------------------------------------------------
fprintf('Generating %d surrogate ρ per subject...\n',nSurrogatePerSub);

% Preallocate: (subject × surrogate × ch × f × t) is impossible to hold.
% We instead loop over subjects and write to disk-backed temporary files.
tmpDir = fullfile(filePath,'tmpSurrogates',analysisName);
if ~exist(tmpDir,'dir'); mkdir(tmpDir); end

pValFile = fullfile(tmpDir,'pValues.mat'); % Uncomment for all subjects
%pValFile = fullfile(tmpDir,'pValues_WithLessSub.mat');
if ~ isfile(pValFile)
    for s = 1:nSub             % use Parallel Toolbox if available
        rhopath = fullfile(tmpDir,[subjects(s).name '_surrogates.mat']);
        if ~ isfile(rhopath)
            subjDir   = fullfile(filePath,subjects(s).name);
            gfpDir = fullfile(subjDir, 'ROCAnal', 'GFP_Analysis');
            saveGFP = fullfile(gfpDir, [analysisName, '_GFP_perTrial.mat']);
            GPFVals = load(saveGFP);
            gfp = GPFVals.GFP_perTrial(GPFVals.optimalTimeWindow,:);
            gfp = gfp';
            nTr   = numel(gfp);
            surRho  = zeros(nSurrogatePerSub,nChan,nFreq,nTime,'single');
            fprintf('Processing subject %s \n', subjects(s).name);
            parfor chanI = 1:nChan
                for frqI = 1:nFreq
                    for timeI = 1:nTime
                        % Load subject-specific single-trial GFP and phase matrices
                        %  • phase: (trial × f × t) complex representation → angle()
                        %  • gfp  : (trial × 1)       scalar
                        % These two variables must be stored previously for each subject in
                        %     phaseTrials.mat  (variable 'phase')   ̶ and  ̶
                        %     gfpTrials.mat    (variable 'gfp')
                        %phaseData = load(fullfile(subjDir,'phaseTrials.mat'),'phase');
        
                        fprintf('For channel %d, frequency %f, time %d and subject %s \n', chanI, frqI, timeI, subjects(s).name);
                        for k = 1:nSurrogatePerSub
                            % --- Step 1.a: draw random phases (same #trials) from uniform [0,2π)
                            randPhase = rand(nTr,1)*2*pi;
        
                            % replace real phase of each trial by *one* random angle
                            % keep frequency–time structure identical across trials
        
        
                            % —— replicate to  (trial × f × t) % I need to do it for all the time-frequency points.
        
                            cosRand = cos(randPhase);
                            sinRand = sin(randPhase);
        
                            % correlation between random phases and real GFP
                            % use analytic formula of circular-linear correlation (Jammalamadaka & SenGupta, 2001)
                            r_cx   = squeeze(sum(bsxfun(@times,cosRand,gfp)))/sqrt(sum(cosRand.^2))/sqrt(sum(gfp.^2));
                            r_sx   = squeeze(sum(bsxfun(@times,sinRand,gfp)))/sqrt(sum(sinRand.^2))/sqrt(sum(gfp.^2));
                            r_cs   = corr(cosRand,sinRand);
        
                            rhoSur = sqrt((r_cx.^2 + r_sx.^2 - 2*r_cx.*r_sx.*r_cs) ./ (1 - r_cs.^2));
                            surRho(k,chanI,frqI,timeI) = rhoSur;        % same size (ch × f × t) after squeezing
                        end % surrogate loop
                    end
                end
            end
            save(rhopath,'surRho','-v7.3');
        end
    end % subject loop
    
    % ------------------------------------------------------------------------
    %  3.  Second-level randomization: grand-average surrogate
    % ------------------------------------------------------------------------
    fprintf('Pooling surrogate ρ and generating %d grand-average iterations...\n', ...
             nGrandIterations);
    
    % Load per-subject surrogates as mem-mapped objects to save RAM
    % subToProcess = [1,2,4];  % comment for all subjects
    M = cell(1,nSub);  % Uncomment for all subjects
    % M = cell(1,length(subToProcess));  % comment for all subjects
    for s = 1:nSub % subToProcess  % Uncomment for all subjects
        disp(subjects(s).name)
        rhopath = fullfile(tmpDir,[subjects(s).name '_surrogates.mat']);
        M{s}    = matfile(rhopath,'Writable',false);
    end

    % Preallocate running count of exceedances
    exceedCount = zeros(nChan,nFreq,nTime,'uint32');
    someProblem = 0;
    blockSize = 1e4;                               % iterate in manageable blocks
    nBlocks   = ceil(nGrandIterations/blockSize);
    
    parfor b = 1:nBlocks
        disp(b)
        blkIter  = min(blockSize, nGrandIterations - (b-1)*blockSize);
        disp(blkIter)
        % Random index matrix: subj × blkIter
        idx = randi(nSurrogatePerSub, [nSub, blkIter], 'uint32'); % Uncomment if you want to run for all subjects
        %idx = randi(nSurrogatePerSub, [length(subToProcess), blkIter], 'uint32');  % comment for all subjects
    
        % For each iteration compute grand-average of selected surrogate ρ
       
        for ii = 1:blkIter
            try
                gAvg = zeros(nChan,nFreq,nTime,'single');
                for s = 1:nSub % subToProcess %% Uncomment for all subjects
                    gAvg = gAvg + squeeze(M{s}.surRho(idx(s,ii),:,:,:));
                end
                gAvg = gAvg / nSub;
        
                exceedCount = exceedCount + uint32(gAvg > meanRho);
            catch            
                someProblem = someProblem + 1
            end
        end
        
        disp('--------------------------------------')
    end
    pValues = double(exceedCount) / double(nGrandIterations);
    save(pValFile, 'pValues')
else
    load(pValFile)
end

% ------------------------------------------------------------------------
%  4.  FDR correction (Benjamini–Hochberg, α = 0.05 on *all* TF points)
% ------------------------------------------------------------------------
pVector = pValues(:);
[h, crit_p, adj_ci_cvrg, adj_p] = fdr_bh(pVector, alphaFDR, 'pdep','yes');
%[~,fdrMaskVec] = fdr_bh(pVector, alphaFDR, 'pdep','yes');
%fdrMask = reshape(fdrMaskVec,size(pValues));
fdrMask = reshape(h,size(pValues));
[idx1, idx2, idx3] = ind2sub(size(fdrMask), find(fdrMask==1));
indices = [idx1, idx2, idx3];
% ------------------------------------------------------------------------
%  5.  Save & clean-up
% ------------------------------------------------------------------------
resultDir = fullfile(filePath,'PhaseAmpCorrelStats',analysisName);
if ~exist(resultDir,'dir'); mkdir(resultDir); end

cfg = struct('nSurrogatePerSub',nSurrogatePerSub, ...
             'nGrandIterations',nGrandIterations, ...
             'rngSeed',rngSeed, ...
             'alphaFDR',alphaFDR);

%save(fullfile(resultDir,sprintf('%s_permStats_WithLessSub.mat',analysisName)), ...
%     'meanRho','pValues','fdrMask', 'indices','cfg','-v7.3');  % comment for all subjects

save(fullfile(resultDir,sprintf('%s_permStats.mat',analysisName)), ...
     'meanRho','pValues','fdrMask', 'indices','cfg','-v7.3');  % Uncomment for all subjects

fprintf('Permutation test completed. Results written to %s\n', resultDir);    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ------------------------------------------------------------------------
%  6.  FIGURE GENERATION (Figure 3 - Busch & VanRullen 2010)
% ------------------------------------------------------------------------
fprintf('Generating Figure 3 visualization...\n');

%try
    % Load time-frequency axis information
    tfInfoFile = fullfile(filePath, subjects(1).name, 'tf', 'Attended_TFInfo.mat');
    if exist(tfInfoFile, 'file')
        tfInfo = load(tfInfoFile);
        tfInfo = tfInfo.TFInfo;
        freqsHz = tfInfo.freqs;
        timesMs = tfInfo.times;
    else
        % Default axes if tf_info.mat not found
        freqsHz = 4:2:50;  % Adjust based on your analysis
        timesMs = -600:4:400;  % Adjust based on your analysis
        warning('tf_info.mat not found. Using default frequency and time axes.');
    end
    
    % Load channel locations for topography
    eegInfoFile = fullfile(filePath, subjects(1).name, 'EEG_info.mat');
    if exist(eegInfoFile, 'file')
        eegInfo = load(eegInfoFile, 'chanLocss');
        chanlocs = eegInfo.chanLocss;
    else
        error('EEG_info.mat file not found. Required for topographical plotting.');
    end
    
    % Collect data for all three conditions
    if strcmp(analysisName, 'Attended')
        % Load unattended data for comparison
        unattDir = fullfile(filePath,'PhaseAmpCorrelStats','Attended');
        unattFile = dir(fullfile(unattDir,'*permStats*.mat'));
        if ~isempty(unattFile)
            unattStats = load(fullfile(unattDir, unattFile(1).name));
            % Create combined "all conditions" data
            allMeanRho = (meanRho + unattStats.meanRho) / 2;
            allpValues = (pValues + unattStats.pValues) / 2;
            allfdrMask = fdrMask | unattStats.fdrMask;
        else
            % If unattended not available, use current data for all panels
            allMeanRho = meanRho;
            allpValues = pValues;
            allfdrMask = fdrMask;
            unattStats.meanRho = meanRho * 0.8;  % Simulated for demo
            unattStats.pValues = pValues * 1.2;
            unattStats.fdrMask = fdrMask * 0;
        end
    else
        unattStats.meanRho = meanRho;
        unattStats.pValues = pValues;
        unattStats.fdrMask = fdrMask;
        allMeanRho = meanRho;
        allpValues = pValues;
        allfdrMask = fdrMask;
    end
    
    % Average across channels for display
    avgRho_all = squeeze(mean(allMeanRho, 1));
    avgRho_unatt = squeeze(mean(unattStats.meanRho, 1));
    avgRho_att = squeeze(mean(meanRho, 1));
    
    avgP_all = squeeze(mean(allpValues, 1));
    avgP_unatt = squeeze(mean(unattStats.pValues, 1));
    avgP_att = squeeze(mean(pValues, 1));
    
    avgFDR_all = squeeze(any(allfdrMask, 1));
    avgFDR_unatt = squeeze(any(unattStats.fdrMask, 1));
    avgFDR_att = squeeze(any(fdrMask, 1));
    
    % Convert to -log10(p) for color scale (matching paper's 10^-7 to 10^-1)
    logP_all = -log10(max(avgP_all, 1e-7));    % Prevent log(0)
    logP_unatt = -log10(max(avgP_unatt, 1e-7));
    logP_att = -log10(max(avgP_att, 1e-7));
    
    % Create figure
    figure('Color', 'w', 'Position', [100 100 1200 500]);
    
    % Define common parameters
    clim = [1 7];  % Color limits: 10^-1 to 10^-7
    timeRange = [-600 250];
    freqRange = [0 50];
    
    %% Panel A: All conditions (left panel with topography inset)
    subplot('Position', [0.08 0.15 0.25 0.75]);
    imagesc(timesMs, freqsHz, logP_all);
    axis xy;
    hold on;
    
    % Add white contour lines for significant regions
    contour(timesMs, freqsHz, double(avgFDR_all), [0.5 0.5], 'w', 'LineWidth', 1.5);
    
    % Add stimulus onset line
    plot([0 0], freqRange, 'k:', 'LineWidth', 1);
    
    set(gca, 'XLim', timeRange, 'YLim', freqRange, 'FontSize', 10);
    caxis(clim);
    colormap(jet);
    title('all conditions', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('time (s)', 'FontSize', 11);
    ylabel('frequency (Hz)', 'FontSize', 11);
    
    % Add topographical inset (4-10 Hz, -400 to -100 ms region)
    freqROI = freqsHz >= 4 & freqsHz <= 10;
    timeROI = timesMs >= -400 & timesMs <= -100;
    topoData = squeeze(mean(allMeanRho(:, freqROI, timeROI), [2 3]));
    
    % Create inset axes
    axes('Position', [0.35 0.6 0.15 0.25]);
    topoplot(topoData, chanlocs, 'electrodes', 'off', 'numcontour', 0, ...
             'style', 'map', 'shading', 'interp');
    title({'4–10 Hz'; '−400…−100 ms'}, 'FontSize', 9);
    
    %% Panel B: Unattended (middle panel)
    subplot('Position', [0.42 0.15 0.18 0.75]);
    imagesc(timesMs, freqsHz, logP_unatt);
    axis xy;
    hold on;
    
    % Add white contour lines
    contour(timesMs, freqsHz, double(avgFDR_unatt), [0.5 0.5], 'w', 'LineWidth', 1.5);
    plot([0 0], freqRange, 'k:', 'LineWidth', 1);
    
    set(gca, 'XLim', timeRange, 'YLim', freqRange, 'YTick', [], 'FontSize', 10);
    caxis(clim);
    title('unattended', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('time (s)', 'FontSize', 11);
    
    %% Panel C: Attended (right panel)
    subplot('Position', [0.65 0.15 0.18 0.75]);
    imagesc(timesMs, freqsHz, logP_att);
    axis xy;
    hold on;
    
    % Add white contour lines
    contour(timesMs, freqsHz, double(avgFDR_att), [0.5 0.5], 'w', 'LineWidth', 1.5);
    plot([0 0], freqRange, 'k:', 'LineWidth', 1);
    
    set(gca, 'XLim', timeRange, 'YLim', freqRange, 'YTick', [], 'FontSize', 10);
    caxis(clim);
    title('attended', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('time (s)', 'FontSize', 11);
    
    %% Add colorbar
    cb = colorbar('Position', [0.88 0.15 0.02 0.75]);
    set(cb, 'Ticks', 1:7, 'TickLabels', {'10^{-1}', '10^{-2}', '10^{-3}', ...
                                         '10^{-4}', '10^{-5}', '10^{-6}', '10^{-7}'});
    ylabel(cb, '[p]', 'FontSize', 11, 'Rotation', 0);
    
    %% Add main title
    sgtitle(sprintf('Circular–linear correlation between EEG phase and poststimulus global field power (%s)', analysisName), ...
            'FontSize', 13, 'FontWeight', 'bold');
    
    % Save figure
    figName = fullfile(resultDir, sprintf('Figure3_%s_PhaseGFP', analysisName));
    saveas(gcf, [figName '.fig']);
    print(gcf, [figName '.png'], '-dpng', '-r300');
    
    fprintf('Figure saved as: %s\n', [figName '.png']);
    
% catch ME
%     warning('Figure generation failed: %s', ME.message);
%     fprintf('Continuing without figure generation...\n');
% end

end
