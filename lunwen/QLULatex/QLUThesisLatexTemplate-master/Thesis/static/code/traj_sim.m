%% 差速机器人典型轨迹运动学仿真
%  演示差速底盘在四种速度指令下的轨迹特征与轮速变化：
%  直线(v=0.45)、定曲率圆(v=0.35,ω=0.45)、S形(正弦转向)、8字(高频正弦)
clear; clc; close all;

r = 0.09;  % 车轮半径(m)
L = 0.52;  % 轮距(m)
dt = 0.01;  % 积分步长(s)
T = 20;  % 仿真总时长(s)
t = 0:dt:T;  % 时间序列

x0 = [0; 0; 0];  % 初始位姿[x, y, θ]

%% 四种典型轨迹的控制输入定义
cases = {
    struct('name', '直线轨迹',    'color', [0.00,0.45,0.74], 'u', @(tt) deal(0.45+0*tt, 0*tt)), ...  % v=0.45, ω=0
    struct('name', '定曲率圆轨迹', 'color', [0.85,0.33,0.10], 'u', @(tt) deal(0.35+0*tt, 0.45+0*tt)), ...  % v=0.35, ω=0.45
    struct('name', 'S形轨迹',     'color', [0.47,0.67,0.19], 'u', @(tt) deal(0.40+0*tt, 0.6*sin(0.5*tt))), ...  % 正弦转向
    struct('name', '8字轨迹',     'color', [0.49,0.18,0.56], 'u', @(tt) deal(0.38+0*tt, 0.7*sin(0.7*tt))) ...  % 高频正弦转向
    };

Ncase = numel(cases);  % 轨迹种数
results = cell(Ncase, 1);  % 缓存每组仿真结果

for i = 1:Ncase
    [v_cmd, omega_cmd] = cases{i}.u(t(1:end-1));  % 提取当前轨迹的速度指令
    sim = simulate_diff_drive(v_cmd, omega_cmd, t, x0, r, L);  % 运动学正解
    sim.name = cases{i}.name;  % 记录轨迹名称
    sim.color = cases{i}.color;  % 记录绘图颜色
    sim.metrics = analyze_metrics(sim, dt);  % 计算运动学指标
    results{i} = sim;
end

%% 轨迹XY平面对比图
figure('Color', 'w', 'Name', '差速机器人典型轨迹对比');  % 创建白色背景图窗
hold on; grid on; axis equal;  % 开启图形保持、网格、等比例坐标轴
xlabel('x (m)'); ylabel('y (m)');  % 坐标轴标签
title('典型轨迹对比');  % 图标题

for i = 1:Ncase  % 遍历四种轨迹
    s = results{i};  % 取出当前轨迹仿真结果
    plot(s.x, s.y, 'LineWidth', 2.0, 'Color', s.color, 'DisplayName', s.name);  % 绘制轨迹曲线
    plot(s.x(1), s.y(1), 'o', 'Color', s.color, 'MarkerFaceColor', s.color);  % 起点标记(实心圆)
    plot(s.x(end), s.y(end), 's', 'Color', s.color, 'MarkerFaceColor', s.color);  % 终点标记(实心方块)
end
legend('Location', 'best');  % 图例自动放置

%% 控制输入与轮速曲线
figure('Color', 'w', 'Name', '控制输入与轮速曲线');  % 创建图窗
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');  % 3行1列紧凑布局

nexttile;  % 第1行: 线速度指令
hold on; grid on;  % 开启图形保持和网格
for i = 1:Ncase  % 遍历四种轨迹
    s = results{i};
    plot(s.t(1:end-1), s.v_cmd, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);  % 绘制线速度指令曲线
end
ylabel('v (m/s)'); title('线速度指令');  % Y轴标签和图标题
legend('Location', 'best');  % 图例自动放置

nexttile;  % 第2行: 角速度指令
hold on; grid on;  % 开启图形保持和网格
for i = 1:Ncase  % 遍历四种轨迹
    s = results{i};
    plot(s.t(1:end-1), s.omega_cmd, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);  % 绘制角速度指令曲线
end
ylabel('\omega (rad/s)'); title('角速度指令');  % Y轴标签和图标题

nexttile;  % 第3行: 左右轮角速度
hold on; grid on;  % 开启图形保持和网格
for i = 1:Ncase  % 遍历四种轨迹
    s = results{i};
    plot(s.t(1:end-1), s.wr, '-', 'LineWidth', 1.1, 'Color', s.color, 'DisplayName', [s.name, ' 右轮']);  % 右轮角速度(实线)
    plot(s.t(1:end-1), s.wl, '--', 'LineWidth', 1.1, 'Color', s.color, 'DisplayName', [s.name, ' 左轮']);  % 左轮角速度(虚线)
end
xlabel('时间 (s)'); ylabel('轮角速度 (rad/s)'); title('左右轮角速度');  % 坐标轴标签和图标题

%% 瞬时曲率对比
figure('Color', 'w', 'Name', '曲率变化曲线');  % 创建图窗
hold on; grid on;  % 开启图形保持和网格
for i = 1:Ncase  % 遍历四种轨迹
    s = results{i};
    plot(s.t(1:end-1), s.kappa, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);  % 绘制瞬时曲率曲线
end
xlabel('时间 (s)'); ylabel('\kappa (1/m)');  % 坐标轴标签
title('瞬时曲率 (\kappa = \omega / v)');  % 图标题: κ=ω/v
legend('Location', 'best');  % 图例自动放置

%% 四轨迹同步动画
export_gif = false;  % 改为true可导出GIF
gif_dir = 'animation_output';  % GIF输出目录
gif_file = fullfile(gif_dir, '四轨迹同步动画.gif');  % GIF文件名

if export_gif && ~exist(gif_dir, 'dir')  % 如需导出且目录不存在则创建
    mkdir(gif_dir);  % 创建输出目录
end

fig_anim = figure('Color', 'w', 'Name', '小车运动动画 - 四轨迹同步');  % 创建动画图窗
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');  % 2×2紧凑布局

car_r = 0.10;  % 车体圆盘半径(m)
car_outline_x = car_r * cos(linspace(0, 2*pi, 50));  % 圆盘轮廓X
car_outline_y = car_r * sin(linspace(0, 2*pi, 50));  % 圆盘轮廓Y
heading_len = 0.18;  % 航向箭头长度(m)
margin = 0.3;  % 坐标轴边距

car_body = gobjects(Ncase, 1);  % 车体圆盘句柄
car_center = gobjects(Ncase, 1);  % 质心句柄
car_heading = gobjects(Ncase, 1);  % 航向箭头句柄
car_trail = gobjects(Ncase, 1);  % 轨迹句柄

for i = 1:Ncase  % 为每个轨迹创建子图
    nexttile;  % 切换到下一个子图
    s = results{i};  % 取出当前轨迹结果
    hold on; grid on; axis equal;  % 开启图形保持、网格、等比例坐标轴
    xlabel('x (m)'); ylabel('y (m)');  % 坐标轴标签
    title(['轨迹 ', num2str(i), ' - ', s.name]);  % 子图标题

    plot(s.x, s.y, '--', 'Color', [0.75, 0.75, 0.75], 'LineWidth', 1.0, ...  % 灰色虚线参考轨迹
        'DisplayName', '参考轨迹');
    xlim([min(s.x)-margin, max(s.x)+margin]);  % X轴范围加边距
    ylim([min(s.y)-margin, max(s.y)+margin]);  % Y轴范围加边距

    car_body(i) = plot(s.x(1)+car_outline_x, s.y(1)+car_outline_y, ...  % 绘制车体圆盘
        'Color', s.color, 'LineWidth', 2.0, 'DisplayName', '车体');
    car_center(i) = plot(s.x(1), s.y(1), 'o', 'Color', s.color, ...  % 绘制质心标记
        'MarkerFaceColor', s.color, 'DisplayName', '质心');
    car_heading(i) = plot([s.x(1), s.x(1)+heading_len*cos(s.theta(1))], ...  % 绘制航向箭头
        [s.y(1), s.y(1)+heading_len*sin(s.theta(1))], ...
        'r-', 'LineWidth', 2.0, 'DisplayName', '航向');
    car_trail(i) = plot(s.x(1), s.y(1), '-', 'Color', [0.10,0.10,0.10], ...  % 绘制运动轨迹(深灰色)
        'LineWidth', 1.2, 'DisplayName', '运动轨迹');
    legend('Location', 'best');  % 图例自动放置
end

step = max(1, round(0.03 / dt));  % 约30FPS帧步长
frame_count = 0;  % GIF帧计数
gif_enabled = export_gif;  % GIF导出开关

for k = 1:step:numel(t)  % 逐帧更新动画
    for i = 1:Ncase  % 更新四个子图中的小车位置
        s = results{i};  % 取出当前轨迹结果
        ki = min(k, numel(s.t));  % 防止索引越界
        set(car_body(i), 'XData', s.x(ki)+car_outline_x, 'YData', s.y(ki)+car_outline_y);  % 更新车体位置
        set(car_center(i), 'XData', s.x(ki), 'YData', s.y(ki));  % 更新质心位置
        set(car_heading(i), ...  % 更新航向箭头
            'XData', [s.x(ki), s.x(ki)+heading_len*cos(s.theta(ki))], ...
            'YData', [s.y(ki), s.y(ki)+heading_len*sin(s.theta(ki))]);
        set(car_trail(i), 'XData', s.x(1:ki), 'YData', s.y(1:ki));  % 更新已走轨迹
    end

    drawnow;  % 强制刷新图形窗口

    if gif_enabled  % GIF导出模式
        if ~isgraphics(fig_anim, 'figure')  % 检查图窗是否有效
            warning('动画窗口句柄无效，已停止 GIF 导出。');
            gif_enabled = false;  % 停止导出
            continue;  % 跳过本帧
        end
        frame_count = frame_count + 1;  % 帧计数加1
        try  % 尝试捕获帧并写入GIF
            ax = gca;  % 获取当前坐标轴
            if isgraphics(ax, 'axes')  % 如果坐标轴有效
                frame_img = getframe(ax);  % 捕获坐标轴区域
            else
                frame_img = getframe(fig_anim);  % 否则捕获整个图窗
            end
            [img_ind, img_map] = rgb2ind(frame2im(frame_img), 256);  % RGB转索引图像(256色)
            if frame_count == 1  % 第一帧: 创建GIF文件
                imwrite(img_ind, img_map, gif_file, 'gif', 'LoopCount', inf, 'DelayTime', 0.03);
            else  % 后续帧: 追加到GIF
                imwrite(img_ind, img_map, gif_file, 'gif', 'WriteMode', 'append', 'DelayTime', 0.03);
            end
        catch ME  % 捕获导出异常
            warning('traj_sim:GifExportFailed', '%s', ME.message);
            gif_enabled = false;  % 停止导出
        end
    end
end

if gif_enabled  % GIF导出成功
    disp(['动画已导出: ', gif_file]);  % 显示导出路径
elseif export_gif  % 导出失败但开关打开
    disp('GIF 未导出成功，但动画播放已完成。');
end

%% 汇总性能指标
names = strings(Ncase, 1);  % 轨迹名称数组
path_len = zeros(Ncase, 1);  % 路径总长数组
disp_len = zeros(Ncase, 1);  % 终点位移数组
avg_v = zeros(Ncase, 1);  % 平均速度数组
max_abs_omega = zeros(Ncase, 1);  % 最大|ω|数组
max_abs_kappa = zeros(Ncase, 1);  % 最大|κ|数组
final_heading_deg = zeros(Ncase, 1);  % 终点航向(°)数组

for i = 1:Ncase  % 遍历四种轨迹提取指标
    names(i) = results{i}.name;  % 轨迹名称
    m = results{i}.metrics;  % 取出指标结构体
    path_len(i) = m.path_len;  % 路径总长
    disp_len(i) = m.disp_len;  % 终点位移
    avg_v(i) = m.avg_v;  % 平均速度
    max_abs_omega(i) = m.max_abs_omega;  % 最大|ω|
    max_abs_kappa(i) = m.max_abs_kappa;  % 最大|κ|
    final_heading_deg(i) = m.final_heading_deg;  % 终点航向(°)
end

summary_tbl = table(names, path_len, disp_len, avg_v, max_abs_omega, max_abs_kappa, final_heading_deg, ...  % 创建汇总表格
    'VariableNames', {'轨迹类型', '路径长度_m', '位移_m', '平均速度_mps', '最大角速度_radps', '最大曲率_1pm', '终点航向角_deg'});

disp('================ 典型轨迹仿真分析汇总 ================');  % 打印表头
disp(summary_tbl);  % 打印汇总表格

%% 差速底盘运动学正解函数
function sim = simulate_diff_drive(v_cmd, omega_cmd, t, x0, r, L)
N = numel(t);  % 时间步数
x = zeros(1, N);  % X坐标序列
y = zeros(1, N);  % Y坐标序列
theta = zeros(1, N);  % 航向角序列

x(1) = x0(1);  % 初始X
y(1) = x0(2);  % 初始Y
theta(1) = x0(3);  % 初始θ

wr = (2 .* v_cmd + omega_cmd .* L) ./ (2 * r);  % 右轮角速度(逆运动学)
wl = (2 .* v_cmd - omega_cmd .* L) ./ (2 * r);  % 左轮角速度(逆运动学)

dt = t(2) - t(1);  % 积分步长
for k = 1:N-1  % 前向欧拉积分
    x(k+1) = x(k) + v_cmd(k) * cos(theta(k)) * dt;  % X位置更新
    y(k+1) = y(k) + v_cmd(k) * sin(theta(k)) * dt;  % Y位置更新
    theta(k+1) = atan2(sin(theta(k) + omega_cmd(k) * dt), cos(theta(k) + omega_cmd(k) * dt));  % 航向角归一化更新
end

eps_v = 1e-6;  % 防止除零的小量
kappa = omega_cmd ./ max(abs(v_cmd), eps_v);  % 瞬时曲率 κ = ω/v

sim = struct();  % 创建输出结构体
sim.t = t;  % 时间序列
sim.x = x;  % X轨迹
sim.y = y;  % Y轨迹
sim.theta = theta;  % 航向角序列
sim.v_cmd = v_cmd;  % 线速度指令
sim.omega_cmd = omega_cmd;  % 角速度指令
sim.wr = wr;  % 右轮角速度
sim.wl = wl;  % 左轮角速度
sim.kappa = kappa;  % 瞬时曲率
end

%% 轨迹性能指标计算
function metrics = analyze_metrics(sim, dt)
dx = diff(sim.x);  % X方向差分
dy = diff(sim.y);  % Y方向差分

path_len = sum(hypot(dx, dy));  % 路径总长 Σ√(dx²+dy²)
disp_len = hypot(sim.x(end)-sim.x(1), sim.y(end)-sim.y(1));  % 起止直线距离
avg_v = mean(abs(sim.v_cmd));  % 平均线速度
max_abs_omega = max(abs(sim.omega_cmd));  % 最大角速度绝对值
max_abs_kappa = max(abs(sim.kappa));  % 最大曲率绝对值
final_heading_deg = rad2deg(sim.theta(end));  % 终点航向角(转角度制)

metrics = struct();  % 创建输出结构体
metrics.path_len = path_len;  % 路径总长
metrics.disp_len = disp_len;  % 终点位移
metrics.avg_v = avg_v;  % 平均速度
metrics.max_abs_omega = max_abs_omega;  % 最大角速度
metrics.max_abs_kappa = max_abs_kappa;  % 最大曲率
metrics.final_heading_deg = final_heading_deg;  % 终点航向角
metrics.sim_time = (numel(sim.t) - 1) * dt;  % 仿真总时长
end
