const fs = require('fs');
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        AlignmentType, BorderStyle, WidthType, ShadingType, VerticalAlign,
        PageBreak, Header, Footer, PageNumber, HeadingLevel } = require('docx');

const border = { style: BorderStyle.SINGLE, size: 4, space: 0, color: "000000" };
const borders = { top: border, bottom: border, left: border, right: border };
const cellMargins = { top: 40, bottom: 40, left: 80, right: 80 };

// Helper: create a cell with text
function textCell(text, opts = {}) {
  const { bold, center, gridSpan, width, vAlign } = opts;
  const tcPr = {
    borders,
    margins: cellMargins,
    verticalAlign: vAlign || VerticalAlign.CENTER,
  };
  if (gridSpan) tcPr.columnSpan = gridSpan;
  if (width) tcPr.width = { size: width, type: WidthType.DXA };

  return new TableCell({
    ...tcPr,
    children: [new Paragraph({
      alignment: center ? AlignmentType.CENTER : AlignmentType.LEFT,
      spacing: { line: 360, lineRule: "auto" },
      children: [new TextRun({
        text,
        font: "宋体",
        size: 24, // 12pt
        bold: bold || false,
      })],
    })],
  });
}

// Helper: create a cell with multiple paragraphs
function multiParaCell(paragraphs, opts = {}) {
  const { gridSpan, width } = opts;
  const tcPr = {
    borders,
    margins: cellMargins,
    verticalAlign: VerticalAlign.TOP,
  };
  if (gridSpan) tcPr.columnSpan = gridSpan;
  if (width) tcPr.width = { size: width, type: WidthType.DXA };

  return new TableCell({
    ...tcPr,
    children: paragraphs,
  });
}

// Helper: normal paragraph with first-line indent
function bodyPara(text) {
  return new Paragraph({
    spacing: { line: 360, lineRule: "auto" },
    indent: { firstLineChars: 200, firstLine: 480 },
    children: [new TextRun({ text, font: "宋体", size: 24 })],
  });
}

// Helper: section heading (no indent)
function sectionHeading(text) {
  return new Paragraph({
    spacing: { line: 360, lineRule: "auto" },
    children: [new TextRun({ text, font: "宋体", size: 24, bold: false })],
  });
}

// Helper: numbered item
function numberedItem(text) {
  return new Paragraph({
    spacing: { line: 360, lineRule: "auto" },
    indent: { firstLineChars: 0, firstLine: 0 },
    children: [new TextRun({ text, font: "宋体", size: 24 })],
  });
}

// ===== Build the content paragraphs for the main body cell =====

const bodyChildren = [];

// Title
bodyChildren.push(new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { after: 200 },
  children: [new TextRun({
    text: "论文（设计）工作进展情况：",
    font: "宋体",
    size: 24,
  })],
}));

// Section 1: Completed work
bodyChildren.push(sectionHeading("一、已完成的工作"));
bodyChildren.push(bodyPara(
  "截止到毕业设计中期，本人已围绕\"智能仓储自主移动机器人结构设计与控制\"课题完成了以下主要工作："
));
bodyChildren.push(bodyPara(
  "（1）文献调研与开题：查阅了国内外智能仓储移动机器人及路径规划算法的相关文献，完成了文献翻译和开题报告撰写，明确了以差速驱动底盘、剪叉式升降机构、Hybrid A*路径规划和双环PID运动控制为核心的研究方案。"
));
bodyChildren.push(bodyPara(
  "（2）总体方案设计：通过多方案对比分析，确定了双轮差速驱动底盘、交流伺服电机+行星减速器动力方案、ARM Cortex-M系列单片机控制系统、Hybrid A*全局路径规划与双环PID运动控制的导航控制策略。"
));
bodyChildren.push(bodyPara(
  "（3）机械结构设计：完成了剪叉式垂直升降机构的结构设计、运动学建模、受力分析与强度校核。在50 kg额定载重下，臂杆压弯组合应力为5.56 MPa，承载平台von Mises等效应力为14.1 MPa，均远低于Q235钢许用应力156.7 MPa；增设侧向支撑后臂杆屈曲安全系数由2.54提升至10.1。完成了三维模型绘制和有限元数值验证。"
));
bodyChildren.push(bodyPara(
  "（4）电气系统设计：完成了以STM32F103C8T6为核心的控制电路设计，包括最小系统电路、红外传感器接口电路和超声波传感器接口电路；完成了SMC80S伺服电机和ZJPX115行星减速器的选型与匹配计算。"
));
bodyChildren.push(bodyPara(
  "（5）运动学建模与仿真：建立了双轮差速运动学模型，在MATLAB环境下完成了直线、圆弧、S形和8字形四种典型轨迹的运动学仿真；完成了Hybrid A*路径规划算法在仓储地图上的仿真实验，生成11.04 m无碰撞路径；完成了5路红外传感器PID循迹控制仿真，RMS横向误差1.5 cm。"
));
bodyChildren.push(bodyPara(
  "（6）运动控制设计与仿真：设计了双环PID级联控制器（位姿外环+轮速内环），在阶跃响应、定点镇定、直线跟踪和圆形轨迹跟踪四种典型工况下完成了仿真验证。定点镇定终点位置误差收敛至厘米级，航向偏差小于1°。"
));
bodyChildren.push(bodyPara(
  "（7）论文撰写：已完成论文第一章（引言）、第二章（总体设计方案）、第三章（机械结构设计）、第四章（电气系统设计）、第五章（运动学建模与仿真）和第六章（运动控制算法分析）的正文撰写。"
));

// Section 2: Planned work
bodyChildren.push(sectionHeading(""));
bodyChildren.push(sectionHeading("二、拟进行的工作及进度安排"));
bodyChildren.push(bodyPara(
  "论文主要章节的理论研究和仿真验证工作已基本完成，后续安排如下："
));
bodyChildren.push(numberedItem(
  "5月底至6月初：完成论文全文的格式排版、图表编号、参考文献核对等整理工作。"
));
bodyChildren.push(numberedItem(
  "6月上旬：根据导师审阅意见修改完善论文，补充不足内容。"
));
bodyChildren.push(numberedItem(
  "6月中旬：完成论文定稿，准备毕业答辩材料。"
));

// Section 3: Problems and solutions
bodyChildren.push(sectionHeading(""));
bodyChildren.push(sectionHeading("三、存在的问题及采取措施"));
bodyChildren.push(bodyPara("1. 存在的问题："));
bodyChildren.push(bodyPara(
  "（1）论文目前仅完成了MATLAB仿真验证，尚未进行实物样机测试，电机死区、轮胎打滑、传感器噪声等实际因素未充分体现。"
));
bodyChildren.push(bodyPara(
  "（2）仿真部分仅给出了Hybrid A*+PID方案的结果，缺乏与其他算法（如标准A*、模糊PID等）的定量对比分析。"
));
bodyChildren.push(bodyPara(
  "（3）运动学模型为二维平面模型，对动力学特性和多传感器融合考虑不足。"
));
bodyChildren.push(bodyPara("2. 解决方法："));
bodyChildren.push(bodyPara(
  "（1）在论文结论与展望部分如实说明仿真与实物之间的差距，提出后续样机装配与实物测试的改进方向。"
));
bodyChildren.push(bodyPara(
  "（2）通过查阅更多文献资料，在论文中补充对所选方案优势的定性分析和讨论。"
));
bodyChildren.push(bodyPara(
  "（3）在不足与改进方向中明确指出动力学建模和多传感器融合是后续研究的重点，为论文的完整性提供支撑。"
));

// Date
bodyChildren.push(new Paragraph({
  alignment: AlignmentType.RIGHT,
  spacing: { line: 360, lineRule: "auto", before: 200 },
  children: [new TextRun({ text: "年     月     日", font: "宋体", size: 24 })],
}));

// ===== Build the document =====

const doc = new Document({
  styles: {
    default: {
      document: {
        run: { font: "宋体", size: 24 },
      },
    },
  },
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 }, // A4
        margin: { top: 1440, right: 1800, bottom: 1440, left: 1800, header: 851, footer: 992 },
      },
    },
    children: [
      // Title
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 100 },
        children: [new TextRun({
          text: "齐鲁工业大学本科毕业论文（设计）中期进展报告表",
          font: "黑体",
          size: 32, // 16pt
          bold: true,
        })],
      }),
      // Empty line
      new Paragraph({ spacing: { after: 0 } }),

      // Main table
      new Table({
        width: { size: 8522, type: WidthType.DXA },
        columnWidths: [1464, 1676, 804, 1656, 1307, 1647], // old grid
        rows: [
          // Row 1: 学部(学院) | 机械工程学部 | 专业班级 | 机器人si22-2
          new TableRow({
            height: { value: 638 },
            children: [
              textCell("学部（学院）", { center: true }),
              textCell("机械工程学部", { center: true, gridSpan: 3 }),
              textCell("专业班级", { center: true }),
              textCell("机器人si22-2", { center: true }),
            ],
          }),
          // Row 2: 学生姓名 | 王子煜 | 学号 | 202201230042 | 导师姓名 | 刘鹏博
          new TableRow({
            height: { value: 656 },
            children: [
              textCell("学生姓名", { center: true }),
              textCell("王子煜", { center: true }),
              textCell("学号", { center: true }),
              textCell("202201230042", { center: true }),
              textCell("导师姓名", { center: true }),
              textCell("刘鹏博", { center: true }),
            ],
          }),
          // Row 3: 课题名称 (spans 5 cols)
          new TableRow({
            height: { value: 623 },
            children: [
              textCell("课题名称", { center: true }),
              textCell("智能仓储自主移动机器人结构设计与控制", { center: true, gridSpan: 5 }),
            ],
          }),
          // Row 4: Main body content (spans 6 cols, large row)
          new TableRow({
            height: { value: 10424 },
            children: [
              new TableCell({
                borders,
                margins: cellMargins,
                columnSpan: 6,
                verticalAlign: VerticalAlign.TOP,
                children: bodyChildren,
              }),
            ],
          }),
          // Row 5: 指导教师评价意见 (spans 6 cols, large row)
          new TableRow({
            height: { value: 13227 },
            children: [
              new TableCell({
                borders,
                margins: cellMargins,
                columnSpan: 6,
                verticalAlign: VerticalAlign.TOP,
                children: [
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [new TextRun({
                      text: "指导教师评价意见",
                      font: "宋体",
                      size: 24,
                    })],
                  }),
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [
                      new TextRun({ text: "1．论文（设计）进展情况评价", font: "宋体", size: 24 }),
                      new TextRun({ text: "                   ", font: "宋体", size: 24, underline: { type: "single" } }),
                    ],
                  }),
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [new TextRun({
                      text: "       （基本完成计划、部分完成计划、没有完成计划）",
                      font: "宋体",
                      size: 24,
                    })],
                  }),
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [
                      new TextRun({ text: "2．学生工作态度情况评价", font: "宋体", size: 24 }),
                      new TextRun({ text: "                        ", font: "宋体", size: 24, underline: { type: "single" } }),
                    ],
                  }),
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [new TextRun({
                      text: "　　　 （认真、一般、较差）",
                      font: "宋体",
                      size: 24,
                    })],
                  }),
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [
                      new TextRun({ text: "3．已完成论文（设计）质量评价", font: "宋体", size: 24 }),
                      new TextRun({ text: "                  ", font: "宋体", size: 24, underline: { type: "single" } }),
                    ],
                  }),
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [new TextRun({
                      text: "       （较好、一般、较差）",
                      font: "宋体",
                      size: 24,
                    })],
                  }),
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [new TextRun({
                      text: "4．论文（设计）不足之处及改进意见",
                      font: "宋体",
                      size: 24,
                    })],
                  }),
                  // Empty lines for writing space
                  ...Array(10).fill(null).map(() => new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [],
                  })),
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [new TextRun({
                      text: "                             指导教师签字：",
                      font: "宋体",
                      size: 24,
                    })],
                  }),
                  ...Array(3).fill(null).map(() => new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [],
                  })),
                  new Paragraph({
                    spacing: { line: 360, lineRule: "auto" },
                    children: [new TextRun({
                      text: "                                                  年     月     日",
                      font: "宋体",
                      size: 24,
                    })],
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
      // Empty paragraph after table
      new Paragraph({ children: [] }),
    ],
  }],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("D:/bylw/中期检查/中期检查_重做.docx", buffer);
  console.log("Done! Saved to D:/bylw/中期检查/中期检查_重做.docx");
});
