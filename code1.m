%% Journal validation: PRISMA and quantitative results
% Reconstructs only calculations directly supported by manuscript counts.
% It does not invent missing year-wise, dataset, index-category, or accuracy-bin data.
clear; clc; close all;

outDir = fullfile(pwd,'validation_outputs');
if ~exist(outDir,'dir'), mkdir(outDir); end
figDir = fullfile(outDir,'figures');
if ~exist(figDir,'dir'), mkdir(figDir); end

%% Source-reported counts
Nidentified = 203;
Nduplicates = 13;
NotherInitialExclusions = 10;
NfullTextAssessed = 180;
NfullTextExcluded = 35;
Nincluded = 145;

NafterInitial = Nidentified - Nduplicates - NotherInitialExclusions;
NcalculatedIncluded = NfullTextAssessed - NfullTextExcluded;

assert(NafterInitial == NfullTextAssessed, 'PRISMA initial-stage mismatch.');
assert(NcalculatedIncluded == Nincluded, 'PRISMA included-study mismatch.');

%% Metric counts as reported in manuscript
metricNames = {'Accuracy','Energy consumption','Network lifetime', ...
               'Computational overhead','All four simultaneously'};
metricCounts = [93 22 20 20 4];

CER = 100 * metricCounts(5) / Nincluded;
RGC = 100 * (Nincluded - metricCounts(5)) / Nincluded;

% Step-by-step validation output
fprintf('PRISMA: 203 - 13 - 10 = %d (reported 180)\\n', NafterInitial);
fprintf('Included: 180 - 35 = %d (reported 145)\\n', NcalculatedIncluded);
fprintf('CER: (4/145)*100 = %.6f%%; standard 2dp = %.2f%%\\n', CER, round(CER,2));
fprintf('RGC: (141/145)*100 = %.6f%%; standard 2dp = %.2f%%\\n', RGC, round(RGC,2));
fprintf('CER + RGC = %.6f%%\\n', CER+RGC);
fprintf('Manuscript body reports CER=2.75%% and RGC=97.25%%; check rounding/definitions.\\n');
fprintf('Conclusion reports 5.63%% for all-four studies; inconsistent with 4/145.\\n');

%% Save machine-readable tables
prismaStage = ["Records identified";"Duplicates removed";"Other initial exclusions"; ...
    "Records after initial screening";"Full-text excluded";"Included studies"];
prismaCount = [Nidentified;Nduplicates;NotherInitialExclusions;NafterInitial;NfullTextExcluded;Nincluded];
writetable(table(prismaStage,prismaCount,'VariableNames',{'Stage','Count'}), ...
    fullfile(outDir,'prisma_counts.csv'));

metric = string(metricNames(:));
count = metricCounts(:);
percentOfIncluded = 100*count/Nincluded;
writetable(table(metric,count,percentOfIncluded, ...
    'VariableNames',{'Metric','StudyCount','PercentOfIncludedStudies'}), ...
    fullfile(outDir,'metric_counts_and_shares.csv'));

auditItem = ["Initial PRISMA arithmetic";"Included-study arithmetic";"CER";"RGC";"Conclusion all-four percentage"];
reported = ["180";"145";"2.75%";"97.25%";"5.63%"];
calculated = [string(NafterInitial);string(NcalculatedIncluded); ...
    string(sprintf('%.6f%%',CER));string(sprintf('%.6f%%',RGC)); ...
    string(sprintf('4/145 = %.6f%%',CER))];
status = ["PASS";"PASS";"CHECK: rounds to 2.76%"; ...
    "CHECK: rounds to 97.24%";"CONFLICT: does not match 4/145"];
writetable(table(auditItem,reported,calculated,status, ...
    'VariableNames',{'Item','ManuscriptReported','Recalculated','Status'}), ...
    fullfile(outDir,'numerical_audit.csv'));

%% Figure 1: PRISMA count flow
f=figure('Color','w','Position',[100 100 900 700]); axis off;
x=0.18; w=0.56; h=0.105; ys=[0.82 0.66 0.50 0.34 0.18];
labels={sprintf('Records identified: n = %d',Nidentified), ...
    sprintf('After initial exclusions: n = %d',NafterInitial), ...
    sprintf('Full-text assessed: n = %d',NfullTextAssessed), ...
    sprintf('Full-text excluded: n = %d',NfullTextExcluded), ...
    sprintf('Studies included: n = %d',Nincluded)};
for k=1:numel(ys)
    annotation('textbox',[x ys(k) w h],'String',labels{k}, ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'EdgeColor','black','BackgroundColor','white','FitBoxToText','off');
end
for k=1:numel(ys)-1
    annotation('arrow',[x+w/2 x+w/2],[ys(k)-0.005 ys(k+1)+h+0.005], ...
        'LineWidth',1.1);
end
annotation('textbox',[0.77 0.63 0.20 0.16], ...
    'String',sprintf('Initial removals:\\n%d duplicates\\n%d other exclusions',Nduplicates,NotherInitialExclusions), ...
    'EdgeColor','none','HorizontalAlignment','left');
annotation('textbox',[0.77 0.30 0.20 0.10], ...
    'String',sprintf('Eligibility exclusions: %d',NfullTextExcluded), ...
    'EdgeColor','none','HorizontalAlignment','left');
sgtitle('PRISMA flow reconstructed from reported counts');
saveas(f,fullfile(figDir,'Figure_PRISMA_Reconstructed.png'));
savefig(f,fullfile(figDir,'Figure_PRISMA_Reconstructed.fig'));

%% Figure 2: counts reported in manuscript
f=figure('Color','w','Position',[100 100 1000 550]);
bar(metricCounts,'FaceColor',[0.65 0.65 0.65],'EdgeColor','black');
set(gca,'XTick',1:numel(metricNames),'XTickLabel',metricNames);
xtickangle(20); ylabel('Number of studies');
title('Reported evaluation dimensions'); grid on; box off;
for k=1:numel(metricCounts)
    text(k,metricCounts(k)+1,num2str(metricCounts(k)), ...
        'HorizontalAlignment','center');
end
ylim([0 max(metricCounts)*1.2]);
saveas(f,fullfile(figDir,'Figure_Evaluation_Coverage.png'));
savefig(f,fullfile(figDir,'Figure_Evaluation_Coverage.fig'));

%% Figure 3: recalculated CER and RGC
f=figure('Color','w','Position',[100 100 850 500]);
bar([CER RGC],'FaceColor',[0.65 0.65 0.65],'EdgeColor','black');
set(gca,'XTick',1:2,'XTickLabel',{'CER','RGC'});
ylabel('Percent'); ylim([0 105]); title('Recalculated coverage ratios'); grid on; box off;
text(1,CER+2,sprintf('%.4f%%',CER),'HorizontalAlignment','center');
text(2,RGC+2,sprintf('%.4f%%',RGC),'HorizontalAlignment','center');
saveas(f,fullfile(figDir,'Figure_CER_RGC_Recalculated.png'));
savefig(f,fullfile(figDir,'Figure_CER_RGC_Recalculated.fig'));

%% Missing inputs needed for exact reconstruction
fid=fopen(fullfile(outDir,'SOURCE_DATA_REQUIRED.txt'),'w');
fprintf(fid,['The manuscript text reports captions for publication-index categories, dataset trends, ' ...
    'accuracy distribution, and year-wise evaluation factors, but not all underlying category/bin/year counts.\\n' ...
    'To recreate those plots faithfully, provide the row-level extraction matrix for all 145 studies, ' ...
    'with fields for publication year, index category, dataset, accuracy value/range, and metric coverage.\\n' ...
    'Do not substitute synthetic counts for observed review data.\\n']);
fclose(fid);
