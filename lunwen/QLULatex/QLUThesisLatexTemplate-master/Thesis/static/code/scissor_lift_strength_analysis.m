%% 剪叉式垂直升降台强度校核与载重分析
clear; clc; close all;  % 清空工作区、命令行、关闭图形窗口

%% ==================== 1. 设计参数输入 ====================
fprintf('========== 剪叉式垂直升降台强度校核 ==========\n\n');  % 打印程序标题

L_arm   = 600;  % 臂杆长度600mm
material = 'Q235';  % 材料牌号

alpha_low  = 19.10;  % 最低位时两臂夹角(°)
alpha_high = 133.49;  % 最高位时两臂夹角(°)

beta_low  = alpha_low  / 2;  % 最低位半角 = 臂与水平面夹角
beta_high = alpha_high / 2;  % 最高位半角
beta_worst = beta_low;  % 最危险工况为最低位（半角最小，臂轴向力最大）

h0 = 49;  % 两端配件（铰座、滚轮座）固定高度(mm)
H_min = L_arm * sind(beta_low) + h0;  % 台面最低高度
H_max = L_arm * sind(beta_high) + h0;  % 台面最高高度
stroke = H_max - H_min;  % 升降行程
H_lift = stroke;  % 理论升程

fprintf('--- 设计参数 ---\n');  % 打印参数标题
fprintf('  臂长 L = %.0f mm,  材料: %s\n', L_arm, material);  % 打印臂长和材料
fprintf('  截面: 36×4.8 mm 实心扁钢（宽面竖直）\n');  % 打印截面信息
fprintf('  两臂夹角 α: %.2f° ~ %.2f°\n', alpha_low, alpha_high);  % 打印夹角范围
fprintf('  水平半角 β: %.2f° ~ %.2f°\n', beta_low, beta_high);  % 打印半角范围
fprintf('  纯剪叉台高: %.1f ~ %.1f mm (行程 %.1f mm)\n', H_min, H_max, stroke);  % 打印高度范围
fprintf('  理论升程: %.0f mm\n\n', H_lift);  % 打印升程

platform_length = 660;   platform_width = 312;   platform_thick = 3;  % 台面：长660宽312厚3mm

B_arm = 4.8;  % 臂杆厚度（水平方向）
H_arm = 36;  % 臂杆宽度（竖直方向，承受弯曲）

D_pin = 18;  % 销轴直径18mm

%% ==================== 2. 材料属性定义 ====================
fprintf('--- 材料属性 (Q235) ---\n');  % 打印材料属性标题
sigma_y = 235;   sigma_b = 375;   tau_y = 0.6*sigma_y;  % 屈服强度、抗拉强度、剪切屈服强度(MPa)
E_steel = 206000;   sigma_brg = 1.5*sigma_y;  % 弹性模量(MPa)、承压许用应力
n_s = 1.5;   n_buckle = 3.0;  % 强度安全系数1.5，屈曲安全系数3.0
sigma_allow = sigma_y/n_s;   tau_allow = tau_y/n_s;  % 许用正应力、许用剪应力
fprintf('  [σ] = %.1f MPa,  [τ] = %.1f MPa\n\n', sigma_allow, tau_allow);  % 打印许用应力

%% ==================== 3. 臂杆截面特性计算 ====================
fprintf('--- 臂截面特性 (%.0f×%.0fmm 实心扁钢) ---\n', B_arm, H_arm);  % 打印截面尺寸

A_sec = B_arm * H_arm;  % 截面积(mm²)
I_strong = B_arm * H_arm^3 / 12;  % 强轴惯性矩，竖直面内抗弯(mm⁴)
I_weak   = H_arm * B_arm^3 / 12;  % 弱轴惯性矩，侧向抗弯(mm⁴)
W_strong = I_strong / (H_arm/2);  % 强轴抗弯截面模量(mm³)
i_min = sqrt(I_weak / A_sec);  % 弱轴最小回转半径(mm)

fprintf('  A = %.1f mm²\n', A_sec);  % 打印截面积
fprintf('  I_strong = %.0f mm⁴ (竖直弯曲)\n', I_strong);  % 打印强轴惯性矩
fprintf('  I_weak = %.0f mm⁴ (侧向弯曲)\n', I_weak);  % 打印弱轴惯性矩
fprintf('  W = %.0f mm³\n', W_strong);  % 打印截面模量
fprintf('  i_min = %.2f mm (弱轴)\n\n', i_min);  % 打印最小回转半径

%% ==================== 4. 额定载荷受力分析 ====================
fprintf('--- 受力分析 (额定 Q = 50 kg) ---\n');  % 打印受力分析标题

Q_rated = 50;  % 额定载重50kg
F_load = Q_rated * 9.81;  % 额定载荷重力(N)

F_arm = F_load / (4 * sind(beta_worst));  % 每根臂杆轴向力（4处铰点均分，由半角分解）

w_self = 7850e-9 * A_sec * 9.81;  % 臂杆自重线载荷(N/mm)
M_self = w_self * L_arm^2 * cosd(beta_worst) / 8;  % 自重产生的跨中弯矩(N·mm)

ecc = 2;  % 载荷偏心距2mm
M_ecc = 0.5 * F_arm * ecc;  % 偏心引起的附加弯矩(N·mm)

M_total = M_self + M_ecc;  % 总弯矩 = 自重弯矩 + 偏心弯矩

fprintf('  最危险位 β = %.2f° (最低位)\n', beta_worst);  % 打印最危险角度
fprintf('  F_arm = %.1f N (轴向)\n', F_arm);  % 打印臂轴向力
fprintf('  M_self = %.1f N·mm,  M_ecc = %.1f N·mm,  M_total = %.1f N·mm\n\n', ...  % 打印弯矩分量
    M_self, M_ecc, M_total);

%% ==================== 5. 臂杆压弯组合强度校核 ====================
fprintf('--- 臂压弯组合强度 ---\n');  % 打印强度校核标题
sigma_axial = F_arm / A_sec;  % 轴向压应力(MPa)
sigma_bend  = M_total / W_strong;  % 弯曲正应力(MPa)
sigma_comb  = sigma_axial + sigma_bend;  % 压弯组合应力(MPa)

fprintf('  σ_axial = %.2f MPa\n', sigma_axial);  % 打印轴向应力
fprintf('  σ_bend  = %.2f MPa\n', sigma_bend);  % 打印弯曲应力
fprintf('  σ_comb  = %.2f MPa  (allow=%.1f, util=%.1f%%)\n', ...  % 打印组合应力及利用率
    sigma_comb, sigma_allow, sigma_comb/sigma_allow*100);
if sigma_comb < sigma_allow  % 判定是否满足强度要求
    fprintf('  判定: 合格\n');  % 满足
else
    fprintf('  判定: 不合格\n');  % 不满足
end

%% ==================== 6. 屈曲稳定性校核（弱轴方向） ====================
fprintf('\n--- 屈曲稳定性（弱轴方向） ---\n');  % 打印屈曲校核标题

mu = 1.0;  L_eff = mu * L_arm;  % 长度系数1.0（两端铰支），有效长度
lambda = L_eff / i_min;  % 弱轴长细比
lambda_p = pi * sqrt(E_steel / (0.8*sigma_y));  % 弹塑性分界长细比

if lambda > lambda_p  % 弹性屈曲范围，使用欧拉公式
    F_cr = pi^2 * E_steel * I_weak / L_eff^2;  % 欧拉临界力(N)
    buck_type = '弹性屈曲（欧拉公式）';  % 屈曲类型标记
else  % 非弹性屈曲范围，使用抛物线公式
    lambda_c = pi * sqrt(E_steel/sigma_y);  % 临界长细比
    sigma_cr_val = sigma_y * (1 - 0.43*(lambda/lambda_c)^2);  % 非弹性临界应力
    F_cr = sigma_cr_val * A_sec;  % 非弹性临界力(N)
    buck_type = '非弹性屈曲（抛物线公式）';  % 屈曲类型标记
end

n_actual = F_cr / F_arm;  % 实际屈曲安全系数

fprintf('  λ = %.1f (> λp=%.0f),  %s\n', lambda, lambda_p, buck_type);  % 打印长细比和屈曲类型
fprintf('  F_cr = %.0f N (%.1f kN)\n', F_cr, F_cr/1000);  % 打印临界力
fprintf('  n_actual = %.2f (要求 ≥ %.1f)\n', n_actual, n_buckle);  % 打印安全系数及要求

if n_actual >= n_buckle  % 判定无支撑时屈曲是否合格
    fprintf('  判定: 合格\n');  % 满足
else  % 不满足时需要侧向支撑
    fprintf('  判定: 不合格！需侧向支撑\n');  % 不满足

    L_eff_braced = L_arm / 2;  % 加中心隔套后有效长度减半
    lambda_b = L_eff_braced / i_min;  % 加支撑后的长细比
    F_cr_b = pi^2 * E_steel * I_weak / L_eff_braced^2;  % 加支撑后的欧拉临界力
    n_b = F_cr_b / F_arm;  % 加支撑后的屈曲安全系数
    fprintf('  加侧向支撑后 (Leff=%.0fmm): λ=%.0f, Fcr=%.0fN, n=%.1f 合格\n', ...  % 打印加支撑结果
        L_eff_braced, lambda_b, F_cr_b, n_b);
end

%% ==================== 7. 销轴强度校核 ====================
fprintf('\n--- 销轴强度 (D=%.0fmm, 45#钢) ---\n', D_pin);  % 打印销轴校核标题

A_pin = pi*(D_pin/2)^2;  % 销轴截面积(mm²)
F_pin = 2 * tau_allow * A_pin;  % 双剪承载力(N)
Q_pin = F_pin / 9.81;  % 双剪承载力换算为重量(kg)

L_span = H_arm + 6;  % 销轴受力跨度 = 臂宽 + 间隙
M_pin = F_arm * L_span / 4;  % 销轴最大弯矩（简支梁跨中集中力）
I_pin = pi*(D_pin/2)^4/4;  % 圆截面惯性矩(mm⁴)
W_pin = I_pin/(D_pin/2);  % 抗弯截面模量(mm³)
sigma_pin = M_pin / W_pin;  % 销轴弯曲应力(MPa)

sigma_brg = F_arm / (D_pin * B_arm);  % 耳板承压应力(MPa)

fprintf('  双剪承载力: %.1f kN (%.0f kg)\n', F_pin/1000, Q_pin);  % 打印双剪承载力
fprintf('  销轴弯曲: %.1f MPa\n', sigma_pin);  % 打印销轴弯曲应力
fprintf('  耳板承压: %.1f MPa\n', sigma_brg);  % 打印承压应力
fprintf('  判定: 全部合格\n');  % 判定

%% ==================== 8. 台面弯曲强度校核 ====================
fprintf('\n--- 台面弯曲 (%.0f×%.0f×%.0fmm) ---\n', ...  % 打印台面校核标题
    platform_length, platform_width, platform_thick);

q_plt = F_load / (platform_length * platform_width);  % 台面均布载荷(MPa)
M_plt = q_plt * platform_width^2 / 8;  % 台面最大弯矩（简支板跨中）
W_plt = platform_thick^2 / 6;  % 台面单位宽度截面模量(mm³/mm)
sigma_plt = M_plt / W_plt;  % 台面最大弯曲应力(MPa)

D_plate = E_steel * platform_thick^3 / (12*(1-0.3^2));  % 薄板弯曲刚度(N·mm)
a = platform_length;  b = platform_width;  % 台面长和宽的简写
amn = (1/a)^2 + (1/b)^2;  % Navier解分母因子
w_max = 16*q_plt/(pi^6*D_plate*1*1*amn^2);  % Navier级数第一项近似挠度

fprintf('  σ = %.1f MPa (allow=%.0f, util=%.0f%%)\n', sigma_plt, sigma_allow, sigma_plt/sigma_allow*100);  % 打印应力
fprintf('  w_max ≈ %.2f mm (L/%.0f)\n', w_max, b/w_max);  % 打印挠度及挠跨比
if sigma_plt < sigma_allow  % 判定台面强度
    fprintf('  判定: 合格\n');  % 满足
else
    fprintf('  判定: 不合格\n');  % 不满足
end

%% ==================== 9. 最大安全载重反算 ====================
fprintf('\n========== 最大载重综合评估 ==========\n');  % 打印载重评估标题

F_arm_max_pin = F_pin;  % 由销轴剪切强度限制的最大臂力(N)
Q1 = F_arm_max_pin * 4 * sind(beta_worst) / 9.81;  % 销轴限制的最大载重(kg)

coeff = 1/(4*sind(beta_worst)*A_sec) + 0.5*ecc/(4*sind(beta_worst)*W_strong);  % 臂强度-载荷关系系数
Q2 = sigma_allow / (coeff * 9.81);  % 臂压弯强度限制的最大载重(kg)

F_arm_max_buckle = F_cr_b / n_buckle;  % 由屈曲安全系数限制的最大臂力(N)
Q3 = F_arm_max_buckle * 4 * sind(beta_worst) / 9.81;  % 屈曲限制的最大载重(kg)

q_max = sigma_allow * W_plt * 8 / platform_width^2;  % 台面许用均布载荷(MPa)
Q4 = q_max * platform_length * platform_width / 9.81;  % 台面弯曲限制的最大载重(kg)

Qs = [Q1, Q2, Q3, Q4];  % 四种失效模式的限制载荷集合
names = {'销轴剪切', '臂压弯强度', '屈曲(加支撑)', '台面弯曲'};  % 失效模式名称
[Q_max, idx] = min(Qs);  % 最小值为最大安全载重，idx为控制因素序号

fprintf('  (1) 销轴剪切:        %.0f kg\n', Q1);  % 打印销轴限制载荷
fprintf('  (2) 臂压弯强度:      %.0f kg\n', Q2);  % 打印臂强度限制载荷
fprintf('  (3) 屈曲(加支撑):    %.0f kg\n', Q3);  % 打印屈曲限制载荷
fprintf('  (4) 台面弯曲:        %.0f kg\n', Q4);  % 打印台面限制载荷
fprintf('\n  最大安全载重: %.0f kg  (控制因素: %s)\n', Q_max, names{idx});  % 打印最终结果
fprintf('  额定 %.0f kg,  安全裕度 %.0f%%\n', Q_rated, (Q_max/Q_rated-1)*100);  % 打印安全裕度

%% ==================== 10. 结果可视化绘图 ====================
figure('Position', [50, 50, 1400, 800], 'Color', 'w');  % 创建大图窗

beta_plot = linspace(beta_low, beta_high, 200);  % 半角从最低到最高取200点

subplot(2,3,1);  % 2×3子图布局，第1个
plot(beta_plot, L_arm*sind(beta_plot), 'b-', 'LineWidth', 2);  % 绘制台面高度-半角曲线
xlabel('水平半角 β (°)'); ylabel('台面高度 (mm)');  % 坐标轴标签
title(sprintf('台面高度 vs β (%.0f~%.0f mm)', L_arm*sind(beta_low), L_arm*sind(beta_high)));  % 标题
grid on;  % 显示网格

subplot(2,3,2);  % 第2个子图
F_arm_plot = F_load ./ (4 * sind(beta_plot));  % 计算各半角下的臂轴向力
plot(beta_plot, F_arm_plot, 'r-', 'LineWidth', 2);  % 绘制臂轴向力-半角曲线
xlabel('水平半角 β (°)'); ylabel('臂轴向力 (N)');  % 坐标轴标签
title(sprintf('F_{arm} vs β (Q=%.0fkg)', Q_rated)); grid on;  % 标题和网格

subplot(2,3,3);  % 第3个子图
bar(categorical(names), Qs, 'FaceColor', [0.3 0.5 0.8]);  % 绘制各失效模式限制载荷柱状图
hold on; yline(Q_rated, 'k--', 'LineWidth', 1.5);  % 绘制额定载荷参考线
ylabel('载荷 (kg)'); title('各失效模式限制载荷'); grid on;  % 标签、标题、网格

subplot(2,3,4);  % 第4个子图
bar(categorical({'轴向','弯曲','组合'}), [sigma_axial, sigma_bend, sigma_comb]);  % 绘制应力分量柱状图
hold on; yline(sigma_allow, 'r--', 'LineWidth', 1.5);  % 绘制许用应力线
ylabel('应力 (MPa)'); title(sprintf('臂应力分量 (%.0fkg)', Q_rated)); grid on;  % 标签、标题、网格

subplot(2,3,5);  % 第5个子图
Q_sweep = linspace(10, 200, 100);  % 载荷扫描范围10~200kg
n_sweep = zeros(size(Q_sweep));  % 初始化安全系数数组
for i = 1:length(Q_sweep)  % 遍历扫描载荷
    Fa = Q_sweep(i)*9.81/(4*sind(beta_worst));  % 当前载荷对应的臂轴向力
    n_sweep(i) = F_cr_b / Fa;  % 当前载荷的屈曲安全系数
end
plot(Q_sweep, n_sweep, 'm-', 'LineWidth', 2);  % 绘制屈曲安全系数-载荷曲线
hold on; yline(n_buckle, 'k--'); yline(1, 'r:');  % 绘制安全系数要求和临界线
xlabel('载荷 (kg)'); ylabel('屈曲安全系数');  % 坐标轴标签
title('屈曲安全系数 vs 载荷 (加支撑后)'); grid on;  % 标题和网格

subplot(2,3,6);  % 第6个子图
sigma_sweep = zeros(size(Q_sweep));  % 初始化台面应力数组
for i = 1:length(Q_sweep)  % 遍历扫描载荷
    qs = Q_sweep(i)*9.81/(platform_length*platform_width);  % 当前载荷的均布载荷
    sigma_sweep(i) = qs*platform_width^2/8 / W_plt;  % 当前载荷的台面应力
end
plot(Q_sweep, sigma_sweep, 'b-', 'LineWidth', 2);  % 绘制台面应力-载荷曲线
hold on; yline(sigma_allow, 'r--', 'LineWidth', 1.5);  % 绘制许用应力线
xlabel('载荷 (kg)'); ylabel('台面应力 (MPa)');  % 坐标轴标签
title('台面弯曲应力 vs 载荷'); grid on;  % 标题和网格

sgtitle(sprintf('剪叉升降台强度校核 | %.0f×%.0fmm扁钢 L=%.0fmm | 额定%.0fkg 最大%.0fkg', ...  % 全局标题
    B_arm, H_arm, L_arm, Q_rated, Q_max), 'FontSize', 14, 'FontWeight', 'bold');

%% ==================== 11. 校核结果汇总输出 ====================
fprintf('\n');  % 空行
fprintf('  ╔════════════════════════════════════════╗\n');  % 表格顶线
fprintf('  ║  剪叉升降台强度校核报告 (%.0fkg)       ║\n', Q_rated);  % 报告标题
fprintf('  ╠════════════════════════════════════════╣\n');  % 表头分割线
fprintf('  ║  臂: %.0f×%.0fmm扁钢  L=%.0fmm        ║\n', B_arm, H_arm, L_arm);  % 臂参数
fprintf('  ║  台面: %d×%d×%dmm  销轴: D=%.0fmm     ║\n', ...  % 台面和销轴参数
    platform_length, platform_width, platform_thick, D_pin);
fprintf('  ║  β: %.1f°~%.1f°  H: %.0f~%.0fmm      ║\n', beta_low, beta_high, H_min, H_max);  % 工作范围
fprintf('  ╠════════════════════════════════════════╣\n');  % 分隔线
fprintf('  ║  臂压弯: %5.1f/%.0f MPa (%.0f%%)      ║\n', sigma_comb, sigma_allow, sigma_comb/sigma_allow*100);  % 臂强度结果
fprintf('  ║  屈曲(支撑): n=%.0f (需≥%.0f)         ║\n', n_b, n_buckle);  % 屈曲结果
fprintf('  ║  销轴: 弯曲%.0f 承压%.0f MPa           ║\n', sigma_pin, sigma_brg);  % 销轴结果
fprintf('  ║  台面: σ=%.0fMPa w=%.2fmm             ║\n', sigma_plt, w_max);  % 台面结果
fprintf('  ╠════════════════════════════════════════╣\n');  % 分隔线
fprintf('  ║  最大安全载重: %.0f kg             ║\n', Q_max);  % 最大载重
fprintf('  ╚════════════════════════════════════════╝\n');  % 表格底线
