import 'dart:io';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as path;

resizeImageDir(String dir) {
  var inDir = Directory(dir);
  var outDir = Directory(path.join(dir, 'resize'));
  if (!outDir.existsSync()) {
    outDir.createSync();
  }
  if (inDir.existsSync()) {
    for (var f in inDir.listSync()) {
      if (RegExp(r'.*\.jpg', caseSensitive: false).firstMatch(f.path) != null) {
        print(f.path);
        var originalImage = image.decodeJpg(File(f.path).readAsBytesSync());
        var resizedImage =
            image.copyResize(originalImage, width: originalImage.width ~/ 2);
        File(path.join(outDir.path, path.basename(f.path)))
            .writeAsBytesSync(image.encodeJpg(resizedImage, quality: 50));
      }
    }
  }
}

main() {
  resizeImageDir('D:\\单位事务\\平安建设\\20190830');
}
