# AWS 插件：在 Neovim 中使用 AWS 服务

<!-- source: lua/plugins/aws.lua -->

`aws.nvim` 用 AWS CLI 读取和查看云端资源，并支持 Lambda 源码下载、部署、调用及日志查看。所有 AWS 命令异步运行，不会阻塞编辑器。

## 准备 AWS CLI 身份

插件使用系统上的 `aws` 命令，不保存凭据。先在终端验证当前身份：

```sh
aws sts get-caller-identity
```

使用 AWS SSO、环境变量、profile 或实例角色时，按 AWS CLI 的常规方式登录和配置。确认返回账号与预期一致后再在 Neovim 中运行 AWS 操作。

需要 AWS CLI v2。Lambda 源码下载还需要 `curl`、`unzip`、`zipinfo` 和 `zip`。

## 打开服务

按 `<leader>aa` 打开可搜索的服务选择器。也可以按 `<leader>a` 后接服务助记键直接打开列表；Which-key 会显示快捷键：

| 按键 | 服务 | 列表内容 |
|---|---|---|
| `<leader>ac` | CloudFormation | Stacks、资源及事件 |
| `<leader>aw` | CloudWatch | Log groups、streams 和 events |
| `<leader>as` | S3 | Buckets；可打开 bucket 浏览其对象 |
| `<leader>al` | Lambda | Functions、详情、源码和日志 |
| `<leader>ak` | KMS | Keys、aliases 与详情 |
| `<leader>aK` | ACM | Certificates 与详情 |
| `<leader>am` | Secrets Manager | Secrets 与详情 |
| `<leader>af` | CloudFront | Distributions 与详情 |
| `<leader>ag` | API Gateway | REST APIs、stages、resources 和 authorizers |
| `<leader>ae` | ECS / Fargate | Clusters、services、tasks 和 events |
| `<leader>ai` | IAM | Users、groups、roles、policies 和 providers |
| `<leader>av` | VPC | VPCs、subnets、gateways、routes 和 security groups |
| `<leader>ad` | DynamoDB | Tables、scan 和 query |
| `<leader>ax` | EC2 | Instances 与详情 |

例如，按 `<leader>al` 可直接打开 Lambda 函数列表。`<leader>aa` 始终保留为完整服务选择器。

`<leader>r*` 是针对“当前正在编辑的资源”的一组动作，资源类型、函数名、profile、region 和 log group 全部从 `.aws-resource.json` 自动推断：

| 按键 | 命令 | 动作 |
|---|---|---|
| `<leader>rd` | `:AwsDownload` | 下载资源源码并写 `.aws-resource.json` |
| `<leader>ru` / `<leader>au` | `:AwsUpload` | 保存全部缓冲区后打包上传 |
| `<leader>ri` | `:AwsInvoke` | 用 `invoke.json` 调用 Lambda，写 `response.json` 并显示 StatusCode/FunctionError/ExecutedVersion |
| `<leader>rl` | `:AwsLogs` | 按 metadata 的 log_group 跟踪日志 |
| `<leader>rr` | `:AwsRefresh` | 重新读取函数配置并写回 metadata |
| `<leader>rm` | `:AwsMetadata` | 显示当前资源的 metadata |

## 浏览列表和详情

列表显示 AWS CLI 返回的数据，并可在列表内搜索、筛选和刷新。按 `<CR>` 打开当前资源的详情或子列表；CloudFormation 可进入资源和事件，CloudWatch 可继续进入 streams 和 events，Lambda 可打开函数详情和日志。

各服务的列表使用 buffer-local 按键。打开列表后可查看屏幕上的按键提示，也可用 `:help aws-nvim` 查完整命令和默认按键。Secrets Manager 的详情支持按 `gS` 显示或隐藏 secret value；查看敏感值前先确认终端和屏幕处于私密环境。

## 选择 AWS profile 和 region

每个 `:Aws*` 命令都接受 `--profile` 与 `--region`，这两个参数只覆盖当前操作：

```vim
:AwsLambda --profile staging --region ap-northeast-1
:AwsCF list --profile production --region us-east-1
:AwsPicker --profile staging --region ap-northeast-1
```

也可在 `require("aws").setup()` 中设置默认 profile 和 region。命令错误会显示 AWS CLI 返回的诊断信息；先检查身份、权限、profile 和 region。

## Lambda 源码工作流

在 Lambda 列表选中函数后：

- `D` 只把源码下载到当前 Neovim 工作目录的 `lambda/<函数名>/`，不会打开任何缓冲区；
- `E` 打开该函数的本地源码用于编辑；本地还没有副本时会先下载再打开，所以不会出现“no local source binding”的死路。

下载使用 `aws lambda get-function` 提供的代码 URL，显示进度，将内容写入暂存目录后再提取。插件会拒绝不安全的归档路径和符号链接，成功后才替换本地函数目录。`.aws-meta.json` 保存函数名、region 和 account 信息。`E` 优先打开 `app.py`、`index.js`、`handler.py` 或 `main.py` 中第一个存在的入口文件。

## Payload 驱动的调用流程

每个下载到本地的 Lambda 目录里会同时维护三个文件：

```text
lambda/<函数名>/
├── app.py              # 源码
├── invoke.json         # 请求体，下载时自动创建（内容 {}）
├── response.json       # 最近一次调用结果
└── .aws-resource.json  # metadata
```

`invoke.json` 是唯一的 payload 来源：不会再临时拼 JSON，也不会发送空 payload。

| 按键 | 动作 |
|---|---|
| `e` | 编辑 payload：打开 `invoke.json`，不存在时先创建 `{}` |
| `i` | 用当前 payload 调用：`aws lambda invoke --payload fileb://invoke.json ...`，结果写入 `response.json` |
| `v` | 查看 `response.json` |
| `r` | 先上传源码，再用 `invoke.json` 调用 |

没有 `invoke.json` 时按 `i` 不会发送请求，而是创建 `{}`、打开文件并提示 `invoke.json created. Please edit payload before invoking.`；JSON 不合法只在本地报错，不会调用 AWS。结果浮窗显示 StatusCode、FunctionError、ExecutedVersion、payload 路径和解码后的日志。

`:AwsInvoke` 使用同一个 `invoke.json`，所以快捷键和命令行为一致。交互面板（`I`）也改为读写 `invoke.json`。

payload 路径通过 `get_current_payload_file(dir)` 解析，后续要支持 `payloads/default.json`、`payloads/test1.json` 等多 payload 时不需要改调用逻辑。

## AWS Profile 与状态栏

插件读取 `~/.aws/config`（或 `$AWS_CONFIG_FILE`），只把 `[default]` 和 `[profile <名称>]` 当作 profile；`[sso-session ...]`、`[services ...]` 等段落会忽略，重复段落以最后一次为准，缺少 `region` 也允许。

```ini
[profile dev]
role_arn = arn:aws:iam::123456789012:role/PowerUser
source_profile = default
region = ap-northeast-1
```

当前 profile 的优先级：`$AWS_PROFILE` → 本次会话里选中的 profile → `default`。

| 命令 | 作用 |
|---|---|
| `:AwsProfile` | 用 `vim.ui.select` 选择（兼容 dressing / snacks / telescope） |
| `:AwsProfile dev` | 直接切到 dev |
| `:AwsProfile reload` | 重新读取 `~/.aws/config` |

选中后会写入 `vim.env.AWS_PROFILE`，所有 AWS CLI 调用（资源动作、Lambda 工作流）立即生效，并触发 `User AwsProfileChanged` 自动刷新状态栏。

状态栏左侧右侧的 `󰸏 dev@ap-northeast-1` 由 Heirline 组件提供，点击后弹出和其它状态栏菜单一致的浮窗，列出所有 profile、当前项带勾选、末尾提供重新加载和 `vim.ui.select` 入口。

API：

```lua
local profile = require("aws.profile")
profile.current()      -- "dev"
profile.set("prod")    -- 写入 $AWS_PROFILE
profile.profiles()     -- { "default", "dev", "stg", "prod" }
profile.region("dev")  -- "ap-northeast-1" 或 nil
profile.summary()      -- "dev@ap-northeast-1"
profile.reload()       -- 重读配置文件
```

## 资源动作（当前 Buffer 即当前资源）

所有动作都先做资源发现：从当前文件目录向上找 `.aws-resource.json`，其次旧版 `.aws-meta.json`，再按目录结构（`lambda/`、`stepfunctions/`、`glue/`）推断，最后才用 AWS Explorer 里光标选中的 Lambda。找不到时直接报 `❌ AWS resource metadata not found` 并终止，不会猜。

metadata 示例：

```json
{
  "type": "lambda",
  "account": "123456789012",
  "region": "ap-northeast-1",
  "profile": "sbi-dwh-dev",
  "function_name": "dwh-dev",
  "log_group": "/aws/lambda/dwh-dev"
}
```

- **下载**：把代码下载到 `lambda/<函数名>/`，并生成 `.aws-resource.json`（同时保留旧 `.aws-meta.json`）。
- **上传**：先 `:wall`；在资源目录生成 `function.zip`，忽略 `.git`、`.github`、`__pycache__`、`.pytest_cache`、`.venv`、`node_modules`、`*.pyc`、`function.zip` 和 `.aws-resource.json`；显示 Function/Profile/Region/Account 后执行 `aws lambda update-function-code`；成功显示 `✅ Upload Success`，失败显示 `❌ Upload Failed` 并原样输出 AWS CLI 报错。
- **调用**：执行 `aws lambda invoke --function-name <名称> response.json --cli-binary-format raw-in-base64-out`，打开 `response.json`，并显示 StatusCode、FunctionError、ExecutedVersion。
- **日志**：用 metadata 的 `log_group` 执行 `aws logs tail <group> --follow`；缺失时 Lambda 回退到 `/aws/lambda/<函数名>`。
- **刷新**：重新读取 Runtime/Architecture/Memory/Timeout/Handler/CodeSha256/CodeSize/LastModified/环境变量名，并写回 `.aws-resource.json`。
- **Metadata**：浮动窗口显示当前资源使用的 metadata 文件，便于排查 profile/region 选错。

`stepfunctions/`、`glue/` 目录可以识别，但对应动作尚未实现，插件会明确提示且不调用 AWS。

## 本地 mock 测试

仓库里的 `docs/mock-data/` 提供完全离线的测试环境：mock 的 `aws`/`curl`/`unzip`/`zip`/`zipinfo`、脱敏的 `~/.aws/config`，以及生成临时工作区的脚本。

```sh
sh docs/mock-data/setup-demo.sh
export PATH="$PWD/docs/mock-data/bin:$PATH"
export AWS_CONFIG_FILE="$PWD/docs/mock-data/aws-config"
export AWS_PROFILE=dev
```

之后 `:AwsProfile`、`:AwsLambda`、`D`/`E`、`e`/`i`/`v`、`r`、`:AwsKMS` 都能在没有真实 AWS 账号的情况下跑通。每次调用都会以 `<profile> <args>` 写入 `$AWS_FAKE_LOG`，可以直接确认传入的 profile 是否正确；`AWS_FAKE_FAIL=1` 用来模拟 `AccessDeniedException`。

## 远程删除保护

插件不提供删除云端资源或清空 S3 bucket 的快捷键、命令或公开 API。AWS CLI 执行层也会拒绝删除类操作，避免旧映射或直接调用触发资源删除。

Lambda 上传和 CloudFront cache invalidation 会修改云端状态，但不删除资源；仍应先核实操作目标和身份。

## 练习

1. 运行 `aws sts get-caller-identity`，确认当前账号。
2. 按 `<leader>aa` 选择 CloudWatch，再进入一个 log group 查看 streams。
3. 按 `<leader>al` 打开 Lambda，选择可安全测试的函数并按 `D` 下载。
4. 检查 cwd 下 `lambda/<函数名>/` 的文件和 `.aws-meta.json`。
5. 在测试账号确认 profile、region 和函数目录后，再尝试上传或调用。

## 参考

- [aws.nvim README：安装、配置、命令与服务说明](https://github.com/iamcheyan/aws.nvim/blob/main/README.md)
- [插件源码](https://github.com/iamcheyan/aws.nvim)
- Neovim 内运行 `:help aws-nvim`
