Testing dartdap
===============

## Running tests

The _dartdap_ tests are implemented using the Dart
[test](https://pub.dev/packages/test) package.

To run all the tests:

    pub run test

To run tests from a particular test file, specifying the path to the
test file:

    pub run test test/util_test.dart

To run a particular test in a particular test file, specify the path
to the test file and the name of the test:

    pub run test test/util_test.dart --name 'config file: test/CONFIG-default.yaml missing directory behaviour'

### No setup

Initially, the tests will load the default configuration file from
"test/CONFIG-default.yaml". Since that configuration does not specify
any LDAP directories to use, it will skip all the tests that require
an LDAP directory.

For more comprehensive testing, LDAP directories are required.

## LDAP directories

### Requirements

To support tests with special needs, multiple test directories can be
used.

Use the default directory, whenever possible, to minimises the amount
of setup work required to create a test environment. Reuse directory
configurations whenever possible.

#### Default

Most of the tests require access to a default LDAP directory. A this
is a LDAP directory that satisfies these requirements:

- Allows BIND to a entry using a password.
- Has an LDAP entry where the tests can create/delete child entries under.

The default directory has the name "default", which is available as
the constant `Config.defaultDirectoryName`. But there are convenience
methods available, so that constant is rarely used in code. See
the documentation in _test/util.dart_ for details.

Note: the default directory can use either LDAP or LDAPS.

#### LDAPS

Some of the tests require access to an LDAPS directory. In addition to
the requirements for the default directory, connections to this
directory *must* use LDAPS (i.e. LDAP over TLS).

The LDAPS directory has the name "ldaps", which is available via the
constant `ldapsDirectoryName` from _util.dart_.

#### LDAP

The BIND tests require access to an LDAP directory. In addition to
the requirements for the default directory, connections to this
directory *must* use LDAP (i.e. LDAP without TLS).

The LDAP directory has the name "ldap", which is available via the
constant `noLdapsDirectoryName` from _util.dart_.

#### Other specialized test directories

Tests with special requirements can also be supported.

Since tests will be skipped if the necessary directory configuration
is not available, these will only run if the tester has setup a test
environment for it. So they will not prevent the other tests from
being run in a different environment.

An extreme example is the default configuration file, which does
not specify any test directories.

Use directory configuration names that identify the behaviour of the
LDAP directory, rather how it is implementation.  For example, use
avoid names like "openldap" or "active-directory", unless the tests
are designed for implementation specific features of those products.

### Deploying test directories

Since _dartdap_ implements standard LDAP, it should work with any
implementation of an LDAP directory.

It is outside the scope of this document to describe how to setup a
test LDAP directory in your test environment. But, for example, the
_test/SETUP-openldap-centos.sh_ script can be used to deploy a
standard test LDAP directory on CentOS 7 using OpenLDAP. Please
consider writing scripts and documentation to help others setup test
environments with with different LDAP implementations.

## Configuration

### File selection

The tests attempt to load the configuration from a file named
"test/CONFIG.yaml".  If that file does not exist, it will load the
"test/CONFIG-default.yaml" file. So to override the default
configuration, create a "test/CONFIG.yaml" file.

The recommended practice is to create a separate file and make
"test/CONFIG.yaml" a symbolic link (or shortcut) to it. That allows
different configuration files to exist, and to change between them by
changing the symlink.  Do not check-in the "test/CONFIG.yaml" file,
otherwise it will prevent the default config file from being used by
other testers until they have setup an LDAP directory that matches
your environment. The _.gitignore_ file has entries for
"test/CONFIG.yaml" to prevent it from being accidentally included in the
source code repository.

For example, the example "test/CONFIG-standard.yaml" configuration
file assumes SSH port forwarding is used to connect to the LDAP
directory. So it can be used like this on the local machine:

    $ ln -s CONFIG-standard.yaml CONFIG.yaml
    $ ssh -L 1389:localhost:389 -L 1636:localhost:636 username@testVM

And the tests run from a different session on the local machine:

    $ pub run test

### File contents

The configuration files are YAML files with two items: directories and
logging. Both of them are optional.

#### Configuration of directories

The "directories" item contains a map of directories. The key is the name of the directory, and is the value
that is used in the test. The value is a map containing these keys:

- `host` for the hostname
- `port` optional port number (defaults to the standard LDAP port 389 or the standard LDAPS port 636)
- `tls` true for LDAPS, false for LDAP (defaults to false)
- `validate-certificate` false means to ignore bad server certificates (default is true)
- `bindDN` distinguished name of the entry for BIND
- `password` password to use in the BIND
- `baseDN` distinguished name of the entry to use in the tests

#### Configuration of logging

The "logging" item contains a map of log levels. The key is the name
of the logger and the value is the logging level. The value can either
be a string value or an integer. See the
[logging](https://pub.dev/packages/logging) package for more details.

#### Example

``` yaml
# Example test configuration

directories:
  default:
    host: server1.test.example.org
	port: 636
	tls: true
	validate-certificate: true
	bindDN: cn=tester,ou=testing,dc=example,dc=com
	password: secretSoDoNotCheckThisFileIn
	baseDN: ou=test,ou=dartdap,ou=testing,dc=example,dc=com
  custom:
    host: server2.test.example.org
	port: 389
	tls: false
	bindDN: cn=tester,ou=testing,dc=example,dc=com
	password: secretSoDoNotCheckThisFileIn
	baseDN: ou=test,ou=dartdap,ou=testing,dc=example,dc=com

logging:
  ldap.recv.asn1: FINE
  ldap.recv.bytes: INFO
  ldap.recv.ldap: FINER
  ldap.recv: FINEST
  ldap.send.bytes: INFO
  ldap.send.ldap: INFO
  ldap.send: FINEST
  ldap: INFO
```

## Writing tests

The configuration file is loaded using the `Config` constructor. A
filename can be provided, but normally it should not be provided so
the normal behaviour of using either "test/CONFIG.yaml" or
"tests/CONFIG-default.yaml" is used. See the documentation/comments in
_test/util.dart_ for more details.

All tests that require an LDAP directory should be skipped if that
directory is not available in the test environment (i.e. not specified
in the configuration file). The `skipIfMissingDirectory` or
`skipIfMissingDefaultDirectory` is designed for use with the _skip_
parameter of the _test_ or _group_ method.

``` dart
void main() {
  final config = util.Config();

  group('tests', () {
    LdapConnection ldap;
	
    setup(() async {
	  ldap = config.defaultDirectory.connect();
	});

    tearDown(() async {
	  await ldap.close();
    });

    test("foobar", () async {
      ... use ldap ...
	});

  }, skip: config.skipIfMissingDefaultDirectory);

  group('special tests', () {
    ...
  }, skip: config.skipIfMissingDirectory('special-directory-name'));
}
```

Warning: the group function is still executed, even if _skip_ tells it
to be skipped! Therefore, statements that will fail when the directory
is not available must be placed inside actual tests or in the group's
_setup_ method.

Before checking in your tests, please make sure they work with the
default configuration. That is, they are correctly skipped if no test
directories are available.

The goal is for the tests to run in any test environment, and for the
tests to run without needing to modify the code. All test environment
specific details should be specified in the configuration files.

## See also


- [test](https://pub.dartlang.org/packages/test) package

- [logging](https://pub.dev/packages/logging) package
