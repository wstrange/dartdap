Testing dartdap
===============

This document describes the unit tests for the _dartdap_ package.

## Quick Start

1. Deploy a test LDAP directory server.

   The supplied test configuration (in _test/TEST-config.yaml_)
   expects the LDAP directory to have an entry for "dc=example,dc=com"
   and can bind to "cn=Manager,dc=example,dc=com" with the password
   "p@ssw0rd".

   A test LDAP directory can be deployed by running the supplied script on CentOS 7:

       testVM$  sudo ./SETUP-dartdap-testing-openldap-centOS7.sh

2. Establish port forwarding to the LDAP directory.

   The supplied test configuration expects LDAP on localhost port
   10389 and LDAPS on localhost port 10636.

       local$  ssh -L 10389:localhost:389 -L 10636:localhost:636 username@testVM

3. Run the tests:

       local$  pub run test

## Known issues

The tests all run successfully from within the WebStorm IDE.  But when
run from the command line, some of them fail with an "_OS Error: Too
many open files_" error message.

## Test LDAP directory server

### Requirements

The tests requires an LDAP directory that:

1. Supports the unencrypted LDAP protocol.

2. Supports the LDAP over TLS (LDAPS) protocol.

3. Contains an entry for "dc=example,dc=com".

4. Allows clients to bind to "cn=Manager,dc=example,dc=com" using the
    password "p@ssw0rd".

There are many LDAP directories to choose from, and many ways to
deploy them.  The package should work with any standard implementation
of LDAP, so the tests should work on other LDAP directories. If you
can, please test it different implementations of LDAP.

It is recommended to install the test LDAP directory in a virtual
machine. That way there is no risk of damage to a production LDAP
directory, and it can be easily deleted and recreated to run the tests
from a known state.

The sections below describe installing and configuring OpenLDAP on
CentOS 7. It describes two alternative ways: using the provided shell
script and doing it manually.

### Automatically creating the test LDAP directory server

This is one way to deploy a test LDAP directory server.

These instructions have been tested with CentOS 7.

1. Copy the _test/SETUP-dartdap-testing-openldap-centOS7.sh_ script to the CentOS 7 virtual
   machine.

        local$ scp SETUP-dartdap-testing-openldap-centOS7.sh username@testVM:

2. SSH to the virtual machine.

        local$ ssh username@testVM

3. Run the script with root privileges:

        testVM$ sudo ./SETUP-dartdap-testing-openldap-centOS7.sh

This will install and configure OpenLDAP with an automatically
generated self-signed certificate with the domain of "localhost"
(which will work for the tests). A PKI certificate and private key can
also be provided to the script: use "-h" to show the available
options.

The script will also run several test queries using _ldapsearch_.  If
the installation and configuration was successful, the tests will run
and "success" is printed out at the end.

Note: if the LDAP directory cannot be contacted, check if SELinux or
any firewalls running.

The script writes the admin password "s3cr3t" into
_/etc/openldap/password-admin.txt_.

The script writes the manager password "p@ssw0rd" into
_/etc/openldap/password-manager.txt_.

Skip down to the "SSH tunnels to the LDAP directory section.

### Manually creating the test LDAP directory server

This is another way to deploy a test LDAP directory server.

Install the OpenLDAP client and server.

On CentOS and Fedora:

    # yum install openldap-clients openldap-servers

On Ubuntu:

    # apt-get install libldap-2.3-0 slapd ldap-utils

Note: the new version of OpenLDAP no longer reads its configuration
from a slapd.conf file. The configurations are now stored under
/etc/openldap/slapd.d and should be managed using the OpenLDAP server
utilities.

Create a digest of the password to use with the _slappasswd_ program.

    # slappasswd

The tests expect the password to be "p@ssw0rd", which hashes to
`{SSHA}azrR84U0RhYICNLh5am74iMxnBBaDmN9`.

Edit the configuration file:

    # vi "/etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif"

Setting the values for `olcSuffix`, `olcRootDN` and adding the
digested password as the `olcRootPW` attribute. Warning: do not add
any blank lines to the file.

    olcSuffix: dc=example,dc=com
    olcRootDN: cn=Manager,dc=example,dc=com
    olcRootPW: {SSHA}azrR84U0RhYICNLh5am74iMxnBBaDmN9

Optionally, check the configuration files are correct by running
`slaptest -u`. Ignore any checksum errors that might be reported.

Start the LDAP server:

    # systemctl start slapd.service

If an error occurs, run `systemctl status -l slapd.service` to show
what went wrong.

Test the LDAP server with a simple search:

    $ ldapsearch -x
    $ ldapsearch -x -H ldap://localhost
    $ ldapsearch -x -b "dc=example,dc=com"

This should return "no such object", since initially that entry does
not exist.

    dn: dc=example,dc=com
    objectClass: dcObject
    objectClass: organization
    o: Example Organisation

    # ldapadd -x -W -D "cn=Manager,dc=example,dc=com" -f root-obj.ldif

Note: configure firewall or stop it.

    # systemctl stop firewalld.service

Load the other schemas:

    ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif 
    ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif 
    ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif 
    ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif 
    ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/misc.ldif 
    
## SSH tunnels to the LDAP directory

The supplied test configuration (in _test/TEST-config.yaml_) expects
to contact the test LDAP directory using:

- Port 10389 for LDAP (without TLS)
- Port 10636 for LDAPS (LDAP over TLS)

This can be done by creating SSH tunnels from local machine (where the
tests will be run) to the machine running the LDAP directory for both
unsecured LDAP (from local port 10389) and TLS secured LDAP (from
local port 10636).
   
      ssh -L 10389:localhost:389 -L 10636:localhost:636 username@testVM

#### Checking the tunnels

##### Checking LDAP

The (non-TLS) LDAP service can be tested by running _ldapsearch_:

    ldapsearch -H ldap://localhost:10389 \
      -D cn=Manager,dc=example,dc=com -x -w p@ssw0rd -b dc=example,dc=com

##### Checking LDAPS

This check should be skipped, because it will most likely fail (see
below for details) -- the unit tests will still work even though this
check fails.

The LDAPS (LDAP over TLS) service can be tested by running _ldapsearch_:

    ldapsearch -H ldaps://localhost:10636 \
      -D cn=Manager,dc=example,dc=com -x -w p@ssw0rd -b dc=example,dc=com

This check usually fails because the self-signed server certificate is
not trusted. Run it with "-d 1": if it prints out "SSLHandshake()
failed: misc. bad certificate" that is the reason.

To trust the self-signed certificate, put "TLS_REQCERT allow" in your
"~/.ldaprc" file (see "man ldap.conf" for details).

Important: remember to remove that entry when finished testing,
otherwise the security of your local machine could be compromised.

## Running the tests

### Running all the tests

If you have not done so already, run:

    pub get

Run all the tests in the directory (tests are files ending in
`_test.dart` in the default directory called `test`):

    pub run test

If the tests all run successfully, it will print out "All tests
passed".

Note: The load test might take about 30 seconds to run.

### Running some of the tests

Run a particular test file, by specifying the path to the test file:

    pub run test test/integration_test.dart

Run a particular test in a particular test file, but specifying the
path to the test file and the name of the test:

    pub run test test/integration_test.dart --name "search with filter: equals attribute in DN"

The tests can also be run directly as a Dart program:

    dart test/integration_test.dart


## See also

For information on writing tests see
<https://pub.dartlang.org/packages/test>
