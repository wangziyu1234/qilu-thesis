%% Hybrid A* 路径规划算法
function path = hybrid_astar_pathplanning()
clear; clc; close all;  % 清空工作区、命令行、关闭图形窗口

%% ==================== 1. 地图构建 ====================
map_w = 10;  map_h = 8;  % 地图宽度10m，高度8m
res   = 0.2;  % 栅格分辨率0.2m
cols  = round(map_w / res);  % 栅格总列数
rows  = round(map_h / res);  % 栅格总行数

obstacles = [  % 货架障碍物，每行为[x1,y1,x2,y2]矩形左下和右上角坐标
    2.0, 0.0, 2.4, 3.0;  % 左侧货架
    4.5, 2.0, 4.9, 5.0;  % 中部左侧货架
    7.0, 0.0, 7.4, 3.5;  % 右侧下方货架
    7.0, 5.0, 7.4, 8.0;  % 右侧上方货架
    3.0, 5.5, 6.0, 5.9;  % 中部横梁
    ];

obs_map = false(rows, cols);  % 初始化障碍物占据栅格地图，false表示自由空间
for i = 1:size(obstacles, 1)  % 遍历每个障碍物矩形
    c1 = max(1,   round(obstacles(i,1)/res)+1);  % 障碍物占据的起始列号
    r1 = max(1,   round(obstacles(i,2)/res)+1);  % 障碍物占据的起始行号
    c2 = min(cols, round(obstacles(i,3)/res)+1);  % 障碍物占据的结束列号
    r2 = min(rows, round(obstacles(i,4)/res)+1);  % 障碍物占据的结束行号
    obs_map(r1:r2, c1:c2) = true;  % 在栅格地图中标记该矩形区域为占据
end

start_pos = [1.0, 1.0, 0];  % 起点位姿，[x,y,θ]，左下角航向0°
goal_pos  = [9.0, 7.0, pi/2];  % 终点位姿，右上角航向90°

fprintf('========== Hybrid A* 路径规划 ==========\n');  % 打印标题
fprintf('起点 (%.1f, %.1f) -> 终点 (%.1f, %.1f)\n', ...  % 打印起终点坐标
    start_pos(1), start_pos(2), goal_pos(1), goal_pos(2));

%% ==================== 2. 搜索参数设置 ====================
step_len = 0.5;  % 运动基元步长0.5m
L = 0.52;  % 差速底盘轮距0.52m
curvatures = [-1.11, -0.52, 0, 0.52, 1.11];  % 5种离散曲率(1/m)，对应不同左右轮速比
n_curv = length(curvatures);  % 曲率种类数
max_iter = 20000;  % 最大搜索迭代次数

%% ==================== 3. 初始化OpenList和CloseList ====================
h0 = hypot(goal_pos(1)-start_pos(1), goal_pos(2)-start_pos(2));  % 起点到终点的欧氏距离作为启发初值
OpenList  = [start_pos(1), start_pos(2), start_pos(3), h0, 0, 0, 0];  % 每行[x,y,θ,f,g,parent_idx,action_id]
CloseList = [];  % 初始化CloseList为空

fprintf('搜索中...\n');  % 搜索开始提示

%% ==================== 4. 主搜索循环 ====================
for iter = 1:max_iter  % 主循环
    if isempty(OpenList)  % OpenList为空则搜索失败
        warning('OpenList 为空, 搜索失败'); path = start_pos; return;  % 返回警告和起点
    end

    [~, mi] = min(OpenList(:,4));  % 取f值（第4列）最小的节点索引
    cur = OpenList(mi, :);  % 当前最优节点
    OpenList(mi, :) = [];  % 从OpenList中移除该节点
    CloseList(end+1, :) = cur; %#ok<AGROW>  % 将该节点加入CloseList
    cur_idx = size(CloseList, 1);  % 记录当前节点在CloseList中的行号，用于后续回溯

    cx = cur(1); cy = cur(2); ct = cur(3);  % 当前节点的x,y,θ
    cg = cur(5);  % 当前节点的g值（已走路径代价）

    if hypot(cx-goal_pos(1), cy-goal_pos(2)) < 0.5  % 当前位置距目标小于0.5m视为到达
        fprintf('找到路径! 迭代 %d\n', iter);  % 打印迭代次数
        path = backtrack(CloseList, start_pos);  % 回溯父节点链提取路径
        path = smooth_path(path, 3);  % 对路径进行3次均值平滑
        fprintf('路径点数: %d, 长度 %.2f m\n', size(path,1), ...  % 打印路径点数和总长
            sum(hypot(diff(path(:,1)), diff(path(:,2)))));
        draw_map(obstacles, path, start_pos, goal_pos, map_w, map_h);  % 绘制规划结果
        return;  % 返回路径
    end

    for a = 1:n_curv*2  % 扩展10种动作（5种曲率×前进/后退）
        if a <= n_curv  % 前5种为前进
            kappa = curvatures(a);  % 取第a种曲率
            dir = 1;  % dir=1表示前进
        else  % 后5种为后退
            kappa = curvatures(a - n_curv);  % 取相同曲率
            dir = -1;  % dir=-1表示后退
        end

        [nx, ny, nt] = step_motion(cx, cy, ct, kappa, step_len, dir);  % 按曲率模型计算新位姿

        if nx < 0 || nx > map_w || ny < 0 || ny > map_h  % 边界检查
            continue;  % 越界则跳过
        end

        if check_obs(cx, cy, nx, ny, obs_map, res, rows, cols)  % 碰撞检测
            continue;  % 碰撞则跳过
        end

        g = cg + step_len;  % 基础代价为步长
        if dir == -1  % 后退运动
            g = g + step_len * 0.5;  % 倒车惩罚，增加50%步长代价
        end
        if abs(kappa) > 1e-6  % 非直线运动
            g = g + 0.1;  % 转弯惩罚，增加0.1代价
        end
        h = hypot(goal_pos(1)-nx, goal_pos(2)-ny);  % 欧氏距离启发值
        f = g + h;  % 总代价f=g+h

        if is_in_list(CloseList, nx, ny, nt, 0.15)  % 节点已在CloseList中
            continue;  % 跳过
        end

        oi = find_in_list(OpenList, nx, ny, nt, 0.15);  % 在OpenList中查找相同节点
        if oi > 0  % 找到了相同节点
            if f < OpenList(oi, 4)  % 新代价更低则更新
                OpenList(oi, :) = [nx, ny, nt, f, g, cur_idx, a];  % 更新该节点信息
            end
            continue;  % 处理完毕
        end

        OpenList(end+1, :) = [nx, ny, nt, f, g, cur_idx, a]; %#ok<AGROW>  % 新节点加入OpenList
    end

    if mod(iter, 2000) == 0  % 每2000次迭代输出一次进度
        fprintf('  迭代 %d, Open: %d, Close: %d\n', ...  % 打印当前进度
            iter, size(OpenList,1), size(CloseList,1));
    end
end

warning('达到最大迭代次数, 未找到路径'); path = start_pos;  % 超限未找到路径
end

%% 差速驱动曲率模型运动基元
function [nx, ny, nt] = step_motion(x, y, theta, kappa, step, dir)
    if abs(kappa) < 1e-6  % 曲率近似为零，直线运动
        nx = x + dir*step*cos(theta);  % 沿当前航向移动x
        ny = y + dir*step*sin(theta);  % 沿当前航向移动y
        nt = theta;  % 航向角不变
    else  % 曲率非零，圆弧运动
        dtheta = dir * step * kappa;  % 航向角变化量
        nt = theta + dtheta;  % 新航向角
        nt = atan2(sin(nt), cos(nt));  % 归一化到[-π,π]
        nx = x + dir*step*cos(theta + dtheta/2);  % 用中值角度计算新x，提高精度
        ny = y + dir*step*sin(theta + dtheta/2);  % 用中值角度计算新y
    end
end

%% 路径段碰撞检测
function hit = check_obs(x1, y1, x2, y2, obs_map, res, rows, cols)
    hit = false;  % 初始设为无碰撞
    for t = 0:0.1:1  % 以0.1步长线性插值11个采样点
        x = x1 + t*(x2-x1);  % 采样点x坐标
        y = y1 + t*(y2-y1);  % 采样点y坐标
        c = round(x/res)+1;  % 采样点对应栅格列号
        r = round(y/res)+1;  % 采样点对应栅格行号
        r = max(1,min(rows,r));  % 行号限幅到有效范围
        c = max(1,min(cols,c));  % 列号限幅到有效范围
        if obs_map(r,c)  % 该栅格被障碍物占据
            hit = true;  % 标记碰撞
            return;  % 立即返回
        end
    end
end

%% 判断节点是否在列表中
function found = is_in_list(lst, x, y, theta, tol)
    if isempty(lst)  % 列表为空
        found = false;  % 返回未找到
        return;
    end
    d = hypot(lst(:,1)-x, lst(:,2)-y);  % 各节点到目标点的欧氏距离
    a = abs(atan2(sin(lst(:,3)-theta), cos(lst(:,3)-theta)));  % 航向角差值的绝对值
    found = any(d < tol & a < 0.1);  % 距离和角度均在容差内则找到
end

%% 在列表中查找节点并返回索引
function idx = find_in_list(lst, x, y, theta, tol)
    if isempty(lst)  % 列表为空
        idx = 0; return;  % 返回0
    end
    d = hypot(lst(:,1)-x, lst(:,2)-y);  % 各节点到目标点的欧氏距离
    a = abs(atan2(sin(lst(:,3)-theta), cos(lst(:,3)-theta)));  % 航向角差值
    idx = find(d < tol & a < 0.1, 1);  % 返回第一个匹配节点的索引
    if isempty(idx), idx = 0; end  % 未找到返回0
end

%% 路径回溯：从终点沿parent_idx回溯到起点
function path = backtrack(CloseList, start_pos)
    cur = size(CloseList, 1);  % 从CloseList最后一个节点（终点）开始
    pts = {};  % 初始化路径点元胞数组
    for k = 1:size(CloseList, 1)  % 最多回溯全部节点
        pts{end+1} = [CloseList(cur,1), CloseList(cur,2), CloseList(cur,3)]; %#ok<AGROW>  % 添加当前节点
        parent_idx = CloseList(cur, 6);  % 读取父节点索引
        if parent_idx == 0  % 父节点索引为0表示已回溯到起点
            break;  % 停止回溯
        end
        cur = parent_idx;  % 跳到父节点继续回溯
    end

    pts = flip(pts);  % 翻转顺序，使起点在前终点在后
    path = cell2mat(pts(:));  % 将元胞数组转为数值矩阵[x,y,θ]
end

%% 路径均值平滑处理
function sp = smooth_path(p, n)
    sp = p;  % 初始化为原始路径
    for pass = 1:n  % 迭代n次平滑
        tmp = sp;  % 创建临时副本
        for i = 2:size(sp,1)-1  % 内部点进行三点加权平均
            tmp(i,1) = 0.25*sp(i-1,1) + 0.5*sp(i,1) + 0.25*sp(i+1,1);  % x坐标平滑
            tmp(i,2) = 0.25*sp(i-1,2) + 0.5*sp(i,2) + 0.25*sp(i+1,2);  % y坐标平滑
        end
        sp = tmp;  % 更新路径
    end
    for i = 1:size(sp,1)-1  % 平滑后重新计算各点航向角
        sp(i,3) = atan2(sp(i+1,2)-sp(i,2), sp(i+1,1)-sp(i,1));  % 由相邻点差分求航向
    end
    sp(end,3) = sp(end-1,3);  % 终点航向角与倒数第二点相同
end

%% 规划结果可视化
function draw_map(obstacles, path, sp, gp, mw, mh)
    figure('Color','w','Position',[100,100,800,500]);  % 创建白色背景图窗
    hold on;  % 保持绘图
    for i = 1:size(obstacles,1)  % 遍历绘制每个障碍物
        x1=obstacles(i,1); y1=obstacles(i,2);  % 障碍物左下角
        x2=obstacles(i,3); y2=obstacles(i,4);  % 障碍物右上角
        fill([x1 x2 x2 x1],[y1 y1 y2 y2],[0.85 0.85 0.85],'EdgeColor','k');  % 灰色填充矩形
    end
    plot(path(:,1),path(:,2),'r-','LineWidth',2.5);  % 规划路径红色实线
    plot(sp(1),sp(2),'go','MarkerSize',12,'LineWidth',2);  % 起点绿色圆点
    plot(gp(1),gp(2),'rx','MarkerSize',12,'LineWidth',2);  % 终点红色叉号
    for i = 1:5:size(path,1)  % 每5个路径点绘制一个航向箭头
        quiver(path(i,1),path(i,2),0.2*cos(path(i,3)),0.2*sin(path(i,3)), ...  % 箭头表示航向
            'b','LineWidth',1,'MaxHeadSize',0.8);
    end
    grid on; axis equal; xlim([0 mw]); ylim([0 mh]);  % 网格、等比例、坐标范围
    xlabel('X (m)'); ylabel('Y (m)');  % 坐标轴标签
    title('Hybrid A* 路径规划结果');  % 图标题
    legend('货架','规划路径','起点','终点','航向','Location','best');  % 图例
    saveas(gcf, 'hybrid_astar_result.png');  % 保存结果图
    fprintf('已保存: hybrid_astar_result.png\n');  % 打印保存信息
end
