"""PID控制原理图绘制 - 使用 matplotlib"""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

# ---------- 中文字体 ----------
plt.rcParams['font.sans-serif'] = ['SimHei', 'Microsoft YaHei', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False

# ---------- 图形尺寸 ----------
fig, ax = plt.subplots(figsize=(12, 4.8))
ax.set_xlim(0, 14.5)
ax.set_ylim(0, 9.5)
ax.set_aspect('equal')
ax.axis('off')

# ---------- 颜色 ----------
box_color   = '#E6F0FF'
box_edge    = '#1A4D80'
sum_color   = '#F0F0F0'
arr_color   = '#2A2A2A'
dash_color   = '#555555'

# ---------- 辅助函数 ----------
def draw_box(cx, cy, w, h, fc=box_color, ec=box_edge):
    rect = mpatches.FancyBboxPatch((cx-w/2, cy-h/2), w, h,
            boxstyle='round,pad=0.06', fc=fc, ec=ec, lw=1.5)
    ax.add_patch(rect)

def draw_circle(cx, cy, r):
    circ = plt.Circle((cx, cy), r, fc=sum_color, ec=arr_color, lw=1.2, zorder=4)
    ax.add_patch(circ)

def draw_arrow(x1, y1, x2, y2, lw=1.5):
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
        arrowprops=dict(arrowstyle='->', color=arr_color, lw=lw))

def draw_line(x1, y1, x2, y2, lw=1.5):
    ax.plot([x1, x2], [y1, y2], '-', color=arr_color, lw=lw)

def draw_dot(x, y):
    ax.plot(x, y, 'o', color=arr_color, markersize=4, zorder=5)

# ---------- 坐标 ----------
x_ref, y_m = 1.0, 5.0      # 参考输入
x_e,   _   = 3.0, 5.0      # 比较点
x_fork,_   = 4.0, 5.0      # 分叉点
x_pid, y_p = 5.5, 7.2      # P 分支
_,     y_i = 5.5, 5.0      # I 分支
_,     y_d = 5.5, 2.8      # D 分支
x_s2,  _   = 8.0, 5.0      # PID 求和点
x_pl,  _   = 10.5, 5.0     # 被控对象
x_fb0, _   = 12.0, 5.0     # 输出分叉
x_out, _   = 13.0, 5.0     # 输出
y_fb  = 7.5                # 反馈线高度
bw, bh = 0.55, 0.28        # 方框半宽半高

# ---------- 1. 方框 ----------
draw_box(x_pid, y_p, bw*2.2, bh*2)    # P
draw_box(x_pid, y_i, bw*2.2, bh*2)    # I
draw_box(x_pid, y_d, bw*2.2, bh*2)    # D
draw_box(x_pl, y_m, bw*2.2, bh*2.2, '#F4E8D0', '#8B6914')  # 被控对象
draw_box(x_pl, y_fb, bw*1.2, bh*1.4, sum_color, box_edge)   # 传感器

# ---------- 2. 圆圈 (比较点/求和点) ----------
draw_circle(x_e, y_m, 0.16)
draw_circle(x_s2, y_m, 0.18)

# ---------- 3. 文本 ----------
ax.text(x_pid, y_p, r'$K_p$', ha='center', va='center', fontsize=14)
ax.text(x_pid, y_i, r'$K_i\!\int$', ha='center', va='center', fontsize=13)
ax.text(x_pid, y_d, r'$K_d\frac{d}{dt}$', ha='center', va='center', fontsize=13)
ax.text(x_pl, y_m, '被控对象', ha='center', va='center', fontsize=11)
ax.text(x_pl, y_fb, '传感器', ha='center', va='center', fontsize=10)

ax.text(1.75, y_m+0.45, r'$r(t)$', ha='center', fontsize=13)       # 参考输入标签
ax.text(0.85, y_m-0.85, '参考输入', ha='center', fontsize=10)
ax.text(3.35, y_m+0.50, r'$e(t)$', ha='center', fontsize=13)       # 偏差
ax.text(8.85, y_m+0.50, r'$u(t)$', ha='center', fontsize=13)       # 控制量
ax.text(12.2, y_m+0.50, r'$y(t)$', ha='center', fontsize=13)       # 输出
ax.text(x_out+0.25, y_m-0.85, '输出', ha='center', fontsize=10)
ax.text(0.85, y_fb-0.60, '反馈', ha='center', fontsize=10)

# 比较点正负号
ax.text(x_e-0.50, y_m-0.38, r'$+$', fontsize=14, ha='center')
ax.text(x_e-0.35, y_m+0.45, r'$-$', fontsize=16, ha='center')
ax.text(x_s2-0.05, y_m+0.95, r'$+$', fontsize=12, ha='center')

# ---------- 4. 主通路连线 ----------
# r → 比较点
draw_arrow(x_ref, y_m, x_e-0.16, y_m)
# 比较点 → 分叉
draw_arrow(x_e+0.16, y_m, x_fork, y_m)
# 分叉 → P
draw_line(x_fork, y_m, x_fork, y_p)
draw_arrow(x_fork, y_p, x_pid-bw*1.1, y_p)
# 分叉 → I
draw_line(x_fork, y_m, x_pid-bw*1.1, y_m)
# 分叉 → D
draw_line(x_fork, y_m, x_fork, y_d)
draw_arrow(x_fork, y_d, x_pid-bw*1.1, y_d)
draw_dot(x_fork, y_m)

# P → 求和点
draw_arrow(x_pid+bw*1.1, y_p, x_s2-0.18, y_p)
draw_line(x_s2-0.18, y_p, x_s2-0.18, y_m+0.18)
draw_dot(x_s2-0.18, y_p)
# I → 求和点
draw_arrow(x_pid+bw*1.1, y_i, x_s2-0.18, y_i)
# D → 求和点
draw_arrow(x_pid+bw*1.1, y_d, x_s2-0.18, y_d)
draw_line(x_s2-0.18, y_d, x_s2-0.18, y_m-0.18)
draw_dot(x_s2-0.18, y_d)

# 求和点 → 被控对象
draw_arrow(x_s2+0.18, y_m, x_pl-bw*1.1, y_m)
# 被控对象 → 输出
draw_arrow(x_pl+bw*1.1, y_m, x_out, y_m)

# ---------- 5. 反馈通路 ----------
draw_dot(x_fb0, y_m)
draw_line(x_fb0, y_m, x_fb0, y_fb)
draw_arrow(x_fb0, y_fb, x_pl+bw*0.6, y_fb)       # → 传感器
draw_arrow(x_pl-bw*0.6, y_fb, 2.2, y_fb)          # ← 传感器
draw_line(2.2, y_fb, 2.2, y_m)
draw_arrow(2.2, y_m, x_e-0.16, y_m)

# ---------- 6. PID 虚线框 ----------
x_l, x_r = x_fork-0.22, x_s2+0.35
y_t, y_b = y_p+bh+0.25, y_d-bh-0.30
ax.plot([x_l, x_r, x_r, x_l, x_l], [y_t, y_t, y_b, y_b, y_t],
        '--', color=dash_color, lw=1.0)
ax.text(x_pid, y_t+0.30, 'PID 控制器', ha='center', fontsize=11, color='#333333')

# ---------- 7. 保存 ----------
plt.tight_layout(pad=0.5)
out_path = r'D:\bylw\code\lunwen\QLULatex\QLUThesisLatexTemplate-master\Thesis\static\figures\pid.png'
fig.savefig(out_path, dpi=200, bbox_inches='tight', facecolor='white', edgecolor='none')
print(f'PID 原理图已保存: {out_path}')
plt.close()
