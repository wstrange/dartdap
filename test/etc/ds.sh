#!/usr/bin/env bash
# For ForgeRock DS.

# Creates the backend
dsconfig create-backend \
          --set base-dn:dc=example,dc=com \
          --set enabled:true \
          --type je \
          --backend-name userRoot \
          --hostname Warrens-MacBook-Air.local \
          --port 4444 \
          --bindDn uid=admin \
          --bindPassword password \
          --trustAll \
          --no-prompt



ldapadd -D "uid=admin" -w password -p 1636 -h Warrens-MacBook-Air.local

dn: ou=people,dc=param,dc=co,dc=in
objectClass: top
objectClass: organizationalUnit
ou: people


./ldapmodify -D "uid=admin" -w password -p 1636 -h localhost --trustAll --useSsl <<EOF
dn: ou=people,dc=example,dc=com
changetype: add
ou: people
objectClass: organizationalUnit
objectClass: top
EOF



