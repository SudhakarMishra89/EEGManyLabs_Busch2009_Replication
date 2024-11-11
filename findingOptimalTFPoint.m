function [] = findingOptimalTFPoint(filePath)
   sourceDir = fullfile(filePath, 'pValues'); 

   attended = load(fullfile(sourceDir, 'Attended_pValues_FDR.mat'));
   attended = squeeze(mean(attended.fdr_mat, 1));
   Unattended = load(fullfile(sourceDir, 'UnAttended_pValues_FDR.mat'));
   Unattended = squeeze(mean(Unattended.fdr_mat, 1));
   avg_pval_fdr = load(fullfile(sourceDir, 'Average_pValues_FDR.mat'));
   avg_pval_fdr = squeeze(mean(avg_pval_fdr.fdr_mat, 1));

end