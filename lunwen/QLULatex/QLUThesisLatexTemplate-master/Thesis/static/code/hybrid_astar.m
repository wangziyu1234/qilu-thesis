%% Hybrid A* 路径规划算法
%  与标准A*的区别: 状态空间从(x,y)扩展为(x,y,θ),
%  后继节点用差速运动基元(5种曲率×进退)生成, 路径天然满足转弯约束
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

obs_map = false(rows, cols);  % 栅格地图，false为空闲
for i = 1:size(obstacles, 1)
    c1 = max(1,   round(obstacles(i,1)/res)+1);
    r1 = max(1,   round(obstacles(i,2)/res)+1);
    c2 = min(cols, round(obstacles(i,3)/res)+1);
    r2 = min(rows, round(obstacles(i,4)/res)+1);
    obs_map(r1:r2, c1:c2) = true;  % 标记占据
end

start_pos = [1.0, 1.0, 0];  % 起点 (x,y,θ)
goal_pos  = [9.0, 7.0, pi/2];  % 终点，航向90°

fprintf('========== Hybrid A* 路径规划 ==========\n');
fprintf('起点 (%.1f, %.1f) -> 终点 (%.1f, %.1f)\n', ...
    start_pos(1), start_pos(2), goal_pos(1), goal_pos(2));

%% —— 搜索参数 ——
step_len = 0.5;  % 运动基元步长(m)
L = 0.52;  % 轮距(m)
curvatures = [-1.11, -0.52, 0, 0.52, 1.11];  % 离散曲率(1/m) —— 对应不同轮速比
n_curv = length(curvatures);
max_iter = 20000;  % 最大迭代次数

%% —— 初始化Open/Close列表 ——
h0 = hypot(goal_pos(1)-start_pos(1), goal_pos(2)-start_pos(2));  % 启发初值(欧氏距离)
OpenList  = [start_pos(1), start_pos(2), start_pos(3), h0, 0, 0, 0];  % [x,y,θ,f,g,parent_idx,action]
CloseList = [];

fprintf('搜索中...\n');

%% —— 主搜索循环 ——
for iter = 1:max_iter
    if isempty(OpenList)
        warning('OpenList 为空, 搜索失败'); path = start_pos; return;
    end

    [~, mi] = min(OpenList(:,4));  % 取f最小节点
    cur = OpenList(mi, :);
    OpenList(mi, :) = [];
    CloseList(end+1, :) = cur; %#ok<AGROW>
    cur_idx = size(CloseList, 1);  % 记录回溯索引

    cx = cur(1); cy = cur(2); ct = cur(3);
    cg = cur(5);  % 当前g值

    if hypot(cx-goal_pos(1), cy-goal_pos(2)) < 0.5  % 距目标<0.5m视为到达
        fprintf('找到路径! 迭代 %d\n', iter);
        path = backtrack(CloseList, start_pos);  % 回溯重建路径
        path = smooth_path(path, 3);  % 三次均值平滑
        fprintf('路径点数: %d, 长度 %.2f m\n', size(path,1), ...
            sum(hypot(diff(path(:,1)), diff(path(:,2)))));
        draw_map(obstacles, path, start_pos, goal_pos, map_w, map_h);
        return;
    end

    for a = 1:n_curv*2  % 10种动作(5曲率×前进/后退)
        if a <= n_curv
            kappa = curvatures(a);  % 前进
            dir = 1;
        else
            kappa = curvatures(a - n_curv);  % 后退
            dir = -1;
        end

        [nx, ny, nt] = step_motion(cx, cy, ct, kappa, step_len, dir);

        if nx < 0 || nx > map_w || ny < 0 || ny > map_h  % 越界
            continue;
        end

        if check_obs(cx, cy, nx, ny, obs_map, res, rows, cols)  % 碰撞
            continue;
        end

        g = cg + step_len;
        if dir == -1
            g = g + step_len * 0.5;  % 倒车加50%代价
        end
        if abs(kappa) > 1e-6
            g = g + 0.1;  % 转弯惩罚
        end
        h = hypot(goal_pos(1)-nx, goal_pos(2)-ny);  % 启发值
        f = g + h;

        if is_in_list(CloseList, nx, ny, nt, 0.15)
            continue;
        end

        oi = find_in_list(OpenList, nx, ny, nt, 0.15);
        if oi > 0
            if f < OpenList(oi, 4)  % 更低代价则更新
                OpenList(oi, :) = [nx, ny, nt, f, g, cur_idx, a];
            end
            continue;
        end

        OpenList(end+1, :) = [nx, ny, nt, f, g, cur_idx, a]; %#ok<AGROW>
    end

    if mod(iter, 2000) == 0  % 每2000轮输出进度
        fprintf('  迭代 %d, Open: %d, Close: %d\n', ...
            iter, size(OpenList,1), size(CloseList,1));
    end
end

warning('达到最大迭代次数, 未找到路径'); path = start_pos;
end

%% 曲率模型运动基元
function [nx, ny, nt] = step_motion(x, y, theta, kappa, step, dir)
    if abs(kappa) < 1e-6  % 直线运动
        nx = x + dir*step*cos(theta);
        ny = y + dir*step*sin(theta);
        nt = theta;
    else  % 圆弧运动
        dtheta = dir * step * kappa;
        nt = theta + dtheta;
        nt = atan2(sin(nt), cos(nt));  % 归一化[-π,π]
        nx = x + dir*step*cos(theta + dtheta/2);  % 中值角度提高精度
        ny = y + dir*step*sin(theta + dtheta/2);
    end
end

%% 路径段碰撞检测(插值采样)
function hit = check_obs(x1, y1, x2, y2, obs_map, res, rows, cols)
    hit = false;
    for t = 0:0.1:1  % 11个采样点
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

%% 列表匹配(位置+航向容差)
function found = is_in_list(lst, x, y, theta, tol)
    if isempty(lst)
        found = false;
        return;
    end
    d = hypot(lst(:,1)-x, lst(:,2)-y);  % 位置距离
    a = abs(atan2(sin(lst(:,3)-theta), cos(lst(:,3)-theta)));  % 角度差
    found = any(d < tol & a < 0.1);
end

%% 在列表中查找节点索引
function idx = find_in_list(lst, x, y, theta, tol)
    if isempty(lst)
        idx = 0; return;
    end
    d = hypot(lst(:,1)-x, lst(:,2)-y);
    a = abs(atan2(sin(lst(:,3)-theta), cos(lst(:,3)-theta)));
    idx = find(d < tol & a < 0.1, 1);
    if isempty(idx), idx = 0; end
end

%% 回溯父节点链重建路径
function path = backtrack(CloseList, start_pos)
    cur = size(CloseList, 1);  % 从终点开始
    pts = {};
    for k = 1:size(CloseList, 1)
        pts{end+1} = [CloseList(cur,1), CloseList(cur,2), CloseList(cur,3)]; %#ok<AGROW>
        parent_idx = CloseList(cur, 6);
        if parent_idx == 0  % 回到起点
            break;
        end
        cur = parent_idx;
    end

    pts = flip(pts);  % 翻转使起点在前
    path = cell2mat(pts(:));
end

%% 均值平滑(3点加权)
function sp = smooth_path(p, n)
    sp = p;
    for pass = 1:n
        tmp = sp;
        for i = 2:size(sp,1)-1  % 内部点加权平均
            tmp(i,1) = 0.25*sp(i-1,1) + 0.5*sp(i,1) + 0.25*sp(i+1,1);
            tmp(i,2) = 0.25*sp(i-1,2) + 0.5*sp(i,2) + 0.25*sp(i+1,2);
        end
        sp = tmp;
    end
    for i = 1:size(sp,1)-1  % 差分求航向
        sp(i,3) = atan2(sp(i+1,2)-sp(i,2), sp(i+1,1)-sp(i,1));
    end
    sp(end,3) = sp(end-1,3);
end

%% 规划结果可视化
function draw_map(obstacles, path, sp, gp, mw, mh)
    figure('Color','w','Position',[100,100,800,500]);
    hold on;
    for i = 1:size(obstacles,1)
        x1=obstacles(i,1); y1=obstacles(i,2);
        x2=obstacles(i,3); y2=obstacles(i,4);
        fill([x1 x2 x2 x1],[y1 y1 y2 y2],[0.85 0.85 0.85],'EdgeColor','k');  % 灰色货架
    end
    plot(path(:,1),path(:,2),'r-','LineWidth',2.5);
    plot(sp(1),sp(2),'go','MarkerSize',12,'LineWidth',2);
    plot(gp(1),gp(2),'rx','MarkerSize',12,'LineWidth',2);
    for i = 1:5:size(path,1)  % 每5点标航向
        quiver(path(i,1),path(i,2),0.2*cos(path(i,3)),0.2*sin(path(i,3)), ...
            'b','LineWidth',1,'MaxHeadSize',0.8);
    end
    grid on; axis equal; xlim([0 mw]); ylim([0 mh]);
    xlabel('X (m)'); ylabel('Y (m)');
    title('Hybrid A* 路径规划结果');
    legend('货架','规划路径','起点','终点','航向','Location','best');
    out_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
    if ~exist(out_dir, 'dir'), mkdir(out_dir); end
    fname = fullfile(out_dir, 'hybrid_astar_result.png');
    saveas(gcf, fname);
    fprintf('已保存: %s\n', fname);
end
