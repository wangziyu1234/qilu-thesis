function path = hybrid_astar_pathplanning()
%HYBRID_ASTAR_PATHPLANNING  Hybrid A* 路径规划
%   输出: path [x, y, theta]

clear; clc; close all;

%% ==================== 1. 地图 ====================
map_w = 10;  map_h = 8;
res   = 0.2;
cols  = round(map_w / res);
rows  = round(map_h / res);

% 货架障碍物 [x1, y1, x2, y2]
obstacles = [
    2.0, 0.0, 2.4, 3.0;
    4.5, 2.0, 4.9, 5.0;
    7.0, 0.0, 7.4, 3.5;
    7.0, 5.0, 7.4, 8.0;
    3.0, 5.5, 6.0, 5.9;
];

obs_map = false(rows, cols);
for i = 1:size(obstacles, 1)
    c1 = max(1,   round(obstacles(i,1)/res)+1);
    r1 = max(1,   round(obstacles(i,2)/res)+1);
    c2 = min(cols, round(obstacles(i,3)/res)+1);
    r2 = min(rows, round(obstacles(i,4)/res)+1);
    obs_map(r1:r2, c1:c2) = true;
end

start_pos = [1.0, 1.0, 0];
goal_pos  = [9.0, 7.0, pi/2];

fprintf('========== Hybrid A* 路径规划 ==========\n');
fprintf('起点 (%.1f, %.1f) -> 终点 (%.1f, %.1f)\n', ...
    start_pos(1), start_pos(2), goal_pos(1), goal_pos(2));

%% ==================== 2. 参数 ====================
step_len = 0.5;                        % 步长 (m)
L = 0.52;                              % 轮距 (m)
curvatures = [-1.11, -0.52, 0, 0.52, 1.11];  % 5 种离散曲率 (m^-1), 由差速轮速比产生
n_curv = length(curvatures);
max_iter = 20000;

%% ==================== 3. 初始化 OpenList / CloseList ====================
% OpenList:  [x, y, theta, f, g, parent_idx, action_id]
% CloseList: [x, y, theta, f, g, parent_idx, action_id]
h0 = hypot(goal_pos(1)-start_pos(1), goal_pos(2)-start_pos(2));
OpenList  = [start_pos(1), start_pos(2), start_pos(3), h0, 0, 0, 0];
CloseList = [];

fprintf('搜索中...\n');

%% ==================== 4. 主循环 ====================
for iter = 1:max_iter
    if isempty(OpenList)
        warning('OpenList 为空'); path = start_pos; return;
    end

    % 4.1 取 f 值最小节点, 移入 CloseList
    [~, mi] = min(OpenList(:,4));
    cur = OpenList(mi, :);
    OpenList(mi, :) = [];
    CloseList(end+1, :) = cur; %#ok<AGROW>
    cur_idx = size(CloseList, 1);  % 当前节点在 CloseList 中的索引

    cx = cur(1); cy = cur(2); ct = cur(3);
    cg = cur(5);   % 当前节点的 g 值

    % 4.2 到达目标?
    if hypot(cx-goal_pos(1), cy-goal_pos(2)) < 0.5
        fprintf('找到路径! 迭代 %d\n', iter);
        path = backtrack(CloseList, start_pos);
        path = smooth_path(path, 3);
        fprintf('路径点数: %d, 长度 %.2f m\n', size(path,1), ...
            sum(hypot(diff(path(:,1)), diff(path(:,2)))));
        draw_map(obstacles, path, start_pos, goal_pos, map_w, map_h);
        return;
    end

    % 4.3 扩展 10 种动作 (5前进 + 5后退)
    for a = 1:n_curv*2
        if a <= n_curv
            kappa = curvatures(a);
            dir = 1;
        else
            kappa = curvatures(a - n_curv);
            dir = -1;
        end

        % 运动模型 (差速驱动曲率)
        [nx, ny, nt] = step_motion(cx, cy, ct, kappa, step_len, dir);

        % 边界
        if nx < 0 || nx > map_w || ny < 0 || ny > map_h
            continue;
        end

        % 碰撞
        if check_obs(cx, cy, nx, ny, obs_map, res, rows, cols)
            continue;
        end

        % 代价值
        g = cg + step_len;
        if dir == -1
            g = g + step_len * 0.5;    % 倒车惩罚
        end
        if abs(kappa) > 1e-6
            g = g + 0.1;               % 转弯惩罚
        end
        h = hypot(goal_pos(1)-nx, goal_pos(2)-ny);
        f = g + h;

        % 跳过已在 CloseList 中的节点
        if is_in_list(CloseList, nx, ny, nt, 0.15)
            continue;
        end

        % OpenList 去重: 若已有相同节点且代价更低则跳过, 否则更新
        oi = find_in_list(OpenList, nx, ny, nt, 0.15);
        if oi > 0
            if f < OpenList(oi, 4)
                OpenList(oi, :) = [nx, ny, nt, f, g, cur_idx, a];
            end
            continue;
        end

        % 加入 OpenList (存储父节点在 CloseList 中的索引)
        OpenList(end+1, :) = [nx, ny, nt, f, g, cur_idx, a]; %#ok<AGROW>
    end

    if mod(iter, 2000) == 0
        fprintf('  迭代 %d, Open: %d, Close: %d\n', ...
            iter, size(OpenList,1), size(CloseList,1));
    end
end

warning('达到最大迭代'); path = start_pos;
end

%% ======================== 运动模型 (差速驱动曲率) ========================
function [nx, ny, nt] = step_motion(x, y, theta, kappa, step, dir)
    if abs(kappa) < 1e-6
        nx = x + dir*step*cos(theta);
        ny = y + dir*step*sin(theta);
        nt = theta;
    else
        dtheta = dir * step * kappa;
        nt = theta + dtheta;
        nt = atan2(sin(nt), cos(nt));
        nx = x + dir*step*cos(theta + dtheta/2);
        ny = y + dir*step*sin(theta + dtheta/2);
    end
end

%% ======================== 碰撞检测 ========================
function hit = check_obs(x1, y1, x2, y2, obs_map, res, rows, cols)
    hit = false;
    for t = 0:0.1:1
        x = x1 + t*(x2-x1);  y = y1 + t*(y2-y1);
        c = round(x/res)+1;   r = round(y/res)+1;
        r = max(1,min(rows,r)); c = max(1,min(cols,c));
        if obs_map(r,c), hit = true; return; end
    end
end

%% ======================== 列表查找 ========================
function found = is_in_list(lst, x, y, theta, tol)
    if isempty(lst)
        found = false;
        return;
    end
    d = hypot(lst(:,1)-x, lst(:,2)-y);
    a = abs(atan2(sin(lst(:,3)-theta), cos(lst(:,3)-theta)));
    found = any(d < tol & a < 0.1);
end

function idx = find_in_list(lst, x, y, theta, tol)
    if isempty(lst)
        idx = 0; return;
    end
    d = hypot(lst(:,1)-x, lst(:,2)-y);
    a = abs(atan2(sin(lst(:,3)-theta), cos(lst(:,3)-theta)));
    idx = find(d < tol & a < 0.1, 1);
    if isempty(idx), idx = 0; end
end

%% ======================== 路径回溯 ========================
function path = backtrack(CloseList, start_pos)
    % CloseList: [x, y, theta, f, g, parent_idx, action_id]
    % 从最后一个节点沿父索引链回溯到起点
    cur = size(CloseList, 1);
    pts = {};
    for k = 1:size(CloseList, 1)
        pts{end+1} = [CloseList(cur,1), CloseList(cur,2), CloseList(cur,3)]; %#ok<AGROW>
        parent_idx = CloseList(cur, 6);
        if parent_idx == 0
            break;
        end
        cur = parent_idx;
    end

    pts = flip(pts);
    path = cell2mat(pts(:));
end

%% ======================== 路径平滑 ========================
function sp = smooth_path(p, n)
    sp = p;
    for pass = 1:n
        tmp = sp;
        for i = 2:size(sp,1)-1
            tmp(i,1) = 0.25*sp(i-1,1) + 0.5*sp(i,1) + 0.25*sp(i+1,1);
            tmp(i,2) = 0.25*sp(i-1,2) + 0.5*sp(i,2) + 0.25*sp(i+1,2);
        end
        sp = tmp;
    end
    for i = 1:size(sp,1)-1
        sp(i,3) = atan2(sp(i+1,2)-sp(i,2), sp(i+1,1)-sp(i,1));
    end
    sp(end,3) = sp(end-1,3);
end

%% ======================== 绘图 ========================
function draw_map(obstacles, path, sp, gp, mw, mh)
    figure('Color','w','Position',[100,100,800,500]);
    hold on;
    for i = 1:size(obstacles,1)
        x1=obstacles(i,1);y1=obstacles(i,2);
        x2=obstacles(i,3);y2=obstacles(i,4);
        fill([x1 x2 x2 x1],[y1 y1 y2 y2],[0.85 0.85 0.85],'EdgeColor','k');
    end
    plot(path(:,1),path(:,2),'r-','LineWidth',2.5);
    plot(sp(1),sp(2),'go','MarkerSize',12,'LineWidth',2);
    plot(gp(1),gp(2),'rx','MarkerSize',12,'LineWidth',2);
    for i = 1:5:size(path,1)
        quiver(path(i,1),path(i,2),0.2*cos(path(i,3)),0.2*sin(path(i,3)), ...
            'b','LineWidth',1,'MaxHeadSize',0.8);
    end
    grid on; axis equal; xlim([0 mw]); ylim([0 mh]);
    xlabel('X (m)'); ylabel('Y (m)');
    title('Hybrid A* 路径规划结果');
    legend('货架','规划路径','起点','终点','航向','Location','best');
    saveas(gcf, 'hybrid_astar_result.png');
    fprintf('已保存: hybrid_astar_result.png\n');
end
