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
figure('Color', 'w', 'Name', '差速机器人典型轨迹对比');
hold on; grid on; axis equal;
xlabel('x (m)'); ylabel('y (m)');
title('典型轨迹对比');

for i = 1:Ncase
    s = results{i};
    plot(s.x, s.y, 'LineWidth', 2.0, 'Color', s.color, 'DisplayName', s.name);
    plot(s.x(1), s.y(1), 'o', 'Color', s.color, 'MarkerFaceColor', s.color);  % 起点标记
    plot(s.x(end), s.y(end), 's', 'Color', s.color, 'MarkerFaceColor', s.color);  % 终点标记
end
legend('Location', 'best');

%% 控制输入与轮速曲线
figure('Color', 'w', 'Name', '控制输入与轮速曲线');
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;  % 线速度指令
hold on; grid on;
for i = 1:Ncase
    s = results{i};
    plot(s.t(1:end-1), s.v_cmd, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);
end
ylabel('v (m/s)'); title('线速度指令');
legend('Location', 'best');

nexttile;  % 角速度指令
hold on; grid on;
for i = 1:Ncase
    s = results{i};
    plot(s.t(1:end-1), s.omega_cmd, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);
end
ylabel('\omega (rad/s)'); title('角速度指令');

nexttile;  % 左右轮角速度
hold on; grid on;
for i = 1:Ncase
    s = results{i};
    plot(s.t(1:end-1), s.wr, '-', 'LineWidth', 1.1, 'Color', s.color, 'DisplayName', [s.name, ' 右轮']);
    plot(s.t(1:end-1), s.wl, '--', 'LineWidth', 1.1, 'Color', s.color, 'DisplayName', [s.name, ' 左轮']);
end
xlabel('时间 (s)'); ylabel('轮角速度 (rad/s)'); title('左右轮角速度');

%% 瞬时曲率对比
figure('Color', 'w', 'Name', '曲率变化曲线');
hold on; grid on;
for i = 1:Ncase
    s = results{i};
    plot(s.t(1:end-1), s.kappa, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);
end
xlabel('时间 (s)'); ylabel('\kappa (1/m)');
title('瞬时曲率 (\kappa = \omega / v)');
legend('Location', 'best');

%% 四轨迹同步动画
export_gif = false;  % 改为true可导出GIF
gif_dir = 'animation_output';
gif_file = fullfile(gif_dir, '四轨迹同步动画.gif');

if export_gif && ~exist(gif_dir, 'dir')
    mkdir(gif_dir);
end

fig_anim = figure('Color', 'w', 'Name', '小车运动动画 - 四轨迹同步');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

car_r = 0.10;  % 车体圆盘半径(m)
car_outline_x = car_r * cos(linspace(0, 2*pi, 50));  % 圆盘轮廓X
car_outline_y = car_r * sin(linspace(0, 2*pi, 50));  % 圆盘轮廓Y
heading_len = 0.18;  % 航向箭头长度(m)
margin = 0.3;  % 坐标轴边距

car_body = gobjects(Ncase, 1);  % 车体圆盘句柄
car_center = gobjects(Ncase, 1);  % 质心句柄
car_heading = gobjects(Ncase, 1);  % 航向箭头句柄
car_trail = gobjects(Ncase, 1);  % 轨迹句柄

for i = 1:Ncase
    nexttile;
    s = results{i};
    hold on; grid on; axis equal;
    xlabel('x (m)'); ylabel('y (m)');
    title(['轨迹 ', num2str(i), ' - ', s.name]);

    plot(s.x, s.y, '--', 'Color', [0.75, 0.75, 0.75], 'LineWidth', 1.0, ...
        'DisplayName', '参考轨迹');
    xlim([min(s.x)-margin, max(s.x)+margin]);
    ylim([min(s.y)-margin, max(s.y)+margin]);

    car_body(i) = plot(s.x(1)+car_outline_x, s.y(1)+car_outline_y, ...
        'Color', s.color, 'LineWidth', 2.0, 'DisplayName', '车体');
    car_center(i) = plot(s.x(1), s.y(1), 'o', 'Color', s.color, ...
        'MarkerFaceColor', s.color, 'DisplayName', '质心');
    car_heading(i) = plot([s.x(1), s.x(1)+heading_len*cos(s.theta(1))], ...
        [s.y(1), s.y(1)+heading_len*sin(s.theta(1))], ...
        'r-', 'LineWidth', 2.0, 'DisplayName', '航向');
    car_trail(i) = plot(s.x(1), s.y(1), '-', 'Color', [0.10,0.10,0.10], ...
        'LineWidth', 1.2, 'DisplayName', '运动轨迹');
    legend('Location', 'best');
end

step = max(1, round(0.03 / dt));  % 约30FPS帧步长
frame_count = 0;  % GIF帧计数
gif_enabled = export_gif;

for k = 1:step:numel(t)
    for i = 1:Ncase
        s = results{i};
        ki = min(k, numel(s.t));
        set(car_body(i), 'XData', s.x(ki)+car_outline_x, 'YData', s.y(ki)+car_outline_y);
        set(car_center(i), 'XData', s.x(ki), 'YData', s.y(ki));
        set(car_heading(i), ...
            'XData', [s.x(ki), s.x(ki)+heading_len*cos(s.theta(ki))], ...
            'YData', [s.y(ki), s.y(ki)+heading_len*sin(s.theta(ki))]);
        set(car_trail(i), 'XData', s.x(1:ki), 'YData', s.y(1:ki));
    end

    drawnow;

    if gif_enabled
        if ~isgraphics(fig_anim, 'figure')
            warning('动画窗口句柄无效，已停止 GIF 导出。');
            gif_enabled = false;
            continue;
        end
        frame_count = frame_count + 1;
        try
            ax = gca;
            if isgraphics(ax, 'axes')
                frame_img = getframe(ax);
            else
                frame_img = getframe(fig_anim);
            end
            [img_ind, img_map] = rgb2ind(frame2im(frame_img), 256);
            if frame_count == 1
                imwrite(img_ind, img_map, gif_file, 'gif', 'LoopCount', inf, 'DelayTime', 0.03);
            else
                imwrite(img_ind, img_map, gif_file, 'gif', 'WriteMode', 'append', 'DelayTime', 0.03);
            end
        catch ME
            warning('traj_sim:GifExportFailed', '%s', ME.message);
            gif_enabled = false;
        end
    end
end

if gif_enabled
    disp(['动画已导出: ', gif_file]);
elseif export_gif
    disp('GIF 未导出成功，但动画播放已完成。');
end

%% 汇总性能指标
names = strings(Ncase, 1);
path_len = zeros(Ncase, 1);
disp_len = zeros(Ncase, 1);
avg_v = zeros(Ncase, 1);
max_abs_omega = zeros(Ncase, 1);
max_abs_kappa = zeros(Ncase, 1);
final_heading_deg = zeros(Ncase, 1);

for i = 1:Ncase
    names(i) = results{i}.name;
    m = results{i}.metrics;
    path_len(i) = m.path_len;  % 路径总长
    disp_len(i) = m.disp_len;  % 终点位移
    avg_v(i) = m.avg_v;  % 平均速度
    max_abs_omega(i) = m.max_abs_omega;  % 最大|ω|
    max_abs_kappa(i) = m.max_abs_kappa;  % 最大|κ|
    final_heading_deg(i) = m.final_heading_deg;  % 终点航向(°)
end

summary_tbl = table(names, path_len, disp_len, avg_v, max_abs_omega, max_abs_kappa, final_heading_deg, ...
    'VariableNames', {'轨迹类型', '路径长度_m', '位移_m', '平均速度_mps', '最大角速度_radps', '最大曲率_1pm', '终点航向角_deg'});

disp('================ 典型轨迹仿真分析汇总 ================');
disp(summary_tbl);

%% 差速底盘运动学正解函数
function sim = simulate_diff_drive(v_cmd, omega_cmd, t, x0, r, L)
N = numel(t);
x = zeros(1, N);
y = zeros(1, N);
theta = zeros(1, N);

x(1) = x0(1);
y(1) = x0(2);
theta(1) = x0(3);

wr = (2 .* v_cmd + omega_cmd .* L) ./ (2 * r);  % 右轮角速度
wl = (2 .* v_cmd - omega_cmd .* L) ./ (2 * r);  % 左轮角速度

dt = t(2) - t(1);
for k = 1:N-1
    x(k+1) = x(k) + v_cmd(k) * cos(theta(k)) * dt;
    y(k+1) = y(k) + v_cmd(k) * sin(theta(k)) * dt;
    theta(k+1) = atan2(sin(theta(k) + omega_cmd(k) * dt), cos(theta(k) + omega_cmd(k) * dt));  % 航向角归一化
end

eps_v = 1e-6;  % 防止除零
kappa = omega_cmd ./ max(abs(v_cmd), eps_v);  % κ = ω/v

sim = struct();
sim.t = t;
sim.x = x;
sim.y = y;
sim.theta = theta;
sim.v_cmd = v_cmd;
sim.omega_cmd = omega_cmd;
sim.wr = wr;
sim.wl = wl;
sim.kappa = kappa;
end

%% 轨迹性能指标计算
function metrics = analyze_metrics(sim, dt)
dx = diff(sim.x);
dy = diff(sim.y);

path_len = sum(hypot(dx, dy));  % Σ√(dx²+dy²)
disp_len = hypot(sim.x(end)-sim.x(1), sim.y(end)-sim.y(1));  % 起止直线距离
avg_v = mean(abs(sim.v_cmd));
max_abs_omega = max(abs(sim.omega_cmd));
max_abs_kappa = max(abs(sim.kappa));
final_heading_deg = rad2deg(sim.theta(end));  % 转角度制

metrics = struct();
metrics.path_len = path_len;
metrics.disp_len = disp_len;
metrics.avg_v = avg_v;
metrics.max_abs_omega = max_abs_omega;
metrics.max_abs_kappa = max_abs_kappa;
metrics.final_heading_deg = final_heading_deg;
metrics.sim_time = (numel(sim.t) - 1) * dt;
end
