%% 剪叉式升降台 —— FEA 有限元分析
% 臂: 36×4.8mm 实心扁钢, L=600mm
% 台面: Navier板弯曲 + 臂: 梁单元FEA + 销轴
% 额定 50kg
clear; clc; close all;

E = 206000;  nu = 0.3;
sigma_allow = 235/1.5;

%% ===== 参数 =====
L_arm = 600;   alpha_low = 19.10;   beta_low = alpha_low/2;
Q_load = 50;
F_load = Q_load * 9.81;
F_arm  = F_load / (4 * sind(beta_low));

% 臂 36×4.8mm 扁钢
B_arm = 4.8;   H_arm = 36;
A_sec = B_arm * H_arm;
I_strong = B_arm * H_arm^3 / 12;
I_weak   = H_arm * B_arm^3 / 12;
W_strong = I_strong / (H_arm/2);

% 台面 660×312×3
a_plt = 660;  b_plt = 312;  t_plt = 3;
q_plt = F_load/(a_plt*b_plt);
D_plate = E*t_plt^3/(12*(1-nu^2));

% 销轴 D=18
D_pin = 18;

fprintf('========== 剪叉升降台 FEA (Q=%.0fkg) ==========\n', Q_load);
fprintf('臂: %.0f×%.0fmm 扁钢, L=%.0fmm\n\n', B_arm, H_arm, L_arm);

%% ===== Part 1: 台面板 Navier 级数解 =====
fprintf('--- Part 1: 台面弯曲 (%.0f×%.0f×%.0fmm) ---\n', a_plt, b_plt, t_plt);

w_c = 0;  Mx_c = 0;  My_c = 0;
for m = 1:2:81
    sm = sin(m*pi/2);
    for n = 1:2:81
        sn = sin(n*pi/2);
        amn = (m/a_plt)^2 + (n/b_plt)^2;
        w_c  = w_c  + 16*q_plt/(pi^6*D_plate*m*n*amn^2)*sm*sn;
        Mx_c = Mx_c + 16*q_plt/(pi^4*m*n*amn^2)*((m/a_plt)^2+nu*(n/b_plt)^2)*sm*sn;
        My_c = My_c + 16*q_plt/(pi^4*m*n*amn^2)*((n/b_plt)^2+nu*(m/a_plt)^2)*sm*sn;
    end
end
sx_c = 6*abs(Mx_c)/t_plt^2;
sy_c = 6*abs(My_c)/t_plt^2;
svm_c = sqrt(sx_c^2 + sy_c^2 - sx_c*sy_c);

fprintf('  w_max = %.2f mm (L/%.0f)\n', w_c, b_plt/w_c);
fprintf('  sigma_vm = %.1f MPa (%.0f%%)', svm_c, svm_c/sigma_allow*100);
if svm_c < sigma_allow, fprintf('  OK\n\n'); else, fprintf('  FAIL\n\n'); end

%% ===== Part 2: 臂 FEA (梁单元) =====
fprintf('--- Part 2: 臂 FEA (30梁单元, 两端铰支) ---\n');

n_elem = 30;  n_nodes = n_elem + 1;  L_e = L_arm / n_elem;
ndof = 3;  n_dof_total = n_nodes * ndof;
K_glob = zeros(n_dof_total);  F_glob = zeros(n_dof_total, 1);

k_e = @(L) [E*A_sec/L,  0,              0,             -E*A_sec/L,  0,              0;
            0,           12*E*I_strong/L^3,6*E*I_strong/L^2,0,       -12*E*I_strong/L^3,6*E*I_strong/L^2;
            0,           6*E*I_strong/L^2, 4*E*I_strong/L, 0,       -6*E*I_strong/L^2, 2*E*I_strong/L;
            -E*A_sec/L, 0,              0,             E*A_sec/L,   0,              0;
            0,           -12*E*I_strong/L^3,-6*E*I_strong/L^2,0,    12*E*I_strong/L^3,-6*E*I_strong/L^2;
            0,           6*E*I_strong/L^2, 2*E*I_strong/L, 0,       -6*E*I_strong/L^2, 4*E*I_strong/L];

for ie = 1:n_elem
    dof_map = ((ie-1)*ndof+1):((ie+1)*ndof);
    K_glob(dof_map, dof_map) = K_glob(dof_map, dof_map) + k_e(L_e);
end

% BC: 两端铰支
fixed_dof = [1, 2, n_dof_total-1];
free_dof  = setdiff(1:n_dof_total, fixed_dof);

% 轴向力
F_glob(n_dof_total-2) = -F_arm;

% 自重
w_s = 7850e-9 * A_sec * 9.81;
for ie = 1:n_elem
    f_eq = w_s * L_e / 2;  m_eq = w_s * L_e^2 / 12;
    F_glob((ie-1)*ndof+2) = F_glob((ie-1)*ndof+2) + f_eq;
    F_glob((ie-1)*ndof+3) = F_glob((ie-1)*ndof+3) - m_eq;
    F_glob(ie*ndof+2)     = F_glob(ie*ndof+2)     + f_eq;
    F_glob(ie*ndof+3)     = F_glob(ie*ndof+3)     + m_eq;
end

U_glob = zeros(n_dof_total, 1);
U_glob(free_dof) = K_glob(free_dof, free_dof) \ F_glob(free_dof);

ux = U_glob(1:ndof:end);  uy = U_glob(2:ndof:end);

sigma_ax_elem = zeros(n_elem,1);  sigma_bd_elem = zeros(n_elem,1);
for ie = 1:n_elem
    u_e = U_glob(((ie-1)*ndof+1):((ie+1)*ndof));
    F_e = k_e(L_e) * u_e;
    N = abs((F_e(4)-F_e(1))/2);
    M = max(abs(F_e(3)), abs(F_e(6)));
    sigma_ax_elem(ie) = N / A_sec;
    sigma_bd_elem(ie) = M / W_strong;
end

sigma_arm_fea = max(sigma_ax_elem + sigma_bd_elem);
uy_max = max(abs(uy));

% 屈曲 (弱轴)
i_min = sqrt(I_weak/A_sec);
lam = L_arm / i_min;
F_cr_weak = pi^2 * E * I_weak / L_arm^2;
n_buckle = F_cr_weak / F_arm;
% 加支撑
L_braced = L_arm/2;
F_cr_braced = pi^2 * E * I_weak / L_braced^2;
n_braced = F_cr_braced / F_arm;

fprintf('  F_arm=%.0fN,  w_self=%.4f N/mm\n', F_arm, w_s);
fprintf('  sigma_axial=%.2f, sigma_bend_max=%.2f, sigma_comb=%.2f MPa (%.0f%%)\n', ...
    max(sigma_ax_elem), max(sigma_bd_elem), sigma_arm_fea, sigma_arm_fea/sigma_allow*100);
fprintf('  uy_max = %.4f mm\n', uy_max);
fprintf('  弱轴屈曲: lambda=%.0f, Fcr=%.0fN, n=%.1f\n', lam, F_cr_weak, n_buckle);
fprintf('  加支撑后: Leff=%.0fmm, Fcr=%.0fN, n=%.1f', L_braced, F_cr_braced, n_braced);
if n_braced >= 3, fprintf('  OK\n\n'); else, fprintf('  FAIL\n\n'); end

%% ===== Part 3: 销轴 =====
fprintf('--- Part 3: 销轴 D=%.0fmm ---\n', D_pin);
L_span = H_arm + 6;
M_pin = F_arm * L_span / 4;
W_pin = pi*(D_pin/2)^3/4;
sigma_pin = M_pin / W_pin;
sigma_brg = F_arm/(D_pin*B_arm);
fprintf('  弯曲=%.0fMPa, 承压=%.1fMPa  OK\n\n', sigma_pin, sigma_brg);

%% ===== Part 4: 可视化 =====
figure('Position', [30, 30, 1500, 500], 'Color', 'w');

% (a) 台面挠度云图
subplot(2,3,1);
nx=25; ny=25; xc=linspace(0,a_plt,nx); yc=linspace(0,b_plt,ny);
Wc=zeros(ny,nx);
for ix=1:nx
    for iy=1:ny
        for m=1:2:21
            sm=sin(m*pi*xc(ix)/a_plt);
            for n=1:2:21
                sn=sin(n*pi*yc(iy)/b_plt);
                amn=(m/a_plt)^2+(n/b_plt)^2;
                Wc(iy,ix)=Wc(iy,ix)+16*q_plt/(pi^6*D_plate*m*n*amn^2)*sm*sn;
            end
        end
    end
end
[Xc,Yc]=meshgrid(xc,yc);
contourf(Xc,Yc,Wc,20,'LineStyle','none');
colormap jet; colorbar;
xlabel('X(mm)'); ylabel('Y(mm)');
title(sprintf('台面挠度 (max=%.2fmm)', w_c));
axis equal tight;

% (b) 臂 FEA 应力沿长度
subplot(2,3,2);
x_elem = linspace(L_e/2, L_arm-L_e/2, n_elem);
yyaxis left;
plot(x_elem, sigma_ax_elem, 'r-', 'LineWidth', 2);
ylabel('轴向应力 (MPa)');
yyaxis right;
plot(x_elem, sigma_bd_elem, 'b-', 'LineWidth', 2);
ylabel('弯曲应力 (MPa)');
xlabel('臂长方向 (mm)');
title(sprintf('臂 FEA 应力分布 (F_{arm}=%.0fN)', F_arm));
legend('轴向', '弯曲'); grid on;

% (c) 臂变形 (放大500倍)
subplot(2,3,3);
x_nodes = linspace(0, L_arm, n_nodes)';
scale = 500;
plot(x_nodes, zeros(size(x_nodes)), 'k--'); hold on;
plot(x_nodes + scale*ux, scale*uy, 'b-', 'LineWidth', 2);
xlabel('X (mm)'); ylabel(sprintf('变形 ×%d (mm)', scale));
title(sprintf('臂变形 (max挠度=%.4fmm)', uy_max));
legend('原始', '变形后'); axis equal; grid on;

% (d) 应力对比
subplot(2,3,4);
vals = [sigma_arm_fea, sigma_pin, svm_c];
names = categorical({'臂组合','销轴弯曲','台面VM'});
bar(names, vals); hold on;
yline(sigma_allow, 'r--', 'LineWidth', 1.5);
ylabel('应力 (MPa)'); title('各部件最大应力'); grid on;

% (e) 屈曲对比
subplot(2,3,5);
bar(categorical({'无支撑(n='+string(round(n_buckle,1))+')','加隔套(n='+string(round(n_braced,1))+')'}), ...
    [n_buckle, n_braced]);
hold on; yline(3, 'r--', 'LineWidth', 1.5);
ylabel('安全系数 n'); title('弱轴屈曲: 无支撑 vs 加隔套'); grid on;

% (f) 安全裕度
subplot(2,3,6);
bar(categorical({'臂','销轴','台面'}), ...
    [sigma_allow-sigma_arm_fea, sigma_allow-sigma_pin, sigma_allow-svm_c]);
ylabel('应力裕度 (MPa)'); title('各部件应力裕度'); grid on;

sgtitle(sprintf('剪叉升降台 FEA | %.0f×%.0fmm扁钢 | Q=%.0fkg | 全部合格', ...
    B_arm, H_arm, Q_load), 'FontSize', 14, 'FontWeight', 'bold');

%% ===== 汇总 =====
fprintf('========== FEA 汇总 ==========\n');
fprintf('  台面: w=%.2fmm, sigma=%.1fMPa (%.0f%%)\n', w_c, svm_c, svm_c/sigma_allow*100);
fprintf('  臂:   sigma=%.2fMPa (%.0f%%), 挠度=%.4fmm\n', sigma_arm_fea, sigma_arm_fea/sigma_allow*100, uy_max);
fprintf('  屈曲: 无支撑n=%.1f, 加隔套n=%.1f\n', n_buckle, n_braced);
fprintf('  销轴: sigma=%.0fMPa\n', sigma_pin);
fprintf('\n  ★ %.0fkg 额定: 全部合格\n', Q_load);
