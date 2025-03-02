#!/usr/bin/env bash
# Run a test OpenLDAP server.  Note the data is not preserved between runs.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# See https://hub.docker.com/r/bitnami/openldap

# Supports both LDAP and LDAPS:
docker run --rm --name openldap -it -p 1389:1389 -p 1636:1636 \
  --network my-network \
  --env LDAP_ADMIN_USERNAME=admin \
  --env LDAP_ADMIN_PASSWORD=password \
  --env LDAP_USERS=user1 \
  --env LDAP_PASSWORDS=password \
  --env LDAP_ROOT=dc=example,dc=com \
  --env LDAP_ADMIN_DN=cn=admin,dc=example,dc=com \
  --env LDAP_ADD_SCHEMA=yes \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --env LDAP_ENABLE_TLS=yes \
  --env LDAP_TLS_CERT_FILE=/opt/bitnami/openldap/certs/cert.pem \
  --env LDAP_TLS_KEY_FILE=/opt/bitnami/openldap/certs/key.pem \
  --env LDAP_TLS_CA_FILE=/opt/bitnami/openldap/certs/cert.pem \
  -v "$SCRIPT_DIR"/test/etc/certs:/opt/bitnami/openldap/certs \
  bitnami/openldap:latest



# Certs were generated using the command:
# brew install mkcert
# mkcert -cert-file certs/cert.pem -key-file certs/key.pem example.com '*.example.com'

# For Non SSL

# docker run --rm --name openldap -it -p 1389:1389 -p 1636:1636 \
#   --network my-network \
#   --env LDAP_ADMIN_USERNAME=admin \
#   --env LDAP_ADMIN_PASSWORD=password \
#   --env LDAP_USERS=user1 \
#   --env LDAP_PASSWORDS=password \
#   --env LDAP_ROOT=dc=example,dc=com \
#   --env LDAP_ADMIN_DN=cn=admin,dc=example,dc=com \
#   --env ALLOW_EMPTY_PASSWORD=yes \
#   bitnami/openldap:latest


# To test  the connection:
# ldapsearch -H ldap://localhost:1389/ -b dc=example,dc=com -D "cn=admin,dc=example,dc=com" -w password
# ldapsearch -H ldaps://localhost:1636/ -b dc=example,dc=com -D "cn=admin,dc=example,dc=com" -w password

# LDAPTLS_REQCERT=never ldapsearch -b "dc=example,dc=org" -w password -D "cn=admin,dc=example,dc=org" -H "ldaps://localhost:1636/" -v -x "(objectclass=*)"

# See https://kb.symas.com/en_US/configuration/how-to-create-certificates-for-openldap


# Add a sample OU:
# ldapadd -w password -D "cn=admin,dc=example,dc=org" -H "ldap://localhost:1389/" <<EOF
# dn: ou=people,dc=example,dc=org
# objectClass: organizationalUnit
# objectClass: top
# ou: people
# EOF
