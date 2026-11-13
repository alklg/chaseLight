# 账号相关的外部配置

代码里已经写好了，但有几处只能在 Supabase 后台点一下,不然功能跑不通。

## 1. 头像 / 背景图（Storage）

跑 `supabase_schema.sql` 第 6 段。它会：

- 确保 `avatars` / `backgrounds` 两个桶存在且公开读；
- 建策略：登录用户只能写自己 `{uid}/` 目录下的对象。

跑完可以自测：登录后换头像 → 退出重登 → 图还在。

## 1.5 profile 缺列

如果 `profiles` 没有 `cover` 列，封面图那份更新会整条失败：

```sql
alter table public.profiles add column if not exists cover text;
```

## 2. 找回密码（深链）

客户端已经注册了 scheme：`com.chase.light://auth/reset`
（Android 在 `AndroidManifest.xml` 的 intent-filter，iOS 在 `Info.plist` 的 CFBundleURLTypes。）

Supabase 后台还要加一条白名单：

Authentication → URL Configuration → **Redirect URLs** 添加：

```
com.chase.light://auth/reset
```

不加的话，邮件里的链接会被 Supabase 丢掉，点开只会回到站点首页。

流程：登录页「忘记密码？」→ 填邮箱 → 收到邮件 → 点开 → App 打开「重置密码」页 → 输两遍新密码。

## 3. 注销账号（Edge Function）

删 auth 用户需要 service role，客户端拿不到，所以走 Edge Function：

1. Dashboard → Edge Functions → 新建，名字必须是 `delete-account`；
2. 把 `supabase/functions/delete-account/index.ts` 的内容整段粘进去，Deploy；
3. 不需要配 secret（`SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` 运行时自带）。

没部署前，账号页点「注销账号」会提示「注销失败」，不会误删任何东西。

## 4. 删除效果

`profiles` / `favorites` / `progress` 三张表都是 `references auth.users on delete cascade`，
删 auth 用户会连数据一起清掉。存储里的头像文件不会自动删（Supabase 不级联 Storage），
属于可接受残留；要清可以再加一条定时任务。
