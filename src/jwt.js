'use strict';

const jwt = require('jsonwebtoken');

const ISSUER = 'tech-challenge-backend';
const EXPIRES_IN_SECONDS = 3600;

/**
 * Issues an HS256 JWT in the same shape the Spring app's own
 * JwtTokenGenerator produces (issuer, iat, exp, subject, role claim) —
 * signed with the same shared secret, so the app's existing
 * NimbusJwtDecoder accepts it without any change on that side.
 */
function issueToken({ subject, role, extraClaims = {} }) {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('JWT_SECRET not configured');

  return jwt.sign(
    { role, ...extraClaims },
    secret,
    {
      algorithm: 'HS256',
      issuer: ISSUER,
      subject,
      expiresIn: EXPIRES_IN_SECONDS,
    }
  );
}

/**
 * Verifies an HS256 JWT signed with the shared secret. Throws if the token
 * is missing, malformed, expired, or signed with a different key.
 */
function verifyToken(token) {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('JWT_SECRET not configured');

  return jwt.verify(token, secret, {
    algorithms: ['HS256'],
    issuer: ISSUER,
  });
}

module.exports = { issueToken, verifyToken, ISSUER, EXPIRES_IN_SECONDS };
