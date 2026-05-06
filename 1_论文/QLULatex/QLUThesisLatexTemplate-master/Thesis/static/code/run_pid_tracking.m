%% ========== Hybrid A* + PID 轨迹跟踪仿真 ==========
%  加载 Hybrid A* 规划的参考路径, 运行 PID 控制器做轨迹跟踪
%  纯 MATLAB, 不依赖 Simulink
%
%  控制结构 (同 diff_drive_robot_pid_system.slx):
%    XY控制器 → 角度PID → 分速度模块 → 轮速PID+电机模型 → 运动学积分
%
%  使用: 直接在 MATLAB 中 F5 运行
clear; clc; close all;

%% ==================== 1. 生成 Hybrid A* 参考路径 ====================
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = pwd; end

% 添加路径规划代码目录 (附录代码需将 hybrid_astar_pathplanning.m 放于同目录)
plan_dir = fullfile(script_dir, '..', '路径规划与循迹');
if exist(plan_dir, 'dir'), addpath(plan_dir); end

fprintf('正在运行 Hybrid A* 路径规划...\n');
path_raw = hybrid_astar_pathplanning();

% 等间距插值 (0.05m)
dx = diff(path_raw(:,1)); dy = diff(path_raw(:,2));
seg_len = hypot(dx, dy);
cum_s = [0; cumsum(seg_len)];
ds = 0.05;
s_query = 0:ds:cum_s(end);
x_ref   = interp1(cum_s, path_raw(:,1), s_query, 'linear')';
y_ref   = interp1(cum_s, path_raw(:,2), s_query, 'linear')';
theta_ref = interp1(cum_s, path_raw(:,3), s_query, 'linear')';
theta_ref = atan2(sin(theta_ref), cos(theta_ref));
s_ref   = s_query';
total_len = s_ref(end);

fprintf('========== Hybrid A* + PID 轨迹跟踪 ==========\n');
fprintf('参考路径: %d 点,  %.2f m\n', length(x_ref), total_len);

%% ==================== 2. 参数设置 ====================
% AGV物理参数
r_wheel = 0.075;    % 车轮半径 (m)
L_base  = 0.52;     % 轮距 (m)

% PID参数 (同原Simulink模型)
Kp_xy     = 1.4;
Kp_theta  = 4.0;   Ki_theta = 0.3;   Kd_theta = 0.05;
Kp_wheel  = 3.0;   Ki_wheel = 1.2;   Kd_wheel = 0.03;

% 电机模型
motor_gain = 1.0;
motor_tau  = 0.15;

% 仿真
dt   = 0.01;
v_max = 0.5;

%% ==================== 3. 梯形速度曲线 ====================
accel = 0.3;  decel = 0.3;
t_acc = v_max / accel;
t_dec = v_max / decel;
d_cruise = max(0, total_len - v_max^2/(2*accel) - v_max^2/(2*decel));
T_total = t_acc + d_cruise / v_max + t_dec + 10;

n_steps = ceil(T_total / dt);
t_vec   = (0:n_steps-1)' * dt;
fprintf('仿真: %.1f s, %d 步, dt=%.2f s\n', T_total, n_steps, dt);

% 弧长进度 → 参考位姿
s_prog = zeros(n_steps, 1);
v_cur  = 0;  s_cur = 0;
for k = 1:n_steps
    tn = t_vec(k);
    if tn < t_acc
        v_des = v_max * tn / t_acc;
    elseif tn > T_total - t_dec
        v_des = v_max * max(0, (T_total - tn) / t_dec);
    else
        v_des = v_max;
    end
    if v_des > v_cur, v_cur = min(v_des, v_cur + accel*dt);
    else,              v_cur = max(v_des, v_cur - decel*dt); end
    s_cur = s_cur + v_cur * dt;
    s_prog(k) = min(s_cur, total_len);
end
x_cmd = interp1(s_ref, x_ref, s_prog, 'linear', 'extrap');
y_cmd = interp1(s_ref, y_ref, s_prog, 'linear', 'extrap');

%% ==================== 4. PID 轨迹跟踪主循环 ====================
% 初始状态
x = x_ref(1);  y = y_ref(1);  theta = theta_ref(1);

% PID积分/微分状态
ang_int = 0;   ang_prev = 0;
wl_int  = 0;   wl_prev  = 0;
wr_int  = 0;   wr_prev  = 0;
motor_wl = 0;  motor_wr = 0;

% 日志
log = zeros(n_steps, 7);  % [t, x, y, theta, v, omega, err]

for k = 1:n_steps
    % --- XY控制器 ---
    dx = x_cmd(k) - x;
    dy = y_cmd(k) - y;
    v_cmd = Kp_xy * sqrt(dx^2 + dy^2);
    v_cmd = max(-0.8, min(0.8, v_cmd));
    ang_tgt = atan2(dy, dx);

    % --- 角度PID ---
    ang_err = atan2(sin(ang_tgt - theta), cos(ang_tgt - theta));
    ang_int = ang_int + ang_err * dt;
    ang_der = (ang_err - ang_prev) / dt;
    ang_prev = ang_err;
    omega_cmd = Kp_theta*ang_err + Ki_theta*ang_int + Kd_theta*ang_der;
    omega_cmd = max(-1.5, min(1.5, omega_cmd));

    % --- 分速度 → 左右轮目标 ---
    wl_tgt = (v_cmd - omega_cmd * L_base/2) / r_wheel;
    wr_tgt = (v_cmd + omega_cmd * L_base/2) / r_wheel;

    % --- 左轮PID + 电机 ---
    wl_err = wl_tgt - motor_wl;
    wl_int = wl_int + wl_err*dt;
    wl_der = (wl_err - wl_prev)/dt;  wl_prev = wl_err;
    wl_drv = Kp_wheel*wl_err + Ki_wheel*wl_int + Kd_wheel*wl_der;
    wl_drv = wl_drv + 0.10 + 0.10*sin(1.15*t_vec(k));
    motor_wl = motor_wl + (motor_gain*wl_drv - motor_wl)/motor_tau * dt;

    % --- 右轮PID + 电机 ---
    wr_err = wr_tgt - motor_wr;
    wr_int = wr_int + wr_err*dt;
    wr_der = (wr_err - wr_prev)/dt;  wr_prev = wr_err;
    wr_drv = Kp_wheel*wr_err + Ki_wheel*wr_int + Kd_wheel*wr_der;
    wr_drv = wr_drv - 0.10 + 0.10*sin(0.82*t_vec(k));
    motor_wr = motor_wr + (motor_gain*wr_drv - motor_wr)/motor_tau * dt;

    % --- 运动学 ---
    v_act = r_wheel*(motor_wl + motor_wr)/2;
    w_act = r_wheel*(motor_wr - motor_wl)/L_base;
    x     = x + v_act*cos(theta)*dt;
    y     = y + v_act*sin(theta)*dt;
    theta = theta + w_act*dt;
    theta = atan2(sin(theta), cos(theta));

    % 日志
    log(k, :) = [t_vec(k), x, y, theta, v_act, w_act, sqrt((x-x_cmd(k))^2+(y-y_cmd(k))^2)];
end

%% ==================== 5. 结果 ====================
rms_err   = sqrt(mean(log(:,7).^2));
max_err   = max(log(:,7));
final_err = log(end, 7);

fprintf('\n========== 结果 ==========\n');
fprintf('RMS跟踪误差:   %.3f m\n', rms_err);
fprintf('最大跟踪误差:  %.3f m\n', max_err);
fprintf('终点误差:      %.3f m\n', final_err);
fprintf('仿真时长:       %.1f s\n', log(end,1));

%% ==================== 6. 绘图 ====================
% 图1: XY轨迹
figure('Color','w','Position',[50,80,1100,450]);
subplot(1,2,1);
plot(x_ref, y_ref, 'b-','LineWidth',1.5); hold on;
plot(log(:,2), log(:,3), 'r--','LineWidth',1.2);
plot(x_ref(1), y_ref(1), 'go','MarkerSize',10,'LineWidth',2);
plot(x_ref(end), y_ref(end), 'rx','MarkerSize',10,'LineWidth',2);
grid on; axis equal;
xlabel('X (m)'); ylabel('Y (m)');
title('Hybrid A* 参考路径 vs PID 跟踪轨迹');
legend('参考路径','PID跟踪','起点','终点','Location','best');

subplot(1,2,2);
plot(log(:,1), log(:,7), 'r-','LineWidth',1.2); hold on;
yline(rms_err, 'b--', sprintf('RMS=%.3fm', rms_err), 'LineWidth',1.5);
grid on; xlabel('时间 (s)'); ylabel('误差 (m)');
title('跟踪误差'); legend('瞬时','RMS');

% 图2: 速度
figure('Color','w','Position',[50,560,1100,350]);
subplot(2,1,1); plot(log(:,1), log(:,5), 'b-','LineWidth',1);
grid on; ylabel('v (m/s)'); title('线速度');
subplot(2,1,2); plot(log(:,1), log(:,6), 'r-','LineWidth',1);
grid on; ylabel('\omega (rad/s)'); xlabel('时间 (s)'); title('角速度');

% 图3: X/Y分量
figure('Color','w','Position',[50,940,1100,300]);
plot(log(:,1), x_cmd, 'b-','DisplayName','X_{ref}'); hold on;
plot(log(:,1), log(:,2), 'r--','DisplayName','X_{act}');
plot(log(:,1), y_cmd, 'c-','DisplayName','Y_{ref}');
plot(log(:,1), log(:,3), 'm--','DisplayName','Y_{act}');
grid on; xlabel('时间 (s)'); ylabel('位置 (m)');
title('X/Y分量跟踪'); legend('Location','best');

fprintf('图表已生成\n');
