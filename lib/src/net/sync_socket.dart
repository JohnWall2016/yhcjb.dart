import 'dart:io';
import 'dart:convert';
import 'dart:collection';

class SyncSocket {
  RawSynchronousSocket _socket;
  final String host;
  final int port;
  final Encoding encoding;

  SyncSocket(String host, int port, {Encoding encoding = utf8})
      : this.host = host,
        this.port = port,
        this.encoding = encoding,
        _socket = RawSynchronousSocket.connectSync(host, port);

  void write(List<int> bytes) {
    _socket.writeFromSync(bytes);
  }

  void writeString(String str) {
    _socket.writeFromSync(encoding.encode(str));
  }

  List<int> read(int bytes) {
    return _socket.readSync(bytes);
  }

  int readInt() {
    var buf = read(1);
    if (buf.isNotEmpty) return buf[0];
    return null;
  }

  String readLine() {
    var buf = BytesBuilder();
    int c, n;
    while (true) {
      c = readInt();
      if (c == null) {
        return encoding.decode(buf.takeBytes());
      } else if (c == 0xd) {
        // \r
        n = readInt();
        if (n == null) {
          buf.addByte(c);
          return encoding.decode(buf.takeBytes());
        } else if (n == 0xa) {
          // \n
          return encoding.decode(buf.takeBytes());
        } else {
          buf.addByte(c);
          buf.addByte(n);
        }
      } else {
        buf.addByte(c);
      }
    }
  }

  String readHttpHeader() {
    var buf = StringBuffer();
    while (true) {
      var line = readLine();
      if (line == null || line == '') break;
      buf.write(line + '\n');
    }
    return buf.toString();
  }

  String readHttpBody([String header]) {
    var buf = BytesBuilder();

    void readBuf(int len) {
      while (len > 0) {
        var data = read(len);
        buf.add(data);
        len -= data.length;
      }
    }

    if (header == null || header.isEmpty) {
      header = readHttpHeader();
    }
    if (RegExp('Transfer-Encoding: chunked').hasMatch(header)) {
      while (true) {
        var len = int.parse(readLine(), radix: 16);
        if (len <= 0) {
          readLine();
          break;
        }
        readBuf(len);
        readLine();
      }
    } else {
      var match = RegExp(r'Content-Length: (\d+)').firstMatch(header);
      if (match != null) {
        var len = int.parse(match.group(1), radix: 10);
        readBuf(len);
      } else {
        throw UnsupportedError('Unsupported transfer mode');
      }
    }
    print(buf.length);
    return encoding.decode(buf.takeBytes());
  }

  void close() {
    _socket.closeSync();
  }

  String get url => '${host}:{port}';

  String getHttp(path) {
    var req = "GET ${path} HTTP/1.1\n" +
        "Host: ${url}\n" +
        "Connection: keep-alive\n" +
        "Cache-Control: max-age=0\n" +
        "Upgrade-Insecure-Requests: 1\n" +
        "User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36\n" +
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8\n" +
        "Accept-Encoding: gzip, deflate\n" +
        "Accept-Language: zh-CN,zh;q=0.9\n\n";
    this.writeString(req);
    return readHttpBody();
  }
}

class HttpRequest {
  SplayTreeMap<String, String> _headers = SplayTreeMap();
  BytesBuilder _body = BytesBuilder();
  final Encoding encoding;
  final String method;
  final String path;

  HttpRequest(this.path, {this.method = 'GET', this.encoding = utf8});

  void addHeader(String key, String value) => _headers[key] = value;
  void addBody(String buf) {
    var bytes = encoding.encode(buf);
    _body.add(bytes);
  }

  List<int> toBytes() {
    var bytes = BytesBuilder();
    bytes.add(encoding.encode('$method $path  HTTP/1.1\r\n'));
    _headers.forEach((key, value) {
      bytes.add(encoding.encode('$key: $value\r\n'));
    });
    if (_body.length > 0) {
      bytes.add(encoding.encode('Content-Length: ${_body.length}\r\n'));
    }
    bytes.add(encoding.encode('\r\n'));
    if (_body.length > 0) {
      bytes.add(_body.takeBytes());
    }
    return bytes.takeBytes();
  }
}
