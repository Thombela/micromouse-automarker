function mazeForSim = generate_maze(rows, cols, block_size)
    result = generate(rows, cols);
    maze = result{1};
    endBlock = result{2};
    mazeForSim = configure_maze(maze, rows, cols, block_size, endBlock);
end

function result =  generate(rows, cols)
    %disp(datetime('now'))

    % Initialize
    maze = ones(rows, cols, 4);% N = 1, E = 2, S = 3, W = 4
    coord = [1,1];
    
    % Generate the maze
    visited = coord;

    endStartx = randi([3, 7]);
    endStarty = randi([3, 7]);

    endBlockCoords = [
        endStartx, endStarty;
        endStartx+1, endStarty;
        endStartx, endStarty+1;
        endStartx+1, endStarty+1
    ];

    visited = [visited; endBlockCoords];
    for i = 0:1
        for j = 0:1
            wall1 = (i == 0) * 3 + (i == 1) * 1;
            wall2 = (j == 0) * 2 + (j == 1) * 4;
            maze(endStarty+i, endStartx+j, wall1) = 0;
            maze(endStarty+i, endStartx+j, wall2) = 0;
        end
    end
    opening = [
        endStartx, endStarty;
        endStartx+1, endStarty;
        endStartx, endStarty+1;
        endStartx+1, endStarty+1];
    while 1
        idx = randi([1, 4]);
        block = opening(idx, :);
        if(block(1) ~= 8 && block(2) ~= 8)
            break
        end
    end
    if(block(1) == endStartx && block(2) == endStarty)
        idx = 1 + 3 * (randi([0, 1]));
        pblock = (idx == 1) * [block(1), block(2)-1] + (idx == 4) * [block(1)-1, block(2)];
    elseif(block(1) == endStartx+1 && block(2) == endStarty)
        idx = randi([1, 2]);
        pblock = (idx == 1) * [block(1), block(2)-1] + (idx == 2) * [block(1)+1, block(2)];
    elseif(block(1) == endStartx && block(2) == endStarty+1)
        idx = randi([3, 4]);
        pblock = (idx == 3) * [block(1), block(2)+1] + (idx == 4) * [block(1)-1, block(2)];
    elseif(block(1) == endStartx+1 && block(2) == endStarty+1)
        idx = randi([2, 3]);
        pblock = (idx == 3) * [block(1), block(2)+1] + (idx == 2) * [block(1)+1, block(2)];
    end
    pidx = (idx == 1) * 3 + (idx == 2) * 4 + (idx == 3) * 1 + (idx == 4) * 2;
    maze(block(2), block(1), idx) = 0;
    maze(pblock(2), pblock(1), pidx) = 0;

    while size(visited, 1) < rows*cols
        result = carve_path(coord, maze, visited, rows, cols);
        visited = result{1};
        maze = result{2};
        coord = result{3};
    end
    
    for i=1:1
        maze = remove_line(maze, rows, 1, endBlockCoords);
    end
    for i=1:1
        maze = remove_line(maze, rows, cols, endBlockCoords);
    end

    result{1} = maze;
    result{2} = [block(1)-1,block(2)-1];
end

function result = carve_path(coord, maze, visited, rows, cols)
    available = get_neighours(coord(1),coord(2),rows,cols,visited);

    if ~isempty(available)
        randomIndex = randi(size(available, 1));
        next = available(randomIndex, :);
        switch next
            case 'N'
                maze(coord(2), coord(1), 1) = 0;
                coord = [coord(1),coord(2)-1];
                maze(coord(2), coord(1), 3) = 0;
            case 'E'
                maze(coord(2), coord(1), 2) = 0;
                coord = [coord(1)+1,coord(2)];
                maze(coord(2), coord(1), 4) = 0;
            case 'S'
                maze(coord(2), coord(1), 3) = 0;
                coord = [coord(1),coord(2)+1];
                maze(coord(2), coord(1), 1) = 0;
            case 'W'
                maze(coord(2), coord(1), 4) = 0;
                coord = [coord(1)-1,coord(2)];
                maze(coord(2), coord(1), 2) = 0;
        end
        visited = [visited;coord];
    else
        pos = size(visited, 1) - 1;
        coord = [visited(pos,1), visited(pos,2)];
        available = get_neighours(coord(1),coord(2),rows,cols,visited);
        i = 2;
        while isempty(available)
            pos = size(visited, 1) - i;
            if pos == 0
                break
            end
            coord = [visited(pos,1), visited(pos,2)];
            available = get_neighours(coord(1),coord(2),rows,cols,visited);
            i=i+1;
        end
        result = carve_path(coord, maze, visited, rows, cols);
        visited = result{1};
        maze = result{2};
        coord = result{3};
    end
    result = {visited, maze, coord};
end

function result = get_neighours(x, y, rows, cols, visited)
    neighbours = [];
    if x >= 0 && x <= cols && y >= 0 && y <= rows
        if x-1 >= 1 && ~any(ismember(visited,[x-1,y],'rows'))
            neighbours = [neighbours;'W'];
        end
        if y-1 >= 1 && ~any(ismember(visited,[x,y-1],'rows'))
            neighbours = [neighbours;'N'];
        end
        if y+1 <= rows && ~any(ismember(visited,[x,y+1],'rows'))
            neighbours = [neighbours;'S'];
        end
        if x+1 <= cols && ~any(ismember(visited,[x+1,y],'rows'))
            neighbours = [neighbours;'E'];
        end
    end
    result = neighbours;
end

function result = remove_line(maze, rows, cols, endBlockCoords)
    blockX = randi([1, cols]);
    blockY = randi([1, rows]);
    
    while any(ismember([blockX, blockY], endBlockCoords, 'rows'))
        blockX = randi([1, cols]);
        blockY = randi([1, rows]);
    end
    side = randi([1, 4]);
    newMaze = maze;

    if ~maze(blockY, blockX, side)
        newMaze = remove_line(maze, rows, cols, endBlockCoords);
    elseif side == 1
        if blockY - 1 == 0 || any(ismember([blockX, blockY-1], endBlockCoords, 'rows'))
            newMaze = remove_line(maze, rows, cols, endBlockCoords);
        else
            newMaze(blockY, blockX, 1) = 0;
            newMaze(blockY-1, blockX, 3) = 0;
        end
    elseif side == 2
        if any(ismember([blockX+1, blockY], endBlockCoords, 'rows')) || blockX == cols
            newMaze = remove_line(maze, rows, cols, endBlockCoords);
        else
            newMaze(blockY, blockX, 2) = 0;
            newMaze(blockY, blockX+1, 4) = 0;
        end
    elseif side == 3
        if any(ismember([blockX, blockY+1], endBlockCoords, 'rows')) || blockY == rows
            newMaze = remove_line(maze, rows, cols, endBlockCoords);
        else
            newMaze(blockY, blockX, 3) = 0;
            newMaze(blockY+1, blockX, 1) = 0;
        end
    elseif side == 4
        if blockX - 1 == 0 || any(ismember([blockX-1, blockY], endBlockCoords, 'rows'))
            newMaze = remove_line(maze, rows, cols, endBlockCoords);
        else
            newMaze(blockY, blockX, 4) = 0;
            newMaze(blockY, blockX-1, 2) = 0;
        end
    end
    result = newMaze;
end

function result = configure_maze(maze, rows, cols, block_size, endBlock)
    newMaze = convert_maze(maze, rows, cols, block_size);
    resizedBinaryMaze = imresize(newMaze, [rows*block_size, cols*block_size], 'nearest');

    % Set the resolution (adjust based on your robot simulator's requirements)
    resolution = block_size; % Example: 10 cells per meter
    simMap = binaryOccupancyMap(resizedBinaryMaze, resolution);
    
    % Set the world limits (optional, if needed)
    simMap.GridLocationInWorld = [0, 0]; % Adjust as needed
    simMap.LocalOriginInWorld = [0, 0]; % Adjust as needed
    
    mazeForSim = struct(...
        'lineFollowingMap', single(newMaze), ... % Adjust as needed
        'obsMap', [], ... % Add obstacle data if available
        'scaleFactor', resolution, ... % Adjust as needed
        'simMap', simMap, ... % Assign the binaryOccupancyMap object
        'endBlock', endBlock, ...
        'rows', rows,...
        'cols', cols...
    );
    result = mazeForSim;
end

function newMaze = convert_maze(maze, rows, cols, block_size)

    % Step 1: Split the maze into 4 sides
    northWalls = maze(:, :, 1); % North walls
    eastWalls = maze(:, :, 2);  % East walls
    southWalls = maze(:, :, 3); % South walls
    westWalls = maze(:, :, 4);  % West walls

    % Step 2: Create an binary maze filled with ones (walls)
    newMaze = zeros(rows*block_size, cols*block_size);

    for row = 1:rows
        newMaze(row*block_size-110:row*block_size-90,1:end) = 2;
    end
    for col = 1:cols
        newMaze(1:end, col*block_size-110:col*block_size-90) = 2;
    end

    for row = 1:rows
        for col = 1:cols
            startRow = (row - 1) * block_size + 1;
            endRow = row * block_size;
            startCol = (col - 1) * block_size + 1;
            endCol = col * block_size;

            % North wall
            if northWalls(row, col) == 1
                newMaze(startRow:startRow+3, startCol:endCol) = 1;
            end

            % East wall
            if eastWalls(row, col) == 1
                newMaze(startRow:endRow, endCol-3:endCol) = 1;
            end

            % South wall
            if southWalls(row, col) == 1
                newMaze(endRow-3:endRow, startCol:endCol) = 1;
            end

            % West wall
            if westWalls(row, col) == 1
                newMaze(startRow:endRow, startCol:startCol+3) = 1;
            end
        end
    end
    
    customColormap = [
        1, 1, 1;    % White (0)
        0, 0, 0; % Brown (1)
        0, 0, 0;    % Black (2)
    ];
    imagesc(newMaze);
    colormap(customColormap)
    axis image;
    pause(10)
    customColormap = [
        1, 1, 1;    % White (0)
        0.6, 0.4, 0.2; % Brown (1)
        0, 0, 0;    % Black (2)
    ];
    colormap(customColormap)
end

function result = cut_maze(maze)
    % Step 1: Cut the first row and first column
    newMaze = maze(2:end, 2:end, :); % Remove the first row and first column

    % Step 2: Convert all ones in the first column of East (4) and North (1) walls into zeros
    newMaze(1, :, 1) = 1; % North wall 
    newMaze(:, 1, 4) = 1; % East wall
    result = newMaze;
end

function visualize_maze(maze, rows, cols)
    clf;
    hold on;

    % Draw the grid and walls
    for x = 1:cols
        for y = 1:rows
            x0 = x - 1;
            y0 = rows - y;

            if maze(y, x, 1) == 1 % North wall
                plot([x0, x0 + 1], [y0 + 1, y0 + 1], 'k', 'LineWidth', 2);
            end
            if maze(y, x, 2) == 1 % East wall
                plot([x0 + 1, x0 + 1], [y0, y0 + 1], 'k', 'LineWidth', 2);
            end
            if maze(y, x, 3) == 1 % South wall
                plot([x0, x0 + 1], [y0, y0], 'k', 'LineWidth', 2);
            end
            if maze(y, x, 4) == 1 % West wall
                plot([x0, x0], [y0, y0 + 1], 'k', 'LineWidth', 2);
            end
        end
    end

    axis equal;
    axis off;
    hold off;
end

% 1 - Maze ends at a 2x2 square
% 2 - Put some diagonals in maze
% 3 - Have multiple routes
% 4 - Mouse has 7 sensors (3 ToF sensors)
% 5 - 
