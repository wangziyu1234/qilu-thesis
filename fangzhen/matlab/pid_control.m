%% 双轮差速AGV PID控制器设计与控制效果仿真验证
%  功能: 仅保留与正文第六章对应的四项场景、四张图和汇总指标

clear; close all; clc;

%% ==================== 1. 参数设置 ====================
r = 0.09;            % 车轮半径 [m]
L = 0.52;            % 两轮间距 [m]
tau = 0.06;          % 电机机电时间常数 [s]
K_motor = 0.33;      % 电机增益 [(rad/s)/V]

Ts = 0.005;          % 仿真步长 [s]
T_sim = 12;          % 仿真总时长 [s]
t = 0:Ts:T_sim;      % 时间向量
N = length(t);       % 总步数

Kp_v = 2.0;          % 速度比例增益
Ki_v = 12.0;         % 速度积分增益
u_sat = 12;          % 电机电压限幅 [V]

Kp_dist  = 0.6;      % 距离→线速度 比例增益
Kp_theta = 3.0;      % 航向角 比例增益
Ki_theta = 0.2;      % 航向角 积分增益
Kd_theta = 0.4;      % 航向角 微分增益

v_max     = 0.5;     % 线速度限幅 [m/s]
omega_max = 2.5;     % 角速度限幅 [rad/s]

out_dir = fileparts(mfilename('fullpath'));
fig_names = {'pid_step_response.png', 'pid_point_stabilization.png', 'pid_line_tracking.png', 'pid_circle_tracking.png'};
scenario_names = {'阶跃响应', '定点镇定', '直线跟踪', '圆形跟踪'};

metrics = struct('scenario', {}, 'value1', {}, 'value2', {}, 'value3', {});

for SCENARIO = 1:4
    [sim, fig_handle, metric] = run_scenario(SCENARIO, t, N, r, L, tau, K_motor, Kp_v, Ki_v, u_sat, Kp_dist, Kp_theta, Ki_theta, Kd_theta, v_max, omega_max);
    saveas(fig_handle, fullfile(out_dir, fig_names{SCENARIO}));
    close(fig_handle);
    metrics(end+1) = metric; %#ok<AGROW>
    fprintf('已保存: %s\n', fullfile(out_dir, fig_names{SCENARIO}));
end

fprintf('\n========== 控制性能指标 ==========\n');
for i = 1:4
    m = metrics(i);
    switch i
        case 1
            fprintf('场景%d 阶跃响应: 速度稳态误差 = %.4f m/s\n', i, m.value1);
        case 2
            fprintf('场景%d 定点镇定: 终点位置误差 (%.4f, %.4f) m, 航向误差 %.2f deg\n', i, m.value1, m.value2, m.value3);
        case 3
            fprintf('场景%d 直线跟踪: 角速度 RMSE = %.4f rad/s\n', i, m.value1);
        case 4
            fprintf('场景%d 圆形跟踪: 线速度 RMSE = %.4f m/s, 角速度 RMSE = %.4f rad/s, 圆度 RMSE = %.4f m\n', i, m.value1, m.value2, m.value3);
    end
end
fprintf('================================\n');

%% ==================== 局部函数 ====================
function [sim, fig, metric] = run_scenario(SCENARIO, t, N, r, L, tau, K_motor, Kp_v, Ki_v, u_sat, Kp_dist, Kp_theta, Ki_theta, Kd_theta, v_max, omega_max)
int_theta = 0;
err_theta_prev = 0;

x = zeros(1,N); y = zeros(1,N); theta_act = zeros(1,N);
wL_act = zeros(1,N); wR_act = zeros(1,N);
wL_ref = zeros(1,N); wR_ref = zeros(1,N);
v_cmd = zeros(1,N); w_cmd = zeros(1,N);
uL = zeros(1,N); uR = zeros(1,N);

x(1) = 0; y(1) = 0; theta_act(1) = 0;
wL_act(1) = 0; wR_act(1) = 0;

switch SCENARIO
    case 1
        step_idx = find(t >= 2.5, 1, 'first');
        v_ref = zeros(1, N);
        v_ref(step_idx:end) = 0.3;
        w_ref = zeros(1,N);
    case 2
        x_tgt = 2.0; y_tgt = 1.0; theta_tgt = pi/4;
        v_ref = zeros(1,N); w_ref = zeros(1,N);
    case 3
        v_ref = 0.25 * ones(1,N); w_ref = zeros(1,N);
    case 4
        R_c = 0.8; w_c = 2*pi/16;
        v_ref = R_c * w_c * ones(1,N); w_ref = w_c * ones(1,N);
end

int_L = 0; int_R = 0;
for k = 1:N-1
    switch SCENARIO
        case 1
            v_cmd(k) = v_ref(k); w_cmd(k) = 0;
        case 2
            ex = x_tgt - x(k); ey = y_tgt - y(k);
            dist_err = sqrt(ex^2 + ey^2);
            if dist_err > 0.08
                theta_des = atan2(ey, ex);
            else
                theta_des = theta_tgt;
            end
            e_theta = atan2(sin(theta_des - theta_act(k)), cos(theta_des - theta_act(k)));
            int_theta = int_theta + e_theta * t(2);
            d_theta = (e_theta - err_theta_prev) / t(2);
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta + Kd_theta*d_theta;
            err_theta_prev = e_theta;
            v_cmd(k) = Kp_dist * dist_err;
            if abs(e_theta) > pi/3, v_cmd(k) = v_cmd(k) * 0.2; end
            if dist_err < 0.08, v_cmd(k) = v_cmd(k) * (dist_err / 0.08); end
            if dist_err < 0.01 && abs(e_theta) < 0.03, v_cmd(k) = 0; w_cmd(k) = 0; end
        case 3
            e_lat = 0.6 - y(k);
            e_theta = atan2(sin(-theta_act(k)), cos(-theta_act(k)));
            int_theta = int_theta + e_theta * t(2);
            d_theta = (e_theta - err_theta_prev) / t(2);
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta + 0.5*Kp_dist*e_lat;
            err_theta_prev = e_theta;
            v_cmd(k) = v_ref(k);
        case 4
            theta_ref = w_c * t(k);
            x_ref = R_c * cos(theta_ref);
            y_ref = R_c * sin(theta_ref);
            ex = x_ref - x(k); ey = y_ref - y(k);
            theta_path = theta_ref + pi/2;
            cross_track = -sin(theta_path)*ex + cos(theta_path)*ey;
            theta_des = theta_path + atan(cross_track / 0.6);
            e_theta = atan2(sin(theta_des - theta_act(k)), cos(theta_des - theta_act(k)));
            int_theta = int_theta + e_theta * t(2);
            d_theta = (e_theta - err_theta_prev) / t(2);
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta + Kd_theta*d_theta;
            err_theta_prev = e_theta;
            along_track = cos(theta_path)*ex + sin(theta_path)*ey;
            v_cmd(k) = v_ref(k) + Kp_dist * along_track;
    end

    v_cmd(k) = max(-v_max, min(v_max, v_cmd(k)));
    w_cmd(k) = max(-omega_max, min(omega_max, w_cmd(k)));

    wL_ref(k) = v_cmd(k)/r - w_cmd(k)*L/(2*r);
    wR_ref(k) = v_cmd(k)/r + w_cmd(k)*L/(2*r);

    eL = wL_ref(k) - wL_act(k);
    eR = wR_ref(k) - wR_act(k);
    if abs(eL) < 8.0, int_L = int_L + eL * t(2); else int_L = 0; end
    if abs(eR) < 8.0, int_R = int_R + eR * t(2); else int_R = 0; end
    uL(k) = Kp_v * eL + Ki_v * int_L;
    uR(k) = Kp_v * eR + Ki_v * int_R;
    uL(k) = max(-u_sat, min(u_sat, uL(k)));
    uR(k) = max(-u_sat, min(u_sat, uR(k)));

    wL_ss = K_motor * uL(k);
    wR_ss = K_motor * uR(k);
    wL_act(k+1) = wL_act(k) + ((wL_ss - wL_act(k)) / tau) * t(2);
    wR_act(k+1) = wR_act(k) + ((wR_ss - wR_act(k)) / tau) * t(2);

    v_now = r/2 * (wL_act(k+1) + wR_act(k+1));
    w_now = r/L * (wR_act(k+1) - wL_act(k+1));
    theta_act(k+1) = theta_act(k) + w_now * t(2);
    x(k+1) = x(k) + v_now * cos(theta_act(k)) * t(2);
    y(k+1) = y(k) + v_now * sin(theta_act(k)) * t(2);
end

v_cur_all = r/2 * (wL_act + wR_act);
w_cur_all = r/L * (wR_act - wL_act);
idx_ss = floor(0.75*N):N;

fig = figure('Color','w','Name',sprintf('场景%d', SCENARIO),'NumberTitle','off','Position',[100 60 1200 750]);

subplot(2,3,1); hold on; grid on; axis equal;
switch SCENARIO
    case 1
        plot(x, y, 'b-', 'LineWidth', 1.5); plot(x(1), y(1), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
        legend('实际轨迹','起点','Location','best'); title('阶跃响应轨迹'); xlabel('X [m]'); ylabel('Y [m]');
    case 2
        plot(x, y, 'b-', 'LineWidth', 1.5); plot(x_tgt, y_tgt, 'r*', 'MarkerSize', 12, 'LineWidth', 2); plot(x(1), y(1), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
        legend('实际轨迹','目标点','起点','Location','best'); title('定点镇定轨迹'); xlabel('X [m]'); ylabel('Y [m]');
    case 3
        plot(x, y, 'b-', 'LineWidth', 1.5); yline(0.6, 'r--', 'LineWidth', 1.5); legend('实际轨迹','目标直线','Location','best'); title('直线跟踪轨迹'); xlabel('X [m]'); ylabel('Y [m]');
    case 4
        plot(x, y, 'b-', 'LineWidth', 1.2); theta_plot = linspace(0, 2*pi, 200); plot(R_c*cos(theta_plot), R_c*sin(theta_plot), 'r--', 'LineWidth', 1.5); legend('实际轨迹','参考圆','Location','best'); title('圆形轨迹跟踪'); xlabel('X [m]'); ylabel('Y [m]');
end

subplot(2,3,2); hold on; grid on;
plot(t, v_cur_all, 'b-', 'LineWidth', 1.2); plot(t, v_ref, 'r--', 'LineWidth', 1.2); xlabel('时间 [s]'); ylabel('线速度 [m/s]'); legend('实际 v','参考 v','Location','best'); title('线速度跟踪');
subplot(2,3,3); hold on; grid on;
plot(t, w_cur_all, 'b-', 'LineWidth', 1.2); plot(t, w_ref, 'r--', 'LineWidth', 1.2); xlabel('时间 [s]'); ylabel('角速度 [rad/s]'); legend('实际 \omega','参考 \omega','Location','best'); title('角速度跟踪');
subplot(2,3,4); hold on; grid on;
plot(t, wL_act, 'b-', 'LineWidth', 1.0); plot(t, wR_act, 'r-', 'LineWidth', 1.0); plot(t, wL_ref, 'b--', 'LineWidth', 0.8); plot(t, wR_ref, 'r--', 'LineWidth', 0.8); xlabel('时间 [s]'); ylabel('轮速 [rad/s]'); legend('\omega_L 实际','\omega_R 实际','\omega_L 指令','\omega_R 指令','Location','best'); title('左右轮速跟踪');
subplot(2,3,5); hold on; grid on;
plot(t, uL, 'b-', 'LineWidth', 1.0); plot(t, uR, 'r-', 'LineWidth', 1.0); yline(u_sat, 'k--'); yline(-u_sat, 'k--'); xlabel('时间 [s]'); ylabel('电压 [V]'); legend('u_L','u_R','饱和限','Location','best'); title('电机控制电压');
subplot(2,3,6); hold on; grid on;
plot(t, theta_act * 180/pi, 'b-', 'LineWidth', 1.2); xlabel('时间 [s]'); ylabel('航向角 [deg]'); title('航向角响应');

sgtitle(sprintf('双轮差速AGV 双环PID控制 - 场景%d', SCENARIO),'FontSize',14,'FontWeight','bold');

metric = struct('scenario', SCENARIO, 'value1', NaN, 'value2', NaN, 'value3', NaN);
switch SCENARIO
    case 1
        metric.value1 = mean(abs(v_ref(idx_ss) - v_cur_all(idx_ss)));
    case 2
        metric.value1 = x_tgt - x(end);
        metric.value2 = y_tgt - y(end);
        metric.value3 = atan2(sin(theta_tgt - theta_act(end)), cos(theta_tgt - theta_act(end))) * 180/pi;
    case 3
        metric.value1 = sqrt(mean((w_cur_all(idx_ss)).^2));
    case 4
        metric.value1 = sqrt(mean((v_ref(idx_ss) - v_cur_all(idx_ss)).^2));
        metric.value2 = sqrt(mean((w_ref(idx_ss) - w_cur_all(idx_ss)).^2));
        dist_to_center = abs(sqrt(x.^2 + y.^2) - R_c);
        metric.value3 = sqrt(mean(dist_to_center(idx_ss).^2));
end

sim = struct('t', t, 'x', x, 'y', y, 'theta_act', theta_act, 'v_cur_all', v_cur_all, 'w_cur_all', w_cur_all);
end
