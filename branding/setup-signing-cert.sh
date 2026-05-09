#!/usr/bin/env bash
# One-time setup: create a self-signed code-signing cert for DreamScribe local builds
# and import it into the user's login keychain, with codesign granted
# non-interactive access to the private key.
#
# After running this once, every `make local` produces a build signed with the
# SAME cryptographic identity. macOS TCC keys permissions on (bundle ID +
# designated requirement), so the binary hash changing per build no longer
# triggers fresh permission prompts — the identity stays stable.
#
# Idempotent: re-running detects the existing cert and exits cleanly.
#
# Usage: bash branding/setup-signing-cert.sh

set -euo pipefail

CERT_NAME="DreamScribe Self-Signed"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Setting up signing cert: $CERT_NAME"

# Detect existing cert
if security find-certificate -c "$CERT_NAME" "$KEYCHAIN" >/dev/null 2>&1; then
  echo "    Cert already in keychain. Verifying it has a usable private key..."
  if security find-identity -v -p codesigning "$KEYCHAIN" | grep -q "$CERT_NAME"; then
    echo "==> All good. No-op."
    exit 0
  else
    echo "    Cert is present but has no associated private key — that's not usable."
    echo "    Delete it from Keychain Access (search for '$CERT_NAME') and re-run this script."
    exit 1
  fi
fi

# OpenSSL config — RSA 4096, 10-year validity, code-signing EKU
cat > "$TMP_DIR/cert.cnf" <<EOF
[req]
distinguished_name = req_dn
req_extensions     = v3_req
prompt             = no

[req_dn]
CN = $CERT_NAME
O  = Dreamers Media
OU = Internal Tools

[v3_req]
keyUsage         = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
basicConstraints = critical, CA:false
EOF

echo "==> Generating private key + self-signed cert (10y validity, codeSigning EKU)..."
openssl req -x509 -newkey rsa:4096 -days 3650 -nodes \
  -keyout "$TMP_DIR/dreamscribe.key" \
  -out    "$TMP_DIR/dreamscribe.crt" \
  -config "$TMP_DIR/cert.cnf" \
  -extensions v3_req \
  >/dev/null 2>&1

# Use a fixed transit passphrase. macOS's `security import` can fail with empty-
# passphrase pkcs12 ("MAC verification failed"). The passphrase is just a transit
# cipher — the keychain itself enforces actual access control once the cert is in.
TRANSIT_PASS="dreamscribe"

echo "==> Bundling into PKCS#12 (legacy mode for macOS Security.framework compat)..."
# OpenSSL 3.x defaults to AES-256/SHA-256 PKCS#12 which macOS's `security import`
# cannot read ("MAC verification failed"). The -legacy flag falls back to
# RC2-40/SHA-1 which macOS handles. Security is fine — the pkcs12 is transient.
openssl pkcs12 -export -legacy \
  -in        "$TMP_DIR/dreamscribe.crt" \
  -inkey     "$TMP_DIR/dreamscribe.key" \
  -name      "$CERT_NAME" \
  -passout   pass:"$TRANSIT_PASS" \
  -out       "$TMP_DIR/dreamscribe.p12" \
  >/dev/null 2>&1

echo "==> Importing into login keychain (codesign + security granted access)..."
security import "$TMP_DIR/dreamscribe.p12" \
  -P "$TRANSIT_PASS"                  \
  -k "$KEYCHAIN"                      \
  -T /usr/bin/codesign                \
  -T /usr/bin/security                \
  >/dev/null

# Note: we deliberately skip `add-trusted-cert` (would need admin password) and
# `set-key-partition-list` (would need keychain password). The cert doesn't need
# to be system-trusted for codesign to use it — codesign just needs to find a
# cert with matching CN that has an associated private key, both of which the
# `security import -T /usr/bin/codesign` step above grants.

echo
echo "==> Done. Verify with:"
echo "    security find-certificate -c \"$CERT_NAME\" >/dev/null && echo OK"
echo
echo "Next step: re-run 'make local' to produce a build signed with this identity."
echo "The first build after switching identities will still trigger fresh TCC"
echo "permission prompts (because the designated requirement changed). Every"
echo "build AFTER that inherits the same trust — no more re-grant dance."
