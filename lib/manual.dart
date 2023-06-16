import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gazou/inget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gazou/junbi.dart';


class ManualPage extends StatefulWidget {
  const ManualPage({Key? key, required this.camera,required this.title}) : super(key: key);

  final String title;
  final CameraDescription camera;
  
  @override
  State<ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> {
  final _audio = AudioCache();
  //色
  var appbar_colors = Colors.white;
  var appbar_text_colors = Colors.white;
  var main_colors = Colors.black;
  var sub_colors = Colors.black;
  var main_text_color = Colors.white;
  var sub_text_colors = Colors.white;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true,
          actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home))],
          title: Text('環境説明',style:TextStyle(color: appbar_colors )),
        backgroundColor: appbar_text_colors),
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
            Image.asset("assets/manual.png"),
            Text('どちらで行うか選択してください',style: TextStyle(fontSize: 22),),
    Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
      ElevatedButton(
        onPressed: (){
          Navigator.push(context, 
          MaterialPageRoute(builder: (context) => JunbiINPage(title: widget.title,camera:widget.camera),
          )
          );
          },
        style: ElevatedButton.styleFrom(
          backgroundColor: main_colors,
          elevation: 30,
          ),
                child: Text('内カメ',style: TextStyle(fontSize: 40, color: main_text_color)),
          ),
      ElevatedButton(
        onPressed: (){
          Navigator.push(context, 
          MaterialPageRoute(builder: (context) => JunbiOUTPage(title: widget.title,camera:widget.camera),
          )
          );
          },
        style: ElevatedButton.styleFrom(
          backgroundColor: main_colors,
          elevation: 30,
          ),
                child: Text('外カメ',style: TextStyle(fontSize: 40, color: main_text_color)),
          ),
          ],
    ),
          ],
          ),
        ),
    );
  }
}
