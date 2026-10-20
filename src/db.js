'use strict';

const { Client } = require('pg');

/**
 * Looks up a cliente by CPF/CNPJ and returns its status, or null if not found.
 * Opens a short-lived connection per invocation — Lambda concurrency here is
 * low (auth calls), so a connection pool isn't worth the added complexity.
 */
async function buscarClientePorCpf(cpfCnpj) {
  const client = new Client({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectionTimeoutMillis: 5000,
  });

  await client.connect();
  try {
    const result = await client.query(
      'SELECT id, nome, status FROM clientes WHERE cpf_cnpj = $1 LIMIT 1',
      [cpfCnpj]
    );
    if (result.rows.length === 0) return null;
    const row = result.rows[0];
    return { id: row.id, nome: row.nome, status: row.status };
  } finally {
    await client.end();
  }
}

module.exports = { buscarClientePorCpf };
