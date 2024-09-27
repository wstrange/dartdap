# Testing dartdap

## Running tests

The _dartdap_ tests are implemented using the Dart
[test](https://pub.dev/packages/test) package.

To run all the tests:

    dart test

To run tests from a particular test file, specifying the path to the
test file:

    `dart test test/util_test.dart`

## Running specific tests using tags

You can run unit tests that do not require a running LDAP server using:

`dart test -t unit`

For more comprehensive testing, LDAP directories are required.

## Test LDAP Server

A sample OpenLDAP
server instance using Docker is the simplest way to execute the test suite.

Run the command:

```bash
cd test/etc
./openldap.sh
```

The sample server supports both LDAP (1389) and LDAPS (1636). The server uses a dummy certificate, so
you will want to use the bad certificate handler in the `LDAPConnection` setup to ignore any certificate errors.

## Test setup in setup.dart

The LDAP connection used by the tests is configured in `setup.dart`. It defaults to using the OpenLDAP docker image on
ports 1389/1636.

If for some reason you want to test against an alternative LDAP server, edit the connection in this file.

## Adding tests

If  your test does not require a running LDAP server (i.e. it is a unit test), add this to the top of your
test file:

```dart
@Tags(['unit'])
library;
```

If your test is specialized to a specific type of directory, you may want to create a tag for it. For example,
for ActiveDirectory:

```dart
@Tags(['AD'])
library;
```

Then run your test using  `dart test -t AD`

## Logging

Logging is configured in `setup.dart`. See the comments in the file for an example of
using heirarichal logging and changing the log levels.


