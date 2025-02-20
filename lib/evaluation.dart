import 'package:firebase_core/firebase_core.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gazou/hand20.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:auto_size_text/auto_size_text.dart';
// idの共有のため（結果画像 id-result.jpg を作る際に必要）
import 'inget.dart';
import 'outget.dart';

//評価結果を返す
class Evaluation extends StatefulWidget {
 Evaluation({Key? key,required this.path1, required this.path2, required this.path3,required this.offsets1,required this.offsets2,required this.offsets3,required this.inoutcamera})
      : super(key: key);
  final String path1;
  final String path2;
  final String path3;
  final List<Offset> offsets1;
  final List<Offset> offsets2;
  final List<Offset> offsets3;
  // final _audio = AudioCache();
  String inoutcamera;

 @override
  State<Evaluation> createState() => _EvaluationState();
}

//firebase (現在はほぼ使用していない)
Future<void> uploadImage(String front,String left,String right,List<Offset> frontoffset,List<Offset> leftoffset,List<Offset> rightoffset) async {

  // 現在の日付を取得
    DateTime now = DateTime.now();

    // 年、月、日を取得
    String year = now.year.toString();
    String month = now.month.toString();
    String day = now.day.toString();
    String today = year + month + day;

    // id設定
    // var id = DateTime.now().millisecondsSinceEpoch;
    var truncatedId = DateTime.now().millisecondsSinceEpoch;
    var id = truncatedId.toInt();


    try {
    File file = File(front);

    Reference storageReference = FirebaseStorage.instance.ref().child('dakko/$today/$id/image/$id-front.jpg');

    UploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.whenComplete(() => print('画像のアップロードが完了しました'));

    // String imageUrl = await storageReference.getDownloadURL();
    // print('画像のURL: $imageUrl');
  } catch (e) {
    print('エラー: $e');
  }
  try {
    File file = File(left);

    Reference storageReference = FirebaseStorage.instance.ref().child('dakko/$today/$id/image/$id-left.jpg');

    UploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.whenComplete(() => print('画像のアップロードが完了しました'));

    // String imageUrl = await storageReference.getDownloadURL();
    // print('画像のURL: $imageUrl');
  } catch (e) {
    print('エラー: $e');
  }
  try {
    File file = File(right);

    Reference storageReference = FirebaseStorage.instance.ref().child('dakko/$today/$id/image/$id-right.jpg');

    UploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.whenComplete(() => print('画像のアップロードが完了しました'));

    // String imageUrl = await storageReference.getDownloadURL();
    // print('画像のURL: $imageUrl');
  } catch (e) {
    print('エラー: $e');
  }
  try {
  // OffsetデータをMapに変換
  List<Map<String, double>> offsetList = frontoffset
      .map((offset) => {'dx': offset.dx, 'dy': offset.dy})
      .toList();

  // MapデータをJSONに変換
  String jsonOffsets = json.encode(offsetList);

  // JSONデータをUTF-8エンコードしてバイトデータに変換
  Uint8List uint8List = Uint8List.fromList(utf8.encode(jsonOffsets));

  // Firebase Storageにアップロードする処理
  Reference storageReference = FirebaseStorage.instance.ref().child('dakko/$today/$id/json/$id-front.json');
  UploadTask uploadTask = storageReference.putData(uint8List);

  await uploadTask.whenComplete(() => print('データのアップロードが完了しました'));
} catch (e) {
  print('エラー: $e');
}
  try {
  // OffsetデータをMapに変換
  List<Map<String, double>> offsetList = leftoffset
      .map((offset) => {'dx': offset.dx, 'dy': offset.dy})
      .toList();

  // MapデータをJSONに変換
  String jsonOffsets = json.encode(offsetList);

  // JSONデータをUTF-8エンコードしてバイトデータに変換
  Uint8List uint8List = Uint8List.fromList(utf8.encode(jsonOffsets));

  // Firebase Storageにアップロードする処理
  Reference storageReference = FirebaseStorage.instance.ref().child('dakko/$today/$id/json/$id-left.json');
  UploadTask uploadTask = storageReference.putData(uint8List);

  await uploadTask.whenComplete(() => print('データのアップロードが完了しました'));
} catch (e) {
  print('エラー: $e');
}
  try {
  // OffsetデータをMapに変換
  List<Map<String, double>> offsetList = rightoffset
      .map((offset) => {'dx': offset.dx, 'dy': offset.dy})
      .toList();

  // MapデータをJSONに変換
  String jsonOffsets = json.encode(offsetList);

  // JSONデータをUTF-8エンコードしてバイトデータに変換
  Uint8List uint8List = Uint8List.fromList(utf8.encode(jsonOffsets));

  // Firebase Storageにアップロードする処理
  Reference storageReference = FirebaseStorage.instance.ref().child('dakko/$today/$id/json/$id-right.json');
  UploadTask uploadTask = storageReference.putData(uint8List);

  await uploadTask.whenComplete(() => print('データのアップロードが完了しました'));
} catch (e) {
  print('エラー: $e');
}
}
// ここまで firebase のコード

//5項目の計算用関数
class _EvaluationState extends State<Evaluation> {
  String kendall = "評価結果を出す";
  String score = "姿勢スコア：計算中";
  String imagefront = "";
  String imageside = "";
  String advice = "";
  String badpoint = "";
  String text = "";
  String image = "";
  int count = 0;
  String aaa = "";
  String dir = "front";
  String button = "score";
  List<String> summraize= [];
  List<Offset> offset = [];
  String imagescore = "assets/imagescore.png";
  String kendall_text = "";
  bool tf = true;
  bool badtf = false;
  bool texttf = true;
  bool advicetf = false;
  bool isVisible = true;

  List<String> badtxt= [];
  List<String> advicetxt= [];

  Uint8List? bytes;
  final globalKeyfront = GlobalKey();
  final globalKeyside = GlobalKey();
  
  
  //色
  var downcolor_1 = Colors.grey;
  var downcolor_2 = Colors.grey;
  var downcolor_3 = Colors.grey;
  var upcolor_1 = Colors.grey;
  var upcolor_2 = Colors.grey;
  var upcolor_3 = Colors.grey;
  //色
  var appbar_colors = Colors.white;
  var appbar_text_colors = Colors.black;
  var main_colors = Colors.black;
  var sub_colors = Colors.black;
  var main_text_colors = Colors.white;
  var sub_text_colors = Colors.white;
  var icon_colors = Colors.black;


  List<Offset> _adjust_front(List<Offset> landmarkfront){
  List<Offset> landmarkfront = widget.offsets1;
  List<Offset> landmarks = [];
  //正面
  if(landmarkfront.length!=9){
    landmarks.add(landmarkfront[0]); //鼻
    landmarks.add(landmarkfront[11]); //左肩
    landmarks.add(landmarkfront[12]); //右肩
    landmarks.add(landmarkfront[13]); //左ひじ
    landmarks.add(landmarkfront[14]); //右ひじ
    landmarks.add(landmarkfront[15]); //左手首
    landmarks.add(landmarkfront[16]); //右手首
    landmarks.add(landmarkfront[23]); //左腰(left_hip)
    landmarks.add(landmarkfront[24]); //右腰(right_hip)
    //戻す
    landmarkfront = landmarks;
  }
  return landmarkfront;
}
  //右調整
  List<Offset> _adjust_right(List<Offset> landmarkright){
    List<Offset> landmarkright = widget.offsets2;
    List<Offset> landmarks = [];
    landmarks = [];
    if(landmarkright.length!=7){
      landmarks.add(landmarkright[0]);
      landmarks.add(landmarkright[12]);
      landmarks.add(landmarkright[14]);
      landmarks.add(landmarkright[16]);
      landmarks.add(landmarkright[24]);
      landmarks.add(landmarkright[26]);
      landmarks.add(landmarkright[28]);
      //戻す
      landmarkright = landmarks;
    }
    return landmarkright;
}
  //左調整
  List<Offset> _adjust_left(List<Offset> landmarkleft){
  List<Offset> landmarkleft = widget.offsets3;
  List<Offset> landmarks = [];
  landmarks = [];
  if(landmarkleft.length!=7){
    landmarks.add(landmarkleft[0]);
    landmarks.add(landmarkleft[11]);
    landmarks.add(landmarkleft[13]);
    landmarks.add(landmarkleft[15]);
    landmarks.add(landmarkleft[23]);
    landmarks.add(landmarkleft[25]);
    landmarks.add(landmarkleft[27]);
    //戻す
    landmarkleft = landmarks;
  }
  return landmarkleft;
}

  //Rightの特徴点を用いてケンダルを計算する
  List<double> _kendall_classification(){
    List<Offset>landmarkright = [];
    List<double>kendalllist = [];
    //調整済み座標持ってきてる
    landmarkright = _adjust_right(landmarkright);
    //メモ
    // List<String> landmarkfront = [0"Nose",1"Left_eye",2"Right_eye",3"Left_mouth",4"Right_mouth",5"Left_shoulder",6"Right_shoulder",
    //                           7"Left_elbow",8"Right_elbow",9"Left_wrist",10"Right_wrist",11"Left_hip",12"Right_hip"];
    // List<String> landmarkright = [0"Nose",1"Right_shoulder",2"Right_elbow",3"Right_wrist",4"Right_hip",5"Right_knee",6"Right_ankle"];
    // List<String> landmarkleft = [0"Nose",1"Left_shoulder",2"Left_elbow",3"Left_wrist",4"Left_hip",5"Left_knee",6"Left_ankle"];

    //ケンダル分類
    String kendall = "";
    double ankle_knee = 0;
    double ankle_hip = 0;
    double ankle_shoulder = 0;

    //ankle_knee 数字が大きい方で引いてるから最後に-1をかけていい感じにしてる
    var tmp1 = landmarkright[5] - landmarkright[6];
    ankle_knee = atan(tmp1.dy/tmp1.dx)*180/pi;
    if(ankle_knee>0){
      ankle_knee = (90 - ankle_knee)*-1;
    }
    else{
      ankle_knee = (-90 + ankle_knee.abs())*-1;
    }

    //ankle_hip 
    var tmp2 = landmarkright[4] - landmarkright[6];
    //tmp1のyを使う
    ankle_hip = atan(tmp1.dy/tmp2.dx)*180/pi;
    if(ankle_hip>0){
      ankle_hip = (90 - ankle_hip)*-1;
    }
    else{
      ankle_hip = (-90 + ankle_hip.abs())*-1;
    }

    //ankle_shoulder
    var tmp3 = landmarkright[1] - landmarkright[6];
    //tmp1のyを使う
    ankle_shoulder = atan(tmp1.dy/tmp3.dx)*180/pi;
    if(ankle_shoulder>0){
      ankle_shoulder = (90 - ankle_shoulder)*-1;
    }
    else{
      ankle_shoulder = (-90 + ankle_shoulder.abs())*-1;
    }

    //下記はケンダル分類が抱っこ姿勢の分類に対応していなとのことで使用していない
    //ケンダル分類
    if(ankle_knee.abs()<10 && ankle_hip.abs()<10 && ankle_shoulder.abs()<10){
      kendall = "ノーマル";
    }
    else if(ankle_knee.abs()>10 && ankle_hip>10){
      kendall = "フラットバック";
    }
    else if(ankle_hip>10){
      kendall = "ロードシス";
    }
    else if(ankle_knee>10){
      kendall = "スウェイバック";
    }
    else if(ankle_knee<-10 && ankle_shoulder<-10){
      kendall = "カイホロードシス";
    }
    else {
      // kendall = "不明";
      kendall = "カイホロードシス";//とりあえず
    }

    kendalllist.add(0);
    kendalllist.add((ankle_knee).abs());
    kendalllist.add((ankle_hip).abs());
    kendalllist.add((ankle_shoulder).abs());

    return kendalllist;//0:何も入ってない,1:足首からankle_kneeの角度，2:足首からankle_hipの角度,3:足首からankle_shoulderの角度
}
  //Leftの特徴点を用いて膝・腰・肩の角度を計算する(今は左の姿勢は判断に使っていない)
  List<String> _leftpoint_classification(){
    List<Offset>landmarkleft = [];
    List<String>left_kendalllist = [];
    //調整済み座標持ってきてる
    landmarkleft = _adjust_left(landmarkleft);
    //メモ
    // List<String> landmarkfront = [0"Nose",1"Left_eye",2"Right_eye",3"Left_mouth",4"Right_mouth",5"Left_shoulder",6"Right_shoulder",
    //                           7"Left_elbow",8"Right_elbow",9"Left_wrist",10"Right_wrist",11"Left_hip",12"Right_hip"];
    // List<String> landmarkright = [0"Nose",1"Right_shoulder",2"Right_elbow",3"Right_wrist",4"Right_hip",5"Right_knee",6"Right_ankle"];
    // List<String> landmarkleft = [0"Nose",1"Left_shoulder",2"Left_elbow",3"Left_wrist",4"Left_hip",5"Left_knee",6"Left_ankle"];

    //ケンダル分類
    String kendall = "";
    double ankle_knee = 0;
    double ankle_hip = 0;
    double ankle_shoulder = 0;

    //ankle_knee 数字が大きい方で引いてるから最後に-1をかけていい感じにしてる
    var tmp1 = landmarkleft[5] - landmarkleft[6];
    ankle_knee = atan(tmp1.dy/tmp1.dx)*180/pi;
    if(ankle_knee>0){
      ankle_knee = (90 - ankle_knee)*-1;
    }
    else{
      ankle_knee = (-90 + ankle_knee.abs())*-1;
    }

    //ankle_hip
    var tmp2 = landmarkleft[4] - landmarkleft[6];
    //tmp1のyを使う
    ankle_hip = atan(tmp1.dy/tmp2.dx)*180/pi;
    if(ankle_hip>0){
      ankle_hip = (90 - ankle_hip)*-1;
    }
    else{
      ankle_hip = (-90 + ankle_hip.abs())*-1;
    }

    //ankle_shoulder
    var tmp3 = landmarkleft[1] - landmarkleft[6];
    //tmp1のyを使う
    ankle_shoulder = atan(tmp1.dy/tmp3.dx)*180/pi;
    if(ankle_shoulder>0){
      ankle_shoulder = (90 - ankle_shoulder)*-1;
    }
    else{
      ankle_shoulder = (-90 + ankle_shoulder.abs())*-1;
    }
    //ケンダル分類
    if(ankle_knee.abs()<10 && ankle_hip.abs()<10 && ankle_shoulder.abs()<10){
      kendall = "ノーマル";
    }
    else if(ankle_knee.abs()<10 && ankle_hip>10 && ankle_shoulder.abs()<10){
      kendall = "ロードシス";
    }
    else if(ankle_knee>10 && ankle_hip.abs()<10 && ankle_shoulder.abs()<10){
      kendall = "スウェイバック";
    }
    else if(ankle_knee<-10 && ankle_hip.abs()<10 && ankle_shoulder<-10){
      kendall = "カイホロードシス";
    }
    else if(ankle_knee.abs()>10 && ankle_hip>10 && ankle_shoulder.abs()<10){
      kendall = "フラットバック";
    }
    else {
      // kendall = "不明";
      kendall = "ノーマル";//とりあえず
    }

   
    left_kendalllist.add(kendall);
    left_kendalllist.add(ankle_knee.toString());
    left_kendalllist.add(ankle_hip.toString());
    left_kendalllist.add(ankle_shoulder.toString());

    return left_kendalllist;
  }
  //肩の平行具合を計算する
  double _ShoulderScore_calculation(){
    List<Offset>landmarkfront = [];
    //調整済み座標持ってきてる
    landmarkfront = _adjust_front(landmarkfront);

    double shoulder_angle = 0;
    double ShoulderScore = 0;
    var tmp1 = landmarkfront[2] - landmarkfront[1];
    shoulder_angle = (((atan(tmp1.dy / tmp1.dx)).abs())*180 / pi);

    ShoulderScore = shoulder_angle;
    return ShoulderScore;
  }
  //抱く高さの位置を計算する
  List<String> _Hugheight_calculation(){
    List<Offset>landmarkfront = [];
    List<String> hugheight = [];
    //調整済み座標持ってきてる
    landmarkfront = _adjust_front(landmarkfront);
    //それぞれの手首の高さ
    int back_hand = 0;
    int hip_hand = 0;
    double back_hand_rate = 0;
    double hip_hand_rate = 0;
    String isdir_hiphand = "";
    String isdir_backhand = "";
    if(landmarkfront[5].dy > landmarkfront[6].dy){
      // print("背中を支えている手首はLeft_wristです");
      back_hand = 6;
      hip_hand = 5;
      isdir_hiphand = "Left_wrist";
      isdir_backhand = "Right_wrist";
    }
    else{
      // print("背中を支えている手首はRight_wristです");
      back_hand = 5;
      hip_hand = 6;
      isdir_hiphand = "Right_wrist";
      isdir_backhand = "Left_wrist";
    }
    var hip_midpoint = (landmarkfront[7] + landmarkfront[8])/2;
    var sholder_midpoint = (landmarkfront[1] + landmarkfront[2])/2;
    back_hand_rate = (landmarkfront[back_hand].dy - hip_midpoint.dy)/(sholder_midpoint.dy - hip_midpoint.dy);
    hip_hand_rate = (landmarkfront[hip_hand].dy - hip_midpoint.dy)/(sholder_midpoint.dy - hip_midpoint.dy);
    //return hip_hand_rate.toString();
    hugheight.add(hip_hand_rate.toString());
    hugheight.add(back_hand_rate.toString());
    hugheight.add(isdir_hiphand);
    hugheight.add(isdir_backhand);

    return hugheight;
  }
  //脇の閉まり具合について
  double _ArmpitFit_calculation(){
    List<Offset>landmarkfront = [];
    //調整済み座標持ってきてる
    landmarkfront = _adjust_front(landmarkfront);

    //座標番号を入れる，初期値は0とする
    int hip_hand_shoulder = 0;
    int hip_hand_elbow = 0;
    //脇の閉まり具合に関する評価スコアをArmpitFitとする
    double ArmpitFit = 0;

    if(landmarkfront[5].dy > landmarkfront[6].dy){
      // print("背中を支えている手首はLeft_wristです");
      hip_hand_shoulder = 1;
      hip_hand_elbow = 3;
    }
    else{
      // print("背中を支えている手首はRight_wristです");
      hip_hand_shoulder = 2;
      hip_hand_elbow = 4;
    }
    ArmpitFit = (landmarkfront[hip_hand_shoulder].dy - landmarkfront[hip_hand_elbow].dy) / (landmarkfront[hip_hand_shoulder].dx - landmarkfront[hip_hand_elbow].dx);
    // print("脇の閉まり具合:"+ArmpitFit.toString());
    //print(ArmpitFit.abs);

    return ArmpitFit.abs();
  }

  //乳児の密着具合について
  double _Closeness_calculation(){
    List<Offset>landmarkfront = [];
    List<Offset>landmarkleft = [];
    List<Offset>landmarkright = [];
    //3方向の調整済み座標を呼び出す
    landmarkfront = _adjust_front(landmarkfront);
    landmarkleft = _adjust_left(landmarkleft);
    landmarkright = _adjust_right(landmarkright);
    //脇の閉まり具合に関する評価スコアをArmpitFitとする
    double Closeness = 0;
    var isdir_backhand = _Hugheight_calculation()[2];//Hugheightの2番目ががishiphand
    var point1;
    var point2;
    var point3;
    // print("aaaaa");
    // print(isdir_backhand);
    if(isdir_backhand=="Left_wrist"){//もし右側の特徴点座標を使うなら2を原点として，1と3がなす角度
      point1 = landmarkright[1];
      point2 = landmarkright[2];
      point3 = landmarkright[3];

    }
    else{//お尻を支える腕が右の時，右側の特徴点座標を参照
      point1 = landmarkleft[1];
      point2 = landmarkleft[2];
      point3 = landmarkleft[3];
    }
    //2つのベクトルのなす角度を計算
    double abX = point2.dx - point1.dx;
    double abY = point2.dy - point1.dy;
    double bcX = point3.dx - point2.dx;
    double bcY = point3.dy - point2.dy;
    double dotProduct = abX * bcX + abY * bcY;
    double magnitudeAB = sqrt(abX * abX + abY * abY);
    double magnitudeBC = sqrt(bcX * bcX + bcY * bcY);
    double cosTheta = dotProduct / (magnitudeAB * magnitudeBC);
    double angleInRadians = acos(cosTheta);
    // ラジアンを度に変換
    Closeness = angleInRadians * (180 / pi);
    Closeness = 180-Closeness;
    return Closeness.abs();//脇の閉まり具合に関する評価スコアを返す
  }
  //計算した値をリストでまとめて返す”さまらいず”
  //   [1.9385906915861866, 不明, 0.3848952710315345, 0.8713518732334877, Right_wrist,ankle_knee,ankle_hip,ankle_shoulder]
  //   [肩の平行具合、ケンダル、ヒップハンド、バックハンド、イズヒップハンド、膝までの角度(右)、腰までの角度(右)、肩までの角度(右)、膝までの角度(左)、腰までの角度(左)、肩までの角度(左)]
  List<String> _Summraize(){

    List<String> summraize = [];

    var ShoulderScore = _ShoulderScore_calculation();

    var Hugheight = _Hugheight_calculation();

    var right_kendalllist= _kendall_classification();

    var left_kendalllist = _leftpoint_classification();

    var ArmpitFit = _ArmpitFit_calculation();

    var Closeness = _Closeness_calculation();

    summraize.add(ShoulderScore.toString());//肩の平行具合
    summraize.add(right_kendalllist[0].toString());//ケンダル
    summraize.add(Hugheight[0].toString());//ヒップハンド
    summraize.add(Hugheight[1].toString());//バックハンド
    summraize.add(Hugheight[2].toString());//イズヒップハンド
    summraize.add(right_kendalllist[1].toString());//膝までの角度(右)
    summraize.add(right_kendalllist[2].toString());//腰までの角度(右)
    summraize.add(right_kendalllist[3].toString());//肩までの角度(右)
    summraize.add(left_kendalllist[1]);//膝までの角度(左)
    summraize.add(left_kendalllist[2]);//腰までの角度(左)
    summraize.add(left_kendalllist[3]);//肩までの角度(左)
    summraize.add(ArmpitFit.toString());//脇の閉まり具合
    summraize.add(Closeness.toString());//脇の閉まり具合

    // print("B1:"+summraize[7]);
    // print("B2:"+summraize[6]);
    // print("B3:"+summraize[5]);
    // print("A:"+summraize[0]);
    // print("R:"+summraize[2]);
    // print("脇の閉まり具合:"+summraize[11]);
    // print("密着具合:"+summraize[12]);
    return summraize;
  }
  //姿勢スコアを返す
  List<int> _score(){
    int sumscore = 0;
    List<int> scorelist = [];
    var ShoulderScore = _ShoulderScore_calculation();//肩のバランス
    var kendall = _kendall_classification()[1] + _kendall_classification()[2] + _kendall_classification()[3];//姿勢
    var Hugheight = _Hugheight_calculation();//抱っこの高さ
    var ArmPitFit = _ArmpitFit_calculation();//脇の開き
    var Closeness = _Closeness_calculation();//密着

    int shoulder_score = 0;
    int backbone_score = 0;
    int hugheight_score = 0;
    int armpitfit_score = 0;
    int closeness_score = 0;

//ここから閾値設定してます
    //姿勢の数値を出力しています．
    print("姿勢の数値"+kendall.toString());

    if(kendall <= 14.065){
      backbone_score = 19;
    }
    else if(14.065 < kendall && kendall <= 21.335){
      backbone_score = 15;
    }
    else if(21.335 < kendall && kendall <= 24.83){
      backbone_score = 10;
    }
    else if(24.83 < kendall && kendall <= 33.5){
      backbone_score = 5;
    }
    else if(33.5 < kendall){
      backbone_score = 0;
    }
    //確認用
    // print("姿勢の点数は"+backbone_score.toString());

    //抱っこの高さの数値化を出力しています
    print("抱っこの高さ"+double.parse(Hugheight[0]).toString());
    if(0.55 < double.parse(Hugheight[0])){
      hugheight_score = 20;
    }
    else if(0.485 < double.parse(Hugheight[0]) && double.parse(Hugheight[0]) <= 0.55){
      hugheight_score = 15;
    }
    else if(0.475 < double.parse(Hugheight[0]) && double.parse(Hugheight[0]) <= 0.485){
      hugheight_score = 10;
    }
    else if(0.425 > double.parse(Hugheight[0]) && double.parse(Hugheight[0]) <= 0.475){
      hugheight_score = 5;
    }
    else if(double.parse(Hugheight[0]) <= 0.425){
      hugheight_score = 0;
    }
    //確認用
    // print("抱っこの高さのスコアは"+hugheight_score.toString());

    //肩のバランスの数値化を出力しています
    print("肩のバランス"+ShoulderScore.toString());
    if(ShoulderScore <= 2.25){
      shoulder_score = 20;
    }
    else if(2.25 < ShoulderScore && ShoulderScore <= 3.0){
      shoulder_score = 15;
    }
    else if(3.0 < ShoulderScore && ShoulderScore <= 6.62){
      shoulder_score = 10;
    }
    else if(6.62 < ShoulderScore && ShoulderScore <= 9.24){
      shoulder_score = 5;
    }
    else if(9.24 < ShoulderScore){
      shoulder_score = 0;
    }
    //確認用
    // print("肩のバランスのスコアは"+shoulder_score.toString());

    //ArmPitFitは脇の開き具合の定量化した変数です．
    //以下で閾値を定めて5段階評価しています．
    if(4.19 < ArmPitFit){
      armpitfit_score = 20;
    }
    else if(1.625 < ArmPitFit && ArmPitFit <= 4.19){
      armpitfit_score = 15;
    }
    else if(1.315 < ArmPitFit && ArmPitFit <= 1.625){
      armpitfit_score = 10;
    }
    else if(1.11 < ArmPitFit && ArmPitFit <= 1.315){
      armpitfit_score = 5;
    }
    else if (ArmPitFit < 1.11){
      armpitfit_score = 0;
    }
    print("脇の開き具合"+ArmPitFit.toString());
    //確認用
    // print("脇の開き具合のスコアは"+armpitfit_score.toString());

    //Closenessは密着具合の定量化した変数です．
    //以下で閾値を定めて5段階評価しています．
    print("密着具合"+Closeness.toString());
    if(Closeness <= 58.38){
      closeness_score = 20;
    }
    else if(58.38 < Closeness && Closeness <= 86.5){

      closeness_score = 15;
    }
    else if(86.5 < Closeness && Closeness <= 144.5){
      closeness_score = 10;
    }
    else if(144.5 < Closeness && Closeness <= 148){
      closeness_score = 5;
    }
    else if(148 < Closeness){
      closeness_score += 0;
    }
    //確認用
    // print("密着具合のスコアは"+closeness_score.toString());

//ここまで変更

    sumscore = shoulder_score + backbone_score + hugheight_score + armpitfit_score + closeness_score;
    
    scorelist.add(sumscore);
    scorelist.add(shoulder_score);
    scorelist.add(backbone_score);
    scorelist.add(hugheight_score);
    scorelist.add(armpitfit_score);
    scorelist.add(closeness_score);

    return scorelist;
  }

  //badpointを返す
  List<String> _badpoint(){
    var summraize = _Summraize();
    var point = _triangular_chart();
    List<String> badpoint = [];
    String badtext = "";
    int badcount = 0;

    List<String> bad_kendall_list
    = ["",
      "耳たぶ,肩峰,股関節,膝,くるぶしの5点が床から一直線に並んでいるのが正しい姿勢です。",
      "骨盤が前傾し過ぎてしまい、反り腰になってしまっている状態です。",
      "頭が前に出て背中が丸まっている、いわゆる猫背の状態です。",
      "背中は猫背丸くで、腰は反っている、いわゆる反り腰の状態です。",
      "背骨のS字カーブが全体的に弱くなっている姿勢です。"];
    List<String> bad_hugheight_list
    = ["",
      "かなり低いです",
      "やや低いです",
      "適切です",];
    List<String> bad_shoulderbalance_list
    = ["",
      "とても差があります",
      "やや差があります",
      "まあバランスがとれています",
      "バランスがとれています",];

    //ケンダル分類指摘出力
    if(summraize[1] == "ノーマル"){
      badpoint.add(bad_kendall_list[0]+bad_kendall_list[1]);
    }
    if(summraize[1] == "ロードシス"){
      badpoint.add(bad_kendall_list[0]+bad_kendall_list[2]);
    }
    if(summraize[1] == "スウェイバック"){
      badpoint.add(bad_kendall_list[0]+bad_kendall_list[3]);
    }
    if(summraize[1] == "カイホロードシス"){
      badpoint.add(bad_kendall_list[0]+bad_kendall_list[4]);
    }
    if(summraize[1] == "フラットバック"){
      badpoint.add(bad_kendall_list[0]+bad_kendall_list[5]);
    }
    else{
    badpoint.add(bad_kendall_list[1]);
    }
    //抱っこの高さ指摘出力
    if(point[5]==3||point[5]==4){
      badpoint.add(bad_hugheight_list[0]+bad_hugheight_list[1]);
    }
    if(point[5]==1||point[5]==2){
      badpoint.add(bad_hugheight_list[0]+bad_hugheight_list[2]);
    }
    if(point[5]==0){
      badpoint.add(bad_hugheight_list[0]+bad_hugheight_list[3]);
    }
    //肩のバランスの指摘出力
    if(point[7]==3||point[7]==4){
      badpoint.add(bad_shoulderbalance_list[0]+bad_shoulderbalance_list[1]);
    }
    if(point[7]==2){
      badpoint.add(bad_shoulderbalance_list[0]+bad_shoulderbalance_list[2]);
    }
    if(point[7]==1){
      badpoint.add(bad_shoulderbalance_list[0]+bad_shoulderbalance_list[3]);
    }
    if(point[7]==0){
      badpoint.add(bad_shoulderbalance_list[0]+bad_shoulderbalance_list[4]);
    }

    for(var i in badpoint){
      if(badcount==0) {
        badtext += badpoint[badcount];
        badcount++;
      }
      else {
        badtext += "\n" + badpoint[badcount];
        badcount++;
      }
    }


    return badpoint;
  }
  //アドバイスを返す
  List<String> _advice(){
    var score = _score();//[0]sumscore [1]shoulder_score [2]backbone_score [3]hugheight_score [4]armpitfit_score [5]closeness_score;
    List<String> advicelist = [];
    int advicecount = 0;

    // ↓ 未使用
    var summraize = _Summraize();
    var point = _triangular_chart();
    String advice = "";

    // アプリで表示されるアドバイス
    List<String> advice_kendall_list
    = ["",
      "全ポイントで外れています。下腹をへこませ、耳たぶ,肩峰,股関節,膝,外くるぶしの5点が一直線に並ぶように抱っこしましょう。",
      "3ヵ所外れています。下腹をへこませ、耳たぶ,肩峰,股関節,膝,外くるぶしの5点が一直線に並ぶように抱っこしましょう。",
      "2ケ所外れています。下腹をへこませ、耳たぶ,肩峰,股関節,膝,外くるぶしの5点が一直線に並ぶように抱っこしましょう。",
      "1ヶ所外れています。下腹をへこませ、耳たぶ,肩峰,股関節,膝,外くるぶしの5点が一直線に並ぶように意識しましょう。",
      "耳たぶ,肩峰,股関節,膝,外くるぶしの5点が一直線に並ぶ理想的な姿勢です。",
    ];
    List<String> advice_hugheight_list
    = ["",
      "非常に低いため抱っこする人の肩に赤ちゃんの顔を乗せ、ほっぺにキスできる高さをこころがけましょう。",
      "かなり低いため抱っこする人の肩に赤ちゃんの顔を乗せ、ほっぺにキスできる高さをこころがけましょう。",
      "やや低いため抱っこする人の肩に赤ちゃんの顔を乗せ、ほっぺにキスできる高さをこころがけましょう。",
      "ほぼ適切です。抱っこする人の肩に赤ちゃんの顔を乗せ、ほっぺにキスできる高さをこころがけましょう。",
      "適切です。",
    ];
    List<String> advice_shoulderbalance_list
    = ["",
      "バランスが非常に崩れています。背筋を伸ばし、肩の力を抜き体全体で抱っこしましょう。",
      "バランスが崩れています。背筋を伸ばし、肩の力を抜き体全体で抱っこしましょう。",
      "バランスにやや差があります。背筋を伸ばし、肩の力を抜き体全体で抱きましょう。",
      "バランスはほぼとれています。腕や肩の力を抜きましょう。",
      "バランスが非常に取れています。",
    ];
    List<String> advice_armpitfit_list
    = ["",
      "非常に開いています。赤ちゃんの顔を肩に乗せ、肘～手首の間と体を使って抱っこしましょう。",
      "かなり開いています。赤ちゃんの顔を肩に乗せ、肘～手首の間と体を使って抱っこしましょう。",
      "やや開いています。肩の力を抜き、赤ちゃんを深く抱いてみましょう。",
      "ほぼ適切です。赤ちゃんをもう少し深く抱いてみましょう。",
      "適切です。",
    ];
    List<String> advice_closeness_list
    = ["",
      "非常に離れています。赤ちゃんと自分の体を密着させましょう。",
      "かなり離れています。赤ちゃんと自分の体を密着させましょう。",
      "やや離れています。赤ちゃんが寄りかかるように抱っこしましょう。",
      "ほぼ適切です。",
      "適切です。",
    ];

    //ケンダル分類指摘出力
    if(score[2] == 0){
      advicelist.add(advice_kendall_list[0]+advice_kendall_list[1]);
    }
    if(score[2] == 5){
      advicelist.add(advice_kendall_list[0]+advice_kendall_list[2]);
    }
    if(score[2] == 10){
      advicelist.add(advice_kendall_list[0]+advice_kendall_list[3]);
    }
    if(score[2] == 15){
      advicelist.add(advice_kendall_list[0]+advice_kendall_list[4]);
    }
    if(score[2] == 19){
      advicelist.add(advice_kendall_list[0]+advice_kendall_list[5]);
    }

    //抱っこの高さ指摘出力
    if(score[3] == 0){
      advicelist.add(advice_hugheight_list[0]+advice_hugheight_list[1]);
    }
    if(score[3] == 5){
      advicelist.add(advice_hugheight_list[0]+advice_hugheight_list[2]);
    }
    if(score[3] == 10){
      advicelist.add(advice_hugheight_list[0]+advice_hugheight_list[3]);
    }
    if(score[3] == 15){
      advicelist.add(advice_hugheight_list[0]+advice_hugheight_list[4]);
    }
    if(score[3] == 20){
      advicelist.add(advice_hugheight_list[0]+advice_hugheight_list[5]);
    }
    //肩のバランスの指摘出力
    if(score[1] == 0){
      advicelist.add(advice_shoulderbalance_list[0]+advice_shoulderbalance_list[1]);
    }
    if(score[1] == 5){
      advicelist.add(advice_shoulderbalance_list[0]+advice_shoulderbalance_list[2]);
    }
    if(score[1] == 10){
      advicelist.add(advice_shoulderbalance_list[0]+advice_shoulderbalance_list[3]);
    }
    if(score[1] == 15){
      advicelist.add(advice_shoulderbalance_list[0]+advice_shoulderbalance_list[4]);
    }
    if(score[1] == 20){
      advicelist.add(advice_shoulderbalance_list[0]+advice_shoulderbalance_list[5]);
    }
    //脇の開きの指摘出力
    if(score[4] == 0){
      advicelist.add(advice_armpitfit_list[0]+advice_armpitfit_list[1]);
    }
    if(score[4] == 5){
      advicelist.add(advice_armpitfit_list[0]+advice_armpitfit_list[2]);
    }
    if(score[4] == 10){
      advicelist.add(advice_armpitfit_list[0]+advice_armpitfit_list[3]);
    }
    if(score[4] == 15){
      advicelist.add(advice_armpitfit_list[0]+advice_armpitfit_list[4]);
    }
    if(score[4] == 20){
      advicelist.add(advice_armpitfit_list[0]+advice_armpitfit_list[5]);
    }
    //密着の指摘出力
    if(score[5] == 0){
      advicelist.add(advice_closeness_list[0]+advice_closeness_list[1]);
    }
    if(score[5] == 5){
      advicelist.add(advice_closeness_list[0]+advice_closeness_list[2]);
    }
    if(score[5] == 10){
      advicelist.add(advice_closeness_list[0]+advice_closeness_list[3]);
    }
    if(score[5] == 15){
      advicelist.add(advice_closeness_list[0]+advice_closeness_list[4]);
    }
    if(score[5] == 20){
      advicelist.add(advice_closeness_list[0]+advice_closeness_list[5]);
    }

    //リストを一つ吐き出したら改行を行う
    for(var i in advicelist){
      if(advicecount==0) {
        advice += advicelist[advicecount];
        advicecount++;
      }
      else {
        advice += "\n" + advicelist[advicecount];
        advicecount++;
      }
    }

    // _advice() の際に返す
    return advicelist;
  }

  //三角チャート
  List <double> _triangular_chart(){
    List<double> point=[];
    List<String> summraize = _Summraize();
    // double hug_height_score = 55;
    // double kendall_score1 = -140;
    // double kendall_score2 = 260;
    // double shoulder_score1 = 90;
    // double shoulder_score2 = 260;

    //満点三角形→path.moveTo(-80, -280);path.lineTo(-160, -140);path.lineTo(0, -140);
    double hug_height_score = -280;
    double kendall_score1 = -160;
    double kendall_score2 = -140;
    double shoulder_score1 = 0;
    double shoulder_score2 = -140;
    //5段階評価用
    double hug_height_point = 0;
    double kendall_point = 0;
    double shoulder_point = 0;

      //抱っこの高さ三角チャート計算
    if(double.parse(summraize[2]) > 0.5){
      hug_height_point = 0;
    }
    else if(double.parse(summraize[2]) > 0.45){
      hug_height_point = 1;
    }
    else if(double.parse(summraize[2]) > 0.40){
      hug_height_point = 2;
    }
    else if(double.parse(summraize[2]) > 0.35){
      hug_height_point = 3;
    }
    else{
      hug_height_point = 4;
    }
    
    //ケンダル三角チャート計算
    if(summraize[1]=="ノーマル"){
      kendall_point = 0;
    }
    else{
      kendall_point = 2;
    }

    //肩の並行三角チャート計算
    if(double.parse(summraize[0]) <= 2.8){
      shoulder_point = 0;
    }
    else if(double.parse(summraize[0]) <= 3.0){
      shoulder_point = 1;
    }
    else if(double.parse(summraize[0]) <= 3.2){
      shoulder_point = 2;
    }
    else if(double.parse(summraize[0]) <= 3.4){
      shoulder_point = 3;
    }
    else{
      shoulder_point = 4;
    }

    //満点三角形→path.moveTo(-25, 55);path.lineTo(-140, 260);path.lineTo(90, 260);
    //計算5段階評価の場合(5→1) hug_height_score +35していく kendall_score1　-28.75 kendallscore2 -16.25していく shoulder_score1 -28.75 shoulder_score2 -16.25していく
    //計算5段階評価の場合(5→1) hug_height_score +22.5していく kendall_score1　20.0 kendallscore2 -12.5していく shoulder_score1 -20 shoulder_score2 -12.5していく
    hug_height_score += hug_height_point * 22.5;
    kendall_score1 += kendall_point * 20;
    kendall_score2 += kendall_point * -12.5;
    shoulder_score1 += shoulder_point * -20;
    shoulder_score2 += shoulder_point * -12.5;

    //追加していく
    point.add(hug_height_score);
    point.add(kendall_score1);
    point.add(kendall_score2);
    point.add(shoulder_score1);
    point.add(shoulder_score2);
    point.add(hug_height_point);
    point.add(kendall_point);
    point.add(shoulder_point);

  return point;
}
  //ダイアログ表示（未使用）
  _openDialog() {
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: EdgeInsets.zero, //titleの周りについているpaddingを無しにする
          title : Visibility(
            child: Image.asset("assets/imagescore.png",height: 200,fit: BoxFit.cover,),visible: tf,
          ),
          content: Column(mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(child: Text(text,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.orange)),visible: texttf,),
            Visibility(child: Text(kendall_text),visible: tf ),

            ListView(//crossAxisAlignment: CrossAxisAlignment.start,
              children:[
            //BadPont
            Visibility(child: Text("横から見た姿勢："),visible: badtf),
            Visibility(child: Text(badtxt[0],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.orange)),visible: badtf),
            Visibility(child: Text("抱っこの位置："),visible: badtf),
            Visibility(child: Text(badtxt[1],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.orange)),visible: badtf),
            Visibility(child: Text("左右の肩の高さ："),visible: badtf),
            Visibility(child: Text(badtxt[2],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.orange)),visible: badtf),
            //アドバイス
            Visibility(child: Text("横から見た姿勢："),visible: advicetf),
            Visibility(child: Text(advicetxt[0],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.orange)),visible: advicetf),
            Visibility(child: Text("抱っこの位置："),visible: advicetf),
            Visibility(child: Text(advicetxt[1],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.orange)),visible: advicetf),
            Visibility(child: Text("左右の肩の高さ："),visible: advicetf),
            Visibility(child: Text(advicetxt[2],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.orange)),visible: advicetf)
          ]
          )
            ],
            ) ,
          actions: <Widget>[
            Visibility(child:
            CustomPaint(
              painter: ImagePainter(_triangular_chart()),
            ),visible: tf
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //複数のスマホで実行できるようにデバイスのサイズを取得するための関数
List<double> _devicesizeget(){
    List<double> devicesize = [];
      //デバイスのサイズ取得
      final double deviceWidth = MediaQuery.of(context).size.width;
      final double deviceHeight = MediaQuery.of(context).size.height;
      devicesize.add(deviceWidth);
      devicesize.add(deviceHeight);
      return devicesize;
  }

// スクショするための関数
Future<void> widgetToImage(wti) async {
  final boundary = wti.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    return;
  }

  // 画像をキャプチャ
  final image = await boundary.toImage(pixelRatio: 3.0); // 例として pixelRatio を指定
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  if (byteData != null) {
    // バイトデータをUint8Listに変換
    Uint8List bytes = byteData.buffer.asUint8List();
    
    // スクリーンショットを表示する
    showDialog(
      context: wti.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Image.memory(bytes),
        );
      },
    );
  }
}

//Widget build
  @override

  Widget build(BuildContext context) {
    //初期状態
    if(count==0){
      // 前ページから引継いだ内容
      image = widget.path1;
      imagefront = widget.path1;
      imageside = widget.path2;
      offset = widget.offsets1;
      dir = "front";
      button = "score";
      count++;
      downcolor_1 = Colors.orange;
      upcolor_1 = Colors.orange;
      text = _score()[0].toString();
      summraize = _Summraize();
      kendall_text = "姿勢パターン:";
      advicetxt = _advice();
      badtxt = _badpoint();
    }

    var _audio = AudioPlayer();
    return Scaffold(
      appBar:PreferredSize(
        preferredSize: Size.fromHeight(_devicesizeget()[1]/12), // AppBarの高さを変更
        child: AppBar(
            centerTitle: true,
            actions:[ElevatedButton(
                        onPressed: () async {
                          String confirmationText =
                              "撮影した写真と推定した姿勢の数値情報が送信されます。\n研究用途以外には使用しません。\n個人情報は保護されます.";
                          String sendtext = "送信します";
                          String nosendtext = "送信しません";
                          showDialog(
                            context: context,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text("アップロードについて"),
                                  content: Text(confirmationText),
                                  actions: [
                                    GestureDetector(
                                      child: Text(
                                        nosendtext,
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      onTap: () {
                                        Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
                                      },
                                    ),
                                    GestureDetector(
                                      child: Text(
                                        sendtext,
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      onTap: () async {
                                        // Firebaseへのアップロード処理
                                        setState(() {
                                          confirmationText = "送信中です。";
                                          sendtext = "";
                                          nosendtext = "";
                                        });
                                        await uploadImage(widget.path1,widget.path2,widget.path3,widget.offsets1,widget.offsets2,widget.offsets3);
                                        Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: Size(120, _devicesizeget()[1]/12),
                          backgroundColor: Colors.black.withOpacity(0.6),
                          elevation: 16,
                        ),
                        child: Text(
                          "FINISH",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: main_text_colors,
                          ),
                        ),
                      )
            ],

            // actions:[IconButton(onPressed: (){Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);}, icon:Icon(Icons.home,color: icon_colors,))],
            title:  Text("縦：評価結果",style:TextStyle(color: appbar_text_colors)),
            backgroundColor: appbar_colors),
      ),
      body:Stack(
          children: <Widget>[
            ListView(
              ),
            ListView(children:[
            Row(
              children: <Widget>[
              RepaintBoundary(
              key: globalKeyfront,
               child: Container(
                width: _devicesizeget()[0]/2,
                height: _devicesizeget()[1]/12*4.5,
                child: InteractiveViewer(
                child: GestureDetector(
                  onTap: () {
                    // スクショするための関数
                    widgetToImage(globalKeyfront);
                  },
                  child:Stack(
                    children: [
                      Transform.scale(
                        scale: 1, // スケールファクター（2.0で2倍に拡大）
                          child: Image.file(
                            File(imagefront),
                          ),
                      ),
                CustomPaint(
                  //引数の渡す方
                  painter: MyPainter(offset=widget.offsets1,dir="front",button,summraize,_score()),
                  // タッチを有効にするため、childが必要
                  child: Center(),
              ),
                    ],
                  ),
                ),
                ),
              ),
              ),

              RepaintBoundary(
              key: globalKeyside,
                child: Container(
                  width: _devicesizeget()[0]/2,
                  height: _devicesizeget()[1]/12*4.5,
                  child: InteractiveViewer(
                  child: GestureDetector(
                  onTap: () {
                    // スクショするための関数
                    widgetToImage(globalKeyside);
                  },
                  // color: Colors.red,
                  child:Stack(
                    children: [
                        Image.file(
                            File(imageside),
                    ),
              Padding(padding: EdgeInsets.only(top:0),
                child: CustomPaint(
                  //引数の渡す方
                  painter: MyPainter(offset=widget.offsets2,dir="right",button,summraize,_score()),
                  // タッチを有効にするため、childが必要
                  child: Center(),
              ),
              ),
                    ],
                  ),
                  ),
                ),
              ),
              ),
              ]
              ),
            Container(
                  width: _devicesizeget()[0],
                  height: _devicesizeget()[1]/12*4.8,
                  // color: Colors.blue,
                  child:Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                    Row(
                      children: [
                        Visibility(visible: texttf,
                        child:Container(
                          // padding: EdgeInsets.only(top: 5),
                          width: _devicesizeget()[0]/2,
                          height: _devicesizeget()[1]/12*3.8,
                          padding: EdgeInsets.only(top: 30),
                          child:Center(
                            child: Column(children: [
                              Text("抱っこスコア",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25,color: Colors.black)),
                              Text(text,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 100,color: Colors.red))
                            ]),
                          )

                        )
                        ),
                        // Visibility(child: Text(kendall_text),visible: tf ),
                        Visibility(visible: tf,
                          child:Container(
                          width: _devicesizeget()[0]/2.5,
                          height: _devicesizeget()[1]/12*3.8,
                            //レーダーチャート
                          padding: EdgeInsets.only(top: 0,right: 0),
                            child: RadarChart(
                              
                              RadarChartData( 
                                tickCount: 5, // レーダーチャートの軸目盛りの数
                                titleTextStyle:
                                TextStyle(color: Colors.black, fontSize: 16,fontWeight: FontWeight.bold),
                                gridBorderData: BorderSide.none, // グラフ内の数字を非表示にする,
                                getTitle: ((index,angle) {
                                  if (index == 0){
                                    return RadarChartTitle(
                                      text: '肩のバランス',
                                      angle: 0
                                    );
                                  }
                                  if (index == 1){
                                    return RadarChartTitle(
                                      text: '重心線',
                                      angle: 0
                                    );
                                  }
                                  if (index == 2){
                                    return RadarChartTitle(
                                      text: '抱っこの高さ',
                                      angle: 0
                                    );
                                  }
                                  if (index == 3){
                                    return RadarChartTitle(
                                      text: '脇の開き',
                                      angle: 0
                                    );
                                  }
                                  if (index == 4){
                                    return RadarChartTitle(
                                      text: '密着',
                                      angle: 0
                                    );
                                  }
                                  else{
                                    return RadarChartTitle(
                                      text: 'あ',
                                      angle: 0
                                    );
                                  }
                                }),
                                dataSets: [
                                  RadarDataSet(
                                    fillColor: Colors.orange.withOpacity(0.4),
                                    borderColor: Colors.red,
                                    borderWidth: 4,
                                    dataEntries: [
                                      // _score()[1]shoulder_score [2]backbone_score [3]hugheight_score [4]armpitfit_score [5]closeness_score;
                                      RadarEntry(value: (_score()[1].toDouble())),
                                      RadarEntry(value: (_score()[2].toDouble())),
                                      RadarEntry(value: (_score()[3].toDouble())),
                                      RadarEntry(value: (_score()[4].toDouble())),
                                      RadarEntry(value: (_score()[5].toDouble())),
                                    ],
                                  ),
                                  //グラフを重ね合わせている(値が取り得る範囲を全て記述することでグラフ描画を正しくしている)
                                  RadarDataSet(
                                    // データの塗りつぶしの色(透過)
                                  fillColor: Colors.blue.withOpacity(0),
                                  // データのボーダーの色(透過)
                                  borderColor: Colors.blue.withOpacity(0),
                                  dataEntries: [
                                    const RadarEntry(value: 20),
                                    const RadarEntry(value: 15),
                                    const RadarEntry(value: 10),
                                    const RadarEntry(value: 5),
                                    const RadarEntry(value: 0),
                                  ]
                                )
                                ],
                                // 他のチャートプロパティを設定
                                ticksTextStyle: const TextStyle(color: Colors.transparent),//目盛り表示消す
                                radarShape: RadarShape.polygon,//チャートの形
                              ),
                            ),
                          ),
                          ),
                      ],
                    ),
                    Visibility(visible:tf, 
                    child:Center(
                    child:Text(_scoretext(_score()),style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25,color: Colors.red)),
                    ),
                    ),
        Visibility(visible:badtf, child:
        Container(
            width: _devicesizeget()[0],
            height: _devicesizeget()[1]/12*4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(child: Padding(padding: EdgeInsets.only(left: 8.0,right: 8.0),child: AutoSizeText("横から見た姿勢：",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black),maxFontSize: 40.0,)),visible: badtf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text(badtxt[0],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black54))),visible: badtf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text("抱っこの位置：",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black))),visible: badtf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text(badtxt[1],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black54))),visible: badtf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text("左右の肩の高さ：",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black))),visible: badtf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text(badtxt[2],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,color: Colors.black54))),visible: badtf),
              ],
            )
                    //BadPoint
    ),
        ),
      Visibility(visible:advicetf, 
      child:Expanded(
      child:SingleChildScrollView(
        child: Container(
            width: _devicesizeget()[0],
            height: _devicesizeget()[1]/12*5.6,
            // 表示エラーの都合上「Column」から「ListView」に変更
            child: ListView(//crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //アドバイス（ここで「アドバイス」のFontSizeを変えたりする）
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text("立位での重心線：",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14,color: Colors.black))),visible: advicetf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text(advicetxt[0],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12,color: Colors.black54))),visible: advicetf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text("抱っこの高さ：",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14,color: Colors.black))),visible: advicetf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text(advicetxt[1],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12,color: Colors.black54))),visible: advicetf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text("肩のバランス：",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14,color: Colors.black))),visible: advicetf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text(advicetxt[2],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12,color: Colors.black54))),visible: advicetf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text("密着：",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14,color: Colors.black))),visible: advicetf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text(advicetxt[3],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12,color: Colors.black54))),visible: advicetf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text("脇の開き：",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14,color: Colors.black))),visible: advicetf),
                Visibility(child: Padding(padding: const EdgeInsets.only(left: 8.0,right: 8.0),child: Text(advicetxt[4],style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12,color: Colors.black54))),visible: advicetf),
              ],
            )
    ),
        ),
      ),
      ),
                  ]
          )
            ),
              // Padding(
              //   padding: EdgeInsets.only(top: 0, left: 0),
              //   child: Container(
              //     width: _devicesizeget()[0],
              //     height: _devicesizeget()[1]/12*1,
              //   child: isVisible
              //       ? ElevatedButton(
              //           onPressed: () async {
              //             String confirmationText =
              //                 "撮影した写真と推定した姿勢の数値情報が送信されます。\n研究用途以外には使用しません。\n個人情報は保護されます.";
              //             String sendtext = "送信します";
              //             String nosendtext = "送信しません";
              //             showDialog(
              //               context: context,
              //               builder: (context) => StatefulBuilder(
              //                 builder: (context, setState) {
              //                   return AlertDialog(
              //                     title: const Text("アップロードについて"),
              //                     content: Text(confirmationText),
              //                     actions: [
              //                       GestureDetector(
              //                         child: Text(
              //                           nosendtext,
              //                           style: TextStyle(fontSize: 20),
              //                         ),
              //                         onTap: () {
              //                           Navigator.pop(context);
              //                         },
              //                       ),
              //                       GestureDetector(
              //                         child: Text(
              //                           sendtext,
              //                           style: TextStyle(fontSize: 20),
              //                         ),
              //                         onTap: () async {
              //                           // Firebaseへのアップロード処理
              //                           setState(() {
              //                             confirmationText = "送信中です。";
              //                             sendtext = "";
              //                             nosendtext = "";
              //                           });
              //                           await uploadImage(widget.path1,widget.path2,widget.path3,widget.offsets1,widget.offsets2,widget.offsets3);
              //                           // ボタン非表示
              //                           setState(() {
              //                             isVisible = false;
              //                           });
              //                           Navigator.pop(context);
              //                         },
              //                       ),
              //                     ],
              //                   );
              //                 },
              //               ),
              //             );
              //           },
              //           style: ElevatedButton.styleFrom(
              //             fixedSize: const Size(60, 30),
              //             backgroundColor: Colors.black.withOpacity(0.6),
              //             elevation: 16,
              //           ),
              //           child: Text(
              //             "データをアップロード",
              //             style: TextStyle(
              //               fontWeight: FontWeight.bold,
              //               fontSize: 28,
              //               color: main_text_colors,
              //             ),
              //           ),
              //         )

              //       : Container(), // ボタンが非表示の場合は空のコンテナを表示
              // ),
              // ),
              ]
              ),

            Row(mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(alignment: Alignment.bottomCenter,
               child: Padding(padding: EdgeInsets.only(top: 10,left: 5),
                 child: Container(
                   width: _devicesizeget()[0]/2.1,
                   height: _devicesizeget()[1]/12*1,
                  child: ElevatedButton(
                      onPressed: (){
                        setState(() {
                          score = _score()[0].toString();
                          text = score;
                          button = "score";
                          imagescore = "assets/imagescore.png";
                          downcolor_1 = Colors.orange;
                          downcolor_2 = Colors.grey;
                          downcolor_3 = Colors.grey;
                          tf = true;
                          badtf = false;
                          texttf = true;
                          advicetf = false;
                          // _openDialog();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize:const Size(120,80),
                        backgroundColor: downcolor_1.withOpacity(0.6),//ボタン背景色
                        elevation: 16,
                      ),
                      child: Text("抱っこスコア",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color: main_text_colors)),
                    ),
                 ),
                    ),
                ),
                  //   Padding(padding: EdgeInsets.only(top: 10,left: 5),
                  //     child: Container(
                  //       width: _devicesizeget()[0]/3.2,
                  //       height: _devicesizeget()[1]/12*1.2,
                  // child: ElevatedButton(
                  //     onPressed: (){
                  //       setState(() {
                  //         summraize = _Summraize();
                  //         badtxt = _badpoint();
                  //         button = "badpoint";
                  //         imagescore = "assets/null.png";
                  //         downcolor_1 = Colors.grey;
                  //         downcolor_2 = Colors.orange;
                  //         downcolor_3 = Colors.grey;
                  //         tf = false;
                  //         badtf = true;
                  //         texttf = false;
                  //         advicetf = false;
                  //         // _openDialog();
                  //       });
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       fixedSize:const Size(120,80),
                  //       backgroundColor: downcolor_2.withOpacity(0.6),
                  //       elevation: 16,
                  //     ),
                  //     child: Text("要点",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30,color: main_text_colors)),
                  //   ),
                  //     ),
                  //   ),
                    Padding(padding: EdgeInsets.only(top: 10,left: 5),
                      child: Container(
                        width: _devicesizeget()[0]/2.1,
                        height: _devicesizeget()[1]/12*1,
                  child: ElevatedButton(
                      onPressed: (){
                        setState(() {

                          advicetxt = _advice();
                          button = "advice";
                          imagescore = "assets/null.png";
                          downcolor_1 = Colors.grey;
                          downcolor_2 = Colors.grey;
                          downcolor_3 = Colors.orange;
                          tf = false;
                          badtf = false;
                          texttf = false;
                          advicetf = true;
                          // _openDialog();

                        });
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize:const Size(120,80),
                        backgroundColor: downcolor_3.withOpacity(0.6),
                        elevation: 16,
                      ),
                      child: Text("アドバイス",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 22,color: main_text_colors)),
                      
                    ),
                      ),
                    ),
              ],
            ),
            // Visibility(child: Text(kendall_text,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 32,color: Colors.black)),visible: tf,),
            // Text(text,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color: Colors.red)),
            // Visibility(child: CustomPaint(
            //   painter: ImagePainter(_triangular_chart()),
            // ),visible: tf)
            
            // Visibility(child: Image.asset(imagescore),visible: tf,)

      // Padding(padding: EdgeInsets.only(top: 730,left: 20),
      //     child: Text(_calculation(kendall),style: TextStyle(fontWeight: FontWeight.bold,fontSize: 35,color: Colors.black)),
      // ),
          ],
      ),
    );
    }
}

//描画用：画像に線や印を描画するための関数
class MyPainter extends CustomPainter{
  //引数の受け取る方
  List<Offset> offsets;
  String dir;
  String button;
  List<String> summraize;
  List<int> scorelist;

  MyPainter(this.offsets,this.dir,this.button,this.summraize,this.scorelist);
  //appberの高さを取得
  // var height = AppBar().preferredSize.height;

  int count = 0;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.red;
    final radius = size.width / 50;
    List<Offset> landmarks = [];

    //テキストペインター用定義
    String text = "";
    TextSpan span = new TextSpan(
        text: text,
        style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.blueGrey.withOpacity(0.5)));//透過50%

    //正面用
    if(dir=="front"){
    //修正ページのx,y座標と合わせる必要があるため -Offset(0,120) , countで制御
    if(count==0){
      //高菜
    offsets = offsets.map((offset) => Offset(offset.dx / 2, offset.dy / 2)).toList();
      count++;
      if(offsets.length==9){
        landmarks.add(offsets[0]-Offset(0, 120));
        landmarks.add(offsets[1]-Offset(0, 120));
        landmarks.add(offsets[2]-Offset(0, 120));
        landmarks.add(offsets[3]-Offset(0, 120));
        landmarks.add(offsets[4]-Offset(0, 120));
        landmarks.add(offsets[5]-Offset(0, 120));
        landmarks.add(offsets[6]-Offset(0, 120));
        landmarks.add(offsets[7]-Offset(0, 120));
        landmarks.add(offsets[8]-Offset(0, 120));
        //戻す
        offsets = landmarks;
      }
    }
    landmarks =  [];
    if(offsets.length!=9){
      landmarks.add(offsets[0]);
      landmarks.add(offsets[11]);
      landmarks.add(offsets[12]);
      landmarks.add(offsets[13]);
      landmarks.add(offsets[14]);
      landmarks.add(offsets[15]);
      landmarks.add(offsets[16]);
      landmarks.add(offsets[23]);
      landmarks.add(offsets[24]);

      //戻す
      offsets = landmarks;
    }

    final Nose = offsets[0];
    // final Left_eye = offsets[1];
    // final Right_eye = offsets[2];
    // final Left_mouth = offsets[3];
    // final Right_mouth = offsets[4];
    final Left_shoulder = offsets[1];
    final Right_shoulder = offsets[2];
    final Left_elbow = offsets[3];
    final Right_elbow = offsets[4];
    final Left_wrist = offsets[5];
    final Right_wrist = offsets[6];
    final Left_hip = offsets[7];
    final Right_hip = offsets[8];

    if(button=="score"||button=="advice") {
      //推定姿勢点プロット
      paint.color = Colors.orange.withOpacity(0.5);
      canvas.drawCircle(Nose, radius, paint);
      canvas.drawCircle(Left_shoulder, radius, paint);
      canvas.drawCircle(Right_shoulder, radius, paint);
      canvas.drawCircle(Left_elbow, radius, paint);
      canvas.drawCircle(Right_elbow, radius, paint);
      canvas.drawCircle(Left_wrist, radius, paint);
      canvas.drawCircle(Right_wrist, radius, paint);
      canvas.drawCircle(Left_hip, radius, paint);
      canvas.drawCircle(Right_hip, radius, paint);
      //canvas.drawCircle(Right_knee, radius, paint);
      //canvas.drawCircle(Right_ankle, radius, paint);
      // canvas.drawCircle(Left_eye, radius, paint);
      // canvas.drawCircle(Right_eye, radius, paint);
      // canvas.drawCircle(Left_mouth, radius, paint);
      // canvas.drawCircle(Right_mouth, radius, paint);
      //推定姿勢線プロット
      paint.strokeWidth = 5;
      paint.color = Colors.green.withOpacity(0.5);
      // canvas.drawLine(Left_mouth, Right_mouth, paint);
      canvas.drawLine(Right_shoulder, Left_shoulder, paint);
      canvas.drawLine(Right_shoulder, Right_elbow, paint);
      canvas.drawLine(Left_shoulder, Left_elbow, paint);
      canvas.drawLine(Left_elbow, Left_wrist, paint);
      canvas.drawLine(Right_elbow, Right_wrist, paint);
      canvas.drawLine(Left_shoulder, Left_hip, paint);
      canvas.drawLine(Right_shoulder, Right_hip, paint);
      //canvas.drawLine(Right_knee, Right_hip, paint);
      //canvas.drawLine(Right_knee, Right_ankle, paint);
      canvas.drawLine(Right_hip, Left_hip, paint);
    }

    //正面でスコアボタンを押しているとき
    if(button=="score") {
        //shoulderbalance描画(肩のバランス：〇〇度)
        // String shouldertext = "肩の角度:" + double.parse(summraize[0]).ceil().toString() + "度";
        String shouldertext = _symbol(scorelist[1]);

        TextSpan shoulderSpan = TextSpan(
          style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),  // オリジナルのスタイルを維持
          text: shouldertext,  // 新しいテキストを指定
        );
        TextPainter shoulder = new TextPainter(text: shoulderSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
        shoulder.layout();
        shoulder.paint(canvas, new Offset(Left_shoulder.dx, (Right_shoulder.dy+Left_shoulder.dy)/2));

        //backhandの高さテキスト表示(手首の高さ：〇〇％)
        // String backwristtext = "手首の高さ:" + ((double.parse(summraize[3])*100).ceil()).toString() + "%";
        String backwristtext = _symbol(scorelist[5]);

        TextSpan backwristSpan = TextSpan(
          style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),  // オリジナルのスタイルを維持
          text: backwristtext,  // 新しいテキストを指定
        );

        TextPainter backwrist = new TextPainter(text: backwristSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
        backwrist.layout();
        if(summraize[4]=="Right_wrist"){
          backwrist.paint(canvas, Left_wrist);
        }
        else if(summraize[4]=="Left_wrist"){
          backwrist.paint(canvas, Right_wrist);
        }
        //backhandの高さテキスト表示(手首の高さ：〇〇％)
        // String hipwristtext = "手首の高さ:" + ((double.parse(summraize[2])*100).ceil()).toString() + "%";
        String hipwristtext = _symbol(scorelist[3]);

        TextSpan hipwristSpan = TextSpan(
          style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),  // オリジナルのスタイルを維持
          text: hipwristtext,  // 新しいテキストを指定
        );

        TextPainter hipwrist = new TextPainter(text: hipwristSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
        hipwrist.layout();
        if(summraize[4]=="Right_wrist"){
          hipwrist.paint(canvas, Right_wrist);
        }
        else if(summraize[4]=="Left_wrist"){
          hipwrist.paint(canvas, Left_wrist);
        }

      }
    //正面badpoint用
    // [1.9385906915861866, 不明, 0.3848952710315345, 0.8713518732334877, Right_wrist]
    // [肩の平行具合、ケンダル、ヒップハンド、バックハンド、イズヒップハンド]
    if(button=="badpoint"){
      //肩の平行具合に異常があるとき
      if (double.parse(summraize[0]) > 2.8){
        //範囲を描画する
        paint.color = Colors.red.withOpacity(0.5);
        paint.strokeWidth = 5;
        canvas.drawCircle(Right_shoulder,15, paint);
        canvas.drawCircle(Left_shoulder,15, paint);
        //shoulderbalanceテキスト表示(肩のバランス)（変更済み）
        String shouldertext = "肩のバランス";

        TextStyle customStyle = TextStyle(
          fontSize: 10.0,  // テキストサイズを指定
          color: Colors.white,  // テキストの色を白に設定
          background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
        );

        TextSpan shoulderSpan = TextSpan(
          style: customStyle,  // オリジナルのスタイルを維持
          text: shouldertext,  // 新しいテキストを指定
        );

        TextPainter shoulderbalance = new TextPainter(text: shoulderSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
        shoulderbalance.layout();
        shoulderbalance.paint(canvas, new Offset(Left_shoulder.dx, (Right_shoulder.dy+Left_shoulder.dy)/2));
      }
      //抱っこの高さに異常があるとき
      if (double.parse(summraize[2]) < 0.5){
        if(summraize[4]=="Right_wrist"){
          //plotする
          paint.color = Colors.red.withOpacity(0.5);
          paint.strokeWidth = 5;
          canvas.drawCircle(Right_wrist, 15, paint);
          //shoulderbalanceテキスト表示(肩のバランス)(変更済み)
          String hugheighttext = "抱っこの高さ";

          TextStyle customStyle = TextStyle(
            fontSize: 10.0,  // テキストサイズを指定
            color: Colors.white,  // テキストの色を白に設定
            background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
          );

          TextSpan  hugheightSpan = TextSpan(
            style: customStyle,  // オリジナルのスタイルを維持
            text: hugheighttext,  // 新しいテキストを指定
          );

          TextPainter hugheight = new TextPainter(text: hugheightSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
          hugheight.layout();
          hugheight.paint(canvas, Right_wrist);
        }
        else if(summraize[4]=="Left_wrist"){
          //plotする
          paint.color = Colors.red.withOpacity(0.5);
          paint.strokeWidth = 5;
          canvas.drawCircle(Left_wrist, 15, paint);
          //shoulderbalanceテキスト表示(肩のバランス)（変更済み）
          String hugheighttext = "抱っこの高さ";

          TextStyle customStyle = TextStyle(
            fontSize: 10.0,  // テキストサイズを指定
            color: Colors.white,  // テキストの色を白に設定
            background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
          );

          TextSpan  hugheightSpan = TextSpan(
            style: customStyle,  // オリジナルのスタイルを維持
            text: hugheighttext,  // 新しいテキストを指定
          );

          TextPainter hugheight = new TextPainter(text: hugheightSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
          hugheight.layout();
          hugheight.paint(canvas, Left_wrist);
          //
        }
      }
        }
      //正面でアドバイスを押したときに描写
    if(button=="advice") {
        //理想の肩のバランスを描画する
        final Right_shoulder_ideal_x = Right_shoulder.dx;
        final Right_shoulder_ideal_y = (Left_shoulder.dy + Right_shoulder.dy) / 2;
        final Left_shoulder_ideal_x = Left_shoulder.dx;
        final Left_shoulder_ideal_y = (Left_shoulder.dy + Right_shoulder.dy) / 2;
        paint.strokeWidth = 5;
        paint.color = Colors.red.withOpacity(0.5);
        canvas.drawLine(Offset(Right_shoulder_ideal_x, Right_shoulder_ideal_y),
            Offset(Left_shoulder_ideal_x, Left_shoulder_ideal_y), paint);
        paint.color = Colors.red.withOpacity(0.7);
        canvas.drawCircle(Offset(Right_shoulder_ideal_x, Right_shoulder_ideal_y),radius, paint);
        canvas.drawCircle(Offset(Left_shoulder_ideal_x, Left_shoulder_ideal_y),radius, paint);
        //shoulderbalanceテキスト表示(肩のバランス)（変更済み）
        String shouldertext = "肩のバランス";

        TextStyle customStyle = TextStyle(
          fontSize: 10.0,  // テキストサイズを指定
          color: Colors.white,  // テキストの色を白に設定
          background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
        );

        TextSpan  shoulderSpan = TextSpan(
          style: customStyle,  // オリジナルのスタイルを維持
          text: shouldertext,  // 新しいテキストを指定
        );


        TextPainter shoulderbalance = new TextPainter(text: shoulderSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
        shoulderbalance.layout();
        shoulderbalance.paint(canvas, new Offset(Left_shoulder.dx, (Right_shoulder.dy+Left_shoulder.dy)/2));

        //抱っこの高さに異常があるとき理想の抱っこの高さを描画する
        if (double.parse(summraize[2]) < 0.5){
          if(summraize[4]=="Right_wrist"){
            //特徴点と直線を描画する
            paint.color = Colors.red.withOpacity(0.5);
            paint.strokeWidth = 5;
            canvas.drawCircle(Right_elbow, radius, paint);//お尻を支えている腕の肘の特徴点を描画
            final Right_wrist_ideal_x = Right_wrist.dx;
            final Right_wrist_ideal_y = (Right_shoulder.dy + Right_hip.dy) / 2;
            canvas.drawCircle(Offset(Right_wrist_ideal_x,Right_wrist_ideal_y), radius, paint);//理想の手首の特徴点を描画
            paint.color = Colors.red.withOpacity(0.5);
            canvas.drawLine(Right_elbow,
                Offset(Right_wrist_ideal_x,Right_wrist_ideal_y), paint);//上記2点をつなげる直線を描画
            //説明用テキストを描画する（変更済み）
            String hugheighttext = "抱っこの高さ";

            TextStyle customStyle = TextStyle(
              fontSize: 10.0,  // テキストサイズを指定
              color: Colors.white,  // テキストの色を白に設定
              background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
            );

            TextSpan hugheightSpan = TextSpan(
              style: customStyle,  // オリジナルのスタイルを維持
              text: hugheighttext,  // 新しいテキストを指定
            );

            TextPainter hugheight = new TextPainter(text: hugheightSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
            hugheight.layout();
            hugheight.paint(canvas,Right_elbow);
        }
          else if(summraize[4]=="Left_wrist"){
            //特徴点と直線を描画する
            paint.color = Colors.red.withOpacity(0.5);
            paint.strokeWidth = 5;
            canvas.drawCircle(Left_elbow, radius, paint);
            final Left_wrist_ideal_x = Left_wrist.dx;
            final Left_wrist_ideal_y = (Left_shoulder.dy + Left_hip.dy) / 2;//理想の手首の特徴点を描画
            canvas.drawCircle(Offset(Left_wrist_ideal_x,Left_wrist_ideal_y), radius, paint);//理想の手首の特徴点を描画
            paint.color = Colors.red.withOpacity(0.5);
            canvas.drawLine(Left_elbow,
                Offset(Left_wrist_ideal_x,Left_wrist_ideal_y), paint);//上記2点をつなげる直線を描画
            //説明用テキストを描画する(変更済み)
            String hugheighttext = "抱っこの高さ";

            TextStyle customStyle = TextStyle(
              fontSize: 10.0,  // テキストサイズを指定
              color: Colors.white,  // テキストの色を白に設定
              background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
            );

            TextSpan hugheightSpan = TextSpan(
              style: customStyle,  // オリジナルのスタイルを維持
              text: hugheighttext,  // 新しいテキストを指定
            );

            TextPainter hugheight = new TextPainter(text: hugheightSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
            hugheight.layout();
            hugheight.paint(canvas,Left_elbow);
          }
        }
    }
  }

  //右用
  if(dir=="right"){
        //修正ページのx,y座標と合わせる必要があるため -Offset(0,120) , countで制御
    if(count==0){
      //高菜
    offsets = offsets.map((offset) => Offset(offset.dx / 2, offset.dy / 2)).toList();
      count++;
      if(offsets.length==7){
        landmarks.add(offsets[0]-Offset(0, 120));
        landmarks.add(offsets[1]-Offset(0, 120));
        landmarks.add(offsets[2]-Offset(0, 120));
        landmarks.add(offsets[3]-Offset(0, 120));
        landmarks.add(offsets[4]-Offset(0, 120));
        landmarks.add(offsets[5]-Offset(0, 120));
        landmarks.add(offsets[6]-Offset(0, 120));
      //戻す
      offsets = landmarks;
      }
    }

    
    landmarks =  [];
    if(offsets.length!=7){
      // landmarks.add(offsets[0]);
      landmarks.add(offsets[8]);//耳
      landmarks.add(offsets[12]);
      landmarks.add(offsets[14]);
      landmarks.add(offsets[16]);
      landmarks.add(offsets[24]);
      landmarks.add(offsets[26]);
      landmarks.add(offsets[28]);

    //戻す
    offsets = landmarks;
   }

    final Nose = offsets[0];
    final Right_shoulder = offsets[1];
    final Right_elbow = offsets[2];
    final Right_wrist = offsets[3];
    final Right_hip = offsets[4];
    final Right_knee = offsets[5];
    final Right_ankle = offsets[6];

    final Right_shoulder_ideal = offsets[1].dy;
    final Right_hip_ideal = offsets[4].dy;
    final Right_knee_ideal = offsets[5].dy;
    final Right_ankle_ideal_x = offsets[6].dx;

    if(button=="score"||button=="advice") {
      //姿勢推定
      paint.color = Colors.orange.withOpacity(0.5);
      canvas.drawCircle(Nose, radius, paint);
      canvas.drawCircle(Right_shoulder, radius, paint);
      canvas.drawCircle(Right_elbow, radius, paint);
      canvas.drawCircle(Right_wrist, radius, paint);
      canvas.drawCircle(Right_hip, radius, paint);
      canvas.drawCircle(Right_knee, radius, paint);
      canvas.drawCircle(Right_ankle, radius, paint);


      //姿勢推定
      paint.strokeWidth = 5;
      paint.color = Colors.green.withOpacity(0.5);
      // canvas.drawLine(Nose, Right_shoulder, paint);
      canvas.drawLine(Right_shoulder, Right_elbow, paint);
      canvas.drawLine(Right_elbow, Right_wrist, paint);
      canvas.drawLine(Right_shoulder, Right_hip, paint);
      canvas.drawLine(Right_knee, Right_hip, paint);
      canvas.drawLine(Right_knee, Right_ankle, paint);
    }

    //右側姿勢スコアのボタンを押したときに描画する
    if(button=="score") {
      //膝角度
      // String kneetext = "膝：" + double.parse(summraize[5]).ceil().toString() + "度";
      TextSpan kneeSpan = TextSpan(
        style: span.style,  // オリジナルのスタイルを維持
        // text: kneetext,  // 新しいテキストを指定
      );
      TextPainter kneepaint = new TextPainter(text: kneeSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      kneepaint.layout();
      kneepaint.paint(canvas, new Offset(Right_knee.dx, Right_knee.dy));

      //腰角度
      // String elbowtext = "腰：" + double.parse(summraize[6]).ceil().toString() + "度";
      String elbowtext = _symbol(scorelist[2]);
      TextSpan hipSpan = TextSpan(
        style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),  // オリジナルのスタイルを維持
        text: elbowtext,  // 新しいテキストを指定
      );
      TextPainter elbowpaint = new TextPainter(text: hipSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      elbowpaint.layout();
      elbowpaint.paint(canvas, new Offset(Right_hip.dx, Right_hip.dy));

      //肩角度
      // String shouldertext = "肩：" + double.parse(summraize[7]).ceil().toString() + "度";
      TextSpan shoulderSpan = TextSpan(
        style: span.style,  // オリジナルのスタイルを維持
        // text: shouldertext,  // 新しいテキストを指定
      );
      TextPainter shoulderpaint = new TextPainter(text: shoulderSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      shoulderpaint.layout();
      shoulderpaint.paint(canvas, new Offset(Right_shoulder.dx, Right_shoulder.dy));
    }


   //右面badpoint用
    if(button=="badpoint"){
      // //ケンダル分類に異常があるとき赤線で
      if (scorelist[2] < 16) {
        //理想姿勢特徴点描画
        paint.color = Colors.red.withOpacity(0.5);
        canvas.drawCircle(
            Offset(Right_ankle_ideal_x, Right_shoulder_ideal), radius, paint);
        canvas.drawCircle(
            Offset(Right_ankle_ideal_x, Right_hip_ideal), radius, paint);
        canvas.drawCircle(
            Offset(Right_ankle_ideal_x, Right_knee_ideal), radius, paint);
        canvas.drawCircle(Right_ankle, radius, paint);

        paint.color = Colors.red.withOpacity(0.5);
        paint.strokeWidth = 5;
        canvas.drawLine(Offset(Right_ankle_ideal_x, Right_shoulder_ideal),
            Offset(Right_ankle_ideal_x, Right_hip_ideal), paint);
        canvas.drawLine(Offset(Right_ankle_ideal_x, Right_hip_ideal),
            Offset(Right_ankle_ideal_x, Right_knee_ideal), paint);
        canvas.drawLine(
            Offset(Right_ankle_ideal_x, Right_knee_ideal), Right_ankle, paint);
        //理想姿勢テキスト描画表示(姿勢)（変更済み）
        String kendaltext = "理想姿勢";

        TextStyle customStyle = TextStyle(
          fontSize: 10.0,  // テキストサイズを指定
          color: Colors.white,  // テキストの色を白に設定
          background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
        );

        TextSpan kendalSpan = TextSpan(
          style: customStyle,  // オリジナルのスタイルを維持
          text: kendaltext,  // 新しいテキストを指定
        );

        TextPainter kendal = new TextPainter(text: kendalSpan,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr);
        kendal.layout();
        kendal.paint(canvas, Right_hip);
      }
      // if (double.parse(summraize[0]) > 2.8){
      //   //plot
      //   paint.color = Colors.red.withOpacity(0.5);
      //   paint.strokeWidth = 5;
      //   canvas.drawCircle(Right_shoulder, 15, paint);
      //   //shoulderbalanceテキスト表示(肩のバランス)
      //   String shouldertext = "肩のバランス";
      //   TextSpan shoulderSpan = TextSpan(
      //     style: span.style,  // オリジナルのスタイルを維持
      //     text: shouldertext,  // 新しいテキストを指定
      //   );
      //   TextPainter shoulderbalance = new TextPainter(text: shoulderSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
      //   shoulderbalance.layout();
      //   shoulderbalance.paint(canvas, Right_shoulder);
      // }

      //抱っこの高さに異常があるときかつ右手がhiphadの時

      if (double.parse(summraize[2]) < 0.5&&summraize[4]=="Right_wrist"){
        //plotする
        paint.color = Colors.red.withOpacity(0.5);
        paint.strokeWidth = 5;
        canvas.drawCircle(Right_wrist, 15, paint);
        //shoulderbalanceテキスト表示(肩のバランス)（変更済み）
        String hugheighttext = "抱っこの高さ";

        TextStyle customStyle = TextStyle(
          fontSize: 10.0,  // テキストサイズを指定
          color: Colors.white,  // テキストの色を白に設定
          background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
        );

        TextSpan  hugheightSpan = TextSpan(
          style: customStyle,  // オリジナルのスタイルを維持
          text: hugheighttext,  // 新しいテキストを指定
        );

        TextPainter hugheight = new TextPainter(text: hugheightSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
        hugheight.layout();
        hugheight.paint(canvas, Right_wrist);
      }
    }
    //理想姿勢
    if(button=="advice") {
      //理想姿勢特徴点描画
      paint.color = Colors.red.withOpacity(0.5);
      canvas.drawCircle(
          Offset(Right_ankle_ideal_x, Right_shoulder_ideal), radius, paint);
      canvas.drawCircle(
          Offset(Right_ankle_ideal_x, Right_hip_ideal), radius, paint);
      canvas.drawCircle(
          Offset(Right_ankle_ideal_x, Right_knee_ideal), radius, paint);
      canvas.drawCircle(Right_ankle, radius, paint);

      paint.color = Colors.red.withOpacity(0.5);
      paint.strokeWidth = 5;
      canvas.drawLine(Offset(Right_ankle_ideal_x, Right_shoulder_ideal),
          Offset(Right_ankle_ideal_x, Right_hip_ideal), paint);
      canvas.drawLine(Offset(Right_ankle_ideal_x, Right_hip_ideal),
          Offset(Right_ankle_ideal_x, Right_knee_ideal), paint);
      canvas.drawLine(
          Offset(Right_ankle_ideal_x, Right_knee_ideal), Right_ankle, paint);
      //理想姿勢テキスト描画表示(姿勢)（アプリ上に反映されるラベル）（ここだけ変更している）
      String kendaltext = "理想姿勢";

      TextStyle customStyle = TextStyle(
        fontSize: 10.0,  // テキストサイズを指定
        color: Colors.white,  // テキストの色を白に設定
        background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
      );

      TextSpan kendalSpan = TextSpan(
        style: customStyle,  // オリジナルのスタイルを維持
        text: kendaltext,  // 新しいテキストを指定
      );

      TextPainter kendal = new TextPainter(text: kendalSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
      kendal.layout();
      kendal.paint(canvas, Right_hip);
    }
  }

  //左用
  if(dir=="left"){
      //修正ページのx,y座標と合わせる必要があるため -Offset(0,120) , countで制御
    if(count==0){
      //高菜
    offsets = offsets.map((offset) => Offset(offset.dx / 2, offset.dy / 2)).toList();
      count++;
      if(offsets.length==7){
        landmarks.add(offsets[0]-Offset(0, 120));
        landmarks.add(offsets[1]-Offset(0, 120));
        landmarks.add(offsets[2]-Offset(0, 120));
        landmarks.add(offsets[3]-Offset(0, 120));
        landmarks.add(offsets[4]-Offset(0, 120));
        landmarks.add(offsets[5]-Offset(0, 120));
        landmarks.add(offsets[6]-Offset(0, 120));
        //戻す
        offsets = landmarks;
      }
    }


    landmarks =  [];
    if(offsets.length!=7){
      // landmarks.add(offsets[0]);
      landmarks.add(offsets[7]);
      landmarks.add(offsets[11]);
      landmarks.add(offsets[13]);
      landmarks.add(offsets[15]);
      landmarks.add(offsets[23]);
      landmarks.add(offsets[25]);
      landmarks.add(offsets[27]);

      //戻す
      offsets = landmarks;
    }

    final Nose = offsets[0];
    final Left_shoulder = offsets[1];
    final Left_elbow = offsets[2];
    final Left_wrist = offsets[3];
    final Left_hip = offsets[4];
    final Left_knee = offsets[5];
    final Left_ankle = offsets[6];

    final Left_shoulder_ideal = offsets[1].dy;
    final Left_hip_ideal = offsets[4].dy;
    final Left_knee_ideal = offsets[5].dy;
    final Left_ankle_ideal_x = offsets[6].dx;
    //左面badpoint用
    if(button=="score"||button=="advice") {
      //姿勢推定
      paint.color = Colors.orange.withOpacity(0.5);
      canvas.drawCircle(Nose, radius, paint);
      canvas.drawCircle(Left_shoulder, radius, paint);
      canvas.drawCircle(Left_elbow, radius, paint);
      canvas.drawCircle(Left_wrist, radius, paint);
      canvas.drawCircle(Left_hip, radius, paint);
      canvas.drawCircle(Left_knee, radius, paint);
      canvas.drawCircle(Left_ankle, radius, paint);

      //姿勢推定
      paint.strokeWidth = 5;
      paint.color = Colors.green.withOpacity(0.5);
      // canvas.drawLine(Nose, Left_shoulder, paint);
      canvas.drawLine(Left_shoulder, Left_elbow, paint);
      canvas.drawLine(Left_elbow, Left_wrist, paint);
      canvas.drawLine(Left_shoulder, Left_hip, paint);
      canvas.drawLine(Left_knee, Left_hip, paint);
      canvas.drawLine(Left_knee, Left_ankle, paint);
    }
    //右側姿勢スコアのボタンを押したときに描画する
    if(button=="score") {
      //膝角度
      String kneetext = "膝：" + double.parse(summraize[8]).ceil().toString() + "度";
      TextSpan kneeSpan = TextSpan(
        style: span.style,  // オリジナルのスタイルを維持
        text: kneetext,  // 新しいテキストを指定
      );
      TextPainter kneepaint = new TextPainter(text: kneeSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      kneepaint.layout();
      kneepaint.paint(canvas, new Offset(Left_knee.dx, Left_knee.dy));

      //腰角度
      String elbowtext = "腰：" + double.parse(summraize[9]).ceil().toString() + "度";
      TextSpan hipSpan = TextSpan(
        style: span.style,  // オリジナルのスタイルを維持
        text: elbowtext,  // 新しいテキストを指定
      );
      TextPainter elbowpaint = new TextPainter(text: hipSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      elbowpaint.layout();
      elbowpaint.paint(canvas, new Offset(Left_hip.dx, Left_hip.dy));

      //肩角度
      String shouldertext = "肩：" + double.parse(summraize[10]).ceil().toString() + "度";
      TextSpan shoulderSpan = TextSpan(
        style: span.style,  // オリジナルのスタイルを維持
        text: shouldertext,  // 新しいテキストを指定
      );
      TextPainter shoulderpaint = new TextPainter(text: shoulderSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
      shoulderpaint.layout();
      shoulderpaint.paint(canvas, new Offset(Left_shoulder.dx, Left_shoulder.dy));
    }
    //左面badpoint用
    if(button=="advice") {
      //理想姿勢描画
      paint.color = Colors.red;
      canvas.drawCircle(
          Offset(Left_ankle_ideal_x, Left_shoulder_ideal), radius, paint);
      canvas.drawCircle(
          Offset(Left_ankle_ideal_x, Left_hip_ideal), radius, paint);
      canvas.drawCircle(
          Offset(Left_ankle_ideal_x, Left_knee_ideal), radius, paint);
      canvas.drawCircle(Left_ankle, radius, paint);

      //理想姿勢
      paint.strokeWidth = 5;
      paint.color = Colors.red;
      canvas.drawLine(Offset(Left_ankle_ideal_x, Left_shoulder_ideal),
          Offset(Left_ankle_ideal_x, Left_hip_ideal), paint);
      canvas.drawLine(Offset(Left_ankle_ideal_x, Left_hip_ideal),
          Offset(Left_ankle_ideal_x, Left_knee_ideal), paint);
      canvas.drawLine(
          Offset(Left_ankle_ideal_x, Left_knee_ideal), Left_ankle, paint);
      //理想姿勢テキスト描画表示(姿勢)（変更済み）
      String kendaltext = "理想姿勢";

      TextStyle customStyle = TextStyle(
        fontSize: 10.0,  // テキストサイズを指定
        color: Colors.white,  // テキストの色を白に設定
        background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
      );

      TextSpan kendalSpan = TextSpan(
        style: customStyle,  // オリジナルのスタイルを維持
        text: kendaltext,  // 新しいテキストを指定
      );

      TextPainter kendal = new TextPainter(text: kendalSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
      kendal.layout();
      kendal.paint(canvas, Left_hip);
    }
    //左用badpoint用
    if(button=="badpoint"){
      //肩の平行具合に異常があるとき
      if (double.parse(summraize[0]) > 2.8){
        //polotする
        paint.color = Colors.red.withOpacity(0.5);
        paint.strokeWidth = 5;
        canvas.drawCircle(Left_shoulder, 15, paint);
        //shoulderbalanceテキスト表示(肩のバランス)（変更済み）
        String shouldertext = "肩のバランス";

        TextStyle customStyle = TextStyle(
          fontSize: 10.0,  // テキストサイズを指定
          color: Colors.white,  // テキストの色を白に設定
          background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
        );

        TextSpan  shoulderSpan = TextSpan(
          style: customStyle,  // オリジナルのスタイルを維持
          text: shouldertext,  // 新しいテキストを指定
        );

        TextPainter shoulderbalance = new TextPainter(text: shoulderSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
        shoulderbalance.layout();
        shoulderbalance.paint(canvas, Left_shoulder);
      }
      //抱っこの高さに異常があるとき
      if (double.parse(summraize[2]) < 0.5){
        if(summraize[4]=="Left_wrist"){
          //plotする
          paint.color = Colors.red.withOpacity(0.5);
          paint.strokeWidth = 5;
          canvas.drawCircle(Left_wrist, 15, paint);
          //shoulderbalanceテキスト表示(肩のバランス)（変更済み）
          String hugheighttext = "抱っこの高さ";

          TextStyle customStyle = TextStyle(
            fontSize: 10.0,  // テキストサイズを指定
            color: Colors.white,  // テキストの色を白に設定
            background: Paint()..color = Colors.black.withOpacity(0.5),  // 半透明の背景色を指定
          );

          TextSpan  hugheightSpan = TextSpan(
            style: customStyle,  // オリジナルのスタイルを維持
            text: hugheighttext,  // 新しいテキストを指定
          );

          TextPainter hugheight = new TextPainter(text: hugheightSpan, textAlign: TextAlign.right, textDirection: TextDirection.ltr);
          hugheight.layout();
          hugheight.paint(canvas, Left_wrist);
        }

      }
    }
  }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

//描画用：三角チャートを作成するための描画(未使用)
class ImagePainter extends CustomPainter{

  List<double> point;
  ImagePainter(this.point);

  @override
  void paint(Canvas canvas, Size size) {
    //チャート用
    // 三角（塗りつぶし）のためのPaintを作る
    Paint fillWithBluePaint = Paint()
      ..color = Colors.red.withOpacity(0.7);
    
    // 三角（外線）のためのPaintを作る
    Paint outlinePaint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Pathを作る
    var path = Path();
    
    double hug_height_score = point[0];
    double kendall_score1 = point[1];
    double kendall_score2 = point[2];
    double shoulder_score1 = point[3];
    double shoulder_score2 = point[4];

    // Pathのメソッドを使って三角形をかく。満点三角形→path.moveTo(-25, 60);path.lineTo(-140, 260);path.lineTo(90, 260);
    // Pathのメソッドを使って三角形をかく。満点三角形→path.moveTo(-80, -280);path.lineTo(-160, -140);path.lineTo(0, -140);
    //抱っこの高さ
    path.moveTo(-80, hug_height_score);
    // //背筋
    path.lineTo(kendall_score1, kendall_score2);
    // //肩の並行
    path.lineTo(shoulder_score1, shoulder_score2);

    // パスの座標と最初の座標を結ぶ。
    path.close();
    
    // 三角形（塗りつぶし）の描画
    canvas.drawPath(path, fillWithBluePaint);
    // 三角形（外線）の描画
    canvas.drawPath(path, outlinePaint);
  }
  

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

//トリミングのための関数(未使用)
class MyClipper extends CustomClipper<Rect> {
  List<Offset> offsets;
  MyClipper(this.offsets);
    Rect getClip(Size size) {
      //最大値と最小値を求める
      List<double> xCoordinates = offsets.map((offset) => offset.dx).toList();
      List<double> yCoordinates = offsets.map((offset) => offset.dy).toList();
      double maxX = xCoordinates.reduce((a, b) => a > b ? a : b);
      double maxY = yCoordinates.reduce((a, b) => a > b ? a : b);
      double minX = xCoordinates.reduce((a, b) => a < b ? a : b);
      double minY = yCoordinates.reduce((a, b) => a < b ? a : b);
      Offset maxoffset = Offset(maxX, maxY);
      Offset minoffset = Offset(minX, minY);
        return Rect.fromPoints(minoffset*0.8/2, maxoffset*1.1/2);//座標
    }

    bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
        return false; // トリミングは常に同じであるため、再クリップを行わない
    }
}

//5角形チャートを描画するための関数
class SquarePainter extends CustomPainter {
  String dir;
  SquarePainter(this.dir);
  @override
  void paint(Canvas canvas, Size size) {
    if(dir=="front"){
      final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
      final rect = Rect.fromLTWH(5, 5, size.width-5, size.height-10);
      canvas.drawRect(rect, paint);
    }
    if(dir=="right"){
      final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
      final rect = Rect.fromLTWH(5, 5, size.width-5, size.height-10);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

//描画用:〇，△，□の描画を行う関数
  String _symbol(int value){
    if (value > 18){
      return "◎";
    }
    else if (value == 0){
      return "×";
    }
    else {
      return "△";
    }
  }

//スコアに応じた文章を返す関数
  String _scoretext(List<int> score){
    //判定項目に一つでも0点があれば
    if (score[1]==0 || score[2]==0 || score[3]==0 || score[4]==0 || score[5]==0){
      return "改善の余地があります！";
    }
    if (100 > score[0] && score[0] >= 80){
      return "あなたは抱っこの達人です！";
    }
    if (80 > score[0] && score[0] >= 70){
      return "抱っこが上手ですね！";
    }
    if (70 > score[0] && score[0] >= 40){
      return "改善の余地があります！";
    }
    if (40 > score[0] && score[0] >= 20){
      return "改善の余地があります！";
    }
    else{
      return "改善の余地があります！";
    }
  }