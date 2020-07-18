import 'package:flutter/material.dart';


import 'dart:math' as math;

import 'draw_network.dart';
import 'network/network_node.dart';
import 'network/position_providers.dart';




void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Simulation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key,}) : super(key: key);


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MessageData{
  int from;
  int to;
  String data;
}

class _MyHomePageState extends State<MyHomePage> {
  int count = 0;
  int rowLength = 5;
  Network network = Network();
  math.Random rand = math.Random();

  bool tapToPlace = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[

          GestureDetector(
            onTapUp: (details){
              if(tapToPlace){
                PositionProvider positionProvider = rand.nextInt(3) == 2?
                  RandomWalk(
                    position: details.localPosition
                  ): PositionProvider(
                    position: details.localPosition
                  );
                network.add(
                  NetworkNode(
                    positionProvider: positionProvider
                  )
                );
                setState(() {
                  count++;
                });
              }
            },
            child: Container(
              color: Colors.black,
              child: NetworkDisplay(network)
            )
          ),
          
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            onPressed: ()async {
              _MessageData message = await showGeneralDialog<_MessageData>(
                context: context, 
                barrierDismissible: true,
                barrierLabel: "message",
                barrierColor: Colors.black38,
                transitionDuration: Duration(milliseconds: 250),
                pageBuilder: (context, animation1, animation2){

                  _MessageData data = _MessageData();
                  data.from = 0;
                  data.to = 0;
                  data.data = "";

                  return Center(
                    child: SizedBox(
                      width: 300,
                      height: 350,
                      child: Material(
                        type: MaterialType.canvas,
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(

                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("Create Message", style: Theme.of(context).textTheme.headline4,),
                              Text("valid ids are 0 - ${NetworkNode.count - 1}"),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: "to",
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (String s){
                                  try {
                                    data.to = int.parse(s);
                                  } catch (e) {
                                  }
                                },
                              ),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: "from",
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (String s){
                                  try {
                                    data.from = int.parse(s);
                                  } catch (e) {
                                  }
                                },
                              ),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: "message",
                                ),
                                onChanged: (String s){
                                  data.data = s;
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: <Widget>[
                                  RaisedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("cancle"),
                                  ),
                                  RaisedButton(
                                    onPressed: () => Navigator.pop(context, data),
                                    child: Text("send message"),
                                  )
                                ],
                              )
                            ]
                          ),
                        )
                      ),
                    )
                  );
                }
              );

              if(message != null){
                network[message.from].sendMessage<String>(message.to, message.data);
              }
          
            },
            tooltip: "send message",
            child: Icon(Icons.send),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            onPressed: (){
              setState(() {
                tapToPlace = !tapToPlace;
              });
            },
            backgroundColor: tapToPlace? Colors.blue: Colors.grey,
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


