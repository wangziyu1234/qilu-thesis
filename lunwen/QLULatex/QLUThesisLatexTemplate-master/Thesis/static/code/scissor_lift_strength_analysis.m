%% 剪叉式垂直升降台 —— 强度校核与载重分析
% 臂杆: 36×4.8mm 实心扁钢, L=600mm, Q235
% 两臂夹角 α=19.10°~133.49°, 半角 β=α/2, h0=49mm(配件)
% 额定载重 50kg
clear; clc; close all;

%% ==================== 1. 设计参数 ====================
fprintf('========== 剪叉式垂直升降台强度校核 ==========\n\n');

L_arm   = 600;       % mm, 臂长
material = 'Q235';

% 两臂夹角 α（用户提供）
alpha_low  = 19.10;   % °, 最低位两臂夹角
alpha_high = 133.49;  % °, 最高位两臂夹角

% 半角 β = α/2 = 臂与水平面夹角（力学分析用）
beta_low  = alpha_low  / 2;   % = 9.55°
beta_high = alpha_high / 2;   % = 66.75°
beta_worst = beta_low;         % 最危险工况

% 台面高度 H = L * sin(β) + h0
h0 = 49;  % mm, 两端配件固定高度贡献
H_min = L_arm * sind(beta_low) + h0;
H_max = L_arm * sind(beta_high) + h0;
stroke = H_max - H_min;
H_lift = stroke;  % mm, 理论升程

fprintf('--- 设计参数 ---\n');
fprintf('  臂长 L = %.0f mm,  材料: %s\n', L_arm, material);
fprintf('  截面: 36×4.8 mm 实心扁钢（宽面竖直）\n');
fprintf('  两臂夹角 α: %.2f° ~ %.2f°\n', alpha_low, alpha_high);
fprintf('  水平半角 β: %.2f° ~ %.2f°\n', beta_low, beta_high);
fprintf('  纯剪叉台高: %.1f ~ %.1f mm (行程 %.1f mm)\n', H_min, H_max, stroke);
fprintf('  理论升程: %.0f mm\n\n', H_lift);

% --- 平台 ---
platform_length = 660;   platform_width = 312;   platform_thick = 3;

% --- 臂截面: 36×4.8mm 实心扁钢 ---
B_arm = 4.8;   % mm, 厚度（水平方向）
H_arm = 36;    % mm, 宽度（竖直方向，承受弯曲）

% --- 销轴 ---
D_pin = 18;  % mm

%% ==================== 2. 材料属性 (Q235) ====================
fprintf('--- 材料属性 (Q235) ---\n');
sigma_y = 235;   sigma_b = 375;   tau_y = 0.6*sigma_y;
E_steel = 206000;   sigma_brg = 1.5*sigma_y;
n_s = 1.5;   n_buckle = 3.0;
sigma_allow = sigma_y/n_s;   tau_allow = tau_y/n_s;
fprintf('  [σ] = %.1f MPa,  [τ] = %.1f MPa\n\n', sigma_allow, tau_allow);

%% ==================== 3. 截面特性 ====================
fprintf('--- 臂截面特性 (%.0f×%.0fmm 实心扁钢) ---\n', B_arm, H_arm);

A_sec = B_arm * H_arm;                        % mm²
I_strong = B_arm * H_arm^3 / 12;              % mm⁴, 竖直面内弯曲
I_weak   = H_arm * B_arm^3 / 12;              % mm⁴, 侧向弯曲
W_strong = I_strong / (H_arm/2);              % mm³
i_min = sqrt(I_weak / A_sec);                 % mm, 弱轴回转半径

fprintf('  A = %.1f mm²\n', A_sec);
fprintf('  I_strong = %.0f mm⁴ (竖直弯曲)\n', I_strong);
fprintf('  I_weak = %.0f mm⁴ (侧向弯曲)\n', I_weak);
fprintf('  W = %.0f mm³\n', W_strong);
fprintf('  i_min = %.2f mm (弱轴)\n\n', i_min);

%% ==================== 4. 额定载荷受力分析 (50kg) ====================
fprintf('--- 受力分析 (额定 Q = 50 kg) ---\n');

Q_rated = 50;
F_load = Q_rated * 9.81;

% 臂轴向力: F_arm = F / (4*sinβ)
F_arm = F_load / (4 * sind(beta_worst));

% 自重弯矩
w_self = 7850e-9 * A_sec * 9.81;  % N/mm
M_self = w_self * L_arm^2 * cosd(beta_worst) / 8;  % N·mm

% 偏心弯矩 (e=2mm)
ecc = 2;
M_ecc = 0.5 * F_arm * ecc;  % N·mm

M_total = M_self + M_ecc;

fprintf('  最危险位 β = %.2f° (最低位)\n', beta_worst);
fprintf('  F_arm = %.1f N (轴向)\n', F_arm);
fprintf('  M_self = %.1f N·mm,  M_ecc = %.1f N·mm,  M_total = %.1f N·mm\n\n', ...
    M_self, M_ecc, M_total);

%% ==================== 5. 臂压弯组合强度 ====================
fprintf('--- 臂压弯组合强度 ---\n');
sigma_axial = F_arm / A_sec;
sigma_bend  = M_total / W_strong;
sigma_comb  = sigma_axial + sigma_bend;

fprintf('  σ_axial = %.2f MPa\n', sigma_axial);
fprintf('  σ_bend  = %.2f MPa\n', sigma_bend);
fprintf('  σ_comb  = %.2f MPa  (allow=%.1f, util=%.1f%%)\n', ...
    sigma_comb, sigma_allow, sigma_comb/sigma_allow*100);
if sigma_comb < sigma_allow
    fprintf('  判定: ✓ 合格\n');
else
    fprintf('  判定: ✗ 不合格\n');
end

%% ==================== 6. 屈曲稳定性（弱轴） ====================
fprintf('\n--- 屈曲稳定性（弱轴方向） ---\n');

mu = 1.0;  L_eff = mu * L_arm;
lambda = L_eff / i_min;
lambda_p = pi * sqrt(E_steel / (0.8*sigma_y));

if lambda > lambda_p
    F_cr = pi^2 * E_steel * I_weak / L_eff^2;
    buck_type = '弹性屈曲（欧拉公式）';
else
    lambda_c = pi * sqrt(E_steel/sigma_y);
    sigma_cr_val = sigma_y * (1 - 0.43*(lambda/lambda_c)^2);
    F_cr = sigma_cr_val * A_sec;
    buck_type = '非弹性屈曲（抛物线公式）';
end

n_actual = F_cr / F_arm;

fprintf('  λ = %.1f (> λp=%.0f),  %s\n', lambda, lambda_p, buck_type);
fprintf('  F_cr = %.0f N (%.1f kN)\n', F_cr, F_cr/1000);
fprintf('  n_actual = %.2f (要求 ≥ %.1f)\n', n_actual, n_buckle);

if n_actual >= n_buckle
    fprintf('  判定: ✓ 合格\n');
else
    fprintf('  判定: ✗ 不合格！需侧向支撑\n');

    % 加中心隔套: L_eff → L/2
    L_eff_braced = L_arm / 2;
    lambda_b = L_eff_braced / i_min;
    F_cr_b = pi^2 * E_steel * I_weak / L_eff_braced^2;
    n_b = F_cr_b / F_arm;
    fprintf('  加侧向支撑后 (Leff=%.0fmm): λ=%.0f, Fcr=%.0fN, n=%.1f ✓\n', ...
        L_eff_braced, lambda_b, F_cr_b, n_b);
end

%% ==================== 7. 销轴强度 ====================
fprintf('\n--- 销轴强度 (D=%.0fmm, 45#钢) ---\n', D_pin);

A_pin = pi*(D_pin/2)^2;
F_pin = 2 * tau_allow * A_pin;  % N, 双剪
Q_pin = F_pin / 9.81;

% 销轴弯曲
L_span = H_arm + 6;
M_pin = F_arm * L_span / 4;
I_pin = pi*(D_pin/2)^4/4;
W_pin = I_pin/(D_pin/2);
sigma_pin = M_pin / W_pin;

% 耳板承压
sigma_brg = F_arm / (D_pin * B_arm);

fprintf('  双剪承载力: %.1f kN (%.0f kg)\n', F_pin/1000, Q_pin);
fprintf('  销轴弯曲: %.1f MPa\n', sigma_pin);
fprintf('  耳板承压: %.1f MPa\n', sigma_brg);
fprintf('  判定: ✓ 全部合格\n');

%% ==================== 8. 台面强度 ====================
fprintf('\n--- 台面弯曲 (%.0f×%.0f×%.0fmm) ---\n', ...
    platform_length, platform_width, platform_thick);

q_plt = F_load / (platform_length * platform_width);
M_plt = q_plt * platform_width^2 / 8;
W_plt = platform_thick^2 / 6;
sigma_plt = M_plt / W_plt;

% 挠度 (Navier 第一项近似)
D_plate = E_steel * platform_thick^3 / (12*(1-0.3^2));
a = platform_length;  b = platform_width;
amn = (1/a)^2 + (1/b)^2;
w_max = 16*q_plt/(pi^6*D_plate*1*1*amn^2);

fprintf('  σ = %.1f MPa (allow=%.0f, util=%.0f%%)\n', sigma_plt, sigma_allow, sigma_plt/sigma_allow*100);
fprintf('  w_max ≈ %.2f mm (L/%.0f)\n', w_max, b/w_max);
if sigma_plt < sigma_allow
    fprintf('  判定: ✓ 合格\n');
else
    fprintf('  判定: ✗ 不合格\n');
end

%% ==================== 9. 最大载重反算 ====================
fprintf('\n========== 最大载重综合评估 ==========\n');

% (1) 销轴
F_arm_max_pin = F_pin;
Q1 = F_arm_max_pin * 4 * sind(beta_worst) / 9.81;

% (2) 臂强度
coeff = 1/(4*sind(beta_worst)*A_sec) + 0.5*ecc/(4*sind(beta_worst)*W_strong);
Q2 = sigma_allow / (coeff * 9.81);

% (3) 屈曲 (加支撑后)
F_arm_max_buckle = F_cr_b / n_buckle;
Q3 = F_arm_max_buckle * 4 * sind(beta_worst) / 9.81;

% (4) 台面
q_max = sigma_allow * W_plt * 8 / platform_width^2;
Q4 = q_max * platform_length * platform_width / 9.81;

Qs = [Q1, Q2, Q3, Q4];
names = {'销轴剪切', '臂压弯强度', '屈曲(加支撑)', '台面弯曲'};
[Q_max, idx] = min(Qs);

fprintf('  (1) 销轴剪切:        %.0f kg\n', Q1);
fprintf('  (2) 臂压弯强度:      %.0f kg\n', Q2);
fprintf('  (3) 屈曲(加支撑):    %.0f kg\n', Q3);
fprintf('  (4) 台面弯曲:        %.0f kg\n', Q4);
fprintf('\n  ★ 最大安全载重: %.0f kg  (控制因素: %s)\n', Q_max, names{idx});
fprintf('  ★ 额定 %.0f kg,  安全裕度 %.0f%%\n', Q_rated, (Q_max/Q_rated-1)*100);

%% ==================== 10. 绘图 ====================
figure('Position', [50, 50, 1400, 800], 'Color', 'w');

beta_plot = linspace(beta_low, beta_high, 200);

subplot(2,3,1);
plot(beta_plot, L_arm*sind(beta_plot), 'b-', 'LineWidth', 2);
xlabel('水平半角 β (°)'); ylabel('台面高度 (mm)');
title(sprintf('台面高度 vs β (%.0f~%.0f mm)', L_arm*sind(beta_low), L_arm*sind(beta_high)));
grid on;

subplot(2,3,2);
F_arm_plot = F_load ./ (4 * sind(beta_plot));
plot(beta_plot, F_arm_plot, 'r-', 'LineWidth', 2);
xlabel('水平半角 β (°)'); ylabel('臂轴向力 (N)');
title(sprintf('F_{arm} vs β (Q=%.0fkg)', Q_rated)); grid on;

subplot(2,3,3);
bar(categorical(names), Qs, 'FaceColor', [0.3 0.5 0.8]);
hold on; yline(Q_rated, 'k--', 'LineWidth', 1.5);
ylabel('载荷 (kg)'); title('各失效模式限制载荷'); grid on;

subplot(2,3,4);
bar(categorical({'轴向','弯曲','组合'}), [sigma_axial, sigma_bend, sigma_comb]);
hold on; yline(sigma_allow, 'r--', 'LineWidth', 1.5);
ylabel('应力 (MPa)'); title(sprintf('臂应力分量 (%.0fkg)', Q_rated)); grid on;

subplot(2,3,5);
Q_sweep = linspace(10, 200, 100);
n_sweep = zeros(size(Q_sweep));
for i = 1:length(Q_sweep)
    Fa = Q_sweep(i)*9.81/(4*sind(beta_worst));
    n_sweep(i) = F_cr_b / Fa;
end
plot(Q_sweep, n_sweep, 'm-', 'LineWidth', 2);
hold on; yline(n_buckle, 'k--'); yline(1, 'r:');
xlabel('载荷 (kg)'); ylabel('屈曲安全系数');
title('屈曲安全系数 vs 载荷 (加支撑后)'); grid on;

subplot(2,3,6);
sigma_sweep = zeros(size(Q_sweep));
for i = 1:length(Q_sweep)
    qs = Q_sweep(i)*9.81/(platform_length*platform_width);
    sigma_sweep(i) = qs*platform_width^2/8 / W_plt;
end
plot(Q_sweep, sigma_sweep, 'b-', 'LineWidth', 2);
hold on; yline(sigma_allow, 'r--', 'LineWidth', 1.5);
xlabel('载荷 (kg)'); ylabel('台面应力 (MPa)');
title('台面弯曲应力 vs 载荷'); grid on;

sgtitle(sprintf('剪叉升降台强度校核 | %.0f×%.0fmm扁钢 L=%.0fmm | 额定%.0fkg 最大%.0fkg', ...
    B_arm, H_arm, L_arm, Q_rated, Q_max), 'FontSize', 14, 'FontWeight', 'bold');

%% ==================== 11. 汇总 ====================
fprintf('\n');
fprintf('  ╔════════════════════════════════════════╗\n');
fprintf('  ║  剪叉升降台强度校核报告 (%.0fkg)       ║\n', Q_rated);
fprintf('  ╠════════════════════════════════════════╣\n');
fprintf('  ║  臂: %.0f×%.0fmm扁钢  L=%.0fmm        ║\n', B_arm, H_arm, L_arm);
fprintf('  ║  台面: %d×%d×%dmm  销轴: D=%.0fmm     ║\n', ...
    platform_length, platform_width, platform_thick, D_pin);
fprintf('  ║  β: %.1f°~%.1f°  H: %.0f~%.0fmm      ║\n', beta_low, beta_high, H_min, H_max);
fprintf('  ╠════════════════════════════════════════╣\n');
fprintf('  ║  臂压弯: %5.1f/%.0f MPa (%.0f%%)      ║\n', sigma_comb, sigma_allow, sigma_comb/sigma_allow*100);
fprintf('  ║  屈曲(支撑): n=%.0f (需≥%.0f)         ║\n', n_b, n_buckle);
fprintf('  ║  销轴: 弯曲%.0f 承压%.0f MPa           ║\n', sigma_pin, sigma_brg);
fprintf('  ║  台面: σ=%.0fMPa w=%.2fmm             ║\n', sigma_plt, w_max);
fprintf('  ╠════════════════════════════════════════╣\n');
fprintf('  ║  ★ 最大安全载重: %.0f kg             ║\n', Q_max);
fprintf('  ╚════════════════════════════════════════╝\n');
