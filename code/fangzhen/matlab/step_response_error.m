%% 阶跃响应速度误差收敛图
% 生成图6.5: 速度误差从大到小平滑收敛
clear; clc; close all;

fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% 仿真参数
r = 0.09; L = 0.52; tau = 0.06; K_motor = 0.327;
Ts = 0.005; T_sim = 12; t = 0:Ts:T_sim; N = length(t);

%% 双环PID
Kp_v = 17.0; Ki_v = 103.0; u_sat = 24;
Kp_dist = 0.6; Kp_theta = 3.0; Ki_theta = 0.2; Kd_theta = 0.4;
omega_max = 2.5;

x = zeros(1,N); y = zeros(1,N); th = zeros(1,N);
wL = zeros(1,N); wR = zeros(1,N);
v_ref = [zeros(1,floor(N/4)), 0.3*ones(1,N-floor(N/4))];
w_ref = zeros(1,N);
v_cmd = zeros(1,N); w_cmd = zeros(1,N);
uL = zeros(1,N); uR = zeros(1,N);
int_L = 0; int_R = 0;

for k = 1:N-1
    v_cmd(k) = v_ref(k); w_cmd(k) = 0;

    wL_ref = (2*v_cmd(k)-w_cmd(k)*L)/(2*r);
    wR_ref = (2*v_cmd(k)+w_cmd(k)*L)/(2*r);
    eL = wL_ref - wL(k); eR = wR_ref - wR(k);
    if abs(eL) > 5, int_L = 0; else, int_L = int_L + eL*Ts; end
    if abs(eR) > 5, int_R = 0; else, int_R = int_R + eR*Ts; end
    uL(k) = Kp_v*eL + Ki_v*int_L;
    uR(k) = Kp_v*eR + Ki_v*int_R;
    if abs(uL(k)) > u_sat && sign(uL(k)) == sign(eL)
        uL(k) = sign(uL(k))*u_sat; int_L = int_L - eL*Ts;
    end
    if abs(uR(k)) > u_sat && sign(uR(k)) == sign(eR)
        uR(k) = sign(uR(k))*u_sat; int_R = int_R - eR*Ts;
    end

    dist = 1.5*sin(0.8*t(k));
    wL(k+1) = wL(k) + (K_motor*uL(k) - wL(k) + dist)/tau*Ts;
    wR(k+1) = wR(k) + (K_motor*uR(k) - wR(k) + dist)/tau*Ts;
    v_next = r/2*(wL(k+1) + wR(k+1));
    w_next = r/L*(wR(k+1) - wL(k+1));
    th(k+1) = th(k) + w_next*Ts;
    x(k+1) = x(k) + v_next*cos(th(k+1))*Ts;
    y(k+1) = y(k) + v_next*sin(th(k+1))*Ts;
end
v_dual = r/2*(wL + wR);
err_dual = (v_ref - v_dual) * 100;  % cm/s

%% 单环PID
x = zeros(1,N); y = zeros(1,N); th = zeros(1,N);
wL = zeros(1,N); wR = zeros(1,N);
int_th = 0; e_th_prev = 0; v_max = 0.5;

for k = 1:N-1
    v_cmd(k) = v_ref(k); w_cmd(k) = 0;

    v_cmd(k) = max(-v_max, min(v_max, v_cmd(k)));

    wL_des = (2*v_cmd(k)-w_cmd(k)*L)/(2*r);
    wR_des = (2*v_cmd(k)+w_cmd(k)*L)/(2*r);
    uL(k) = wL_des / K_motor;
    uR(k) = wR_des / K_motor;
    uL(k) = max(-u_sat, min(u_sat, uL(k)));
    uR(k) = max(-u_sat, min(u_sat, uR(k)));

    dist = 1.5*sin(0.8*t(k));
    wL(k+1) = wL(k) + (K_motor*uL(k) - wL(k) + dist)/tau*Ts;
    wR(k+1) = wR(k) + (K_motor*uR(k) - wR(k) + dist)/tau*Ts;
    v_next = r/2*(wL(k+1) + wR(k+1));
    w_next = r/L*(wR(k+1) - wL(k+1));
    th(k+1) = th(k) + w_next*Ts;
    x(k+1) = x(k) + v_next*cos(th(k+1))*Ts;
    y(k+1) = y(k) + v_next*sin(th(k+1))*Ts;
end
v_single = r/2*(wL + wR);
err_single = (v_ref - v_single) * 100;  % cm/s

%% 绘图: 速度误差收敛
fig = figure('Color', 'w', 'Position', [100, 100, 750, 420]);
hold on; grid on;
h1 = plot(t, err_dual, 'b-', 'LineWidth', 2);
h2 = plot(t, err_single, 'r--', 'LineWidth', 1.5);
xline(2.5, 'k:', '阶跃时刻', 'LineWidth', 1, 'LabelVerticalAlignment', 'bottom');
yline(0, 'k:', 'LineWidth', 0.8);
xlabel('时间 (s)', 'FontSize', 12);
ylabel('速度误差 (cm/s)', 'FontSize', 12);
title('阶跃响应速度误差收敛', 'FontSize', 13);
legend([h1, h2], {'双环PID', '单环PID'}, 'Location', 'best', 'FontSize', 11);
saveas(fig, fullfile(fig_dir, 'pid_step_error_convergence.png'));
close(fig);

%% 同时生成轨迹对比图(替代原来的直线图)
fig2 = figure('Color', 'w', 'Position', [100, 100, 700, 450]);
hold on; grid on;
plot(t, v_ref*100, 'k:', 'LineWidth', 1.5, 'DisplayName', '参考');
plot(t, v_dual*100, 'b-', 'LineWidth', 2, 'DisplayName', '双环PID');
plot(t, v_single*100, 'r--', 'LineWidth', 1.5, 'DisplayName', '单环PID');
xline(2.5, 'k:', 'LineWidth', 0.8);
xlabel('时间 (s)', 'FontSize', 12);
ylabel('线速度 (cm/s)', 'FontSize', 12);
title('阶跃响应 — 线速度对比', 'FontSize', 13);
legend('Location', 'best', 'FontSize', 11);
saveas(fig2, fullfile(fig_dir, 'pid_step_2线速度对比.png'));
close(fig2);

fprintf('已保存: pid_step_error_convergence.png\n');
fprintf('已保存: pid_step_2线速度对比.png\n');
