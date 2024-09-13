Testing dartdap
===============

## Running tests

The _dartdap_ tests are implemented using the Dart
[test](https://pub.dev/packages/test) package.

To run all the tests:

    dart test

To run tests from a particular test file, specifying the path to the
test file:

    `dart test test/util_test.dart`

To run a particular test in a particular test file, specify the path
to the test file and the name of the test:

    `dart test test/util_test.dart --name 'config file: test/CONFIG-default.yaml missing directory behaviour'`

## Running specific tests using tags

You can run unit tests that do not require a running LDAP server:

`dart test -t unit`


For more comprehensive testing, LDAP directories are required.


## Test LDAP Server

A sample OpenLDAP
server instance using Docker is the simplest way to execute the test suite.

Run the command:

```
cd test/etc
./openldap.sh

```

The sample server supports both LDAP (1389) and LDAPS (1636). The server uses a dummy certificate, so
you will want to use the bad certificate  handler in the `LDAPConnection` setup to ignore it.

See `test/util.dart`.



## Adding tests

If  your test does not require a running LDAP server (i.e. it is a unit test), add this to the top of your
test file:

```dart
@Tags(['unit'])
library;
```

If your test is specialized to a specific type of directory, you may want to create a tag for it. For example,
for ActiveDirectory:

```
@Tags(['AD'])
library;
```

Then run your test using  `dart test -t AD`


## Configuring the LDAP Connection

The ldap connection is setup in `test/util.dart`.  The configuration options should be quite straightforward. The configuration provided
works against the sample OpenLDAP server, and uses LDAPS on port 1636.

## LDAP directories

### Requirements

To support tests with special needs, multiple test directories can be
used.

Use the default directory, whenever possible, to minimises the amount
of setup work required to create a test environment. Reuse directory
configurations whenever possible.


#### Configuration of directories

The "directories" item contains a map of directories. The key is the name of the directory, and is the value
that is used in the test. The value is a map containing these keys:

- `host` for the hostname (mandatory)
- `port` port number (defaults to the standard LDAP port 389 or the standard LDAPS port 636)
- `ssl` true for LDAPS, false for LDAP (defaults to false)
- `validate-certificate` false means to ignore bad server certificates (defaults to true)
- `bindDN` distinguished name of the entry for BIND (optional)
- `password` password to use in the BIND (mandatory if there is a _bindDN_)
- `testDN` distinguished name of the branch to use in the tests (mandatory)

#### Configuration of logging

The "logging" item contains a map of log levels. The key is the name
of the logger and the value is the logging level. The value can either
be a string value or an integer. See the
[logging](https://pub.dev/packages/logging) package for more details.



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
