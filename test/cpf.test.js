'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { isValidCpf, normalizeCpf } = require('../src/cpf');

test('normalizeCpf strips punctuation and keeps 11 digits', () => {
  assert.equal(normalizeCpf('529.982.247-25'), '52998224725');
  assert.equal(normalizeCpf('52998224725'), '52998224725');
});

test('normalizeCpf rejects wrong length', () => {
  assert.equal(normalizeCpf('123'), null);
  assert.equal(normalizeCpf(''), null);
  assert.equal(normalizeCpf(undefined), null);
});

test('isValidCpf accepts a known-valid CPF', () => {
  assert.equal(isValidCpf('529.982.247-25'), true);
});

test('isValidCpf rejects repeated-digit sequences', () => {
  assert.equal(isValidCpf('111.111.111-11'), false);
  assert.equal(isValidCpf('00000000000'), false);
});

test('isValidCpf rejects a CPF with a wrong check digit', () => {
  assert.equal(isValidCpf('529.982.247-26'), false);
});

test('isValidCpf rejects malformed input', () => {
  assert.equal(isValidCpf('not-a-cpf'), false);
  assert.equal(isValidCpf('123456789'), false);
});
