'use strict';

const { isValidCpf, normalizeCpf } = require('./cpf');
const { buscarClientePorCpf } = require('./db');
const { issueToken } = require('./jwt');

function response(statusCode, body) {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

/**
 * POST /auth/cpf — validates the CPF, checks the cliente exists and is
 * ATIVO in the database, and issues a JWT valid for the protected APIs.
 * This is the public route on the API Gateway (no authorizer attached).
 */
exports.handler = async (event) => {
  let payload;
  try {
    payload = JSON.parse(event.body || '{}');
  } catch {
    return response(400, { message: 'Corpo da requisição inválido (JSON esperado)' });
  }

  const cpf = normalizeCpf(payload.cpf);
  if (!cpf || !isValidCpf(cpf)) {
    return response(400, { message: 'CPF inválido' });
  }

  let cliente;
  try {
    cliente = await buscarClientePorCpf(cpf);
  } catch (err) {
    console.error('Erro ao consultar cliente', err);
    return response(500, { message: 'Erro interno ao validar CPF' });
  }

  if (!cliente) {
    return response(404, { message: 'Cliente não encontrado' });
  }

  if (cliente.status !== 'ATIVO') {
    return response(403, { message: 'Cliente inativo' });
  }

  const accessToken = issueToken({
    subject: cpf,
    role: 'CLIENTE',
    extraClaims: { clienteId: cliente.id },
  });

  return response(200, { accessToken });
};
