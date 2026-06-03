/**
 * Helpers for equations, tables, and figures following QLU thesis template.
 *
 * Template rules:
 *   Equations: centered, chapter-numbered in parentheses (e.g. (3-1)),
 *              number right-aligned, 小四号TNR, variables explained after.
 *   Tables:    chapter-numbered (e.g. 表 3-1), caption ABOVE in 宋体5号/TNR,
 *              content in 宋体/TNR 5号, double-line header.
 *   Figures:   chapter-numbered (e.g. 图 3-1), caption BELOW in 宋体5号/TNR,
 *              annotation in 宋体/TNR 小五号, first-line indent 2 chars.
 */
const { Paragraph, TextRun, Table, TableRow, TableCell,
        AlignmentType, BorderStyle, WidthType, ShadingType } = require('docx');

const SONG = 'SimSun';
const HEI = 'SimHei';
const TNR  = 'Times New Roman';
const WUHAO   = 20;   // 五号 = 10pt
const XIAOWU  = 18;   // 小五 = 9pt
const SIHAO   = 28;   // 四号
const XIAOSI  = 24;   // 小四
const LINE    = 360;  // 1.5 倍行距

// thin border
const thin = { style: BorderStyle.SINGLE, size: 1, color: '000000' };
const noBorder = { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' };
const noBorders = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };
const allBorders = { top: thin, bottom: thin, left: thin, right: thin };
const headerBorders = { top: thin, bottom: thin, left: thin, right: thin };

// ===== EQUATION =====
// eq(ch, num, text, vars)
// e.g. eq(3, 1, 'H = L·sin(β) + h₀', 'L为臂杆长度，β为水平半角，h₀为配件固定高度')
function eq(ch, num, text, vars) {
  const lines = [];
  // spacing before
  lines.push(new Paragraph({ spacing: { before: 120, after: 0, line: LINE }, children: [] }));
  // equation line: centered text + right-aligned number
  lines.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 0, line: LINE },
    children: [
      new TextRun({ text, font: TNR, size: XIAOSI, italics: true }),
      new TextRun({ text: `（${ch}-${num}）`, font: TNR, size: XIAOSI }),
    ],
    tabStops: [{ type: 'right', position: 8500 }],
  }));
  // variable explanation (if provided)
  if (vars) {
    lines.push(new Paragraph({
      spacing: { before: 0, after: 120, line: LINE },
      indent: { firstLine: 480 },
      children: [new TextRun({ text: `式中，${vars}。`, font: SONG, size: XIAOSI })],
    }));
  }
  return lines;
}

// eqCentered(ch, num, text, vars) — for multi-line or longer equations
function eqCentered(ch, num, text, vars) {
  const lines = [];
  lines.push(new Paragraph({ spacing: { before: 120, after: 0, line: LINE }, children: [] }));
  lines.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 0, line: LINE },
    children: [
      new TextRun({ text, font: TNR, size: XIAOSI, italics: true }),
    ],
  }));
  lines.push(new Paragraph({
    alignment: AlignmentType.RIGHT,
    spacing: { after: 0, line: LINE },
    children: [new TextRun({ text: `（${ch}-${num}）`, font: TNR, size: XIAOSI })],
  }));
  if (vars) {
    lines.push(new Paragraph({
      spacing: { before: 0, after: 120, line: LINE },
      indent: { firstLine: 480 },
      children: [new TextRun({ text: `式中，${vars}。`, font: SONG, size: XIAOSI })],
    }));
  }
  return lines;
}

// ===== TABLE =====
// tbl(ch, num, title, headers, rows)
// e.g. tbl(3, 1, 'Q235钢的主要性能参数', ['性能指标', '数值范围/说明'], [['屈服强度σₛ', '≥ 235 MPa'], ...])
function tbl(ch, num, title, headers, rows) {
  const content = [];
  const colCount = headers.length;
  // Caption above table (宋体5号)
  content.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 240, after: 120, line: LINE },
    children: [
      new TextRun({ text: `表 ${ch}-${num}  `, font: SONG, size: WUHAO }),
      new TextRun({ text: title, font: SONG, size: WUHAO }),
    ],
  }));

  // Calculate column widths (total ~9026 DXA for A4 with 2.5cm margins)
  const totalW = 9026;
  const colW = Math.floor(totalW / colCount);

  // Header row
  const headerRow = new TableRow({
    children: headers.map(h => new TableCell({
      borders: headerBorders,
      width: { size: colW, type: WidthType.DXA },
      shading: { fill: 'D9E2F3', type: ShadingType.CLEAR },
      verticalAlign: 'center',
      margins: { top: 40, bottom: 40, left: 80, right: 80 },
      children: [new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 0, line: 300 },
        children: [new TextRun({ text: h, font: SONG, size: WUHAO, bold: true })],
      })],
    })),
  });

  // Data rows
  const dataRows = rows.map(row => new TableRow({
    children: row.map(cell => new TableCell({
      borders: allBorders,
      width: { size: colW, type: WidthType.DXA },
      margins: { top: 40, bottom: 40, left: 80, right: 80 },
      children: [new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 0, line: 300 },
        children: [new TextRun({ text: String(cell), font: SONG, size: WUHAO })],
      })],
    })),
  }));

  content.push(new Table({
    width: { size: totalW, type: WidthType.DXA },
    columnWidths: Array(colCount).fill(colW),
    rows: [headerRow, ...dataRows],
  }));

  // Spacing after table
  content.push(new Paragraph({ spacing: { before: 120, after: 0, line: LINE }, children: [] }));
  return content;
}

// ===== FIGURE PLACEHOLDER =====
// fig(ch, num, caption, widthPercent)
function fig(ch, num, caption, widthPercent = 0.6) {
  const content = [];
  // Spacing before
  content.push(new Paragraph({ spacing: { before: 240, after: 0, line: LINE }, children: [] }));
  // Placeholder box
  content.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 0, line: LINE },
    border: { top: { style: BorderStyle.SINGLE, size: 1, color: '999999' },
              bottom: { style: BorderStyle.SINGLE, size: 1, color: '999999' },
              left: { style: BorderStyle.SINGLE, size: 1, color: '999999' },
              right: { style: BorderStyle.SINGLE, size: 1, color: '999999' } },
    children: [new TextRun({ text: `  [ 图 ${ch}-${num} ]  `, font: SONG, size: WUHAO, color: '999999' })],
  }));
  // Caption below (宋体5号)
  content.push(new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 60, after: 120, line: LINE },
    children: [
      new TextRun({ text: `图 ${ch}-${num}  `, font: SONG, size: WUHAO }),
      new TextRun({ text: caption, font: SONG, size: WUHAO }),
    ],
  }));
  return content;
}

// figNote(ch, num, note) — annotation below figure caption (小五号)
function figNote(ch, num, note) {
  return new Paragraph({
    spacing: { before: 0, after: 120, line: 280 },
    indent: { firstLine: 480 },
    children: [new TextRun({ text: note, font: SONG, size: XIAOWU })],
  });
}

module.exports = { eq, eqCentered, tbl, fig, figNote };
