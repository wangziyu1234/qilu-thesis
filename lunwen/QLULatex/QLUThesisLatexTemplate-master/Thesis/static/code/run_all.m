%% 批量运行全部仿真, 保存图片, 输出关键数据
%  轮半径已更新为 r = 0.09 m, 对应驱动轮直径 180 mm

clear; clc; close all;

% 图片输出目录
fig_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fprintf('========== 1. 典型轨迹运动学仿真 (chasu) ==========\n');

%% ---- 1.1 运行 chasu 仿真 ----
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

% ---- 1.3 控制输入与轮速曲线 ----
figure('Color','w','Position',[100,50,800,700]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
nexttile; hold on; grid on;
for i=1:Ncase, s=results{i}; plot(s.t(1:end-1),s.v_cmd,'LineWidth',1.5,'Color',s.color); end
ylabel('v (m/s)'); title('线速度指令'); legend('Location','best');
nexttile; hold on; grid on;
for i=1:Ncase, s=results{i}; plot(s.t(1:end-1),s.omega_cmd,'LineWidth',1.5,'Color',s.color); end
ylabel('\omega (rad/s)'); title('角速度指令');
nexttile; hold on; grid on;
for i=1:Ncase
    s=results{i};
    plot(s.t(1:end-1),s.wr,'-','LineWidth',1.1,'Color',s.color);
    plot(s.t(1:end-1),s.wl,'--','LineWidth',1.1,'Color',s.color);
end
xlabel('时间 (s)'); ylabel('轮角速度 (rad/s)'); title('左右轮角速度');
saveas(gcf, fullfile(fig_dir, '输入与轮速曲线.png')); close(gcf);

% ---- 1.4 曲率对比 ----
figure('Color','w','Position',[100,50,600,400]); hold on; grid on;
for i=1:Ncase, s=results{i}; plot(s.t(1:end-1),s.kappa,'LineWidth',1.5,'Color',s.color); end
xlabel('时间 (s)'); ylabel('\kappa (1/m)'); title('瞬时曲率对比');
legend('Location','best');
saveas(gcf, fullfile(fig_dir, '曲率变化.png')); close(gcf);

fprintf('\n========== 2. 双环PID控制仿真 (diff_drive_pid_sim) ==========\n');

%% ---- 2. 运行 PID 仿真 (4个场景) ----
for SCENARIO = 1:4
    fprintf('\n--- 场景 %d ---\n', SCENARIO);
    diff_drive_pid_sim_run;
end

fprintf('\n========== 3. Hybrid A* 路径规划 + 循迹仿真 ==========\n');

%% ---- 3. Hybrid A* 路径规划 ----
addpath(fileparts(mfilename('fullpath')));
ref_path = hybrid_astar_pathplanning();

%% ---- 4. 红外循迹仿真 ----
line_following_pid(ref_path);

fprintf('\n========== 全部仿真完成 ==========\n');

%% ===== 局部函数: PID仿真逻辑 =====
function diff_drive_pid_sim_run
    r = 0.09; L = 0.52; tau = 0.06;
    K_motor = 0.327;
    Ts = 0.005; T_sim = 12; t = 0:Ts:T_sim; N = length(t);
    Kp_v = 17.0; Ki_v = 103.0; u_sat = 24;
    Kp_dist = 0.6; Kp_theta = 3.0; Ki_theta = 0.2; Kd_theta = 0.4;
    v_max = 0.5; omega_max = 2.5;

    x = zeros(1,N); y = zeros(1,N); theta_act = zeros(1,N);
    wL_act = zeros(1,N); wR_act = zeros(1,N);
    wL_ref = zeros(1,N); wR_ref = zeros(1,N);
    v_cmd = zeros(1,N); w_cmd = zeros(1,N);
    uL = zeros(1,N); uR = zeros(1,N);
    x(1)=0; y(1)=0; theta_act(1)=0;
    wL_act(1)=0; wR_act(1)=0;
    int_theta=0; err_theta_prev=0;

    % Use evalin to get SCENARIO
    SC = evalin('caller','SCENARIO');
    fig_dir_local = evalin('caller','fig_dir');

    switch SC
        case 1
            v_ref = [zeros(1,floor(N/4)), 0.3*ones(1,N-floor(N/4))];
            w_ref = zeros(1,N);
        case 2
            x_tgt=2.0; y_tgt=1.0; theta_tgt=pi/4;
            v_ref=zeros(1,N); w_ref=zeros(1,N);
        case 3
            v_ref=0.25*ones(1,N); w_ref=zeros(1,N);
        case 4
            R_c=0.8; w_c=2*pi/16;
            v_ref=R_c*w_c*ones(1,N); w_ref=w_c*ones(1,N);
    end

    int_L=0; int_R=0;
    for k = 1:N-1
        v_cur = r/2*(wL_act(k)+wR_act(k));
        w_cur = r/L*(wR_act(k)-wL_act(k));

        switch SC
            case 1
                v_cmd(k)=v_ref(k); w_cmd(k)=0;
            case 2
                ex=x_tgt-x(k); ey=y_tgt-y(k); dist_err=sqrt(ex^2+ey^2);
                if dist_err>0.08, theta_des=atan2(ey,ex);
                else, theta_des=theta_tgt; end
                err_theta = atan2(sin(theta_des-theta_act(k)), cos(theta_des-theta_act(k)));
                int_theta = int_theta + err_theta*Ts;
                d_theta = (err_theta-err_theta_prev)/Ts;
                w_cmd(k) = Kp_theta*err_theta + Ki_theta*int_theta + Kd_theta*d_theta;
                w_cmd(k) = max(-omega_max, min(omega_max, w_cmd(k)));
                v_cmd(k) = max(0, Kp_dist*dist_err);
                if abs(err_theta)>pi/3, v_cmd(k)=v_cmd(k)*0.2; end
                if dist_err<0.02, v_cmd(k)=0; end
                err_theta_prev=err_theta;
            case 3
                lat_err = 0.6-y(k);
                theta_des = atan2(Kp_dist*lat_err, v_ref(k)+1e-6);
                err_theta = atan2(sin(theta_des-theta_act(k)),cos(theta_des-theta_act(k)));
                int_theta = int_theta + err_theta*Ts;
                d_theta = (err_theta-err_theta_prev)/Ts;
                w_cmd(k) = Kp_theta*err_theta + Ki_theta*int_theta + Kd_theta*d_theta;
                w_cmd(k) = max(-omega_max, min(omega_max, w_cmd(k)));
                v_cmd(k) = v_ref(k);
                err_theta_prev=err_theta;
            case 4
                v_cmd(k)=v_ref(k); w_cmd(k)=w_ref(k);
        end

        wL_ref(k+1) = (2*v_cmd(k)-w_cmd(k)*L)/(2*r);
        wR_ref(k+1) = (2*v_cmd(k)+w_cmd(k)*L)/(2*r);
        eL = wL_ref(k+1)-wL_act(k); eR = wR_ref(k+1)-wR_act(k);
        if abs(eL)>8.0, int_L=0; else, int_L=int_L+eL*Ts; end
        if abs(eR)>8.0, int_R=0; else, int_R=int_R+eR*Ts; end
        uL(k)=Kp_v*eL+Ki_v*int_L; uR(k)=Kp_v*eR+Ki_v*int_R;
        if abs(uL(k))>u_sat && sign(uL(k))==sign(eL), uL(k)=sign(uL(k))*u_sat; int_L=int_L-eL*Ts; end
        if abs(uR(k))>u_sat && sign(uR(k))==sign(eR), uR(k)=sign(uR(k))*u_sat; int_R=int_R-eR*Ts; end
        dwL = (K_motor*uL(k)-wL_act(k))/tau;
        dwR = (K_motor*uR(k)-wR_act(k))/tau;
        wL_act(k+1) = wL_act(k) + dwL*Ts;
        wR_act(k+1) = wR_act(k) + dwR*Ts;
        v_cur_next = r/2*(wL_act(k+1)+wR_act(k+1));
        w_cur_next = r/L*(wR_act(k+1)-wL_act(k+1));
        theta_act(k+1) = theta_act(k) + w_cur_next*Ts;
        x(k+1) = x(k) + v_cur_next*cos(theta_act(k+1))*Ts;
        y(k+1) = y(k) + v_cur_next*sin(theta_act(k+1))*Ts;
    end

    wL_ref(1)=wL_ref(2); wR_ref(1)=wR_ref(2);
    v_cur_all = r/2*(wL_act+wR_act);
    w_cur_all = r/L*(wR_act-wL_act);
    idx_ss = floor(0.75*N):N;

    % 绘图
    fig = figure('Color','w','Position',[50,50,1200,800]);
    tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

    nexttile; hold on; grid on;
    plot(t, x,'b-','LineWidth',1.5); xlabel('时间 (s)'); ylabel('x (m)'); title('X 坐标');

    nexttile; hold on; grid on;
    plot(t, y,'r-','LineWidth',1.5); xlabel('时间 (s)'); ylabel('y (m)'); title('Y 坐标');

    nexttile; hold on; grid on;
    plot(t, theta_act*180/pi,'k-','LineWidth',1.5); xlabel('时间 (s)'); ylabel('\theta (°)'); title('航向角');

    nexttile; hold on; grid on;
    if SC==1||SC==3||SC==4, plot(t, v_ref,'b--','LineWidth',1); end
    plot(t, v_cur_all,'r-','LineWidth',1.5);
    xlabel('时间 (s)'); ylabel('v (m/s)'); title('线速度'); legend('参考','实际','Location','best');

    nexttile; hold on; grid on;
    if SC==4, plot(t, w_ref,'b--','LineWidth',1); end
    plot(t, w_cur_all,'r-','LineWidth',1.5);
    xlabel('时间 (s)'); ylabel('\omega (rad/s)'); title('角速度');

    nexttile; hold on; grid on;
    plot(t, uL,'b-','LineWidth',1); plot(t, uR,'r--','LineWidth',1);
    xlabel('时间 (s)'); ylabel('电压 (V)'); title('电机电压'); legend('左','右');

    sgtitle(sprintf('双环PID控制仿真 - 场景%d', SC),'FontSize',14,'FontWeight','bold');

    fnames = {'pid_step_response','pid_point_stabilization','pid_line_tracking','pid_circle_tracking'};
    saveas(fig, fullfile(fig_dir_local, [fnames{SC} '.png'])); close(fig);

    % 打印指标
    switch SC
        case 1
            v_err = mean(abs(v_ref(idx_ss)-v_cur_all(idx_ss)));
            fprintf('速度稳态误差: %.4f m/s\n', v_err);
        case 2
            fprintf('终点位置误差: (%.4f, %.4f) m\n', x_tgt-x(end), y_tgt-y(end));
            t_err = atan2(sin(theta_tgt-theta_act(end)), cos(theta_tgt-theta_act(end)));
            fprintf('终点航向误差: %.2f deg\n', t_err*180/pi);
        case 3
            fprintf('角速度RMSE: %.4f rad/s\n', sqrt(mean(w_cur_all(idx_ss).^2)));
        case 4
            fprintf('线速度RMSE: %.4f m/s\n', sqrt(mean((v_ref(idx_ss)-v_cur_all(idx_ss)).^2)));
            fprintf('角速度RMSE: %.4f rad/s\n', sqrt(mean((w_ref(idx_ss)-w_cur_all(idx_ss)).^2)));
            dist_c = abs(sqrt(x.^2+y.^2)-R_c);
            fprintf('轨迹圆度RMSE: %.4f m\n', sqrt(mean(dist_c(idx_ss).^2)));
    end
end
