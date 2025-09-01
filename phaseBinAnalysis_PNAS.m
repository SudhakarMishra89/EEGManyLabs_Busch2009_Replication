function phaseBinAnalysis_PNAS(filePath, subjects, freqIdx, timeIdx, nBins)
% -------------------------------------------------------------------------
% Implementation of bin-wise phase–GFP/perception analysis.
%
% INPUTS
%   filePath   : root directory that contains one folder per subject
%   subjects   : struct array with field .name (same as in previous funcs)
%   freqIdx    : frequency index of the significant TF point (integer)
%   timeIdx    : prestimulus time index of the significant TF point
%   nBins      : number of phase bins (set to 11 to replicate the paper)
%
% OUTPUT (saved per analysis)
%   GFPbins.mat      : (subj × att × bin) standardized GFP
%   hitRateBins.mat  : (subj × att × bin) standardized detection rate
%   ANOVA_results.mat: repeated-measures ANOVA tables for GFP & hit rate

%% SETTINGS ---------------------------------------------------------------
%roiLabels = {'F1','Fz','F2','FC1','FCz','FC3'};  % fronto-central ROI
roiLabels = {'F1','F2','FC1','FC3'};  % fronto-central ROI
binEdges  = linspace(-pi, pi, nBins+1);          % equal-width edges
centralBin = ceil(nBins/2);                      % will be dropped (== #6)

% Pre-allocate result matrices
nSub  = numel(subjects);
nAtt  = 1;                         % 1 = attended / valid, 2 = unattended / invalid
if nAtt == 1
    attNames = {'Att'};
else
    attNames = {'Att','Unatt'};
end
GFPbins     = nan(nSub,nAtt,nBins);    % standardized GFP
hitRateBins = nan(nSub,nAtt,nBins);    % standardized detection rate

%% LOOP OVER SUBJECTS -----------------------------------------------------
for s = 1:nSub
    fprintf('Subject %s (%d/%d)\n', subjects(s).name, s, nSub);
    subjDir = fullfile(filePath, subjects(s).name);

    for att = 1:nAtt
        % ---------- LOAD SINGLE-TRIAL GFP & BEHAVIOR -------------------------
        if att == 1
            gfpFile = fullfile(subjDir,'ROCAnal','GFP_Analysis', ...
                               'Attended_GFP_perTrial.mat');        % attended template
        else
            gfpFile = fullfile(subjDir,'ROCAnal','GFP_Analysis', ...
                               'Unattended_GFP_perTrial.mat');        % attended template
        end

        gfpA = load(gfpFile);                                   % contains GFP_perTrial, optimalTimeWindow
        optIdx = gfpA.optimalTimeWindow;                        % scalar (time sample)
        gfp_perTrial = gfpA.GFP_perTrial(optIdx,:).';           % (trial × 1)
        nTrials = numel(gfp_perTrial);
    
        % behavioural labels (hitMissLabels) & attention labels
        labelsFile = fullfile(subjDir,'trialIndexCond.mat');
        L = load(labelsFile);           % must contain: AttendedReport, UnAttendedReport

        if att == 1
            report = L.trialIndexCond.AttendedReport;
            %hitMiss = zeros(nTrials,1);
            %hitMiss(L.trialIndexCond.AttendedReport==1 | L.trialIndexCond.UnAttendedReport==1) = 1;
            attVec = zeros(nTrials,1);      % 1 = attended
            % Attended and unattended cannot be at the same place.
            attVec((L.trialIndexCond.AttendedReport==1)) = 1;        
        else
            report = L.trialIndexCond.UnAttendedReport;
            %hitMiss = zeros(nTrials,1);
            %hitMiss(L.trialIndexCond.AttendedReport==1 | L.trialIndexCond.UnAttendedReport==1) = 1;
            attVec = zeros(nTrials,1);      % 1 = attended
            % Attended and unattended cannot be at the same place.
            attVec((L.trialIndexCond.UnAttendedReport==1)) = 1;                    
        end
    
        % ---------- LOAD PRESTIMULUS PHASE (ROI avg) -------------------------
        roiPhase = zeros(nTrials,numel(roiLabels));             % each column a channel
        for c = 1:numel(roiLabels)
            % channel index resolved via EEG.chanlocs labels saved earlier
            if att == 1
                chanTFfile = fullfile(subjDir,'tf', sprintf('Attended_TF_%d.mat', getChanIdx(subjDir,roiLabels{c})));
            else
                chanTFfile = fullfile(subjDir,'tf', sprintf('Unattended_TF_%d.mat', getChanIdx(subjDir,roiLabels{c})));
            end
            tf = load(chanTFfile,'tf');                         % (freq × time × trials)
            roiPhase(:,c) = angle(squeeze(tf.tf(freqIdx, timeIdx, :))); % column vector
        end
        phaseVec = circ_mean(roiPhase,[],2);                    % average ROI phase per trial
    
        % ---------- BINNING --------------------------------------------------
        [~,~,binIdx] = histcounts(phaseVec,binEdges);           % 1…nBins
        % ensure no 0 indices
        binIdx(binIdx==0) = 1;
        % ---------- STANDARDISATION FACTORS ---------------------------------
        meanGFP   = mean(gfp_perTrial);
        %meanHit   = mean(hitMiss);
        % ---------- PER-ATTENTION LOOP --------------------------------------
        for b = 1:nBins
            binIndexes = find(binIdx==b);
            sel = (attVec==att) & (binIdx==b);
            if any(sel)
                GFPbins(s,att,b)     = mean(gfp_perTrial(sel))/meanGFP;
                hitRateBins(s,att,b) = sum(report(binIdx==b)==1)/length(binIndexes);
%                hitRateBins(s,att,b) = mean(hitMiss(sel))/meanHit;
            end
        end
    end

    % ---------- PHASE ALIGNMENT (shift bins) -----------------------------
    % compute mean GFP across att conditions to find maximum bin
    subjGFP = squeeze(GFPbins(s,:,:));    % att × bin
    [~,maxBin] = max(mean(subjGFP,'omitnan'));
    shift = centralBin - maxBin;
    GFPbins(s,:,:)     = circshift(subjGFP, [0, shift]);
    subjHit = squeeze(hitRateBins(s,:,:));
    hitRateBins(s,:,:) = circshift(subjHit,[0, shift]);
end

%% REMOVE CENTRAL BIN FROM STATS -----------------------------------------
keepBins = setdiff(1:nBins, centralBin);
GFPstats     = GFPbins(:,:,keepBins);
hitRateStats = hitRateBins(:,:,keepBins);

%% REPEATED-MEASURES ANOVA (within: attention × phase) -------------------
binNames = strcat('Bin',string(keepBins));

% ----- GFP Anova -----
dataMat = reshape(GFPstats,nSub,[]);        % subj × (att*bin)
tblGFP  = array2table(dataMat);
tblGFP.Subject = (1:nSub).';
within  = table(repelem(attNames,numel(keepBins))', ...
                repmat(binNames,1,nAtt)', ...
                'VariableNames',{'Attention','Phase'});
rmGFP   = fitrm(tblGFP,'Var1-Var20~1','WithinDesign',within);
anovaGFP = ranova(rmGFP,'WithinModel','Attention*Phase');

% ----- Hit Rate Anova -----
dataMat = reshape(hitRateStats,nSub,[]);
tblHit  = array2table(dataMat);
tblHit.Subject = (1:nSub).';
rmHit   = fitrm(tblHit,'Var1-Var20~1','WithinDesign',within);
anovaHit = ranova(rmHit,'WithinModel','Attention*Phase');

%% GENERATE FIGURE 4 (BUSCH & VANRULLEN 2010) ----------------------------
fprintf('\nGenerating Figure 4 replication...\n');

% Calculate means and standard errors
meanGFP_att = squeeze(mean(GFPbins(:,1,:),'omitnan'));     % attended
meanGFP_unatt = squeeze(mean(GFPbins(:,2,:),'omitnan'));   % unattended
semGFP_att = squeeze(std(GFPbins(:,1,:),'omitnan'))/sqrt(nSub);
semGFP_unatt = squeeze(std(GFPbins(:,2,:),'omitnan'))/sqrt(nSub);

meanHit_att = squeeze(mean(hitRateBins(:,1,:),'omitnan'));
meanHit_unatt = squeeze(mean(hitRateBins(:,2,:),'omitnan'));
semHit_att = squeeze(std(hitRateBins(:,1,:),'omitnan'))/sqrt(nSub);
semHit_unatt = squeeze(std(hitRateBins(:,2,:),'omitnan'))/sqrt(nSub);

% Phase angles in degrees (aligned so maximum GFP is at 0°)
phaseAngles = linspace(-150, 150, nBins);

% Create figure
fig = figure('Position', [100, 100, 1200, 500]);

% Panel A: GFP vs Phase
subplot(1,2,1);
hold on;

% Plot attended condition (blue)
h1 = errorbar(phaseAngles, meanGFP_att, semGFP_att, 'o-', ...
             'Color', [0.2 0.4 0.8], 'LineWidth', 2, 'MarkerSize', 6, ...
             'MarkerFaceColor', [0.2 0.4 0.8], 'CapSize', 4);

% Plot unattended condition (red)
h2 = errorbar(phaseAngles, meanGFP_unatt, semGFP_unatt, 's-', ...
             'Color', [0.8 0.2 0.2], 'LineWidth', 2, 'MarkerSize', 6, ...
             'MarkerFaceColor', [0.8 0.2 0.2], 'CapSize', 4);

xlabel('Prestimulus Phase (degrees)', 'FontSize', 12);
ylabel('Normalized GFP', 'FontSize', 12);
title('A. Average GFP as function of prestimulus phase', 'FontSize', 14, 'FontWeight', 'bold');
legend([h1, h2], {'Attended', 'Unattended'}, 'Location', 'best', 'FontSize', 11);
grid on; grid minor;
xlim([-160, 160]);
set(gca, 'XTick', -150:50:150, 'FontSize', 10);

% Panel B: Detection Rate vs Phase
subplot(1,2,2);
hold on;

% Plot attended condition (blue)
h3 = errorbar(phaseAngles, meanHit_att, semHit_att, 'o-', ...
             'Color', [0.2 0.4 0.8], 'LineWidth', 2, 'MarkerSize', 6, ...
             'MarkerFaceColor', [0.2 0.4 0.8], 'CapSize', 4);

% Plot unattended condition (red)
h4 = errorbar(phaseAngles, meanHit_unatt, semHit_unatt, 's-', ...
             'Color', [0.8 0.2 0.2], 'LineWidth', 2, 'MarkerSize', 6, ...
             'MarkerFaceColor', [0.8 0.2 0.2], 'CapSize', 4);

xlabel('Prestimulus Phase (degrees)', 'FontSize', 12);
ylabel('Normalized Detection Rate', 'FontSize', 12);
title('B. Average detection rate as function of prestimulus phase', 'FontSize', 14, 'FontWeight', 'bold');
legend([h3, h4], {'Attended', 'Unattended'}, 'Location', 'best', 'FontSize', 11);
grid on; grid minor;
xlim([-160, 160]);
set(gca, 'XTick', -150:50:150, 'FontSize', 10);

% Adjust layout
sgtitle('Figure 4: Phase-dependent modulation of GFP and perception (Busch & VanRullen, 2010)', ...
        'FontSize', 16, 'FontWeight', 'bold');

%% SAVE RESULTS -----------------------------------------------------------
resDir = fullfile(filePath,'phaseBinAnalysis');
if ~exist(resDir,'dir'); mkdir(resDir); end

% Save data
save(fullfile(resDir,'GFPbins.mat'),    'GFPbins','binEdges','roiLabels','centralBin');
save(fullfile(resDir,'hitRateBins.mat'),'hitRateBins','binEdges','roiLabels','centralBin');
save(fullfile(resDir,'ANOVA_results.mat'),'anovaGFP','anovaHit','within');

% Save figure
savefig(fig, fullfile(resDir,'Figure4_Busch2010.fig'));
print(fig, fullfile(resDir,'Figure4_Busch2010.png'), '-dpng', '-r300');

%% DISPLAY RESULTS --------------------------------------------------------
fprintf('\n=== STATISTICAL RESULTS ===\n');
fprintf('GFP Analysis (excluding central bin):\n');
disp(anovaGFP);

fprintf('\nHit Rate Analysis (excluding central bin):\n');
disp(anovaHit);

fprintf('\n=== EFFECT SIZES ===\n');
% Calculate effect sizes as mentioned in the paper
attended_gfp_range = max(meanGFP_att) - min(meanGFP_att);
unattended_gfp_range = max(meanGFP_unatt) - min(meanGFP_unatt);
attended_hit_range = max(meanHit_att) - min(meanHit_att);
unattended_hit_range = max(meanHit_unatt) - min(meanHit_unatt);

fprintf('GFP modulation range - Attended: %.3f, Unattended: %.3f\n', ...
        attended_gfp_range, unattended_gfp_range);
fprintf('Hit rate modulation range - Attended: %.3f, Unattended: %.3f\n', ...
        attended_hit_range, unattended_hit_range);

% Calculate phase-dependent differences (0° vs 180° bins)
central_idx = centralBin;
opposite_idx = mod(central_idx + nBins/2 - 1, nBins) + 1;

gfp_diff_att = (meanGFP_att(central_idx) - meanGFP_att(opposite_idx)) / mean(meanGFP_att);
hit_diff_att = (meanHit_att(central_idx) - meanHit_att(opposite_idx)) / mean(meanHit_att);

fprintf('Phase effect (0° vs 180°) - GFP: %.1f%%, Hit rate: %.1f%%\n', ...
        gfp_diff_att*100, hit_diff_att*100);

fprintf('\nPhase-bin analysis complete. Results stored in %s\n', resDir);
fprintf('Figure 4 saved as: %s\n', fullfile(resDir,'Figure4_Busch2010.png'));

end

% =======================  HELPER FUNCTIONS ===============================
function idx = getChanIdx(subjDir, label)
    load(fullfile(subjDir,'EEG_info.mat'),'chanLocss'); % Note: user's variable name
    idx = find(strcmpi({chanLocss.labels}, label),1,'first');
    if isempty(idx)
        error('Channel %s not found for subject in %s.',label,subjDir);
    end
end
