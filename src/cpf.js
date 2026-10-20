'use strict';

/**
 * Normalizes a CPF string to 11 raw digits, or null if the input doesn't
 * contain exactly 11 digits once punctuation is stripped.
 */
function normalizeCpf(input) {
  if (typeof input !== 'string') return null;
  const digits = input.replace(/\D/g, '');
  return digits.length === 11 ? digits : null;
}

function calcCheckDigit(digits, weightStart) {
  let sum = 0;
  for (let i = 0; i < digits.length; i++) {
    sum += parseInt(digits[i], 10) * (weightStart - i);
  }
  const remainder = sum % 11;
  return remainder < 2 ? 0 : 11 - remainder;
}

/**
 * Validates a CPF: 11 digits, not a repeated-digit sequence (e.g. "11111111111"),
 * and both check digits match the standard CPF algorithm.
 */
function isValidCpf(input) {
  const cpf = normalizeCpf(input);
  if (!cpf) return false;
  if (/^(\d)\1{10}$/.test(cpf)) return false;

  const firstCheck = calcCheckDigit(cpf.slice(0, 9), 10);
  if (firstCheck !== parseInt(cpf[9], 10)) return false;

  const secondCheck = calcCheckDigit(cpf.slice(0, 10), 11);
  if (secondCheck !== parseInt(cpf[10], 10)) return false;

  return true;
}

module.exports = { normalizeCpf, isValidCpf };
