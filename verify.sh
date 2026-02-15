#!/bin/bash

echo "=============================================="
echo " NetworkNuts Lab Interview Validation Script"
echo " Role: DevOps / Linux / SRE"
echo "=============================================="
echo

PASS=true

fail() {
  echo "✘ $1"
  PASS=false
}

pass() {
  echo "✔ $1"
}

# --------------------------------------------------
# 1. OS CHECK (RHEL 9 or 10)
# --------------------------------------------------
echo "[1] Checking OS version..."
if grep -E "Red Hat Enterprise Linux (9|10)" /etc/os-release >/dev/null 2>&1; then
  pass "RHEL 9/10 detected"
else
  fail "OS is NOT RHEL 9 or 10"
fi
echo

# --------------------------------------------------
# 2. Apache Installation & Status
# --------------------------------------------------
echo "[2] Checking Apache (httpd)..."

if rpm -q httpd >/dev/null 2>&1; then
  pass "httpd package installed"
else
  fail "httpd package NOT installed"
fi

if systemctl is-active httpd >/dev/null 2>&1; then
  pass "httpd service is running"
else
  fail "httpd service is NOT running"
fi

if systemctl is-enabled httpd >/dev/null 2>&1; then
  pass "httpd service enabled on boot"
else
  fail "httpd service NOT enabled on boot"
fi
echo

# --------------------------------------------------
# 3. Website Content Validation (EXACT 3 HTML FILES)
# --------------------------------------------------
echo "[3] Validating website deployment..."

if [ -d /var/www/html ]; then
  pass "/var/www/html directory exists"
else
  fail "/var/www/html directory missing"
fi

HTML_COUNT=$(find /var/www/html -maxdepth 1 -type f -name "*.html" | wc -l)

if [ "$HTML_COUNT" -eq 3 ]; then
  pass "Exactly 3 HTML files found in /var/www/html"
else
  fail "Expected exactly 3 HTML files, found $HTML_COUNT"
fi
echo

# --------------------------------------------------
# 4. Hostname Validation
# --------------------------------------------------
echo "[4] Checking hostname..."

CURRENT_HOSTNAME=$(hostnamectl --static)
if [ "$CURRENT_HOSTNAME" == "domain1.networknuts.com" ]; then
  pass "Hostname correctly set"
else
  fail "Hostname incorrect (found: $CURRENT_HOSTNAME)"
fi
echo

# --------------------------------------------------
# 5. SSH Password Authentication
# --------------------------------------------------
echo "[5] Checking SSH password authentication..."

SSHD_CONF="/etc/ssh/sshd_config"

if grep -Ei "^PasswordAuthentication\s+yes" "$SSHD_CONF" >/dev/null 2>&1; then
  pass "PasswordAuthentication enabled"
else
  fail "PasswordAuthentication NOT enabled"
fi

if systemctl is-active sshd >/dev/null 2>&1; then
  pass "sshd service running"
else
  fail "sshd service NOT running"
fi
echo

# --------------------------------------------------
# 6. User Validation
# --------------------------------------------------
echo "[6] Validating user site.engineer..."

if id site.engineer >/dev/null 2>&1; then
  pass "User site.engineer exists"
else
  fail "User site.engineer does NOT exist"
fi

if getent shadow site.engineer >/dev/null 2>&1; then
  pass "Password set for site.engineer"
else
  fail "Password NOT set for site.engineer"
fi
echo

# --------------------------------------------------
# 7. Podman Validation
# --------------------------------------------------
echo "[7] Checking Podman..."

if command -v podman >/dev/null 2>&1; then
  pass "Podman installed"
else
  fail "Podman NOT installed"
fi

if podman info >/dev/null 2>&1; then
  pass "Podman functional"
else
  fail "Podman not functioning correctly"
fi
echo

# --------------------------------------------------
# 8. Nginx Container Validation
# --------------------------------------------------
echo "[8] Validating Nginx container..."

if podman ps | grep -q nginx; then
  pass "Nginx container is running"
else
  fail "Nginx container NOT running"
fi

if ss -lntp | grep -q ":8080"; then
  pass "Port 8080 is listening"
else
  fail "Port 8080 is NOT listening"
fi

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)

if [ "$HTTP_STATUS" == "200" ]; then
  pass "Nginx reachable on http://localhost:8080"
else
  fail "Nginx NOT reachable on port 8080 (HTTP $HTTP_STATUS)"
fi
echo

# --------------------------------------------------
# FINAL RESULT
# --------------------------------------------------
echo "=============================================="
if [ "$PASS" = true ]; then
  echo "✔✔✔ ALL CHECKS PASSED ✔✔✔"
  echo "Candidate has SUCCESSFULLY completed the task."
  exit 0
else
  echo "✘✘✘ VALIDATION FAILED ✘✘✘"
  echo "One or more checks did not meet the requirements."
  exit 1
fi
