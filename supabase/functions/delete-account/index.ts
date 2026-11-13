// 注销账号：客户端没有 service role，删 auth 用户只能放在 Edge Function 里做。
//
// 部署：Supabase Dashboard → Edge Functions → 新建 delete-account，粘贴本文件；
// 或用 CLI：supabase functions deploy delete-account
// 不需要额外 secret，SUPABASE_URL / SERVICE_ROLE_KEY 由运行时注入。

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req) => {
  const auth = req.headers.get('Authorization') ?? '';
  if (!auth.startsWith('Bearer ')) {
    return new Response('unauthorized', { status: 401 });
  }

  // 先用调用者自己的 token 确认他是谁
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: auth } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response('unauthorized', { status: 401 });

  // 再用 service role 删号；profiles / favorites / progress 都是 on delete cascade
  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) return new Response(error.message, { status: 500 });

  return new Response('ok', { status: 200 });
});
