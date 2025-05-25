warning('off', 'all');
clear;
robotParameters;
sensorParameters;
markParameters;
currentSimulinkPath = string(pwd);

solutionsPath = currentSimulinkPath + '/Solutions';
submissionsList = {dir(fullfile(solutionsPath, '*.slx')).name};


createMazes(markParams.addMazes)
mazesPath = currentSimulinkPath + '/Mazes';
mazesList = {dir(fullfile(mazesPath, '*.mat')).name};

if isempty(submissionsList) %End if there are no files
    return;
else
    createCSV(mazesList)

    fprintf('Starting Automarker: %s\n', datetime('now', 'Format', 'HH:MM:SS'));

    for s_idx = 1:length(submissionsList)
    
        copyfile(solutionsPath + '/' + submissionsList(s_idx), currentSimulinkPath + '/solution.slx');
        bdclose('robot');
        submission = submissionsList(s_idx);
        mode = submission{1}(end-7:end-3);
    
        for m_idx = 1:length(mazesList)
    
            copyfile(mazesPath + '/' + mazesList(m_idx), currentSimulinkPath + '/maze.mat');

            load maze.mat;
            load_system("robot.slx");

            if mode == "enco"
                vals = get_param('robot/Variable Sensor', 'MaskValues');
                vals{2} = 'Tick Encoder';
                set_param(['robot', '/Variable Sensor'], 'MaskValues', vals);
            else
                vals = get_param('robot/Variable Sensor', 'MaskValues');
                vals{2} = 'Line Follow';
                set_param(['robot', '/Variable Sensor'], 'MaskValues', vals);
            end


            vals = get_param('robot/Robot Simulator', 'MaskValues');
            vals{7} = 'False';
            set_param(['robot', '/Robot Simulator'], 'MaskValues', vals);

            try
                sim("robot.slx");
            catch simErr
                simulationParams = struct();
                simulationParams.finishTime = 0;
                simulationParams.explorationArray = 0;
                simulationParams.sen_noise_line = 0;
                simulationParams.sen_noise_dist = 0;
                simulationParams.sen_drift = 0;
                simulationParams.sen_fail_line = 0;
                simulationParams.sen_fail_dist = 0;
                simulationParams.sen_fail_var = 0;
                simulationParams.com_delay = 0;
                simulationParams.whe_slip = 0;
            end

            simulationParams = evalin('base', 'simulationParams');

            firstSim = struct();
            firstSim.finishTime = simulationParams.finishTime;
            firstSim.explorationArray = simulationParams.explorationArray;

            vals{7} = 'True';
            set_param(['robot', '/Robot Simulator'], 'MaskValues', vals);

            try
                sim("robot.slx");
            catch simErr
                simulationParams = struct();
                simulationParams.finishTime = 0;
                simulationParams.explorationArray = 0;
                simulationParams.sen_noise_line = 0;
                simulationParams.sen_noise_dist = 0;
                simulationParams.sen_drift = 0;
                simulationParams.sen_fail_line = 0;
                simulationParams.sen_fail_dist = 0;
                simulationParams.sen_fail_var = 0;
                simulationParams.com_delay = 0;
                simulationParams.whe_slip = 0;
            end

            simulationParams.finishTime1 = firstSim.finishTime;
            simulationParams.explorationArray1 = firstSim.explorationArray;

            updateCSV(submissionsList(s_idx), mazesList(m_idx))
        end
        
    end
    fprintf('Finish Automarking: %s\n', datetime('now', 'Format', 'HH:MM:SS'));

    calculateFinalScore()
    checkPlagiarism()
end

function createMazes(max)
    mazesPath = fullfile(pwd, 'Mazes');  % Adjust path if needed
    deleteMazes = dir(fullfile(mazesPath, 'maze_*'));
    
    for i = 1:length(deleteMazes)
        delete(fullfile(mazesPath, deleteMazes(i).name));
    end

    for i = 1:max
        mazeForSim = generate_maze(7, 9, 200);
        if ~exist('Mazes', 'dir')
            mkdir('Mazes');
        end
        
        % Save it as maze1.mat
        save(fullfile('Mazes', ['maze_', num2str(i), '.mat']), 'mazeForSim');
    end
end

function createCSV(mazesList)

    if exist('results.csv', 'file')
        delete('results.csv');
    end

    headers = ["Submission"];
    for i = 1:length(mazesList)
        headers = [headers, ...
            sprintf('%s complete time', mazesList{i}), ...
            sprintf('%s exploration %%', mazesList{i}), ...
            sprintf('%s Sensor Noise Line', mazesList{i}), ...
            sprintf('%s Sensor Noise Distance %%', mazesList{i}), ...
            sprintf('%s Sensor Noise Drift', mazesList{i}), ...
            sprintf('%s Sensor Fail Line %%', mazesList{i}), ...
            sprintf('%s Sensor Fail Distance', mazesList{i}), ...
            sprintf('%s Sensor Fail Variable %%', mazesList{i}), ...
            sprintf('%s Command Delay', mazesList{i}), ...
            sprintf('%s Wheel Slippage %%', mazesList{i}), ...
            sprintf('%s score', mazesList{i})];
    end
    headers = [headers, 'final Score'];
    csvPath = fullfile(pwd, 'results.csv');
    writematrix(headers, csvPath);
end

function updateCSV(submission, maze)
    csvPath = fullfile(pwd, 'results.csv');
    data = readcell(csvPath);
    headers = data(1, :);
    rows = data(2:end, :);
    
    mazeRows = evalin('base', 'mazeForSim.rows');
    mazeCols = evalin('base', 'mazeForSim.cols');

    marks = evalin('base', 'markParams');
    total = marks.sm_complete + marks.sm_explore + marks.sm_sen_noise_line + marks.sm_sen_noise_dist + marks.sm_sen_drift + marks.sm_sen_fail_line + marks.sm_sen_fail_dist + marks.sm_sen_fail_var + marks.sm_com_delay + marks.sm_whe_slip;

    finishTime1 = evalin('base', 'simulationParams.finishTime1');
    finishTime = evalin('base', 'simulationParams.finishTime');
    explorationArray1 = evalin('base', 'simulationParams.explorationArray1');
    explorationArray = evalin('base', 'simulationParams.explorationArray');
    lineNoise = evalin('base', 'simulationParams.sen_noise_line');
    distNoise = evalin('base', 'simulationParams.sen_noise_dist');
    varNoise = evalin('base', 'simulationParams.sen_drift');
    lineFail = evalin('base', 'simulationParams.sen_fail_line');
    distFail = evalin('base', 'simulationParams.sen_fail_dist');
    varFail = evalin('base', 'simulationParams.sen_fail_var');
    delay = evalin('base', 'simulationParams.com_delay');
    slip = evalin('base', 'simulationParams.whe_slip');

    exploredCells1 = explorationArray1(explorationArray1(:,1) ~= ' ', :);
    exploredCells = explorationArray(explorationArray(:,1) ~= ' ', :);
    uniqueCells1 = unique(exploredCells1, 'rows');
    uniqueCells = unique(exploredCells, 'rows');
    explorationPct1 = round(length(uniqueCells1) * 100 /(mazeRows * mazeCols));
    explorationPct = round(length(uniqueCells) * 100 /(mazeRows * mazeCols));
    
    rowIdx = find(strcmp(rows(:, 1), submission));
    
    if isempty(rowIdx)
        newRow = repmat({''}, 1, length(headers));
        newRow{1} = submission;
        rows = [rows; newRow];
        rowIdx = size(rows, 1);
    end
    for i = 1:numel(headers)
        if iscell(headers{i})
            headers{i} = headers{i}{1};
        end
    end
    
    % Flatten rows
    for i = 1:numel(rows)
        if iscell(rows{i})
            rows{i} = rows{i}{1};
        end
    end

    completionScore = 0;
    fastest_time = 0;

    if finishTime1 > 0
        completionScore = 25 + 25 * (marks.maxTime - finishTime1)/marks.maxTime;
        fastest_time = finishTime1;
    end
    if finishTime > 0
        completionScore = completionScore + 25 + 25 * (marks.maxTime - finishTime)/marks.maxTime;
        if finishTime < finishTime1
            fastest_time = finishTime;
        end
    end

    sm_complete = marks.sm_complete * completionScore / total;
    sm_explore = marks.sm_explore * ((explorationPct1 + explorationPct)/2) / total;
    sm_sen_noise_line = marks.sm_sen_noise_line *  lineNoise / total;
    sm_sen_noise_dist = marks.sm_sen_noise_dist * distNoise / total;
    sm_sen_drift = marks.sm_sen_drift * varNoise /total;
    sm_sen_fail_line = marks.sm_sen_fail_line * lineFail / total;
    sm_sen_fail_dist = marks.sm_sen_fail_dist * distFail / total;
    sm_sen_fail_var = marks.sm_sen_fail_var * varFail / total;
    sm_com_delay = marks.sm_com_delay * delay / total;
    sm_whe_slip = marks.sm_whe_slip * slip / total;
    
    baseCol = find(strcmp(headers, sprintf('%s complete time', maze{1})));

    rows{rowIdx, baseCol} = fastest_time;
    rows{rowIdx, baseCol + 1} = sm_explore;
    rows{rowIdx, baseCol + 2} = sm_sen_noise_line;
    rows{rowIdx, baseCol + 3} = sm_sen_noise_dist;
    rows{rowIdx, baseCol + 4} = sm_sen_drift;
    rows{rowIdx, baseCol + 5} = sm_sen_fail_line;
    rows{rowIdx, baseCol + 6} = sm_sen_fail_dist;
    rows{rowIdx, baseCol + 7} = sm_sen_fail_var;
    rows{rowIdx, baseCol + 8} = sm_com_delay;
    rows{rowIdx, baseCol + 9} = sm_whe_slip;
    rows{rowIdx, baseCol + 10} = sm_complete + sm_explore + sm_sen_noise_line + sm_sen_noise_dist + sm_sen_drift + sm_sen_fail_line + sm_sen_fail_dist + sm_sen_fail_var + sm_com_delay + sm_whe_slip;
    
    headers = cellfun(@(x) replaceMissing(x), headers, 'UniformOutput', false);
    rows = cellfun(@(x) replaceMissing(x), rows, 'UniformOutput', false);

    writecell([headers; rows], csvPath);
end

function calculateFinalScore()
    csvPath = fullfile(pwd, 'results.csv');
    data = readcell(csvPath);

    headers = data(1, :);
    rows = data(2:end, :);

    % Find all score columns that are not the final Score
    scoreColIdxs = find(contains(headers, 'score') & ~strcmp(headers, 'final Score'));

    % Find the index of the final Score column
    finalScoreIdx = strcmp(headers, 'final Score');

    for i = 1:size(rows, 1)
        scores = zeros(1, length(scoreColIdxs));

        for j = 1:length(scoreColIdxs)
            val = rows{i, scoreColIdxs(j)};
            if isnumeric(val)
                scores(j) = val;
            elseif ischar(val) || isstring(val)
                num = str2double(val);
                if ~isnan(num)
                    scores(j) = num;
                end
            end
        end

        % Calculate average and round to 2 decimal places
        averageScore = round(mean(scores), 2);
        rows{i, finalScoreIdx} = averageScore;
    end

    writecell([headers; rows], csvPath);
end

function checkPlagiarism()
    csvPath = fullfile(pwd, 'results.csv');
    txtPath = fullfile(pwd, 'plagiarism.txt');

    data = readcell(csvPath);
    headers = data(1, :);
    rows = data(2:end, :);

    fid = fopen(txtPath, 'w');
    if fid == -1
        error('Unable to create plagiarism.txt');
    end

    n = size(rows, 1);
    matchesFound = false;
    compared = false(n);  % To avoid repeating row comparisons

    for i = 1:n
        for j = i+1:n
            if ~compared(i, j)
                row1 = rows(i, 2:end);  % Exclude submission name
                row2 = rows(j, 2:end);

                if isequaln(row1, row2)
                    fprintf(fid, 'Plagiarism detected between %s and %s\n', rows{i, 1}, rows{j, 1});
                    matchesFound = true;
                end
                compared(i, j) = true;
                compared(j, i) = true;
            end
        end
    end

    if ~matchesFound
        fprintf(fid, 'Success, no plagiarism encountered.\n');
    end

    fclose(fid);
end

function out = replaceMissing(in)
    if ismissing(in)
        if isnumeric(in)
            out = NaN;
        else
            out = "N/A";  % Or "" if you want it blank
        end
    else
        out = in;
    end
end