'use strict';

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_ISSUER = process.env.JWT_ISSUER;
const JWT_AUDIENCE = process.env.JWT_AUDIENCE;

function denied() {
  return { isAuthorized: false };
}

function extractBearerToken(headers) {
  const authHeader = (headers && (headers.authorization || headers.Authorization)) || '';
  const [scheme, token] = authHeader.split(' ');

  if (!token || !/^Bearer$/i.test(scheme)) {
    return null;
  }

  return token;
}

exports.handler = async (event) => {
  if (!JWT_SECRET) {
    console.error('Variável de ambiente JWT_SECRET ausente.');
    return denied();
  }

  const token = extractBearerToken(event.headers);
  if (!token) {
    return denied();
  }

  try {
    const claims = jwt.verify(token, JWT_SECRET, {
      ...(JWT_ISSUER ? { issuer: JWT_ISSUER } : {}),
      ...(JWT_AUDIENCE ? { audience: JWT_AUDIENCE } : {}),
    });

    return {
      isAuthorized: true,
      context: {
        sub: claims.sub,
        customerId: claims.customerId,
        role: claims.role,
      },
    };
  } catch (err) {
    console.error('Token inválido ou expirado:', err.message);
    return denied();
  }
};
