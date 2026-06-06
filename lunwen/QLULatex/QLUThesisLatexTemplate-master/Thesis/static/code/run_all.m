%% 批量运行全部仿真, 保存图片, 输出关键数据
%  轮半径已更新为 r = 0.09 m, 对应驱动轮直径 180 mm

clear; clc; close all; clear functions; rehash toolboxcache;

% 图片输出目录
fig_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fprintf('========== 1. 典型轨迹运动学仿真 (traj_sim) ==========\n');

%% ---- 1.1 运行 traj_sim 仿真 ----
r = 0.09; L = 0.52; dt = 0.01; T = 20;
t_full = 0:dt:T;
x0 = [0;0;0];

cases = {
    struct('name','直线轨迹','color',[0.00,0.45,0.74],'v',@(tt)0.45+0*tt,'w',@(tt)0*tt), ...
    struct('name','定曲率圆轨迹','color',[0.85,0.33,0.10],'v',@(tt)0.35+0*tt,'w',@(tt)0.45+0*tt), ...
    struct('name','S形轨迹','color',[0.47,0.67,0.19],'v',@(tt)0.40+0*tt,'w',@(tt)0.6*sin(0.5*tt)), ...
    struct('name','8字轨迹','color',[0.49,0.18,0.56],'v',@(tt)0.38+0*tt,'w',@(tt)0.7*sin(0.7*tt)) ...
    };
Ncase = numel(cases);
results = cell(Ncase,1);

for i = 1:Ncase
    t_sub = t_full(1:end-1);
    v_cmd = cases{i}.v(t_sub);
    omega_cmd = cases{i}.w(t_sub);
    Nt = numel(t_full);
    x = zeros(1,Nt); y = zeros(1,Nt); theta = zeros(1,Nt);
    x(1)=x0(1); y(1)=x0(2); theta(1)=x0(3);
    wr = (2*v_cmd + omega_cmd*L)/(2*r);
    wl = (2*v_cmd - omega_cmd*L)/(2*r);
    for k = 1:Nt-1
        x(k+1) = x(k) + v_cmd(k)*cos(theta(k))*dt;
        y(k+1) = y(k) + v_cmd(k)*sin(theta(k))*dt;
        theta(k+1) = atan2(sin(theta(k)+omega_cmd(k)*dt), cos(theta(k)+omega_cmd(k)*dt));
    end
    eps_v = 1e-6;
    kappa = omega_cmd ./ max(abs(v_cmd), eps_v);
    s.name = cases{i}.name; s.color = cases{i}.color;
    s.t = t_full; s.x = x; s.y = y; s.theta = theta;
    s.v_cmd = v_cmd; s.omega_cmd = omega_cmd;
    s.wr = wr; s.wl = wl; s.kappa = kappa;
    dx = diff(x); dy = diff(y);
    s.path_len = sum(hypot(dx,dy));
    s.disp_len = hypot(x(end)-x(1), y(end)-y(1));
    s.avg_v = mean(abs(v_cmd));
    s.max_abs_omega = max(abs(omega_cmd));
    s.max_abs_kappa = max(abs(kappa));
    s.final_heading_deg = rad2deg(theta(end));
    results{i} = s;
end

% 打印汇总表
fprintf('%-16s %8s %8s %10s %12s %10s %10s\n', '轨迹类型','路径/m','位移/m','均速m/s','max|ω|','max|κ|','终点°');
for i=1:Ncase
    s = results{i};
    fprintf('%-16s %8.1f %8.3f %10.2f %12.2f %10.3f %10.1f\n', ...
        s.name, s.path_len, s.disp_len, s.avg_v, s.max_abs_omega, s.max_abs_kappa, s.final_heading_deg);
end

% ---- 1.2 保存各轨迹单独图片 ----
traj_files = {'直线.png','圆形.png','s型.png','8字.png'};
for i = 1:Ncase
    s = results{i};
    figure('Color','w','Position',[50,50,600,450]); hold on; grid on; axis equal;
    plot(s.x, s.y, 'LineWidth',2.0, 'Color', s.color);
    plot(s.x(1), s.y(1), 'o', 'Color', s.color, 'MarkerFaceColor', s.color);
    plot(s.x(end), s.y(end), 's', 'Color', s.color, 'MarkerFaceColor', s.color);
    xlabel('x (m)'); ylabel('y (m)'); title([s.name '仿真结果']);
    saveas(gcf, fullfile(fig_dir, traj_files{i}));
    close(gcf);
end

% ---- 1.3 线速度指令 ----
figure('Color','w','Position',[100,50,700,420]); hold on; grid on;
traj_names = cell(1,Ncase);
for i=1:Ncase, s=results{i}; plot(s.t(1:end-1),s.v_cmd,'LineWidth',1.5,'Color',s.color); traj_names{i}=cases{i}.name; end
xlabel('时间 (s)'); ylabel('v (m/s)'); title('线速度指令');
legend(traj_names,'Location','best');
saveas(gcf, fullfile(fig_dir, '线速度指令.png')); close(gcf);

% ---- 1.4 角速度指令 ----
figure('Color','w','Position',[120,70,700,420]); hold on; grid on;
for i=1:Ncase, s=results{i}; plot(s.t(1:end-1),s.omega_cmd,'LineWidth',1.5,'Color',s.color); end
xlabel('时间 (s)'); ylabel('\omega (rad/s)'); title('角速度指令');
legend(traj_names,'Location','best');
saveas(gcf, fullfile(fig_dir, '角速度指令.png')); close(gcf);

% ---- 1.5 左右轮角速度 ----
figure('Color','w','Position',[140,90,700,420]); hold on; grid on;
for i=1:Ncase
    s=results{i};
    plot(s.t(1:end-1),s.wr,'-','LineWidth',1.1,'Color',s.color);
    plot(s.t(1:end-1),s.wl,'--','LineWidth',1.1,'Color',s.color);
end
xlabel('时间 (s)'); ylabel('轮角速度 (rad/s)'); title('左右轮角速度');
legs = {};
for i=1:Ncase, legs{end+1}=[cases{i}.name ' 右轮']; legs{end+1}=[cases{i}.name ' 左轮']; end
legend(legs,'Location','best','FontSize',7);
saveas(gcf, fullfile(fig_dir, '左右轮角速度.png')); close(gcf);

% ---- 1.6 曲率对比 ----
figure('Color','w','Position',[100,50,600,400]); hold on; grid on;
for i=1:Ncase, s=results{i}; plot(s.t(1:end-1),s.kappa,'LineWidth',1.5,'Color',s.color); end
xlabel('时间 (s)'); ylabel('\kappa (1/m)'); title('瞬时曲率对比');
legend('Location','best');
saveas(gcf, fullfile(fig_dir, '曲率变化.png')); close(gcf);

fprintf('\n========== 2. PID控制仿真: 双环 vs 单环 对比 ==========\n');

%% ---- 2. 运行 PID 仿真 (双环 + 单环, 4个场景) ----
scenario_names = {'阶跃响应','定点镇定','S形轨迹','圆形跟踪'};
for SC = 1:4
    fprintf('\n--- 场景%d: %s ---\n', SC, scenario_names{SC});

    % 双环PID仿真
    dual = run_dual_pid(SC);
    % 单环PID仿真(对照组)
    single = run_single_pid(SC);

    % 画对比图 (每个场景拆成独立图片)
    plot_pid_comparison(dual, single, SC, fig_dir, scenario_names{SC});
end

% b_pid_control生成独立结果图 (需手动运行)


fprintf('\n========== 3. Hybrid A* 路径规划 + 循迹仿真 ==========\n');

%% ---- 3. Hybrid A* 路径规划 ----
addpath(fileparts(mfilename('fullpath')));
ref_path = c_hybrid_astar();

%% ---- 4. 红外循迹仿真 ----
d_tracking_pid(ref_path);

fprintf('\n========== 5. 剪叉机构运动简图 (e_mechanism_diagram) ==========\n');
e_mechanism_diagram;

fprintf('\n========== 6. 剪叉机构强度校核 (f_lift_strength) ==========\n');
f_lift_strength;

fprintf('\n========== 7. 剪叉机构有限元分析 (g_scissor_lift_fea) ==========\n');
g_scissor_lift_fea;

fprintf('\n========== 全部仿真完成 ==========\n');

%% ===== 局部函数: 双环PID仿真 =====
function res = run_dual_pid(SC)
    r = 0.09; L = 0.52; tau = 0.06; K_motor = 0.327;
    Ts = 0.005; T_sim = 12; t = 0:Ts:T_sim; N = length(t);
    Kp_v = 17.0; Ki_v = 103.0; u_sat = 24;
    Kp_dist = 0.6; Kp_theta = 3.0; Ki_theta = 0.2; Kd_theta = 0.4;
    omega_max = 2.5;

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
            v_ref=0.30*ones(1,N); w_ref=0.8*sin(1.0*t);
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
                % 预计算S形参考轨迹
                if k==1
                    x_ref_s = zeros(1,N); y_ref_s = zeros(1,N); th_ref_s = zeros(1,N);
                    for kk=1:N-1
                        x_ref_s(kk+1)=x_ref_s(kk)+v_ref(kk)*cos(th_ref_s(kk))*Ts;
                        y_ref_s(kk+1)=y_ref_s(kk)+v_ref(kk)*sin(th_ref_s(kk))*Ts;
                        th_ref_s(kk+1)=th_ref_s(kk)+w_ref(kk)*Ts;
                    end
                end
                ex_s=x_ref_s(k)-x(k); ey_s=y_ref_s(k)-y(k);
                theta_path_s=th_ref_s(k);
                cross_track_s=-sin(theta_path_s)*ex_s+cos(theta_path_s)*ey_s;
                theta_des_s=theta_path_s+atan(cross_track_s/0.6);
                e_th=atan2(sin(theta_des_s-th(k)),cos(theta_des_s-th(k)));
                int_th=int_th+e_th*Ts;
                d_th=(e_th-e_th_prev)/Ts;
                w_cmd(k)=Kp_theta*e_th+Ki_theta*int_th+Kd_theta*d_th;
                e_th_prev=e_th;
                along_track_s=cos(theta_path_s)*ex_s+sin(theta_path_s)*ey_s;
                v_cmd(k)=v_ref(k)+Kp_dist*along_track_s;
            case 4
                % 参考圆上当前时刻的期望位置
                theta_ref = w_c * t(k);
                x_ref = R_c * cos(theta_ref);  y_ref = R_c * sin(theta_ref);
                % 横向偏差(到圆弧的法向距离)
                theta_path = theta_ref + pi/2;  % 圆弧切线方向
                ex = x_ref - x(k);  ey = y_ref - y(k);
                cross_track = -sin(theta_path)*ex + cos(theta_path)*ey;
                % 航向修正: 基于横向偏差的PD控制
                theta_des = theta_path + atan(cross_track / 0.6);
                e_th = atan2(sin(theta_des-th(k)), cos(theta_des-th(k)));
                int_th = int_th + e_th*Ts;
                d_th = (e_th - e_th_prev)/Ts;
                w_cmd(k) = Kp_theta*e_th + Ki_theta*int_th + Kd_theta*d_th;
                e_th_prev = e_th;
                % 纵向偏差修正
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
    if SC==3, res.x_ref_s=x_ref_s; res.y_ref_s=y_ref_s; end
    if SC==4, res.R_c=R_c; end
end

%% ===== 局部函数: 单环PID仿真(对照组) =====
function res = run_single_pid(SC)
    r = 0.09; L = 0.52; tau = 0.06; K_motor = 0.327;
    Ts = 0.005; T_sim = 12; t = 0:Ts:T_sim; N = length(t);
    % 单环PID: 与双环相同的外环参数, 但没有内环PI反馈
    % 外环PID输出速度指令, 直接转电压(无轮速闭环)
    Kp_theta = 3.0; Ki_theta = 0.2; Kd_theta = 0.4;
    Kp_dist = 0.6;
    u_sat = 24; v_max = 0.5; omega_max = 2.5;

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
            v_ref=0.30*ones(1,N); w_ref=0.8*sin(1.0*t);
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
                % 预计算S形参考轨迹
                if k==1
                    x_ref_s = zeros(1,N); y_ref_s = zeros(1,N); th_ref_s = zeros(1,N);
                    for kk=1:N-1
                        x_ref_s(kk+1)=x_ref_s(kk)+v_ref(kk)*cos(th_ref_s(kk))*Ts;
                        y_ref_s(kk+1)=y_ref_s(kk)+v_ref(kk)*sin(th_ref_s(kk))*Ts;
                        th_ref_s(kk+1)=th_ref_s(kk)+w_ref(kk)*Ts;
                    end
                end
                ex_s=x_ref_s(k)-x(k); ey_s=y_ref_s(k)-y(k);
                theta_path_s=th_ref_s(k);
                cross_track_s=-sin(theta_path_s)*ex_s+cos(theta_path_s)*ey_s;
                theta_des_s=theta_path_s+atan(cross_track_s/0.6);
                e_th=atan2(sin(theta_des_s-th(k)),cos(theta_des_s-th(k)));
                int_th=int_th+e_th*Ts;
                d_th=(e_th-e_th_prev)/Ts;
                w_cmd(k)=Kp_theta*e_th+Ki_theta*int_th+Kd_theta*d_th;
                e_th_prev=e_th;
                along_track_s=cos(theta_path_s)*ex_s+sin(theta_path_s)*ey_s;
                v_cmd(k)=v_ref(k)+Kp_dist*along_track_s;
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
    fnames = {'step','point','scurve','circle'};

    % ---- 图1: 轨迹对比 (S形和圆形加局部放大) ----
    fig1 = figure('Color','w','Position',[50,50,700,550]);
    hold on; grid on; axis equal;
    plot(dual.x, dual.y, 'b-', 'LineWidth',2, 'DisplayName','双环PID');
    plot(single.x, single.y, 'r--', 'LineWidth',1.8, 'DisplayName','单环PID');
    if SC==2
        plot(dual.x_tgt, dual.y_tgt, 'k*', 'MarkerSize',15, 'LineWidth',2, 'DisplayName','目标点');
    elseif SC==3
        % 绘制S形参考轨迹
        if isfield(dual,'x_ref_s')
            plot(dual.x_ref_s, dual.y_ref_s, 'k:', 'LineWidth',1.5, 'DisplayName','参考轨迹');
        end
    elseif SC==4
        th_p = linspace(0,2*pi,200);
        plot(dual.R_c*cos(th_p), dual.R_c*sin(th_p), 'k--', 'LineWidth',1.5, 'DisplayName','参考圆');
    end
    xlabel('X (m)'); ylabel('Y (m)');
    title(sprintf('%s — 轨迹对比', sc_name));
    legend('Location','best');
    % S形和圆形加局部放大
    if SC==3 || SC==4
        ax_zoom = axes('Position',[0.15,0.58,0.32,0.32]);
        box on; hold on; grid on;
        plot(dual.x, dual.y, 'b-', 'LineWidth',1.5);
        plot(single.x, single.y, 'r--', 'LineWidth',1.2);
        if SC==3
            xlim([0.3,1.0]); ylim([0.6,1.4]);
        else
            xlim([-0.15,0.15]); ylim([-0.75,-0.45]);
        end
        title('局部放大');
    end
    saveas(fig1, fullfile(fig_dir, sprintf('pid_%s_1轨迹对比.png', fnames{SC})));
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
    saveas(fig2, fullfile(fig_dir, sprintf('pid_%s_2线速度对比.png', fnames{SC})));
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
    saveas(fig3, fullfile(fig_dir, sprintf('pid_%s_3角速度对比.png', fnames{SC})));
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
    saveas(fig4, fullfile(fig_dir, sprintf('pid_%s_4电压对比.png', fnames{SC})));
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
end
