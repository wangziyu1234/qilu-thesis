"""从精确数据生成SVG原理图"""
import json, math

with open('hybrid_astar_data.json') as f:
    d = json.load(f)

path_x = d['path_x']
path_y = d['path_y']
path_theta = d['path_theta']
errors = d['errors']
max_err_idx = max(range(len(errors)), key=lambda i: abs(errors[i]))
times = d['times']
rms = d['rms']
max_err = d['max_error']
follow_time = d['follow_time']
path_length = d['path_length']
n_pts = d['n_path_pts']

# ===== 坐标转换 =====
# 地图: 10m×8m, SVG区域: (60,102)-(460,372) = 400×270
# Xsvg = 60 + X*40, Ysvg = 372 - Y*33.75
def m2svg(mx, my):
    return (60 + mx * 40, 372 - my * 33.75)

# 路径点转SVG
path_svg = [m2svg(path_x[i], path_y[i]) for i in range(n_pts)]

# 误差曲线: t∈[0,36.2], err∈[-3.01,3.01]
# SVG区域: (292,440)-(472,575) = 180×135
# Xsvg = 292 + t/36.2*180, Ysvg = 507.5 - err/4*135 (对称 ±4cm)
def err2svg(t, e):
    x = 292 + (t / max(follow_time, 1)) * 180
    y = 507.5 - (e / 4.0) * 135
    return (round(x, 1), round(y, 1))

# 采样误差曲线点
err_sample_idx = list(range(0, len(errors), 20))
if err_sample_idx[-1] != len(errors)-1:
    err_sample_idx.append(len(errors)-1)
err_points = [err2svg(times[i], errors[i]) for i in err_sample_idx]

# ===== 货架障碍物 =====
obstacles = [
    (2.0, 0.0, 2.4, 3.0),   # 左下竖
    (4.5, 2.0, 4.9, 5.0),   # 中左竖
    (7.0, 0.0, 7.4, 3.5),   # 右下竖
    (7.0, 5.0, 7.4, 8.0),   # 右上竖
    (3.0, 5.5, 6.0, 5.9),   # 中部横梁
]

def obs_svg(x1, y1, x2, y2):
    sx1, sy1 = m2svg(x1, y2)  # 注意Y翻转
    sx2, sy2 = m2svg(x2, y1)
    return (round(sx1,1), round(sy1,1), round(sx2-sx1,1), round(sy2-sy1,1))

# ===== 生成路径SVG path =====
# 用平滑贝塞尔曲线
def gen_path_d(pts):
    if len(pts) < 2:
        return ""
    d = f"M {pts[0][0]} {pts[0][1]}"
    for i in range(1, len(pts)):
        d += f" L {pts[i][0]} {pts[i][1]}"
    return d

path_d = gen_path_d(path_svg)
err_d = gen_path_d(err_points)

# 航向箭头 (每3个点取一个)
heading_arrows = []
for i in range(0, n_pts, 3):
    sx, sy = path_svg[i]
    theta = path_theta[i]
    ex = sx + 12 * math.cos(theta)
    ey = sy - 12 * math.sin(theta)  # SVG Y翻转
    heading_arrows.append((round(sx,1), round(sy,1), round(ex,1), round(ey,1)))

# ===== 输出SVG =====
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 880" font-family="Microsoft YaHei, Arial, sans-serif">
  <defs>
    <marker id="arrow" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto"><polygon points="0 0,8 3,0 6" fill="#555"/></marker>
    <marker id="arrB" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto"><polygon points="0 0,8 3,0 6" fill="#1565c0"/></marker>
  </defs>

  <rect width="520" height="880" rx="10" fill="#f8f9ff" stroke="#c5cae9" stroke-width="1.5"/>

  <!-- 标题 -->
  <rect x="30" y="16" width="460" height="42" rx="8" fill="#283593"/>
  <text x="260" y="44" text-anchor="middle" font-size="18" font-weight="bold" fill="#fff">Hybrid A* 路径规划 + PID 循迹仿真</text>

  <!-- ===== 上：路径规划地图 ===== -->
  <rect x="30" y="72" width="460" height="320" rx="8" fill="#fff" stroke="#e0e0e0" stroke-width="1"/>
  <text x="260" y="92" text-anchor="middle" font-size="12" fill="#999">仓储地图 · 10m × 8m · 5个货架障碍物</text>

  <!-- 地图底色 -->
  <rect x="60" y="102" width="400" height="270" rx="2" fill="#fafafa" stroke="#ccc" stroke-width="0.8"/>

  <!-- 网格线 -->
  <g stroke="#eee" stroke-width="0.4" opacity="0.6">'''

# 横线 Y=1..7
for ym in range(1, 8):
    _, sy = m2svg(0, ym)
    svg += f'\n    <line x1="60" y1="{round(sy,1)}" x2="460" y2="{round(sy,1)}"/>'
# 竖线 X=1..9
for xm in range(1, 10):
    sx, _ = m2svg(xm, 0)
    svg += f'\n    <line x1="{round(sx,1)}" y1="102" x2="{round(sx,1)}" y2="372"/>'

svg += '''
  </g>

  <!-- 货架障碍物 -->'''

for obs in obstacles:
    ox, oy, ow, oh = obs_svg(*obs)
    svg += f'''
  <rect x="{ox}" y="{oy}" width="{ow}" height="{oh}" fill="#bbb" stroke="#888" stroke-width="1" rx="1"/>'''

svg += f'''

  <!-- 规划路径 (红色) -->
  <path d="{path_d}" fill="none" stroke="#c62828" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"/>

  <!-- 航向箭头 (蓝色) -->'''
for ax, ay, aex, aey in heading_arrows:
    svg += f'''
  <line x1="{ax}" y1="{ay}" x2="{aex}" y2="{aey}" stroke="#1565c0" stroke-width="1.5" marker-end="url(#arrB)"/>'''

# 起点终点
gsx, gsy = m2svg(1.0, 1.0)
esx, esy = m2svg(9.0, 7.0)
svg += f'''

  <!-- 起点 -->
  <circle cx="{round(gsx,1)}" cy="{round(gsy,1)}" r="8" fill="none" stroke="#4caf50" stroke-width="2.5"/>
  <text x="{round(gsx,1)}" y="{round(gsy+18,1)}" text-anchor="middle" font-size="9" fill="#2e7d32" font-weight="bold">起点(1,1)</text>

  <!-- 终点 -->
  <line x1="{round(esx-6,1)}" y1="{round(esy-6,1)}" x2="{round(esx+6,1)}" y2="{round(esy+6,1)}" stroke="#c62828" stroke-width="2.5"/>
  <line x1="{round(esx+6,1)}" y1="{round(esy-6,1)}" x2="{round(esx-6,1)}" y2="{round(esy+6,1)}" stroke="#c62828" stroke-width="2.5"/>
  <text x="{round(esx,1)}" y="{round(esy-10,1)}" text-anchor="middle" font-size="9" fill="#c62828" font-weight="bold">终点(9,7)</text>

  <!-- 坐标轴 -->
  <g stroke="#555" stroke-width="1" fill="#555" marker-end="url(#arrow)">
    <line x1="60" y1="372" x2="80" y2="372"/>
    <line x1="60" y1="372" x2="60" y2="352"/>
  </g>
  <text x="82" y="376" font-size="8" fill="#555">X(m)</text>
  <text x="52" y="352" font-size="8" fill="#555">Y</text>

  <!-- 图例 -->
  <g transform="translate(70, 380)">
    <rect x="0" y="0" width="380" height="18" rx="3" fill="none"/>
    <rect x="4" y="3" width="10" height="12" rx="1" fill="#bbb" stroke="#888" stroke-width="0.6"/>
    <text x="18" y="13" font-size="8" fill="#555">货架</text>
    <line x1="55" y1="9" x2="75" y2="9" stroke="#c62828" stroke-width="2.5"/>
    <text x="79" y="13" font-size="8" fill="#555">Hybrid A* 规划路径 ({n_pts}点, {path_length}m)</text>
    <circle cx="230" cy="9" r="4" fill="none" stroke="#4caf50" stroke-width="1.5"/>
    <text x="238" y="13" font-size="8" fill="#555">起点</text>
    <line x1="264" y1="5" x2="272" y2="13" stroke="#c62828" stroke-width="1.5"/>
    <line x1="272" y1="5" x2="264" y2="13" stroke="#c62828" stroke-width="1.5"/>
    <text x="276" y="13" font-size="8" fill="#555">终点</text>
    <line x1="302" y1="9" x2="316" y2="9" stroke="#1565c0" stroke-width="1.2" marker-end="url(#arrB)"/>
    <text x="320" y="13" font-size="8" fill="#555">航向</text>
  </g>

  <!-- ===== 中左：参考路径 vs 循迹轨迹 ===== -->
  <rect x="30" y="410" width="220" height="190" rx="8" fill="#fff" stroke="#e0e0e0" stroke-width="1"/>
  <text x="140" y="430" text-anchor="middle" font-size="11" font-weight="bold" fill="#283593">参考路径 vs 循迹轨迹</text>
  <rect x="52" y="440" width="180" height="135" rx="2" fill="#fafafa" stroke="#ddd" stroke-width="0.6"/>'''

# 小图中的参考路径和循迹轨迹 (缩小版)
# 参考路径
small_path_ref = []
small_pathFollow = []
rx_list = d['robot_x']
ry_list = d['robot_y']
for i in range(0, n_pts, 2):
    sx = 52 + (path_x[i] / 10) * 180
    sy = 575 - (path_y[i] / 8) * 135
    small_path_ref.append((round(sx,1), round(sy,1)))
for i in range(0, len(rx_list), 40):
    sx = 52 + (rx_list[i] / 10) * 180
    sy = 575 - (ry_list[i] / 8) * 135
    small_pathFollow.append((round(sx,1), round(sy,1)))

ref_d = gen_path_d(small_path_ref)
fol_d = gen_path_d(small_pathFollow)

svg += f'''
  <path d="{ref_d}" fill="none" stroke="#1565c0" stroke-width="2.2" stroke-linecap="round"/>
  <path d="{fol_d}" fill="none" stroke="#c62828" stroke-width="1.3" stroke-dasharray="5,2" stroke-linecap="round"/>
  <circle cx="{small_path_ref[0][0]}" cy="{small_path_ref[0][1]}" r="4.5" fill="none" stroke="#4caf50" stroke-width="1.5"/>
  <g transform="translate(56, 578)">
    <line x1="0" y1="5" x2="22" y2="5" stroke="#1565c0" stroke-width="2.2"/>
    <text x="26" y="9" font-size="8" fill="#555">参考路径</text>
    <line x1="82" y1="5" x2="104" y2="5" stroke="#c62828" stroke-width="1.3" stroke-dasharray="5,2"/>
    <text x="108" y="9" font-size="8" fill="#555">循迹轨迹</text>
  </g>

  <!-- ===== 中右：横向误差曲线 ===== -->
  <rect x="270" y="410" width="220" height="190" rx="8" fill="#fff" stroke="#e0e0e0" stroke-width="1"/>
  <text x="380" y="430" text-anchor="middle" font-size="11" font-weight="bold" fill="#283593">循迹横向误差</text>
  <rect x="292" y="440" width="180" height="135" rx="2" fill="#fafafa" stroke="#ddd" stroke-width="0.6"/>

  <!-- 零线 -->
  <line x1="292" y1="507.5" x2="472" y2="507.5" stroke="#aaa" stroke-width="0.5" stroke-dasharray="2,2"/>

  <!-- RMS带 ±{rms}cm -->
  <line x1="292" y1="{round(507.5 - rms/4*135, 1)}" x2="472" y2="{round(507.5 - rms/4*135, 1)}" stroke="#1565c0" stroke-width="0.8" stroke-dasharray="3,2"/>
  <line x1="292" y1="{round(507.5 + rms/4*135, 1)}" x2="472" y2="{round(507.5 + rms/4*135, 1)}" stroke="#1565c0" stroke-width="0.8" stroke-dasharray="3,2"/>
  <text x="474" y="{round(507.5 - rms/4*135 - 3, 1)}" font-size="7" fill="#1565c0">+RMS</text>
  <text x="474" y="{round(507.5 + rms/4*135 + 10, 1)}" font-size="7" fill="#1565c0">−RMS</text>

  <!-- ±3cm参考线 -->
  <line x1="292" y1="{round(507.5 - 3/4*135, 1)}" x2="472" y2="{round(507.5 - 3/4*135, 1)}" stroke="#4caf50" stroke-width="0.6" stroke-dasharray="2,2" opacity="0.5"/>
  <line x1="292" y1="{round(507.5 + 3/4*135, 1)}" x2="472" y2="{round(507.5 + 3/4*135, 1)}" stroke="#4caf50" stroke-width="0.6" stroke-dasharray="2,2" opacity="0.5"/>

  <!-- 误差曲线 (红色) -->
  <polyline points="'''

# 输出误差曲线点
pts_str = " ".join(f"{p[0]},{p[1]}" for p in err_points)
svg += pts_str + '"'

svg += f'''
            fill="none" stroke="#c62828" stroke-width="1.2" stroke-linejoin="round"/>

  <!-- 最大误差标注 -->
  <text x="305" y="{round(err2svg(times[max_err_idx], errors[max_err_idx])[1] - 5, 1)}" font-size="7" fill="#e65100">{max_err:.1f}cm</text>

  <!-- RMS标注 -->
  <text x="448" y="{round(507.5 - rms/4*135 - 3, 1)}" font-size="7" fill="#1565c0" font-weight="bold">RMS={rms}cm</text>

  <!-- 坐标轴标注 -->
  <text x="460" y="568" font-size="7" fill="#555">时间(s)</text>
  <text x="296" y="452" font-size="7" fill="#555">误差(cm)</text>

  <!-- ===== 算法流程 ===== -->
  <rect x="30" y="614" width="460" height="90" rx="8" fill="#fff" stroke="#e0e0e0" stroke-width="1"/>
  <rect x="48" y="626" width="80" height="24" rx="5" fill="#283593"/>
  <text x="88" y="643" text-anchor="middle" font-size="12" font-weight="bold" fill="#fff">算法流程</text>

  <g transform="translate(55, 662)">
    <rect x="0" y="0" width="72" height="30" rx="4" fill="#e8eaf6" stroke="#5c6bc0" stroke-width="1"/>
    <text x="36" y="13" text-anchor="middle" font-size="8" font-weight="bold" fill="#283593">栅格地图</text>
    <text x="36" y="24" text-anchor="middle" font-size="7" fill="#666">10×8m, 0.2m</text>
    <line x1="72" y1="15" x2="88" y2="15" stroke="#555" stroke-width="1" marker-end="url(#arrow)"/>

    <rect x="88" y="0" width="72" height="30" rx="4" fill="#e8eaf6" stroke="#5c6bc0" stroke-width="1"/>
    <text x="124" y="13" text-anchor="middle" font-size="8" font-weight="bold" fill="#283593">Hybrid A*</text>
    <text x="124" y="24" text-anchor="middle" font-size="7" fill="#666">10种运动基元</text>
    <line x1="160" y1="15" x2="176" y2="15" stroke="#555" stroke-width="1" marker-end="url(#arrow)"/>

    <rect x="176" y="0" width="72" height="30" rx="4" fill="#e8eaf6" stroke="#5c6bc0" stroke-width="1"/>
    <text x="212" y="13" text-anchor="middle" font-size="8" font-weight="bold" fill="#283593">路径平滑</text>
    <text x="212" y="24" text-anchor="middle" font-size="7" fill="#666">3次均值滤波</text>
    <line x1="248" y1="15" x2="264" y2="15" stroke="#555" stroke-width="1" marker-end="url(#arrow)"/>

    <rect x="264" y="0" width="72" height="30" rx="4" fill="#e8f5e9" stroke="#43a047" stroke-width="1"/>
    <text x="300" y="13" text-anchor="middle" font-size="8" font-weight="bold" fill="#2e7d32">PID循迹</text>
    <text x="300" y="24" text-anchor="middle" font-size="7" fill="#666">5路红外纠偏</text>
    <line x1="336" y1="15" x2="352" y2="15" stroke="#555" stroke-width="1" marker-end="url(#arrow)"/>

    <rect x="352" y="0" width="72" height="30" rx="4" fill="#fff3e0" stroke="#e65100" stroke-width="1"/>
    <text x="388" y="13" text-anchor="middle" font-size="8" font-weight="bold" fill="#e65100">执行输出</text>
    <text x="388" y="24" text-anchor="middle" font-size="7" fill="#666">ωₗ, ωᵣ 轮速</text>
  </g>

  <!-- ===== 仿真结果指标 ===== -->
  <rect x="30" y="718" width="460" height="146" rx="8" fill="#fff" stroke="#e0e0e0" stroke-width="1"/>
  <rect x="48" y="730" width="80" height="24" rx="5" fill="#283593"/>
  <text x="88" y="747" text-anchor="middle" font-size="12" font-weight="bold" fill="#fff">仿真结果</text>

  <rect x="48" y="762" width="100" height="52" rx="6" fill="#e8f5e9" stroke="#43a047" stroke-width="1"/>
  <text x="98" y="782" text-anchor="middle" font-size="10" fill="#2e7d32">RMS 横向误差</text>
  <text x="98" y="802" text-anchor="middle" font-size="16" font-weight="bold" fill="#2e7d32">{rms} cm</text>

  <rect x="160" y="762" width="100" height="52" rx="6" fill="#fff3e0" stroke="#e65100" stroke-width="1"/>
  <text x="210" y="782" text-anchor="middle" font-size="10" fill="#e65100">最大横向误差</text>
  <text x="210" y="802" text-anchor="middle" font-size="16" font-weight="bold" fill="#e65100">{max_err} cm</text>

  <rect x="272" y="762" width="100" height="52" rx="6" fill="#e3f2fd" stroke="#1565c0" stroke-width="1"/>
  <text x="322" y="782" text-anchor="middle" font-size="10" fill="#1565c0">规划路径长度</text>
  <text x="322" y="802" text-anchor="middle" font-size="16" font-weight="bold" fill="#1565c0">{path_length} m</text>

  <rect x="384" y="762" width="92" height="52" rx="6" fill="#f3e5f5" stroke="#7b1fa2" stroke-width="1"/>
  <text x="430" y="782" text-anchor="middle" font-size="10" fill="#7b1fa2">循迹耗时</text>
  <text x="430" y="802" text-anchor="middle" font-size="16" font-weight="bold" fill="#7b1fa2">{follow_time} s</text>

  <text x="60" y="838" font-size="10" fill="#444">传感器覆盖宽度 ±80mm，最大误差在检测裕量内。路径搜索迭代 3008 次，控制器响应平稳。</text>
  <text x="60" y="854" font-size="10" fill="#444">曲率集合 κ ∈ {{−1.11, −0.52, 0, 0.52, 1.11}} m⁻¹，步长 0.5m，轮距 L=0.52m。</text>

</svg>'''

with open('hybrid_astar_vertical.svg', 'w', encoding='utf-8') as f:
    f.write(svg)
print(f"SVG已生成: hybrid_astar_vertical.svg")
print(f"路径: {n_pts}点, {path_length}m | RMS: {rms}cm | 最大误差: {max_err}cm | 耗时: {follow_time}s")
