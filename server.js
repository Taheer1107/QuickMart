require('dotenv').config();

const bcrypt = require('bcryptjs');
const cors = require('cors');
const { randomUUID } = require('crypto');
const express = require('express');
const jwt = require('jsonwebtoken');
const path = require('path');
const { Pool } = require('pg');
const { sendOrderConfirmation } = require('./server/email');

const app = express();
const port = process.env.PORT || 8080;
const jwtSecret = process.env.JWT_SECRET;

if (!process.env.DATABASE_URL) {
  console.warn('DATABASE_URL is not configured; database API requests will fail.');
}
if (!jwtSecret) {
  console.warn('JWT_SECRET is not configured; authentication endpoints are disabled.');
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

app.use(cors({ origin: process.env.CORS_ORIGIN || true }));
app.use(express.json({ limit: '1mb' }));

function createToken(user) {
  return jwt.sign({ email: user.email, isAdmin: user.is_admin }, jwtSecret, {
    subject: user.id,
    expiresIn: '7d',
  });
}

function requireAuth(req, res, next) {
  if (!jwtSecret) return res.status(503).json({ error: 'Authentication is not configured' });
  const header = req.get('authorization');
  const token = header && header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Bearer token required' });

  try {
    req.user = jwt.verify(token, jwtSecret);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function requireAdmin(req, res, next) {
  if (!req.user.isAdmin) return res.status(403).json({ error: 'Admin access required' });
  next();
}

function handleError(res, error) {
  console.error(error);
  if (error.code === '23505') return res.status(409).json({ error: 'Resource already exists' });
  return res.status(500).json({ error: 'Internal server error' });
}

app.get('/api/health', async (req, res) => {
  try {
    await pool.query('select 1');
    res.json({ status: 'ok', database: 'connected' });
  } catch (error) {
    console.error(error);
    res.status(503).json({ status: 'error', database: 'unavailable' });
  }
});

app.post('/api/auth/register', async (req, res) => {
  if (!jwtSecret) return res.status(503).json({ error: 'Authentication is not configured' });
  const email = typeof req.body.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const password = typeof req.body.password === 'string' ? req.body.password : '';
  if (!email || password.length < 8) {
    return res.status(400).json({ error: 'A valid email and password of at least 8 characters are required' });
  }

  try {
    const passwordHash = await bcrypt.hash(password, 12);
    const result = await pool.query(
      'insert into users (id, email, password_hash) values ($1, $2, $3) returning id, email, is_admin',
      [randomUUID(), email, passwordHash],
    );
    const user = result.rows[0];
    res.status(201).json({ user, token: createToken(user) });
  } catch (error) {
    handleError(res, error);
  }
});

app.post('/api/auth/login', async (req, res) => {
  if (!jwtSecret) return res.status(503).json({ error: 'Authentication is not configured' });
  const email = typeof req.body.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const password = typeof req.body.password === 'string' ? req.body.password : '';
  try {
    const result = await pool.query(
      'select id, email, password_hash, is_admin from users where email = $1',
      [email],
    );
    const user = result.rows[0];
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    delete user.password_hash;
    res.json({ user, token: createToken(user) });
  } catch (error) {
    handleError(res, error);
  }
});

app.get('/api/auth/me', requireAuth, async (req, res) => {
  try {
    const result = await pool.query('select id, email, is_admin from users where id = $1', [req.user.sub]);
    if (!result.rows[0]) return res.status(404).json({ error: 'User not found' });
    res.json(result.rows[0]);
  } catch (error) {
    handleError(res, error);
  }
});

app.get('/api/products', async (req, res) => {
  try {
    const result = await pool.query(
      'select id, name, price, image_url, created_at from products order by id',
    );
    res.json(result.rows);
  } catch (error) {
    handleError(res, error);
  }
});

app.post('/api/products', requireAuth, requireAdmin, async (req, res) => {
  const { name, price, imageUrl } = req.body;
  if (!name || !Number.isFinite(Number(price)) || !imageUrl) {
    return res.status(400).json({ error: 'name, price, and imageUrl are required' });
  }
  try {
    const result = await pool.query(
      'insert into products (name, price, image_url) values ($1, $2, $3) returning *',
      [name.trim(), Number(price), imageUrl.trim()],
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    handleError(res, error);
  }
});

app.delete('/api/products/:id', requireAuth, requireAdmin, async (req, res) => {
  try {
    const result = await pool.query('delete from products where id = $1 returning id', [req.params.id]);
    if (!result.rows[0]) return res.status(404).json({ error: 'Product not found' });
    res.status(204).end();
  } catch (error) {
    handleError(res, error);
  }
});

app.get('/api/cart', requireAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `select c.id, c.quantity,
              json_build_object('id', p.id, 'name', p.name, 'price', p.price, 'image_url', p.image_url) as product
         from cart_items c join products p on p.id = c.product_id
        where c.user_id = $1 order by c.id`,
      [req.user.sub],
    );
    res.json(result.rows);
  } catch (error) {
    handleError(res, error);
  }
});

app.post('/api/cart', requireAuth, async (req, res) => {
  const productId = Number(req.body.productId);
  if (!Number.isInteger(productId)) return res.status(400).json({ error: 'productId is required' });
  try {
    const result = await pool.query(
      `insert into cart_items (user_id, product_id, quantity) values ($1, $2, 1)
       on conflict (user_id, product_id) do update set quantity = cart_items.quantity + 1
       returning id, product_id, quantity`,
      [req.user.sub, productId],
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    handleError(res, error);
  }
});

app.patch('/api/cart/:id', requireAuth, async (req, res) => {
  const quantity = Number(req.body.quantity);
  if (!Number.isInteger(quantity)) return res.status(400).json({ error: 'quantity is required' });
  try {
    if (quantity <= 0) {
      await pool.query('delete from cart_items where id = $1 and user_id = $2', [req.params.id, req.user.sub]);
      return res.status(204).end();
    }
    const result = await pool.query(
      'update cart_items set quantity = $1 where id = $2 and user_id = $3 returning id, quantity',
      [quantity, req.params.id, req.user.sub],
    );
    if (!result.rows[0]) return res.status(404).json({ error: 'Cart item not found' });
    res.json(result.rows[0]);
  } catch (error) {
    handleError(res, error);
  }
});

app.delete('/api/cart/:id', requireAuth, async (req, res) => {
  try {
    await pool.query('delete from cart_items where id = $1 and user_id = $2', [req.params.id, req.user.sub]);
    res.status(204).end();
  } catch (error) {
    handleError(res, error);
  }
});

app.delete('/api/cart', requireAuth, async (req, res) => {
  try {
    await pool.query('delete from cart_items where user_id = $1', [req.user.sub]);
    res.status(204).end();
  } catch (error) {
    handleError(res, error);
  }
});

app.post('/api/orders', requireAuth, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('begin');
    const cart = await client.query(
      `select c.product_id, c.quantity, p.name, p.price
         from cart_items c join products p on p.id = c.product_id
        where c.user_id = $1 for update`,
      [req.user.sub],
    );
    if (cart.rows.length === 0) {
      await client.query('rollback');
      return res.status(400).json({ error: 'Cart is empty' });
    }
    const total = cart.rows.reduce((sum, item) => sum + Number(item.price) * item.quantity, 0);
    const order = await client.query(
      'insert into orders (user_id, total) values ($1, $2) returning id, total, created_at',
      [req.user.sub, total],
    );
    for (const item of cart.rows) {
      await client.query(
        'insert into order_items (order_id, product_name, price, quantity) values ($1, $2, $3, $4)',
        [order.rows[0].id, item.name, item.price, item.quantity],
      );
    }
    await client.query('delete from cart_items where user_id = $1', [req.user.sub]);
    await client.query('commit');
    try {
      await sendOrderConfirmation({
        email: req.user.email,
        order: order.rows[0],
        items: cart.rows.map((item) => ({
          product_name: item.name,
          price: item.price,
          quantity: item.quantity,
        })),
      });
    } catch (emailError) {
      console.error('Order confirmation email failed:', emailError);
    }
    res.status(201).json({ order: order.rows[0], items: cart.rows });
  } catch (error) {
    await client.query('rollback');
    handleError(res, error);
  } finally {
    client.release();
  }
});

app.get('/api/orders/:id', requireAuth, async (req, res) => {
  try {
    const order = await pool.query(
      'select id, user_id, total, created_at from orders where id = $1 and user_id = $2',
      [req.params.id, req.user.sub],
    );
    if (!order.rows[0]) return res.status(404).json({ error: 'Order not found' });
    const items = await pool.query(
      'select id, order_id, product_name, price, quantity from order_items where order_id = $1 order by id',
      [req.params.id],
    );
    res.json({ order: order.rows[0], items: items.rows });
  } catch (error) {
    handleError(res, error);
  }
});

const webRoot = path.join(__dirname, 'build', 'web');

app.use(express.static(webRoot, { index: false }));

app.get('*', (req, res) => {
  res.sendFile(path.join(webRoot, 'index.html'));
});

app.listen(port, () => {
  console.log(`QuickMart Flutter app is running on port ${port}`);
});
