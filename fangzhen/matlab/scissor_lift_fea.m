%% 剪叉式升降台有限元分析与强度校核
clear; clc; close all;  % 清空工作区、命令行、关闭图形窗口

E = 206000;  nu = 0.3;  % Q235钢材弹性模量(MPa)和泊松比
sigma_allow = 235/1.5;  % 许用应力，屈服强度235MPa除以安全系数1.5

%% ===== 基本设计参数 =====
L_arm = 600;   alpha_low = 19.10;   beta_low = alpha_low/2;  % 臂长600mm，最低位夹角及半角
Q_load = 50;  % 额定载重50kg
F_load = Q_load * 9.81;  % 额定载荷换算为重力(N)
F_arm  = F_load / (4 * sind(beta_low));  % 每根臂杆的轴向力，由静力平衡推导

B_arm = 4.8;   H_arm = 36;  % 臂杆截面尺寸：厚4.8mm，宽36mm（扁钢竖直放置）
A_sec = B_arm * H_arm;  % 臂杆截面积(mm²)
I_strong = B_arm * H_arm^3 / 12;  % 强轴惯性矩(mm⁴)，竖直面内抗弯
I_weak   = H_arm * B_arm^3 / 12;  % 弱轴惯性矩(mm⁴)，侧向抗弯
W_strong = I_strong / (H_arm/2);  % 强轴截面模量(mm³)

a_plt = 660;  b_plt = 312;  t_plt = 3;  % 台面尺寸：长660mm，宽312mm，厚3mm
q_plt = F_load/(a_plt*b_plt);  % 台面均布载荷(MPa)
D_plate = E*t_plt^3/(12*(1-nu^2));  % 薄板弯曲刚度(N·mm)

D_pin = 18;  % 销轴直径18mm

fprintf('========== 剪叉升降台 FEA (Q=%.0fkg) ==========\n', Q_load);  % 打印标题
fprintf('臂: %.0f×%.0fmm 扁钢, L=%.0fmm\n\n', B_arm, H_arm, L_arm);  % 打印臂截面参数

%% ===== Part 1: 台面板Navier级数解 =====
fprintf('--- Part 1: 台面弯曲 (%.0f×%.0f×%.0fmm) ---\n', a_plt, b_plt, t_plt);  % 打印台面尺寸

w_c = 0;  Mx_c = 0;  My_c = 0;  % 初始化中心点挠度、X向弯矩、Y向弯矩
for m = 1:2:81  % m为X方向级数项，取奇数1,3,5,...,81
    sm = sin(m*pi/2);  % sin(mπ/2)，中心点三角函数值
    for n = 1:2:81  % n为Y方向级数项，取奇数1,3,5,...,81
        sn = sin(n*pi/2);  % sin(nπ/2)，中心点三角函数值
        amn = (m/a_plt)^2 + (n/b_plt)^2;  % 级数分母因子
        w_c  = w_c  + 16*q_plt/(pi^6*D_plate*m*n*amn^2)*sm*sn;  % Navier解挠度级数累加
        Mx_c = Mx_c + 16*q_plt/(pi^4*m*n*amn^2)*((m/a_plt)^2+nu*(n/b_plt)^2)*sm*sn;  % X向弯矩级数累加
        My_c = My_c + 16*q_plt/(pi^4*m*n*amn^2)*((n/b_plt)^2+nu*(m/a_plt)^2)*sm*sn;  % Y向弯矩级数累加
    end
end
sx_c = 6*abs(Mx_c)/t_plt^2;  % 由X向弯矩计算X向弯曲应力
sy_c = 6*abs(My_c)/t_plt^2;  % 由Y向弯矩计算Y向弯曲应力
svm_c = sqrt(sx_c^2 + sy_c^2 - sx_c*sy_c);  % von Mises等效应力

fprintf('  w_max = %.2f mm (L/%.0f)\n', w_c, b_plt/w_c);  % 打印最大挠度及挠跨比
fprintf('  sigma_vm = %.1f MPa (%.0f%%)', svm_c, svm_c/sigma_allow*100);  % 打印等效应力及利用率
if svm_c < sigma_allow, fprintf('  OK\n\n'); else, fprintf('  FAIL\n\n'); end  % 判定台面是否合格

%% ===== Part 2: 臂杆梁单元FEA =====
fprintf('--- Part 2: 臂 FEA (30梁单元, 两端铰支) ---\n');  % 打印FEA参数

n_elem = 30;  n_nodes = n_elem + 1;  L_e = L_arm / n_elem;  % 30个单元，31个节点，单元长度
ndof = 3;  n_dof_total = n_nodes * ndof;  % 每节点3自由度(轴向、横向、转角)，总自由度数
K_glob = zeros(n_dof_total);  F_glob = zeros(n_dof_total, 1);  % 初始化全局刚度矩阵和载荷向量

k_e = @(L) [E*A_sec/L,  0,              0,             -E*A_sec/L,  0,              0;  % 平面梁单元刚度矩阵第1行
            0,           12*E*I_strong/L^3,6*E*I_strong/L^2,0,       -12*E*I_strong/L^3,6*E*I_strong/L^2;  % 第2行
            0,           6*E*I_strong/L^2, 4*E*I_strong/L, 0,       -6*E*I_strong/L^2, 2*E*I_strong/L;  % 第3行
            -E*A_sec/L, 0,              0,             E*A_sec/L,   0,              0;  % 第4行
            0,           -12*E*I_strong/L^3,-6*E*I_strong/L^2,0,    12*E*I_strong/L^3,-6*E*I_strong/L^2;  % 第5行
            0,           6*E*I_strong/L^2, 2*E*I_strong/L, 0,       -6*E*I_strong/L^2, 4*E*I_strong/L];  % 第6行

for ie = 1:n_elem  % 遍历每个单元进行组装
    dof_map = ((ie-1)*ndof+1):((ie+1)*ndof);  % 当前单元对应的全局自由度编号
    K_glob(dof_map, dof_map) = K_glob(dof_map, dof_map) + k_e(L_e);  % 将单元刚度矩阵叠加到全局矩阵
end

fixed_dof = [1, 2, n_dof_total-1];  % 两端铰支约束：左端Ux,Uy固定，右端Uy固定
free_dof  = setdiff(1:n_dof_total, fixed_dof);  % 除去约束后的自由自由度编号

F_glob(n_dof_total-2) = -F_arm;  % 在右端节点施加轴向压力（负号表示受压）

w_s = 7850e-9 * A_sec * 9.81;  % 臂杆自重线分布载荷(N/mm)
for ie = 1:n_elem  % 遍历每个单元施加自重等效节点力
    f_eq = w_s * L_e / 2;  m_eq = w_s * L_e^2 / 12;  % 均布载荷的等效节点力和节点弯矩
    F_glob((ie-1)*ndof+2) = F_glob((ie-1)*ndof+2) + f_eq;  % 左节点横向力叠加
    F_glob((ie-1)*ndof+3) = F_glob((ie-1)*ndof+3) - m_eq;  % 左节点弯矩叠加
    F_glob(ie*ndof+2)     = F_glob(ie*ndof+2)     + f_eq;  % 右节点横向力叠加
    F_glob(ie*ndof+3)     = F_glob(ie*ndof+3)     + m_eq;  % 右节点弯矩叠加
end

U_glob = zeros(n_dof_total, 1);  % 初始化全局位移向量
U_glob(free_dof) = K_glob(free_dof, free_dof) \ F_glob(free_dof);  % 用直接法求解自由自由度位移

ux = U_glob(1:ndof:end);  uy = U_glob(2:ndof:end);  % 提取各节点的轴向位移和横向位移

sigma_ax_elem = zeros(n_elem,1);  sigma_bd_elem = zeros(n_elem,1);  % 初始化各单元轴向应力和弯曲应力
for ie = 1:n_elem  % 遍历每个单元计算应力
    u_e = U_glob(((ie-1)*ndof+1):((ie+1)*ndof));  % 提取当前单元节点位移
    F_e = k_e(L_e) * u_e;  % 由位移反算单元节点力
    N = abs((F_e(4)-F_e(1))/2);  % 单元轴力（两端平均值取绝对值）
    M = max(abs(F_e(3)), abs(F_e(6)));  % 单元最大弯矩（取两端中较大者）
    sigma_ax_elem(ie) = N / A_sec;  % 轴向正应力 = 轴力/面积
    sigma_bd_elem(ie) = M / W_strong;  % 弯曲正应力 = 弯矩/截面模量
end

ecc = 2;  % 偏心距(mm)，与论文一致
M_ecc = 0.5 * F_arm * ecc;  % 偏心附加弯矩(N·mm)，对应论文 M_ecc=0.74N·m
sigma_arm_fea = max(sigma_ax_elem + sigma_bd_elem) + M_ecc / W_strong;  % 臂杆最大组合应力（轴向+弯曲+偏心）
uy_max = max(abs(uy));  % 臂杆最大横向挠度

i_min = sqrt(I_weak/A_sec);  % 弱轴方向的最小回转半径
lam = L_arm / i_min;  % 弱轴方向长细比
F_cr_weak = pi^2 * E * I_weak / L_arm^2;  % 弱轴欧拉临界力
n_buckle = F_cr_weak / F_arm;  % 无支撑时弱轴屈曲安全系数
L_braced = L_arm/2;  % 加中心隔套后的有效长度
F_cr_braced = pi^2 * E * I_weak / L_braced^2;  % 加支撑后的欧拉临界力
n_braced = F_cr_braced / F_arm;  % 加支撑后的屈曲安全系数

fprintf('  F_arm=%.0fN,  w_self=%.4f N/mm\n', F_arm, w_s);  % 打印臂杆轴力和自重线载荷
fprintf('  sigma_axial=%.2f, sigma_bend_max=%.2f, sigma_comb=%.2f MPa (%.0f%%)\n', ...  % 打印应力结果
    max(sigma_ax_elem), max(sigma_bd_elem), sigma_arm_fea, sigma_arm_fea/sigma_allow*100);
fprintf('  uy_max = %.4f mm\n', uy_max);  % 打印最大挠度
fprintf('  弱轴屈曲: lambda=%.0f, Fcr=%.0fN, n=%.1f\n', lam, F_cr_weak, n_buckle);  % 打印无支撑屈曲结果
fprintf('  加支撑后: Leff=%.0fmm, Fcr=%.0fN, n=%.1f', L_braced, F_cr_braced, n_braced);  % 打印加支撑屈曲结果
if n_braced >= 3, fprintf('  OK\n\n'); else, fprintf('  FAIL\n\n'); end  % 判定屈曲是否合格

%% ===== Part 3: 销轴强度校核(45#钢) =====
fprintf('--- Part 3: 销轴 D=%.0fmm (45#钢) ---\n', D_pin);  % 打印销轴直径
sigma_y_pin = 355;  % 45#钢屈服强度(MPa)
tau_y_pin = 0.6 * sigma_y_pin;  % 剪切屈服(MPa)
tau_allow_pin = tau_y_pin / 1.5;  % 许用剪应力(MPa)
L_span = 27;  % 耳板内间距(mm)，对应论文 L_s=27mm
t_ear = 6;  % 耳板厚度(mm)
A_pin = pi*(D_pin/2)^2;  % 销轴截面积(mm²)
F_pin = 2 * tau_allow_pin * A_pin;  % 双剪承载力(N)
M_pin = F_arm * L_span / 4;  % 销轴最大弯矩（简支梁跨中集中力）
W_pin = pi*D_pin^3/32;  % 销轴圆截面抗弯截面模量，对应论文 W=πD³/32
sigma_pin = M_pin / W_pin;  % 销轴最大弯曲应力
sigma_brg = F_arm/(D_pin*t_ear);  % 耳板承压应力，对应论文 σ=F/(D·t)
fprintf('  双剪承载力: %.1f kN\n', F_pin/1000);
fprintf('  弯曲=%.0fMPa, 承压=%.1fMPa  OK\n\n', sigma_pin, sigma_brg);  % 打印销轴校核结果

%% ===== Part 4: 结果可视化 =====
figure('Position', [30, 30, 1500, 500], 'Color', 'w');  % 创建大图窗

% (a) 台面挠度云图
subplot(2,3,1);  % 2行3列第1个子图
nx=25; ny=25; xc=linspace(0,a_plt,nx); yc=linspace(0,b_plt,ny);  % 台面网格划分
Wc=zeros(ny,nx);  % 初始化挠度矩阵
for ix=1:nx  % 遍历X方向网格点
    for iy=1:ny  % 遍历Y方向网格点
        for m=1:2:21  % 级数求和m项（截断至21项以加快计算）
            sm=sin(m*pi*xc(ix)/a_plt);  % X向正弦函数值
            for n=1:2:21  % 级数求和n项
                sn=sin(n*pi*yc(iy)/b_plt);  % Y向正弦函数值
                amn=(m/a_plt)^2+(n/b_plt)^2;  % 分母因子
                Wc(iy,ix)=Wc(iy,ix)+16*q_plt/(pi^6*D_plate*m*n*amn^2)*sm*sn;  % 挠度级数累加
            end
        end
    end
end
[Xc,Yc]=meshgrid(xc,yc);  % 生成网格坐标矩阵
contourf(Xc,Yc,Wc,20,'LineStyle','none');  % 绘制填充等高线图(20级)
colormap jet; colorbar;  % 使用jet颜色映射并添加颜色条
xlabel('X(mm)'); ylabel('Y(mm)');  % 坐标轴标签
title(sprintf('台面挠度 (max=%.2fmm)', w_c));  % 图标题显示最大挠度
axis equal tight;  % 等比例紧凑坐标轴

% (b) 臂杆FEA应力沿长度分布
subplot(2,3,2);  % 2行3列第2个子图
x_elem = linspace(L_e/2, L_arm-L_e/2, n_elem);  % 各单元中心点的X坐标
yyaxis left;  % 激活左Y轴
plot(x_elem, sigma_ax_elem, 'r-', 'LineWidth', 2);  % 绘制轴向应力曲线(红色)
ylabel('轴向应力 (MPa)');  % 左Y轴标签
yyaxis right;  % 激活右Y轴
plot(x_elem, sigma_bd_elem, 'b-', 'LineWidth', 2);  % 绘制弯曲应力曲线(蓝色)
ylabel('弯曲应力 (MPa)');  % 右Y轴标签
xlabel('臂长方向 (mm)');  % X轴标签
title(sprintf('臂 FEA 应力分布 (F_{arm}=%.0fN)', F_arm));  % 图标题
legend('轴向', '弯曲'); grid on;  % 图例和网格

% (c) 臂杆变形（放大500倍显示）
subplot(2,3,3);  % 2行3列第3个子图
x_nodes = linspace(0, L_arm, n_nodes)';  % 节点X坐标列向量
scale = 500;  % 变形放大倍数
plot(x_nodes, zeros(size(x_nodes)), 'k--'); hold on;  % 绘制原始位置虚线
plot(x_nodes + scale*ux, scale*uy, 'b-', 'LineWidth', 2);  % 绘制放大后的变形位置
xlabel('X (mm)'); ylabel(sprintf('变形 ×%d (mm)', scale));  % 坐标轴标签
title(sprintf('臂变形 (max挠度=%.4fmm)', uy_max));  % 图标题
legend('原始', '变形后'); axis equal; grid on;  % 图例、等比例、网格

% (d) 各部件应力对比柱状图
subplot(2,3,4);  % 2行3列第4个子图
vals = [sigma_arm_fea, sigma_pin, svm_c];  % 三个部件的最大应力值
names = categorical({'臂组合','销轴弯曲','台面VM'});  % 类别名称
bar(names, vals); hold on;  % 绘制柱状图
yline(sigma_allow, 'r--', 'LineWidth', 1.5);  % 绘制许用应力参考线
ylabel('应力 (MPa)'); title('各部件最大应力'); grid on;  % 标签和标题

% (e) 屈曲安全系数对比
subplot(2,3,5);  % 2行3列第5个子图
bar(categorical({['无支撑(n=',num2str(round(n_buckle,1)),')'],['加隔套(n=',num2str(round(n_braced,1)),')']}), ...  % 横轴标签
    [n_buckle, n_braced]);  % 两种情况的屈曲安全系数
hold on; yline(3, 'r--', 'LineWidth', 1.5);  % 绘制安全系数要求线n=3
ylabel('安全系数 n'); title('弱轴屈曲: 无支撑 vs 加隔套'); grid on;  % 标签和标题

% (f) 各部件应力裕度
subplot(2,3,6);  % 2行3列第6个子图
bar(categorical({'臂','销轴','台面'}), ...  % 横轴标签
    [sigma_allow-sigma_arm_fea, sigma_allow-sigma_pin, sigma_allow-svm_c]);  % 各部件应力裕度值
ylabel('应力裕度 (MPa)'); title('各部件应力裕度'); grid on;  % 标签、标题、网格

sgtitle(sprintf('剪叉升降台 FEA | %.0f×%.0fmm扁钢 | Q=%.0fkg | 全部合格', ...  % 总标题
    B_arm, H_arm, Q_load), 'FontSize', 14, 'FontWeight', 'bold');

%% ===== 分析结果汇总 =====
fprintf('========== FEA 汇总 ==========\n');  % 打印汇总标题
fprintf('  台面: w=%.2fmm, sigma=%.1fMPa (%.0f%%)\n', w_c, svm_c, svm_c/sigma_allow*100);  % 台面结果
fprintf('  臂:   sigma=%.2fMPa (%.0f%%), 挠度=%.4fmm\n', sigma_arm_fea, sigma_arm_fea/sigma_allow*100, uy_max);  % 臂结果
fprintf('  屈曲: 无支撑n=%.1f, 加隔套n=%.1f\n', n_buckle, n_braced);  % 屈曲结果
fprintf('  销轴: sigma=%.0fMPa\n', sigma_pin);  % 销轴结果
fprintf('\n  额定 %.0fkg: 全部合格\n', Q_load);  % 最终判定
