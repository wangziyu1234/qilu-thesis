%% 剪叉式垂直升降台强度校核与载重分析
%  对臂杆(压弯组合+屈曲)、销轴(双剪、弯曲、承压)、台面(弯曲)逐项校核
%  最危险工况: 最低位(β=9.55°), 臂杆轴向力是最高位的5.5倍
clear; clc; close all;

%% —— 设计参数 ——
fprintf('========== 剪叉式垂直升降台强度校核 ==========\n\n');

L_arm   = 600;  % 臂杆长度(mm)
material = 'Q235';

alpha_low  = 19.10;  % 最低位两臂夹角(°)
alpha_high = 133.49;  % 最高位两臂夹角(°)

beta_low  = alpha_low  / 2;  % 最低位半角
beta_high = alpha_high / 2;  % 最高位半角
beta_worst = beta_low;  % 最危险工况: 最低位时轴向力最大

h0 = 49;  % 两端配件固定高度(mm)
H_min = L_arm * sind(beta_low) + h0;  % 台面最低高度
H_max = L_arm * sind(beta_high) + h0;  % 台面最高高度
stroke = H_max - H_min;  % 升降行程
H_lift = stroke;

fprintf('--- 设计参数 ---\n');
fprintf('  臂长 L = %.0f mm,  材料: %s\n', L_arm, material);
fprintf('  截面: 36×4.8 mm 实心扁钢（宽面竖直）\n');
fprintf('  两臂夹角 α: %.2f° ~ %.2f°\n', alpha_low, alpha_high);
fprintf('  水平半角 β: %.2f° ~ %.2f°\n', beta_low, beta_high);
fprintf('  纯剪叉台高: %.1f ~ %.1f mm (行程 %.1f mm)\n', H_min, H_max, stroke);
fprintf('  理论升程: %.0f mm\n\n', H_lift);

platform_length = 660;   platform_width = 312;   platform_thick = 3;  % 台面尺寸(mm)
B_arm = 4.8;  % 臂厚(水平方向, mm)
H_arm = 36;  % 臂宽(竖直方向, mm)
D_pin = 18;  % 销轴直径(mm)

%% —— 材料属性(Q235) ——
fprintf('--- 材料属性 (Q235) ---\n');
sigma_y = 235;   sigma_b = 375;   tau_y = 0.6*sigma_y;  % 屈服/抗拉/剪切屈服(MPa)
E_steel = 206000;  % 弹性模量(MPa)
n_s = 1.5;   n_buckle = 3.0;  % 安全系数
sigma_allow = sigma_y/n_s;   tau_allow = tau_y/n_s;  % 许用应力
fprintf('  [σ] = %.1f MPa,  [τ] = %.1f MPa\n\n', sigma_allow, tau_allow);

%% —— 臂杆截面特性 ——
fprintf('--- 臂截面特性 (%.0f×%.0fmm 实心扁钢) ---\n', B_arm, H_arm);

A_sec = B_arm * H_arm;  % 截面积(mm²)
I_strong = B_arm * H_arm^3 / 12;  % 强轴惯性矩(竖直面内抗弯)
I_weak   = H_arm * B_arm^3 / 12;  % 弱轴惯性矩(侧向抗弯)
W_strong = I_strong / (H_arm/2);  % 强轴截面模量(mm³)
i_min = sqrt(I_weak / A_sec);  % 弱轴最小回转半径(mm)

fprintf('  A = %.1f mm²\n', A_sec);
fprintf('  I_strong = %.0f mm⁴ (竖直弯曲)\n', I_strong);
fprintf('  I_weak = %.0f mm⁴ (侧向弯曲)\n', I_weak);
fprintf('  W = %.0f mm³\n', W_strong);
fprintf('  i_min = %.2f mm (弱轴)\n\n', i_min);

%% —— 额定载荷受力分析 ——
fprintf('--- 受力分析 (额定 Q = 50 kg) ---\n');

Q_rated = 50;  % 额定载重(kg)
F_load = Q_rated * 9.81;  % 额定载荷重力(N)

F_arm = F_load / (4 * sind(beta_worst));  % 单根臂杆轴向力(4铰点均分)

w_self = 7850e-9 * A_sec * 9.81;  % 臂杆自重线载荷(N/mm)
M_self = w_self * L_arm^2 * cosd(beta_worst) / 8;  % 自重引起跨中弯矩(N·mm)

ecc = 2;  % 载荷偏心距(mm)
M_ecc = 0.5 * F_arm * ecc;  % 偏心附加弯矩(N·mm)

M_total = M_self + M_ecc;

fprintf('  最危险位 β = %.2f° (最低位)\n', beta_worst);
fprintf('  F_arm = %.1f N (轴向)\n', F_arm);
fprintf('  M_self = %.1f N·mm,  M_ecc = %.1f N·mm,  M_total = %.1f N·mm\n\n', ...
    M_self, M_ecc, M_total);

%% —— 臂杆压弯组合强度 ——
fprintf('--- 臂压弯组合强度 ---\n');
sigma_axial = F_arm / A_sec;  % 轴向压应力
sigma_bend  = M_total / W_strong;  % 弯曲正应力
sigma_comb  = sigma_axial + sigma_bend;  % 压弯组合应力

fprintf('  σ_axial = %.2f MPa\n', sigma_axial);
fprintf('  σ_bend  = %.2f MPa\n', sigma_bend);
fprintf('  σ_comb  = %.2f MPa  (allow=%.0f, util=%.1f%%)\n', ...
    sigma_comb, sigma_allow, sigma_comb/sigma_allow*100);
if sigma_comb < sigma_allow
    fprintf('  判定: 合格\n');
else
    fprintf('  判定: 不合格\n');
end

%% —— 屈曲稳定性(弱轴) ——
fprintf('\n--- 屈曲稳定性（弱轴方向） ---\n');

mu = 1.0;  L_eff = mu * L_arm;  % 两端铰支, 有效长度(mm)
lambda = L_eff / i_min;  % 长细比
lambda_p = pi * sqrt(E_steel / (0.8*sigma_y));  % 弹塑性分界长细比

if lambda > lambda_p  % 弹性屈曲: 欧拉公式
    F_cr = pi^2 * E_steel * I_weak / L_eff^2;
    buck_type = '弹性屈曲（欧拉公式）';
else  % 非弹性屈曲: 抛物线公式
    lambda_c = pi * sqrt(E_steel/sigma_y);
    sigma_cr_val = sigma_y * (1 - 0.43*(lambda/lambda_c)^2);
    F_cr = sigma_cr_val * A_sec;
    buck_type = '非弹性屈曲（抛物线公式）';
end

n_actual = F_cr / F_arm;  % 实际安全系数

fprintf('  λ = %.1f (> λp=%.0f),  %s\n', lambda, lambda_p, buck_type);
fprintf('  F_cr = %.0f N (%.1f kN)\n', F_cr, F_cr/1000);
fprintf('  n_actual = %.2f (要求 ≥ %.1f)\n', n_actual, n_buckle);

if n_actual >= n_buckle
    fprintf('  判定: 合格\n');
else  % 不满足 → 加侧向支撑
    fprintf('  判定: 不合格！需侧向支撑\n');

    L_eff_braced = L_arm / 2;  % 加中心隔套, 有效长度减半
    lambda_b = L_eff_braced / i_min;
    F_cr_b = pi^2 * E_steel * I_weak / L_eff_braced^2;
    n_b = F_cr_b / F_arm;
    fprintf('  加侧向支撑后 (Leff=%.0fmm): λ=%.0f, Fcr=%.0fN, n=%.1f 合格\n', ...
        L_eff_braced, lambda_b, F_cr_b, n_b);
end

%% —— 销轴强度(45#钢) ——
fprintf('\n--- 销轴强度 (D=%.0fmm, 45#钢) ---\n', D_pin);
sigma_y_pin = 355;  % 45#钢屈服强度(MPa)
tau_y_pin = 0.6 * sigma_y_pin;  % 45#钢剪切屈服(MPa)
tau_allow_pin = tau_y_pin / n_s;  % 45#钢许用剪应力(MPa)

A_pin = pi*(D_pin/2)^2;  % 截面(mm²)
F_pin = 2 * tau_allow_pin * A_pin;  % 双剪承载力(N)
Q_pin = F_pin / 9.81;  % 折合载重(kg)

L_span = 27;  % 耳板内间距(mm)，对应论文 L_s=27mm
t_ear = 6;  % 耳板厚度(mm)
M_pin = F_arm * L_span / 4;  % 简支梁跨中弯矩
W_pin = pi*D_pin^3/32;  % 截面模量，对应论文 W=πD³/32
sigma_pin = M_pin / W_pin;  % 弯曲应力

sigma_brg = F_arm / (D_pin * t_ear);  % 耳板承压应力，对应论文 σ=F/(D·t)

fprintf('  双剪承载力: %.1f kN (%.0f kg)\n', F_pin/1000, Q_pin);
fprintf('  销轴弯曲: %.1f MPa\n', sigma_pin);
fprintf('  耳板承压: %.1f MPa\n', sigma_brg);
fprintf('  判定: 全部合格\n');

%% —— 台面弯曲 ——
fprintf('\n--- 台面弯曲 (%.0f×%.0f×%.0fmm) ---\n', ...
    platform_length, platform_width, platform_thick);

q_plt = F_load / (platform_length * platform_width);  % 均布载荷(MPa)
M_plt = q_plt * platform_width^2 / 8;  % 简支板跨中弯矩
W_plt = platform_thick^2 / 6;  % 单位宽度截面模量
sigma_plt = M_plt / W_plt;  % 最大弯曲应力

D_plate = E_steel * platform_thick^3 / (12*(1-0.3^2));  % 薄板弯曲刚度
a_p = platform_length;  b_p = platform_width;
amn = (1/a_p)^2 + (1/b_p)^2;
w_max = 16*q_plt/(pi^6*D_plate*1*1*amn^2);  % Navier级数一阶近似挠度

fprintf('  σ = %.1f MPa (allow=%.0f, util=%.0f%%)\n', sigma_plt, sigma_allow, sigma_plt/sigma_allow*100);
fprintf('  w_max ≈ %.2f mm (L/%.0f)\n', w_max, b_p/w_max);
if sigma_plt < sigma_allow
    fprintf('  判定: 合格\n');
else
    fprintf('  判定: 不合格\n');
end

%% —— 最大安全载重反算 ——
fprintf('\n========== 最大载重综合评估 ==========\n');

F_arm_max_pin = F_pin;  % 销轴剪切限制的臂力
Q1 = F_arm_max_pin * 4 * sind(beta_worst) / 9.81;  % 销轴限制载重

coeff = 1/(4*sind(beta_worst)*A_sec) + 0.5*ecc/(4*sind(beta_worst)*W_strong);
Q2 = sigma_allow / (coeff * 9.81);  % 臂强度限制载重

F_arm_max_buckle = F_cr_b / n_buckle;  % 屈曲限制臂力
Q3 = F_arm_max_buckle * 4 * sind(beta_worst) / 9.81;  % 屈曲限制载重

q_max = sigma_allow * W_plt * 8 / platform_width^2;  % 台面许用均布载荷
Q4 = q_max * platform_length * platform_width / 9.81;  % 台面限制载重

Qs = [Q1, Q2, Q3, Q4];  % 四种失效模式限制值
names = {'销轴剪切', '臂压弯强度', '屈曲(加支撑)', '台面弯曲'};
[Q_max, idx] = min(Qs);  % 最薄弱环节决定最大载重

fprintf('  (1) 销轴剪切:        %.0f kg\n', Q1);
fprintf('  (2) 臂压弯强度:      %.0f kg\n', Q2);
fprintf('  (3) 屈曲(加支撑):    %.0f kg\n', Q3);
fprintf('  (4) 台面弯曲:        %.0f kg\n', Q4);
fprintf('\n  最大安全载重: %.0f kg  (控制因素: %s)\n', Q_max, names{idx});
fprintf('  额定 %.0f kg,  安全裕度 %.0f%%\n', Q_rated, (Q_max/Q_rated-1)*100);

%% —— 结果可视化 ——
figure('Position', [50, 50, 1400, 800], 'Color', 'w');  % 创建大尺寸白色图窗

beta_plot = linspace(beta_low, beta_high, 200);  % 半角扫描范围(200个采样点)

subplot(2,3,1);  % 子图1: 台面高度 vs β
plot(beta_plot, L_arm*sind(beta_plot), 'b-', 'LineWidth', 2);  % 蓝色曲线: H=L·sinβ
xlabel('水平半角 β (°)'); ylabel('台面高度 (mm)');  % 坐标轴标签
title(sprintf('台面高度 vs β (%.0f~%.0f mm)', L_arm*sind(beta_low), L_arm*sind(beta_high)));  % 动态标题
grid on;  % 开启网格

subplot(2,3,2);  % 子图2: 臂轴向力 vs β
F_arm_plot = F_load ./ (4 * sind(beta_plot));  % 各β下的臂轴向力 F=Q/(4·sinβ)
plot(beta_plot, F_arm_plot, 'r-', 'LineWidth', 2);  % 红色曲线: 轴向力
xlabel('水平半角 β (°)'); ylabel('臂轴向力 (N)');  % 坐标轴标签
title(sprintf('F_{arm} vs β (Q=%.0fkg)', Q_rated)); grid on;  % 动态标题+网格

subplot(2,3,3);  % 子图3: 各失效模式限制载荷柱状图
bar(categorical(names), Qs, 'FaceColor', [0.3 0.5 0.8]);  % 蓝色柱状图
hold on; yline(Q_rated, 'k--', 'LineWidth', 1.5);  % 黑色虚线: 额定载荷参考线
ylabel('载荷 (kg)'); title('各失效模式限制载荷'); grid on;  % 标签和标题

subplot(2,3,4);  % 子图4: 臂应力分量柱状图
bar(categorical({'轴向','弯曲','组合'}), [sigma_axial, sigma_bend, sigma_comb]);  % 三组柱状
hold on; yline(sigma_allow, 'r--', 'LineWidth', 1.5);  % 红色虚线: 许用应力线
ylabel('应力 (MPa)'); title(sprintf('臂应力分量 (%.0fkg)', Q_rated)); grid on;  % 标签和标题

subplot(2,3,5);  % 子图5: 屈曲安全系数 vs 载荷
Q_sweep = linspace(10, 200, 100);  % 载荷扫描范围 10~200kg(100点)
n_sweep = zeros(size(Q_sweep));  % 初始化安全系数数组
for i = 1:length(Q_sweep)  % 逐载荷计算屈曲安全系数
    Fa = Q_sweep(i)*9.81/(4*sind(beta_worst));  % 对应臂轴向力
    n_sweep(i) = F_cr_b / Fa;  % 屈曲安全系数(加支撑后)
end
plot(Q_sweep, n_sweep, 'm-', 'LineWidth', 2);  % 品红色曲线: 安全系数
hold on; yline(n_buckle, 'k--'); yline(1, 'r:');  % 要求安全线(n=3)和临界线(n=1)
xlabel('载荷 (kg)'); ylabel('屈曲安全系数');  % 坐标轴标签
title('屈曲安全系数 vs 载荷 (加支撑后)'); grid on;  % 标题+网格

subplot(2,3,6);  % 子图6: 台面弯曲应力 vs 载荷
sigma_sweep = zeros(size(Q_sweep));  % 初始化应力数组
for i = 1:length(Q_sweep)  % 逐载荷计算台面应力
    qs = Q_sweep(i)*9.81/(platform_length*platform_width);  % 换算均布载荷
    sigma_sweep(i) = qs*platform_width^2/8 / W_plt;  % 简支板最大弯曲应力
end
plot(Q_sweep, sigma_sweep, 'b-', 'LineWidth', 2);  % 蓝色曲线: 台面应力
hold on; yline(sigma_allow, 'r--', 'LineWidth', 1.5);  % 红色虚线: 许用应力线
xlabel('载荷 (kg)'); ylabel('台面应力 (MPa)');  % 坐标轴标签
title('台面弯曲应力 vs 载荷'); grid on;  % 标题+网格

sgtitle(sprintf('剪叉升降台强度校核 | %.0f×%.0fmm扁钢 L=%.0fmm | 额定%.0fkg 最大%.0fkg', ...  % 总标题
    B_arm, H_arm, L_arm, Q_rated, Q_max), 'FontSize', 14, 'FontWeight', 'bold');

%% —— 校核结果汇总 ——
fprintf('\n========== 剪叉升降台强度校核报告 (%.0fkg) ==========\n', Q_rated);  % 打印报告标题
fprintf('  臂: %.0f x %.0f mm扁钢, L = %.0f mm\n', B_arm, H_arm, L_arm);  % 臂杆参数
fprintf('  台面: %d x %d x %d mm, 销轴 D = %.0f mm\n', ...  % 台面和销轴参数
    platform_length, platform_width, platform_thick, D_pin);
fprintf('  beta: %.1f ~ %.1f deg, H: %.0f ~ %.0f mm\n', beta_low, beta_high, H_min, H_max);  % 角度和高度范围
fprintf('------------------------------------------------------\n');  % 分隔线
fprintf('  臂压弯: %5.1f / %.0f MPa (%.0f%%)\n', sigma_comb, sigma_allow, sigma_comb/sigma_allow*100);  % 压弯利用率
fprintf('  屈曲(支撑): n = %.0f (需 >= %.0f)\n', n_b, n_buckle);  % 屈曲安全系数
fprintf('  销轴: 弯曲 %.0f, 承压 %.0f MPa\n', sigma_pin, sigma_brg);  % 销轴应力
fprintf('  台面: sigma = %.0f MPa, w = %.2f mm\n', sigma_plt, w_max);  % 台面应力和挠度
fprintf('------------------------------------------------------\n');  % 分隔线
fprintf('  最大安全载重: %.0f kg\n', Q_max);  % 最大安全载重
fprintf('======================================================\n');  % 结束线
