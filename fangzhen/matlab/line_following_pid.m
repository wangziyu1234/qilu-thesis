function line_following_pid(ref_path)
%LINE_FOLLOWING_PID  红外传感器 PID 循迹仿真
%   模拟 5 路 TCRT5000 红外传感器检测黑线, PID 差速纠偏
%   输入: ref_path [x, y, theta] 参考路径 (来自 Hybrid A*)

if nargin < 1                                           % 无输入时使用默认椭圆形路径
    t = linspace(0, 3.5*pi, 200);                       % 参数 t: 0~3.5π, 200 点
    ref_path = [2 + 1.5*cos(t)', 2 + 0.8*sin(t)', ...
                atan2(0.8*cos(t), -1.5*sin(t))'];       % [x, y, theta] 椭圆路径
end

%% ==================== 1. 参数设置 ====================
r_wheel = 0.075;                % 车轮半径 [m]
L_base  = 0.52;                 % 轮距 [m]
v_nom   = 0.3;                  % 标称行驶速度 [m/s]

n_sensors  = 5;                 % 红外传感器数量
sensor_spacing = 0.04;          % 传感器间距 [m]
sensor_offsets = (-2:2) * sensor_spacing;  % 各传感器横向偏移: [-0.08, -0.04, 0, 0.04, 0.08] m
line_width = 0.03;              % 黑线检测宽度 [m]

Kp = 3.0;                       % 循迹 PID 比例增益
Ki = 0.08;                      % 循迹 PID 积分增益
Kd = 1.0;                       % 循迹 PID 微分增益

dt       = 0.01;                % 仿真步长 [s]
max_time = 80;                  % 最大仿真时长 [s]

%% ==================== 2. 路径预处理 ====================
ref_x = ref_path(:, 1);         % 参考路径 x 坐标序列
ref_y = ref_path(:, 2);         % 参考路径 y 坐标序列
n_ref = size(ref_path, 1);      % 参考路径点数
path_len = sum(hypot(diff(ref_x), diff(ref_y)));  % 路径总长度 [m]

fprintf('\n========== PID 循迹仿真 ==========\n');
fprintf('参考路径: %d 点, %.2f m\n', n_ref, path_len);

%% ==================== 3. 仿真主循环 ====================
n_steps = ceil(max_time / dt);  % 最大仿真步数
log = zeros(n_steps, 7);        % 日志: [t, x, y, theta, v, omega, lat_err]

x = ref_x(1);                   % 初始 x [m]
y = ref_y(1);                   % 初始 y [m]
theta = ref_path(1, 3);         % 初始航向角 [rad]
e_int = 0;                      % 积分项初值
e_prev = 0;                     % 上一时刻偏移量

for k = 1:n_steps
    t_now = (k-1) * dt;         % 当前仿真时间 [s]

    % --- 3.1 传感器检测 (阵列位于车体前方 80mm) ---
    fwd = 0.08;                 % 传感器阵列前向安装距离 [m]
    % 各传感器在全局坐标系中的位置: 车体中心前移 + 横向偏移
    sx = x + fwd*cos(theta) + sensor_offsets * cos(theta + pi/2);
    sy = y + fwd*sin(theta) + sensor_offsets * sin(theta + pi/2);

    % 逐传感器判断是否检测到黑线 (距参考路径小于线宽)
    sensor_state = zeros(1, n_sensors);
    for s = 1:n_sensors
        d = point_to_path(sx(s), sy(s), ref_x, ref_y);  % 传感器到参考路径的最短距离
        if d < line_width
            sensor_state(s) = 1;    % 1 表示检测到黑线
        end
    end

    % --- 3.2 偏移量计算 ---
    % 传感器权重: 左侧负, 中间零, 右侧正
    weights = -4:2:4;
    active = find(sensor_state == 1);    % 检测到黑线的传感器编号

    if ~isempty(active)
        offset = mean(weights(active));  % 加权平均偏移量
    else
        offset = e_prev * 1.5;           % 丢线时外推, 加大纠偏力矩使车体回到可检测区域
    end

    % 实际横向误差 (评估用, 计算到参考路径最近点的法向距离)
    [~, min_i] = min((ref_x - x).^2 + (ref_y - y).^2);  % 找参考路径最近点索引
    tang = ref_path(min_i, 3);           % 该点的切线方向
    lat_err = -(x - ref_x(min_i))*sin(tang) + (y - ref_y(min_i))*cos(tang);  % 横向误差 [m]

    % --- 3.3 PID 控制 ---
    e_int = e_int + offset * dt;         % 积分累加
    e_int = max(-2, min(2, e_int));      % 积分抗饱和: 限幅 ±2
    e_der = (offset - e_prev) / dt;      % 微分项
    e_prev = offset;                     % 更新上一拍偏移量

    omega = Kp * offset + Ki * e_int + Kd * e_der;  % PID 输出角速度 [rad/s]
    omega = max(-1.5, min(1.5, omega));  % 角速度限幅 ±1.5 rad/s

    % --- 3.4 差速运动学更新 ---
    x     = x + v_nom * cos(theta) * dt; % x 方向位置更新
    y     = y + v_nom * sin(theta) * dt; % y 方向位置更新
    theta = theta + omega * dt;          % 航向角更新
    theta = atan2(sin(theta), cos(theta));  % 航向角归一化到 [-π, π]

    log(k, :) = [t_now, x, y, theta, v_nom, omega, lat_err];  % 记录当前步数据

    % --- 3.5 到达终点判断 ---
    if hypot(x - ref_x(end), y - ref_y(end)) < 0.2  % 距终点小于 0.2m
        fprintf('到达终点! t = %.1f s\n', t_now);
        log = log(1:k, :);              % 截断日志
        break;
    end
end

%% ==================== 4. 性能指标计算 ====================
rms_err  = sqrt(mean(log(:,7).^2));     % 横向误差 RMS [m]
max_err  = max(abs(log(:,7)));          % 最大横向误差 [m]
final_t  = log(end, 1);                 % 仿真实际耗时 [s]

fprintf('RMS 横向误差:  %.4f m (%.1f cm)\n', rms_err, rms_err*100);
fprintf('最大横向误差:  %.4f m (%.1f cm)\n', max_err, max_err*100);
fprintf('仿真时长:      %.1f s\n', final_t);

%% ==================== 5. 结果可视化 ====================
figure('Color', 'w', 'Position', [50, 80, 1200, 500]);  % 创建图形窗口

subplot(2, 2, 1);                       % 子图1: XY 轨迹对比
plot(ref_x, ref_y, 'b-', 'LineWidth', 2); hold on;  % 参考路径 (蓝色实线)
plot(log(:,2), log(:,3), 'r--', 'LineWidth', 1.2);  % 实际轨迹 (红色虚线)
plot(ref_x(1), ref_y(1), 'go', 'MarkerSize', 10, 'LineWidth', 2);  % 起点 (绿色圆点)
plot(ref_x(end), ref_y(end), 'rx', 'MarkerSize', 10, 'LineWidth', 2);  % 终点 (红色叉号)
grid on; axis equal;                    % 网格 + 等比例坐标
xlabel('X (m)'); ylabel('Y (m)');
title('参考路径 vs 循迹轨迹');
legend('参考', '循迹', '起点', '终点', 'Location', 'best');

subplot(2, 2, 2);                       % 子图2: 横向误差曲线
plot(log(:,1), log(:,7)*100, 'r-', 'LineWidth', 1); hold on;  % 误差曲线 [cm]
yline( rms_err*100, 'b--', sprintf('RMS=%.1fcm', rms_err*100));  % RMS 线
yline(-rms_err*100, 'b--');             % -RMS 线
yline( line_width*100, 'g:');           % 线宽上界
yline(-line_width*100, 'g:');           % 线宽下界
grid on; xlabel('时间 (s)'); ylabel('误差 (cm)');
title('循迹横向误差');

subplot(2, 2, 3);                       % 子图3: 纠偏角速度
plot(log(:,1), log(:,6), 'r-', 'LineWidth', 1);  % 角速度指令曲线
grid on; xlabel('时间 (s)'); ylabel('\omega (rad/s)');
title('纠偏角速度');

subplot(2, 2, 4);                       % 子图4: 传感器布局示意图
hold on; grid on; axis equal;
rectangle('Position', [-0.10,-0.06,0.20,0.12], 'Curvature', 0.2, ...
          'EdgeColor', 'b', 'LineWidth', 2);  % 车体外轮廓
for s = 1:n_sensors
    plot(sensor_offsets(s), 0.06, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r');  % 传感器位置
end
plot([-0.08, 0.08], [0.06, 0.06], 'k-', 'LineWidth', 3);  % 黑线 (粗黑实线)
xlabel('横向 (m)'); ylabel('纵向 (m)');
title('5路红外传感器布局');

saveas(gcf, 'line_following_result.png');  % 保存综合结果图
fprintf('已保存: line_following_result.png\n');

% 单独保存传感器布局图 (论文插图用)
fig2 = figure('Color', 'w', 'Position', [200, 200, 350, 280]);
hold on; grid on; axis equal;
rectangle('Position', [-0.10,-0.06,0.20,0.12], 'Curvature', 0.2, ...
          'EdgeColor', 'b', 'LineWidth', 2);  % 车体外轮廓
for s = 1:n_sensors
    plot(sensor_offsets(s), 0.06, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r');  % 传感器位置
end
plot([-0.08, 0.08], [0.06, 0.06], 'k-', 'LineWidth', 3);  % 黑线
xlabel('横向 (m)'); ylabel('纵向 (m)');
title('5路红外传感器布局');
saveas(fig2, 'sensor_layout.png');      % 保存传感器布局图
fprintf('已保存: sensor_layout.png\n');
end

%% ======================== 辅助函数 ========================
% 点到多段线的最短距离, 用于判断传感器是否落在黑线上
function d = point_to_path(px, py, path_x, path_y)
    d = inf;                            % 初始化为无穷大
    n = length(path_x);                 % 路径点数
    for i = 1:n-1                       % 遍历每一段线段
        ax = path_x(i);   ay = path_y(i);      % 线段起点
        bx = path_x(i+1); by = path_y(i+1);    % 线段终点
        abx = bx-ax;  aby = by-ay;             % 线段向量
        apx = px-ax;  apy = py-ay;             % 点到起点的向量
        ab2 = abx^2 + aby^2;                   % 线段长度的平方
        if ab2 < 1e-10                         % 线段极短时
            t = 0;                              % 投影参数取 0
        else
            t = max(0, min(1, (apx*abx+apy*aby)/ab2));  % 投影参数, 限制在 [0,1]
        end
        cx = ax + t*abx;                       % 投影点 x
        cy = ay + t*aby;                       % 投影点 y
        d = min(d, hypot(px-cx, py-cy));       % 更新最短距离
    end
end
