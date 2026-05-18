%% 双轮差速AGV PID控制器设计与控制效果仿真验证
%  功能: 差速驱动运动学建模 + 双环PID控制 + 多场景仿真验证

clearvars -except SCENARIO; close all; clc;   % 清除除 SCENARIO 外的所有变量

%% ==================== 1. 参数设置 ====================

% ---- AGV 物理参数 ----
r = 0.09;            % 车轮半径 [m]
L = 0.52;            % 两轮间距 (轮距) [m]
tau = 0.06;          % 电机机电时间常数 [s]
K_motor = 0.327;     % 电机增益 [(rad/s)/V]（由Ke=8 V/krpm, i=40推导：K_motor = (1000*2π/60)/8/40 ≈ 0.327）

% ---- 仿真参数 ----
Ts = 0.005;          % 仿真步长 [s]
T_sim = 12;          % 仿真总时长 [s]
t = 0:Ts:T_sim;      % 时间向量
N = length(t);       % 总步数

% ---- 速度环 PI 参数（内环）----
Kp_v = 17.0;         % 速度比例增益（Km修正后等比例放大 17 ≈ 2.0×2.8/0.327）
Ki_v = 103.0;        % 速度积分增益（Km修正后等比例放大 103 ≈ 12.0×2.8/0.327）
u_sat = 24;          % 电机电压限幅 [V]（额定转速对应电压≈24V）

% ---- 位姿环 PID 参数（外环）----
Kp_dist  = 0.6;      % 距离→线速度 比例增益
Kp_theta = 3.0;      % 航向角 比例增益
Ki_theta = 0.2;      % 航向角 积分增益
Kd_theta = 0.4;      % 航向角 微分增益

v_max     = 0.5;      % 线速度限幅 [m/s]
omega_max = 2.5;     % 角速度限幅 [rad/s]

%% ==================== 2. 状态向量预分配 ====================

x = zeros(1,N);                            % x 坐标序列 [m]
y = zeros(1,N);                            % y 坐标序列 [m]
theta_act = zeros(1,N);                    % 实际航向角序列 [rad]
wL_act = zeros(1,N);                       % 左轮实际角速度 [rad/s]
wR_act = zeros(1,N);                       % 右轮实际角速度 [rad/s]
wL_ref = zeros(1,N);                       % 左轮指令角速度 [rad/s]
wR_ref = zeros(1,N);                       % 右轮指令角速度 [rad/s]
v_cmd  = zeros(1,N);                       % 外环输出线速度指令 [m/s]
w_cmd  = zeros(1,N);                       % 外环输出角速度指令 [rad/s]
uL     = zeros(1,N);                       % 左电机电压 [V]
uR     = zeros(1,N);                       % 右电机电压 [V]

% 初始位姿: 原点, 航向 0°
x(1) = 0;  y(1) = 0;  theta_act(1) = 0;
wL_act(1) = 0;  wR_act(1) = 0;            % 初始轮速为零

% 外环积分/微分状态
int_theta  = 0;                            % 航向角积分初值
err_theta_prev = 0;                        % 上一拍航向偏差

%% ==================== 3. 参考轨迹 ====================

% 选择场景: 1-阶跃响应  2-定点镇定  3-直线跟踪  4-圆形跟踪
% 如已从外部传入 SCENARIO 则使用外部值, 否则默认场景 4
if ~exist('SCENARIO', 'var'), SCENARIO = 4; end

switch SCENARIO
    case 1  % ---- 阶跃响应: 2.5s 时刻起给 0.3 m/s 线速度指令 ----
        v_ref = [zeros(1,floor(N/4)), 0.3*ones(1,N-floor(N/4))];  % 前 1/4 零, 后 3/4 恒值
        w_ref = zeros(1,N);                 % 角速度指令为零

    case 2  % ---- 定点镇定: 目标位姿 (2.0, 1.0, π/4) ----
        x_tgt = 2.0;                        % 目标 x [m]
        y_tgt = 1.0;                        % 目标 y [m]
        theta_tgt = pi/4;                   % 目标航向角 45°
        v_ref = zeros(1,N);                 % 无固定参考速度
        w_ref = zeros(1,N);

    case 3  % ---- 直线跟踪: 目标直线 y=0.6, 标称速度 0.25 m/s ----
        v_ref = 0.25 * ones(1,N);           % 恒定线速度 0.25 m/s
        w_ref = zeros(1,N);                 % 角速度指令为零

    case 4  % ---- 圆形轨迹: 半径 0.8m, 周期 16s (ω=2π/16, v=ωR) ----
        R_c = 0.8;                          % 圆半径 [m]
        w_c = 2*pi/16;                      % 圆角速度 [rad/s]
        v_ref = R_c * w_c * ones(1,N);      % 参考线速度 [m/s]
        w_ref = w_c * ones(1,N);            % 参考角速度 [rad/s]
end

%% ==================== 4. 主仿真循环 ====================

int_L = 0;  int_R = 0;                     % 左右轮速度环积分初值

for k = 1:N-1                              % 遍历每个仿真步

    % ---- 4.1 当前实际车速 (由轮速反馈计算) ----
    v_cur  = r/2 * (wL_act(k) + wR_act(k));  % 当前线速度 [m/s]
    w_cur  = r/L * (wR_act(k) - wL_act(k));  % 当前角速度 [rad/s]

    % ---- 4.2 外环: 误差计算 → v_cmd, w_cmd ----
    switch SCENARIO
        case 1  % 阶跃响应: 直接给定速度指令 (开环前馈, 速度环闭环)
            v_cmd(k) = v_ref(k);            % 线速度 = 参考值
            w_cmd(k) = 0;                   % 角速度 = 0

        case 2  % 定点镇定: 距离+航向两阶段策略
            ex = x_tgt - x(k);              % x 方向偏差
            ey = y_tgt - y(k);              % y 方向偏差
            dist_err = sqrt(ex^2 + ey^2);   % 欧氏距离偏差 [m]

            % 两阶段: 远距指向目标点, 近距对准目标角度
            if dist_err > 0.08              % 大于 8cm: 朝目标点前进
                theta_des = atan2(ey, ex);
            else                            % 小于 8cm: 对准目标角度
                theta_des = theta_tgt;
            end
            e_theta = theta_des - theta_act(k);           % 航向偏差
            e_theta = atan2(sin(e_theta), cos(e_theta));  % 归一化到 [-π, π]

            % 航向 PID 控制
            int_theta = int_theta + e_theta * Ts;         % 积分累加
            d_theta = (e_theta - err_theta_prev) / Ts;    % 微分项
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta + Kd_theta*d_theta;
            err_theta_prev = e_theta;                     % 更新上一拍偏差

            % 线速度: 距离×增益, 角度大时减速, 近距降速
            v_cmd(k) = Kp_dist * dist_err;                % 距离比例控制
            if abs(e_theta) > pi/3                        % 航向偏差 > 60°: 优先转向
                v_cmd(k) = v_cmd(k) * 0.2;
            end
            if dist_err < 0.08                            % 接近目标: 降速
                v_cmd(k) = v_cmd(k) * (dist_err / 0.08);
            end
            if dist_err < 0.01 && abs(e_theta) < 0.03    % 到位 (1cm 且 1.7°): 停车
                v_cmd(k) = 0;  w_cmd(k) = 0;
            end

        case 3  % 直线跟踪: 目标直线 y=0.6, 沿 x 轴行驶
            v_cmd(k) = v_ref(k);            % 纵向速度保持标称值

            % 横向偏差 + 航向偏差 → 角速度修正
            e_lat = 0.6 - y(k);             % 横向偏差 (距离目标直线) [m]
            e_theta = -theta_act(k);        % 期望航向 = 0 (沿 x 轴)
            e_theta = atan2(sin(e_theta), cos(e_theta));  % 归一化

            int_theta = int_theta + e_theta * Ts;         % 积分累加
            d_theta = (e_theta - err_theta_prev) / Ts;    % 微分项
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta ...
                       + 0.5*Kp_dist*e_lat;               % 横向偏差也贡献角速度
            err_theta_prev = e_theta;

        case 4  % 圆形轨迹跟踪: 半径 0.8m 逆时针圆
            % 参考位姿 (逆时针圆)
            theta_ref = w_c * t(k);                     % 参考航向角
            x_ref = R_c * cos(theta_ref);               % 参考 x
            y_ref = R_c * sin(theta_ref);               % 参考 y

            ex = x_ref - x(k);                          % x 方向偏差
            ey = y_ref - y(k);                          % y 方向偏差

            theta_path = theta_ref + pi/2;              % 轨迹切线方向 (径向+90°)
            cross_track = -sin(theta_path)*ex + cos(theta_path)*ey;  % 横向偏差 [m]
            theta_des = theta_path + atan(cross_track / 0.6);       % 期望航向 = 切线+纠偏
            e_theta = theta_des - theta_act(k);                     % 航向偏差
            e_theta = atan2(sin(e_theta), cos(e_theta));

            int_theta = int_theta + e_theta * Ts;                 % 积分累加
            d_theta = (e_theta - err_theta_prev) / Ts;            % 微分项
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta + Kd_theta*d_theta;
            err_theta_prev = e_theta;

            % 线速度 = 参考速度 + 纵向修正
            along_track = cos(theta_path)*ex + sin(theta_path)*ey;  % 纵向偏差
            v_cmd(k) = v_ref(k) + Kp_dist * along_track;            % 速度修正
    end

    % 外环输出限幅
    v_cmd(k) = max(-v_max, min(v_max, v_cmd(k)));        % 线速度限幅
    w_cmd(k) = max(-omega_max, min(omega_max, w_cmd(k))); % 角速度限幅

    % ---- 4.3 逆运动学: (v, ω) → (ωL_ref, ωR_ref) ----
    wL_ref(k) = v_cmd(k)/r - w_cmd(k)*L/(2*r);  % 左轮指令角速度 [rad/s]
    wR_ref(k) = v_cmd(k)/r + w_cmd(k)*L/(2*r);  % 右轮指令角速度 [rad/s]

    % ---- 4.4 速度环 PI ----
    eL = wL_ref(k) - wL_act(k);               % 左轮速度偏差
    eR = wR_ref(k) - wR_act(k);               % 右轮速度偏差

    % 积分分离: 大偏差 (>8 rad/s) 时清零积分, 加速响应
    if abs(eL) < 8.0, int_L = int_L + eL * Ts; else int_L = 0; end
    if abs(eR) < 8.0, int_R = int_R + eR * Ts; else int_R = 0; end

    uL(k) = Kp_v * eL + Ki_v * int_L;          % 左电机 PI 输出 [V]
    uR(k) = Kp_v * eR + Ki_v * int_R;          % 右电机 PI 输出 [V]

    % 电压限幅 + 抗积分饱和 (遇限削弱积分)
    if uL(k) > u_sat                           % 左电压超上限
        uL(k) = u_sat;  int_L = int_L - eL * Ts;  % 退回本次积分累加
    elseif uL(k) < -u_sat                      % 左电压超下限
        uL(k) = -u_sat;  int_L = int_L - eL * Ts;
    end
    if uR(k) > u_sat                           % 右电压超上限
        uR(k) = u_sat;  int_R = int_R - eR * Ts;
    elseif uR(k) < -u_sat                      % 右电压超下限
        uR(k) = -u_sat;  int_R = int_R - eR * Ts;
    end

    % ---- 4.5 电机动力学 (一阶惯性环节) ----
    wL_ss = K_motor * uL(k);                   % 左轮稳态角速度
    wR_ss = K_motor * uR(k);                   % 右轮稳态角速度
    dwL = (wL_ss - wL_act(k)) / tau;           % 左轮角加速度
    dwR = (wR_ss - wR_act(k)) / tau;           % 右轮角加速度
    wL_act(k+1) = wL_act(k) + dwL * Ts;        % 左轮速度欧拉更新
    wR_act(k+1) = wR_act(k) + dwR * Ts;        % 右轮速度欧拉更新

    % ---- 4.6 运动学更新 (欧拉法) ----
    v_now  = r/2 * (wL_act(k+1) + wR_act(k+1)); % 更新后线速度
    w_now  = r/L * (wR_act(k+1) - wL_act(k+1));  % 更新后角速度

    x(k+1) = x(k) + v_now * cos(theta_act(k)) * Ts;      % x 位置更新
    y(k+1) = y(k) + v_now * sin(theta_act(k)) * Ts;      % y 位置更新
    theta_act(k+1) = theta_act(k) + w_now * Ts;           % 航向角更新

end
fprintf('仿真完成。\n');

%% ==================== 5. 可视化 ====================

figure('Name','双轮差速PID控制仿真','NumberTitle','off',...
       'Position',[100 60 1200 750]);          % 创建图形窗口

% ---- 图1: 轨迹 (x-y 平面) ----
subplot(2,3,1);  hold on;  grid on;  axis equal;

switch SCENARIO
    case 2  % 定点镇定轨迹
        plot(x, y, 'b-', 'LineWidth', 1.5);   % 实际轨迹
        plot(x_tgt, y_tgt, 'r*', 'MarkerSize', 12, 'LineWidth', 2);  % 目标点
        plot(x(1), y(1), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);   % 起点
        legend('实际轨迹','目标点','起点','Location','best');
        title('定点镇定轨迹');
    case 3  % 直线跟踪轨迹
        plot(x, y, 'b-', 'LineWidth', 1.5);   % 实际轨迹
        yline(0.6, 'r--', 'LineWidth', 1.5);  % 目标直线 y=0.6
        legend('实际轨迹','目标直线','Location','best');
        title('直线跟踪轨迹');
    case 4  % 圆形轨迹跟踪
        plot(x, y, 'b-', 'LineWidth', 1.2);   % 实际轨迹
        theta_plot = linspace(0, 2*pi, 200);
        plot(R_c*cos(theta_plot), R_c*sin(theta_plot), 'r--', 'LineWidth', 1.5);  % 参考圆
        legend('实际轨迹','参考圆','Location','best');
        title('圆形轨迹跟踪');
end
xlabel('X [m]');  ylabel('Y [m]');

% ---- 图2: 线速度跟踪 ----
subplot(2,3,2);  hold on;  grid on;
v_cur_all = r/2 * (wL_act + wR_act);          % 全程线速度
plot(t, v_cur_all, 'b-', 'LineWidth', 1.2);  % 实际线速度
plot(t, v_ref, 'r--', 'LineWidth', 1.2);      % 参考线速度
xlabel('时间 [s]');  ylabel('线速度 [m/s]');
legend('实际 v','参考 v','Location','best');
title('线速度跟踪');

% ---- 图3: 角速度跟踪 ----
subplot(2,3,3);  hold on;  grid on;
w_cur_all = r/L * (wR_act - wL_act);          % 全程角速度
plot(t, w_cur_all, 'b-', 'LineWidth', 1.2);  % 实际角速度
plot(t, w_ref, 'r--', 'LineWidth', 1.2);      % 参考角速度
xlabel('时间 [s]');  ylabel('角速度 [rad/s]');
legend('实际 \omega','参考 \omega','Location','best');
title('角速度跟踪');

% ---- 图4: 左右轮速跟踪 ----
subplot(2,3,4);  hold on;  grid on;
plot(t, wL_act, 'b-', 'LineWidth', 1.0);      % 左轮实际
plot(t, wR_act, 'r-', 'LineWidth', 1.0);      % 右轮实际
plot(t, wL_ref, 'b--', 'LineWidth', 0.8);     % 左轮指令
plot(t, wR_ref, 'r--', 'LineWidth', 0.8);     % 右轮指令
xlabel('时间 [s]');  ylabel('轮速 [rad/s]');
legend('\omega_L 实际','\omega_R 实际','\omega_L 指令','\omega_R 指令','Location','best');
title('左右轮速跟踪');

% ---- 图5: 电机控制电压 ----
subplot(2,3,5);  hold on;  grid on;
plot(t, uL, 'b-', 'LineWidth', 1.0);          % 左电机电压
plot(t, uR, 'r-', 'LineWidth', 1.0);          % 右电机电压
yline(u_sat, 'k--');  yline(-u_sat, 'k--');   % 饱和限 ±12V
xlabel('时间 [s]');  ylabel('电压 [V]');
legend('u_L','u_R','饱和限','Location','best');
title('电机控制电压');

% ---- 图6: 航向角响应 ----
subplot(2,3,6);  hold on;  grid on;
plot(t, theta_act * 180/pi, 'b-', 'LineWidth', 1.2);  % 实际航向角 [deg]
if SCENARIO == 4
    plot(t, w_c * t * 180/pi, 'r--', 'LineWidth', 1.2);  % 参考航向角
    legend('实际 \theta','参考 \theta','Location','best');
elseif SCENARIO == 2
    yline(theta_tgt*180/pi, 'r--', 'LineWidth', 1.2);    % 目标航向角
    legend('实际 \theta','目标 \theta','Location','best');
end
xlabel('时间 [s]');  ylabel('航向角 [deg]');
title('航向角响应');

sgtitle('双轮差速AGV 双环PID控制仿真结果','FontSize',14,'FontWeight','bold');

% 保存图片到脚本所在目录
out_dir = fileparts(mfilename('fullpath'));   % 脚本所在目录
scenario_names = {'阶跃响应','定点镇定','直线跟踪','圆形跟踪'};
fname = fullfile(out_dir, ['仿真结果_场景' num2str(SCENARIO) '_' scenario_names{SCENARIO} '.png']);
saveas(gcf, fname);                           % 保存为 PNG
fprintf('图片已保存: %s\n', fname);

%% ==================== 6. 性能指标 ====================

fprintf('\n========== 控制性能指标 ==========\n');

idx_ss = floor(0.75*N):N;                     % 稳态段索引 (后 1/4 数据)
switch SCENARIO
    case 1  % 阶跃响应: 稳态速度误差
        v_err_ss = mean(abs(v_ref(idx_ss) - v_cur_all(idx_ss)));  % 平均绝对速度误差
        fprintf('速度稳态误差: %.4f m/s\n', v_err_ss);

    case 2  % 定点镇定: 终点位置/航向误差
        x_err = x_tgt - x(end);               % 终点 x 偏差
        y_err = y_tgt - y(end);               % 终点 y 偏差
        t_err = theta_tgt - theta_act(end);   % 终点航向偏差
        t_err = atan2(sin(t_err), cos(t_err));
        fprintf('终点位置误差: (%.4f, %.4f) m\n', x_err, y_err);
        fprintf('终点航向误差: %.2f deg\n', t_err * 180/pi);

    case {3, 4}  % 直线/圆形跟踪: RMSE
        v_err_rmse = sqrt(mean((v_ref(idx_ss) - v_cur_all(idx_ss)).^2));  % 线速度 RMSE
        w_err_rmse = sqrt(mean((w_ref(idx_ss) - w_cur_all(idx_ss)).^2));  % 角速度 RMSE
        fprintf('线速度 RMSE: %.4f m/s\n', v_err_rmse);
        fprintf('角速度 RMSE: %.4f rad/s\n', w_err_rmse);
        if SCENARIO == 4                     % 圆形跟踪额外输出圆度 RMSE
            dist_to_center = abs(sqrt(x.^2 + y.^2) - R_c);  % 各点到圆心的距离偏差
            fprintf('轨迹圆度 RMSE: %.4f m\n', sqrt(mean(dist_to_center(idx_ss).^2)));
        end
end

fprintf('================================\n');
