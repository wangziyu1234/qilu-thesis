%% 双轮差速AGV双环PID控制仿真
clearvars -except SCENARIO; close all; clc;  % 清除除SCENARIO外的所有变量、关闭图形、清屏

%% ==================== 1. 系统参数设置 ====================

r = 0.09;  % 车轮半径0.09m
L = 0.52;  % 两轮轮距0.52m
tau = 0.06;  % 电机机电时间常数0.06s
K_motor = 0.327;  % 电机增益(rad/s)/V

Ts = 0.005;  % 仿真步长0.005s
T_sim = 12;  % 仿真总时长12s
t = 0:Ts:T_sim;  % 生成时间向量
N = length(t);  % 总仿真步数

Kp_v = 17.0;  % 速度环比例增益
Ki_v = 103.0;  % 速度环积分增益
u_sat = 24;  % 电机电压限幅24V

Kp_dist  = 0.6;  % 位姿环距离-速度比例增益
Kp_theta = 3.0;  % 位姿环航向角比例增益
Ki_theta = 0.2;  % 位姿环航向角积分增益
Kd_theta = 0.4;  % 位姿环航向角微分增益

v_max     = 0.5;  % 线速度限幅0.5m/s
omega_max = 2.5;  % 角速度限幅2.5rad/s

%% ==================== 2. 状态向量预分配 ====================

x = zeros(1,N);  % 预分配x坐标序列
y = zeros(1,N);  % 预分配y坐标序列
theta_act = zeros(1,N);  % 预分配实际航向角序列
wL_act = zeros(1,N);  % 预分配左轮实际角速度
wR_act = zeros(1,N);  % 预分配右轮实际角速度
wL_ref = zeros(1,N);  % 预分配左轮指令角速度
wR_ref = zeros(1,N);  % 预分配右轮指令角速度
v_cmd  = zeros(1,N);  % 预分配外环输出线速度指令
w_cmd  = zeros(1,N);  % 预分配外环输出角速度指令
uL     = zeros(1,N);  % 预分配左电机电压
uR     = zeros(1,N);  % 预分配右电机电压

x(1) = 0;  y(1) = 0;  theta_act(1) = 0;  % 初始位姿：原点，航向0°
wL_act(1) = 0;  wR_act(1) = 0;  % 初始轮速为零

int_theta  = 0;  % 航向角积分项初值
err_theta_prev = 0;  % 上一拍航向偏差初值

%% ==================== 3. 四种参考轨迹定义 ====================

if ~exist('SCENARIO', 'var'), SCENARIO = 4; end  % 默认场景4（圆形轨迹跟踪）

switch SCENARIO  % 根据场景编号选择参考轨迹
    case 1  % 场景1：阶跃响应，2.5s后给0.3m/s速度指令
        v_ref = [zeros(1,floor(N/4)), 0.3*ones(1,N-floor(N/4))];  % 前1/4为零，后3/4恒值0.3
        w_ref = zeros(1,N);  % 角速度指令为零

    case 2  % 场景2：定点镇定，目标位姿(2.0,1.0,45°)
        x_tgt = 2.0;  % 目标x坐标
        y_tgt = 1.0;  % 目标y坐标
        theta_tgt = pi/4;  % 目标航向角45°
        v_ref = zeros(1,N);  % 无固定参考速度
        w_ref = zeros(1,N);  % 无固定参考角速度

    case 3  % 场景3：直线跟踪y=0.6
        v_ref = 0.25 * ones(1,N);  % 恒定线速度0.25m/s
        w_ref = zeros(1,N);  % 角速度指令为零

    case 4  % 场景4：圆形轨迹跟踪，半径0.8m，周期16s
        R_c = 0.8;  % 圆半径0.8m
        w_c = 2*pi/16;  % 圆角速度
        v_ref = R_c * w_c * ones(1,N);  % 参考线速度v=ωR
        w_ref = w_c * ones(1,N);  % 参考角速度
end

%% ==================== 4. 主仿真循环 ====================

int_L = 0;  int_R = 0;  % 左右轮速度环积分项初值

for k = 1:N-1  % 遍历每个仿真步

    v_cur  = r/2 * (wL_act(k) + wR_act(k));  % 由轮速反馈计算当前线速度
    w_cur  = r/L * (wR_act(k) - wL_act(k));  % 由轮速反馈计算当前角速度

    switch SCENARIO  % 根据场景执行不同的外环控制策略
        case 1  % 阶跃响应：直接给定速度指令
            v_cmd(k) = v_ref(k);  % 线速度等于参考值
            w_cmd(k) = 0;  % 角速度为零

        case 2  % 定点镇定：距离+航向两阶段控制
            ex = x_tgt - x(k);  % x方向偏差
            ey = y_tgt - y(k);  % y方向偏差
            dist_err = sqrt(ex^2 + ey^2);  % 到目标点的欧氏距离

            if dist_err > 0.08  % 距离大于8cm：朝目标点前进
                theta_des = atan2(ey, ex);  % 期望航向指向目标点
            else  % 距离小于8cm：对准目标角度
                theta_des = theta_tgt;  % 期望航向为最终目标角度
            end
            e_theta = theta_des - theta_act(k);  % 航向偏差
            e_theta = atan2(sin(e_theta), cos(e_theta));  % 归一化到[-π,π]

            int_theta = int_theta + e_theta * Ts;  % 航向积分累加
            d_theta = (e_theta - err_theta_prev) / Ts;  % 航向微分计算
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta + Kd_theta*d_theta;  % 航向PID输出
            err_theta_prev = e_theta;  % 保存本拍偏差

            v_cmd(k) = Kp_dist * dist_err;  % 线速度与距离成正比
            if abs(e_theta) > pi/3  % 航向偏差大于60°：优先转向
                v_cmd(k) = v_cmd(k) * 0.2;  % 降速至20%
            end
            if dist_err < 0.08  % 接近目标：继续降速
                v_cmd(k) = v_cmd(k) * (dist_err / 0.08);  % 按比例降速
            end
            if dist_err < 0.01 && abs(e_theta) < 0.03  % 到位判定（1cm且1.7°）
                v_cmd(k) = 0;  w_cmd(k) = 0;  % 停车
            end

        case 3  % 直线跟踪：目标直线y=0.6
            v_cmd(k) = v_ref(k);  % 纵向速度保持标称值

            e_lat = 0.6 - y(k);  % 横向偏差
            e_theta = -theta_act(k);  % 期望航向为0（沿x轴）
            e_theta = atan2(sin(e_theta), cos(e_theta));  % 归一化航向偏差

            int_theta = int_theta + e_theta * Ts;  % 积分累加
            d_theta = (e_theta - err_theta_prev) / Ts;  % 微分计算
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta ...  % PID输出+横向偏差前馈
                       + 0.5*Kp_dist*e_lat;
            err_theta_prev = e_theta;  % 保存本拍偏差

        case 4  % 圆形轨迹跟踪
            theta_ref = w_c * t(k);  % 参考航向角
            x_ref = R_c * cos(theta_ref);  % 参考x坐标
            y_ref = R_c * sin(theta_ref);  % 参考y坐标

            ex = x_ref - x(k);  % x方向偏差
            ey = y_ref - y(k);  % y方向偏差

            theta_path = theta_ref + pi/2;  % 轨迹切线方向（径向+90°）
            cross_track = -sin(theta_path)*ex + cos(theta_path)*ey;  % 横向偏差（垂直轨迹方向）
            theta_des = theta_path + atan(cross_track / 0.6);  % 期望航向=切线方向+横向纠偏
            e_theta = theta_des - theta_act(k);  % 航向偏差
            e_theta = atan2(sin(e_theta), cos(e_theta));  % 归一化

            int_theta = int_theta + e_theta * Ts;  % 积分累加
            d_theta = (e_theta - err_theta_prev) / Ts;  % 微分计算
            w_cmd(k) = Kp_theta*e_theta + Ki_theta*int_theta + Kd_theta*d_theta;  % PID输出
            err_theta_prev = e_theta;  % 保存本拍偏差

            along_track = cos(theta_path)*ex + sin(theta_path)*ey;  % 纵向偏差（沿轨迹方向）
            v_cmd(k) = v_ref(k) + Kp_dist * along_track;  % 线速度=参考+纵向修正
    end

    v_cmd(k) = max(-v_max, min(v_max, v_cmd(k)));  % 线速度限幅
    w_cmd(k) = max(-omega_max, min(omega_max, w_cmd(k)));  % 角速度限幅

    wL_ref(k) = v_cmd(k)/r - w_cmd(k)*L/(2*r);  % 逆运动学计算左轮指令角速度
    wR_ref(k) = v_cmd(k)/r + w_cmd(k)*L/(2*r);  % 逆运动学计算右轮指令角速度

    eL = wL_ref(k) - wL_act(k);  % 左轮速度偏差
    eR = wR_ref(k) - wR_act(k);  % 右轮速度偏差

    if abs(eL) < 8.0, int_L = int_L + eL * Ts; else int_L = 0; end  % 积分分离：大偏差清零积分
    if abs(eR) < 8.0, int_R = int_R + eR * Ts; else int_R = 0; end  % 积分分离：大偏差清零积分

    uL(k) = Kp_v * eL + Ki_v * int_L;  % 左电机PI输出电压
    uR(k) = Kp_v * eR + Ki_v * int_R;  % 右电机PI输出电压

    if uL(k) > u_sat  % 左电压超上限
        uL(k) = u_sat;  int_L = int_L - eL * Ts;  % 限幅并退回积分累加（抗饱和）
    elseif uL(k) < -u_sat  % 左电压超下限
        uL(k) = -u_sat;  int_L = int_L - eL * Ts;  % 限幅并退回积分累加
    end
    if uR(k) > u_sat  % 右电压超上限
        uR(k) = u_sat;  int_R = int_R - eR * Ts;  % 限幅并退回积分累加
    elseif uR(k) < -u_sat  % 右电压超下限
        uR(k) = -u_sat;  int_R = int_R - eR * Ts;  % 限幅并退回积分累加
    end

    wL_ss = K_motor * uL(k);  % 左轮稳态角速度=电机增益×电压
    wR_ss = K_motor * uR(k);  % 右轮稳态角速度
    dwL = (wL_ss - wL_act(k)) / tau;  % 左轮角加速度（一阶惯性）
    dwR = (wR_ss - wR_act(k)) / tau;  % 右轮角加速度
    wL_act(k+1) = wL_act(k) + dwL * Ts;  % 左轮速度欧拉更新
    wR_act(k+1) = wR_act(k) + dwR * Ts;  % 右轮速度欧拉更新

    v_now  = r/2 * (wL_act(k+1) + wR_act(k+1));  % 更新后的实际线速度
    w_now  = r/L * (wR_act(k+1) - wL_act(k+1));  % 更新后的实际角速度

    x(k+1) = x(k) + v_now * cos(theta_act(k)) * Ts;  % x坐标欧拉更新
    y(k+1) = y(k) + v_now * sin(theta_act(k)) * Ts;  % y坐标欧拉更新
    theta_act(k+1) = theta_act(k) + w_now * Ts;  % 航向角欧拉更新

end
fprintf('仿真完成。\n');  % 打印完成信息

%% ==================== 5. 结果可视化 ====================

figure('Name','双轮差速PID控制仿真','NumberTitle','off',...  % 创建图形窗口
       'Position',[100 60 1200 750]);

subplot(2,3,1);  hold on;  grid on;  axis equal;  % 第1子图：轨迹

switch SCENARIO  % 根据场景绘制不同轨迹
    case 2  % 定点镇定轨迹
        plot(x, y, 'b-', 'LineWidth', 1.5);  % 实际轨迹蓝色实线
        plot(x_tgt, y_tgt, 'r*', 'MarkerSize', 12, 'LineWidth', 2);  % 目标点红色星号
        plot(x(1), y(1), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);  % 起点黑色圆点
        legend('实际轨迹','目标点','起点','Location','best');  % 图例
        title('定点镇定轨迹');  % 标题
    case 3  % 直线跟踪轨迹
        plot(x, y, 'b-', 'LineWidth', 1.5);  % 实际轨迹
        yline(0.6, 'r--', 'LineWidth', 1.5);  % 目标直线y=0.6红色虚线
        legend('实际轨迹','目标直线','Location','best');  % 图例
        title('直线跟踪轨迹');  % 标题
    case 4  % 圆形轨迹跟踪
        plot(x, y, 'b-', 'LineWidth', 1.2);  % 实际轨迹
        theta_plot = linspace(0, 2*pi, 200);  % 生成圆的角度参数
        plot(R_c*cos(theta_plot), R_c*sin(theta_plot), 'r--', 'LineWidth', 1.5);  % 参考圆
        legend('实际轨迹','参考圆','Location','best');  % 图例
        title('圆形轨迹跟踪');  % 标题
end
xlabel('X [m]');  ylabel('Y [m]');  % 坐标轴标签

subplot(2,3,2);  hold on;  grid on;  % 第2子图：线速度跟踪
v_cur_all = r/2 * (wL_act + wR_act);  % 全程实际线速度
plot(t, v_cur_all, 'b-', 'LineWidth', 1.2);  % 实际线速度蓝色
plot(t, v_ref, 'r--', 'LineWidth', 1.2);  % 参考线速度红色虚线
xlabel('时间 [s]');  ylabel('线速度 [m/s]');  % 坐标轴标签
legend('实际 v','参考 v','Location','best');  % 图例
title('线速度跟踪');  % 标题

subplot(2,3,3);  hold on;  grid on;  % 第3子图：角速度跟踪
w_cur_all = r/L * (wR_act - wL_act);  % 全程实际角速度
plot(t, w_cur_all, 'b-', 'LineWidth', 1.2);  % 实际角速度
plot(t, w_ref, 'r--', 'LineWidth', 1.2);  % 参考角速度
xlabel('时间 [s]');  ylabel('角速度 [rad/s]');  % 坐标轴标签
legend('实际 \omega','参考 \omega','Location','best');  % 图例
title('角速度跟踪');  % 标题

subplot(2,3,4);  hold on;  grid on;  % 第4子图：左右轮速跟踪
plot(t, wL_act, 'b-', 'LineWidth', 1.0);  % 左轮实际角速度蓝色
plot(t, wR_act, 'r-', 'LineWidth', 1.0);  % 右轮实际角速度红色
plot(t, wL_ref, 'b--', 'LineWidth', 0.8);  % 左轮指令角速度蓝色虚线
plot(t, wR_ref, 'r--', 'LineWidth', 0.8);  % 右轮指令角速度红色虚线
xlabel('时间 [s]');  ylabel('轮速 [rad/s]');  % 坐标轴标签
legend('\omega_L 实际','\omega_R 实际','\omega_L 指令','\omega_R 指令','Location','best');  % 图例
title('左右轮速跟踪');  % 标题

subplot(2,3,5);  hold on;  grid on;  % 第5子图：电机控制电压
plot(t, uL, 'b-', 'LineWidth', 1.0);  % 左电机电压
plot(t, uR, 'r-', 'LineWidth', 1.0);  % 右电机电压
yline(u_sat, 'k--');  yline(-u_sat, 'k--');  % 饱和限±24V虚线
xlabel('时间 [s]');  ylabel('电压 [V]');  % 坐标轴标签
legend('u_L','u_R','饱和限','Location','best');  % 图例
title('电机控制电压');  % 标题

subplot(2,3,6);  hold on;  grid on;  % 第6子图：航向角响应
plot(t, theta_act * 180/pi, 'b-', 'LineWidth', 1.2);  % 实际航向角（转为度）
if SCENARIO == 4  % 圆形跟踪时绘制参考航向
    plot(t, w_c * t * 180/pi, 'r--', 'LineWidth', 1.2);  % 参考航向角
    legend('实际 \theta','参考 \theta','Location','best');  % 图例
elseif SCENARIO == 2  % 定点镇定绘制目标航向
    yline(theta_tgt*180/pi, 'r--', 'LineWidth', 1.2);  % 目标航向角虚线
    legend('实际 \theta','目标 \theta','Location','best');  % 图例
end
xlabel('时间 [s]');  ylabel('航向角 [deg]');  % 坐标轴标签
title('航向角响应');  % 标题

sgtitle('双轮差速AGV 双环PID控制仿真结果','FontSize',14,'FontWeight','bold');  % 全局标题

out_dir = fileparts(mfilename('fullpath'));  % 获取脚本所在目录路径
scenario_names = {'阶跃响应','定点镇定','直线跟踪','圆形跟踪'};  % 四种场景名称
fname = fullfile(out_dir, ['仿真结果_场景' num2str(SCENARIO) '_' scenario_names{SCENARIO} '.png']);  % 拼接文件名
saveas(gcf, fname);  % 保存为PNG图片
fprintf('图片已保存: %s\n', fname);  % 打印保存路径

%% ==================== 6. 控制性能指标计算 ====================

fprintf('\n========== 控制性能指标 ==========\n');  % 打印性能指标标题

idx_ss = floor(0.75*N):N;  % 稳态段索引（后1/4数据）
switch SCENARIO  % 根据场景计算不同指标
    case 1  % 阶跃响应：稳态速度误差
        v_err_ss = mean(abs(v_ref(idx_ss) - v_cur_all(idx_ss)));  % 稳态平均绝对速度误差
        fprintf('速度稳态误差: %.4f m/s\n', v_err_ss);  % 打印速度误差

    case 2  % 定点镇定：终点位置和航向误差
        x_err = x_tgt - x(end);  % 终点x偏差
        y_err = y_tgt - y(end);  % 终点y偏差
        t_err = theta_tgt - theta_act(end);  % 终点航向偏差
        t_err = atan2(sin(t_err), cos(t_err));  % 归一化航向偏差
        fprintf('终点位置误差: (%.4f, %.4f) m\n', x_err, y_err);  % 打印位置误差
        fprintf('终点航向误差: %.2f deg\n', t_err * 180/pi);  % 打印航向误差

    case {3, 4}  % 直线/圆形跟踪：RMSE指标
        v_err_rmse = sqrt(mean((v_ref(idx_ss) - v_cur_all(idx_ss)).^2));  % 线速度RMSE
        w_err_rmse = sqrt(mean((w_ref(idx_ss) - w_cur_all(idx_ss)).^2));  % 角速度RMSE
        fprintf('线速度 RMSE: %.4f m/s\n', v_err_rmse);  % 打印线速度RMSE
        fprintf('角速度 RMSE: %.4f rad/s\n', w_err_rmse);  % 打印角速度RMSE
        if SCENARIO == 4  % 圆形跟踪额外输出轨迹圆度RMSE
            dist_to_center = abs(sqrt(x.^2 + y.^2) - R_c);  % 各点到圆心的距离偏差
            fprintf('轨迹圆度 RMSE: %.4f m\n', sqrt(mean(dist_to_center(idx_ss).^2)));  % 打印圆度RMSE
        end
end

fprintf('================================\n');  % 打印分隔线
