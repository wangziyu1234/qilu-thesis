%% 双轮差速AGV双环PID控制仿真
clearvars -except SCENARIO; close all; clc;  % 保留SCENARIO变量

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

%% —— 状态预分配 ——

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

%% —— 四种参考轨迹 ——

if ~exist('SCENARIO', 'var'), SCENARIO = 4; end  % 默认场景4

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

    if abs(eL) < 8.0, int_L = int_L + eL * Ts; else int_L = 0; end  % 积分分离
    if abs(eR) < 8.0, int_R = int_R + eR * Ts; else int_R = 0; end

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

%% —— 结果可视化 ——

figure('Name','双轮差速PID控制仿真','NumberTitle','off',...
       'Position',[100 60 1200 750]);

subplot(2,3,1);  hold on;  grid on;  axis equal;  % XY轨迹

switch SCENARIO
    case 1  % 阶跃响应
        plot(x, y, 'b-', 'LineWidth', 1.5);
        plot(x(1), y(1), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
        legend('实际轨迹','起点','Location','best');
        title('阶跃响应轨迹');
    case 2  % 定点镇定
        plot(x, y, 'b-', 'LineWidth', 1.5);
        plot(x_tgt, y_tgt, 'r*', 'MarkerSize', 12, 'LineWidth', 2);
        plot(x(1), y(1), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
        legend('实际轨迹','目标点','起点','Location','best');
        title('定点镇定轨迹');
    case 3  % 直线跟踪
        plot(x, y, 'b-', 'LineWidth', 1.5);
        yline(0.6, 'r--', 'LineWidth', 1.5);
        legend('实际轨迹','目标直线','Location','best');
        title('直线跟踪轨迹');
    case 4  % 圆形跟踪
        plot(x, y, 'b-', 'LineWidth', 1.2);
        theta_plot = linspace(0, 2*pi, 200);
        plot(R_c*cos(theta_plot), R_c*sin(theta_plot), 'r--', 'LineWidth', 1.5);
        legend('实际轨迹','参考圆','Location','best');
        title('圆形轨迹跟踪');
end
xlabel('X [m]');  ylabel('Y [m]');

subplot(2,3,2);  hold on;  grid on;  % 线速度
v_cur_all = r/2 * (wL_act + wR_act);
plot(t, v_cur_all, 'b-', 'LineWidth', 1.2);
plot(t, v_ref, 'r--', 'LineWidth', 1.2);
xlabel('时间 [s]');  ylabel('线速度 [m/s]');
legend('实际 v','参考 v','Location','best');
title('线速度跟踪');

subplot(2,3,3);  hold on;  grid on;  % 角速度
w_cur_all = r/L * (wR_act - wL_act);
plot(t, w_cur_all, 'b-', 'LineWidth', 1.2);
plot(t, w_ref, 'r--', 'LineWidth', 1.2);
xlabel('时间 [s]');  ylabel('角速度 [rad/s]');
legend('实际 \omega','参考 \omega','Location','best');
title('角速度跟踪');

subplot(2,3,4);  hold on;  grid on;  % 轮速跟踪
plot(t, wL_act, 'b-', 'LineWidth', 1.0);
plot(t, wR_act, 'r-', 'LineWidth', 1.0);
plot(t, wL_ref, 'b--', 'LineWidth', 0.8);
plot(t, wR_ref, 'r--', 'LineWidth', 0.8);
xlabel('时间 [s]');  ylabel('轮速 [rad/s]');
legend('\omega_L 实际','\omega_R 实际','\omega_L 指令','\omega_R 指令','Location','best');
title('左右轮速跟踪');

subplot(2,3,5);  hold on;  grid on;  % 电机电压
plot(t, uL, 'b-', 'LineWidth', 1.0);
plot(t, uR, 'r-', 'LineWidth', 1.0);
yline(u_sat, 'k--');  yline(-u_sat, 'k--');
xlabel('时间 [s]');  ylabel('电压 [V]');
legend('u_L','u_R','饱和限','Location','best');
title('电机控制电压');

subplot(2,3,6);  hold on;  grid on;  % 航向角
plot(t, theta_act * 180/pi, 'b-', 'LineWidth', 1.2);
if SCENARIO == 4
    plot(t, w_c * t * 180/pi, 'r--', 'LineWidth', 1.2);
    legend('实际 \theta','参考 \theta','Location','best');
elseif SCENARIO == 2
    yline(theta_tgt*180/pi, 'r--', 'LineWidth', 1.2);
    legend('实际 \theta','目标 \theta','Location','best');
end
xlabel('时间 [s]');  ylabel('航向角 [deg]');
title('航向角响应');

sgtitle('双轮差速AGV 双环PID控制仿真结果','FontSize',14,'FontWeight','bold');

out_dir = fileparts(mfilename('fullpath'));
scenario_names = {'阶跃响应','定点镇定','直线跟踪','圆形跟踪'};
fname = fullfile(out_dir, ['仿真结果_场景' num2str(SCENARIO) '_' scenario_names{SCENARIO} '.png']);
saveas(gcf, fname);
fprintf('图片已保存: %s\n', fname);

%% —— 控制性能指标 ——

fprintf('\n========== 控制性能指标 ==========\n');

idx_ss = floor(0.75*N):N;  % 稳态段(后1/4数据)
switch SCENARIO
    case 1  % 速度稳态误差
        v_err_ss = mean(abs(v_ref(idx_ss) - v_cur_all(idx_ss)));
        fprintf('速度稳态误差: %.4f m/s\n', v_err_ss);

    case 2  % 终点误差
        x_err = x_tgt - x(end);  y_err = y_tgt - y(end);
        t_err = theta_tgt - theta_act(end);
        t_err = atan2(sin(t_err), cos(t_err));
        fprintf('终点位置误差: (%.4f, %.4f) m\n', x_err, y_err);
        fprintf('终点航向误差: %.2f deg\n', t_err * 180/pi);

    case {3, 4}  % 连续跟踪RMSE
        v_err_rmse = sqrt(mean((v_ref(idx_ss) - v_cur_all(idx_ss)).^2));
        w_err_rmse = sqrt(mean((w_ref(idx_ss) - w_cur_all(idx_ss)).^2));
        fprintf('线速度 RMSE: %.4f m/s\n', v_err_rmse);
        fprintf('角速度 RMSE: %.4f rad/s\n', w_err_rmse);
        if SCENARIO == 4
            dist_to_center = abs(sqrt(x.^2 + y.^2) - R_c);
            fprintf('轨迹圆度 RMSE: %.4f m\n', sqrt(mean(dist_to_center(idx_ss).^2)));
        end
end

fprintf('================================\n');
