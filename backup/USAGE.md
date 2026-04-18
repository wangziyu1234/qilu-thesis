# 备份命令速查

已在当前仓库配置 3 个 Git 本地别名：

- `git bkday`
- `git bktag`
- `git bkbundle`

## 1) 日常快照备份

```powershell
git bkday
```

可选：自定义提交信息

```powershell
git bkday -CommitMessage "docs: 更新第四章"
```

可选：推送到其他远程/分支

```powershell
git bkday -Remote lunwen -Branch main
```

## 2) 里程碑标签备份

```powershell
git bktag -TagName v2026.04.18-初稿提交 -TagMessage "初稿版"
```

## 3) 离线包备份（bundle）

```powershell
git bkbundle
```

默认会在仓库根目录生成 `bundle/*.bundle` 文件。

可选：自定义输出目录和文件前缀

```powershell
git bkbundle -OutputDir archive -FilePrefix thesis
```

## 建议频率

- 每天结束前：`git bkday`
- 每周或每次交稿前：`git bktag`
- 每月一次：`git bkbundle` 并把 bundle 文件复制到 U 盘/网盘
