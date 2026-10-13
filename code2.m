
%% ACCURACY-RANGE ANALYSIS OF IoT ANOMALY DETECTION STUDIES
% Manuscript: A PRISMA-Based Critical Analysis of Smart Anomaly
% Detection Frameworks: Performance Trends, Research Gaps and Future Directions
%
% SOURCE:
% Pasted text(14).txt - DOI and reported Key Results supplied for review.
%
% ACCURACY BANDS:
% 80-89%, 90-94%, 95-97%, 98-100%
%
% IMPORTANT:
% This script performs preliminary extraction from reported text.
% Verify extracted values against the original papers before publication.
% Studies without a clearly detected accuracy are marked unassigned.

clear;
clc;
close all;

%% 1. INPUT AND OUTPUT PATHS
inputFile = 'Pasted text(14).txt';
outputDir = 'Accuracy_Range_Results';

if ~isfile(inputFile)
    error(['Input file not found: ' inputFile newline ...
        'Place Pasted text(14).txt in the current MATLAB folder.']);
end

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% 2. READ SOURCE FILE
rawText = fileread(inputFile);
lines = splitlines(string(rawText));
lines = strtrim(lines);
lines(lines == "") = [];

% DOI patterns
doiPattern = ...
    '(10\.\d{4,9}/[-._;()/:A-Z0-9]+)';

% Store results
DOI = strings(0,1);
ReportedResult = strings(0,1);
Accuracy = zeros(0,1);
AccuracyRange = strings(0,1);
ExtractionNote = strings(0,1);

%% 3. EXTRACT DOI AND KEY RESULTS
for i = 1:numel(lines)

    currentLine = lines(i);

    doiTokens = regexp(char(currentLine), ...
        doiPattern, 'match', 'ignorecase');

    if isempty(doiTokens)
        continue;
    end

    % Use the first DOI found on the line
    currentDOI = string(doiTokens{1});

    % Remove trailing punctuation from DOI
    currentDOI = regexprep(currentDOI, '[.,;]+$', '');

    % Extract reported accuracy percentages
    % This is a text-based extraction and requires source verification.
    percentTokens = regexp(char(currentLine), ...
        '(\d+(?:\.\d+)?)\s*%', 'tokens');

    detectedValues = [];

    for j = 1:numel(percentTokens)

        value = str2double(percentTokens{j}{1});

        if isfinite(value) && value >= 0 && value <= 100
            detectedValues(end+1) = value; %#ok<SAGROW>
        end
    end

    % Identify values explicitly associated with accuracy
    % rather than treating every percentage as accuracy.
    lowerLine = lower(char(currentLine));

    accuracyValues = [];

    if contains(lowerLine, 'accuracy') || ...
       contains(lowerLine, 'accurate')

        % Prefer percentages near the word "accuracy".
        % A manual check is still needed for ambiguous sentences.
        for j = 1:numel(detectedValues)
            val = detectedValues(j);

            % Retain candidate values; note that another percentage
            % on the same line might refer to a different metric.
            if val >= 80 && val <= 100
                accuracyValues(end+1) = val; %#ok<SAGROW>
            end
        end
    end

    % Skip lines without a numerical accuracy candidate.
    % Keep these references in a separate audit file below.
    if isempty(accuracyValues)
        continue;
    end

    % Rule: use the highest detected accuracy on the line.
    % Verify this rule against the original study before publication.
    selectedAccuracy = max(accuracyValues);

    % Assign accuracy band
    if selectedAccuracy >= 80 && selectedAccuracy < 90
        rangeLabel = "80-89%";

    elseif selectedAccuracy >= 90 && selectedAccuracy < 95
        rangeLabel = "90-94%";

    elseif selectedAccuracy >= 95 && selectedAccuracy < 98
        rangeLabel = "95-97%";

    elseif selectedAccuracy >= 98 && selectedAccuracy <= 100
        rangeLabel = "98-100%";

    else
        rangeLabel = "Outside selected ranges";
    end

    DOI(end+1,1) = currentDOI; %#ok<SAGROW>
    ReportedResult(end+1,1) = currentLine; %#ok<SAGROW>
    Accuracy(end+1,1) = selectedAccuracy; %#ok<SAGROW>
    AccuracyRange(end+1,1) = rangeLabel; %#ok<SAGROW>
    ExtractionNote(end+1,1) = ...
        "Automatically extracted; verify original paper"; %#ok<SAGROW>
end

%% 4. REMOVE DUPLICATE DOI ENTRIES
% If a DOI appears more than once, retain the first extracted record.
if ~isempty(DOI)
    [~, uniqueIndex] = unique(lower(DOI), 'stable');

    DOI = DOI(uniqueIndex);
    ReportedResult = ReportedResult(uniqueIndex);
    Accuracy = Accuracy(uniqueIndex);
    AccuracyRange = AccuracyRange(uniqueIndex);
    ExtractionNote = ExtractionNote(uniqueIndex);
end

%% 5. CREATE REFERENCE-LEVEL AUDIT TABLE
if isempty(DOI)
    error(['No numerical accuracy values were extracted. ' ...
        'Check the format of the source text file.']);
end

AuditTable = table(DOI, Accuracy, AccuracyRange, ...
    ReportedResult, ExtractionNote, ...
    'VariableNames', {'DOI','AccuracyPercent','AccuracyRange', ...
    'ReportedKeyResult','VerificationNote'});

writetable(AuditTable, ...
    fullfile(outputDir, 'accuracy_reference_audit.csv'));

%% 6. COUNT PAPERS IN EACH ACCURACY RANGE
rangeNames = ["80-89%"; "90-94%"; "95-97%"; "98-100%"];

paperCounts = zeros(numel(rangeNames),1);
paperPercentages = zeros(numel(rangeNames),1);

for i = 1:numel(rangeNames)
    paperCounts(i) = sum(AccuracyRange == rangeNames(i));
end

totalAssigned = sum(paperCounts);

if totalAssigned > 0
    paperPercentages = 100 * paperCounts / totalAssigned;
end

SummaryTable = table(rangeNames, paperCounts, paperPercentages, ...
    'VariableNames', {'AccuracyRange','NumberOfPapers','Percentage'});

writetable(SummaryTable, ...
    fullfile(outputDir, 'accuracy_range_summary.csv'));

%% 7. DISPLAY COUNTS
fprintf('\n====================================================\n');
fprintf('IoT ANOMALY DETECTION: ACCURACY-RANGE ANALYSIS\n');
fprintf('====================================================\n');

fprintf('Unique DOI records with extracted accuracy: %d\n', ...
    height(AuditTable));

fprintf('\nAccuracy-range summary:\n');
disp(SummaryTable);

%% 8. PRINT DOI REFERENCES UNDER EACH RANGE
for i = 1:numel(rangeNames)

    fprintf('\n-----------------------------------------------\n');
    fprintf('ACCURACY RANGE: %s\n', char(rangeNames(i)));
    fprintf('-----------------------------------------------\n');

    idx = AccuracyRange == rangeNames(i);

    if any(idx)
        for k = find(idx)'
            fprintf('DOI: %s | Accuracy: %.2f%%\n', ...
                char(DOI(k)), Accuracy(k));
            fprintf('Key result: %s\n\n', ...
                char(ReportedResult(k)));
        end
    else
        fprintf('No papers assigned to this range.\n');
    end
end

%% 9. GENERATE BAR CHART
fig = figure('Color','w', ...
    'Name','Accuracy Range Distribution');

bar(paperCounts, 0.65);

set(gca, ...
    'XTick', 1:numel(rangeNames), ...
    'XTickLabel', cellstr(rangeNames), ...
    'FontSize', 11, ...
    'LineWidth', 1);

xlabel('Reported Detection Accuracy Range');
ylabel('Number of Studies');
title('Distribution of Reported Accuracy in Reviewed Studies');

grid on;
box on;

for i = 1:numel(paperCounts)
    text(i, paperCounts(i), sprintf('%d', paperCounts(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',11);
end

exportgraphics(fig, ...
    fullfile(outputDir, 'accuracy_range_distribution.png'), ...
    'Resolution', 300);

savefig(fig, ...
    fullfile(outputDir, 'accuracy_range_distribution.fig'));

%% 10. EXPORT REFERENCES GROUPED BY ACCURACY RANGE
for i = 1:numel(rangeNames)

    idx = AccuracyRange == rangeNames(i);
    rangeTable = AuditTable(idx,:);

    safeName = replace(rangeNames(i), "-", "_");
    safeName = replace(safeName, "%", "percent");

    outFile = fullfile(outputDir, ...
        "References_" + safeName + ".csv");

    writetable(rangeTable, outFile);
end

%% 11. FINAL SUMMARY
fprintf('\n====================================================\n');
fprintf('ANALYSIS COMPLETED\n');
fprintf('====================================================\n');
fprintf('Output folder: %s\n', outputDir);
fprintf('Files generated:\n');
fprintf('1. accuracy_reference_audit.csv\n');
fprintf('2. accuracy_range_summary.csv\n');
fprintf('3. accuracy_range_distribution.png\n');
fprintf('4. accuracy_range_distribution.fig\n');
fprintf('5. One reference CSV per accuracy range\n');

fprintf('\nIMPORTANT: Automatically extracted values are preliminary.\n');
fprintf('Check each DOI and reported metric in the original paper.\n');
