import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gazou/inget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gazou/outget.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'dart:async';

// inget に進む class
class JunbiINPage extends StatefulWidget {
  const JunbiINPage({Key? key, required this.camera, required this.title}) : super(key: key);

  final String title;
  final CameraDescription camera;

  @override
  State<JunbiINPage> createState() => _JunbiINPageState();
}

class _JunbiINPageState extends State<JunbiINPage> {
  final _audio = AudioCache();
  var appbar_colors = Colors.white;
  var appbar_text_colors = Colors.black;
  var main_colors = Colors.black;
  var sub_colors = Colors.black;
  var main_text_colors = Colors.white;
  var sub_text_colors = Colors.white;
  var icon_colors = Colors.black;
  double _angle = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    //_timer = Timer.periodic(Duration(seconds: 3), (Timer t) {
      //accelerometerEvents.listen((AccelerometerEvent event) {
        /*setState(() {
          double x = event.x;
          double y = event.y;
          double z = event.z;
          _angle = (math.atan2(z, math.sqrt(y * y + x * x)) * (180 / math.pi)).abs();
        });
      });
    });*/
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
            },
            icon: Icon(Icons.home, color: icon_colors),
          )
        ],
        title: Text('内カメラ', style: TextStyle(color: appbar_text_colors)),
        backgroundColor: appbar_colors,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Image.asset("assets/intejun.png"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final cameras = await availableCameras();
                    final firstCamera = cameras[1];
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("撮影手順は読みましたか？",style: TextStyle(fontSize: 17),),
                        content: const Text("撮影準備が開始されます",style: TextStyle(fontSize: 17),),
                        actions: [
                          GestureDetector(
                            child: Text("はい", style: TextStyle(fontSize: 30)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestScreen(camera: widget.camera),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: main_colors,
                    elevation: 30,
                  ),
                  child: Text('次へ', style: TextStyle(fontSize: 40, color: main_text_colors)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// manual.dart の82行目からここに移動
class JunbiOUTPage extends StatefulWidget {

  const JunbiOUTPage({Key? key, required this.camera,required this.title}) : super(key: key);
  final String title;
  final CameraDescription camera;
  
  @override
  State<JunbiOUTPage> createState() => _JunbiOUTPageState(); // 100行目に移動
}

class _JunbiOUTPageState extends State<JunbiOUTPage> {
  final _audio = AudioCache();
  //色の変更
  var appbar_colors = Colors.white;
  var appbar_text_colors = Colors.black;
  var main_colors = Colors.black;
  var sub_colors = Colors.black;
  var main_text_colors = Colors.white;
  var sub_text_colors = Colors.white;
  var icon_colors = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true,
          actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home,color: icon_colors,))],
          title: Text('外カメラ',style:TextStyle(color:appbar_text_colors)),
        backgroundColor: appbar_colors),
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
            Image.asset("assets/outtejun.png"),
    Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
      ElevatedButton(
        onPressed: ()async{
            final cameras = await availableCameras();
  // 利用可能なカメラのリストから特定のカメラを取得
            final firstCamera = cameras[0];
showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("準備はできましたか？",style: TextStyle(fontSize: 20),),
            content: const Text("撮影が開始されます",style: TextStyle(fontSize: 17),),
            actions: [
              GestureDetector(
                child: Text("はい",style: TextStyle(fontSize: 30),),
                onTap: (){
                  Navigator.push(context,
                      // outget.dart の OutTakePicture1 に移動
                      MaterialPageRoute(builder: (context) => OutTakePicture1(camera:firstCamera),
                      )
                  );
                },
              ),
              // GestureDetector(
              //   child: Text("いいえ",style: TextStyle(fontSize: 30),),
              //   onTap: (){
              //     Navigator.pop(context);
              //   },
              // ),
            ],
          ),
        );
          },
        style: ElevatedButton.styleFrom(
          backgroundColor: main_colors,
          elevation: 30,
          ),
          child:Text('次へ',style: TextStyle(fontSize: 40, color: main_text_colors)),
          ),
          ],
    ),
          ],
          ),
        ),
    );
  }
}