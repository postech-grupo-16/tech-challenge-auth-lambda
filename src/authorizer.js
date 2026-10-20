'use strict';

const { verifyToken } = require('./jwt');

/**
 * HTTP API Lambda authorizer (payload format 2.0 / "simple responses").
 * Validates the Bearer JWT with the same shared secret the Spring app
 * uses, before the Gateway proxies the request to the application.
 * This is defense at the edge — the Spring app's own OAuth2 Resource
 * Server still re-validates the token independently.
 */
exports.handler = async (event) => {
  const authHeader =
    event.headers?.authorization || event.headers?.Authorization || '';
  const match = /^Bearer\s+(.+)$/i.exec(authHeader);

  if (!match) {
    return { isAuthorized: false };
  }

  try {
    const claims = verifyToken(match[1]);
    return {
      isAuthorized: true,
      context: {
        subject: claims.sub,
        role: claims.role,
      },
    };
  } catch (err) {
    console.warn('Token rejeitado pelo authorizer:', err.message);
    return { isAuthorized: false };
  }
};
