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
| `<leader>ri` | `:AwsInvoke` | 调用 Lambda，写 `response.json` 并显示 StatusCode/FunctionError/ExecutedVersion |
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

## 交互式远程调用面板

在 Lambda 列表按 `I`（或在绑定源码里执行 `:AwsLambdaInvoke`）会打开底部水平分屏的调用面板：

- 上方是可编辑的 **JSON 载荷框**（`filetype=json`，带语法高亮），默认载入该函数上次使用的载荷；
- 下方是一行 **按钮栏**：`[ Invoke <C-s> ]`、`[ Upload + Invoke ]`、`[ Copy response ]`、`[ Close q ]`，既支持鼠标点击也支持快捷键；
- 右侧显示实时状态：`ready`、`invoking…`、`ok · 200`、`response copied`。

面板内快捷键：`<C-s>` / `<C-CR>` 调用，`<C-a>` 先上传再调用，`q` / `<Esc>` 关闭。JSON 不合法时只在面板内提示，不会调用 AWS。调用结果（StatusCode、RequestId、响应体和解码后的 CloudWatch 日志）显示在 `aws://lambda/invoke-result/<函数名>` 浮动窗口，`Copy response` 会把原始响应写入无名寄存器。

对下载后的源码作出修改后，可以在该函数绑定目录内执行：

```vim
:AwsLambdaUpload
:AwsLambdaInvoke
:AwsLambdaUploadInvoke
:AwsLambdaLogs
:AwsLambdaLogsStop
```

上传会更新 AWS 上的 Lambda 部署包；调用会实际执行函数；日志命令会持续读取 CloudWatch。执行前检查当前文件属于正确的 `lambda/<函数名>/` 目录，并确认账号、profile、region 与函数名称。自动保存部署默认关闭；启用 `lambda.auto_deploy` 后，仅绑定目录下的文件会触发部署。

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
