import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const escapeHtml = (value: string) => value
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;');

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const authorization = request.headers.get('Authorization');
    const token = authorization?.replace('Bearer ', '');
    const body = await request.json();
    const orderId = Number(body.orderId);

    if (!token || !Number.isInteger(orderId)) {
      return Response.json({ error: 'Invalid request' }, { status: 400 });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const emailJsServiceId = Deno.env.get('EMAILJS_SERVICE_ID');
    const emailJsTemplateId = Deno.env.get('EMAILJS_TEMPLATE_ID');
    const emailJsPublicKey = Deno.env.get('EMAILJS_PUBLIC_KEY');
    const emailJsPrivateKey = Deno.env.get('EMAILJS_PRIVATE_KEY');

    if (!emailJsServiceId || !emailJsTemplateId || !emailJsPublicKey) {
      return Response.json({ error: 'Email service is not configured' }, { status: 500 });
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser(token);
    if (userError || !userData.user?.email) {
      return Response.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { data: order, error: orderError } = await adminClient
      .from('orders')
      .select('id, user_id, total, created_at')
      .eq('id', orderId)
      .eq('user_id', userData.user.id)
      .single();

    if (orderError || !order) {
      return Response.json({ error: 'Order not found' }, { status: 404 });
    }

    const { data: items, error: itemsError } = await adminClient
      .from('order_items')
      .select('product_name, price, quantity')
      .eq('order_id', orderId);

    if (itemsError) {
      return Response.json({ error: 'Could not load order items' }, { status: 500 });
    }

    const itemRows = (items ?? []).map((item) =>
      `<tr><td style="padding:8px 0">${escapeHtml(item.product_name)} x ${item.quantity}</td><td style="padding:8px 0;text-align:right">₹${Number(item.price) * item.quantity}</td></tr>`,
    ).join('');

    const emailResponse = await fetch('https://api.emailjs.com/api/v1.0/email/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        service_id: emailJsServiceId,
        template_id: emailJsTemplateId,
        user_id: emailJsPublicKey,
        ...(emailJsPrivateKey ? { accessToken: emailJsPrivateKey } : {}),
        template_params: {
          to_email: userData.user.email,
          order_id: order.id,
          order_items: itemRows,
          order_total: Number(order.total).toFixed(0),
        },
      }),
    });

    if (!emailResponse.ok) {
      const errorText = await emailResponse.text();
      return Response.json({ error: errorText }, { status: 502 });
    }

    return Response.json({ sent: true, orderId });
  } catch (error) {
    return Response.json({ error: String(error) }, { status: 500 });
  }
});
