function line_following_pid(ref_path)
%LINE_FOLLOWING_PID  红外传感器 PID 循迹仿真
%   模拟 5 路 TCRT5000 红外传感器检测黑线, PID 差速纠偏
%
%   输入: ref_path [x, y, theta] 参考路径 (来自 Hybrid A*)

if nargin < 1
    t = linspace(0, 3.5*pi, 200);
    ref_path = [2 + 1.5*cos(t)', 2 + 0.8*sin(t)', atan2(0.8*cos(t), -1.5*sin(t))'];
end

%% ==================== 1. 参数设置 ====================
r_wheel = 0.075;
L_base  = 0.52;
v_nom   = 0.3;            % 标称速度 (m/s)

n_sensors  = 5;
sensor_spacing = 0.04;
sensor_offsets = (-2:2) * sensor_spacing;
line_width = 0.03;         % 黑线检测宽度 (m), 3cm 比较实际

Kp = 3.0;  Ki = 0.08;  Kd = 1.0;

dt       = 0.01;
max_time = 80;

%% ==================== 2. 路径预处理 ====================
ref_x = ref_path(:, 1);
ref_y = ref_path(:, 2);
n_ref = size(ref_path, 1);
path_len = sum(hypot(diff(ref_x), diff(ref_y)));

fprintf('\n========== PID 循迹仿真 ==========\n');
fprintf('参考路径: %d 点, %.2f m\n', n_ref, path_len);

%% ==================== 3. 仿真主循环 ====================
n_steps = ceil(max_time / dt);
log = zeros(n_steps, 7);

x = ref_x(1);  y = ref_y(1);  theta = ref_path(1, 3);
e_int = 0;  e_prev = 0;

for k = 1:n_steps
    t_now = (k-1) * dt;

    % --- 3.1 传感器检测 ---
    sx = x + sensor_offsets * cos(theta + pi/2);
    sy = y + sensor_offsets * sin(theta + pi/2);

    sensor_state = zeros(1, n_sensors);
    for s = 1:n_sensors
        d = point_to_path(sx(s), sy(s), ref_x, ref_y);
        if d < line_width
            sensor_state(s) = 1;
        end
    end

    % --- 3.2 偏移量 ---
    weights = -4:2:4;
    active = find(sensor_state == 1);

    if ~isempty(active)
        offset = mean(weights(active));
    else
        offset = e_prev * 1.5;
    end

    % 实际横向误差 (评估用)
    [~, min_i] = min((ref_x - x).^2 + (ref_y - y).^2);
    tang = ref_path(min_i, 3);
    lat_err = -(x - ref_x(min_i))*sin(tang) + (y - ref_y(min_i))*cos(tang);

    % --- 3.3 PID ---
    e_int = e_int + offset * dt;
    e_int = max(-2, min(2, e_int));
    e_der = (offset - e_prev) / dt;
    e_prev = offset;

    omega = Kp * offset + Ki * e_int + Kd * e_der;
    omega = max(-1.5, min(1.5, omega));

    % --- 3.4 运动学 ---
    x     = x + v_nom * cos(theta) * dt;
    y     = y + v_nom * sin(theta) * dt;
    theta = theta + omega * dt;
    theta = atan2(sin(theta), cos(theta));

    log(k, :) = [t_now, x, y, theta, v_nom, omega, lat_err];

    % --- 3.5 到达终点 ---
    if hypot(x - ref_x(end), y - ref_y(end)) < 0.2
        fprintf('到达终点! t = %.1f s\n', t_now);
        log = log(1:k, :);
        break;
    end
end

%% ==================== 4. 结果 ====================
rms_err  = sqrt(mean(log(:,7).^2));
max_err  = max(abs(log(:,7)));
final_t  = log(end, 1);

fprintf('RMS 横向误差:  %.4f m (%.1f cm)\n', rms_err, rms_err*100);
fprintf('最大横向误差:  %.4f m (%.1f cm)\n', max_err, max_err*100);
fprintf('仿真时长:      %.1f s\n', final_t);

%% ==================== 5. 绘图 ====================
figure('Color', 'w', 'Position', [50, 80, 1200, 500]);

subplot(2, 2, 1);
plot(ref_x, ref_y, 'b-', 'LineWidth', 2); hold on;
plot(log(:,2), log(:,3), 'r--', 'LineWidth', 1.2);
plot(ref_x(1), ref_y(1), 'go', 'MarkerSize', 10, 'LineWidth', 2);
plot(ref_x(end), ref_y(end), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
grid on; axis equal;
xlabel('X (m)'); ylabel('Y (m)');
title('参考路径 vs 循迹轨迹');
legend('参考', '循迹', '起点', '终点', 'Location', 'best');

subplot(2, 2, 2);
plot(log(:,1), log(:,7)*100, 'r-', 'LineWidth', 1); hold on;
yline( rms_err*100, 'b--', sprintf('RMS=%.1fcm', rms_err*100));
yline(-rms_err*100, 'b--');
yline( line_width*100, 'g:');
yline(-line_width*100, 'g:');
grid on; xlabel('时间 (s)'); ylabel('误差 (cm)');
title('循迹横向误差');

subplot(2, 2, 3);
plot(log(:,1), log(:,6), 'r-', 'LineWidth', 1);
grid on; xlabel('时间 (s)'); ylabel('\omega (rad/s)');
title('纠偏角速度');

subplot(2, 2, 4);
hold on; grid on; axis equal;
rectangle('Position', [-0.10,-0.06,0.20,0.12], 'Curvature', 0.2, 'EdgeColor', 'b', 'LineWidth', 2);
for s = 1:n_sensors
    plot(sensor_offsets(s), 0.06, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
end
plot([-0.08, 0.08], [0.06, 0.06], 'k-', 'LineWidth', 3);
xlabel('横向 (m)'); ylabel('纵向 (m)');
title('5路红外传感器布局');

saveas(gcf, 'line_following_result.png');
fprintf('已保存: line_following_result.png\n');

% 单独保存传感器布局图 (论文用)
fig2 = figure('Color', 'w', 'Position', [200, 200, 350, 280]);
hold on; grid on; axis equal;
rectangle('Position', [-0.10,-0.06,0.20,0.12], 'Curvature', 0.2, 'EdgeColor', 'b', 'LineWidth', 2);
for s = 1:n_sensors
    plot(sensor_offsets(s), 0.06, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
end
plot([-0.08, 0.08], [0.06, 0.06], 'k-', 'LineWidth', 3);
xlabel('横向 (m)'); ylabel('纵向 (m)');
title('5路红外传感器布局');
saveas(fig2, 'sensor_layout.png');
fprintf('已保存: sensor_layout.png\n');
end

%% ======================== 辅助函数 ========================

function d = point_to_path(px, py, path_x, path_y)
    d = inf;
    n = length(path_x);
    for i = 1:n-1
        ax = path_x(i); ay = path_y(i);
        bx = path_x(i+1); by = path_y(i+1);
        abx = bx-ax; aby = by-ay;
        apx = px-ax; apy = py-ay;
        ab2 = abx^2 + aby^2;
        if ab2 < 1e-10
            t = 0;
        else
            t = max(0, min(1, (apx*abx+apy*aby)/ab2));
        end
        cx = ax + t*abx;
        cy = ay + t*aby;
        d = min(d, hypot(px-cx, py-cy));
    end
end
