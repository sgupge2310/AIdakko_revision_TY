import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:gazou/main.dart';
import 'evaluation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gazou/inblaze.dart';
import 'package:quiver/async.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gazou/pause.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:math' as math;
import 'package:sensors/sensors.dart';

//撮影準備画面
class TestScreen extends StatefulWidget {
  final CameraDescription camera;

  const TestScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _angle = 0; // デバイスの傾きを保持する変数
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late DateTime _lastUpdate = DateTime.now();
  final _audio = AudioCache();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();

    //音声指示
    _audio.play('prepare.mp3');

    // 加速度計のデータを1秒ごとに監視し、角度を計算して更新する
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (DateTime.now().difference(_lastUpdate) > Duration(seconds: 1)) {
        _lastUpdate = DateTime.now();
        setState(() {
          _angle = _calculateAngle(event);
        });
      }
    });
  }

  // 加速度計から角度を計算する関数
  int _calculateAngle(AccelerometerEvent event) {
    double ax = event.x;
    double ay = event.y;
    double az = event.z;
    double norm = math.sqrt(ax * ax + ay * ay + az * az);
    double angle = (math.acos(az / norm) * 180.0 / math.pi) - 90.0;
    return angle.abs().round(); // 角度を整数に丸める
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription.cancel(); // リスナーの解除
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('撮影準備画面'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // カメラの初期化が完了したらカメラ画面を表示
            return Stack(
              children: <Widget>[
                CameraPreview(_controller),
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'デバイスの傾き: $_angle°',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '傾きを0°に近づけてください',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '【撮影推奨環境】\nカメラと被写体の距離：2m\nカメラと地面の距離　：1m',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          SizedBox(
            width: 160,
            height: 80,
            child: FloatingActionButton(
              onPressed: () async {
                try {
                  await _initializeControllerFuture;
                  // カメラが準備できたら TakePictureScreen に遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakePictureScreen(camera: widget.camera),
                    ),
                  );
                } catch (e) {
                  print('カメラの起動に失敗しました: $e');
                }
              },
              child: Text(
                '撮影開始',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

//get0
/// 写真撮影画面（junbi.dartからここに移動）
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState(); // 移動
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int _start = 10;
  int _current = 10;
  int tmp = 0;
  int count = 0;
  final _audio = AudioCache();

  // ③ カウントダウン処理を行う関数を定義
  Future <void> startTimer() async{
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: _start), //初期値
      new Duration(seconds: 1), // 減らす幅
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() {
        _current = _start - duration.elapsed.inSeconds; //毎秒減らしていく
      });
    });
    // ④終了時の処理
    sub.onDone(()async {
      final image = await _controller.takePicture();

      //画像をローカルに保存
      String imagePath = image.path; // XFile からファイルのパスを取得
      await _saveImageToGallery(imagePath);
      await Navigator.push(
                    context,
                    // inblaze.dart の BlazePage1 に移動
                    MaterialPageRoute(builder: (context) => BlazePage1(imagePath:image.path,camera:widget.camera),
              )
                    );
    });
  }
  //色
  var appbar_colors = Colors.white;
  var appbar_text_colors = Colors.black;
  var main_colors = Colors.black;
  var sub_colors = Colors.black;
  var main_text_colors = Colors.white;
  var sub_text_colors = Colors.white;
  var icon_colors = Colors.black;
  // ID定義（全ウィジェットで共有するため static を使用）
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
      _audio.play('zensin.mp3');
      startTimer();
      count++;
    }

    return Scaffold(
      appBar:  AppBar(centerTitle: true,title:  Text('正面を向いてください',style:TextStyle(color: appbar_text_colors)),
      actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home,color: icon_colors,))],
        backgroundColor: appbar_colors),
      body: Stack(
        alignment: Alignment.center,
        fit:StackFit.loose,
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
          Opacity(
            opacity: check ? opacity = 0.5 : opacity = 0.5,
            child: Container(
              alignment: Alignment.center,
              child: Text(
              "$_current",
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 300,
              color: Color.fromARGB(255, 50, 51, 51),
              ),
              ),
            ),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
                Padding(padding: const EdgeInsets.only(top:650,left: 30),
                child:ElevatedButton(
                  onPressed: (){
                    dispose();
                    Navigator.push(
                    context,
                    // pause.dart の Pause1Page に移動
                    MaterialPageRoute(builder: (context) => Pause1Page(title:"中断中",camera:widget.camera),
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: main_colors,
                    elevation: 16,
                  ),
                  child: Text('中断する',style: TextStyle(fontSize: 50,color: main_text_colors)),
                ),
                )
              ],
        ),
        ],
      ),
    );
  }

  //画像をローカルに保存
Future<void> _saveImageToGallery(String imagePath) async {
  // 画像を保存するファイル名を指定
  final fileName = "${id}-front.jpg";
  // 保存したい画像ファイルのパスとファイル名を指定して保存
  final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

  if (result != null) {
    print('画像がギャラリーアルバムに保存されました: $result');
  } else {
    print('画像の保存に失敗しました');
  }
}
}

//get1
/// 写真撮影画面（正面）
class TakePictureScreen1 extends StatefulWidget {
  const TakePictureScreen1({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreen1State createState() => TakePictureScreen1State();
}

class TakePictureScreen1State extends State<TakePictureScreen1> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int _start = 5;
  int _current = 5;
  int tmp = 0;
  int count = 0;
  final _audio = AudioCache();

  // ③ カウントダウン処理を行う関数を定義
  Future <void> startTimer() async{
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: _start), //初期値
      new Duration(seconds: 1), // 減らす幅
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() {
        _current = _start - duration.elapsed.inSeconds; //毎秒減らしていく
      });
    });
    // ④終了時の処理
    sub.onDone(()async {
      final image = await _controller.takePicture();
      //画像をローカルに保存
      String imagePath = image.path; // XFile からファイルのパスを取得
      await _saveImageToGallery(imagePath);
      await Navigator.push(
                    context,
                    // inblaze.dart の BlazePage1 に移動
                    MaterialPageRoute(builder: (context) => BlazePage1(imagePath:image.path,camera:widget.camera),
              )
                    );
    });
  }

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
      _audio.play('syoumen.mp3');
      startTimer();
      count++;
    }

    return Scaffold(
      appBar:  AppBar(centerTitle: true,title:  Text('正面を向いてください',style:TextStyle(color: appbar_text_colors)),
      actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home,color: icon_colors,))],
        backgroundColor: appbar_colors),
      body: Stack(
        alignment: Alignment.center,
        fit:StackFit.loose,
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
          Opacity(
            opacity: check ? opacity = 0.5 : opacity = 0.5,
            child: Container(
              alignment: Alignment.center,
              child: Text(
              "$_current",
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 300,
              color: Color.fromARGB(255, 50, 51, 51),
              ),
            ),
          ),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
                Padding(padding: const EdgeInsets.only(top:650,left: 30),
                child:ElevatedButton(
                  onPressed: (){
                    dispose();
                    Navigator.push(
                    context,
                        // pause.dart の Pause1Page に移動
                    MaterialPageRoute(builder: (context) => Pause1Page(title:"中断中",camera:widget.camera),
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: main_colors,
                    elevation: 16,
                  ),
                  child: Text('中断する',style: TextStyle(fontSize: 50,color: main_text_colors)),
                ),
                )
              ],
        ),
        ],
      ),
      
    );
  }
  //画像をローカルに保存
Future<void> _saveImageToGallery(String imagePath) async {
  // 画像を保存するファイル名を指定
  final fileName = "${TakePictureScreenState.id}-front.jpg";
  // 保存したい画像ファイルのパスとファイル名を指定して保存
  final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

  if (result != null) {
    print('画像がギャラリーアルバムに保存されました: $result');
  } else {
    print('画像の保存に失敗しました');
  }
}
}

/// 写真撮影画面（正面-やり直し）
class TakePictureScreen1p1 extends StatefulWidget {
  const TakePictureScreen1p1({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreen1p1State createState() => TakePictureScreen1p1State();
}

class TakePictureScreen1p1State extends State<TakePictureScreen1p1> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int _start = 10;
  int _current = 10;
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


  // ③ カウントダウン処理を行う関数を定義
  Future <void> startTimer() async{
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: _start), //初期値
      new Duration(seconds: 1), // 減らす幅
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() {
        _current = _start - duration.elapsed.inSeconds; //毎秒減らしていく
      });
    });
    // ④終了時の処理
    sub.onDone(()async {
      final image = await _controller.takePicture();
      //画像をローカルに保存
      String imagePath = image.path; // XFile からファイルのパスを取得
      await _saveImageToGallery(imagePath);
      await Navigator.push(
                    context,
                    // inblaze.dart の BlazePage1 に移動
                    MaterialPageRoute(builder: (context) => BlazePage1(imagePath:image.path,camera:widget.camera),
              )
                    );
    });
  }


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
      _audio.play('syoumen.mp3');
      startTimer();
      count++;
    }
    return Scaffold(
      appBar:  AppBar(centerTitle: true,title:  Text('正面を向いてください',style:TextStyle(color: appbar_text_colors)),
      actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home,color: icon_colors,))],
        backgroundColor: appbar_colors),
      body: Stack(
        alignment: Alignment.center,
        fit:StackFit.loose,
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
          Opacity(
            opacity: check ? opacity = 0.5 : opacity = 0.5,
            child: Container(
              alignment: Alignment.center,
              child: Text(
              "$_current",
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 300,
              color: Color.fromARGB(255, 50, 51, 51),
              ),
            ),
          ),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
                Padding(padding: const EdgeInsets.only(top:650,left: 30),
                child:ElevatedButton(
                  onPressed: (){
                    dispose();
                    Navigator.push(
                    context,
                        // pause.dart の Pause1Page に移動
                    MaterialPageRoute(builder: (context) => Pause1Page(title:"中断中",camera:widget.camera),
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: main_colors,
                    elevation: 16,
                  ),
                  child:Text('中断する',style: TextStyle(fontSize: 50,color: main_text_colors)),
                ),
                )
              ],
        ),
        ],
      ),
      
    );
  }
//画像をローカルに保存
Future<void> _saveImageToGallery(String imagePath) async {
  // 画像を保存するファイル名を指定
  final fileName = "${TakePictureScreenState.id}-front.jpg";
  // 保存したい画像ファイルのパスとファイル名を指定して保存
  final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

  if (result != null) {
    print('画像がギャラリーアルバムに保存されました: $result');
  } else {
    print('画像の保存に失敗しました');
  }
}
}

//get2
/// 写真撮影画面（左側）
class TakePictureScreen2 extends StatefulWidget {
  const TakePictureScreen2({
    Key? key,
    required this.camera,
    required this.path1,
    required this.offsets1,
  }) : super(key: key);

  final CameraDescription camera;
  final String path1;
  final List<Offset> offsets1;

  @override
  TakePictureScreen2State createState() => TakePictureScreen2State();
}

class TakePictureScreen2State extends State<TakePictureScreen2> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int _start = 5;
  int _current = 5;
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

  // ③ カウントダウン処理を行う関数を定義
  Future <void> startTimer() async{
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: _start), //初期値
      new Duration(seconds: 1), // 減らす幅
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() {
        _current = _start - duration.elapsed.inSeconds; //毎秒減らしていく
      });
    });
    // ④終了時の処理
    sub.onDone(()async {
      final image = await _controller.takePicture();
      //画像をローカルに保存
      String imagePath = image.path; // XFile からファイルのパスを取得
      await _saveImageToGallery(imagePath);
      await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BlazePage2(imagePath:image.path,camera:widget.camera,path1: widget.path1,offsets1: widget.offsets1,),
              )
                    );
    });
  }


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
      startTimer();
      count++;
    }
    return Scaffold(
      appBar:  AppBar(centerTitle: true,title:  Text('⇦を向いてください',style:TextStyle(color: appbar_text_colors)),
      actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home,color: icon_colors,))],
        backgroundColor: appbar_colors),
      body: Stack(
        alignment: Alignment.center,
        fit:StackFit.loose,
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
          Opacity(
            opacity: check ? opacity = 0.5 : opacity = 0.5,
            child: Container(
              alignment: Alignment.center,
              child: Text(
              "$_current",
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 300,
              color: Color.fromARGB(255, 50, 51, 51),
              ),
            ),
          ),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
                Padding(padding: const EdgeInsets.only(top:650,left: 30),
                child:ElevatedButton(
                  onPressed: (){
                    dispose();
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Pause2Page(title:"中断中",camera:widget.camera,path1:widget.path1, offsets1: widget.offsets1,),
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: main_colors,
                    elevation: 16,
                  ),
                  child:Text('中断する',style: TextStyle(fontSize: 50,color: main_text_colors)),
                ),
                )
              ],
        ),
        ],
      ),
      
    );
  }
//画像をローカルに保存
Future<void> _saveImageToGallery(String imagePath) async {
  // 画像を保存するファイル名を指定
  final fileName = "${TakePictureScreenState.id}-right.jpg";
  // 保存したい画像ファイルのパスとファイル名を指定して保存
  final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

  if (result != null) {
    print('画像がギャラリーアルバムに保存されました: $result');
  } else {
    print('画像の保存に失敗しました');
  }
}
}

/// 写真撮影画面（左側-やり直し）
class TakePictureScreen2p2 extends StatefulWidget {
  const TakePictureScreen2p2({
    Key? key,
    required this.camera,
    required this.path1,
    required this.offsets1,
  }) : super(key: key);

  final CameraDescription camera;
  final String path1;
  final List<Offset> offsets1;


  @override
  TakePictureScreen2p2State createState() => TakePictureScreen2p2State();
}

class TakePictureScreen2p2State extends State<TakePictureScreen2p2> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int _start = 10;
  int _current = 10;
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

  // ③ カウントダウン処理を行う関数を定義
  Future <void> startTimer() async{
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: _start), //初期値
      new Duration(seconds: 1), // 減らす幅
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() {
        _current = _start - duration.elapsed.inSeconds; //毎秒減らしていく
      });
    });
    // ④終了時の処理
    sub.onDone(()async {
      final image = await _controller.takePicture();
      //画像をローカルに保存
      String imagePath = image.path; // XFile からファイルのパスを取得
      await _saveImageToGallery(imagePath);
      await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BlazePage2(imagePath:image.path,camera:widget.camera,path1: widget.path1,offsets1: widget.offsets1,),
              )
                    );
    });
  }


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
      startTimer();
      count++;
    }
    return Scaffold(
      appBar:  AppBar(centerTitle: true,title:  Text('⇦を向いてください',style:TextStyle(color: appbar_text_colors)),
      actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home,color: icon_colors,))],
        backgroundColor: appbar_colors),
      body: Stack(
        alignment: Alignment.center,
        fit:StackFit.loose,
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
          Opacity(
            opacity: check ? opacity = 0.5 : opacity = 0.5,
            child: Container(
              alignment: Alignment.center,
              child: Text(
              "$_current",
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 300,
              color: Color.fromARGB(255, 50, 51, 51),
              ),
            ),
          ),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
                Padding(padding: const EdgeInsets.only(top:650,left: 30),
                child:ElevatedButton(
                  onPressed: (){
                    dispose();
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Pause2Page(title:"中断中",camera:widget.camera,path1:widget.path1,offsets1: widget.offsets1,),
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: main_colors,
                    elevation: 16,
                  ),
                  child:Text('中断する',style: TextStyle(fontSize: 50,color: main_text_colors)),
                ),
                )
              ],
        ),
        ],
      ),
      
    );
  }
//画像をローカルに保存
Future<void> _saveImageToGallery(String imagePath) async {
  // 画像を保存するファイル名を指定
  final fileName = "${TakePictureScreenState.id}-right.jpg";
  // 保存したい画像ファイルのパスとファイル名を指定して保存
  final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

  if (result != null) {
    print('画像がギャラリーアルバムに保存されました: $result');
  } else {
    print('画像の保存に失敗しました');
  }
}
}

//get3
/// 写真撮影画面（右側）
class TakePictureScreen3 extends StatefulWidget {
  const TakePictureScreen3({
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
  TakePictureScreen3State createState() => TakePictureScreen3State();
}

class TakePictureScreen3State extends State<TakePictureScreen3> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int _start = 8;
  int _current = 8;
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

  // ③ カウントダウン処理を行う関数を定義
  Future <void> startTimer() async{
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: _start), //初期値
      new Duration(seconds: 1), // 減らす幅
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() {
        _current = _start - duration.elapsed.inSeconds; //毎秒減らしていく
      });
    });
    // ④終了時の処理
    sub.onDone(()async {
      final image = await _controller.takePicture();
      //画像をローカルに保存
      String imagePath = image.path; // XFile からファイルのパスを取得
      await _saveImageToGallery(imagePath);
      await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BlazePage3(imagePath:image.path,camera:widget.camera,path1:widget.path1,path2:widget.path2,offsets1: widget.offsets1,offsets2: widget.offsets2,),
              )
                    );
    });
  }


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
      startTimer();
      count++;
    }
    return Scaffold(
      appBar:  AppBar(centerTitle: true,title:  Text('⇨を向いてください',style:TextStyle(color: appbar_text_colors)),
      actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home,color: icon_colors,))],
        backgroundColor: appbar_colors),
      body: Stack(
        alignment: Alignment.center,
        fit:StackFit.loose,
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
          Opacity(
            opacity: check ? opacity = 0.5 : opacity = 0.5,
            child: Container(
              alignment: Alignment.center,
              child: Text(
              "$_current",
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 300,
              color: Color.fromARGB(255, 50, 51, 51),
              ),
            ),
          ),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
                Padding(padding: const EdgeInsets.only(top:650,left: 30),
                child:ElevatedButton(
                  onPressed: (){
                    dispose();
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Pause3Page(title:"中断中",camera:widget.camera,path1:widget.path1,path2:widget.path2,offsets1: widget.offsets1,offsets2: widget.offsets2,),
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: main_colors,
                    elevation: 16,
                  ),
                  child:Text('中断する',style: TextStyle(fontSize: 50,color: main_text_colors)),
                ),
                )
              ],
        ),
        ],
      ),
      
    );
  }
//画像をローカルに保存
Future<void> _saveImageToGallery(String imagePath) async {
  // 画像を保存するファイル名を指定
  final fileName = "${TakePictureScreenState.id}-left.jpg";
  // 保存したい画像ファイルのパスとファイル名を指定して保存
  final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

  if (result != null) {
    print('画像がギャラリーアルバムに保存されました: $result');
  } else {
    print('画像の保存に失敗しました');
  }
}
}

/// 写真撮影画面（右側-やり直し）
class TakePictureScreen3p3 extends StatefulWidget {
  const TakePictureScreen3p3({
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
  TakePictureScreen3p3State createState() => TakePictureScreen3p3State();
}

class TakePictureScreen3p3State extends State<TakePictureScreen3p3> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool check = true;
  double opacity = 0.5;
  int _start = 10;
  int _current = 10;
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


  // ③ カウントダウン処理を行う関数を定義
  Future <void> startTimer() async{
    CountdownTimer countDownTimer = new CountdownTimer(
      new Duration(seconds: _start), //初期値
      new Duration(seconds: 1), // 減らす幅
    );

    var sub = countDownTimer.listen(null);
    sub.onData((duration) {
      setState(() {
        _current = _start - duration.elapsed.inSeconds; //毎秒減らしていく
      });
    });
    // ④終了時の処理
    sub.onDone(()async {
      final image = await _controller.takePicture();
      //画像をローカルに保存
      String imagePath = image.path; // XFile からファイルのパスを取得
      await _saveImageToGallery(imagePath);
      await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BlazePage3(imagePath:image.path,camera:widget.camera,path1:widget.path1,path2:widget.path2,offsets1: widget.offsets1,offsets2: widget.offsets2,),
              )
                    );
    });
  }


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
      startTimer();
      count++;
    }
    return Scaffold(
      appBar:  AppBar(centerTitle: true,title:  Text('⇨を向いてください',style:TextStyle(color: appbar_text_colors)),
      actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home,color: icon_colors,))],
        backgroundColor: appbar_colors),
      body: Stack(
        alignment: Alignment.center,
        fit:StackFit.loose,
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
          Opacity(
            opacity: check ? opacity = 0.5 : opacity = 0.5,
            child: Container(
              alignment: Alignment.center,
              child: Text(
              "$_current",
              style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 300,
              color: Color.fromARGB(255, 50, 51, 51),
              ),
            ),
          ),
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
                Padding(padding: const EdgeInsets.only(top:650,left: 30),
                child:ElevatedButton(
                  onPressed: (){
                    dispose();
                    Navigator.push(
                    context,

                    MaterialPageRoute(builder: (context) => Pause3Page(title:"中断中",camera:widget.camera,path1:widget.path1,path2:widget.path2,offsets1: widget.offsets1,offsets2: widget.offsets2,),
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: main_colors,
                    elevation: 16,
                  ),
                  child: Text('中断する',style: TextStyle(fontSize: 50,color: main_text_colors)),
                ),
                )
              ],
        ),
        ],
      ),
      
    );
  }

//画像をローカルに保存
Future<void> _saveImageToGallery(String imagePath) async {
  // 画像を保存するファイル名を指定
  final fileName = "${TakePictureScreenState.id}-left.jpg";
  // 保存したい画像ファイルのパスとファイル名を指定して保存
  final result = await ImageGallerySaver.saveFile(imagePath, name: fileName);

  if (result != null) {
    print('画像がギャラリーアルバムに保存されました: $result');
  } else {
    print('画像の保存に失敗しました');
  }
}
}

