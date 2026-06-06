%% 双轮差速AGV双环PID控制仿真 + 单环PID对比实验
%  外环(位姿环): 根据位置/航向偏差计算速度指令 v_cmd, ω_cmd
%  内环(轮速环): PI控制左右轮跟踪逆运动学解算的轮速指令
%  四种场景：阶跃响应、定点镇定、直线跟踪、圆形轨迹跟踪
%  对比实验：双环PID vs 单环PID（无内环速度闭环）
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

% 图片输出目录
fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% —— 主循环: 四种场景 ——

scenario_names = {'阶跃响应','定点镇定','直线跟踪','圆形跟踪'};

for SCENARIO = 1:4
fprintf('\n===== 场景%d: %s =====\n', SCENARIO, scenario_names{SCENARIO});

%% —— 双环PID仿真 ——
dual = run_dual_pid(SCENARIO, r, L, tau, K_motor, Ts, T_sim, ...
    Kp_v, Ki_v, u_sat, Kp_dist, Kp_theta, Ki_theta, Kd_theta, v_max, omega_max);

%% —— 单环PID仿真(对照组) ——
single = run_single_pid(SCENARIO, r, L, tau, K_motor, Ts, T_sim, ...
    Kp_dist, Kp_theta, Ki_theta, Kd_theta, u_sat, v_max, omega_max);

%% —— 对比图绘制 ——
plot_pid_comparison(dual, single, SCENARIO, fig_dir, scenario_names{SCENARIO});

end  % for SCENARIO = 1:4

fprintf('\n================================\n');
fprintf('所有场景仿真完成，对比图已保存至: %s\n', fig_dir);

%% ===== 局部函数: 双环PID仿真 =====
function res = run_dual_pid(SC, r, L, tau, K_motor, Ts, T_sim, ...
    Kp_v, Ki_v, u_sat, Kp_dist, Kp_theta, Ki_theta, Kd_theta, ~, omega_max)
    t = 0:Ts:T_sim; N = length(t);

    x = zeros(1,N); y = zeros(1,N); th = zeros(1,N);
    wL = zeros(1,N); wR = zeros(1,N);
    v_cmd = zeros(1,N); w_cmd = zeros(1,N);
    uL = zeros(1,N); uR = zeros(1,N);
    int_th = 0; e_th_prev = 0; int_L = 0; int_R = 0;

    switch SC
        case 1
            v_ref = [zeros(1,floor(N/4)), 0.3*ones(1,N-floor(N/4))];
            w_ref = zeros(1,N);
        case 2
            x_tgt=2.0; y_tgt=1.0; th_tgt=pi/4;
            v_ref=zeros(1,N); w_ref=zeros(1,N);
        case 3
            v_ref=0.25*ones(1,N); w_ref=zeros(1,N);
        case 4
            R_c=0.8; w_c=2*pi/16;
            v_ref=R_c*w_c*ones(1,N); w_ref=w_c*ones(1,N);
    end

    for k = 1:N-1
        switch SC
            case 1
                v_cmd(k)=v_ref(k); w_cmd(k)=0;
            case 2
                ex=x_tgt-x(k); ey=y_tgt-y(k); d_err=sqrt(ex^2+ey^2);
                if d_err>0.08, th_des=atan2(ey,ex); else, th_des=th_tgt; end
                e_th=atan2(sin(th_des-th(k)),cos(th_des-th(k)));
                int_th=int_th+e_th*Ts;
                d_th=(e_th-e_th_prev)/Ts;
                w_cmd(k)=Kp_theta*e_th+Ki_theta*int_th+Kd_theta*d_th;
                w_cmd(k)=max(-omega_max,min(omega_max,w_cmd(k)));
                v_cmd(k)=max(0,Kp_dist*d_err);
                if abs(e_th)>pi/3, v_cmd(k)=v_cmd(k)*0.2; end
                if d_err<0.02, v_cmd(k)=0; end
                e_th_prev=e_th;
            case 3
                lat_err=0.6-y(k);
                th_des=atan2(Kp_dist*lat_err,v_ref(k)+1e-6);
                e_th=atan2(sin(th_des-th(k)),cos(th_des-th(k)));
                int_th=int_th+e_th*Ts;
                d_th=(e_th-e_th_prev)/Ts;
                w_cmd(k)=Kp_theta*e_th+Ki_theta*int_th+Kd_theta*d_th;
                w_cmd(k)=max(-omega_max,min(omega_max,w_cmd(k)));
                v_cmd(k)=v_ref(k);
                e_th_prev=e_th;
            case 4
                theta_ref = w_c * t(k);
                x_ref = R_c * cos(theta_ref);  y_ref = R_c * sin(theta_ref);
                theta_path = theta_ref + pi/2;
                ex = x_ref - x(k);  ey = y_ref - y(k);
                cross_track = -sin(theta_path)*ex + cos(theta_path)*ey;
                theta_des = theta_path + atan(cross_track / 0.6);
                e_th = atan2(sin(theta_des-th(k)), cos(theta_des-th(k)));
                int_th = int_th + e_th*Ts;
                d_th = (e_th - e_th_prev)/Ts;
                w_cmd(k) = Kp_theta*e_th + Ki_theta*int_th + Kd_theta*d_th;
                e_th_prev = e_th;
                along_track = cos(theta_path)*ex + sin(theta_path)*ey;
                v_cmd(k) = v_ref(k) + Kp_dist * along_track;
        end

        % 逆运动学 → 内环速度PI
        wL_ref = (2*v_cmd(k)-w_cmd(k)*L)/(2*r);
        wR_ref = (2*v_cmd(k)+w_cmd(k)*L)/(2*r);
        eL=wL_ref-wL(k); eR=wR_ref-wR(k);
        if abs(eL)>5, int_L=0; else, int_L=int_L+eL*Ts; end
        if abs(eR)>5, int_R=0; else, int_R=int_R+eR*Ts; end
        uL(k)=Kp_v*eL+Ki_v*int_L; uR(k)=Kp_v*eR+Ki_v*int_R;
        if abs(uL(k))>u_sat&&sign(uL(k))==sign(eL), uL(k)=sign(uL(k))*u_sat; int_L=int_L-eL*Ts; end
        if abs(uR(k))>u_sat&&sign(uR(k))==sign(eR), uR(k)=sign(uR(k))*u_sat; int_R=int_R-eR*Ts; end

        % 电机动力学 (含负载扰动)
        dist = 1.5*sin(0.8*t(k));  % 正弦摩擦扰动
        wL(k+1)=wL(k)+(K_motor*uL(k)-wL(k)+dist)/tau*Ts;
        wR(k+1)=wR(k)+(K_motor*uR(k)-wR(k)+dist)/tau*Ts;
        v_next=r/2*(wL(k+1)+wR(k+1));
        w_next=r/L*(wR(k+1)-wL(k+1));
        th(k+1)=th(k)+w_next*Ts;
        x(k+1)=x(k)+v_next*cos(th(k+1))*Ts;
        y(k+1)=y(k)+v_next*sin(th(k+1))*Ts;
    end

    res.t=t; res.x=x; res.y=y; res.th=th;
    res.v=r/2*(wL+wR); res.w=r/L*(wR-wL);
    res.v_ref=v_ref; res.w_ref=w_ref;
    res.uL=uL; res.uR=uR;
    res.wL_act=wL; res.wR_act=wR;
    res.name='双环PID'; res.SC=SC;
    if SC==2, res.x_tgt=x_tgt; res.y_tgt=y_tgt; res.th_tgt=th_tgt; end
    if SC==4, res.R_c=R_c; end
end

%% ===== 局部函数: 单环PID仿真(对照组) =====
function res = run_single_pid(SC, r, L, tau, K_motor, Ts, T_sim, ...
    Kp_dist, Kp_theta, Ki_theta, Kd_theta, u_sat, v_max, omega_max)
    t = 0:Ts:T_sim; N = length(t);
    % 单环PID: 与双环相同的外环参数, 但没有内环PI反馈
    % 外环PID输出速度指令, 直接转电压(无轮速闭环)

    x = zeros(1,N); y = zeros(1,N); th = zeros(1,N);
    wL = zeros(1,N); wR = zeros(1,N);
    v_cmd = zeros(1,N); w_cmd = zeros(1,N);
    uL = zeros(1,N); uR = zeros(1,N);
    int_th = 0; e_th_prev = 0;

    switch SC
        case 1
            v_ref = [zeros(1,floor(N/4)), 0.3*ones(1,N-floor(N/4))];
            w_ref = zeros(1,N);
        case 2
            x_tgt=2.0; y_tgt=1.0; th_tgt=pi/4;
            v_ref=zeros(1,N); w_ref=zeros(1,N);
        case 3
            v_ref=0.25*ones(1,N); w_ref=zeros(1,N);
        case 4
            R_c=0.8; w_c=2*pi/16;
            v_ref=R_c*w_c*ones(1,N); w_ref=w_c*ones(1,N);
    end

    for k = 1:N-1
        switch SC
            case 1
                v_cmd(k)=v_ref(k); w_cmd(k)=0;
            case 2
                ex=x_tgt-x(k); ey=y_tgt-y(k); d_err=sqrt(ex^2+ey^2);
                if d_err>0.08, th_des=atan2(ey,ex); else, th_des=th_tgt; end
                e_th=atan2(sin(th_des-th(k)),cos(th_des-th(k)));
                int_th=int_th+e_th*Ts;
                d_th=(e_th-e_th_prev)/Ts;
                w_cmd(k)=Kp_theta*e_th+Ki_theta*int_th+Kd_theta*d_th;
                w_cmd(k)=max(-omega_max,min(omega_max,w_cmd(k)));
                v_cmd(k)=max(0,Kp_dist*d_err);
                if abs(e_th)>pi/3, v_cmd(k)=v_cmd(k)*0.2; end
                if d_err<0.02, v_cmd(k)=0; end
                e_th_prev=e_th;
            case 3
                lat_err=0.6-y(k);
                th_des=atan2(Kp_dist*lat_err,v_ref(k)+1e-6);
                e_th=atan2(sin(th_des-th(k)),cos(th_des-th(k)));
                int_th=int_th+e_th*Ts;
                d_th=(e_th-e_th_prev)/Ts;
                w_cmd(k)=Kp_theta*e_th+Ki_theta*int_th+Kd_theta*d_th;
                w_cmd(k)=max(-omega_max,min(omega_max,w_cmd(k)));
                v_cmd(k)=v_ref(k);
                e_th_prev=e_th;
            case 4
                theta_ref = w_c * t(k);
                x_ref = R_c * cos(theta_ref);  y_ref = R_c * sin(theta_ref);
                theta_path = theta_ref + pi/2;
                ex_r = x_ref - x(k);  ey_r = y_ref - y(k);
                cross_track = -sin(theta_path)*ex_r + cos(theta_path)*ey_r;
                along_track = cos(theta_path)*ex_r + sin(theta_path)*ey_r;
                theta_des = theta_path + atan(cross_track / 0.6);
                e_th = atan2(sin(theta_des-th(k)), cos(theta_des-th(k)));
                int_th = int_th + e_th*Ts;
                d_th = (e_th - e_th_prev)/Ts;
                w_cmd(k) = Kp_theta*e_th + Ki_theta*int_th + Kd_theta*d_th;
                e_th_prev = e_th;
                v_cmd(k) = v_ref(k) + Kp_dist * along_track;
        end

        v_cmd(k) = max(-v_max, min(v_max, v_cmd(k)));
        w_cmd(k) = max(-omega_max, min(omega_max, w_cmd(k)));

        % 单环: 逆运动学→直接转电压 (没有内环PI跟踪轮速)
        wL_des = (2*v_cmd(k)-w_cmd(k)*L)/(2*r);
        wR_des = (2*v_cmd(k)+w_cmd(k)*L)/(2*r);
        uL(k) = wL_des / K_motor;
        uR(k) = wR_des / K_motor;
        uL(k) = max(-u_sat, min(u_sat, uL(k)));
        uR(k) = max(-u_sat, min(u_sat, uR(k)));

        % 电机动力学 (含相同负载扰动)
        dist = 1.5*sin(0.8*t(k));
        wL(k+1) = wL(k) + (K_motor*uL(k)-wL(k)+dist)/tau*Ts;
        wR(k+1) = wR(k) + (K_motor*uR(k)-wR(k)+dist)/tau*Ts;
        v_next = r/2*(wL(k+1)+wR(k+1));
        w_next = r/L*(wR(k+1)-wL(k+1));
        th(k+1) = th(k) + w_next*Ts;
        x(k+1) = x(k) + v_next*cos(th(k+1))*Ts;
        y(k+1) = y(k) + v_next*sin(th(k+1))*Ts;
    end

    res.t=t; res.x=x; res.y=y; res.th=th;
    res.v=r/2*(wL+wR); res.w=r/L*(wR-wL);
    res.v_ref=v_ref; res.w_ref=w_ref;
    res.uL=uL; res.uR=uR;
    res.name='单环PID'; res.SC=SC;
    if SC==2, res.x_tgt=x_tgt; res.y_tgt=y_tgt; res.th_tgt=th_tgt; end
    if SC==4, res.R_c=R_c; end
end

%% ===== 局部函数: 对比图 (每个场景拆成独立图片) =====
function plot_pid_comparison(dual, single, SC, fig_dir, sc_name)
    t = dual.t;
    fnames = {'step','point','line','circle'};
    prefix = sprintf('pid_%s', fnames{SC});

    % ---- 图1: 轨迹对比 ----
    fig1 = figure('Color','w','Position',[50,50,700,550]);
    hold on; grid on; axis equal;
    plot(dual.x, dual.y, 'b-', 'LineWidth',2, 'DisplayName','双环PID');
    plot(single.x, single.y, 'r--', 'LineWidth',1.8, 'DisplayName','单环PID');
    if SC==2
        plot(dual.x_tgt, dual.y_tgt, 'k*', 'MarkerSize',15, 'LineWidth',2, 'DisplayName','目标点');
    elseif SC==3
        yline(0.6, 'k--', 'LineWidth',1.5, 'DisplayName','目标直线');
    elseif SC==4
        th_p = linspace(0,2*pi,200);
        plot(dual.R_c*cos(th_p), dual.R_c*sin(th_p), 'k--', 'LineWidth',1.5, 'DisplayName','参考圆');
    end
    xlabel('X (m)'); ylabel('Y (m)');
    title(sprintf('%s — 轨迹对比', sc_name));
    legend('Location','best');
    saveas(fig1, fullfile(fig_dir, [prefix '_1轨迹对比.png']));
    close(fig1);

    % ---- 图2: 线速度对比 ----
    fig2 = figure('Color','w','Position',[100,100,700,450]);
    hold on; grid on;
    if SC~=2, plot(t, dual.v_ref, 'k:', 'LineWidth',1.5, 'DisplayName','参考'); end
    plot(t, dual.v, 'b-', 'LineWidth',1.8, 'DisplayName','双环PID');
    plot(t, single.v, 'r--', 'LineWidth',1.5, 'DisplayName','单环PID');
    xlabel('时间 (s)'); ylabel('v (m/s)');
    title(sprintf('%s — 线速度对比', sc_name));
    legend('Location','best');
    saveas(fig2, fullfile(fig_dir, [prefix '_2线速度对比.png']));
    close(fig2);

    % ---- 图3: 角速度对比 ----
    fig3 = figure('Color','w','Position',[150,150,700,450]);
    hold on; grid on;
    if SC==4, plot(t, dual.w_ref, 'k:', 'LineWidth',1.5, 'DisplayName','参考'); end
    plot(t, dual.w, 'b-', 'LineWidth',1.8, 'DisplayName','双环PID');
    plot(t, single.w, 'r--', 'LineWidth',1.5, 'DisplayName','单环PID');
    xlabel('时间 (s)'); ylabel('\omega (rad/s)');
    title(sprintf('%s — 角速度对比', sc_name));
    legend('Location','best');
    saveas(fig3, fullfile(fig_dir, [prefix '_3角速度对比.png']));
    close(fig3);

    % ---- 图4: 电机电压对比 ----
    fig4 = figure('Color','w','Position',[200,200,700,450]);
    hold on; grid on;
    plot(t, dual.uL, 'b-', 'LineWidth',1.2, 'DisplayName','双环 左轮');
    plot(t, dual.uR, 'b--', 'LineWidth',1.2, 'DisplayName','双环 右轮');
    plot(t, single.uL, 'r-', 'LineWidth',1.0, 'DisplayName','单环 左轮');
    plot(t, single.uR, 'r--', 'LineWidth',1.0, 'DisplayName','单环 右轮');
    yline(24, 'k:', 'LineWidth',1); yline(-24, 'k:', 'LineWidth',1);
    xlabel('时间 (s)'); ylabel('电压 (V)');
    title(sprintf('%s — 电机电压对比', sc_name));
    legend('Location','best');
    saveas(fig4, fullfile(fig_dir, [prefix '_4电压对比.png']));
    close(fig4);

    % ---- 打印性能指标对比 ----
    idx_ss = floor(0.75*length(t)):length(t);
    fprintf('\n  %-10s | %-12s | %-12s\n', '指标', '双环PID', '单环PID');
    fprintf('  %s\n', repmat('-',1,40));
    switch SC
        case 1
            d_err = mean(abs(dual.v_ref(idx_ss)-dual.v(idx_ss)));
            s_err = mean(abs(single.v_ref(idx_ss)-single.v(idx_ss)));
            fprintf('  %-10s | %10.4f   | %10.4f\n', '速度稳态误差', d_err, s_err);
        case 2
            d_pos = sqrt((dual.x_tgt-dual.x(end))^2+(dual.y_tgt-dual.y(end))^2);
            s_pos = sqrt((single.x_tgt-single.x(end))^2+(single.y_tgt-single.y(end))^2);
            d_th = abs(rad2deg(atan2(sin(dual.th_tgt-dual.th(end)),cos(dual.th_tgt-dual.th(end)))));
            s_th = abs(rad2deg(atan2(sin(single.th_tgt-single.th(end)),cos(single.th_tgt-single.th(end)))));
            fprintf('  %-10s | %8.4f m  | %8.4f m\n', '位置误差', d_pos, s_pos);
            fprintf('  %-10s | %8.2f°    | %8.2f°\n', '航向误差', d_th, s_th);
        case 3
            d_rmse = sqrt(mean(dual.w(idx_ss).^2));
            s_rmse = sqrt(mean(single.w(idx_ss).^2));
            fprintf('  %-10s | %10.4f   | %10.4f\n', '角速度RMSE', d_rmse, s_rmse);
        case 4
            d_vr = sqrt(mean((dual.v_ref(idx_ss)-dual.v(idx_ss)).^2));
            s_vr = sqrt(mean((single.v_ref(idx_ss)-single.v(idx_ss)).^2));
            d_wr = sqrt(mean((dual.w_ref(idx_ss)-dual.w(idx_ss)).^2));
            s_wr = sqrt(mean((single.w_ref(idx_ss)-single.w(idx_ss)).^2));
            d_dist = abs(sqrt(dual.x.^2+dual.y.^2)-dual.R_c);
            s_dist = abs(sqrt(single.x.^2+single.y.^2)-single.R_c);
            fprintf('  %-10s | %10.4f   | %10.4f\n', '线速度RMSE', d_vr, s_vr);
            fprintf('  %-10s | %10.4f   | %10.4f\n', '角速度RMSE', d_wr, s_wr);
            fprintf('  %-10s | %10.4f   | %10.4f\n', '轨迹圆度RMSE', ...
                sqrt(mean(d_dist(idx_ss).^2)), sqrt(mean(s_dist(idx_ss).^2)));
    end

    fprintf('图片已保存: %s_1~4对比.png\n', prefix);
end
