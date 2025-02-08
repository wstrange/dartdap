// keeps tabs on a connection. How long it has been opened.
// Checked out or not, etc.
class ConnectionInfo {
  bool inUse = false; // true if the connection is being used: getConnection()
  int id = 0; // uniquely identify a connection. This is the

  DateTime? lastHealthCheck;
  DateTime created = DateTime.now();
}
