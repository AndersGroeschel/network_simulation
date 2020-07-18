

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mesh_network_simulation/network/network_node.dart';

import 'dart:math' as math;

import 'messages.dart';

math.Random _rand = math.Random();

class AnimatedPosition extends PositionProvider{
  Animation<Offset> positionAnimation;
  final Duration defaultDuration;
  AnimationController controller;

  AnimatedPosition({
    Offset position = Offset.zero,
    this.defaultDuration = const Duration(seconds: 2)
  }): super(position: position);

  @override
  void initialize(){
    controller = AnimationController(vsync: vsync);
    controller.addListener(updateRenderer);
    positionAnimation = Tween(begin: position, end: position).animate(controller);
  }

  @override
  Offset get position => positionAnimation?.value?? super.position;

  Future<void> setDestination(Offset destination, {Duration duration}) async{
    
    positionAnimation = Tween<Offset>(
      begin: position,
      end: destination
    ).animate(CurvedAnimation(
      parent: controller, 
      curve: Curves.easeInOut
    ));
    controller.duration = duration?? defaultDuration;
    await controller.forward(from: 0);
  }

}

mixin DefaultWalk on AnimatedPosition{

  bool shouldStep = true;

  void step(){
    if(shouldStep){
      Offset diff = Offset(
        (_rand.nextDouble() * 100) - 50,
        (_rand.nextDouble() * 100) - 50
      );
      setDestination(position + diff).then((value) => step());
    }
  }

  void stopWalk(){
    shouldStep = false;
  }

  @override
  void initialize() {
    super.initialize();
    step();
  }


}

mixin ConnectionUpdater on PositionProvider{
  Timer updateTimer;
  Duration waitTime = Duration(milliseconds: 200);
  bool canUpdate = true;
  bool updateConnections = true;

  @override
  void updateRenderer() {
    super.updateRenderer();
    broadcastPositionUpdate();
    if(updateConnections){
      updateConnections = false;
      node.updateConnections();
      Timer(waitTime * 10, (){
        updateConnections = true;
      });
    }
  }


  
  void broadcastPositionUpdate() {
    if(canUpdate){
      canUpdate = false;
      node.broadcast(MessageType.shouldUpdateConnections);
      updateTimer = Timer(waitTime, (){
        canUpdate = true;
      });
    }
  }
  
}

class RandomWalk extends AnimatedPosition with DefaultWalk, ConnectionUpdater{
  RandomWalk({
    Offset position,
    Duration defaultDuration = const Duration(seconds: 2)
  }): super(position: position, defaultDuration: defaultDuration);
}

