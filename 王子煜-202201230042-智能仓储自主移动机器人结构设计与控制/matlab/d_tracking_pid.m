%% 红外传感器PID循迹仿真
%  5路红外传感器横向排布, 检测黑线偏移量, PID输出角速度纠偏
%  以Hybrid A*规划路径为参考，5路红外检测横向偏移，PID纠偏输出角速度
function d_tracking_pid(ref_path)
if nargin < 1  % 无输入时用默认椭圆路径
    t = linspace(0, 3.5*pi, 200);
    ref_path = [2 + 1.5*cos(t)', 2 + 0.8*sin(t)', ...
                atan2(0.8*cos(t), -1.5*sin(t))'];
end

%% —— 小车参数 ——
r_wheel = 0.09;  % 车轮半径(m)
L_base  = 0.52;  % 轮距(m)
v_nom   = 0.25;  % 标称速度(m/s)

n_sensors  = 5;  % 传感器个数
sensor_spacing = 0.04;  % 间距(m)
sensor_offsets = (-2:2) * sensor_spacing;  % 各传感器横向偏移
line_width = 0.03;  % 黑线宽度(m)

Kp = 3.0;   Ki = 0.08;   Kd = 1.0;  % PID参数

dt       = 0.01;  % 步长(s)
max_time = 80;  % 最大仿真时长(s)

%% —— 参考路径预处理(插值加密) ——
ref_x_orig = ref_path(:, 1);
ref_y_orig = ref_path(:, 2);
n_orig = size(ref_path, 1);

% 计算累积弧长
s_orig = zeros(n_orig, 1);
for i = 2:n_orig
    s_orig(i) = s_orig(i-1) + hypot(ref_x_orig(i)-ref_x_orig(i-1), ...
                                     ref_y_orig(i)-ref_y_orig(i-1));
end

% 插值：每0.02m一个点
ds = 0.02;  % 插值间距(m)
s_interp = 0:ds:s_orig(end);
ref_x = interp1(s_orig, ref_x_orig, s_interp, 'pchip');
ref_y = interp1(s_orig, ref_y_orig, s_interp, 'pchip');
n_ref = length(ref_x);

% 计算每个插值点的切线方向（航向角）
ref_theta = zeros(1, n_ref);
for i = 1:n_ref-1
    ref_theta(i) = atan2(ref_y(i+1)-ref_y(i), ref_x(i+1)-ref_x(i));
end
ref_theta(end) = ref_theta(end-1);

% 计算路径曲率(用于前馈控制)
ref_kappa = zeros(1, n_ref);
for i = 2:n_ref-1
    dtheta = ref_theta(i+1) - ref_theta(i);
    dtheta = atan2(sin(dtheta), cos(dtheta));  % 归一化到[-pi,pi]
    ref_kappa(i) = dtheta / ds;  % 曲率 = dθ/ds
end
ref_kappa(1) = ref_kappa(2);
ref_kappa(end) = ref_kappa(end-1);
% 对曲率做平滑,避免噪声
kappa_smooth = 5;  % 平滑窗口(点数)
ref_kappa = movmean(ref_kappa, kappa_smooth);

path_len = s_orig(end);  % 路径总长度

fprintf('\n========== PID 循迹仿真 ==========\n');
fprintf('参考路径: %d 点, %.2f m\n', n_ref, path_len);

%% —— 仿真主循环 ——
n_steps = ceil(max_time / dt);
log = zeros(n_steps, 7);  % [t, x, y, θ, v, ω, lat_err]

x = ref_x(1);  y = ref_y(1);  % 初始位置
theta = ref_theta(1);  % 初始航向
e_int = 0;  e_prev = 0;  % 积分和上拍偏差

% omega输出移动平均滤波器
ma_window = 6;  % 移动平均窗口长度(点数)
omega_buf = zeros(1, ma_window);  % 环形缓冲区
ma_idx = 0;  % 缓冲区写入指针

% 软启动参数
v_ramp_time = 1.0;  % 速度爬升时间(s)

for k = 1:n_steps
    t_now = (k-1) * dt;

    % 软启动: 速度在v_ramp_time内从0线性爬升到v_nom
    if t_now < v_ramp_time
        v_now = v_nom * (t_now / v_ramp_time);
    else
        v_now = v_nom;
    end

    % 传感器位置
    fwd = 0.08;  % 传感器距车体前端距离(m)
    sx = x + fwd*cos(theta) + sensor_offsets * cos(theta + pi/2);
    sy = y + fwd*sin(theta) + sensor_offsets * sin(theta + pi/2);

    sensor_state = zeros(1, n_sensors);
    for s = 1:n_sensors
        d = point_to_path(sx(s), sy(s), ref_x, ref_y);  % 到参考路径最短距离
        if d < line_width
            sensor_state(s) = 1;  % 检测到黑线
        end
    end

    active = find(sensor_state == 1);

    % 横向误差计算(始终计算,用于记录、丢线处理和前馈)
    [~, min_i] = min((ref_x - x).^2 + (ref_y - y).^2);  % 路径最近点
    tang = ref_theta(min_i);  % 该点切线方向
    lat_err = -(x - ref_x(min_i))*sin(tang) + (y - ref_y(min_i))*cos(tang);  % 法向误差

    on_line = ~isempty(active);

    if on_line
        % 传感器质心偏移: 用检测到的传感器物理位置平均值
        offset = mean(sensor_offsets(active)) / sensor_spacing;
    else  % 丢线: 基于横向误差外推
        offset = sign(lat_err) * min(abs(lat_err) * 15, 3);
    end

    e_int = e_int + offset * dt;
    e_int = max(-2, min(2, e_int));  % 积分限幅防饱和
    e_der = (offset - e_prev) / dt;
    e_prev = offset;

    omega_pid = Kp * offset + Ki * e_int + Kd * e_der;  % PID输出

    % 曲率前馈: omega_ff = v * kappa, 预判弯道
    omega_ff = v_now * ref_kappa(min_i);

    omega_raw = omega_pid + omega_ff;  % PID + 前馈
    omega_raw = max(-1.5, min(1.5, omega_raw));  % ±1.5rad/s限幅

    % 移动平均滤波(比IIR更有效地抑制高频毛刺)
    ma_idx = mod(ma_idx, ma_window) + 1;
    omega_buf(ma_idx) = omega_raw;
    omega = mean(omega_buf);

    x     = x + v_now * cos(theta) * dt;
    y     = y + v_now * sin(theta) * dt;
    theta = theta + omega * dt;
    theta = atan2(sin(theta), cos(theta));  % 归一化航向

    log(k, :) = [t_now, x, y, theta, v_now, omega, lat_err];

    if hypot(x - ref_x(end), y - ref_y(end)) < 0.2  % 距终点<0.2m
        fprintf('到达终点! t = %.1f s\n', t_now);
        log = log(1:k, :);
        break;
    end
end

%% —— 性能指标 ——
rms_err  = sqrt(mean(log(:,7).^2));  % 横向误差RMS
max_err  = max(abs(log(:,7)));  % 最大横向误差
final_t  = log(end, 1);

fprintf('RMS 横向误差:  %.4f m (%.1f cm)\n', rms_err, rms_err*100);
fprintf('最大横向误差:  %.4f m (%.1f cm)\n', max_err, max_err*100);
fprintf('仿真时长:      %.1f s\n', final_t);

%% —— 结果绘图 ——

figure('Color', 'w', 'Position', [50, 80, 700, 550]);  % 图1: 轨迹对比
plot(ref_x, ref_y, 'b-', 'LineWidth', 2); hold on;  % 蓝色实线: 参考路径
plot(log(:,2), log(:,3), 'r--', 'LineWidth', 1.2);  % 红色虚线: 循迹轨迹
plot(ref_x(1), ref_y(1), 'go', 'MarkerSize', 10, 'LineWidth', 2);  % 绿色圆圈: 起点
plot(ref_x(end), ref_y(end), 'rx', 'MarkerSize', 10, 'LineWidth', 2);  % 红色叉号: 终点
grid on; axis equal;  % 开启网格和等比例坐标轴
xlabel('X (m)'); ylabel('Y (m)');  % 坐标轴标签
title('参考路径 vs 循迹轨迹');  % 图标题
legend('参考', '循迹', '起点', '终点', 'Location', 'best');  % 图例
out_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');  % 图片输出目录
if ~exist(out_dir, 'dir'), mkdir(out_dir); end  % 如目录不存在则创建
fname1 = fullfile(out_dir, 'line_following_traj.png');  % 拼接文件名
saveas(gcf, fname1);  % 保存图窗
fprintf('已保存: %s\n', fname1);  % 打印保存路径

figure('Color', 'w', 'Position', [100, 100, 800, 450]);  % 图2: 横向误差时程
plot(log(:,1), log(:,7)*100, 'r-', 'LineWidth', 1); hold on;  % 红色实线: 横向误差(cm)
yline( rms_err*100, 'b--', sprintf('RMS=%.1fcm', rms_err*100));  % 蓝色虚线: +RMS线
yline(-rms_err*100, 'b--');  % 蓝色虚线: -RMS线
yline( line_width*100, 'g:');  % 绿色点线: +黑线宽度
yline(-line_width*100, 'g:');  % 绿色点线: -黑线宽度
grid on; xlabel('时间 (s)'); ylabel('误差 (cm)');  % 坐标轴标签
title('循迹横向误差');  % 图标题
fname2 = fullfile(out_dir, 'line_following_error.png');  % 拼接文件名
saveas(gcf, fname2);  % 保存图窗
fprintf('已保存: %s\n', fname2);  % 打印保存路径

figure('Color', 'w', 'Position', [150, 120, 800, 450]);  % 图3: 角速度指令
omg_rms = sqrt(mean(log(:,6).^2));  % 角速度RMS
plot(log(:,1), log(:,6), 'r-', 'LineWidth', 1); hold on;  % 红色实线: 角速度指令
yline( omg_rms, 'b--', sprintf('RMS=%.2f rad/s', omg_rms));  % 蓝色虚线: +RMS线
yline(-omg_rms, 'b--');  % 蓝色虚线: -RMS线
yline(0, 'k:');  % 黑色点线: 零线
grid on; xlabel('时间 (s)'); ylabel('\omega (rad/s)');  % 坐标轴标签
title('纠偏角速度指令');  % 图标题
legend('角速度指令', 'Location', 'best');  % 图例
fname3 = fullfile(out_dir, 'line_following_omega.png');  % 拼接文件名
saveas(gcf, fname3);  % 保存图窗
fprintf('已保存: %s\n', fname3);  % 打印保存路径

figure('Color', 'w', 'Position', [200, 140, 400, 350]);  % 图4: 传感器布局示意
hold on; grid on; axis equal;  % 开启图形保持、网格、等比例坐标轴
rectangle('Position', [-0.10,-0.06,0.20,0.12], 'Curvature', 0.2, ...  % 绘制圆角矩形车体
          'EdgeColor', 'b', 'LineWidth', 2);
for s = 1:n_sensors  % 绘制5个红外传感器
    plot(sensor_offsets(s), 0.06, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r');  % 红色方块传感器
end
plot([-0.08, 0.08], [0.06, 0.06], 'k-', 'LineWidth', 3);  % 黑色粗线: 黑线轨迹
xlabel('横向 (m)'); ylabel('纵向 (m)');  % 坐标轴标签
title('5路红外传感器布局');  % 图标题
fname4 = fullfile(out_dir, 'sensor_layout.png');  % 拼接文件名
saveas(gcf, fname4);  % 保存图窗
fprintf('已保存: %s\n', fname4);  % 打印保存路径
end

%% 点到多段线最短距离
function d = point_to_path(px, py, path_x, path_y)
    d = inf;
    n = length(path_x);
    for i = 1:n-1  % 逐段计算
        ax = path_x(i);   ay = path_y(i);
        bx = path_x(i+1); by = path_y(i+1);
        abx = bx-ax;  aby = by-ay;  % 线段向量
        apx = px-ax;  apy = py-ay;  % 点到起点向量
        ab2 = abx^2 + aby^2;
        if ab2 < 1e-10  % 退化为点
            t = 0;
        else
            t = max(0, min(1, (apx*abx+apy*aby)/ab2));  % 投影参数截断[0,1]
        end
        cx = ax + t*abx;
        cy = ay + t*aby;
        d = min(d, hypot(px-cx, py-cy));
    end
end
