%% Generate the two study-analysis graphs from CSV input files
% Required files in the same folder:
%   Pasted text(14).txt
%   Yearwise_Metric_Study_Coding.csv
%   Yearwise_Dataset_Study_Coding.csv
%
% The CSVs hold the study-analysis values from the user's supplied figures.
% The code validates/selects the correct files, then plots the data.

clear; clc; close all;

sourceFile = 'Pasted text(14).txt';
metricFile = 'Yearwise_Metric_Study_Coding.csv';
datasetFile = 'Yearwise_Dataset_Study_Coding.csv';

%% Find the DOI summary text file
if ~isfile(sourceFile)
    altSource = fullfile(scriptFolder,'Pasted text (14).txt');
    if isfile(altSource)
        sourceFile = altSource;
    else
        [f,pth] = uigetfile({'*.txt','Text file'},'Select Pasted text(14).txt');
        if isequal(f,0), error('No text file selected.'); end
        sourceFile = fullfile(pth,f);
    end
end

%% Read DOI inventory (for traceability)
raw = fileread(sourceFile);
raw = strrep(raw,sprintf('\r\n'),sprintf('\n'));
raw = strrep(raw,sprintf('\r'),sprintf('\n'));
lines = regexp(raw,'\n','split');
doiList = {};
resultList = {};
for i = 1:numel(lines)
    line = strtrim(lines{i});
    if isempty(line) || (contains(lower(line),'doi') && contains(lower(line),'key results'))
        continue;
    end
    tok = regexp(line,'(10\.\d{4,9}/[-._;()/:A-Z0-9]+)(.*)$', ...
        'tokens','once','ignorecase');
    if isempty(tok), continue; end
    doi = regexprep(strtrim(tok{1}),'[.,;]+$','');
    resultText = regexprep(strtrim(tok{2}),'^[\s\t|,:-]+','');
    idx = find(strcmpi(doi,doiList),1);
    if isempty(idx)
        doiList{end+1,1} = doi; %#ok<SAGROW>
        resultList{end+1,1} = resultText; %#ok<SAGROW>
    elseif isempty(resultList{idx}) && ~isempty(resultText)
        resultList{idx} = resultText;
    end
end
fprintf('Unique DOI records in source file: %d\n',numel(doiList));

%% Load metric CSV from the same folder as this script
if ~isfile(metricFile)
    [f,pth] = uigetfile({'*.csv','CSV files'}, ...
        'Select Yearwise_Metric_Study_Coding.csv');
    if isequal(f,0), error('Metric CSV not selected.'); end
    metricFile = fullfile(pth,f);
end
M = readtable(metricFile);
mNames = lower(regexprep(string(M.Properties.VariableNames),'[^a-zA-Z0-9]',''));
yearCol = find(mNames=="year",1);
energyCol = find(contains(mNames,"energy"),1);
lifetimeCol = find(contains(mNames,"lifetime"),1);
overheadCol = find(contains(mNames,"overhead"),1);
accuracyCol = find(contains(mNames,"accuracy"),1);
if isempty(yearCol) || isempty(energyCol) || isempty(lifetimeCol) || ...
        isempty(overheadCol) || isempty(accuracyCol)
    error('Metric input is not the correct CSV. Use Yearwise_Metric_Study_Coding.csv from the package.');
end

metricYears = M{:,yearCol};
metricValues = [M{:,energyCol}, M{:,lifetimeCol}, M{:,overheadCol}, M{:,accuracyCol}];
metricNames = {'Energy Consumption','Network Lifetime','Computational Overhead','Accuracy'};

%% Load dataset CSV. Prefer the CSV beside this script; prompt only if absent.
if ~isfile(datasetFile)
    [f,pth] = uigetfile({'*.csv','CSV files'}, ...
        'Select Yearwise_Dataset_Study_Coding.csv (first column lists dataset names)');
    if isequal(f,0), error('Dataset CSV not selected.'); end
    datasetFile = fullfile(pth,f);
end

% Read CSV as cells first to avoid MATLAB version-dependent header rewriting.
rawCells = readcell(datasetFile);
if isempty(rawCells) || size(rawCells,2) < 3
    error('Dataset CSV is empty or does not have enough columns.');
end

headers = string(rawCells(1,:));
firstColumn = string(rawCells(2:end,1));
% Verify that first column contains dataset labels rather than numeric years.
numericFirst = str2double(firstColumn);
if all(~isnan(numericFirst))
    error(['The selected file is not the dataset CSV. Please place ' ...
        'Yearwise_Dataset_Study_Coding.csv from the supplied package in the ' ...
        'same folder as this script and run again.']);
end

datasetNames = firstColumn;
datasetYears = [];
yearCols = [];
for c = 2:size(rawCells,2)
    h = strtrim(headers(c));
    yr = str2double(h);
    if isnan(yr)
        digits = regexp(char(h),'20\d{2}','match','once');
        if ~isempty(digits), yr = str2double(digits); end
    end
    if ~isnan(yr) && yr >= 1900 && yr <= 2100
        datasetYears(end+1) = yr; %#ok<SAGROW>
        yearCols(end+1) = c; %#ok<SAGROW>
    end
end
% Fallback for MATLAB versions that read numeric headers as empty/Var names.
if isempty(yearCols)
    if size(rawCells,2)-1 == 6
        yearCols = 2:7;
        datasetYears = 2021:2026;
        fprintf('Using six count columns as years 2021–2026.\\n');
    else
        error('Dataset CSV must have Dataset followed by year counts for 2021–2026.');
    end
end
[datasetYears,order] = sort(datasetYears);
yearCols = yearCols(order);
datasetCounts = zeros(numel(datasetNames),numel(yearCols));
for r = 1:numel(datasetNames)
    for c = 1:numel(yearCols)
        value = rawCells{r+1,yearCols(c)};
        if ischar(value) || isstring(value), value = str2double(string(value)); end
        if isempty(value) || isnan(value), value = 0; end
        datasetCounts(r,c) = double(value);
    end
end
if any(datasetCounts(:) < 0) || any(datasetCounts(:) > 1000)
    error('Dataset count values are invalid. Check the dataset coding CSV.');
end

%% Figure 1: Year-wise performance metrics (grouped bars)
outDir = fullfile(pwd,'Study_Analysis_Graphs');
if ~exist(outDir,'dir'), mkdir(outDir); end

fig1 = figure('Color','w','Name','Year-wise Performance Metrics');
b = bar(metricYears,metricValues,'grouped','BarWidth',0.82);
colors = [0.20 0.45 0.72; 0.85 0.30 0.00; 0.93 0.68 0.00; 0.55 0.10 0.80];
hold on;
for k = 1:numel(b)
    b(k).FaceColor = colors(k,:);
    b(k).EdgeColor = [0.15 0.15 0.15];
    xx = b(k).XEndPoints; yy = b(k).YEndPoints;
    for j = 1:numel(yy)
        text(xx(j),yy(j)+0.22,sprintf('%d',round(yy(j))), ...
            'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',9);
    end
end
set(gca,'XTick',metricYears,'XTickLabel',string(metricYears),'YGrid','on','Layer','top');
xlabel('Year'); ylabel('Number of Papers');
title('Year-wise Performance Evaluation Metrics in IoT Anomaly Detection');
legend(metricNames,'Location','northwest');
ylim([0 max(metricValues,[],'all')+3]); box on; hold off;
exportgraphics(fig1,fullfile(outDir,'Fig1_Yearwise_Performance_Metrics.png'),'Resolution',300);

%% Figure 2: Year-wise dataset usage (stacked bars)
fig2 = figure('Color','w','Name','Year-wise Dataset Usage');
% Dataset rows are categories; each column is a year. Use explicit x positions
% so stacked segments are grouped under dataset names (not under year columns).
b2 = bar(1:numel(datasetNames),datasetCounts,'stacked','BarWidth',0.68);
yearColors = [0.20 0.45 0.72; 0.85 0.30 0.00; 0.93 0.68 0.00; ...
              0.55 0.10 0.80; 0.27 0.65 0.16; 0.30 0.75 0.90];
hold on;
for k = 1:numel(b2)
    b2(k).FaceColor = yearColors(mod(k-1,size(yearColors,1))+1,:);
    b2(k).EdgeColor = [0.15 0.15 0.15];
end
for d = 1:size(datasetCounts,1)
    runTotal = 0;
    for y = 1:size(datasetCounts,2)
        val = datasetCounts(d,y);
        if val > 0
            text(d,runTotal+val/2,sprintf('%d',round(val)), ...
                'HorizontalAlignment','center','VerticalAlignment','middle', ...
                'FontWeight','bold','FontSize',10,'Color','k');
        end
        runTotal = runTotal+val;
    end
end
set(gca,'XTick',1:numel(datasetNames),'XTickLabel',datasetNames, ...
    'YGrid','on','Layer','top','FontSize',10);
xlabel('Dataset'); ylabel('Number of Papers');
title('Year-wise Dataset Usage in IoT Network based Anomaly Detection');
lgd = legend(string(datasetYears),'Location','northeastoutside');
% Set the legend title separately for compatibility with older MATLAB releases.
try
    title(lgd,'Year');
catch
    % Older releases may not support legend titles; the year labels remain visible.
end
ylim([0 max(sum(datasetCounts,2))+2]);
ylabel('Number of Papers');
box on; hold off;
exportgraphics(fig2,fullfile(outDir,'Fig2_Yearwise_Dataset_Usage.png'),'Resolution',300);

%% Export exactly the data used in the figures
writetable(M,fullfile(outDir,'Metric_Coding_Used.csv'));
writecell([{'Dataset', num2cell(datasetYears)}; cellstr(datasetNames), num2cell(datasetCounts)], ...
    fullfile(outDir,'Dataset_Coding_Used.csv'));
fprintf('\nSuccess! Both graphs saved in:\n%s\n',outDir);
