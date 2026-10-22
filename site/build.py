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
import os
import re
import shutil
import sys
from html.parser import HTMLParser
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
    ("getting-started", "安装"),
    ("tutorials", "教程"),
    ("plugins", "插件"),
    ("wiki", "百科"),
    ("reference", "知识"),
    ("changes", "最近改动"),
]

# Ordered series for the tutorials section: (slug, short title).
TUTORIALS = [
    ("01-why-vim", "起步：先把观念摆正"),
    ("02-moving-around", "光标移动"),
    ("03-basic-editing", "基本编辑"),
    ("04-yank-and-registers", "复制与寄存器"),
    ("05-search-and-replace", "查找与替换"),
    ("06-files-and-buffers", "文件与缓冲"),
    ("07-visual-and-windows", "可视模式与窗口"),
    ("08-cmdline-and-help", "命令行与帮助"),
    ("09-options", "选项与配置"),
    ("10-regex-and-global", "正则与 :g"),
    ("11-operator-grammar", "操作符与动作语法"),
    ("12-text-objects", "文本对象"),
    ("13-macros", "宏与重复"),
    ("14-mappings", "映射与 Leader 设计"),
]

WIKI = [
    ("01-architecture", "架构：buffer、window、tab"),
    ("02-clipboard", "剪贴板与系统集成"),
    ("03-filetypes", "文件类型与语法高亮"),
    ("04-lsp", "LSP 是什么"),
    ("05-treesitter", "Treesitter 与正则高亮"),
    ("06-folding", "折叠机制"),
    ("07-encoding", "编码与换行符"),
    ("08-ime-and-cjk", "输入法与中文处理"),
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
        ("markview", "markview.nvim", "公开", "Markdown 等文档预览"),
        ("multicursor.nvim", "multicursor.nvim", "公开", "多光标匹配与批量编辑"),
        ("nvim-ufo", "nvim-ufo", "公开", "代码折叠"),
    ]),
    ("阅读、诊断与撤销", [
        ("hover-nvim", "hover.nvim", "公开", "统一的悬浮文档窗口"),
        ("trouble-nvim", "trouble.nvim", "公开", "诊断、符号与引用面板"),
        ("nvim-bqf", "nvim-bqf", "公开", "快速修复列表的预览与高亮"),
    ]),
    ("阅读与上下文", [
        ("nvim-treesitter-context", "nvim-treesitter-context", "公开", "固定在窗口顶部的结构上下文"),
        ("hlchunk.nvim", "hlchunk.nvim", "公开", "当前代码块高亮"),
    ]),
    ("导航、标记与编辑辅助", [
        ("grapple.nvim", "grapple.nvim", "公开", "按分支保存的文件标签"),
        ("portal.nvim", "portal.nvim", "公开", "可搜索的跳转与改动历史"),
        ("vim-matchup", "vim-matchup", "公开", "增强的 % 匹配与结构选中"),
        ("dial.nvim", "dial.nvim", "公开", "可扩展的递增与递减"),
    ]),
    ("Git 与项目记录", [
        ("gitsigns", "gitsigns.nvim", "公开", "Git 行变更与 hunk 操作"),
        ("diffview", "diffview.nvim", "公开", "分支差异与文件历史"),
        ("bookmark", "bookmark.nvim", "私有", "项目书签"),
    ]),
    ("界面、颜色与辅助操作", [
        ("heirline", "heirline.nvim", "公开", "状态栏与上下文栏"),
        ("which-key", "which-key.nvim", "公开", "快捷键提示"),
        ("indent-guides", "snacks.nvim 缩进线", "公开", "缩进参考线与范围线"),
        ("rainbow-delimiters", "rainbow-delimiters.nvim", "公开", "成对括号着色"),
        ("satellite", "satellite.nvim", "公开", "窗口边缘位置标记"),
        ("nvim-hlslens", "nvim-hlslens", "公开", "搜索结果位置提示"),
        ("fidget", "fidget.nvim", "公开", "LSP 任务进度提示"),
        ("mini-pairs", "mini.pairs", "公开", "自动补全括号与引号"),
        ("mini-hipatterns", "mini.hipatterns", "公开", "颜色值文本高亮"),
        ("ccc", "ccc.nvim", "公开", "取色与颜色转换"),
        ("smart-paste", "smart-paste.nvim", "私有", "系统剪贴板与缩进粘贴"),
        ("noice", "noice.nvim", "公开", "命令行、消息与确认框浮层"),
    ]),
    ("私有语言工具", [
        ("cobol", "cobol.nvim", "私有", "COBOL 导航、格式与辅助"),
        ("batch", "batch.nvim", "私有", "Windows Batch 标签导航与分析"),
        ("contextline", "contextline.nvim", "私有", "语言结构上下文栏"),
        ("vimquest", "VimQuest.nvim", "私有", "词汇练习"),
        ("position-ruler", "position-ruler.nvim", "私有", "定长文件的字符列标尺"),
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
-- Why this is not just `nvim --headless -u init.lua`.
--
-- `-u <file>` does not put the checkout on the runtimepath, so every
-- require("config.*") fails and config/keymaps-defaults.lua never runs. The
-- dump then silently loses every <leader> mapping. Prepending the resolved
-- config directory and requiring the keymap modules explicitly fixes that.
--
-- The dump happens synchronously: deferring it made nvim hang in this
-- environment, and the plugin load above already installs their keymaps.
local cfg = os.getenv("NVIM_DUMP_CONFIG") or vim.fn.stdpath("config")
local real = vim.fn.resolve(cfg)
vim.opt.rtp:prepend(real)
package.path = real .. "/lua/?.lua;" .. real .. "/lua/?/init.lua;" .. package.path

for _, mod in ipairs({ "config.keymaps-defaults", "config.keymaps" }) do
  pcall(require, mod)
end

local ok = pcall(require, "lazy")
if ok then
  local lazy = require("lazy")
  for _, p in ipairs(lazy.plugins()) do
    local st = p._ and p._.loaded
    local is_loaded = (type(st) == "table" and next(st) ~= nil) or st == true
    if not is_loaded then
      pcall(function() lazy.load({ plugins = { p.name } }) end)
    end
  end
end

local leader = vim.g.mapleader or " "
local out = {}
for _, mode in ipairs({ "n", "x", "o", "i", "t", "c" }) do
  local maps = vim.api.nvim_get_keymap(mode)
  table.sort(maps, function(a, b) return a.lhs < b.lhs end)
  for _, m in ipairs(maps) do
    local lhs = m.lhs
    if leader ~= "" and lhs:sub(1, #leader) == leader and lhs ~= leader then
      lhs = "<leader>" .. lhs:sub(#leader + 1)
    end
    out[#out + 1] = table.concat({ lhs, m.mode, ((m.desc or ""):gsub("\\t", " ")) }, "\\t")
  end
end
vim.fn.writefile(vim.env.KEYMAP_DUMP or "/tmp/nvim-keys.tsv", out)
vim.cmd("qa!")
"""


def refresh_keymaps() -> list[dict]:
    """Run a headless Neovim and capture the real keymap set."""
    import subprocess
    import tempfile
    import os

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
            timeout=300,
            env={
                **os.environ,
                "KEYMAP_DUMP": "/tmp/nvim-keys.tsv",
                # stdpath("config") is unreliable here; point at the checkout.
                "NVIM_DUMP_CONFIG": str(ROOT),
            },
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
        if rows:
            return rows
        # In CI a failed dump means the plugins did not install. Falling back to
        # the cache would publish a reference table that no longer matches the
        # configuration, so fail instead.
        if os.environ.get("KEYMAP_STRICT") == "1":
            raise BuildError(
                "keymap refresh produced nothing; plugins are probably not installed. "
                "Refusing to fall back to the cached table."
            )
        print(
            "warning: keymap refresh produced nothing; keeping site/keymaps.tsv.",
            file=sys.stderr,
        )
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
LSP_NAMES = {
    "code_action": "代码操作",
    "implementation": "跳到实现",
    "rename": "重命名符号",
    "references": "列出引用",
    "type_definition": "跳到类型定义",
    "signature_help": "参数提示",
    "document_symbol": "文档符号列表",
    "definition": "跳到定义",
    "declaration": "跳到声明",
    "hover": "悬停文档",
    "format": "格式化",
}

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
    "vim.snippet.jump if active, otherwise <Tab>": "跳转 snippet 占位符，否则 Tab",
    "vim.snippet.jump if active, otherwise <S-Tab>": "跳转上一个 snippet 占位符，否则 Shift-Tab",
}


def fix_desc(desc: str) -> str:
    d = (desc or "").strip()
    if not d:
        return ""
    if d in DESC_FIXES:
        return DESC_FIXES[d]
    # Unwrap common LSP helpers into readable Chinese.
    # Any Lua API description is unreadable to a reader; label it instead.
    m = re.match(r"^vim\.lsp\.([a-z_]+)\.([a-z_]+)\(\)$", d)
    if m:
        group, action = m.group(1), m.group(2)
        if group == "codelens":
            return "执行 CodeLens（LSP）" if action == "run" else f"CodeLens：{action}（LSP）"
        return f"{LSP_NAMES.get(action, action.replace('_', ' '))}（LSP）"
    if re.match(r"^vim\.diagnostic\.([a-z_]+)\(\)$", d):
        return f"诊断：{re.match(r'^vim\.diagnostic\.([a-z_]+)\(\)$', d).group(1).replace('_', ' ')}"
    if re.match(r"^require\(", d) or d.startswith("vim.treesitter"):
        return d
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
        active = current == slug or current == f"{slug}-index"
        cls = "nav-link current" if active else "nav-link"
        items.append(f'<a class="{cls}" href="{rel_root(current)}{slug}.html">{label}</a>')
    return "\n".join(items)


def rel_root(current: str) -> str:
    """Relative prefix back to the site root.

    Top-level pages must not climb; anything under a subdirectory does.
    """
    # Anything published under a subdirectory needs to climb one level.
    subdirs = {"guide-page", "plugin-page", "tutorials", "wiki", "reference"}
    return "../" if current in subdirs else ""


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
      <a class="nav-search" href="{prefix}search.html" title="站内搜索（/）"><span aria-hidden="true">⌕</span>搜索</a>
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


def side_filter(placeholder: str) -> str:
    """Client-side filter box for a sidebar; behaviour lives in site.js."""
    return (
        '<div class="side-search">'
        '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/>'
        '<path d="M20 20l-4.2-4.2"/></svg>'
        f'<input type="search" class="side-filter" placeholder="{html_escape(placeholder)}" '
        'aria-label="筛选列表" spellcheck="false">'
        '<button type="button" class="side-clear" aria-label="清除" hidden>&times;</button>'
        '</div>'
    )


def side_nav(current: str, prefix: str = "", guide_prefix: str = "", current_slug: str = "") -> str:
    if current == "plugins" or current == "plugins-index":
        groups = []
        for category, entries in CATALOG:
            # Mark the group containing the current page so it can start open.
            here = any(slug == current_slug for slug, *_ in entries)
            cls = "side-group open" if here else "side-group"
            links = "".join(
                f'<a href="{prefix}{slug}.html" data-side-item '
                f'data-label="{html_escape((name + " " + desc).lower())}"'
                f'{" class=current" if slug == current_slug else ""}>'
                f'<span>{html_escape(name)}</span></a>'
                for slug, name, _kind, desc in entries
            )
            groups.append(
                f'<div class="{cls}">'
                f'<button class="side-head" type="button" aria-expanded="{str(here).lower()}">'
                f'<em>{html_escape(category)}</em><i aria-hidden="true">{len(entries)}</i></button>'
                f'<div class="side-items">{links}</div></div>'
            )
        return (
            '<p class="side-title">插件手册</p>'
            + side_filter("筛选插件…")
            + "".join(groups)
        )
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
            f'<a href="#g-{html_escape(slug)}" data-side-item '
            f'data-label="{html_escape((label + " " + desc).lower())}">'
            f'<span>{html_escape(label)}</span></a>'
            for slug, (label, desc) in [(_slugify(n), (n, d)) for n, d in scenes]
        )
        return (
            '<p class="side-title">按场景</p>'
            + side_filter("筛选场景…")
            + '<div class="side-group open">' + links
            + '</div><div class="side-group"><a href="#all"><span>完整键位表</span></a>'
            + '<a href="getting-started.html"><span>安装与更新</span></a></div>'
        )
    if current == "guides":
        links = "".join(
            f'<a href="{guide_prefix}{slug}.html" data-side-item '
            f'data-label="{html_escape(label.lower())}"><span>{html_escape(label)}</span></a>'
            for slug, label in GUIDE_LINKS
        )
        return (
            f'<p class="side-title">指南</p>'
            + side_filter("筛选指南…")
            + f'<div class="side-group open">{links}</div>'
        )
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


<section class="routes">
  <div class="routes-inner">
    <h2>从这里开始</h2>
    <ul class="route-list">
      <li><a href="getting-started.html">安装</a><span>依赖清单、安装命令、更新与卸载、常见失败</span></li>
      <li><a href="tutorials.html">教程</a><span>从零学 Neovim，14 篇，口语讲解，配练习</span></li>
      <li><a href="plugins.html">插件</a><span>{total_plugins} 章，每个插件解决什么问题、怎么用</span></li>
      <li><a href="wiki.html">百科</a><span>架构、LSP、Treesitter、编码等概念与机制</span></li>
      <li><a href="reference.html">知识</a><span>按键速查、选项总表、命令、术语对照</span></li>
      <li><a href="changes.html">最近改动</a><span>配置和手册最近改了什么</span></li>
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



def plugin_sequence() -> list[tuple[str, str, str, str]]:
    """Flat reading order of the plugin chapters: catalogue order, as listed.

    The sidebar groups by topic; the pager walks the same list end to end so
    "next" always means the next chapter in the book, not the next in a group.
    """
    flat: list[tuple[str, str, str, str]] = []
    for category, entries in CATALOG:
        for slug, name, kind, desc in entries:
            flat.append((slug, name, kind, category))
    return flat


def plugin_pager(slug: str) -> str:
    """Previous/next links for a plugin chapter, or nothing when alone."""
    seq = plugin_sequence()
    index = next((i for i, item in enumerate(seq) if item[0] == slug), None)
    if index is None:
        return ""

    parts: list[str] = []
    if index > 0:
        prev_slug, prev_name, _k, _c = seq[index - 1]
        parts.append(
            f'<a class="pager-link prev" href="{prev_slug}.html">'
            f'<span class="pager-dir">← 上一篇</span>'
            f'<strong>{html_escape(prev_name)}</strong></a>'
        )
    else:
        parts.append('<span class="pager-link disabled"></span>')

    if index < len(seq) - 1:
        next_slug, next_name, _k, _c = seq[index + 1]
        parts.append(
            f'<a class="pager-link next" href="{next_slug}.html">'
            f'<span class="pager-dir">下一篇 →</span>'
            f'<strong>{html_escape(next_name)}</strong></a>'
        )
    else:
        parts.append(
            '<a class="pager-link next" href="../plugins.html">'
            '<span class="pager-dir">读完 →</span><strong>回到插件手册</strong></a>'
        )

    position = f'{index + 1} / {len(seq)}'
    return (
        f'<nav class="pager" aria-label="章节翻页">'
        f'<p class="pager-pos">{position}</p>'
        f'<div class="pager-row">{"".join(parts)}</div>'
        f'</nav>'
    )


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
  <aside class="side">{side_nav("plugins", "../plugins/", current_slug=slug)}</aside>
  <article class="prose">
    <p class="crumb"><a href="../index.html">首页</a> / <a href="../plugins.html">插件手册</a> / {html_escape(category)}</p>
    <h1>{html_escape(name)}</h1>
    <p class="pmeta"><span>{html_escape(kind)}</span> {html_escape(desc)}</p>
    {html}
    {plugin_pager(slug)}
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
        mm = re.match(r"^([A-Za-z0-9._\-]+)\.md$", target)
        if mm:
            return f'href="{mm.group(1).lower()}.html"'
        # Cross-section references
        # Cross-section links: ../wiki/x.md, ../guides/x.md, ../reference/x.md.
        # Sections published at their own path keep it; development/ lives
        # under guides/.
        for sect in ("wiki", "tutorials", "reference", "guides", "development"):
            if target.startswith(f"../{sect}/"):
                tail = target[len(f"../{sect}/") :].replace(".md", ".html")
                published = "guides" if sect == "development" else sect
                if page_dir in ("plugins", "tutorials", "wiki", "reference"):
                    return f'href="../{published}/{tail}"'
                return f'href="{published}/{tail}"'
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
    for sub in ("guides", "development"):
        for p in sorted((DOCS / sub).glob("*.md")):
            md_text = p.read_text(encoding="utf-8")
            title = first_h1(md_text, p.stem)
            entries.append((p, p.stem.lower(), title))

    GUIDE_LINKS = [(slug, title) for _p, slug, title in entries]

    for path, slug, title in entries:
        md_text = path.read_text(encoding="utf-8")
        html = rewrite_source_links(strip_h1(render_md(md_text)), "guides")
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

    def guide_kind(path: Path) -> str:
        rel = str(path.relative_to(DOCS))
        if rel.startswith("reference/"):
            return "参考"
        if rel.startswith("development/"):
            return "实现说明"
        return "使用指南"

    cards = "".join(
        f'<a class="pcard" href="guides/{slug}.html">'
        f'<span class="pcard-k">{guide_kind(path)}</span>'
        f'<strong>{html_escape(title)}</strong></a>'
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



# ---------------------------------------------------------------------------
# Build checks
#
# These catch the two classes of mistake that actually happened here: a
# hand-edited stylesheet that stopped parsing partway through, and links that
# pointed at files that no longer exist. A broken site should fail the build,
# not ship and get noticed later.
# ---------------------------------------------------------------------------


# --- P1: the catalogue must match the configuration ------------------------
#
# CATALOG is written by hand and docs/plugins/chapters/ holds one file per
# chapter. Adding a plugin without a chapter, or deleting a plugin while its
# chapter remains, both used to pass silently. Compare the three sources and
# report the difference.

REPO_SPEC = re.compile(r'^\s{2,8}"([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)"', re.M)


def declared_plugins() -> dict[str, set[str]]:
    """repo -> spec files, as declared in lua/plugins/*.lua."""
    found: dict[str, set[str]] = {}
    for path in sorted((ROOT / "lua" / "plugins").glob("*.lua")):
        text = path.read_text(encoding="utf-8")
        for repo in REPO_SPEC.findall(text):
            found.setdefault(repo, set()).add(path.stem)
    return found


def check_catalogue() -> None:
    chapters = {p.stem for p in (DOCS / "plugins" / "chapters").glob("*.md")}
    catalogue = {slug for _c, entries in CATALOG for slug, *_ in entries}

    problems: list[str] = []

    missing_chapter = sorted(catalogue - chapters)
    if missing_chapter:
        problems.append(
            "CATALOG lists chapters with no file in docs/plugins/chapters/: "
            + ", ".join(missing_chapter)
        )

    orphan_chapter = sorted(chapters - catalogue)
    if orphan_chapter:
        problems.append(
            "docs/plugins/chapters/ has files not listed in CATALOG (they would "
            "never be published): " + ", ".join(orphan_chapter)
        )

    # Chapters whose declared source file has been deleted or renamed.
    for path in sorted((DOCS / "plugins" / "chapters").glob("*.md")):
        text = path.read_text(encoding="utf-8")
        m = re.search(r"<!--\s*source:\s*(lua/plugins/[\w.-]+\.lua)\s*-->", text)
        if m and not (ROOT / m.group(1)).exists():
            problems.append(f"{path.name} declares source {m.group(1)}, which no longer exists")

    if problems:
        raise BuildError("\n".join(problems))



# --- P2: keys cited in chapters must exist in the configuration ------------
#
# The runtime dump only contains global mappings: keys registered in on_attach
# or after FileType are buffer-local and never appear in a headless dump with no
# files open. So the check also scans the Lua sources for string key
# definitions. Both sources are unioned before deciding a key is unknown.

KEY_STRING = re.compile(r'["\'](<leader>[A-Za-z0-9<>_.\-]*)["\']')
CITED = re.compile(r'`(<leader>[A-Za-z0-9<>_.\-]+)`')


def config_keys() -> set[str]:
    """Keys the configuration can produce: runtime dump plus source strings."""
    keys: set[str] = set()

    if KEYMAP_CACHE.exists():
        for line in KEYMAP_CACHE.read_text(encoding="utf-8").splitlines():
            parts = line.split("\t")
            if parts and parts[0]:
                keys.add(parts[0])

    for path in (ROOT / "lua").rglob("*.lua"):
        text = path.read_text(encoding="utf-8")
        for m in KEY_STRING.finditer(text):
            keys.add(m.group(1))
    return keys


def check_keymap_freshness() -> None:
    """The committed dump must not predate the configuration it describes."""
    newest = max(
        (p.stat().st_mtime for p in (ROOT / "lua").rglob("*.lua")),
        default=0,
    )
    cache = KEYMAP_CACHE.stat().st_mtime if KEYMAP_CACHE.exists() else 0
    if cache and newest > cache:
        stale_days = (newest - cache) / 86400
        msg = (
            f"site/keymaps.tsv is older than lua/ by {stale_days:.1f} day(s). "
            "Run: python3 site/build.py --refresh-keys"
        )
        if os.environ.get("KEYMAP_REQUIRE_FRESH") == "1":
            raise BuildError(msg)
        print(f"warning: {msg}", file=sys.stderr)


def check_cited_keys() -> None:
    """Report chapter references to keys the configuration never defines."""
    keys = config_keys()
    # A bare prefix like <leader>c is a group, not a binding; skip anything
    # whose full form is a prefix of a real key.
    groups = {k[:i] for k in keys for i in range(2, len(k))}
    unknown: dict[str, set[str]] = {}
    for path in sorted((DOCS / "plugins" / "chapters").glob("*.md")):
        text = path.read_text(encoding="utf-8")
        for key in set(CITED.findall(text)):
            if key in keys or key in groups:
                continue
            unknown.setdefault(key, set()).add(path.stem)

    if unknown:
        lines = [f"{k} (in {', '.join(sorted(v))})" for k, v in sorted(unknown.items())]
        raise BuildError(
            f"{len(unknown)} key(s) cited in chapters but not found in the configuration: "
            + "; ".join(lines[:8])
        )



# --- P3: every plugin in the config should be reachable from the handbook ----
#
# Plugins get added to lua/plugins/ and the handbook quietly falls behind.
# This compares the declared repositories against the published chapters and
# reports anything that has no page, using a normalised name match so
# "blink.cmp" still matches the blink-cmp chapter.

SKIP_REPOS = {
    # Covered together on the dependencies page.
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "kevinhwang91/promise-async",
}
NOT_REPOS = ("textDocument/", "use/", "diagnostics/", "file/")


def _normalise_name(text: str) -> str:
    return re.sub(r"[-._]", "", text.lower().replace(".nvim", ""))


def declared_repositories() -> dict[str, set[str]]:
    repos: dict[str, set[str]] = {}
    for path in sorted((ROOT / "lua" / "plugins").glob("*.lua")):
        text = path.read_text(encoding="utf-8")
        for repo in re.findall(r'"([A-Za-z0-9_.\-]+/[A-Za-z0-9_.\-]+)"', text):
            if repo.startswith(NOT_REPOS):
                continue
            repos.setdefault(repo, set()).add(path.stem)
    return repos


def check_plugin_coverage() -> None:
    chapters = {p.stem: _normalise_name(p.stem) for p in (DOCS / "plugins" / "chapters").glob("*.md")}
    uncovered: list[str] = []

    for repo, spec_files in sorted(declared_repositories().items()):
        if repo in SKIP_REPOS:
            continue
        name = _normalise_name(repo.split("/")[1])
        if any(name == chap or name in chap or chap in name for chap in chapters.values()):
            continue
        uncovered.append(f"{repo} (declared in {', '.join(sorted(spec_files))}.lua)")

    if uncovered:
        raise BuildError(
            f"{len(uncovered)} plugin(s) in lua/plugins/ have no handbook chapter: "
            + "; ".join(uncovered)
        )


class BuildError(Exception):
    pass


def check_css() -> None:
    """Braces must balance and no declaration may sit outside a rule block."""
    path = OUT / "assets" / "site.css"
    css = path.read_text(encoding="utf-8")

    opens, closes = css.count("{"), css.count("}")
    if opens != closes:
        raise BuildError(f"site.css: unbalanced braces ({opens} '{{' vs {closes} '}}')")

    depth = 0
    stray = []
    for lineno, line in enumerate(css.splitlines(), 1):
        if depth == 0 and line.strip().startswith("}"):
            stray.append(lineno)
        depth += line.count("{") - line.count("}")
        if depth < 0:
            depth = 0
    if stray:
        raise BuildError(
            f"site.css: {len(stray)} closing brace(s) with no open rule at line(s) "
            + ", ".join(str(n) for n in stray[:5])
        )

    depth = 0
    orphans = []
    for lineno, line in enumerate(css.splitlines(), 1):
        stripped = line.strip()
        if depth == 0 and stripped and not stripped.startswith(("/*", "*", "@", "}", ":root")):
            if ":" in stripped and stripped.endswith(";") and "{" not in stripped:
                orphans.append((lineno, stripped))
        depth += line.count("{") - line.count("}")
    if orphans:
        detail = ", ".join(f"line {n}: {t[:40]}" for n, t in orphans[:5])
        raise BuildError(f"site.css: {len(orphans)} declaration(s) outside any rule ({detail})")


class _RefCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.refs: list[str] = []

    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        for key in ("href", "src"):
            value = d.get(key, "")
            if value and not value.startswith(("http:", "https:", "mailto:", "#", "data:", "file:")):
                self.refs.append(value.split("#")[0].split("?")[0])


def check_links() -> None:
    """Every internal link must resolve, and every page needs a title and an h1."""
    broken: list[tuple[str, str]] = []
    headless: list[str] = []
    for page in OUT.rglob("*.html"):
        text = page.read_text(encoding="utf-8")
        if "<h1" not in text or "<title>" not in text:
            headless.append(str(page.relative_to(OUT)))
        collector = _RefCollector()
        collector.feed(text)
        for ref in set(collector.refs):
            if ref and not (page.parent / ref).resolve().exists():
                broken.append((str(page.relative_to(OUT)), ref))

    problems = []
    if broken:
        sample = "; ".join(f"{f} -> {r}" for f, r in broken[:5])
        problems.append(f"{len(broken)} broken internal link(s): {sample}")
    if headless:
        problems.append(f"{len(headless)} page(s) missing <h1> or <title>: {', '.join(headless[:5])}")
    if problems:
        raise BuildError("\n".join(problems))



# ---------------------------------------------------------------------------
# Site-wide search
#
# Build a JSON index of every page and ship it; site.js filters it in the
# browser. No service, no dependency — the index is small enough to inline.
# ---------------------------------------------------------------------------

def build_search_index() -> list[dict]:
    entries: list[dict] = []

    def add(title: str, kind: str, href: str, text: str) -> None:
        # Strip markdown and the boilerplate every chapter shares, so the
        # snippet shows content rather than "公开插件 · 回到插件目录".
        plain = re.sub(r"`{1,3}[^`]*`{1,3}", " ", text)
        plain = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", plain)
        plain = re.sub(r"^#\s+.*$", " ", plain, flags=re.M)
        for noise in ("公开插件", "私有插件", "依赖", "管理器", "回到插件目录",
                      "它解决什么问题", "在当前配置里怎么用", "动手练习",
                      "注意事项", "查快捷键和帮助"):
            plain = plain.replace(noise, " ")
        plain = re.sub(r"[#>*_|\-]{1,}", " ", plain)
        plain = re.sub(r"\s+", " ", plain).strip()
        entries.append({
            "t": title,
            "k": kind,
            "u": href,
            "s": plain[:220],
        })

    add("首页", "页面", "index.html", "Neovim 配置首页，安装入口、仓库内容、按键预览")
    add("安装与更新", "页面", "getting-started.html",
        (DOCS / "INSTALL.md").read_text(encoding="utf-8") if (DOCS / "INSTALL.md").exists() else "")
    add("按键速查", "页面", "keys.html",
        "按键速查表，按场景分组：文件搜索、Git、代码与 LSP、搜索替换、多光标、诊断、界面开关")

    for category, items in CATALOG:
        for slug, name, kind, desc in items:
            src = DOCS / "plugins" / "chapters" / f"{slug}.md"
            body = src.read_text(encoding="utf-8") if src.exists() else ""
            add(f"{name}（{category}）", kind, f"plugins/{slug}.html", desc + " " + body)

    for path in sorted((DOCS / "guides").glob("*.md")) + sorted((DOCS / "reference").glob("*.md")) + sorted((DOCS / "development").glob("*.md")):
        add(first_h1(path.read_text(encoding="utf-8"), path.stem), "指南",
            f"guides/{path.stem.lower()}.html", path.read_text(encoding="utf-8"))

    return entries


def build_search_page(entries: list[dict]) -> str:
    payload = json.dumps(entries, ensure_ascii=False, separators=(",", ":"))
    inner = f"""
<div class="search-page">
  <div class="search-box">
    <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/>
    <path d="M20 20l-4.2-4.2"/></svg>
    <input id="site-search" type="search" autofocus
           placeholder="搜索插件、按键、指南…（按 / 聚焦）"
           aria-label="站内搜索" spellcheck="false">
    <kbd>/</kbd>
  </div>
  <p class="search-meta" id="search-meta"></p>
  <div id="search-results" class="search-results" aria-live="polite"></div>
  <div class="search-hints" id="search-hints">
    <p class="search-hints-title">可以搜什么</p>
    <ul>
      <li>插件名，例如 <code>gitsigns</code>、<code>treesitter</code></li>
      <li>按键，例如 <code>&lt;leader&gt;gd</code>、<code>Ctrl-n</code></li>
      <li>概念，例如 <code>多光标</code>、<code>折叠</code>、<code>剪贴板</code></li>
      <li>页面标题，例如 <code>安装与更新</code></li>
    </ul>
  </div>
</div>
"""
    body = f"""
<div class="wrap doc">
  <aside class="side"></aside>
  <article class="prose">
    <p class="crumb"><a href="index.html">首页</a> / 搜索</p>
    <h1>搜索</h1>
    {inner}
  </article>
</div>
<script id="search-data" type="application/json">{payload}</script>
"""
    return page("搜索 — " + SITE["name"], body, "search")



# ---------------------------------------------------------------------------
# Recent changes
#
# Visitors cannot tell whether the handbook is current. Read the configuration's
# own commit history and publish the last few changes. Only commits that touch
# lua/ or docs/ count; site-only commits are noise to a reader.
# ---------------------------------------------------------------------------

CHANGELOG_LIMIT = 12


def recent_changes() -> list[dict]:
    import subprocess

    try:
        out = subprocess.run(
            [
                "git", "log", f"-{CHANGELOG_LIMIT * 3}", "--no-merges",
                "--date=short", "--format=%h|%ad|%s",
                "--", "lua/", "docs/", "lazy-lock.json",
            ],
            cwd=ROOT, capture_output=True, text=True, timeout=30, check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return []
    if out.returncode != 0:
        return []

    entries: list[dict] = []
    for line in out.stdout.splitlines():
        parts = line.split("|", 2)
        if len(parts) != 3:
            continue
        entries.append({"hash": parts[0], "date": parts[1], "subject": parts[2]})
        if len(entries) >= CHANGELOG_LIMIT:
            break
    return entries


def build_changes_page() -> int:
    entries = recent_changes()

    if entries:
        rows = "".join(
            f'<li class="chg"><time>{html_escape(e["date"])}</time>'
            f'<span>{html_escape(e["subject"])}</span>'
            f'<code>{html_escape(e["hash"])}</code></li>'
            for e in entries
        )
        body_html = f'<ol class="chg-list">{rows}</ol>'
        lead = "配置和手册的近期改动，来自仓库的提交历史。只列出动过 <code>lua/</code> 或 <code>docs/</code> 的提交。"
    else:
        body_html = "<p>没有可用的提交历史。</p>"
        lead = ""

    inner = f"""
<p class="lede">{lead}</p>
{body_html}
<p class="chg-foot">
  完整历史见
  <a href="https://github.com/{SITE['repo']}/commits/main">GitHub 提交记录</a>。
</p>
"""
    body = f"""
<div class="wrap doc">
  <aside class="side"></aside>
  <article class="prose">
    <p class="crumb"><a href="index.html">首页</a> / 最近改动</p>
    <h1>最近改动</h1>
    {inner}
  </article>
</div>
"""
    (OUT / "changes.html").write_text(
        page("最近改动 — " + SITE["name"], body, "changes"), encoding="utf-8"
    )
    return len(entries)



# ---------------------------------------------------------------------------
# Series sections: tutorials, wiki, reference
#
# Each is an ordered list of markdown files in its own docs/ subdirectory. They
# share one renderer: an index page listing the series, per-page rendering with
# a pager, and a sidebar showing the whole series.
# ---------------------------------------------------------------------------

SERIES = {
    "tutorials": {"dir": DOCS / "tutorials", "label": "教程", "lead":
        "从零开始学 Neovim。前 10 篇覆盖日常编辑需要的全部基础动作，"
        "后 4 篇讲按键背后的语法——那是新手真正卡住的第二层。"},
    "wiki": {"dir": DOCS / "wiki", "label": "百科", "lead":
        "概念与机制。不属于某一个插件，而是理解整个编辑器怎么工作。"},
    "reference": {"dir": DOCS / "reference", "label": "知识", "lead":
        "速查与对照。写东西时随手查，不需要从头读。"},
}


def series_items(kind: str, locale: str = "zh-cn") -> list[tuple[str, str]]:
    """(slug, title) in reading order for a series."""
    ordered = TUTORIALS if kind == "tutorials" else WIKI if kind == "wiki" else None
    if ordered:
        return list(ordered)
    # reference: alphabetical by the docs/reference file list
    result = []
    for path in sorted((SERIES["reference"]["dir"]).glob("*.md")):
        title = first_h1(path.read_text(encoding="utf-8"), path.stem)
        result.append((path.stem.lower(), title))
    return result


def series_sidebar(kind: str, current_slug: str, prefix: str = "") -> str:
    items = series_items(kind)
    rows = []
    for slug, title in items:
        cls = ' class="current"' if slug == current_slug else ""
        rows.append(
            f'<a href="{prefix}{slug}.html" data-side-item '
            f'data-label="{html_escape(title.lower())}"{cls}><span>{html_escape(title)}</span></a>'
        )
    label = SERIES[kind]["label"]
    return (
        f'<p class="side-title">{label}</p>'
        + side_filter(f"筛选{label}…")
        + f'<div class="side-group open">{"".join(rows)}</div>'
    )


def series_pager(kind: str, slug: str) -> str:
    items = series_items(kind)
    idx = next((i for i, (s, _t) in enumerate(items) if s == slug), None)
    if idx is None:
        return ""
    label = SERIES[kind]["label"]

    parts = []
    if idx > 0:
        ps, pt = items[idx - 1]
        parts.append(
            f'<a class="pager-link prev" href="{ps}.html">'
            f'<span class="pager-dir">← 上一篇</span><strong>{html_escape(pt)}</strong></a>'
        )
    else:
        parts.append('<span class="pager-link disabled"></span>')

    if idx < len(items) - 1:
        ns, nt = items[idx + 1]
        parts.append(
            f'<a class="pager-link next" href="{ns}.html">'
            f'<span class="pager-dir">下一篇 →</span><strong>{html_escape(nt)}</strong></a>'
        )
    else:
        parts.append(
            f'<a class="pager-link next" href="../{kind}.html">'
            f'<span class="pager-dir">读完了 →</span><strong>回到{label}索引</strong></a>'
        )

    return (
        f'<nav class="pager" aria-label="翻页">'
        f'<p class="pager-pos">{idx + 1} / {len(items)}</p>'
        f'<div class="pager-row">{"".join(parts)}</div></nav>'
    )


def build_series(kind: str) -> int:
    cfg = SERIES[kind]
    src_dir: Path = cfg["dir"]
    label = cfg["label"]
    count = 0

    for path in sorted(src_dir.glob("*.md")):
        slug = path.stem.lower()
        md_text = path.read_text(encoding="utf-8")
        title = first_h1(md_text, path.stem)
        MD.reset()
        html = MD.convert(md_text)
        toc_html = getattr(MD, "toc", "")
        html = rewrite_source_links(strip_h1(html), kind)
        toc = ""
        if toc_html and md_text.count("\n## ") >= 3:
            toc = f'<nav class="toc"><p class="toc-title">本页内容</p>{toc_html}</nav>'

        body = f"""
<div class="wrap doc">
  <aside class="side">{series_sidebar(kind, slug, "")}</aside>
  <article class="prose">
    <p class="crumb"><a href="../index.html">首页</a> / <a href="../{kind}.html">{label}</a></p>
    <h1>{html_escape(title)}</h1>
    {toc}
    {html}
    {series_pager(kind, slug)}
    <p class="pnav"><a href="../{kind}.html">← {label}索引</a>
    <a href="https://github.com/{SITE['repo']}/blob/main/docs/{kind}/{path.name}">在 GitHub 上编辑</a></p>
  </article>
</div>
"""
        out = OUT / kind / f"{slug}.html"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(page(f"{title} — {SITE['name']}", body, kind), encoding="utf-8")
        count += 1

    # index page
    cards = "".join(
        f'<a class="pcard" href="{kind}/{slug}.html">'
        f'<span class="pcard-k">{i + 1:02d}</span><strong>{html_escape(t)}</strong></a>'
        for i, (slug, t) in enumerate(series_items(kind))
    )
    inner = (
        f'<p class="lede">{cfg["lead"]}</p>'
        f'<div class="pgrid">{cards}</div>'
    )
    body = f"""
<div class="wrap doc">
  <aside class="side">{series_sidebar(kind, "", kind + "/")}</aside>
  <article class="prose">
    <p class="crumb"><a href="index.html">首页</a> / {label}</p>
    <h1>{label}</h1>
    {inner}
  </article>
</div>
"""
    (OUT / f"{kind}.html").write_text(
        page(f"{label} — {SITE['name']}", body, f"{kind}-index"), encoding="utf-8"
    )
    return count


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
    n_tutorials = build_series("tutorials")
    n_wiki = build_series("wiki")
    n_reference = build_series("reference")

    # Top-level prose pages rendered from docs/.
    build_doc_page("getting-started", "getting-started", "安装与更新", DOCS / "INSTALL.md")

    n_changes = build_changes_page()

    search_entries = build_search_index()
    (OUT / "search.html").write_text(build_search_page(search_entries), encoding="utf-8")

    # Static assets.
    (OUT / "assets").mkdir(exist_ok=True)
    for name in ("site.css", "site.js"):
        shutil.copy(ROOT / "site" / name, OUT / "assets" / name)

    print(f"pages: 1 home, 1 keys, 1 plugins, {n_plugins} plugin chapters, {n_guides} guides, {n_tutorials} tutorials, {n_wiki} wiki, {n_reference} reference, {n_changes} changes")
    print(f"keymaps parsed: {len(keymaps)}")

    # Fail loudly rather than publishing a broken site.
    try:
        check_css()
        check_links()
        check_catalogue()
        check_keymap_freshness()
        check_cited_keys()
        check_plugin_coverage()
    except BuildError as exc:
        print(f"build check failed: {exc}", file=sys.stderr)
        return 1
    print("checks: css ok, links ok")
    print(f"output: {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
