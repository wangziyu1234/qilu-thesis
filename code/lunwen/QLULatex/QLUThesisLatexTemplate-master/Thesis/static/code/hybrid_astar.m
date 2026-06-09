%% Hybrid A* 路径规划算法（优化版）
%  与标准A*的区别: 状态空间从(x,y)扩展为(x,y,θ),
%  后继节点用差速运动基元(5种曲率×进退)生成, 路径天然满足转弯约束
%  优化内容: 障碍物膨胀、3D航向栅格去重、解析扩展、B样条平滑、综合评价
function path = hybrid_astar()
%  注：被 run_all 调用时不执行 close all 以免关闭已有图窗
if nargout == 0, clear; clc; close all; end  % 仅独立运行时清屏关图

%% —— 地图构建 ——
map_w = 10;  map_h = 8;  % 地图尺寸(m)
res   = 0.2;  % 栅格分辨率(m)
cols  = round(map_w / res);  % 栅格列数
rows  = round(map_h / res);  % 栅格行数

obstacles = [  % 货架障碍物 [x1,y1,x2,y2]
    2.0, 0.0, 2.4, 3.0;  % 左货架
    4.5, 2.0, 4.9, 5.0;  % 中左货架
    7.0, 0.0, 7.4, 3.5;  % 右下货架
    7.0, 5.0, 7.4, 8.0;  % 右上货架
    3.0, 5.5, 6.0, 5.9;  % 中部横梁
    ];

%% —— 障碍物膨胀（考虑车体安全距离）——
r_robot = 0.38;  % 车体等效半径(m) = 660mm车宽/2 + 0.05m安全裕量
r_inflate = ceil(r_robot / res);  % 膨胀栅格数

obs_map = false(rows, cols);  % 栅格地图，false为空闲
for i = 1:size(obstacles, 1)
    c1 = max(1,   round(obstacles(i,1)/res)+1);
    r1 = max(1,   round(obstacles(i,2)/res)+1);
    c2 = min(cols, round(obstacles(i,3)/res)+1);
    r2 = min(rows, round(obstacles(i,4)/res)+1);
    % 膨胀区域：向四周扩展r_inflate个栅格
    r1e = max(1, r1 - r_inflate);  r2e = min(rows, r2 + r_inflate);
    c1e = max(1, c1 - r_inflate);  c2e = min(cols, c2 + r_inflate);
    obs_map(r1e:r2e, c1e:c2e) = true;  % 标记占据+膨胀
end

start_pos = [1.0, 1.0, 0];  % 起点 (x,y,θ)
goal_pos  = [9.0, 7.0, pi/2];  % 终点，航向90°

fprintf('========== Hybrid A* 路径规划（优化版） ==========\n');
fprintf('起点 (%.1f, %.1f, %.1f°) -> 终点 (%.1f, %.1f, %.1f°)\n', ...
    start_pos(1), start_pos(2), rad2deg(start_pos(3)), ...
    goal_pos(1), goal_pos(2), rad2deg(goal_pos(3)));
fprintf('障碍物膨胀半径: %.2f m (%d 栅格)\n', r_robot, r_inflate);

%% —— 搜索参数 ——
step_len = 0.5;  % 运动基元步长(m)
curvatures = [-1.11, -0.52, 0, 0.52, 1.11];  % 离散曲率(1/m)
n_curv = length(curvatures);
max_iter = 20000;  % 最大迭代次数
goal_tol = 0.5;  % 到达目标的位置容差(m)
goal_ang_tol = deg2rad(30);  % 到达目标的航向容差(rad)

%% —— 3D航向栅格（快速状态去重）——
n_theta_bins = 72;  % 航向离散为72个bin（每5°一个bin）
theta_bin_res = 2*pi / n_theta_bins;
best_g = inf(rows, cols, n_theta_bins);

sc = max(1, min(cols, round(start_pos(1)/res)+1));
sr = max(1, min(rows, round(start_pos(2)/res)+1));
stb = max(1, min(n_theta_bins, floor(mod(start_pos(3), 2*pi)/theta_bin_res)+1));
h0 = hypot(goal_pos(1)-start_pos(1), goal_pos(2)-start_pos(2));
OpenList  = [start_pos(1), start_pos(2), start_pos(3), h0, 0, 0, 0];
CloseList = [];
best_g(sr, sc, stb) = 0;

%% —— 统计变量 ——
n_expanded = 0;
t_start = tic;

fprintf('搜索中...\n');

%% —— 主搜索循环 ——
for iter = 1:max_iter
    if isempty(OpenList)
        warning('OpenList 为空, 搜索失败'); path = start_pos; return;
    end

    [~, mi] = min(OpenList(:,4));
    cur = OpenList(mi, :);
    OpenList(mi, :) = [];
    CloseList(end+1, :) = cur; %#ok<AGROW>
    cur_idx = size(CloseList, 1);
    n_expanded = n_expanded + 1;

    cx = cur(1); cy = cur(2); ct = cur(3);
    cg = cur(5);

    %% —— 解析扩展：尝试直连目标 ——
    dist_to_goal = hypot(cx - goal_pos(1), cy - goal_pos(2));
    if dist_to_goal < step_len * 1.5
        dtheta = goal_pos(3) - ct;
        dtheta = atan2(sin(dtheta), cos(dtheta));
        if abs(dtheta) < goal_ang_tol
            if ~check_obs(cx, cy, goal_pos(1), goal_pos(2), obs_map, res, rows, cols)
                g = cg + dist_to_goal;
                fprintf('解析扩展成功! 迭代 %d, 节点扩展 %d\n', iter, n_expanded);
                goal_row = [goal_pos(1), goal_pos(2), goal_pos(3), g, g, cur_idx, 0];
                CloseList(end+1, :) = goal_row;
                path = backtrack(CloseList, start_pos);
                elapsed = toc(t_start);
                path = weighted_avg_smooth(path, 5);
                print_metrics(path, iter, n_expanded, elapsed, obstacles, r_robot);
                draw_map(obstacles, path, start_pos, goal_pos, map_w, map_h);
                return;
            end
        end
    end

    %% —— 目标检测（位置+航向双重约束）——
    if dist_to_goal < goal_tol
        dtheta = goal_pos(3) - ct;
        dtheta = atan2(sin(dtheta), cos(dtheta));
        if abs(dtheta) < goal_ang_tol
            fprintf('找到路径! 迭代 %d, 节点扩展 %d\n', iter, n_expanded);
            path = backtrack(CloseList, start_pos);
            elapsed = toc(t_start);
            path = bspline_smooth(path);
            print_metrics(path, iter, n_expanded, elapsed, obstacles, r_robot);
            draw_map(obstacles, path, start_pos, goal_pos, map_w, map_h);
            return;
        end
    end

    %% —— 展开后继节点 ——
    for a = 1:n_curv*2
        if a <= n_curv
            kappa = curvatures(a);  dir = 1;
        else
            kappa = curvatures(a - n_curv);  dir = -1;
        end

        [nx, ny, nt] = step_motion(cx, cy, ct, kappa, step_len, dir);

        if nx < 0 || nx > map_w || ny < 0 || ny > map_h
            continue;
        end

        if check_obs(cx, cy, nx, ny, obs_map, res, rows, cols)
            continue;
        end

        % 代价函数：步长 + 倒车惩罚 + 转弯惩罚 + 航向偏差惩罚
        g = cg + step_len;
        if dir == -1
            g = g + step_len * 0.5;
        end
        if abs(kappa) > 1e-6
            g = g + 0.1;
        end
        to_goal_angle = atan2(goal_pos(2)-ny, goal_pos(1)-nx);
        heading_diff = abs(atan2(sin(nt - to_goal_angle), cos(nt - to_goal_angle)));
        g = g + 0.05 * heading_diff;

        h = hypot(goal_pos(1)-nx, goal_pos(2)-ny);
        f = g + h;

        nc = max(1, min(cols, round(nx/res)+1));
        nr = max(1, min(rows, round(ny/res)+1));
        ntb = max(1, min(n_theta_bins, floor(mod(nt, 2*pi)/theta_bin_res)+1));

        if g >= best_g(nr, nc, ntb)
            continue;
        end
        best_g(nr, nc, ntb) = g;

        if is_in_list(CloseList, nx, ny, nt, 0.15)
            continue;
        end

        oi = find_in_list(OpenList, nx, ny, nt, 0.15);
        if oi > 0
            if f < OpenList(oi, 4)
                OpenList(oi, :) = [nx, ny, nt, f, g, cur_idx, a];
            end
            continue;
        end

        OpenList(end+1, :) = [nx, ny, nt, f, g, cur_idx, a]; %#ok<AGROW>
    end

    if mod(iter, 2000) == 0
        fprintf('  迭代 %d, Open: %d, Close: %d\n', ...
            iter, size(OpenList,1), size(CloseList,1));
    end
end

warning('达到最大迭代次数, 未找到路径'); path = start_pos;
end

%% ========== 运动基元 ==========
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

%% ========== 碰撞检测（膨胀地图）==========
function hit = check_obs(x1, y1, x2, y2, obs_map, res, rows, cols)
    hit = false;
    for t = 0:0.05:1  % 21个采样点（加密检测）
        x = x1 + t*(x2-x1);
        y = y1 + t*(y2-y1);
        c = round(x/res)+1;
        r = round(y/res)+1;
        r = max(1,min(rows,r));
        c = max(1,min(cols,c));
        if obs_map(r,c)
            hit = true;
            return;
        end
    end
end

%% ========== 列表匹配 ==========
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

%% ========== 回溯 ==========
function path = backtrack(CloseList, ~)
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

%% ========== 加权平均平滑 ==========
function sp = weighted_avg_smooth(p, n_pass)
    sp = p;
    for pass = 1:n_pass
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

%% ========== 综合评价指标 ==========
function print_metrics(path, n_iter, n_expanded, elapsed, obstacles, r_robot)
    fprintf('\n========== 路径规划评价 ==========\n');

    % 1. 路径长度
    seg_len = hypot(diff(path(:,1)), diff(path(:,2)));
    total_len = sum(seg_len);
    fprintf('路径长度: %.2f m\n', total_len);

    % 2. 路径平滑性（曲率变化率）
    if size(path,1) >= 3
        curvatures_path = zeros(size(path,1)-2, 1);
        for i = 2:size(path,1)-1
            dx1 = path(i,1) - path(i-1,1);  dy1 = path(i,2) - path(i-1,2);
            dx2 = path(i+1,1) - path(i,1);  dy2 = path(i+1,2) - path(i,2);
            cross = dx1*dy2 - dy1*dx2;
            len1 = hypot(dx1, dy1);  len2 = hypot(dx2, dy2);
            if len1*len2 > 1e-6
                curvatures_path(i-1) = cross / (len1*len2);
            end
        end
        curvature_std = std(curvatures_path);
        max_curv = max(abs(curvatures_path));
        fprintf('曲率标准差: %.4f (越小越平滑)\n', curvature_std);
        fprintf('最大曲率: %.4f\n', max_curv);
    end

    % 3. 最小安全距离
    min_dist = inf;
    for i = 1:size(path,1)
        px = path(i,1);  py = path(i,2);
        for k = 1:size(obstacles,1)
            ox1 = obstacles(k,1); oy1 = obstacles(k,2);
            ox2 = obstacles(k,3); oy2 = obstacles(k,4);
            cx_clamp = max(ox1, min(px, ox2));
            cy_clamp = max(oy1, min(py, oy2));
            d = hypot(px - cx_clamp, py - cy_clamp);
            min_dist = min(min_dist, d);
        end
    end
    fprintf('最小安全距离: %.3f m (车体半径 %.2f m)\n', min_dist, r_robot);
    if min_dist < r_robot
        fprintf('  [警告] 路径进入安全裕量!\n');
    else
        fprintf('  [安全] 路径在安全裕量之外\n');
    end

    % 4. 搜索效率
    fprintf('搜索迭代: %d\n', n_iter);
    fprintf('扩展节点: %d\n', n_expanded);
    fprintf('搜索耗时: %.3f s\n', elapsed);
    fprintf('节点效率: %.4f m/节点\n', total_len/max(n_expanded,1));

    % 5. 航向连续性
    heading_diffs = abs(atan2(sin(diff(path(:,3))), cos(diff(path(:,3)))));
    max_heading_rate = max(heading_diffs);
    fprintf('路径点数: %d\n', size(path,1));
    fprintf('最大航向变化率: %.2f°/步\n', rad2deg(max_heading_rate));
    fprintf('===================================\n\n');
end

%% ========== 可视化 ==========
function draw_map(obstacles, path, sp, gp, mw, mh)
    figure('Color','w','Position',[100,100,800,500]);
    hold on;
    for i = 1:size(obstacles,1)
        x1=obstacles(i,1); y1=obstacles(i,2);
        x2=obstacles(i,3); y2=obstacles(i,4);
        fill([x1 x2 x2 x1],[y1 y1 y2 y2],[0.85 0.85 0.85],'EdgeColor','k');
    end
    plot(path(:,1),path(:,2),'r-','LineWidth',2.5);
    plot(sp(1),sp(2),'go','MarkerSize',12,'LineWidth',2);
    plot(gp(1),gp(2),'rx','MarkerSize',12,'LineWidth',2);
    for i = 1:5:size(path,1)
        quiver(path(i,1),path(i,2),0.2*cos(path(i,3)),0.2*sin(path(i,3)), ...
            'b','LineWidth',1,'MaxHeadSize',0.8);
    end
    grid on; axis equal;
    xlim([0 mw]); ylim([0 mh]);
    xlabel('X (m)'); ylabel('Y (m)');
    title('Hybrid A* 路径规划结果（优化版）');
    legend('货架','规划路径','起点','终点','航向','Location','best');
    out_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
    if ~exist(out_dir, 'dir'), mkdir(out_dir); end
    fname = fullfile(out_dir, 'hybrid_astar_result.png');
    saveas(gcf, fname);
    fprintf('已保存: %s\n', fname);
end
