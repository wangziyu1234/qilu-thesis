function path = hybrid_astar()
%HYBRID_ASTAR  Hybrid A* 路径规划
%   在仓储栅格地图上规划满足差速运动学约束的无碰撞路径
%   输出: path [x, y, theta]

clear; clc; close all;

%% ==================== 1. 地图 ====================
map_w = 10;  map_h = 8;                 % 地图尺寸 [m]
res   = 0.2;                            % 栅格分辨率 [m]
cols  = round(map_w / res);             % 栅格列数
rows  = round(map_h / res);             % 栅格行数

% 货架障碍物 [x1, y1, x2, y2] (矩形左下/右上角)
obstacles = [
    2.0, 0.0, 2.4, 3.0;                % 左侧货架
    4.5, 2.0, 4.9, 5.0;                % 中部左侧货架
    7.0, 0.0, 7.4, 3.5;                % 右侧下方货架
    7.0, 5.0, 7.4, 8.0;                % 右侧上方货架
    3.0, 5.5, 6.0, 5.9;                % 中部横梁
    ];

obs_map = false(rows, cols);            % 障碍物占据栅格地图 (false = 自由)
for i = 1:size(obstacles, 1)
    c1 = max(1,   round(obstacles(i,1)/res)+1);  % 障碍物左列
    r1 = max(1,   round(obstacles(i,2)/res)+1);  % 障碍物下行
    c2 = min(cols, round(obstacles(i,3)/res)+1);  % 障碍物右列
    r2 = min(rows, round(obstacles(i,4)/res)+1);  % 障碍物上行
    obs_map(r1:r2, c1:c2) = true;       % 标记占据
end

% 起点 (x, y, theta), 终点 (x, y, theta)
start_pos = [1.0, 1.0, 0];              % 起点: 左下角, 航向 0°
goal_pos  = [9.0, 7.0, pi/2];           % 终点: 右上角, 航向 90°

fprintf('========== Hybrid A* 路径规划 ==========\n');
fprintf('起点 (%.1f, %.1f) -> 终点 (%.1f, %.1f)\n', ...
    start_pos(1), start_pos(2), goal_pos(1), goal_pos(2));

%% ==================== 2. 搜索参数 ====================
step_len = 0.5;                         % 运动基元步长 [m]
L = 0.52;                               % 轮距 [m]
% 5 种离散曲率 [1/m], 由差速左右轮速比产生: 1.8:1, 1.3:1, 1:1, 1:1.3, 1:1.8
curvatures = [-1.11, -0.52, 0, 0.52, 1.11];
n_curv = length(curvatures);            % 曲率种类数
max_iter = 20000;                       % 最大搜索迭代次数

%% ==================== 3. 初始化 OpenList / CloseList ====================
% 每行: [x, y, theta, f(=g+h), g, parent_idx, action_id]
h0 = hypot(goal_pos(1)-start_pos(1), goal_pos(2)-start_pos(2));  % 起点启发值
OpenList  = [start_pos(1), start_pos(2), start_pos(3), h0, 0, 0, 0];
CloseList = [];

fprintf('搜索中...\n');

%% ==================== 4. 主循环 ====================
for iter = 1:max_iter
    if isempty(OpenList)
        warning('OpenList 为空, 搜索失败'); path = start_pos; return;
    end

    % 4.1 取 f 值最小节点 (最优候选), 移入 CloseList
    [~, mi] = min(OpenList(:,4));       % 找最小 f 值的行索引
    cur = OpenList(mi, :);              % 当前最优节点
    OpenList(mi, :) = [];               % 从 OpenList 移除
    CloseList(end+1, :) = cur; %#ok<AGROW>  % 加入 CloseList
    cur_idx = size(CloseList, 1);       % 当前节点在 CloseList 中的索引 (用于回溯)

    cx = cur(1); cy = cur(2); ct = cur(3);  % 当前节点的 x, y, theta
    cg = cur(5);                             % 当前节点的 g 值

    % 4.2 到达目标?
    if hypot(cx-goal_pos(1), cy-goal_pos(2)) < 0.5  % 距目标小于 0.5m
        fprintf('找到路径! 迭代 %d\n', iter);
        path = backtrack(CloseList, start_pos);      % 回溯提取路径
        path = smooth_path(path, 3);                 % 3 次均值平滑
        fprintf('路径点数: %d, 长度 %.2f m\n', size(path,1), ...
            sum(hypot(diff(path(:,1)), diff(path(:,2)))));
        draw_map(obstacles, path, start_pos, goal_pos, map_w, map_h);
        return;
    end

    % 4.3 扩展 10 种动作 (5 种曲率 × 前进/后退)
    for a = 1:n_curv*2
        if a <= n_curv
            kappa = curvatures(a);       % 前进: 使用第 a 种曲率
            dir = 1;                     % dir=1 表示前进
        else
            kappa = curvatures(a - n_curv);  % 后退: 使用相同曲率
            dir = -1;                        % dir=-1 表示后退
        end

        % 差速底盘曲率约束下的运动基元扩展
        [nx, ny, nt] = step_motion(cx, cy, ct, kappa, step_len, dir);

        % 边界检查
        if nx < 0 || nx > map_w || ny < 0 || ny > map_h
            continue;
        end

        % 碰撞检测 (沿路径段插值采样)
        if check_obs(cx, cy, nx, ny, obs_map, res, rows, cols)
            continue;
        end

        % 代价值计算
        g = cg + step_len;               % 基础代价: 步长
        if dir == -1
            g = g + step_len * 0.5;      % 倒车惩罚 (增加 50% 步长代价)
        end
        if abs(kappa) > 1e-6
            g = g + 0.1;                 % 转弯惩罚 (非直线扩展加 0.1)
        end
        h = hypot(goal_pos(1)-nx, goal_pos(2)-ny);  % 欧氏距离启发值
        f = g + h;                                     % 总代价

        % 跳过已在 CloseList 中的节点
        if is_in_list(CloseList, nx, ny, nt, 0.15)
            continue;
        end

        % OpenList 去重: 若已有相同节点且代价更低则跳过, 否则更新
        oi = find_in_list(OpenList, nx, ny, nt, 0.15);
        if oi > 0
            if f < OpenList(oi, 4)       % 新代价更低则更新
                OpenList(oi, :) = [nx, ny, nt, f, g, cur_idx, a];
            end
            continue;
        end

        % 加入 OpenList (存储父节点在 CloseList 中的索引)
        OpenList(end+1, :) = [nx, ny, nt, f, g, cur_idx, a]; %#ok<AGROW>
    end

    if mod(iter, 2000) == 0              % 每 2000 次迭代输出进度
        fprintf('  迭代 %d, Open: %d, Close: %d\n', ...
            iter, size(OpenList,1), size(CloseList,1));
    end
end

warning('达到最大迭代次数, 未找到路径'); path = start_pos;
end

%% ======================== 运动基元: 差速驱动曲率模型 ========================
function [nx, ny, nt] = step_motion(x, y, theta, kappa, step, dir)
    if abs(kappa) < 1e-6                 % 直线运动 (曲率≈0)
        nx = x + dir*step*cos(theta);    % x 沿航向移动
        ny = y + dir*step*sin(theta);    % y 沿航向移动
        nt = theta;                      % 航向不变
    else                                 % 曲线运动
        dtheta = dir * step * kappa;     % 航向变化量
        nt = theta + dtheta;             % 新航向
        nt = atan2(sin(nt), cos(nt));    % 归一化到 [-π, π]
        nx = x + dir*step*cos(theta + dtheta/2);  % 用中值角度计算新 x
        ny = y + dir*step*sin(theta + dtheta/2);  % 用中值角度计算新 y
    end
end

%% ======================== 碰撞检测 ========================
% 沿路径段以 0.1m 步长插值采样, 逐一检查栅格是否被障碍物占据
function hit = check_obs(x1, y1, x2, y2, obs_map, res, rows, cols)
    hit = false;
    for t = 0:0.1:1                     % 线性插值 11 个采样点
        x = x1 + t*(x2-x1);             % 采样点 x
        y = y1 + t*(y2-y1);             % 采样点 y
        c = round(x/res)+1;             % 采样点对应列号
        r = round(y/res)+1;             % 采样点对应行号
        r = max(1,min(rows,r));         % 行号限幅
        c = max(1,min(cols,c));         % 列号限幅
        if obs_map(r,c)                 % 该栅格被占据
            hit = true;
            return;
        end
    end
end

%% ======================== 列表查找 ========================
function found = is_in_list(lst, x, y, theta, tol)
    if isempty(lst)                     % 空列表返回 false
        found = false;
        return;
    end
    d = hypot(lst(:,1)-x, lst(:,2)-y);  % 各节点到目标点的欧氏距离
    a = abs(atan2(sin(lst(:,3)-theta), cos(lst(:,3)-theta)));  % 航向角差值的绝对值
    found = any(d < tol & a < 0.1);     % 存在距离和航向均在容差内的节点
end

function idx = find_in_list(lst, x, y, theta, tol)
    if isempty(lst)                     % 空列表返回 0
        idx = 0; return;
    end
    d = hypot(lst(:,1)-x, lst(:,2)-y);  % 各节点到目标点的欧氏距离
    a = abs(atan2(sin(lst(:,3)-theta), cos(lst(:,3)-theta)));  % 航向角差值
    idx = find(d < tol & a < 0.1, 1);   % 返回第一个匹配的索引
    if isempty(idx), idx = 0; end       % 未找到则返回 0
end

%% ======================== 路径回溯 ========================
% 从终点沿 parent_idx 链回溯到起点, 提取完整路径
function path = backtrack(CloseList, start_pos)
    cur = size(CloseList, 1);           % 从 CloseList 最后一个节点 (终点) 开始
    pts = {};
    for k = 1:size(CloseList, 1)        % 最多回溯全部节点
        pts{end+1} = [CloseList(cur,1), CloseList(cur,2), CloseList(cur,3)]; %#ok<AGROW>
        parent_idx = CloseList(cur, 6); % 父节点索引
        if parent_idx == 0              % 回溯到起点 (parent_idx=0)
            break;
        end
        cur = parent_idx;               % 继续向父节点回溯
    end

    pts = flip(pts);                    % 翻转 (起点→终点)
    path = cell2mat(pts(:));            % 转为矩阵 [x, y, theta]
end

%% ======================== 路径平滑 ========================
% 均值滤波平滑 (3次迭代), 消除节点间距不均导致的微小折角
function sp = smooth_path(p, n)
    sp = p;                             % 初始化为原始路径
    for pass = 1:n                      % 迭代 n 次
        tmp = sp;
        for i = 2:size(sp,1)-1          % 内部点进行均值平滑
            tmp(i,1) = 0.25*sp(i-1,1) + 0.5*sp(i,1) + 0.25*sp(i+1,1);  % x 平滑
            tmp(i,2) = 0.25*sp(i-1,2) + 0.5*sp(i,2) + 0.25*sp(i+1,2);  % y 平滑
        end
        sp = tmp;
    end
    for i = 1:size(sp,1)-1              % 重新计算各点航向角
        sp(i,3) = atan2(sp(i+1,2)-sp(i,2), sp(i+1,1)-sp(i,1));
    end
    sp(end,3) = sp(end-1,3);            % 终点航向角等于前一点
end

%% ======================== 结果绘图 ========================
function draw_map(obstacles, path, sp, gp, mw, mh)
    figure('Color','w','Position',[100,100,800,500]);
    hold on;
    for i = 1:size(obstacles,1)         % 绘制障碍物 (灰色填充矩形)
        x1=obstacles(i,1); y1=obstacles(i,2);
        x2=obstacles(i,3); y2=obstacles(i,4);
        fill([x1 x2 x2 x1],[y1 y1 y2 y2],[0.85 0.85 0.85],'EdgeColor','k');
    end
    plot(path(:,1),path(:,2),'r-','LineWidth',2.5);   % 规划路径 (红色实线)
    plot(sp(1),sp(2),'go','MarkerSize',12,'LineWidth',2);   % 起点 (绿色圆点)
    plot(gp(1),gp(2),'rx','MarkerSize',12,'LineWidth',2);   % 终点 (红色叉号)
    for i = 1:5:size(path,1)            % 每 5 个节点绘制一个航向箭头
        quiver(path(i,1),path(i,2),0.2*cos(path(i,3)),0.2*sin(path(i,3)), ...
            'b','LineWidth',1,'MaxHeadSize',0.8);
    end
    grid on; axis equal; xlim([0 mw]); ylim([0 mh]);
    xlabel('X (m)'); ylabel('Y (m)');
    title('Hybrid A* 路径规划结果');
    legend('货架','规划路径','起点','终点','航向','Location','best');
    saveas(gcf, 'hybrid_astar_result.png');  % 保存结果图
    fprintf('已保存: hybrid_astar_result.png\n');
end
