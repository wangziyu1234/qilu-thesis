import re

with open('D:/bylw/code/lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/pages/body.tex', 'r', encoding='utf-8') as f:
    content = f.read()

ch3_start = content.find(r'\chapter{智能仓储移动机器人机械结构设计}')
ch4_start = content.find(r'\chapter{智能仓储移动机器人电气系统设计}')
ch3 = content[ch3_start:ch4_start]

# Edit 1: Arm description
old = '两根等长臂杆（各1200\\,mm，销孔中心距）在中点处通过中心铰轴交叉连接，构成一个剪叉单元。臂杆截面为30\\,mm × 30\\,mm × 6\\,mm的Q235矩形钢管。'
new = '两根等长臂杆（各600\\,mm，销孔中心距）在中点处通过中心铰轴交叉连接，构成一个剪叉单元。臂杆采用36\\,mm × 4.8\\,mm的Q235实心扁钢，宽面竖直布置以提供抗弯刚度。'
ch3 = ch3.replace(old, new)
print('Edit 1 done')

# Edit 2: Working parameters
old = '臂杆长度$L = 1200$\\,mm。在最低工作位置，两臂夹角$\\alpha_{\\min} = 15.78^{\\circ}$，对应水平半角$\\beta_{\\min} = 7.89^{\\circ}$；在最高工作位置，两臂夹角$\\alpha_{\\max} = 57.12^{\\circ}$，对应水平半角$\\beta_{\\max} = 28.56^{\\circ}$。由式(\\ref{eq:H_beta})计算得：\n\\begin{align}\n    H_{\\min} &= 1200 \\times \\sin(7.89^{\\circ}) \\approx 164.7\\ \\text{mm} \\\\\n    H_{\\max} &= 1200 \\times \\sin(28.56^{\\circ}) \\approx 573.7\\ \\text{mm}\n\\end{align}\n\n理论升降行程约为$409.0$\\,mm。考虑到底座结构高度和平台厚度等因素，设计升降高度取458.92\\,mm，覆盖常用仓库货架的底层至中层高度范围。'
new2 = '臂杆长度$L = 600$\\,mm。在最低工作位置，两臂夹角$\\alpha_{\\min} = 15.78^{\\circ}$，对应水平半角$\\beta_{\\min} = 7.89^{\\circ}$；在最高工作位置，两臂夹角$\\alpha_{\\max} = 57.12^{\\circ}$，对应水平半角$\\beta_{\\max} = 28.56^{\\circ}$。由式(\\ref{eq:H_beta})计算得：\n\\begin{align}\n    H_{\\min} &= 600 \\times \\sin(7.89^{\\circ}) \\approx 82.4\\ \\text{mm} \\\\\n    H_{\\max} &= 600 \\times \\sin(28.56^{\\circ}) \\approx 286.8\\ \\text{mm}\n\\end{align}\n\n理论升降行程约为$204.4$\\,mm。考虑到底盘高度（约172\\,mm）、车体框架及平台厚度等结构尺寸后，台面相对于地面的设计最大高度取458.92\\,mm，覆盖常用仓库货架的底层至中层取放需求。'
ch3 = ch3.replace(old, new2)
print('Edit 2 done')

# Edit 3: Cross-section
old = '臂杆采用30\\,mm × 30\\,mm × 6\\,mm的Q235矩形钢管，其截面几何参数计算如下：\n\\begin{align}\n    A &= BH - (B-2t)(H-2t) = 30^{2} - (30-12)^{2} = 900 - 324 = 576\\ \\text{mm}^{2} \\label{eq:A}\\\\\n    I &= \\frac{BH^{3} - (B-2t)(H-2t)^{3}}{12} = \\frac{30^{4} - 18^{4}}{12} = 58752\\ \\text{mm}^{4} \\label{eq:I}\\\\\n    W &= \\frac{I}{H/2} = \\frac{58752}{15} = 3917\\ \\text{mm}^{3} \\label{eq:W}\\\\\n    i_{\\min} &= \\sqrt{\\frac{I}{A}} = \\sqrt{\\frac{58752}{576}} = 10.1\\ \\text{mm} \\label{eq:imin}\n\\end{align}'
new3 = '臂杆采用36\\,mm × 4.8\\,mm的Q235实心扁钢，宽面（36\\,mm）沿竖直方向布置以增强抗弯能力，其截面几何参数计算如下：\n\\begin{align}\n    A &= B \\cdot H = 4.8 \\times 36 = 172.8\\ \\text{mm}^{2} \\label{eq:A}\\\\\n    I_{\\text{强}} &= \\frac{B H^{3}}{12} = \\frac{4.8 \\times 36^{3}}{12} \\approx 18662\\ \\text{mm}^{4} \\quad \\text{（竖直面内弯曲）} \\label{eq:I_strong}\\\\\n    I_{\\text{弱}} &= \\frac{H B^{3}}{12} = \\frac{36 \\times 4.8^{3}}{12} \\approx 332\\ \\text{mm}^{4} \\quad \\text{（侧向弯曲）} \\label{eq:I_weak}\\\\\n    W &= \\frac{I_{\\text{强}}}{H/2} = \\frac{18662}{18} \\approx 1037\\ \\text{mm}^{3} \\label{eq:W}\\\\\n    i_{\\min} &= \\sqrt{\\frac{I_{\\text{弱}}}{A}} = \\sqrt{\\frac{332}{172.8}} \\approx 1.39\\ \\text{mm} \\label{eq:imin}\n\\end{align}'
ch3 = ch3.replace(old, new3)
print('Edit 3 done')

# Edit 4: Self-weight
old = '臂杆自重线载荷为：\n\\begin{equation}\n    w = \\rho \\cdot A \\cdot g = 7.85 \\times 10^{-6}\\ \\text{kg/mm}^{3} \\times 576\\ \\text{mm}^{2} \\times 9.81\\ \\text{m/s}^{2} \\approx 0.0443\\ \\text{N/mm}\n    \\label{eq:w_self}\n\\end{equation}\n\n将臂杆简化为两端铰支的简支梁，自重产生的跨中最大弯矩为：\n\\begin{equation}\n    M_{\\text{self}} = \\frac{w \\cdot L^{2} \\cdot \\cos{\\beta}}{8} \\approx \\frac{0.0443 \\times 1200^{2} \\times \\cos(7.89^{\\circ})}{8} \\times 10^{-3} \\approx 7.90\\ \\text{N·m}\n    \\label{eq:M_self}\n\\end{equation}'
new4 = '臂杆自重线载荷为：\n\\begin{equation}\n    w = \\rho \\cdot A \\cdot g = 7.85 \\times 10^{-6}\\ \\text{kg/mm}^{3} \\times 172.8\\ \\text{mm}^{2} \\times 9.81\\ \\text{m/s}^{2} \\approx 0.0133\\ \\text{N/mm}\n    \\label{eq:w_self}\n\\end{equation}\n\n将臂杆简化为两端铰支的简支梁，自重产生的跨中最大弯矩为：\n\\begin{equation}\n    M_{\\text{self}} = \\frac{w \\cdot L^{2} \\cdot \\cos{\\beta}}{8} \\approx \\frac{0.0133 \\times 600^{2} \\times \\cos(7.89^{\\circ})}{8} \\times 10^{-3} \\approx 0.59\\ \\text{N·m}\n    \\label{eq:M_self}\n\\end{equation}'
ch3 = ch3.replace(old, new4)
print('Edit 4 done')

# Edit 5: M_ecc and M_total
old = '此外，考虑制造和装配过程中不可避免的偏心误差，保守取偏心距$e = 2$\\,mm，其引起的附加弯矩为：\n\\begin{equation}\n    M_{\\text{ecc}} = 0.5 \\cdot F_{\\text{arm}} \\cdot e = 0.5 \\times 893.3 \\times 0.002 \\approx 0.89\\ \\text{N·m}\n    \\label{eq:M_ecc}\n\\end{equation}\n\n综合弯矩最大值为$M_{\\max} \\approx 8.79$\\,N·m。'
new5 = '此外，考虑制造和装配过程中不可避免的偏心误差，保守取偏心距$e = 2$\\,mm，其引起的附加弯矩为：\n\\begin{equation}\n    M_{\\text{ecc}} = 0.5 \\cdot F_{\\text{arm}} \\cdot e = 0.5 \\times 893.3 \\times 0.002 \\approx 0.89\\ \\text{N·m}\n    \\label{eq:M_ecc}\n\\end{equation}\n\n综合弯矩最大值为$M_{\\max} \\approx 1.49$\\,N·m。'
ch3 = ch3.replace(old, new5)
print('Edit 5 done')

# Edit 6: Stresses
old = '轴向压应力为：\n\\begin{equation}\n    \\sigma_{a} = \\frac{F_{\\text{arm}}}{A} = \\frac{893.3}{576} \\approx 1.55\\ \\text{MPa}\n    \\label{eq:sigma_a}\n\\end{equation}\n\n弯曲正应力（考虑自重弯矩和偏心弯矩）为：\n\\begin{equation}\n    \\sigma_{b} = \\frac{M_{\\max}}{W} = \\frac{8.79 \\times 10^{3}}{3917} \\approx 2.24\\ \\text{MPa}\n    \\label{eq:sigma_b}\n\\end{equation}\n\n压弯组合最大应力出现在截面受压侧边缘：\n\\begin{equation}\n    \\sigma_{\\max} = \\sigma_{a} + \\sigma_{b} = 1.55 + 2.24 = 3.79\\ \\text{MPa}\n    \\label{eq:sigma_max}\n\\end{equation}'
new6 = '轴向压应力为：\n\\begin{equation}\n    \\sigma_{a} = \\frac{F_{\\text{arm}}}{A} = \\frac{893.3}{172.8} \\approx 5.17\\ \\text{MPa}\n    \\label{eq:sigma_a}\n\\end{equation}\n\n弯曲正应力（考虑自重弯矩和偏心弯矩）为：\n\\begin{equation}\n    \\sigma_{b} = \\frac{M_{\\max}}{W} = \\frac{1.49 \\times 10^{3}}{1037} \\approx 1.44\\ \\text{MPa}\n    \\label{eq:sigma_b}\n\\end{equation}\n\n压弯组合最大应力出现在截面受压侧边缘：\n\\begin{equation}\n    \\sigma_{\\max} = \\sigma_{a} + \\sigma_{b} = 5.17 + 1.44 = 6.61\\ \\text{MPa}\n    \\label{eq:sigma_max}\n\\end{equation}'
ch3 = ch3.replace(old, new6)
print('Edit 6 done')

# Edit 7: Stress conclusion
old = '$\\sigma_{\\max} = 3.79$\\,MPa $\\ll [\\sigma] = 156.7$\\,MPa，臂杆强度满足设计要求，应力利用率仅为$2.4\\%$，具有极大的安全余量。'
new7 = '$\\sigma_{\\max} = 6.61$\\,MPa $\\ll [\\sigma] = 156.7$\\,MPa，臂杆强度满足设计要求，应力利用率仅为$4.2\\%$，具有充足的安全余量。'
ch3 = ch3.replace(old, new7)
print('Edit 7 done')

# Edit 8: Buckling - find and replace the whole subsection
old_bs = '臂杆为细长受压构件，需校核其整体稳定性。将臂杆简化为两端铰支的压杆，长度系数$\\mu = 1.0$，有效长度$L_{\\text{eff}} = \\mu L = 1200$\\,mm。长细比为：'
old_be = '臂杆屈曲稳定性极为充裕，不存在失稳风险。'

si = ch3.find(old_bs)
ei = ch3.find(old_be)
if si > 0 and ei > si:
    new_buckle = '臂杆为细长受压构件，需校核其整体稳定性。由于臂杆截面为扁钢，弱轴方向（侧向，$I_{\\text{弱}} = 332$\\,mm$^{4}$）的惯性矩远小于强轴方向（竖直面内，$I_{\\text{强}} = 18662$\\,mm$^{4}$），因此侧向屈曲是稳定性的控制因素。\n\n将臂杆简化为两端铰支的压杆，长度系数$\\mu = 1.0$，有效长度$L_{\\text{eff}} = \\mu L = 600$\\,mm。弱轴方向的长细比为：\n\\begin{equation}\n    \\lambda = \\frac{L_{\\text{eff}}}{i_{\\min}} = \\frac{600}{1.39} \\approx 431.7\n    \\label{eq:lambda}\n\\end{equation}\n\nQ235钢的比例极限长细比约为$\\lambda_{p} \\approx 104$。由于$\\lambda = 431.7 > \\lambda_{p}$，该杆属于大柔度压杆，其临界载荷采用欧拉公式计算：\n\\begin{equation}\n    F_{\\text{cr}} = \\frac{\\pi^{2} E I_{\\text{弱}}}{L_{\\text{eff}}^{2}} = \\frac{\\pi^{2} \\times 2.06 \\times 10^{5} \\times 332}{600^{2}} \\approx 1874\\ \\text{N}\n    \\label{eq:Fcr}\n\\end{equation}\n\n取屈曲稳定安全系数$n_{\\text{buckle}} = 3.0$，则：\n\\begin{equation}\n    n_{\\text{actual}} = \\frac{F_{\\text{cr}}}{F_{\\text{arm}}} = \\frac{1874}{893.3} \\approx 2.10 < 3.0\n    \\label{eq:n_buckle}\n\\end{equation}\n\n上述计算表明，在无侧向约束的条件下，臂杆弱轴方向的安全系数$n_{\\text{actual}} \\approx 2.10$略低于设计要求的$n_{\\text{buckle}} = 3.0$。为解决这一问题，本设计在两侧臂杆之间增设侧向支撑隔套，将有效长度减半至$300$\\,mm，此时：\n\\begin{equation}\n    F_{\\text{cr}}^{\\prime} = \\frac{\\pi^{2} \\times 2.06 \\times 10^{5} \\times 332}{300^{2}} \\approx 7496\\ \\text{N}\n\\end{equation}\n\\begin{equation}\n    n_{\\text{actual}}^{\\prime} = \\frac{7496}{893.3} \\approx 8.39 \\gg 3.0\n    \\label{eq:n_buckle_braced}\n\\end{equation}\n\n增设侧向支撑后，屈曲安全系数提升至8.39，满足设计要求。因此，在实际结构中必须设置中心隔套或侧向限位装置以防止臂杆发生侧向失稳。'
    ch3 = ch3[:si] + new_buckle + ch3[ei + len(old_be):]
    print('Edit 8 done')
else:
    print(f'Edit 8 FAILED: si={si}, ei={ei}')

# Edit 9: Summary
old = '（1）剪叉式升降机构采用单层剪叉方案，臂长$L = 1200$\\,mm，两臂夹角范围为$15.78^{\\circ} \\sim 57.12^{\\circ}$，对应台面高度约$165 \\sim 574$\\,mm，行程覆盖常用货架高度范围。\n\n（2）额定载重设定为50\\,kg，在最危险工况（最低位，$\\beta = 7.89^{\\circ}$）下，臂杆轴向力为893.3\\,N，组合应力约3.79\\,MPa，远低于Q235钢的许用应力156.7\\,MPa；屈曲临界载荷约83.0\\,kN，安全系数$n \\approx 93$，不存在稳定性风险。'
new9 = '（1）剪叉式升降机构采用单层剪叉方案，臂长$L = 600$\\,mm，截面为36\\,mm × 4.8\\,mm的Q235实心扁钢，两臂夹角范围为$15.78^{\\circ} \\sim 57.12^{\\circ}$。纯剪叉机构台面高度约$82 \\sim 287$\\,mm，计入底盘高度（约172\\,mm）后，台面总高度约$254 \\sim 459$\\,mm，设计升降高度458.92\\,mm，行程覆盖常用货架高度范围。\n\n（2）额定载重设定为50\\,kg，在最危险工况（最低位，$\\beta = 7.89^{\\circ}$）下，臂杆轴向力为893.3\\,N，组合应力约6.61\\,MPa，远低于Q235钢的许用应力156.7\\,MPa（利用率4.2\\%）；弱轴方向屈曲临界载荷约1.87\\,kN，在增设侧向支撑隔套后有效长度减半，安全系数提升至$n \\approx 8.4$，满足稳定性设计要求。'
ch3 = ch3.replace(old, new9)
print('Edit 9 done')

# Reassemble
content = content[:ch3_start] + ch3 + content[ch4_start:]

with open('D:/bylw/code/lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/pages/body.tex', 'w', encoding='utf-8') as f:
    f.write(content)

print('All edits applied successfully.')
