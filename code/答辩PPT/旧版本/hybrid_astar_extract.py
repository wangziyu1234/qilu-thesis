"""复现MATLAB Hybrid A*算法，提取精确坐标用于SVG绘图"""
import numpy as np
import json, math

# ===== 地图参数 (与MATLAB一致) =====
map_w, map_h = 10, 8
res = 0.2
cols = round(map_w / res)
rows = round(map_h / res)

obstacles = np.array([
    [2.0, 0.0, 2.4, 3.0],
    [4.5, 2.0, 4.9, 5.0],
    [7.0, 0.0, 7.4, 3.5],
    [7.0, 5.0, 7.4, 8.0],
    [3.0, 5.5, 6.0, 5.9],
])

obs_map = np.zeros((rows, cols), dtype=bool)
for obs in obstacles:
    c1 = max(0, min(cols-1, round(obs[0]/res)))
    r1 = max(0, min(rows-1, round(obs[1]/res)))
    c2 = max(0, min(cols-1, round(obs[2]/res)))
    r2 = max(0, min(rows-1, round(obs[3]/res)))
    obs_map[r1:r2+1, c1:c2+1] = True

start_pos = np.array([1.0, 1.0, 0.0])
goal_pos = np.array([9.0, 7.0, math.pi/2])

# ===== 搜索参数 =====
step_len = 0.5
L = 0.52
curvatures = [-1.11, -0.52, 0, 0.52, 1.11]
n_curv = len(curvatures)
max_iter = 20000

def step_motion(x, y, theta, kappa, step, d):
    if abs(kappa) < 1e-6:
        nx = x + d*step*math.cos(theta)
        ny = y + d*step*math.sin(theta)
        nt = theta
    else:
        dtheta = d * step * kappa
        nt = theta + dtheta
        nt = math.atan2(math.sin(nt), math.cos(nt))
        nx = x + d*step*math.cos(theta + dtheta/2)
        ny = y + d*step*math.sin(theta + dtheta/2)
    return nx, ny, nt

def check_obs(x1, y1, x2, y2):
    for t_i in range(11):
        t = t_i / 10.0
        x = x1 + t*(x2-x1)
        y = y1 + t*(y2-y1)
        c = min(cols-1, max(0, round(x/res)))
        r = min(rows-1, max(0, round(y/res)))
        if obs_map[r, c]:
            return True
    return False

def is_in_list(lst, x, y, theta, tol=0.15):
    if len(lst) == 0:
        return False
    d = np.sqrt((lst[:,0]-x)**2 + (lst[:,1]-y)**2)
    a = np.abs(np.arctan2(np.sin(lst[:,2]-theta), np.cos(lst[:,2]-theta)))
    return bool(np.any((d < tol) & (a < 0.1)))

def find_in_list(lst, x, y, theta, tol=0.15):
    if len(lst) == 0:
        return -1
    d = np.sqrt((lst[:,0]-x)**2 + (lst[:,1]-y)**2)
    a = np.abs(np.arctan2(np.sin(lst[:,2]-theta), np.cos(lst[:,2]-theta)))
    idxs = np.where((d < tol) & (a < 0.1))[0]
    return int(idxs[0]) if len(idxs) > 0 else -1

# ===== 主搜索 =====
h0 = math.hypot(goal_pos[0]-start_pos[0], goal_pos[1]-start_pos[1])
OpenList = [[start_pos[0], start_pos[1], start_pos[2], h0, 0, 0, 0]]
CloseList = []

found_path = None
for iteration in range(1, max_iter+1):
    if not OpenList:
        break
    # 取f最小
    mi = min(range(len(OpenList)), key=lambda i: OpenList[i][3])
    cur = OpenList.pop(mi)
    CloseList.append(cur)
    cur_idx = len(CloseList) - 1
    cx, cy, ct, cg = cur[0], cur[1], cur[2], cur[4]

    if math.hypot(cx-goal_pos[0], cy-goal_pos[1]) < 0.5:
        # 回溯
        path_pts = []
        ci = cur_idx
        while True:
            path_pts.append([CloseList[ci][0], CloseList[ci][1], CloseList[ci][2]])
            pi = int(CloseList[ci][5])
            if pi == 0:
                path_pts.append([CloseList[0][0], CloseList[0][1], CloseList[0][2]])
                break
            ci = pi
        path_pts.reverse()
        found_path = np.array(path_pts)
        break

    for a in range(n_curv * 2):
        if a < n_curv:
            kappa = curvatures[a]
            d = 1
        else:
            kappa = curvatures[a - n_curv]
            d = -1
        nx, ny, nt = step_motion(cx, cy, ct, kappa, step_len, d)
        if nx < 0 or nx > map_w or ny < 0 or ny > map_h:
            continue
        if check_obs(cx, cy, nx, ny):
            continue
        g = cg + step_len
        if d == -1:
            g += step_len * 0.5
        if abs(kappa) > 1e-6:
            g += 0.1
        h = math.hypot(goal_pos[0]-nx, goal_pos[1]-ny)
        f = g + h
        if is_in_list(np.array(CloseList), nx, ny, nt):
            continue
        oi = find_in_list(np.array(OpenList), nx, ny, nt)
        if oi >= 0:
            if f < OpenList[oi][3]:
                OpenList[oi] = [nx, ny, nt, f, g, cur_idx, a]
            continue
        OpenList.append([nx, ny, nt, f, g, cur_idx, a])

    if iteration % 2000 == 0:
        print(f"  iter {iteration}, Open: {len(OpenList)}, Close: {len(CloseList)}")

if found_path is None:
    print("未找到路径!")
    exit(1)

print(f"找到路径! 迭代 {iteration}, 节点数 {len(found_path)}")

# ===== 均值平滑 (3次) =====
sp = found_path.copy()
for pass_i in range(3):
    tmp = sp.copy()
    for i in range(1, len(sp)-1):
        tmp[i,0] = 0.25*sp[i-1,0] + 0.5*sp[i,0] + 0.25*sp[i+1,0]
        tmp[i,1] = 0.25*sp[i-1,1] + 0.5*sp[i,1] + 0.25*sp[i+1,1]
    sp = tmp
for i in range(len(sp)-1):
    sp[i,2] = math.atan2(sp[i+1,1]-sp[i,1], sp[i+1,0]-sp[i,0])
sp[-1,2] = sp[-2,2]

path_len = sum(math.hypot(sp[i+1,0]-sp[i,0], sp[i+1,1]-sp[i,1]) for i in range(len(sp)-1))
print(f"平滑后路径点数: {len(sp)}, 长度: {path_len:.2f} m")

# ===== 等间距插值 (0.05m) =====
interp_pts = [sp[0].tolist()]
for i in range(len(sp)-1):
    seg_len = math.hypot(sp[i+1,0]-sp[i,0], sp[i+1,1]-sp[i,1])
    n_sub = max(1, round(seg_len / 0.05))
    for j in range(1, n_sub+1):
        t = j / n_sub
        x = sp[i,0] + t*(sp[i+1,0]-sp[i,0])
        y = sp[i,1] + t*(sp[i+1,1]-sp[i,1])
        theta = sp[i,2] + t*(sp[i+1,2]-sp[i,2])
        interp_pts.append([x, y, theta])
interp_path = np.array(interp_pts)
print(f"插值后路径点数: {len(interp_path)}")

# ===== PID循迹仿真 (与MATLAB tracking_pid.m完全一致) =====
Kp, Ki, Kd = 3.0, 0.08, 1.0
v_nom = 0.3
dt = 0.01        # MATLAB: dt=0.01
max_time = 80.0
fwd = 0.08       # 传感器距车体前端距离(m)

n_sensors = 5
sensor_spacing = 0.04
sensor_offsets_arr = np.array([-2, -1, 0, 1, 2]) * sensor_spacing  # [-0.08,-0.04,0,0.04,0.08]
sensor_weights_arr = np.array([-4, -2, 0, 2, 4])
line_width = 0.03  # 黑线宽度(m)

def point_to_path(px, py, path_x, path_y):
    """点到折线段最短距离 (与MATLAB一致)"""
    d_min = float('inf')
    n = len(path_x)
    for i in range(n-1):
        ax, ay = path_x[i], path_y[i]
        bx, by = path_x[i+1], path_y[i+1]
        abx, aby = bx-ax, by-ay
        apx, apy = px-ax, py-ay
        ab2 = abx*abx + aby*aby
        if ab2 < 1e-10:
            t = 0
        else:
            t = max(0.0, min(1.0, (apx*abx+apy*aby)/ab2))
        cx = ax + t*abx
        cy = ay + t*aby
        dd = math.hypot(px-cx, py-cy)
        if dd < d_min:
            d_min = dd
    return d_min

# 初始化
x, y, theta = interp_path[0,0], interp_path[0,1], interp_path[0,2]
e_int = 0.0
e_prev = 0.0
times, errors, omegas = [], [], []
robot_x_list, robot_y_list = [x], [y]

ref_px = interp_path[:,0]
ref_py = interp_path[:,1]

n_steps = int(max_time / dt)
for step_i in range(n_steps):
    t_now = step_i * dt

    # 传感器全局坐标 (与MATLAB一致)
    sx = x + fwd*math.cos(theta) + sensor_offsets_arr * math.cos(theta + math.pi/2)
    sy = y + fwd*math.sin(theta) + sensor_offsets_arr * math.sin(theta + math.pi/2)

    # 传感器状态
    sensor_state = np.zeros(n_sensors)
    for s in range(n_sensors):
        d = point_to_path(sx[s], sy[s], ref_px, ref_py)
        if d < line_width:
            sensor_state[s] = 1

    active = np.where(sensor_state == 1)[0]
    if len(active) > 0:
        offset = np.mean(sensor_weights_arr[active])
    else:
        offset = e_prev * 1.5

    # 横向误差 (用于记录)
    dists2 = (ref_px - x)**2 + (ref_py - y)**2
    min_i = np.argmin(dists2)
    tang = interp_path[min_i, 2]
    lat_err = -(x - ref_px[min_i])*math.sin(tang) + (y - ref_py[min_i])*math.cos(tang)

    # PID (与MATLAB一致)
    e_int += offset * dt
    e_int = max(-2.0, min(2.0, e_int))  # 积分限幅
    e_der = (offset - e_prev) / dt
    e_prev = offset

    omega = Kp * offset + Ki * e_int + Kd * e_der
    omega = max(-1.5, min(1.5, omega))

    # 运动学更新
    x += v_nom * math.cos(theta) * dt
    y += v_nom * math.sin(theta) * dt
    theta += omega * dt
    theta = math.atan2(math.sin(theta), math.cos(theta))

    times.append(t_now)
    errors.append(lat_err * 100)  # cm
    omegas.append(omega)
    robot_x_list.append(x)
    robot_y_list.append(y)

    # 到终点则停
    if math.hypot(x - ref_px[-1], y - ref_py[-1]) < 0.2:
        break

errors = np.array(errors)
rms = np.sqrt(np.mean(errors**2))
max_err = np.max(np.abs(errors))
print(f"循迹完成: {len(times)}步, RMS={rms:.2f}cm, 最大误差={max_err:.2f}cm, 时长={times[-1]:.1f}s")

# ===== 输出数据 =====
data = {
    "path_x": sp[:,0].tolist(),
    "path_y": sp[:,1].tolist(),
    "path_theta": sp[:,2].tolist(),
    "interp_x": interp_path[:,0].tolist(),
    "interp_y": interp_path[:,1].tolist(),
    "robot_x": robot_x_list,
    "robot_y": robot_y_list,
    "times": times,
    "errors": errors.tolist(),
    "omegas": omegas,
    "path_length": round(path_len, 2),
    "rms": round(float(rms), 2),
    "max_error": round(float(max_err), 2),
    "n_path_pts": len(sp),
    "n_interp_pts": len(interp_path),
    "n_follow_steps": len(times),
    "follow_time": round(times[-1], 1) if times else 0,
}

with open("hybrid_astar_data.json", "w") as f:
    json.dump(data, f, indent=2)
print(f"\n数据已保存到 hybrid_astar_data.json")
print(f"路径长度: {path_len:.2f}m, 路径点数: {len(sp)}, 迭代: {iteration}")
print(f"RMS: {rms:.2f}cm, 最大误差: {max_err:.2f}cm")
