function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

async function sendOrderConfirmation({ email, order, items }) {
  const serviceId = process.env.EMAILJS_SERVICE_ID;
  const templateId = process.env.EMAILJS_TEMPLATE_ID;
  const publicKey = process.env.EMAILJS_PUBLIC_KEY;
  const privateKey = process.env.EMAILJS_PRIVATE_KEY;

  if (!serviceId || !templateId || !publicKey) {
    console.warn('EmailJS is not configured; skipping order confirmation email.');
    return;
  }

  const itemRows = items.map((item) => (
    `<tr><td style="padding:8px 0">${escapeHtml(item.product_name)} x ${item.quantity}</td>` +
    `<td style="padding:8px 0;text-align:right">₹${(Number(item.price) * item.quantity).toFixed(0)}</td></tr>`
  )).join('');

  const response = await fetch('https://api.emailjs.com/api/v1.0/email/send', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      service_id: serviceId,
      template_id: templateId,
      user_id: publicKey,
      ...(privateKey ? { accessToken: privateKey } : {}),
      template_params: {
        to_email: email,
        order_id: order.id,
        order_items: itemRows,
        order_total: Number(order.total).toFixed(0),
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`EmailJS returned ${response.status}: ${await response.text()}`);
  }
}

module.exports = { sendOrderConfirmation };