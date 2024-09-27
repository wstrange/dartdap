#!/bin/sh
#
# NOT MAINTAINED - use at your own risk!
#
# Setup a standard dartdap test directory using OpenLDAP on CentOS.
# See README.md for what a "standard" test directory is.
#
# IMPORTANT: currently only works on CentOS 7 (using default mode).
# It works on CentOS 8, but only with the "--tls-none" option.
# So the "ldaps" directory configuration cannot use it, and
# therefore tests that require it will be skipped.
#
# Usage:
# 1. Create a new CentOS 7 or CentOS 8 machine (e.g. on a virtual machine).
# 2. Copy this script to it.
# 3. Run it with root privileges: sudo ./SETUP-openldap-centos.sh
#
# Run with -h to see the available options for setting up TLS
# (i.e. LDAPS).  The default option is recommended (it uses the
# generated self-signed certificate that CentOS 7's openlda-servers
# package automatically creates).  Some of the tests require an LDAPS
# directory (so they must be skipped if the "--tls-none" option is
# used), and changes in recent versions of OpenLDAP means the "tls"
# option (where you provide the private key and certificates) doesn't
# work anymore!
#
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/ch-Directory_Servers.html#s1-OpenLDAP
# https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS

PROG=`basename "$0"`
PROGDIR=`dirname "$0"`

trap "echo $PROG: error: aborted; exit 3" ERR

#----------------------------------------------------------------
# Constants

BRANCH_DN="dc=example,dc=com"
BIND_DN="cn=Manager,${BRANCH_DN}"
TEST_DN="ou=testing,${BRANCH_DN}"

ADMIN_PASSWORD=s3cr3t
MANAGER_PASSWORD=password

ADMIN_PASSWORD_FILE=/etc/openldap/password-admin.txt
MANAGER_PASSWORD_FILE=/etc/openldap/password-manager.txt

# Location of the Mozilla NSS certificate/key database

NSS_DIR=/etc/openldap/certs

# QUIET=
QUIET=--quiet

#----------------------------------------------------------------
# Process arguments

if [ $# -eq 1 -a "$1" = '--tls-none' ]; then
  TLS_SETUP=none
elif [ $# -eq 0  -o  $# -eq 1 -a "$1" = '--tls-default' ]; then
  TLS_SETUP=default
  TLS_DOMAIN=localhost
elif [ $# -ge 4 -a "$1" = '--tls' ]; then
  TLS_SETUP=provided; shift
  TLS_DOMAIN="$1"; shift
  TLS_PVT="$1"; shift
  TLS_CRT="$1"; shift
  if [ ! -f "$TLS_PVT" ]; then
    echo "$PROG: error: file not found: $TLS_PVT" >&2
    exit 1
  fi
  if [ ! -f "$TLS_CRT" ]; then
    echo "$PROG: error: file not found: $TLS_CRT" >&2
    exit 1
  fi
else
  echo "Usage: $PROG [options]"
  echo "Options:"
  echo "  --tls-default"
  echo "      - use self-signed certificate generated by install (default)"
  echo "  --tls domainname server.pvt server.crt {issuer.crt...}"
  echo "      - setup with explicitly provided PKI credentials"
  echo "  --tls-none"
  echo "      - do not setup LDAPS, only setup LDAP"
  exit 0
fi

#----------------------------------------------------------------
# Check permissions

if [ `id -u` -ne 0 ]; then
  echo "$PROG: error: root privileges required (see -h for help)" >&2
  exit 1
fi

#----------------------------------------------------------------
# Detect Linux distribution

DISTRO=unknown
if [ -f '/etc/system-release' ]; then
  DISTRO=`head -1 /etc/system-release`
fi

if echo "$DISTRO" | grep '^CentOS Linux release 7' > /dev/null; then
  YUM=yum
  USE_SYMAS=
elif echo "$DISTRO" | grep '^CentOS Linux release 8' > /dev/null; then
  YUM=dnf
  USE_SYMAS=yes
  # Using Symas OpenLDAP packages <https://symas.com/linuxopenldap/>,
  # since "openldap-server" is no longer provided with CentOS 8.

  if [ "$TLS_SETUP" != 'none' ]; then
    cat >&2 <<EOF
$PROG: CentOS 8 with LDAPS (LDAP over TLS) is not supported.
  Either:
  1. Use CentOS 7 instead, which this script fully supports;
  2. Install with the "--tls-none" option (but that will only allow the tests
     that use LDAP to pass, those that use LDAPS won't pass); or
  3  Help update this script so it configures the Symas OpenLDAP server
     to run with LDAPS enabled.
EOF
    exit 3  # TODO: add commands to configure TLS and remove this error
    # Unlike CentOS 7's openldap-server package, installing Symas does not
    # generate a self-signed certificate and setup /etc/openldap/certs.
    # This script will have to do that and also configure OpenLDAP for TLS.
  fi
else
  echo "$PROG: error: unsupported distribution: $DISTRO" >&2
  exit 1
fi

#----------------------------------------------------------------
# Install OpenLDAP

if [ -n "$USE_SYMAS" ]; then
  # Set up repository to use Symas build of OpenLDAP

  echo "$PROG: using Symas OpenLDAP"
  curl --silent --output /etc/yum.repos.d/sofl.repo \
       https://repo.symas.com/configs/SOFL/rhel8/sofl.repo

  # Packages and backend for Symas OpenLDAP server

  PACKAGES="symas-openldap-servers symas-openldap-clients nss-tools"
  BACKEND=mdb
else
  # Packages and backend for OpenLDAP server provided by CentOS 7 distro

  PACKAGES="openldap-servers openldap-clients"
  BACKEND=hdb
fi

# Install packages

for PKG in $PACKAGES; do
  if ! rpm -q "${PKG}" >/dev/null; then
    echo "$PROG: $YUM install ${PKG}"
    $YUM install -y $QUIET "${PKG}"
  fi
done

#----------------------------------------------------------------
# Configure OpenLDAP

# No longer needed since Symas OpenLDAP uses mdb backend and not hdb?
#
# Configure backend storage (so warnings aren't generated by slapd)
#
# if [ ! -f /var/lib/ldap/DB_CONFIG ]; then
#     # Create a DB_CONFIG file so the HDB storage mechanism performs better
#
#     cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
#     chown ldap. /var/lib/ldap/DB_CONFIG
# fi

#----------------------------------------------------------------
# Start the slapd service

echo "$PROG: enabling slapd to start at boot"
systemctl enable slapd.service

echo "$PROG: starting slapd"
systemctl start slapd.service

#----------------------------------------------------------------
# Configure the administration password

# Store the password in a file, so it can be securely passed to slappasswd

if [ ! -e "$ADMIN_PASSWORD_FILE" ]; then
  touch "$ADMIN_PASSWORD_FILE"
  chmod 600 "$ADMIN_PASSWORD_FILE"
  /bin/echo -n "$ADMIN_PASSWORD" > "$ADMIN_PASSWORD_FILE"
  chmod 400 "$ADMIN_PASSWORD_FILE"
  echo "$PROG: saving password: $ADMIN_PASSWORD_FILE"
else
  echo "$PROG: using password file: $ADMIN_PASSWORD_FILE"
fi

# Hash the password

PASSWORD_HASH=`slappasswd -n -T "$ADMIN_PASSWORD_FILE"`

# Set the admin password in OpenLDAP

echo "$PROG: setting OpenLDAP admin password"

ldapadd -Y EXTERNAL -Q -H ldapi:/// <<EOF
dn: olcDatabase={0}config,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: ${PASSWORD_HASH}
EOF

#----------------------------------------------------------------
# Import some standard schemas

if ! ldapsearch -Y EXTERNAL -H ldapi:/// -b cn={1}cosine,cn=schema,cn=config * -LLL >/dev/null 2>&1; then
  echo "$PROG: importing standard schemas"

  ldapadd -Y EXTERNAL -Q -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
  ldapadd -Y EXTERNAL -Q -H ldapi:/// -f /etc/openldap/schema/nis.ldif
  ldapadd -Y EXTERNAL -Q -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
fi

#----------------------------------------------------------------
# Configure the directory tree

# Configure the manager password

# Store the password in a file, so it can be securely passed to slappasswd

if [ ! -e "$MANAGER_PASSWORD_FILE" ]; then
  touch "$MANAGER_PASSWORD_FILE"
  chmod 600 "$MANAGER_PASSWORD_FILE"
  /bin/echo -n "$MANAGER_PASSWORD" > "$MANAGER_PASSWORD_FILE"
  chmod 400 "$MANAGER_PASSWORD_FILE"
  echo "$PROG: saving password: $MANAGER_PASSWORD_FILE"
else
  echo "$PROG: using password file: $MANAGER_PASSWORD_FILE"
fi

# Hash the password

PASSWORD_HASH=`slappasswd -n -T "$MANAGER_PASSWORD_FILE"`

# Create the branch

echo "$PROG: setting test manager password"


ldapmodify -Y EXTERNAL -Q -H ldapi:/// <<EOF
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess:{0}
  to
    * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth"
    read by dn.base="${BIND_DN}"
    read by * none

dn: olcDatabase={2}$BACKEND,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: ${BRANCH_DN}

dn: olcDatabase={2}$BACKEND,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: ${BIND_DN}

dn: olcDatabase={2}$BACKEND,cn=config
changetype: modify
#add: olcRootPW
replace: olcRootPW
olcRootPW: ${PASSWORD_HASH}

dn: olcDatabase={2}$BACKEND,cn=config
changetype: modify
#add: olcAccess
replace: olcAccess
olcAccess:{0}
  to
    attrs=userPassword,shadowLastChange by dn="${BIND_DN}"
    write by anonymous
    auth by self
    write by * none
olcAccess:{1}
 to
   dn.base="" by * read
olcAccess:{2}
  to
    * by dn="${BIND_DN}"
    write by * read
EOF

#----------------------------------------------------------------
# Populate the branch with entries

echo "$PROG: populating test branch: ${BRANCH_DN}"

if ldapdelete -x -D ${BIND_DN} -y ${MANAGER_PASSWORD_FILE} \
	      -r ${BRANCH_DN} >/dev/null 2>&1; then
  echo "$PROG: deleted existing entries from ${BRANCH_DN}"
fi

ldapadd -x -D ${BIND_DN} -y ${MANAGER_PASSWORD_FILE} <<EOF
dn: ${BRANCH_DN}
o: Example Organization
objectClass: top
objectClass: dcObject
objectclass: organization

dn: ${TEST_DN}
objectClass: organizationalUnit

#dn: ${BIND_DN}
#description: Directory Manager
#objectClass: organizationalRole
#
#dn: ou=Users,${TEST_DN}
#objectClass: organizationalUnit
#
#dn: ou=Groups,${TEST_DN}
#objectClass: organizationalUnit
EOF

#----------------------------------------------------------------
# Configure TLS so slapd supports LDAPS

if [ "$TLS_SETUP" = 'provided' ]; then
  # Add provided credentials to the certificate and private key database

  # OpenSSL uses Mozilla NSS, which is managed using the "certutil" and
  # "modutil" commands.

  # Create PKCS#12

  PKCS12_FILE="/etc/openldap/${TLS_DOMAIN}.p12"
  TLS_NAME="${TLS_DOMAIN}"

  touch "${PKCS12_FILE}"
  chmod 600 "${PKCS12_FILE}"
  openssl pkcs12 -export \
	  -inkey "${TLS_PVT}" -in "$TLS_CRT" \
	  -out "${PKCS12_FILE}" -passout pass:"" -name "${TLS_NAME}"

  # Remove (just in case it is already in the NSS)
  # Wrapped in "if" to ignore error if it fails

  if certutil -d "$NSS_DIR" -D -n "${TLS_NAME}" >/dev/null 2>&1;
  then : ; fi

  # Remove issuer certificates

  for ISSUER_CRT in $*; do
    NAME=`basename "${ISSUER_CRT}" .crt`
    if certutil -d "$NSS_DIR" -D -n "$NAME" >/dev/null 2>&1;
    then : ; fi
  done

  # Import it into the NSS

  pk12util -d "$NSS_DIR" -k "$NSS_DIR"/password \
	   -i "${PKCS12_FILE}" -W ""

  # Sometimes pk12util claims to have imported succesfully, but doesn't.
  # Check for this situation.

  if ! certutil -d "$NSS_DIR" -L | grep "^${TLS_NAME}" >/dev/null; then
    echo "$PROG: pk12util failed to import the PKCS#12 file" >&2
    echo "$PROG: Remove some certs from the NSS database and try again." >&2
    exit 1
  fi

  rm "${PKCS12_FILE}"

  # Change the trust attributes on it
  # TODO: nothing changes, trust attributes remain "u,u,u". Bug in certutil?

  certutil -d "$NSS_DIR" -M -n "${TLS_NAME}" -t "u,,"

  if [ $# -gt 0 ]; then
    # Add issuer certificates
    for ISSUER_CRT in $*; do
      NAME=`basename "${ISSUER_CRT}" .crt`
      certutil -d "$NSS_DIR" -A -i "${ISSUER_CRT}" -n "$NAME" -t "c,,"
    done

  else
    # No issuer certificates (assume it is self signed): trust it as a CA
    certutil -d "$NSS_DIR" -M -n "$TLS_NAME" -t "Cu,,"
  fi

elif [ "$TLS_SETUP" = 'default' ]; then
  # Self-signed certificate should already exist with this name

  TLS_NAME="OpenLDAP Server"
fi

if [ "$TLS_SETUP" != 'none' ]; then
  # Check certificate exists in the Mozilla NSS certificate/key database

  if ! certutil -d "$NSS_DIR" -L -n "$TLS_NAME" >/dev/null ; then
    echo "$PROG: error: NSS database missing credentials: \"$TLS_NAME\" ($NSS_DIR)" >&2
    exit 1
  fi

fi

if [ "$TLS_SETUP" = 'provided' ]; then
  # Configure OpenLDAP to use provided credentials
  #
  # When using Mozilla NSS, the value of "olcTLSCertificateFile" is
  # repurposed as the name of the certificate in the NSS database.
  # The directory containing the NSS certificate/key database
  # is specified by "TLS_CACERTDIR" in /etc/openldap/ldap.conf,
  # or in the cn=config entry as the "olcTLSCACertificatePath" attribute.
  #
  # See <https://www.openldap.org/faq/data/cache/1514.html>

  echo "$PROG: setting OpenLDAP TLS certificates"

  ldapmodify -Y EXTERNAL -Q -H ldapi:/// <<EOF
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: "${TLS_NAME}"
EOF
fi
# Note: if using "default" the package installed OpenLDAP should
# already be configured to use the automatically generated
# credentials. The olcTLSCertificateFile should already have the
# value of "OpenLDAP Server", which is the name of the self-signed
# certificate in the Mozilla NSS store in /etc/openldap/certs.

if [ "$TLS_SETUP" != 'none' ]; then
  # Enable TLS

  # Edit /etc/sysconfig/slapd to add "ldaps:///" to SLAPD_URLS
  # so slapd will listen on port 636 for LDAP over TLS (as well
  # as supporting StartTLS on port 386).

  sed --in-place=.bak \
      -e 's|^SLAPD_URLS=.*|SLAPD_URLS="ldapi:/// ldap:/// ldaps:///"|' \
      /etc/sysconfig/slapd
# else
#   # Disable TLS (actually this should be unnecessary, since the package
#   # should have installed OpenLDAP without "ldaps://")
#
#   # Edit /etc/sysconfig/slapd to remove "ldaps:///" from SLAPD_URLS
#
#   sed --in-place=.bak \
#       -e 's|^SLAPD_URLS=.*|SLAPD_URLS="ldapi:/// ldap:///"|' \
#       /etc/sysconfig/slapd

  # Warning: StartTLS is still enabled. Only LDAPS is disabled
  # Does it matter? Do we need to fix this?
fi

# Restart slapd so above configurations are used

systemctl restart slapd.service

echo "$PROG: LDAP directory installed and configured"

#----------------------------------------------------------------
# Test searches to make sure installation is working as expected

echo
echo "$PROG: performing some test LDAP searches"
echo

sleep 3  # give slapd time to start up

echo "$PROG: ldap://localhost (no TLS)"
ldapsearch \
  -H ldap://localhost \
  -D ${BIND_DN} -x -y ${MANAGER_PASSWORD_FILE} \
  -LLL \
  -b ${BRANCH_DN} '(dc=*)'

if [ "$TLS_SETUP" != 'none' ]; then

  echo "$PROG: ldap://${TLS_DOMAIN} + optional StartTLS"
  ldapsearch -Z \
	     -H ldap://"${TLS_DOMAIN}" \
	     -D ${BIND_DN} -x -y ${MANAGER_PASSWORD_FILE} \
	     -LLL \
	     -b ${BRANCH_DN} '(dc=*)'

  echo "$PROG: ldap://${TLS_DOMAIN} + mandatory StartTLS"
  ldapsearch -ZZ \
	     -H ldap://"${TLS_DOMAIN}" \
	     -D ${BIND_DN} -x -y ${MANAGER_PASSWORD_FILE} \
	     -LLL \
	     -b ${BRANCH_DN} '(dc=*)'

  echo "$PROG: ldaps://${TLS_DOMAIN} (LDAP over TLS)"
  ldapsearch \
    -H ldaps://"${TLS_DOMAIN}" \
    -D ${BIND_DN} -x -y ${MANAGER_PASSWORD_FILE} \
    -LLL \
    -b ${BRANCH_DN} '(ou=*)'
else
  echo "$PROG: warning: LDAPS (LDAP over TLS) is not available"
fi

cat <<EOF
--
Success: LDAP directory deployed:
  bindDN: "${BIND_DN}"
  password: "$MANAGER_PASSWORD"
  testDN: "${TEST_DN}"
EOF

exit 0

#EOF
