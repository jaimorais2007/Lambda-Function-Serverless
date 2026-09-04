'use strict';

const jwt = require('jsonwebtoken');
const pg = require('pg');

const CUSTOMERS_TABLE = process.env.CUSTOMERS_TABLE;
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';

const pool = new pg.Pool({
    host: process.env.RDS_HOSTNAME,
    user: process.env.RDS_USERNAME,
    password: process.env.RDS_PASSWORD,
    database: process.env.RDS_DB_NAME,
    port: process.env.RDS_PORT || 5432,
    ssl: { rejectUnauthorized: false }
});

const ALLOWED_STATUSES = (process.env.ALLOWED_STATUSES || 0)
  .split(',')
  .map((s) => s.trim().toUpperCase())
  .filter(Boolean);

function response(statusCode, body) {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

function onlyDigits(value) {
  return typeof value === 'string' ? value.replace(/\D/g, '') : '';
}

function isValidCPF(rawCpf) {
  const cpf = onlyDigits(rawCpf);

  if (cpf.length !== 11) return false;
  if (/^(\d)\1{10}$/.test(cpf)) return false;

  const calcCheckDigit = (base) => {
    let sum = 0;
    let weight = base.length + 1;
    for (const digit of base) {
      sum += parseInt(digit, 10) * weight;
      weight -= 1;
    }
    const rest = sum % 11;
    return rest < 2 ? 0 : 11 - rest;
  };

  const base9 = cpf.slice(0, 9);
  const digit1 = calcCheckDigit(base9);
  const digit2 = calcCheckDigit(base9 + String(digit1));

  return cpf === base9 + String(digit1) + String(digit2);
}

async function authenticate({ cpf } = {}) {
  const cleanCpf = onlyDigits(cpf);

  if (!isValidCPF(cleanCpf)) {
    return response(400, { message: 'CPF inválido.' });
  }

  const result = await pool.query(
    `SELECT * FROM ${CUSTOMERS_TABLE} WHERE cpf = $1`,
    [cleanCpf]
  );

  const customer = result.rows[0];

  if (!customer) {
    return response(404, { message: 'Cliente não encontrado.' });
  }

  const status = String(customer.status || '').toUpperCase();
  if (!ALLOWED_STATUSES.includes(status)) {
    return response(403, {
      message: `Cliente com status "${customer.status}" não está apto a autenticar.`,
    });
  }

  const token = jwt.sign(
    {
      sub: cleanCpf,
      customerId: customer.customerId || customer.id || cleanCpf,
      status,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );

  return response(200, { token, tokenType: 'Bearer', expiresIn: JWT_EXPIRES_IN });
}

exports.handler = async (event) => {
  try {
    if (!CUSTOMERS_TABLE || !JWT_SECRET) {
      console.error('Variáveis de ambiente CUSTOMERS_TABLE ou JWT_SECRET ausentes.');
      return response(500, { message: 'Erro de configuração do servidor.' });
    }

    let body = {};
    if (event.body) {
      try {
        body = JSON.parse(event.body);
      } catch (e) {
        return response(400, { message: 'JSON inválido no corpo da requisição.' });
      }
    } else if (event.cpf) {
      body = event;
    }

    return await authenticate(body);
  } catch (err) {
    console.error('Erro inesperado:', err);
    return response(500, { message: 'Erro interno do servidor.' });
  }
};
