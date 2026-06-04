const fs = require('fs');
const path = require('path');
const PptxGenJS = require('pptxgenjs');

const pptx = new PptxGenJS();
pptx.layout = 'LAYOUT_WIDE';
pptx.author = 'GitHub Copilot';
pptx.company = 'bylw';
pptx.subject = '答辩PPT';
pptx.title = '智能仓储举升式AGV小车的设计与控制研究';
pptx.lang = 'zh-CN';

const W = 13.333;
const H = 7.5;
const ROOT = 'd:/bylw/code';
const FIG1 = path.join(ROOT, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures');
const FIG2 = path.join(ROOT, 'fangzhen/figures');
const OUT = path.join(ROOT, '答辩PPT/答辩PPT_图文并茂.pptx');

const C = {
  navy: '1A365D',
  navy2: '0C2D53',
  gold: 'E8C547',
  ink: '1A202C',
  text: '2D3748',
  muted: '718096',
  line: 'E2E8F0',
  paper: 'F7FAFC',
  white: 'FFFFFF',
  green: '2F855A',
  red: 'C53030',
};

function img(dir, name) {
  return path.join(dir, name);
}

function exists(filePath) {
  return fs.existsSync(filePath);
}

function addBg(slide, dark = false) {
  slide.background = { color: dark ? C.navy2 : C.white };
  if (!dark) {
    slide.addShape(pptx.ShapeType.rect, {
      x: 0,
      y: 0,
      w: W,
      h: 0.1,
      line: { color: C.gold, transparency: 100 },
      fill: { color: C.gold },
    });
  }
}

function addHeader(slide, no, title, subtitle = '') {
  slide.addShape(pptx.ShapeType.rect, {
    x: 0,
    y: 0,
    w: W,
    h: 0.56,
    line: { color: C.navy2, transparency: 100 },
    fill: { color: C.navy2 },
  });
  slide.addShape(pptx.ShapeType.rect, {
    x: 0,
    y: 0.56,
    w: W,
    h: 0.06,
    line: { color: C.gold, transparency: 100 },
    fill: { color: C.gold },
  });
  slide.addShape(pptx.ShapeType.roundRect, {
    x: 0.38,
    y: 0.82,
    w: 0.78,
    h: 0.42,
    rectRadius: 0.05,
    line: { color: C.gold, transparency: 100 },
    fill: { color: C.gold },
  });
  slide.addText(String(no).padStart(2, '0'), {
    x: 0.38,
    y: 0.88,
    w: 0.78,
    h: 0.14,
    margin: 0,
    align: 'center',
    fontFace: 'Arial',
    fontSize: 12,
    bold: true,
    color: C.navy2,
  });
  slide.addText(title, {
    x: 1.3,
    y: 0.82,
    w: 9.0,
    h: 0.24,
    margin: 0,
    fontFace: 'Microsoft YaHei',
    fontSize: 18,
    bold: true,
    color: C.white,
  });
  if (subtitle) {
    slide.addText(subtitle, {
      x: 1.3,
      y: 1.07,
      w: 9.0,
      h: 0.14,
      margin: 0,
      fontFace: 'Microsoft YaHei',
      fontSize: 8.5,
      color: 'DDE8F5',
    });
  }
  slide.addText(`${no}/10`, {
    x: 12.0,
    y: 0.9,
    w: 0.86,
    h: 0.14,
    margin: 0,
    align: 'right',
    fontFace: 'Arial',
    fontSize: 10,
    color: 'D6E1F2',
  });
}

function footer(slide, text = '齐鲁工业大学本科毕业论文（设计）答辩') {
  slide.addText(text, {
    x: 0.38,
    y: 7.08,
    w: 5.8,
    h: 0.12,
    margin: 0,
    fontFace: 'Microsoft YaHei',
    fontSize: 8,
    color: C.muted,
  });
}

function rectCard(slide, x, y, w, h, fill = C.white, line = C.line) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x,
    y,
    w,
    h,
    rectRadius: 0.06,
    line: { color: line, pt: 1.1 },
    fill: { color: fill },
  });
}

function tag(slide, text, x, y, w, fill = C.navy, color = C.white) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x,
    y,
    w,
    h: 0.22,
    rectRadius: 0.04,
    line: { color: fill, transparency: 100 },
    fill: { color: fill },
  });
  slide.addText(text, {
    x,
    y: y + 0.01,
    w,
    h: 0.12,
    margin: 0,
    align: 'center',
    fontFace: 'Microsoft YaHei',
    fontSize: 8.5,
    bold: true,
    color,
  });
}

function picture(slide, rel, x, y, w, h) {
  const filePath = rel.includes('d:/') || rel.includes('d:\\') ? rel : (rel.startsWith('fangzhen/') ? path.join(ROOT, rel) : path.join(ROOT, rel));
  if (!exists(filePath)) return false;
  slide.addImage({ path: filePath, x, y, w, h });
  return true;
}

function metric(slide, x, y, w, h, value, unit, title, accent = C.navy) {
  rectCard(slide, x, y, w, h, C.white);
  slide.addShape(pptx.ShapeType.rect, {
    x,
    y,
    w,
    h: 0.08,
    line: { color: accent, transparency: 100 },
    fill: { color: accent },
  });
  slide.addText(value, {
    x: x + 0.08,
    y: y + 0.12,
    w: w - 0.16,
    h: 0.28,
    margin: 0,
    align: 'center',
    fontFace: 'Arial',
    fontSize: 18,
    bold: true,
    color: accent,
  });
  slide.addText(unit, {
    x: x + 0.08,
    y: y + 0.39,
    w: w - 0.16,
    h: 0.12,
    margin: 0,
    align: 'center',
    fontFace: 'Microsoft YaHei',
    fontSize: 8,
    color: C.muted,
  });
  slide.addText(title, {
    x: x + 0.08,
    y: y + 0.53,
    w: w - 0.16,
    h: 0.16,
    margin: 0,
    align: 'center',
    fontFace: 'Microsoft YaHei',
    fontSize: 8.5,
    color: C.text,
    bold: true,
  });
}

function bullets(slide, lines, x, y, w, h, color = C.text, size = 11.5) {
  slide.addText(lines.map((line, idx) => ({
    text: line,
    options: { bullet: { indent: 12 }, breakLine: idx !== lines.length - 1 },
  })), {
    x,
    y,
    w,
    h,
    margin: 0,
    fontFace: 'Microsoft YaHei',
    fontSize: size,
    color,
    fit: 'shrink',
    valign: 'top',
    paraSpaceAfterPt: 6,
  });
}

async function main() {
  // 1. 封面
  {
    const slide = pptx.addSlide();
    addBg(slide, true);
    slide.addShape(pptx.ShapeType.rect, {
      x: 0,
      y: 0,
      w: 4.2,
      h: H,
      line: { color: C.navy2, transparency: 100 },
      fill: { color: C.navy2 },
    });
    slide.addShape(pptx.ShapeType.rect, {
      x: 0,
      y: 0,
      w: 4.2,
      h: 0.16,
      line: { color: C.gold, transparency: 100 },
      fill: { color: C.gold },
    });
    slide.addText('答辩PPT', { x: 0.58, y: 0.55, w: 1.0, h: 0.18, margin: 0, fontFace: 'Arial', fontSize: 15, bold: true, color: C.gold });
    slide.addText('智能仓储举升式AGV小车\n的设计与控制研究', {
      x: 0.58,
      y: 1.18,
      w: 3.28,
      h: 1.3,
      margin: 0,
      fontFace: 'Microsoft YaHei',
      fontSize: 19.5,
      bold: true,
      color: C.white,
      fit: 'shrink',
    });
    slide.addText('基于双轮差速驱动、剪叉式举升机构与双闭环 PID 控制', {
      x: 0.58,
      y: 2.48,
      w: 3.1,
      h: 0.32,
      margin: 0,
      fontFace: 'Microsoft YaHei',
      fontSize: 11,
      color: 'DDE8F5',
      fit: 'shrink',
    });
    slide.addText('机械工程学院  |  机器人（SI）22-2  |  王子煜', {
      x: 0.58,
      y: 2.76,
      w: 3.2,
      h: 0.16,
      margin: 0,
      fontFace: 'Microsoft YaHei',
      fontSize: 8.8,
      color: 'DDE8F5',
      fit: 'shrink',
    });
    slide.addText('指导教师：刘鹏博', {
      x: 0.58,
      y: 2.98,
      w: 2.0,
      h: 0.14,
      margin: 0,
      fontFace: 'Microsoft YaHei',
      fontSize: 8.8,
      color: 'DDE8F5',
    });
    rectCard(slide, 0.58, 3.42, 3.05, 1.2, '153055', '355B8A');
    slide.addText('50 kg 额定载荷\n0.4 m 升降行程\n30 m/min 最大速度', {
      x: 0.82,
      y: 3.66,
      w: 2.58,
      h: 0.48,
      margin: 0,
      fontFace: 'Arial',
      fontSize: 14,
      bold: true,
      color: C.white,
      align: 'center',
      fit: 'shrink',
    });
    metric(slide, 0.58, 5.28, 0.95, 0.95, '50', 'kg', '额定载荷', C.gold);
    metric(slide, 1.65, 5.28, 0.95, 0.95, '0.4', 'm', '升降行程', C.gold);
    metric(slide, 2.72, 5.28, 0.95, 0.95, '30', 'm/min', '最大速度', C.gold);
    slide.addText('毕业设计答辩 / 2026', { x: 0.58, y: 6.58, w: 2.2, h: 0.14, margin: 0, fontFace: 'Microsoft YaHei', fontSize: 9, color: 'DDE8F5' });
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/机械总装.png', 4.65, 0.65, 8.2, 5.85);
    slide.addShape(pptx.ShapeType.roundRect, {
      x: 4.92,
      y: 5.95,
      w: 7.7,
      h: 0.48,
      rectRadius: 0.04,
      line: { color: '365B8A', pt: 1 },
      fill: { color: '123055', transparency: 10 },
    });
    slide.addText('本科毕业论文（设计）答辩', { x: 5.1, y: 6.07, w: 2.6, h: 0.12, margin: 0, fontFace: 'Microsoft YaHei', fontSize: 9.5, color: C.white });
    slide.addText('结构设计 · 运动建模 · 路径规划 · PID 控制', { x: 7.9, y: 6.07, w: 4.4, h: 0.12, margin: 0, align: 'right', fontFace: 'Microsoft YaHei', fontSize: 9.5, color: 'DDE8F5' });
  }

  // 2. 目录
  {
    const slide = pptx.addSlide();
    slide.background = { color: C.paper };
    addHeader(slide, 0, '汇报目录', '将论文内容压缩为 6 个板块，方便答辩时快速切换');
    const x = [0.55, 2.72, 4.89, 7.06, 9.23, 11.4];
    const items = [
      ['01', '研究背景\n与目标', '仓储需求与设计任务'],
      ['02', '总体方案\n设计', '底盘、升降、控制架构'],
      ['03', '机械结构\n设计', '剪叉机构与强度校核'],
      ['04', '电气系统\n设计', '主控、电机与传感器'],
      ['05', '建模、规划\n与控制', '运动学、Hybrid A*、PID'],
      ['06', '结论与\n展望', '成果总结与后续工作'],
    ];
    items.forEach((it, i) => {
      rectCard(slide, x[i], 1.85, 1.85, 1.42);
      tag(slide, it[0], x[i] + 0.17, 1.99, 0.48, C.navy, C.white);
      slide.addText(it[1], { x: x[i] + 0.1, y: 2.55, w: 1.65, h: 0.42, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 11, bold: true, color: C.ink, fit: 'shrink' });
      slide.addText(it[2], { x: x[i] + 0.12, y: 2.98, w: 1.6, h: 0.16, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 8.2, color: C.muted });
    });
    const bottom = [
      ['AGV.png', '整车概念'],
      ['jiagou.png', '机械结构'],
      ['sensor_layout.png', '传感器布局'],
      ['hybrid_astar_result.png', '路径规划'],
    ];
    bottom.forEach((item, i) => {
      const bx = 0.75 + i * 3.12;
      rectCard(slide, bx, 4.18, 2.56, 2.0);
      picture(slide, `lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/${item[0]}`, bx + 0.12, 4.31, 2.32, 1.42);
      slide.addText(item[1], { x: bx + 0.1, y: 5.78, w: 2.36, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 8.8, color: C.muted });
    });
    footer(slide);
  }

  // 3. 背景与目标
  {
    const slide = pptx.addSlide();
    addBg(slide, false);
    addHeader(slide, 1, '研究背景、国内外现状与目标', '国内外研究现状压缩为一页，后面重点放在总体方案、结构与控制结果');
    rectCard(slide, 0.5, 1.62, 4.55, 5.3, C.white);
    tag(slide, '研究背景', 0.76, 1.9, 1.0, C.gold, C.ink);
    bullets(slide, [
      '仓储搬运对效率、柔性和安全性的要求持续提升。',
      '固定通道与动态人机混行并存，传统人工搬运难以兼顾效率与稳定性。',
      '中小型仓库更需要结构紧凑、成本可控的举升式 AGV。',
    ], 0.76, 2.24, 3.9, 1.15, C.text, 11.2);
    slide.addText('国内外研究现状', { x: 0.76, y: 3.18, w: 1.2, h: 0.14, margin: 0, fontFace: 'Microsoft YaHei', fontSize: 10, bold: true, color: C.navy });
    bullets(slide, [
      '国外在 AMR、SLAM、Hybrid A* 和多机协同方面研究较成熟。',
      '国内在仓储 AGV 产业化上进展快，但系统性集成与复杂工况验证仍需加强。',
      '举升式 AGV 将搬运与升降结合，属于更贴近本课题的工程落地方向。',
    ], 0.76, 3.4, 3.88, 1.12, C.text, 10.2);
    metric(slide, 0.78, 3.75, 1.18, 1.15, '50', 'kg', '额定载荷', C.navy);
    metric(slide, 2.06, 3.75, 1.18, 1.15, '452', 'mm', '升降行程', C.navy);
    metric(slide, 3.34, 3.75, 1.18, 1.15, '30', 'm/min', '最高速度', C.navy);
    slide.addText('设计任务', { x: 0.76, y: 5.12, w: 1.0, h: 0.14, margin: 0, fontFace: 'Microsoft YaHei', fontSize: 10, bold: true, color: C.navy });
    bullets(slide, [
      '采用双轮差速驱动，保证狭窄通道内转向灵活。',
      '采用剪叉式举升机构，兼顾承载能力与收拢高度。',
      '采用 Hybrid A* 与双闭环 PID，提高路径跟踪精度。',
    ], 0.76, 5.34, 3.85, 1.05, C.text, 10.8);

    rectCard(slide, 5.3, 1.62, 3.0, 5.3, C.white);
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/AGV.png', 5.58, 2.0, 2.46, 2.35);
    slide.addText('机器人概念图', { x: 5.55, y: 4.42, w: 2.52, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 8.8, color: C.muted });
    bullets(slide, [
      '底盘、升降、控制三部分协同设计。',
      '在 50 kg 额定载荷下完成稳定搬运。',
      '满足仓储通道尺寸与部署成本约束。',
    ], 5.57, 4.74, 2.42, 1.0, C.text, 10.4);

    rectCard(slide, 8.5, 1.62, 4.3, 5.3, C.white);
    tag(slide, '关键结果', 8.76, 1.9, 1.0, C.gold, C.ink);
    metric(slide, 8.74, 2.24, 1.16, 1.18, '5.56', 'MPa', '臂杆最危险工况应力', C.green);
    metric(slide, 10.02, 2.24, 1.16, 1.18, '14.1', 'MPa', '平台 von Mises 应力', C.green);
    metric(slide, 11.3, 2.24, 1.16, 1.18, '10.1', '-', '侧向支撑后屈曲系数', C.green);
    slide.addText('结构安全裕度充足，后续重点转向路径规划和轨迹控制。', { x: 8.8, y: 3.76, w: 3.6, h: 0.26, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 11.5, bold: true, color: C.text, fit: 'shrink' });
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/jiagou.png', 8.84, 4.14, 2.82, 1.76);
    slide.addText('整体结构示意', { x: 8.8, y: 5.96, w: 2.9, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 8.8, color: C.muted });
    footer(slide);
  }

  // 4. 总体设计
  {
    const slide = pptx.addSlide();
    slide.background = { color: C.paper };
    addHeader(slide, 2, '总体设计方案', '从驱动、举升到控制与规划，按“底盘 - 承载 - 大脑”三层组织系统');
    const x = [0.55, 4.48, 8.41];
    const titles = ['驱动方案', '升降机构', '控制与规划'];
    const pics = ['chasu.png', 'jiagou.png', 'dual_loop_pid.png'];
    const desc = [
      '双轮差速驱动适合狭窄通道和原地转向。',
      '剪叉式举升机构兼顾载荷、行程和收拢高度。',
      'Hybrid A* 规划与双闭环 PID 协同实现路径跟踪。',
    ];
    x.forEach((vx, idx) => {
      rectCard(slide, vx, 1.78, 3.26, 4.7);
      tag(slide, titles[idx], vx + 0.18, 2.0, 1.05, C.navy, C.white);
      picture(slide, `lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/${pics[idx]}`, vx + 0.2, 2.38, 2.86, 2.18);
      slide.addText(desc[idx], { x: vx + 0.18, y: 4.78, w: 2.9, h: 0.42, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 11.2, bold: true, color: C.text, fit: 'shrink' });
      slide.addText(idx === 0 ? '选择理由：灵活性高' : idx === 1 ? '选择理由：结构紧凑' : '选择理由：跟踪精度高', { x: vx + 0.18, y: 5.32, w: 2.9, h: 0.14, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9, color: C.muted });
    });
    rectCard(slide, 0.55, 6.62, 12.3, 0.42, '1B2F4A', '1B2F4A');
    slide.addText('总体方案以差速底盘为基础，配合剪叉式举升和双闭环 PID 控制，适合中小型仓储场景的短距离高频搬运任务。', { x: 0.82, y: 6.75, w: 11.75, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9.4, color: C.white });
    footer(slide);
  }

  // 5. 机械结构
  {
    const slide = pptx.addSlide();
    slide.background = { color: C.white };
    addHeader(slide, 3, '机械结构设计', '重点展示剪叉式举升机构、结构布置与强度校核结果');
    rectCard(slide, 0.55, 1.72, 4.2, 5.38);
    tag(slide, '剪叉机构运动状态', 0.8, 1.98, 1.55, C.gold, C.ink);
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/jiagou_low.png', 0.8, 2.4, 1.75, 1.92);
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/jiagou_high.png', 2.6, 2.4, 1.75, 1.92);
    slide.addText('最低位', { x: 0.95, y: 4.45, w: 1.4, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 8.8, color: C.muted });
    slide.addText('最高位', { x: 2.75, y: 4.45, w: 1.4, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 8.8, color: C.muted });
    bullets(slide, [
      '收拢状态下高度低，适合车体内部布置。',
      '展开时可获得较大的升降行程，便于适配不同货架高度。',
      '采用侧向支撑提升稳定性和屈曲安全系数。',
    ], 0.82, 4.82, 3.55, 1.38, C.text, 10.8);

    rectCard(slide, 4.98, 1.72, 3.1, 5.38);
    tag(slide, '结构总装', 5.24, 1.98, 0.9, C.navy, C.white);
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/机械总装.png', 5.28, 2.32, 2.5, 2.55);
    slide.addText('机械总装图', { x: 5.26, y: 4.95, w: 2.55, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 8.8, color: C.muted });
    bullets(slide, ['底盘、升降台、驱动轮和万向轮的整体布局。', '空间利用与维修便利性兼顾。'], 5.18, 5.18, 2.72, 0.9, C.text, 10.3);

    rectCard(slide, 8.36, 1.72, 4.4, 5.38);
    tag(slide, '强度校核', 8.62, 1.98, 1.0, C.green, C.white);
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/fea_results_50kg.png', 8.62, 2.34, 3.85, 2.25);
    metric(slide, 8.7, 4.86, 1.18, 1.1, '5.56', 'MPa', '臂杆危险工况', C.green);
    metric(slide, 10.02, 4.86, 1.18, 1.1, '14.1', 'MPa', '平台等效应力', C.green);
    metric(slide, 11.34, 4.86, 1.18, 1.1, '156.7', 'MPa', 'Q235 许用应力', C.red);
    slide.addText('关键零件应力远低于材料许用值，结构满足 50 kg 额定载荷要求。', { x: 8.75, y: 6.0, w: 3.5, h: 0.14, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 10.3, color: C.text, fit: 'shrink' });
    footer(slide);
  }

  // 6. 电气系统
  {
    const slide = pptx.addSlide();
    slide.background = { color: C.paper };
    addHeader(slide, 4, '电气系统设计', '主控、电机、传感器与驱动电路共同构成机器人的“神经系统”');
    const cards = [
      ['控制器', 'STM32F103C8T6 实物图', 'STM32F103C8T6实物图.png'],
      ['驱动电机', '400W 交流伺服电机', 'SMC80S-0040-30AoK-3DKH电机外形图.png'],
      ['传感器', '红外与超声波组合', 'sensor_layout.png'],
      ['电路与接口', '最小系统与控制接口', 'dual_loop_pid.png'],
    ];
    cards.forEach((it, idx) => {
      const col = idx % 2;
      const row = Math.floor(idx / 2);
      const x = 0.58 + col * 6.25;
      const y = 1.78 + row * 2.55;
      rectCard(slide, x, y, 5.95, 2.05);
      tag(slide, it[0], x + 0.18, y + 0.18, 0.95, C.navy, C.white);
      picture(slide, `lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/${it[2]}`, x + 0.22, y + 0.48, 1.95, 1.18);
      slide.addText(it[1], { x: x + 2.35, y: y + 0.58, w: 3.28, h: 0.38, margin: 0, fontFace: 'Microsoft YaHei', fontSize: 12.5, bold: true, color: C.ink });
      const notes = ['负责路径跟踪与状态管理。', '提供底盘运动所需扭矩。', '完成环境感知与安全检测。', '形成控制闭环的基础接口。'];
      slide.addText(notes[idx], { x: x + 2.35, y: y + 1.08, w: 3.1, h: 0.22, margin: 0, fontFace: 'Microsoft YaHei', fontSize: 10.2, color: C.muted });
    });
    rectCard(slide, 0.58, 6.02, 12.2, 0.5, '1B2F4A', '1B2F4A');
    slide.addText('主控、电机、传感器之间通过信号采集、执行控制和保护电路协同工作，为后续运动学建模与闭环控制提供硬件基础。', { x: 0.82, y: 6.16, w: 11.74, h: 0.14, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9.3, color: C.white });
    footer(slide);
  }

  // 7. 运动学建模
  {
    const slide = pptx.addSlide();
    slide.background = { color: C.white };
    addHeader(slide, 5, '运动学建模与轨迹仿真', '建立差速运动学模型，并验证四类典型轨迹的可达性');
    rectCard(slide, 0.55, 1.72, 4.0, 5.4);
    tag(slide, '双轮差速模型', 0.78, 1.98, 1.18, C.gold, C.ink);
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/双轮模型.png', 0.78, 2.32, 3.54, 2.45);
    bullets(slide, ['以左右轮速度差作为转向基础。', '用于推导位姿与轮速之间的映射关系。', '为规划与控制仿真提供统一模型。'], 0.82, 4.94, 3.28, 1.0, C.text, 10.8);

    rectCard(slide, 4.85, 1.72, 7.92, 5.4);
    tag(slide, '四类典型轨迹', 5.12, 1.98, 1.2, C.navy, C.white);
    const sims = [
      ['直线.png', '直线'],
      ['圆形.png', '圆形'],
      ['s型.png', 'S 形'],
      ['8字.png', '8 字'],
    ];
    sims.forEach((it, idx) => {
      const x0 = 5.12 + (idx % 2) * 3.5;
      const y0 = 2.35 + Math.floor(idx / 2) * 2.06;
      rectCard(slide, x0, y0, 3.08, 1.82, 'F8FBFF');
      picture(slide, `fangzhen/figures/${it[0]}`, x0 + 0.12, y0 + 0.12, 2.84, 1.34);
      slide.addText(it[1], { x: x0 + 0.12, y: y0 + 1.48, w: 2.84, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9.2, color: C.muted });
    });
    slide.addText('结果表明，模型能够覆盖仓储搬运中常见的直行、转弯和曲线过渡工况，适合作为后续路径规划和 PID 控制的基础。', { x: 5.2, y: 6.36, w: 7.1, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9.5, color: C.text });
    footer(slide);
  }

  // 8. 路径规划与循迹
  {
    const slide = pptx.addSlide();
    slide.background = { color: C.paper };
    addHeader(slide, 6, '路径规划与循迹', '将全局规划与红外循迹结合起来，完成仓储地图中的稳定跟踪');
    rectCard(slide, 0.55, 1.72, 5.65, 5.4);
    tag(slide, 'Hybrid A* 全局规划', 0.8, 1.98, 1.52, C.navy, C.white);
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/hybrid_astar_result.png', 0.82, 2.36, 5.0, 3.1);
    slide.addText('生成无碰撞、可执行的平滑路径', { x: 0.9, y: 5.6, w: 4.9, h: 0.14, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 11, bold: true, color: C.text });
    slide.addText('适用于存在货架、转角和障碍物的仓储环境', { x: 0.9, y: 5.95, w: 4.9, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9.1, color: C.muted });

    rectCard(slide, 6.42, 1.72, 6.35, 1.0);
    metric(slide, 6.68, 1.95, 1.5, 0.68, '11.04', 'm', '规划路径长度', C.navy);
    metric(slide, 8.35, 1.95, 1.5, 0.68, '1.5', 'cm', '横向跟踪 RMS 误差', C.green);
    metric(slide, 10.02, 1.95, 1.5, 0.68, '4', '场景', '验证工况', C.gold);

    const lineImgs = [
      ['line_following_traj.png', '循迹轨迹'],
      ['line_following_error.png', '横向误差'],
      ['line_following_omega.png', '纠偏角速度'],
    ];
    lineImgs.forEach((it, idx) => {
      const x0 = 6.42 + idx * 2.06;
      rectCard(slide, x0, 3.1, 1.94, 3.58);
      tag(slide, it[1], x0 + 0.22, 3.33, 1.08, C.gold, C.ink);
      picture(slide, `lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/${it[0]}`, x0 + 0.12, 3.68, 1.7, 2.25);
    });
    slide.addText('规划与循迹的组合使机器人具备从地图级路径到实际底盘动作的完整闭环。', { x: 6.55, y: 6.9, w: 6.0, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9.2, color: C.text });
    footer(slide);
  }

  // 9. PID控制
  {
    const slide = pptx.addSlide();
    slide.background = { color: C.white };
    addHeader(slide, 7, '运动控制算法与仿真验证', '双闭环 PID 负责位姿和轮速控制，仿真覆盖阶跃、镇定与轨迹跟踪');
    rectCard(slide, 0.55, 1.72, 4.55, 5.4);
    tag(slide, '双闭环 PID 结构', 0.8, 1.98, 1.35, C.navy, C.white);
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/dual_loop_pid.png', 0.86, 2.34, 3.9, 2.45);
    bullets(slide, ['外环负责位姿误差修正，内环负责轮速响应。', '对积分项进行约束，抑制饱和与超调。', '控制目标是稳定、快速、可重复的轨迹跟踪。'], 0.88, 4.9, 3.55, 1.0, C.text, 10.8);

    rectCard(slide, 5.36, 1.72, 7.42, 5.4);
    const sim = [
      ['pid_step_response.png', '阶跃响应'],
      ['pid_point_stabilization.png', '定点镇定'],
      ['pid_line_tracking.png', '直线跟踪'],
      ['pid_circle_tracking.png', '圆形跟踪'],
    ];
    sim.forEach((it, idx) => {
      const x0 = 5.62 + (idx % 2) * 3.34;
      const y0 = 2.18 + Math.floor(idx / 2) * 2.2;
      rectCard(slide, x0, y0, 3.0, 1.9, 'FBFDFF');
      picture(slide, `fangzhen/figures/${it[0]}`, x0 + 0.1, y0 + 0.12, 2.8, 1.3);
      slide.addText(it[1], { x: x0 + 0.1, y: y0 + 1.46, w: 2.8, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9.2, color: C.muted });
    });
    slide.addText('在四种典型工况下，控制器均能保持稳定收敛，说明双闭环 PID 适合本课题的运动控制需求。', { x: 5.7, y: 6.34, w: 6.9, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9.4, color: C.text });
    footer(slide);
  }

  // 10. 结论与展望
  {
    const slide = pptx.addSlide();
    slide.background = { color: C.navy2 };
    slide.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: W, h: 0.16, line: { color: C.gold, transparency: 100 }, fill: { color: C.gold } });
    slide.addText('结论与展望', { x: 0.72, y: 0.6, w: 2.4, h: 0.16, margin: 0, fontFace: 'Microsoft YaHei', fontSize: 11, bold: true, color: C.gold });
    slide.addText('谢谢各位老师指导', { x: 0.72, y: 1.0, w: 5.0, h: 0.5, margin: 0, fontFace: 'Microsoft YaHei', fontSize: 22, bold: true, color: C.white });
    slide.addText('Q & A', { x: 0.72, y: 1.68, w: 1.8, h: 0.3, margin: 0, fontFace: 'Arial', fontSize: 24, bold: true, color: C.gold });

    rectCard(slide, 0.72, 2.4, 4.9, 3.4, '153055', '355B8A');
    tag(slide, '主要成果', 0.98, 2.68, 1.0, C.gold, C.ink);
    bullets(slide, [
      '完成了举升式 AGV 的总体方案、机械结构和电气系统设计。',
      '建立了差速运动学模型，并完成四类典型轨迹仿真。',
      '实现了 Hybrid A* 路径规划与双闭环 PID 控制验证。',
      '关键结构校核满足 50 kg 额定载荷的设计要求。',
    ], 1.0, 3.1, 4.15, 2.05, 'EDF2F7', 11.1);

    rectCard(slide, 5.95, 2.4, 3.2, 3.4, '0F213A', '365B8A');
    picture(slide, 'lunwen/QLULatex/QLUThesisLatexTemplate-master/Thesis/static/figures/机械总装.png', 6.18, 2.72, 2.78, 2.15);
    slide.addText('结构总装', { x: 6.1, y: 5.02, w: 3.0, h: 0.12, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 9, color: 'DDE8F5' });

    rectCard(slide, 9.38, 2.4, 3.23, 3.4, '0F213A', '365B8A');
    tag(slide, '后续工作', 9.64, 2.68, 1.0, C.gold, C.ink);
    bullets(slide, [
      '进一步优化控制器参数与抗扰性能。',
      '补充真实场地测试与硬件联调。',
      '扩展感知能力和路径规划场景。',
    ], 9.65, 3.08, 2.5, 1.7, 'EDF2F7', 10.1);
    slide.addText('智能仓储举升式 AGV\n结构设计与控制研究', { x: 9.54, y: 5.04, w: 2.66, h: 0.34, margin: 0, align: 'center', fontFace: 'Microsoft YaHei', fontSize: 13, bold: true, color: C.white });
  }

  await pptx.writeFile({ fileName: OUT });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
