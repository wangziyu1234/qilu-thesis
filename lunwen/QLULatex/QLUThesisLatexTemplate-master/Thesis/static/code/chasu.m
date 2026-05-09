clear; clc; close all;

% 差速机器人典型轨迹仿真与分析
% 状态: [x, y, theta]
% 运动学模型: x_dot = v*cos(theta), y_dot = v*sin(theta), theta_dot = omega
% 轮速映射: wr = (2*v + omega*L)/(2*r), wl = (2*v - omega*L)/(2*r)

%% 机器人与仿真参数
r = 0.075;     % 轮半径 [m]
L = 0.52;      % 轮距 [m]
dt = 0.01;     % 积分步长 [s]
T = 20;        % 仿真时长 [s]
t = 0:dt:T;    % 时间向量

x0 = [0; 0; 0];  % 初始位姿 [x0; y0; theta0]

%% 通过 v(t), omega(t) 定义典型轨迹
cases = {
    struct('name', '直线轨迹',    'color', [0.00,0.45,0.74], 'u', @(tt) deal(0.45+0*tt, 0*tt)), ...
    struct('name', '定曲率圆轨迹', 'color', [0.85,0.33,0.10], 'u', @(tt) deal(0.35+0*tt, 0.45+0*tt)), ...
    struct('name', 'S形轨迹',     'color', [0.47,0.67,0.19], 'u', @(tt) deal(0.40+0*tt, 0.6*sin(0.5*tt))), ...
    struct('name', '8字轨迹',     'color', [0.49,0.18,0.56], 'u', @(tt) deal(0.38+0*tt, 0.7*sin(0.7*tt))) ...
    };
% 直线:  v=0.45, omega=0
% 圆:    v=0.35, omega=0.45 (定曲率)
% S形:   v=0.40, omega=0.6*sin(0.5t) (正弦转向)
% 8字:   v=0.38, omega=0.7*sin(0.7t) (高频正弦转向)

Ncase = numel(cases);              % 轨迹数量
results = cell(Ncase, 1);          % 存储各轨迹仿真结果

for i = 1:Ncase
    [v_cmd, omega_cmd] = cases{i}.u(t(1:end-1));  % 提取线速度和角速度指令
    sim = simulate_diff_drive(v_cmd, omega_cmd, t, x0, r, L);  % 运动学正解
    sim.name = cases{i}.name;      % 轨迹名称
    sim.color = cases{i}.color;    % 绘图颜色
    sim.metrics = analyze_metrics(sim, dt);  % 计算运动学指标
    results{i} = sim;              % 存入结果
end

%% 绘制 XY 平面轨迹
figure('Color', 'w', 'Name', '差速机器人典型轨迹对比');
hold on; grid on; axis equal;
xlabel('x (m)'); ylabel('y (m)');
title('典型轨迹对比');

for i = 1:Ncase
    s = results{i};
    plot(s.x, s.y, 'LineWidth', 2.0, 'Color', s.color, 'DisplayName', s.name);  % 轨迹线
    plot(s.x(1), s.y(1), 'o', 'Color', s.color, 'MarkerFaceColor', s.color);    % 起点圆点
    plot(s.x(end), s.y(end), 's', 'Color', s.color, 'MarkerFaceColor', s.color); % 终点方块
end
legend('Location', 'best');

%% 绘制控制输入与轮速曲线
figure('Color', 'w', 'Name', '控制输入与轮速曲线');
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;  % 子图1: 线速度指令
hold on; grid on;
for i = 1:Ncase
    s = results{i};
    plot(s.t(1:end-1), s.v_cmd, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);
end
ylabel('v (m/s)'); title('线速度指令');
legend('Location', 'best');

nexttile;  % 子图2: 角速度指令
hold on; grid on;
for i = 1:Ncase
    s = results{i};
    plot(s.t(1:end-1), s.omega_cmd, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);
end
ylabel('\omega (rad/s)'); title('角速度指令');

nexttile;  % 子图3: 左右轮角速度
hold on; grid on;
for i = 1:Ncase
    s = results{i};
    plot(s.t(1:end-1), s.wr, '-', 'LineWidth', 1.1, 'Color', s.color, 'DisplayName', [s.name, ' 右轮']);
    plot(s.t(1:end-1), s.wl, '--', 'LineWidth', 1.1, 'Color', s.color, 'DisplayName', [s.name, ' 左轮']);
end
xlabel('时间 (s)'); ylabel('轮角速度 (rad/s)'); title('左右轮角速度');

%% 曲率对比
figure('Color', 'w', 'Name', '曲率变化曲线');
hold on; grid on;
for i = 1:Ncase
    s = results{i};
    plot(s.t(1:end-1), s.kappa, 'LineWidth', 1.5, 'Color', s.color, 'DisplayName', s.name);
end
xlabel('时间 (s)'); ylabel('\kappa (1/m)');
title('瞬时曲率 (\kappa = \omega / v)');
legend('Location', 'best');

%% 小车运动动画（四种轨迹同步播放）
% 圆盘表示车体, 红色箭头指示航向, 四类轨迹同时在 2×2 子图中播放
export_gif = false;                    % 是否导出 GIF 文件
gif_dir = 'animation_output';          % GIF 输出目录
gif_file = fullfile(gif_dir, '四轨迹同步动画.gif');

if export_gif && ~exist(gif_dir, 'dir')
    mkdir(gif_dir);                    % 创建输出目录
end

fig_anim = figure('Color', 'w', 'Name', '小车运动动画 - 四轨迹同步');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% 小车外形参数 (简化为圆盘 + 航向箭头)
car_r = 0.10;                          % 车体圆盘半径 [m]
car_outline_x = car_r * cos(linspace(0, 2*pi, 50));  % 圆盘 x 坐标
car_outline_y = car_r * sin(linspace(0, 2*pi, 50));  % 圆盘 y 坐标
heading_len = 0.18;                    % 航向箭头长度 [m]
margin = 0.3;                          % 坐标轴边距 [m]

% 预分配图元句柄
car_body = gobjects(Ncase, 1);         % 车体圆盘句柄
car_center = gobjects(Ncase, 1);       % 质心点句柄
car_heading = gobjects(Ncase, 1);      % 航向箭头句柄
car_trail = gobjects(Ncase, 1);        % 运动轨迹句柄

for i = 1:Ncase                        % 初始化各子图
    nexttile;
    s = results{i};
    hold on; grid on; axis equal;
    xlabel('x (m)'); ylabel('y (m)');
    title(['轨迹 ', num2str(i), ' - ', s.name]);

    plot(s.x, s.y, '--', 'Color', [0.75, 0.75, 0.75], 'LineWidth', 1.0);  % 灰色参考轨迹
    xlim([min(s.x)-margin, max(s.x)+margin]);
    ylim([min(s.y)-margin, max(s.y)+margin]);

    car_body(i) = plot(s.x(1)+car_outline_x, s.y(1)+car_outline_y, ...
        'Color', s.color, 'LineWidth', 2.0);           % 初始车体位置
    car_center(i) = plot(s.x(1), s.y(1), 'o', 'Color', s.color, ...
        'MarkerFaceColor', s.color);                   % 初始质心位置
    car_heading(i) = plot([s.x(1), s.x(1)+heading_len*cos(s.theta(1))], ...
        [s.y(1), s.y(1)+heading_len*sin(s.theta(1))], ...
        'r-', 'LineWidth', 2.0);                       % 初始航向箭头
    car_trail(i) = plot(s.x(1), s.y(1), '-', 'Color', [0.10,0.10,0.10], ...
        'LineWidth', 1.2);                             % 初始轨迹
    legend('Location', 'best');
end

% 动画帧率控制: 约 30 FPS, 跳帧显示
step = max(1, round(0.03 / dt));
frame_count = 0;
gif_enabled = export_gif;

for k = 1:step:numel(t)                % 按步长跳帧播放
    for i = 1:Ncase
        s = results{i};
        ki = min(k, numel(s.t));       % 确保不越界
        set(car_body(i), 'XData', s.x(ki)+car_outline_x, 'YData', s.y(ki)+car_outline_y);
        set(car_center(i), 'XData', s.x(ki), 'YData', s.y(ki));
        set(car_heading(i), ...
            'XData', [s.x(ki), s.x(ki)+heading_len*cos(s.theta(ki))], ...
            'YData', [s.y(ki), s.y(ki)+heading_len*sin(s.theta(ki))]);
        set(car_trail(i), 'XData', s.x(1:ki), 'YData', s.y(1:ki));
    end

    drawnow;                           % 刷新图形

    if gif_enabled                     % GIF 帧写入
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
            warning('chasu:GifExportFailed', '%s', ME.message);
            gif_enabled = false;
        end
    end
end

if gif_enabled
    disp(['动画已导出: ', gif_file]);
elseif export_gif
    disp('GIF 未导出成功，但动画播放已完成。');
end

%% 汇总指标表
% 提取各轨迹的路径长度、位移、平均速度、最大角速度、最大曲率等指标
names = strings(Ncase, 1);
path_len = zeros(Ncase, 1);
disp_len = zeros(Ncase, 1);
avg_v = zeros(Ncase, 1);
max_abs_omega = zeros(Ncase, 1);
max_abs_kappa = zeros(Ncase, 1);
final_heading_deg = zeros(Ncase, 1);

for i = 1:Ncase
    names(i) = results{i}.name;                      % 轨迹名称
    m = results{i}.metrics;                          % 指标结构体
    path_len(i) = m.path_len;                        % 路径总长度 [m]
    disp_len(i) = m.disp_len;                        % 终点位移 [m]
    avg_v(i) = m.avg_v;                              % 平均速度 [m/s]
    max_abs_omega(i) = m.max_abs_omega;              % 最大角速度绝对值 [rad/s]
    max_abs_kappa(i) = m.max_abs_kappa;              % 最大曲率绝对值 [1/m]
    final_heading_deg(i) = m.final_heading_deg;      % 终点航向角 [deg]
end

summary_tbl = table(names, path_len, disp_len, avg_v, max_abs_omega, max_abs_kappa, final_heading_deg, ...
    'VariableNames', {'轨迹类型', '路径长度_m', '位移_m', '平均速度_mps', '最大角速度_radps', '最大曲率_1pm', '终点航向角_deg'});

disp('================ 典型轨迹仿真分析汇总 ================');
disp(summary_tbl);

%% 局部函数

% 差速底盘运动学正解仿真: 给定 v(t) 和 ω(t), 欧拉积分求解位姿
function sim = simulate_diff_drive(v_cmd, omega_cmd, t, x0, r, L)
N = numel(t);                          % 时间点数
x = zeros(1, N);                       % x 坐标序列
y = zeros(1, N);                       % y 坐标序列
theta = zeros(1, N);                   % 航向角序列

x(1) = x0(1);                          % 初始 x
y(1) = x0(2);                          % 初始 y
theta(1) = x0(3);                      % 初始 theta

% 轮速按差速运动学反算
wr = (2 .* v_cmd + omega_cmd .* L) ./ (2 * r);  % 右轮角速度 [rad/s]
wl = (2 .* v_cmd - omega_cmd .* L) ./ (2 * r);  % 左轮角速度 [rad/s]

dt = t(2) - t(1);                      % 时间步长
for k = 1:N-1                          % 欧拉前向积分
    x(k+1) = x(k) + v_cmd(k) * cos(theta(k)) * dt;     % x 更新
    y(k+1) = y(k) + v_cmd(k) * sin(theta(k)) * dt;     % y 更新
    theta(k+1) = atan2(sin(theta(k) + omega_cmd(k) * dt), cos(theta(k) + omega_cmd(k) * dt));
end

% 曲率 κ = ω/v (避免除零)
eps_v = 1e-6;
kappa = omega_cmd ./ max(abs(v_cmd), eps_v);  % 瞬时曲率 [1/m]

sim = struct();                        % 打包输出结构体
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

% 轨迹分析: 计算路径长度、位移、平均速度、曲率等指标
function metrics = analyze_metrics(sim, dt)
dx = diff(sim.x);                      % x 方向差分
dy = diff(sim.y);                      % y 方向差分

path_len = sum(hypot(dx, dy));         % 路径总长度: Σ√(dx²+dy²)
disp_len = hypot(sim.x(end)-sim.x(1), sim.y(end)-sim.y(1));  % 终点位移
avg_v = mean(abs(sim.v_cmd));          % 平均线速度 [m/s]
max_abs_omega = max(abs(sim.omega_cmd));    % 最大角速度绝对值 [rad/s]
max_abs_kappa = max(abs(sim.kappa));        % 最大曲率绝对值 [1/m]
final_heading_deg = rad2deg(sim.theta(end)); % 终点航向角 [deg]

metrics = struct();                    % 打包输出
metrics.path_len = path_len;
metrics.disp_len = disp_len;
metrics.avg_v = avg_v;
metrics.max_abs_omega = max_abs_omega;
metrics.max_abs_kappa = max_abs_kappa;
metrics.final_heading_deg = final_heading_deg;
metrics.sim_time = (numel(sim.t) - 1) * dt;  % 仿真总时长 [s]
end
