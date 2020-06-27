/// Tests the configuration loading utilities in "util_test.dart".
///
/// These tests do not use a LDAP server. They only test the LDAP configuration,
/// and not the connection to an LDAP server with those settings.
///
/// These tests should work with any properly set up configuration. That is,
/// it should work regardless of if there is a CONFIG.yaml file or not. And
/// should work regardless of the contents of the customized CONFIG.yaml file
/// (even if it does not have a "default" directory defined in it).

import 'package:test/test.dart';
import "util.dart" as util;

//----------------------------------------------------------------
/// Common tests that can be applied to any config file.
/// Even the default config, which specifies no directories.

void commonTestsOnAnyConfig(util.Config c) {
  // Looking for a non-existent directory configuration

  test("missing directory behaviour", () {
    const _missingDirectoryName = 'this-name-should-never-exist-in-any-config';
    expect(c.hasDirectory(_missingDirectoryName), isFalse);
    expect(c.directory(_missingDirectoryName), isNull);
  });

  // The secured LDAPS directory (if it is specified) must have TLS
  // This test will always be skipped when using the default config file.

  test("directory: ${util.ldapsDirectoryName}", () {
    final directoryConfig = c.directory(util.ldapsDirectoryName);

    expect(directoryConfig.ssl, equals(true),
        reason: 'TLS expected but not set: "${util.noLdapsDirectoryName}"');
  }, skip: c.skipIfMissingDirectory(util.ldapsDirectoryName));

  // The non-secured LDAP directory (if it is specified) must not have TLS
  // This test will always be skipped when using the default config file.

  test("directory: ${util.noLdapsDirectoryName}", () {
    final directoryConfig = c.directory(util.noLdapsDirectoryName);
    expect(directoryConfig.ssl, equals(false),
        reason: 'TLS not expected but is set): "${util.noLdapsDirectoryName}"');
  }, skip: c.skipIfMissingDirectory(util.noLdapsDirectoryName));
}

//----------------------------------------------------------------

void main() {
  test("config file missing", () {
    expect(() => util.Config(filename: 'CONFIG-file-does-not-exist.yaml'),
        throwsA(TypeMatcher<util.ConfigException>()));
  });

  test("config file contents not YAML", () {
    // Use the README.md file, which always exists but does not contain YAML
    expect(() => util.Config(filename: 'test/README.md'),
        throwsA(TypeMatcher<util.ConfigFileException>()));
  });

  group("config file: preferred or default", () {
    // This test may use either the preferred OR the default config file

    final c = util.Config();

    commonTestsOnAnyConfig(c);

    // Nothing else can be guaranteed, since the tester can create a preferred
    // config file that is customised to their special testing needs.
    // It might not even have a default directory specified!
  });

  group("config file: ${util.Config.defaultConfigFilename}", () {
    // Explicitly provide the filename, so the default config is always used.
    // Otherwise, *if* the preferred file exists ('test/CONFIG.yaml'), it will
    // be used instead and it will most certainly contain different
    // configurations from the default config file.

    final c = util.Config(filename: util.Config.defaultConfigFilename);

    commonTestsOnAnyConfig(c);

    test('does not specify any directories ', () {
      expect(c.hasDefaultDirectory, isFalse);
      expect(c.hasDirectory(util.Config.defaultDirectoryName), isFalse);
      expect(c.hasDirectory(util.noLdapsDirectoryName), isFalse);
      expect(c.hasDirectory(util.ldapsDirectoryName), isFalse);
      expect(c.directoryNames, isEmpty);
    });
  });
}
