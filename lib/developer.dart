import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gazou/manual.dart';
// import 'package:quiver/async.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gazou/improve.dart';
import 'package:gazou/test.dart';
import 'package:gazou/hand20.dart';
import 'package:gazou/landmark.dart';

class Developer extends StatefulWidget {
  const Developer({Key? key, required this.camera,required this.title}) : super(key: key);

  final String title;
  final CameraDescription camera;
  
  @override
  State<Developer> createState() => _DeveloperState();
}

class _DeveloperState extends State<Developer> {
  final _audio = AudioCache();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:  AppBar(centerTitle: true,title:  Text(widget.title,style:TextStyle(color: Colors.black)),
        backgroundColor: Color.fromARGB(255, 174, 168, 167)),
        body:  Stack(
          children: <Widget>[
            // SizedBox(
            //   width: double.infinity,
            //   child: Image.asset("assets/dakko3.jpg"),),
            Column(
          children: <Widget>[
            // Container(
            //   padding: EdgeInsets.only(top: 32),
            //   child: Text('選択してください',style: TextStyle(fontSize: 30),),
            // ),
           
           SizedBox(height: 16,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // ElevatedButton(
                //   onPressed: () {
                //   },
                //   style: ElevatedButton.styleFrom(
                //     primary: Color.fromARGB(255, 214, 204, 203),
                //     elevation: 26,
                //   ),
                //   child: Text('基本情報入力',style: TextStyle(fontSize: 20,color: Colors.black)),
                // ),
                // ElevatedButton(
                //   onPressed: _opneUrl,
                //   style: ElevatedButton.styleFrom(
                //     primary: Color.fromARGB(255, 214, 204, 203),
                //     elevation: 26,
                //   ),
                //   child: Text('アンケート入力',style: TextStyle(fontSize: 20,color: Colors.black)),
                // ),
                
              ],
            ),
            //隠しボタン
            Row(
              children: <Widget>[
                Padding(padding: EdgeInsets.only(left: 80),
              child: ElevatedButton(
                  onPressed: (){
                    _audio.play('akatyankoe.mp3');
                  },
                  style: ElevatedButton.styleFrom(
               primary: Colors.transparent,
                elevation: 0,
                  ),
                  child: Text('     ',style: TextStyle(fontSize: 50,color: Colors.black)),
                ),
                ),
              ]
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(padding: EdgeInsets.only(top: 5,right: 10),
              child: ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManualPage(title:widget.title,camera:widget.camera),
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    fixedSize:const Size(150,150),
                    backgroundColor: Colors.orange,
                    elevation: 16,
                  ),
                  child: Text('姿勢\n評価',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 40,color: Colors.white)),
                ),
                ),
               ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Improve()
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(fixedSize:const Size(100,100),
                    primary: Color.fromARGB(255, 214, 160, 255),
                    elevation: 16,
                  ),
                  child: Text('修正を行う',style: TextStyle(fontSize: 40,color: Colors.black)),
                ), 
              Padding(padding: EdgeInsets.only(top: 25,left: 0),
               child: ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HandexpPage()
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    fixedSize:const Size(18,150),
                    backgroundColor: Colors.green,
                    elevation: 1,
                  ),
                  child: Text('腱鞘炎\nチェック',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 35,color: Colors.white),textAlign: TextAlign.center,),
                ), 
              ),
                ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BlazePage()
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 214, 160, 255),
                    elevation: 16,
                  ),
                  child: Text('test',style: TextStyle(fontSize: 20,color: Colors.black)),
                ),   
              
              ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Landmark(camera: widget.camera)
              )
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    fixedSize:const Size(180,150),
                    backgroundColor: Colors.green,
                    elevation: 16,
                  ),
                  child: Text('landmark',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 35,color: Colors.white),textAlign: TextAlign.center,),
                ),            

              ],
            ),
          ],
        ),
            // ElevatedButton(
            //   onPressed: () { /* ボタンがタップされた時の処理 */ },
            //   child: Text('基本情報の登録',style:TextStyle(color: Colors.black)),
              
            //   )
          ],
        )
    );
  }
   void _opneUrl() async {
    final url = Uri.parse('https://docs.google.com/forms/d/168uxibsGbr7ciBM2FsLRksgxEMEkJ_TzCcePeq9n82s/edit?usp=sharing'); //←ここに表示させたいURLを入力する
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
      );
    } else {
      throw 'このURLにはアクセスできません';
    }
  }
}
