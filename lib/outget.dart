import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:gazou/main.dart';
// import 'package:quiver/async.dart';
import 'package:gazou/pause.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gazou/outblaze.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/services.dart';
// ↓copy_resize用
import 'package:image/image.dart' as imgLib;
import 'dart:typed_data';


/// 写真撮影画面
class OutTakePicture1 extends StatefulWidget {
  const OutTakePicture1({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  OutTakePicture1State createState() => OutTakePicture1State();
}

class OutTakePicture1State extends State<OutTakePicture1> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int tmp = 0;
  int count = 0;
  final _audio = AudioCache();
  //色
  var appbar_colors = Colors.white;
  var appbar_text_colors = Colors.black;
  var main_colors = Colors.black;
  var sub_colors = Colors.black;
  var main_text_colors = Colors.white;
  var sub_text_colors = Colors.white;
  var icon_colors = Colors.black;
  //ID定義（全ウィジェットで共有するため static を使用）
  static String? id;

  @override
  void initState() {
    super.initState();
    // アプリを終了せずに，再度撮影を行なうときはIDを初期化
    id = null;
    // 時間情報の取得とIDの作成
    if (id == null) {
      DateTime now = DateTime.now();
      String year = now.year.toString();
      String month = now.month.toString().padLeft(2, '0');
      String day = now.day.toString().padLeft(2, '0');
      String hour = now.hour.toString().padLeft(2, '0');
      String minute = now.minute.toString().padLeft(2, '0');
      String second = now.second.toString().padLeft(2, '0');
      id = year + "_" + month + "_" + day + "_" + hour + minute + second;
    }

    _controller = CameraController(
      // カメラを指定
      widget.camera,
      // 解像度を定義
      ResolutionPreset.medium,
    );

    // コントローラーを初期化
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    if (count == 0) {
      _audio.play('syoumen.mp3');
      count++;
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('正面を向いてください', style: TextStyle(color: appbar_text_colors)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
            },
            icon: Icon(Icons.home, color: icon_colors),
          )
        ],
        backgroundColor: appbar_colors,
      ),
      body: Stack(
        alignment: Alignment.center,
        fit: StackFit.loose,
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
          Opacity(
            opacity: check ? opacity = 0.8 : opacity = 0.8,
            child: Image.asset("assets/syoumen.png"),
          ),
          CustomPaint(
            painter: CenterLinePainter(),
            child: Container(),
          ),
          //横線に関するソースコード
          CustomPaint(
            painter: BottomLinePainter(),
            child: Container(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 1.5,
                    left: MediaQuery.of(context).size.height * 0.3),
                child: Transform.scale(
                  scale: 2,
                  child: FloatingActionButton(
                    onPressed: () async {
                      // 写真を撮る
                      final image = await _controller.takePicture();

                      //画像をローカルに保存
                      String imagePath = image.path; // XFile からファイルのパスを取得
                      await _saveImageToGallery(imagePath);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OutBlazePage1(imagePath: image.path, camera: widget.camera),
                        ),
                      );
                      // path を出力
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //画像をローカルに保存
  Future<void> _saveImageToGallery(String imagePath) async {
    // 画像を保存するファイル名を指定
    final fileName = "$id-front.jpg";
    // 保存したい画像ファイルのパスとファイル名を指定して保存
    final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

    if (result != null) {
      print('画像がギャラリーアルバムに保存されました: $result');
    } else {
      print('画像の保存に失敗しました');
    }
  }
}

class CenterLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final top = Offset(centerX, 0);
    final bottom = Offset(centerX, size.height);

    canvas.drawLine(top, bottom, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

//横線に関するソースコード
class BottomLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centerY = size.height * 0.8; // 画面の80%の位置に配置
    final left = Offset(0, centerY);
    final right = Offset(size.width, centerY);

    canvas.drawLine(left, right, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// 以下、OutTakePicture2とOutTakePicture3も同様に修正

/// 写真撮影画面
class OutTakePicture2 extends StatefulWidget {
  const OutTakePicture2({
    Key? key,
    required this.camera,
    required this.path1,
    required this.offsets1,
  }) : super(key: key);

  final CameraDescription camera;
  final String path1;
  final List<Offset> offsets1;

  @override
  OutTakePicture2State createState() => OutTakePicture2State();
}

class OutTakePicture2State extends State<OutTakePicture2> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int tmp = 0;
  int count = 0;
  final _audio = AudioCache();
  //色
  var appbar_colors = Colors.white;
  var appbar_text_colors = Colors.black;
  var main_colors = Colors.black;
  var sub_colors = Colors.black;
  var main_text_colors = Colors.white;
  var sub_text_colors = Colors.white;
  var icon_colors = Colors.black;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      // カメラを指定
      widget.camera,
      // 解像度を定義
      ResolutionPreset.medium,
    );

    // コントローラーを初期化
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    if (count == 0) {
      _audio.play('hidari.mp3');
      count++;
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('⇨を向いてください', style: TextStyle(color: appbar_text_colors)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
            },
            icon: Icon(Icons.home, color: icon_colors),
          )
        ],
        backgroundColor: appbar_colors,
      ),
      body: Stack(
        alignment: Alignment.center,
        fit: StackFit.loose,
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
          Opacity(
            opacity: check ? opacity = 0.8 : opacity = 0.8,
            child: Image.asset("assets/⇨.png"),
          ),
          CustomPaint(
            painter: CenterLinePainter(),
            child: Container(),
          ),
          //横線に関するソースコード
          CustomPaint(
            painter: BottomLinePainter(),
            child: Container(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 1.5,
                    left: MediaQuery.of(context).size.height * 0.3),
                child: Transform.scale(
                  scale: 2,
                  child: FloatingActionButton(
                    onPressed: () async {
                      // 写真を撮る
                      final image = await _controller.takePicture();
                      //画像をローカルに保存
                      String imagePath = image.path; // XFile からファイルのパスを取得
                      await _saveImageToGallery(imagePath);

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OutBlazePage2(
                            imagePath: image.path,
                            camera: widget.camera,
                            path1: widget.path1,
                            offsets1: widget.offsets1,
                          ),
                        ),
                      );
                      // path を出力
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //画像をローカルに保存
  Future<void> _saveImageToGallery(String imagePath) async {
    // 画像を保存するファイル名を指定
    final fileName = "${OutTakePicture1State.id}-right.jpg";
    // 保存したい画像ファイルのパスとファイル名を指定して保存
    final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

    if (result != null) {
      print('画像がギャラリーアルバムに保存されました: $result');
    } else {
      print('画像の保存に失敗しました');
    }
  }
}

/// 写真撮影画面
class OutTakePicture3 extends StatefulWidget {
  const OutTakePicture3({
    Key? key,
    required this.camera,
    required this.path1,
    required this.path2,
    required this.offsets1,
    required this.offsets2,
  }) : super(key: key);

  final CameraDescription camera;
  final String path1;
  final String path2;
  final List<Offset> offsets1;
  final List<Offset> offsets2;

  @override
  OutTakePicture3State createState() => OutTakePicture3State();
}

class OutTakePicture3State extends State<OutTakePicture3> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int tmp = 0;
  int count = 0;
  final _audio = AudioCache();
  //色
  var appbar_colors = Colors.white;
  var appbar_text_colors = Colors.black;
  var main_colors = Colors.black;
  var sub_colors = Colors.black;
  var main_text_colors = Colors.white;
  var sub_text_colors = Colors.white;
  var icon_colors = Colors.black;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      // カメラを指定
      widget.camera,
      // 解像度を定義
      ResolutionPreset.medium,
    );

    // コントローラーを初期化
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    if (count == 0) {
      _audio.play('migi.mp3');
      count++;
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('⇦を向いてください', style: TextStyle(color: appbar_text_colors)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
            },
            icon: Icon(Icons.home, color: icon_colors),
          )
        ],
        backgroundColor: appbar_colors,
      ),
      body: Stack(
        alignment: Alignment.center,
        fit: StackFit.loose,
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
          Opacity(
            opacity: check ? opacity = 0.8 : opacity = 0.8,
            child: Image.asset("assets/⇦.png"),
          ),
          CustomPaint(
            painter: CenterLinePainter(),
            child: Container(),
          ),
          //横線に関するソースコード
          CustomPaint(
            painter: BottomLinePainter(),
            child: Container(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 1.5,
                    left: MediaQuery.of(context).size.height * 0.3),
                child: Transform.scale(
                  scale: 2,
                  child: FloatingActionButton(
                    onPressed: () async {
                      // 写真を撮る
                      final image = await _controller.takePicture();
                      //画像をローカルに保存
                      String imagePath = image.path; // XFile からファイルのパスを取得
                      await _saveImageToGallery(imagePath);

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OutBlazePage3(
                            imagePath: image.path,
                            camera: widget.camera,
                            path1: widget.path1,
                            path2: widget.path2,
                            offsets1: widget.offsets1,
                            offsets2: widget.offsets2,
                          ),
                        ),
                      );
                      // path を出力
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //画像をローカルに保存
  Future<void> _saveImageToGallery(String imagePath) async {
    // 画像を保存するファイル名を指定
    final fileName = "${OutTakePicture1State.id}-left.jpg";
    // 保存したい画像ファイルのパスとファイル名を指定して保存
    final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

    if (result != null) {
      print('画像がギャラリーアルバムに保存されました: $result');
    } else {
      print('画像の保存に失敗しました');
    }
  }
}