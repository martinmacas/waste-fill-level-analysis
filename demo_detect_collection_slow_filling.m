%demo_detect_collection_slow_filling.m
% 
% The demonstration of the detection of slowly filling waste (coloured glass) collections.
%This demonstrates the collection schedules identification, splitting the
%signal into intervals with different collections schedules and detection
%of collection using simple thresholding and supervised classifier
%%
clear; clc;

%% Configuration
dataFolder = 'Data_1_bsklo';

%% Load file list
files = dir(dataFolder);

%% Process each file
for fileIdx = 7:numel(files)

    fprintf('Processing file %d/%d\n', fileIdx, numel(files));
    close all;

    %% Load data
    filePath = fullfile(files(fileIdx).folder, files(fileIdx).name);
    load(filePath);  % expects variables: Time, p

    % Sort data chronologically
    [time, sortIdx] = sort(Time);
    fillLevel = p(sortIdx);

    timeAll = time;
    fillLevelAll = fillLevel;

    %% Initial detection (rough estimation of collections)
    %collectionsInitial = detect_collections_thresholding(timeAll, fillLevelAll, []);
    collectionsInitial = detect_collections_supervised_bsklo(timeAll, fillLevelAll, [], []);


    %% Detect schedule change points and stable intervals (special arguments used)
    [schedules, idxStart, idxEnd] = ...
        detect_changepoints_periodical(timeAll, fillLevelAll, collectionsInitial,'tol_period',48,'tol_missing',3);

    %% Initialize analysis structure
    analysis = struct([]);

    %% Visualization setup
    figure('WindowState', 'maximized');
    plot(timeAll, fillLevelAll, 'k:', 'LineWidth', 1);
    hold on;

    %% Process each detected interval
    for intervalIdx = 1:numel(idxStart)

        % Extract interval data
        idxRange = idxStart(intervalIdx):idxEnd(intervalIdx);
        timeInterval = timeAll(idxRange);
        fillInterval = fillLevelAll(idxRange);

        %% Store interval metadata
        analysis(intervalIdx).period        = intervalIdx;
        analysis(intervalIdx).idxStart      = idxStart(intervalIdx);
        analysis(intervalIdx).idxEnd        = idxEnd(intervalIdx);
        analysis(intervalIdx).timeStart     = timeInterval(1);
        analysis(intervalIdx).timeEnd       = timeInterval(end);
        analysis(intervalIdx).durationDays  = days(timeInterval(end) - timeInterval(1));
        analysis(intervalIdx).numSamples    = numel(timeInterval);
        analysis(intervalIdx).schedule      = schedules{intervalIdx};

        %% Check if interval is suitable for analysis
        isLongEnough = analysis(intervalIdx).durationDays > 3*schedules{intervalIdx}(1)*7 && ...
                       analysis(intervalIdx).numSamples > 300;

        analysis(intervalIdx).isLongEnough = isLongEnough;

        if ~isLongEnough
            continue;
        end

        %% Run detection methods
        [cThresh, ~, ~, ~] = detect_collections_thresholding( ...
            timeInterval, fillInterval, [], schedules{intervalIdx});

        Time_expected = expected_collection_times(timeInterval(cThresh), schedules{intervalIdx}); 
    
        [cSupervised, ~, ~, ~] = detect_collections_supervised_bsklo( ...
            timeInterval, fillInterval, [], Time_expected);

        %% Evaluate disagreement between methods
        disagreementCount = sum(xor(cThresh, cSupervised));
        agreementCount    = sum(cThresh & cSupervised);

        if (agreementCount + disagreementCount) > 0
            disagreementRatio = disagreementCount / (agreementCount + disagreementCount);
        else
            disagreementRatio = 0;
        end

        preCollectionLevel = median(fillInterval(cSupervised));

        fprintf('Interval %d:\n', intervalIdx);
        fprintf('  Disagreement ratio: %.3f\n', disagreementRatio);

        if disagreementCount > 0
            fprintf('  cThresh only: %.2f%%\n', ...
                100 * sum(cThresh & ~cSupervised) / disagreementCount);
            fprintf('  cSupervised only: %.2f%%\n', ...
                100 * sum(~cThresh & cSupervised) / disagreementCount);
        end

        fprintf('  Median pre-collection level: %.2f\n', preCollectionLevel);

        %% Detect missing collections (if schedule exists)
        missingIdx = [];
        scheduledTimes = [];

        if ~isempty(schedules{intervalIdx})
            [missingIdx, scheduledTimes] = detect_missing_collection_periodical( ...
                timeInterval, fillInterval, cSupervised, schedules{intervalIdx}, 48);
        end
        

        %% Plot signal
        plot(timeInterval, fillInterval, '.-', 'LineWidth', 1);

        % Plot detections
        plot(timeInterval(cThresh), fillInterval(cThresh), 's', ...
            'MarkerFaceColor', [0.9290 0.6940 0.1250], 'MarkerSize', 12);

        plot(timeInterval(cSupervised), fillInterval(cSupervised), 's', ...
            'MarkerFaceColor', [0.4660 0.6740 0.1880], 'MarkerSize', 8);

       
        %% Plot scheduled collections
          if ~isempty(schedules{intervalIdx})
            
             % Highlight missing collections
            if ~isempty(missingIdx)
                plot(timeInterval(missingIdx), fillInterval(missingIdx), ...
                    'rx', 'MarkerSize', 12, 'LineWidth', 2);
            end

%             schedule = schedules{intervalIdx};
% 
%             scheduledTimes = ( ...
%                 dateshift(timeInterval(1), 'start', 'week') + days(1) + ...
%                 hours(schedule * 168) + ...
%                 7 * days(0:round(hours(timeInterval(end) - timeInterval(1)) / 168))' ...
%             )';
% 
%             scheduledTimes = scheduledTimes(:);

            % Plot schedule lines
            plot([Time_expected Time_expected]', ...
                repmat([0 100], numel(Time_expected), 1)', ...
                '-', 'Color', [0.4660 0.6740 0.1880]);


        end

        %% Axis formatting
        xticks(dateshift(min(timeAll), 'start', 'day'):hours(24): ...
               dateshift(max(timeAll), 'end', 'day'));

        datetick('x', 'dd.mm. ddd', 'keepticks');
        ylim([-10 120]);

        %% Store statistics
        analysis(intervalIdx).numCollections = sum(cSupervised);

        if ~isempty(scheduledTimes)
            analysis(intervalIdx).missingCount = numel(missingIdx);
            analysis(intervalIdx).missingRatio = ...
                100 * numel(missingIdx) / numel(scheduledTimes);
        else
            analysis(intervalIdx).missingCount = 0;
            analysis(intervalIdx).missingRatio = 0;
        end

    end

    %% Final plot formatting
    if exist("missingIdx")
        if ~isempty(missingIdx)    
            legend('Whole fill level signal','Signal in detected interval', 'Thresholding', 'Supervised classifier','Missing collections', 'Scheduled collection');
        else
            legend('Whole fill level signal','Signal in detected interval', 'Thresholding', 'Supervised classifier','Scheduled collection');
        end
    end
    disp('Press a key to continue to the next signal...');
pause
end