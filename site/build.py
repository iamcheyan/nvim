#!/usr/bin/env python3
"""Build the static site for the iamcheyan/nvim configuration.

Content source is the repository's own docs/ tree, so what you read on GitHub
and what the site renders are the same Markdown. The keymap tables are parsed
out of lua/plugins/ at build time instead of being hand-written, which is the
only way a reference page of this size stays correct.

No frontend toolchain: Markdown in, HTML out, committed as plain files.
"""

from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
OUT = ROOT / "build" / "site"

MD = markdown.Markdown(
    extensions=["tables", "fenced_code", "toc", "attr_list", "sane_lists"],
    extension_configs={"toc": {"permalink": False, "toc_depth": "2-3"}},
)

# ---------------------------------------------------------------------------
# Site metadata
# ---------------------------------------------------------------------------

SITE = {
    "name": "Neovim",
    "repo": "iamcheyan/nvim",
    "url": "https://nvim.iamcheyan.com",
    "tagline": "一套完整、可直接运行的 Neovim 配置",
}

# Top-level navigation. Order is deliberate: install, then use, then go deep.
NAV = [
    ("getting-started", "安装与更新"),
    ("keys", "按键"),
    ("plugins", "插件手册"),
    ("guides", "指南"),
]

# Plugin catalogue: category -> [(chapter slug, display name, kind, one-liner)]
CATALOG = [
    ("搜索、启动与窗口", [
        ("dashboard-nvim", "dashboard-nvim", "公开", "启动页、最近文件与项目目录"),
        ("snacks.nvim", "snacks.nvim", "公开", "文件与内容搜索、通知和工具"),
        ("neo-tree.nvim", "neo-tree.nvim", "公开", "文件树、缓冲区与 Git 视图"),
        ("bufferline.nvim", "bufferline.nvim", "公开", "顶部缓冲区标签栏"),
        ("grug-far.nvim", "grug-far.nvim", "公开", "跨文件查找替换"),
        ("auto-session", "auto-session", "公开", "按项目保存与恢复会话"),
        ("aerial", "aerial.nvim", "公开", "代码符号大纲"),
        ("quicker", "quicker.nvim", "公开", "quickfix 上下文与编辑"),
    ]),
    ("编辑、补全与代码导航", [
        ("blink-cmp", "blink.cmp", "公开", "输入补全与代码片段"),
        ("nvim-lspconfig", "nvim-lspconfig", "公开", "语言服务器与跳转"),
        ("mason", "mason.nvim", "公开", "安装语言服务器与工具"),
        ("mason-lspconfig", "mason-lspconfig.nvim", "公开", "Mason 与 LSP 的连接"),
        ("nvim-treesitter", "nvim-treesitter", "公开", "语法解析与高亮"),
        ("nvim-treesitter-textobjects", "nvim-treesitter-textobjects", "公开", "语法对象与结构跳转"),
        ("mini-ai", "mini.ai", "公开", "代码结构文本对象"),
        ("mini-surround", "mini.surround", "公开", "添加、删除、替换包围符号"),
        ("flash.nvim", "flash.nvim", "公开", "屏幕内快速定位"),
        ("nvim-lint", "nvim-lint", "公开", "ShellCheck 静态检查"),
        ("markview", "markview.nvim", "公开", "Markdown 等文档预览"),
        ("multicursor.nvim", "multicursor.nvim", "公开", "多光标匹配与批量编辑"),
        ("nvim-ufo", "nvim-ufo", "公开", "代码折叠"),
    ]),
    ("Git 与项目记录", [
        ("gitsigns", "gitsigns.nvim", "公开", "Git 行变更与 hunk 操作"),
        ("diffview", "diffview.nvim", "公开", "分支差异与文件历史"),
        ("bookmark", "bookmark.nvim", "私有", "项目书签"),
    ]),
    ("界面、颜色与辅助操作", [
        ("heirline", "heirline.nvim", "公开", "状态栏与上下文栏"),
        ("which-key", "which-key.nvim", "公开", "快捷键提示"),
        ("indent-blankline", "indent-blankline.nvim", "公开", "缩进参考线"),
        ("rainbow-delimiters", "rainbow-delimiters.nvim", "公开", "成对括号着色"),
        ("satellite", "satellite.nvim", "公开", "窗口边缘位置标记"),
        ("nvim-hlslens", "nvim-hlslens", "公开", "搜索结果位置提示"),
        ("fidget", "fidget.nvim", "公开", "LSP 任务进度提示"),
        ("mini-pairs", "mini.pairs", "公开", "自动补全括号与引号"),
        ("mini-hipatterns", "mini.hipatterns", "公开", "颜色值文本高亮"),
        ("ccc", "ccc.nvim", "公开", "取色与颜色转换"),
        ("smart-paste", "smart-paste.nvim", "私有", "系统剪贴板与缩进粘贴"),
    ]),
    ("私有语言工具", [
        ("cobol", "cobol.nvim", "私有", "COBOL 导航、格式与辅助"),
        ("batch", "batch.nvim", "私有", "Windows Batch 标签导航与分析"),
        ("contextline", "contextline.nvim", "私有", "语言结构上下文栏"),
        ("vimquest", "VimQuest.nvim", "私有", "词汇练习"),
    ]),
    ("管理器与依赖", [
        ("lazy", "lazy.nvim", "管理器", "插件安装与更新"),
        ("dependencies", "依赖库", "依赖", "plenary.nvim、nui.nvim、promise-async、nvim-web-devicons"),
    ]),
]


# ---------------------------------------------------------------------------
# Keymap extraction
#
# Mappings are read from a real Neovim instance, not parsed out of the Lua
# source: lazy-loaded plugins install their keymaps in config(), so a static
# parser sees almost nothing and, worse, guesses wrong descriptions. The dump
# runs with the repository on the runtimepath, which is how a headless build
# reproduces what a user actually gets.
#
# The result is cached in site/keymaps.tsv so the site can be built on a
# machine without the plugin set, and refreshed with --refresh-keys.
# ---------------------------------------------------------------------------

KEYMAP_CACHE = ROOT / "site" / "keymaps.tsv"

DUMP_LUA = r"""
vim.defer_fn(function()
  local lazy = require("lazy")
  for _, p in ipairs(lazy.plugins()) do
    if not p._.loaded then
      pcall(function() lazy.load({ plugins = { p.name } }) end)
    end
  end
  vim.defer_fn(function()
    local out = {}
    for _, mode in ipairs({ "n", "x", "o", "i", "t", "c" }) do
      local maps = vim.api.nvim_get_keymap(mode)
      table.sort(maps, function(a, b) return a.lhs < b.lhs end)
      for _, m in ipairs(maps) do
        local lhs = m.lhs
        local desc = (m.desc or ""):gsub("\t", " ")
        if lhs:sub(1, 6) == "<Space" and lhs ~= "<Space>" then
          lhs = "<leader>" .. lhs:sub(7)
        end
        out[#out + 1] = table.concat({ lhs, m.mode, desc }, "\t")
      end
    end
    vim.fn.writefile(out, "/tmp/nvim-keys.tsv")
    vim.cmd("qa!")
  end, 6000)
end, 4000)
"""


def refresh_keymaps() -> list[dict]:
    """Run a headless Neovim and capture the real keymap set."""
    import subprocess
    import tempfile

    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False) as fh:
        fh.write(DUMP_LUA)
        script = fh.name
    try:
        subprocess.run(
            ["nvim", "--headless", "-u", "init.lua", "--cmd", "set rtp+.", "-c", f"luafile {script}"],
            cwd=ROOT,
            check=False,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=240,
        )
    finally:
        Path(script).unlink(missing_ok=True)

    dumped = Path("/tmp/nvim-keys.tsv")
    if not dumped.exists():
        return []
    rows = []
    for line in dumped.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        lhs, modes, desc = parts[0], parts[1], (parts[2] if len(parts) > 2 else "")
        if not lhs or lhs.startswith("<Plug>"):
            continue
        rows.append({"lhs": lhs, "modes": [modes], "desc": desc, "plugin": "", "source": "dump"})
    KEYMAP_CACHE.write_text(
        "\n".join(f'{r["lhs"]}\t{",".join(r["modes"])}\t{r["desc"]}' for r in rows) + "\n",
        encoding="utf-8",
    )
    return rows


def load_keymaps(refresh: bool = False) -> list[dict]:
    if refresh:
        rows = refresh_keymaps()
        if not rows:
            print(
                "warning: keymap refresh produced nothing; keeping site/keymaps.tsv.\n"
                "         regeneration needs a working plugin install (Lazy load all).",
                file=sys.stderr,
            )
        elif rows:
            return rows
    if not KEYMAP_CACHE.exists():
        return []
    rows = []
    for line in KEYMAP_CACHE.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        lhs, modes, desc = parts[0], parts[1], (parts[2] if len(parts) > 2 else "")
        rows.append(
            {"lhs": lhs, "modes": modes.split(","), "desc": desc, "plugin": "", "source": "cache"}
        )
    return rows


def _normalise_lhs(lhs: str) -> str:
    """Spell modifiers the way the documentation does (Ctrl-n -> <C-n>)."""
    out = lhs
    out = re.sub(r"<leader>", "␣", out)
    return out


def _sort_key(lhs: str) -> tuple:
    key = _normalise_lhs(lhs)
    # Group by prefix so the table reads like a keymap, not an alphabet.
    key = key.replace("<", "").replace(">", "")
    return (len(key), key.lower())


def render_key(lhs: str) -> str:
    """Render one lhs as a row of keycaps."""
    token = _normalise_lhs(lhs)
    parts: list[str] = []
    buf = ""
    i = 0
    while i < len(token):
        ch = token[i]
        if ch == "␣":
            if buf:
                parts.append(buf)
                buf = ""
            parts.append("Space")
            i += 1
            continue
        if ch == "<":
            j = token.find(">", i)
            if j != -1:
                if buf:
                    parts.append(buf)
                    buf = ""
                inner = token[i + 1 : j]
                parts.append(KEY_ALIAS.get(inner.lower(), inner))
                i = j + 1
                continue
        buf += ch
        i += 1
    if buf:
        parts.append(buf)
    return "".join(f'<kbd>{html_escape(p)}</kbd>' for p in parts if p)


KEY_ALIAS = {
    "leader": "Space",
    "c": "Ctrl",
    "s-c": "Ctrl+Shift",
    "cr": "Enter",
    "esc": "Esc",
    "tab": "Tab",
    "bs": "Backspace",
    "space": "Space",
    "up": "↑",
    "down": "↓",
    "left": "←",
    "right": "→",
}


# Vim's own mapping descriptions are often raw API names. Translate the ones
# this configuration actually produces; anything unknown stays verbatim so we
# never invent behaviour.
DESC_FIXES = {
    "vim.lsp.buf.code_action()": "代码操作（LSP）",
    "vim.lsp.buf.implementation()": "跳到实现（LSP）",
    "vim.lsp.buf.rename()": "重命名符号（LSP）",
    "vim.lsp.buf.references()": "列出引用（LSP）",
    "vim.lsp.buf.hover()": "悬停文档（LSP）",
    "vim.lsp.buf.definition()": "跳到定义（LSP）",
    "vim.lsp.buf.type_definition()": "跳到类型定义（LSP）",
    "vim.lsp.buf.signature_help()": "参数提示（LSP）",
    "vim.lsp.buf.declaration()": "跳到声明（LSP）",
    "vim.diagnostic.open_float()": "在浮窗中显示诊断",
    "vim.diagnostic.goto_next()": "下一个诊断",
    "vim.diagnostic.goto_prev()": "上一个诊断",
    "vim.diagnostic.setloclist()": "诊断写入 location list",
    "mapping()": "",
}


def fix_desc(desc: str) -> str:
    d = (desc or "").strip()
    if not d:
        return ""
    if d in DESC_FIXES:
        return DESC_FIXES[d]
    # Unwrap common LSP helpers into readable Chinese.
    m = re.match(r"^vim\.lsp\.buf\.([a-z_]+)\(\)$", d)
    if m:
        return f"{m.group(1).replace('_', ' ')}（LSP）"
    if d.startswith(":help ") or d.endswith("-default"):
        return ""
    return d


def _slugify(text: str) -> str:
    """Stable anchor for a Chinese heading: pinyin-free, just index-stable."""
    return "".join(f"{ord(c):x}" for c in text)[:24]


def html_escape(s: str) -> str:
    return (
        s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")
    )


# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------

def nav_html(current: str) -> str:
    items = []
    for slug, label in NAV:
        cls = "nav-link current" if current == slug else "nav-link"
        items.append(f'<a class="{cls}" href="{rel_root(current)}{slug}.html">{label}</a>')
    return "\n".join(items)


def rel_root(current: str) -> str:
    """Relative prefix back to the site root.

    Top-level pages must not climb; anything under a subdirectory does.
    """
    return "../" if current in ("guide-page", "plugin-page") else ""


def page(title: str, body: str, current: str, *, is_home: bool = False) -> str:
    prefix = rel_root(current)
    return f"""<!doctype html>
<html lang="zh-CN" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html_escape(title)}</title>
<meta name="description" content="{html_escape(SITE['tagline'])} — {html_escape(SITE['repo'])}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&family=Noto+Sans+SC:wght@400;500;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{prefix}assets/site.css">
</head>
<body{' class="home-body"' if is_home else ''}>
<a class="skip" href="#main">跳到内容</a>
<header class="bar">
  <div class="bar-inner">
    <a class="logo" href="{prefix}index.html">
      <span class="logo-mark" aria-hidden="true">%</span>
      <span class="logo-text"><strong>nvim</strong><small>{html_escape(SITE['repo'])}</small></span>
    </a>
    <nav class="nav" id="site-nav">
      {nav_html(current)}
      <a class="nav-link repo" href="https://github.com/{SITE['repo']}" rel="noopener">GitHub&nbsp;↗</a>
    </nav>
    <button class="theme-btn" id="theme-btn" type="button" aria-label="切换明暗主题">
      <span class="t-dark" aria-hidden="true">◐</span><span class="t-light" aria-hidden="true">◑</span>
    </button>
    <button class="nav-btn" id="nav-btn" type="button" aria-expanded="false" aria-controls="site-nav">
      <span aria-hidden="true">≡</span><em>菜单</em>
    </button>
  </div>
</header>
<main id="main">
{body}
</main>
<footer class="foot">
  <div class="foot-inner">
    <p><strong>{html_escape(SITE['repo'])}</strong> — {html_escape(SITE['tagline'])}</p>
    <p class="foot-links">
      <a href="https://github.com/{SITE['repo']}">仓库</a>
      <a href="https://github.com/{SITE['repo']}/blob/main/README.md">README</a>
      <a href="https://github.com/{SITE['repo']}/issues">Issues</a>
    </p>
  </div>
</footer>
<script src="{prefix}assets/site.js" defer></script>
</body>
</html>
"""


def article_shell(title: str, inner: str, current: str, crumb: str = "", prefix: str = "") -> str:
    trail = (
        f'<p class="crumb">{crumb}</p>' if crumb else ""
    )
    body = f"""
<div class="wrap doc">
  <aside class="side" id="side">
    {side_nav(current, prefix)}
  </aside>
  <article class="prose">
    {trail}
    <h1>{html_escape(title)}</h1>
    {inner}
  </article>
</div>
"""
    return page(title, body, current)


def side_nav(current: str, prefix: str = "", guide_prefix: str = "") -> str:
    if current == "plugins":
        groups = []
        for category, entries in CATALOG:
            links = "".join(
                f'<a href="{prefix}{slug}.html"><span>{html_escape(name)}</span></a>'
                for slug, name, _kind, _desc in entries
            )
            groups.append(
                f'<div class="side-group"><p class="side-head">{html_escape(category)}</p>{links}</div>'
            )
        return f'<p class="side-title">插件手册</p>' + "".join(groups)
    if current == "keys":
        scenes = [
            ("文件与搜索", "文件、内容、最近文件"),
            ("Git", "hunk、blame、diff、历史"),
            ("代码与 LSP", "定义、引用、重命名、格式化"),
            ("搜索替换", "跨文件替换与项目检索"),
            ("多光标", "Ctrl 组合与按行加光标"),
            ("诊断与 quickfix", "错误列表与跳转"),
            ("界面开关", "侧栏、终端、Markdown 预览"),
        ]
        links = "".join(
            f'<a href="#g-{html_escape(slug)}"><span>{html_escape(label)}</span></a>'
            for slug, label in [(_slugify(n), n) for n, _d in scenes]
        )
        return (
            '<p class="side-title">按场景</p><div class="side-group">'
            + links
            + '</div><div class="side-group"><a href="#all"><span>完整键位表</span></a>'
            + '<a href="getting-started.html"><span>安装与更新</span></a></div>'
        )
    if current == "guides":
        links = "".join(
            f'<a href="{guide_prefix}{slug}.html"><span>{html_escape(label)}</span></a>'
            for slug, label in GUIDE_LINKS
        )
        return f'<p class="side-title">指南</p><div class="side-group">{links}</div>'
    return ""


GUIDE_LINKS: list[tuple[str, str]] = []


# ---------------------------------------------------------------------------
# Markdown rendering
# ---------------------------------------------------------------------------

def render_md(text: str) -> str:
    MD.reset()
    return MD.convert(text)


def strip_h1(html: str) -> str:
    return re.sub(r"<h1[^>]*>.*?</h1>\s*", "", html, count=1, flags=re.S)


def first_h1(md_text: str, fallback: str) -> str:
    m = re.search(r"^#\s+(.+)$", md_text, re.M)
    return m.group(1).strip() if m else fallback


# ---------------------------------------------------------------------------
# Pages
# ---------------------------------------------------------------------------

HIGHLIGHTS = [
    ("<leader>ff", "找文件", "按名字打开项目里的文件"),
    ("<leader>fg", "搜内容", "在整个项目里搜文本"),
    ("<leader>gd", "看差异", "并排查看当前分支的改动"),
    ("<leader>cs", "看大纲", "按结构跳转当前文件的符号"),
    ("<leader>sr", "跨文件替换", "先看匹配数，再决定是否落盘"),
    ("<C-n>", "多光标", "选中下一个匹配并同时编辑"),
    ("gaip", "按行加光标", "段落每行一个光标"),
    ("<leader>?", "查按键", "列出当前 buffer 的全部映射"),
]


def build_home(keymaps: list[dict]) -> str:
    total_plugins = sum(len(entries) for _c, entries in CATALOG)  # 章节数
    total_specs = len(list((ROOT / "lua" / "plugins").glob("*.lua")))  # 插件规格文件数
    have = {r["lhs"] for r in keymaps}
    rows = []
    for lhs, name, desc in HIGHLIGHTS:
        mark = "" if lhs in have else '<span class="tdim">（未在此环境导出）</span>'
        rows.append(
            f'<div class="preview-row"><span class="keys">{render_key(lhs)}</span>'
            f'<span><strong style="color:var(--ink)">{html_escape(name)}</strong> · {html_escape(desc)} {mark}</span></div>'
        )
    preview_rows = "".join(rows)
    body = f"""
<section class="hero">
  <div class="hero-inner">
    <div class="hero-copy">
      <p class="eyebrow">Neovim 0.12+ · Linux / macOS</p>
      <h1>一套能直接用的<br><em>Neovim 配置</em></h1>
      <p class="lede">{html_escape(SITE['repo'])}：{total_specs} 个插件规格、{total_plugins} 章手册，一条命令装好。
      装完之后靠 which-key 发现按键，按手册逐项上手。</p>
      <div class="hero-cta">
        <a class="btn" href="getting-started.html">开始安装 <span aria-hidden="true">→</span></a>
        <a class="btn ghost" href="keys.html">按场景查按键</a>
      </div>
    </div>
    <div class="term" aria-label="安装命令">
      <div class="term-bar"><i></i><i></i><i></i><span>~/nvim</span></div>
      <pre class="term-body"><code><span class="pr">$</span> git clone https://github.com/{SITE['repo']}.git ~/nvim
<span class="pr">$</span> bash ~/nvim/init.sh
<span class="dim"># 已有 dotfiles？用子模块方式，见安装页</span></code></pre>
    </div>
  </div>
</section>

<section class="facts">
  <div class="facts-inner">
    <div class="fact"><b>{total_plugins}</b><span>插件章节</span></div>
    <div class="fact"><b>{len(keymaps)}</b><span>可查按键</span></div>
    <div class="fact"><b>0.12+</b><span>Neovim 版本</span></div>
    <div class="fact"><b>3</b><span>平台支持</span></div>
  </div>
</section>

<section class="preview">
  <div class="preview-inner">
    <h2>按键长什么样</h2>
    <p class="lede">构建时从运行中的 Neovim 导出，与仓库里的配置一致。</p>
    <div class="preview-grid">{preview_rows}</div>
    <p class="preview-more"><a href="keys.html">查看全部 {len(keymaps)} 个按键 →</a></p>
  </div>
</section>

<section class="specs">
  <div class="specs-inner">
    <h2>仓库里有什么</h2>
    <dl class="spec-list">
      <div><dt>{total_specs}</dt><dd>插件规格，全部在 <code>lua/plugins/</code></dd></div>
      <div><dt>{total_plugins}</dt><dd>章插件手册</dd></div>
      <div><dt>{len(keymaps)}</dt><dd>条按键，构建时从运行中的 Neovim 导出</dd></div>
      <div><dt>0.12+</dt><dd>Neovim 版本下限，Treesitter 走 main 分支</dd></div>
      <div><dt>3</dt><dd>平台：Linux、macOS、WSL</dd></div>
      <div><dt>2</dt><dd>装法：独立 clone、dotfiles 子模块</dd></div>
    </dl>
  </div>
</section>


<section class="cards">
  <div class="cards-inner">
    <h2>它是什么</h2>
    <div class="card-grid">
      <div class="card">
        <p class="card-k">开箱可用</p>
        <h3>装好就能写代码</h3>
        <p>依赖、插件、Treesitter parser 都由安装脚本处理。缺什么会告诉你，不会留一个半成品环境。</p>
      </div>
      <div class="card">
        <p class="card-k">可读可改</p>
        <h3>41 个插件规格全在仓库里</h3>
        <p>没有藏在别处的默认值。每章手册都指着具体文件，改配置时知道自己在改什么。</p>
      </div>
      <div class="card">
        <p class="card-k">按键可查</p>
        <h3>{len(keymaps)} 个按键从源码生成</h3>
        <p>按键页由构建脚本直接解析配置源生成，不是手抄的表格——它不会和你装的版本不一致。</p>
      </div>
      <div class="card">
        <p class="card-k">两种装法</p>
        <h3>独立仓库或 dotfiles 子模块</h3>
        <p>单机用可以独立 clone；多机同步走 dotfiles 子模块，两条路径都保持可用。</p>
      </div>
    </div>
  </div>
</section>

<section class="routes">
  <div class="routes-inner">
    <h2>从这里开始</h2>
    <ul class="route-list">
      <li><a href="getting-started.html">安装与更新</a><span>依赖清单、安装命令、更新与卸载、常见失败</span></li>
      <li><a href="keys.html">按键速查</a><span>按场景分组，附完整键位表</span></li>
      <li><a href="plugins.html">插件手册</a><span>{total_plugins} 章，每章解决什么问题、怎么用、练习</span></li>
      <li><a href="guides.html">指南</a><span>Treesitter、剪贴板、Markdown 等专题记录</span></li>
    </ul>
  </div>
</section>
"""
    return page(f"{SITE['name']} — {SITE['tagline']}", body, "index", is_home=True)


SCENES = [
    ("文件与搜索", ["<leader>f", "<leader><space>", "<leader>/", "<leader>e"]),
    ("Git", ["<leader>g", "]h", "[h", "]H", "[H"]),
    ("代码与 LSP", ["<leader>c", "gd", "gr", "K"]),
    ("搜索替换", ["<leader>s"]),
    ("多光标", ["<C-", "<up>", "<down>", "ga", "<leader>a", "<leader>n", "<leader>s", "<leader>N"]),
    ("诊断与 quickfix", ["<leader>x", "]d", "[d", "]q", "[q"]),
    ("界面开关", ["<leader>u", "<leader>w"]),
]


def _matches(lhs: str, prefixes: list[str]) -> bool:
    return any(lhs.startswith(p) for p in prefixes)


def build_keys(keymaps: list[dict]) -> str:
    # Collapse identical lhs entries that only differ by mode, and drop the
    # which-key group placeholders (no description) except where they carry one.
    merged: dict[str, dict] = {}
    for row in keymaps:
        lhs = row["lhs"]
        if lhs in ("<Space>", " ", "SPC "):
            continue
        cur = merged.get(lhs)
        if cur is None:
            merged[lhs] = {"lhs": lhs, "modes": list(row["modes"]), "desc": fix_desc(row["desc"])}
        else:
            for m in row["modes"]:
                if m not in cur["modes"]:
                    cur["modes"].append(m)
            if not cur["desc"] and fix_desc(row["desc"]):
                cur["desc"] = fix_desc(row["desc"])

    rows = list(merged.values())

    def table(items: list[dict]) -> str:
        items = sorted(items, key=lambda r: (len(r["lhs"]), r["lhs"].lower()))
        trs = []
        for r in items:
            desc = html_escape(r["desc"]) if r["desc"] else '<span class="tdim">—</span>'
            trs.append(
                f'<tr><td class="k">{render_key(r["lhs"])}</td>'
                f'<td>{desc}</td>'
                f'<td class="m">{html_escape("".join(r["modes"]))}</td></tr>'
            )
        return f'<table class="keys"><tbody>{"".join(trs)}</tbody></table>'

    # Assign each key to the first scene it matches; leftovers go to "其它".
    used: set[str] = set()
    blocks = []
    for name, prefixes in SCENES:
        items = [r for r in rows if r["lhs"] not in used and _matches(r["lhs"], prefixes)]
        if not items:
            continue
        for r in items:
            used.add(r["lhs"])
        anchor = f'id="g-{_slugify(name)}"'
        blocks.append(
            f'<section class="keygroup" {anchor}><h2>{html_escape(name)}'
            f'<span>{len(items)}</span></h2>{table(items)}</section>'
        )

    rest = [r for r in rows if r["lhs"] not in used]
    if rest:
        blocks.append(
            f'<section class="keygroup" id="rest"><h2>其它<span>{len(rest)}</span></h2>'
            f"{table(rest)}</section>"
        )

    inner = f"""
<p class="lede">下表由构建脚本从运行中的 Neovim 导出（<code>nvim_get_keymap</code>），
不是手抄的清单。按 <kbd>Space</kbd> 后稍停可看 which-key 提示；
<code>:verbose nmap</code> 可查任意键的最终来源。</p>
<p class="kcount"><b>{len(rows)}</b> 个可用按键 · 按场景分组</p>
<div class="keygrid">{''.join(blocks)}</div>
"""
    body = f"""
<div class="wrap doc">
  <aside class="side">{side_nav("keys")}</aside>
  <article class="prose">
    <p class="crumb"><a href="index.html">首页</a> / 按键速查</p>
    <h1>按键速查</h1>
    {inner}
  </article>
</div>
"""
    return page(f"按键速查 — {SITE['name']}", body, "keys")


def build_plugin_index() -> str:
    sections = []
    for category, entries in CATALOG:
        cards = "".join(
            f'<a class="pcard" href="plugins/{slug}.html">'
            f'<span class="pcard-k">{html_escape(kind)}</span>'
            f"<strong>{html_escape(name)}</strong>"
            f"<em>{html_escape(desc)}</em></a>"
            for slug, name, kind, desc in entries
        )
        sections.append(
            f'<section class="pgroup"><h2>{html_escape(category)}</h2>'
            f'<div class="pgrid">{cards}</div></section>'
        )
    total = sum(len(e) for _c, e in CATALOG)
    inner = (
        f'<p class="lede">{total} 章，按插件分组。多数章节先说明它解决什么问题，'
        f'再给本配置里的用法和一组练习。</p>'
    ) + "".join(sections)
    return article_shell("插件手册", inner, "plugins", '<a href="index.html">首页</a> / 插件手册', "plugins/")


def build_plugin_pages() -> int:
    count = 0
    for category, entries in CATALOG:
        for slug, name, kind, desc in entries:
            src = DOCS / "plugins" / "chapters" / f"{slug}.md"
            if not src.exists():
                continue
            md_text = src.read_text(encoding="utf-8")
            html = rewrite_source_links(strip_h1(render_md(md_text)), "plugins")
            # Rewrite the "back to index" line into our own breadcrumb.
            html = re.sub(r"<blockquote>.*?</blockquote>\s*", "", html, count=1, flags=re.S)
            html = html.replace('href="../PLUGINS.md"', 'href="index.html"')
            html = re.sub(r'href="\.\./PLUGINS\.md"', 'href="plugins.html"', html)
            body = f"""
<div class="wrap doc">
  <aside class="side">{side_nav("plugins", "../plugins/")}</aside>
  <article class="prose">
    <p class="crumb"><a href="../index.html">首页</a> / <a href="../plugins.html">插件手册</a> / {html_escape(category)}</p>
    <h1>{html_escape(name)}</h1>
    <p class="pmeta"><span>{html_escape(kind)}</span> {html_escape(desc)}</p>
    {html}
    <p class="pnav"><a href="../plugins.html">← 全部插件</a><a href="https://github.com/{SITE['repo']}/blob/main/docs/plugins/chapters/{slug}.md">在 GitHub 上编辑</a></p>
  </article>
</div>
"""
            out = OUT / "plugins" / f"{slug}.html"
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(page(f"{name} — {SITE['name']}", body, "plugin-page"), encoding="utf-8")
            count += 1
    return count


GUIDE_SLUGS: set[str] = set()


def rewrite_source_links(html: str, page_dir: str = "guides") -> str:
    """Turn repository-only and cross-section links into real destinations."""
    def repl(m):
        target = m.group(1)
        # Sibling chapter written as .md
        mm = re.match(r"^([a-z0-9.\-]+)\.md$", target)
        if mm and page_dir == "plugins":
            return f'href="{mm.group(1)}.html"'
        # Cross-section references
        for sect in ("reference", "development", "guides"):
            if target.startswith(f"../{sect}/"):
                tail = target[len(f"../{sect}/") :].replace(".md", ".html")
                # reference/ and development/ are published flat under guides/.
                base = "../guides/" if page_dir == "plugins" else ""
                return f'href="{base}{tail}"'
        # Repository files that are not published pages
        if re.match(r"^\.\./\.\./(lua|tests|scripts|docs)/", target) or \
           re.match(r"^\.\./(lua|tests|scripts)/", target) or \
           target.startswith("../CONFIG-"):
            rel = target.replace("../", "")
            return f'href="https://github.com/{SITE["repo"]}/blob/main/{rel}"'
        return m.group(0)
    return re.sub(r'href="([^"]+)"', repl, html)


def build_guides() -> int:
    global GUIDE_LINKS
    entries: list[tuple[Path, str, str]] = []
    for sub in ("guides", "reference", "development"):
        for p in sorted((DOCS / sub).glob("*.md")):
            md_text = p.read_text(encoding="utf-8")
            title = first_h1(md_text, p.stem)
            entries.append((p, p.stem.lower(), title))

    GUIDE_LINKS = [(slug, title) for _p, slug, title in entries]

    for path, slug, title in entries:
        md_text = path.read_text(encoding="utf-8")
        html = rewrite_source_links(strip_h1(render_md(md_text)))
        body = f"""
<div class="wrap doc">
  <aside class="side">{side_nav("guides")}</aside>
  <article class="prose">
    <p class="crumb"><a href="../index.html">首页</a> / <a href="../guides.html">指南</a></p>
    <h1>{html_escape(title)}</h1>
    {html}
  </article>
</div>
"""
        out = OUT / "guides" / f"{slug}.html"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(page(f"{title} — {SITE['name']}", body, "guide-page"), encoding="utf-8")

    cards = "".join(
        f'<a class="pcard" href="guides/{slug}.html"><strong>{html_escape(title)}</strong>'
        f'<em>{html_escape(str(path.relative_to(DOCS)))}</em></a>'
        for path, slug, title in entries
    )
    inner = (
        '<p class="lede">配置相关问题、平台差异与实现说明。这些是排查时的第一手记录，'
        "不是复述官方文档。</p>"
        f'<div class="pgrid wide">{cards}</div>'
    )
    body = f"""
<div class="wrap doc">
  <aside class="side">{side_nav("guides", guide_prefix="guides/")}</aside>
  <article class="prose">
    <p class="crumb"><a href="index.html">首页</a> / 指南</p>
    <h1>指南</h1>
    {inner}
  </article>
</div>
"""
    (OUT / "guides.html").write_text(
        page(f"指南 — {SITE['name']}", body, "guides"), encoding="utf-8"
    )
    return len(entries)


def build_doc_page(slug: str, nav_key: str, title: str, src: Path | None) -> None:
    toc = ""
    if src and src.exists():
        md_text = src.read_text(encoding="utf-8")
        title = first_h1(md_text, title)
        MD.reset()
        html = MD.convert(md_text)
        try:
            toc_html = MD.toc
        except AttributeError:
            toc_html = ""
        html = strip_h1(html)
        if toc_html and md_text.count("\n## ") >= 3:
            toc = f'<nav class="toc"><p class="toc-title">本页内容</p>{toc_html}</nav>'
    else:
        html = "<p>内容整理中。</p>"
    body = f"""
<div class="wrap doc">
  <aside class="side"></aside>
  <article class="prose">
    <p class="crumb"><a href="index.html">首页</a> / {html_escape(title)}</p>
    <h1>{html_escape(title)}</h1>
    {toc}
    {html}
  </article>
</div>
"""
    (OUT / f"{slug}.html").write_text(
        page(f"{title} — {SITE['name']}", body, nav_key), encoding="utf-8"
    )


def main() -> int:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)

    keymaps = load_keymaps(refresh="--refresh-keys" in sys.argv)

    (OUT / "index.html").write_text(build_home(keymaps), encoding="utf-8")
    (OUT / "keys.html").write_text(build_keys(keymaps), encoding="utf-8")
    (OUT / "plugins.html").write_text(build_plugin_index(), encoding="utf-8")

    n_plugins = build_plugin_pages()
    n_guides = build_guides()

    # Top-level prose pages rendered from docs/.
    build_doc_page("getting-started", "getting-started", "安装与更新", DOCS / "INSTALL.md")

    # Static assets.
    (OUT / "assets").mkdir(exist_ok=True)
    for name in ("site.css", "site.js"):
        shutil.copy(ROOT / "site" / name, OUT / "assets" / name)

    # Redirect legacy paths.
    (OUT / "tutorials").mkdir(exist_ok=True)
    (OUT / "tutorials" / "index.html").write_text(
        '<meta http-equiv="refresh" content="0;url=../plugins.html">', encoding="utf-8"
    )

    print(f"pages: 1 home, 1 keys, 1 plugins, {n_plugins} plugin chapters, {n_guides} guides")
    print(f"keymaps parsed: {len(keymaps)}")
    print(f"output: {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
