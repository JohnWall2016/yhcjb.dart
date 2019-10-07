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
    if (buf != null && buf.isNotEmpty) return buf[0];
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

  HttpHeader readHttpHeader() {
    var header = HttpHeader();
    while (true) {
      var line = readLine();
      if (line == null || line == '') break;

      var i = line.indexOf(':');
      if (i > 0) header.add(line.substring(0, i), line.substring(i + 1).trim());
    }
    return header;
  }

  String readHttpBody([HttpHeader header]) {
    var buf = BytesBuilder();

    void readBuf(int len) {
      while (len > 0) {
        var data = read(len);
        buf.add(data);
        len -= data.length;
      }
    }

    if (header == null) {
      header = readHttpHeader();
    }
    if (header['Transfer-Encoding']?.contains('chunked') ?? false) {
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
      var length = header['Content-Length'];
      if (length != null) {
        var len = int.parse(length[0], radix: 10);
        readBuf(len);
      } else {
        throw UnsupportedError('Unsupported transfer mode');
      }
    }
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

class HttpHeader extends SplayTreeMap<String, List<String>> {
  List<String> operator [](Object key) => super[(key as String).toLowerCase()];

  void operator []=(Object key, List<String> values) =>
      super[(key as String).toLowerCase()] = values;

  void add(String name, String value) {
    var key = name.toLowerCase();
    if (!containsKey(key)) {
      super[key] = [];
    }
    super[key].add(value);
  }
}

class HttpRequest {
  HttpHeader _header = HttpHeader();
  BytesBuilder _body = BytesBuilder();
  final Encoding encoding;
  final String method;
  final String path;

  HttpRequest(this.path,
      {this.method = 'GET', this.encoding = utf8, HttpHeader header}) {
    if (header != null) _header.addAll(header);
  }

  void addHeader(String key, String value) => _header.add(key, value);

  void addBody(String buf) {
    var bytes = encoding.encode(buf);
    _body.add(bytes);
  }

  List<int> toBytes() {
    var bytes = BytesBuilder();
    bytes.add(encoding.encode('$method $path  HTTP/1.1\r\n'));
    _header.forEach((key, values) {
      values.forEach((value) {
        bytes.add(encoding.encode('$key: $value\r\n'));
      });
    });
    if (_body.length > 0) {
      bytes.add(encoding.encode('content-length: ${_body.length}\r\n'));
    }
    bytes.add(encoding.encode('\r\n'));
    if (_body.length > 0) {
      bytes.add(_body.takeBytes());
    }
    return bytes.takeBytes();
  }
}
