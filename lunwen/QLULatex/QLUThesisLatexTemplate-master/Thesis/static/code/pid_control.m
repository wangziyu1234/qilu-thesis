%% 双轮差速AGV双环PID控制仿真
%  外环(位姿环): 根据位置/航向偏差计算速度指令 v_cmd, ω_cmd
%  内环(轮速环): PI控制左右轮跟踪逆运动学解算的轮速指令
%  四种场景：阶跃响应、定点镇定、直线跟踪、圆形轨迹跟踪
clear; close all; clc;

%% —— 系统参数 ——

r = 0.09;  % 车轮半径(m)
L = 0.52;  % 轮距(m)
tau = 0.06;  % 电机机电时间常数(s)
K_motor = 0.327;  % 电机增益 (rad/s)/V

Ts = 0.005;  % 仿真步长(s)
T_sim = 12;  % 仿真时长(s)
t = 0:Ts:T_sim;
N = length(t);

Kp_v = 17.0;  % 速度环Kp
Ki_v = 103.0;  % 速度环Ki
u_sat = 24;  % 电压限幅(V)

Kp_dist  = 0.6;  % 距离增益
Kp_theta = 3.0;  % 航向Kp
Ki_theta = 0.2;  % 航向Ki
Kd_theta = 0.4;  % 航向Kd

v_max     = 0.5;  % 线速度上限(m/s)
omega_max = 2.5;  % 角速度上限(rad/s)

%% —— 主循环: 四种场景 ——

scenario_names = {'阶跃响应','定点镇定','直线跟踪','圆形跟踪'};

for SCENARIO = 1:4
fprintf('\n===== 场景%d: %s =====\n', SCENARIO, scenario_names{SCENARIO});

%% —— 状态预分配(每场景重置) ——

x = zeros(1,N);  y = zeros(1,N);
theta_act = zeros(1,N);
wL_act = zeros(1,N);  wR_act = zeros(1,N);
wL_ref = zeros(1,N);  wR_ref = zeros(1,N);
v_cmd  = zeros(1,N);  w_cmd  = zeros(1,N);
uL     = zeros(1,N);  uR     = zeros(1,N);

x(1) = 0;  y(1) = 0;  theta_act(1) = 0;  % 起点
wL_act(1) = 0;  wR_act(1) = 0;  % 初始静止

int_theta  = 0;  % 航向积分
err_theta_prev = 0;  % 上拍航向偏差

switch SCENARIO
    case 1  % 阶跃响应: 2.5s时给0.3m/s
        v_ref = [zeros(1,floor(N/4)), 0.3*ones(1,N-floor(N/4))];
        w_ref = zeros(1,N);

    case 2  % 定点镇定: 目标(2.0, 1.0, 45°)
        x_tgt = 2.0;  y_tgt = 1.0;
        theta_tgt = pi/4;
        v_ref = zeros(1,N);  w_ref = zeros(1,N);

    case 3  % 直线跟踪: y=0.6
        v_ref = 0.25 * ones(1,N);
        w_ref = zeros(1,N);

    case 4  % 圆形轨迹: R=0.8m, T=16s
        R_c = 0.8;
        w_c = 2*pi/16;
        v_ref = R_c * w_c * ones(1,N);
        w_ref = w_c * ones(1,N);
end

%% —— 主仿真循环 ——

int_L = 0;  int_R = 0;  % 左右轮速积分

for k = 1:N-1

    v_cur  = r/2 * (wL_act(k) + wR_act(k));  % 实际线速度(反馈)
    w_cur  = r/L * (wR_act(k) - wL_act(k));  % 实际角速度(反馈)

    switch SCENARIO
        case 1  % 阶跃响应
            v_cmd(k) = v_ref(k);
            w_cmd(k) = 0;

        case 2  % 定点镇定
            ex = x_tgt - x(k);  ey = y_tgt - y(k);
            dist_err = sqrt(ex^2 + ey^2);

            if dist_err > 0.08  % 远: 指向目标
                theta_des = atan2(ey, ex);
            else  % 近: 对准目标角度
                theta_des = theta_tgt;
            end
            e_theta = theta_des - theta_act(k);
            e_theta = atan2(sin(e_theta), cos(e_theta));  % 归一化

            int_theta = int_theta + e_theta * Ts;
            d_theta = (e_theta - err_theta_prev) / Ts;
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta + Kd_theta*d_theta;
            err_theta_prev = e_theta;

            v_cmd(k) = Kp_dist * dist_err;  % 距离→速度
            if abs(e_theta) > pi/3  % 大角度先转向
                v_cmd(k) = v_cmd(k) * 0.2;
            end
            if dist_err < 0.08
                v_cmd(k) = v_cmd(k) * (dist_err / 0.08);
            end
            if dist_err < 0.01 && abs(e_theta) < 0.03  % 到位(1cm+1.7°)
                v_cmd(k) = 0;  w_cmd(k) = 0;
            end

        case 3  % 直线跟踪
            v_cmd(k) = v_ref(k);
            e_lat = 0.6 - y(k);
            e_theta = -theta_act(k);
            e_theta = atan2(sin(e_theta), cos(e_theta));

            int_theta = int_theta + e_theta * Ts;
            d_theta = (e_theta - err_theta_prev) / Ts;
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta ...
                       + 0.5*Kp_dist*e_lat;  % +横向偏差前馈
            err_theta_prev = e_theta;

        case 4  % 圆形跟踪
            theta_ref = w_c * t(k);
            x_ref = R_c * cos(theta_ref);  y_ref = R_c * sin(theta_ref);

            ex = x_ref - x(k);  ey = y_ref - y(k);
            theta_path = theta_ref + pi/2;  % 切线方向

            cross_track = -sin(theta_path)*ex + cos(theta_path)*ey;  % 横向偏差
            theta_des = theta_path + atan(cross_track / 0.6);
            e_theta = theta_des - theta_act(k);
            e_theta = atan2(sin(e_theta), cos(e_theta));

            int_theta = int_theta + e_theta * Ts;
            d_theta = (e_theta - err_theta_prev) / Ts;
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta + Kd_theta*d_theta;
            err_theta_prev = e_theta;

            along_track = cos(theta_path)*ex + sin(theta_path)*ey;  % 纵向偏差
            v_cmd(k) = v_ref(k) + Kp_dist * along_track;
    end

    v_cmd(k) = max(-v_max, min(v_max, v_cmd(k)));  % 限幅
    w_cmd(k) = max(-omega_max, min(omega_max, w_cmd(k)));

    wL_ref(k) = v_cmd(k)/r - w_cmd(k)*L/(2*r);  % 逆运动学→左轮指令
    wR_ref(k) = v_cmd(k)/r + w_cmd(k)*L/(2*r);  % 逆运动学→右轮指令

    eL = wL_ref(k) - wL_act(k);  % 左轮偏差
    eR = wR_ref(k) - wR_act(k);  % 右轮偏差

    if abs(eL) < 5.0, int_L = int_L + eL * Ts; else int_L = 0; end  % 积分分离(阈值≈最高轮速5.6rad/s)
    if abs(eR) < 5.0, int_R = int_R + eR * Ts; else int_R = 0; end

    uL(k) = Kp_v * eL + Ki_v * int_L;  % 左PI
    uR(k) = Kp_v * eR + Ki_v * int_R;  % 右PI

    if uL(k) > u_sat  % 遇限削弱积分
        uL(k) = u_sat;  int_L = int_L - eL * Ts;
    elseif uL(k) < -u_sat
        uL(k) = -u_sat;  int_L = int_L - eL * Ts;
    end
    if uR(k) > u_sat
        uR(k) = u_sat;  int_R = int_R - eR * Ts;
    elseif uR(k) < -u_sat
        uR(k) = -u_sat;  int_R = int_R - eR * Ts;
    end

    wL_ss = K_motor * uL(k);  % 左轮稳态角速度
    wR_ss = K_motor * uR(k);  % 右轮稳态角速度
    dwL = (wL_ss - wL_act(k)) / tau;  % 一阶惯性环节
    dwR = (wR_ss - wR_act(k)) / tau;
    wL_act(k+1) = wL_act(k) + dwL * Ts;
    wR_act(k+1) = wR_act(k) + dwR * Ts;

    v_now  = r/2 * (wL_act(k+1) + wR_act(k+1));
    w_now  = r/L * (wR_act(k+1) - wL_act(k+1));

    x(k+1) = x(k) + v_now * cos(theta_act(k)) * Ts;
    y(k+1) = y(k) + v_now * sin(theta_act(k)) * Ts;
    theta_act(k+1) = theta_act(k) + w_now * Ts;

end
fprintf('仿真完成。\n');

%% —— 结果可视化 (每张图独立保存) ——

out_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');  % 图片输出目录
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
v_cur_all = r/2 * (wL_act + wR_act);  % 由轮速反算实际线速度
w_cur_all = r/L * (wR_act - wL_act);  % 由轮速反算实际角速度
prefix = sprintf('仿真结果_场景%d_%s', SCENARIO, scenario_names{SCENARIO});

% ---- 图1: XY轨迹 ----
fig1 = figure('Color','w','Position',[50,50,650,500]);
hold on; grid on; axis equal;
switch SCENARIO
    case 1
        plot(x, y, 'b-', 'LineWidth', 1.5);
        plot(x(1), y(1), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
        legend('实际轨迹','起点','Location','best');
    case 2
        plot(x, y, 'b-', 'LineWidth', 1.5);
        plot(x_tgt, y_tgt, 'r*', 'MarkerSize', 12, 'LineWidth', 2);
        plot(x(1), y(1), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
        legend('实际轨迹','目标点','起点','Location','best');
    case 3
        plot(x, y, 'b-', 'LineWidth', 1.5);
        yline(0.6, 'r--', 'LineWidth', 1.5);
        legend('实际轨迹','目标直线','Location','best');
    case 4
        plot(x, y, 'b-', 'LineWidth', 1.2);
        th_plot = linspace(0, 2*pi, 200);
        plot(R_c*cos(th_plot), R_c*sin(th_plot), 'r--', 'LineWidth', 1.5);
        legend('实际轨迹','参考圆','Location','best');
end
xlabel('X [m]'); ylabel('Y [m]');
title(sprintf('%s — 轨迹', scenario_names{SCENARIO}));
saveas(fig1, fullfile(out_dir, [prefix '_1轨迹.png'])); close(fig1);

% ---- 图2: 线速度跟踪 ----
fig2 = figure('Color','w','Position',[100,100,650,420]);
hold on; grid on;
plot(t, v_ref, 'r--', 'LineWidth', 1.2, 'DisplayName','参考 v');
plot(t, v_cur_all, 'b-', 'LineWidth', 1.5, 'DisplayName','实际 v');
xlabel('时间 [s]'); ylabel('线速度 [m/s]');
title(sprintf('%s — 线速度跟踪', scenario_names{SCENARIO}));
legend('Location','best');
saveas(fig2, fullfile(out_dir, [prefix '_2线速度.png'])); close(fig2);

% ---- 图3: 角速度跟踪 ----
fig3 = figure('Color','w','Position',[150,150,650,420]);
hold on; grid on;
plot(t, w_ref, 'r--', 'LineWidth', 1.2, 'DisplayName','参考 \omega');
plot(t, w_cur_all, 'b-', 'LineWidth', 1.5, 'DisplayName','实际 \omega');
xlabel('时间 [s]'); ylabel('角速度 [rad/s]');
title(sprintf('%s — 角速度跟踪', scenario_names{SCENARIO}));
legend('Location','best');
saveas(fig3, fullfile(out_dir, [prefix '_3角速度.png'])); close(fig3);

% ---- 图4: 左右轮速跟踪 ----
fig4 = figure('Color','w','Position',[200,200,650,420]);
hold on; grid on;
plot(t, wL_act, 'b-', 'LineWidth', 1.0, 'DisplayName','\omega_L 实际');
plot(t, wR_act, 'r-', 'LineWidth', 1.0, 'DisplayName','\omega_R 实际');
plot(t, wL_ref, 'b--', 'LineWidth', 0.8, 'DisplayName','\omega_L 指令');
plot(t, wR_ref, 'r--', 'LineWidth', 0.8, 'DisplayName','\omega_R 指令');
xlabel('时间 [s]'); ylabel('轮速 [rad/s]');
title(sprintf('%s — 左右轮速跟踪', scenario_names{SCENARIO}));
legend('Location','best');
saveas(fig4, fullfile(out_dir, [prefix '_4轮速.png'])); close(fig4);

% ---- 图5: 电机电压 ----
fig5 = figure('Color','w','Position',[250,250,650,420]);
hold on; grid on;
plot(t, uL, 'b-', 'LineWidth', 1.0, 'DisplayName','u_L');
plot(t, uR, 'r-', 'LineWidth', 1.0, 'DisplayName','u_R');
yline(u_sat, 'k--', 'DisplayName','饱和限');
yline(-u_sat, 'k--', 'HandleVisibility','off');
xlabel('时间 [s]'); ylabel('电压 [V]');
title(sprintf('%s — 电机控制电压', scenario_names{SCENARIO}));
legend('Location','best');
saveas(fig5, fullfile(out_dir, [prefix '_5电压.png'])); close(fig5);

% ---- 图6: 航向角 ----
fig6 = figure('Color','w','Position',[300,300,650,420]);
hold on; grid on;
plot(t, theta_act * 180/pi, 'b-', 'LineWidth', 1.2, 'DisplayName','实际 \theta');
if SCENARIO == 4
    plot(t, w_c * t * 180/pi, 'r--', 'LineWidth', 1.2, 'DisplayName','参考 \theta');
elseif SCENARIO == 2
    yline(theta_tgt*180/pi, 'r--', 'LineWidth', 1.2, 'DisplayName','目标 \theta');
end
xlabel('时间 [s]'); ylabel('航向角 [deg]');
title(sprintf('%s — 航向角响应', scenario_names{SCENARIO}));
legend('Location','best');
saveas(fig6, fullfile(out_dir, [prefix '_6航向角.png'])); close(fig6);

fprintf('图片已保存: %s_1~6*.png\n', prefix);

%% —— 控制性能指标 ——

fprintf('\n========== 控制性能指标 ==========\n');  % 打印指标表头

idx_ss = floor(0.75*N):N;  % 稳态段索引(后1/4数据用于计算稳态指标)
switch SCENARIO  % 根据场景计算不同指标
    case 1  % 阶跃响应: 速度稳态误差
        v_err_ss = mean(abs(v_ref(idx_ss) - v_cur_all(idx_ss)));  % 稳态段速度偏差均值
        fprintf('速度稳态误差: %.4f m/s\n', v_err_ss);  % 打印速度稳态误差

    case 2  % 定点镇定: 终点位置和航向误差
        x_err = x_tgt - x(end);  y_err = y_tgt - y(end);  % X和Y方向终点误差
        t_err = theta_tgt - theta_act(end);  % 航向角终点误差
        t_err = atan2(sin(t_err), cos(t_err));  % 航向误差归一化到[-π,π]
        fprintf('终点位置误差: (%.4f, %.4f) m\n', x_err, y_err);  % 打印位置误差
        fprintf('终点航向误差: %.2f deg\n', t_err * 180/pi);  % 打印航向误差(°)

    case {3, 4}  % 直线/圆形跟踪: 线速度和角速度RMSE
        v_err_rmse = sqrt(mean((v_ref(idx_ss) - v_cur_all(idx_ss)).^2));  % 线速度RMSE
        w_err_rmse = sqrt(mean((w_ref(idx_ss) - w_cur_all(idx_ss)).^2));  % 角速度RMSE
        fprintf('线速度 RMSE: %.4f m/s\n', v_err_rmse);  % 打印线速度RMSE
        fprintf('角速度 RMSE: %.4f rad/s\n', w_err_rmse);  % 打印角速度RMSE
        if SCENARIO == 4  % 圆形跟踪额外计算轨迹圆度
            dist_to_center = abs(sqrt(x.^2 + y.^2) - R_c);  % 各点到圆心的距离与半径之差
            fprintf('轨迹圆度 RMSE: %.4f m\n', sqrt(mean(dist_to_center(idx_ss).^2)));  % 打印圆度RMSE
        end
end

end  % for SCENARIO = 1:4 (四种场景循环结束)

fprintf('================================\n');  % 打印结束分隔线
