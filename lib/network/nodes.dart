import 'dart:async';

import 'package:flutter/widgets.dart';

import 'messages.dart';
import 'network_node.dart';
import 'dart:math' as math;

math.Random _random = math.Random();

// currently this Node has no functionality to send messages outside of its local range
// it can however figure out which nodes are around it
class ConnectionBuildingNode extends NetworkNode{

  /// the ids of the current connected nodes 
  /// 
  /// a value of true means the connection is valid
  /// 
  /// a value of false means there is a chance the connection isn't valid, if no 
  /// connection accepted message is recieved from such a node it is removed
  final Map<int, bool> currentConnections;


  bool _canUpdateConnections = true;
  bool _queueConnectionUpdate = false;

  ConnectionBuildingNode({
    Widget build,
    PositionProvider positionProvider,
    Duration broadcastDuration = const Duration(milliseconds: 750),
    Duration messageDuration = const Duration(milliseconds: 500),
    double signalRange = 64
  }):
    currentConnections = <int, bool>{},
    super(
      build: build,
      positionProvider: positionProvider,
      broadcastDuration: broadcastDuration,
      messageDuration: messageDuration,
      signalRange: signalRange,
    );



  @override
  Iterable<int> get connectedNodes => currentConnections.keys;

  @override
  void recieveMessage(Message message) {
    switch (message.code) {
      case MessageCodes.requestingConnection:
        sendLocalMessage(message.senderId, MessageType.connectionAccepted);
        if(!currentConnections.containsKey(message.senderId)){
          currentConnections[message.senderId] = false;
          updateConnections();
        }
        break;
      case MessageCodes.connectionAccepted:
        currentConnections[message.senderId] = true;
        updateMessagePainter();
        break;
      case MessageCodes.shouldUpdateConnections:
        updateConnections();
    }
  }

  @override
  void updateConnections() {
    if(_canUpdateConnections){
      _queueConnectionUpdate = false;
      _canUpdateConnections = false;
      currentConnections.updateAll((key, value) => false);
      broadcast(MessageType.requestingConnection);
      Timer(broadcastDuration + messageDuration, (){
        currentConnections.removeWhere((key, value) => !value);
        updateMessagePainter();
        _canUpdateConnections = true;
        if(_queueConnectionUpdate){
          updateConnections();
        }
      });
    }else{
      _queueConnectionUpdate = true;
    }
  }

  @override
  void sendMessage<T>(int recieverId, T data) {}



}


class DataPackage<T>{
  final T data;
  final int destination;
  final int id;

  DataPackage({
    this.data, 
    this.destination,
  }): this.id = _random.nextInt(4294967295);
      // this won't be a guaranteed unique id, but using a unique id for messages would 
      // be very difficult to do in real life anyway, and a more sophisticated version 
      // of a random number would likely be used 
}


/// this is probaly the worst but simplest way to send non-local messages
class WaveMessangingNode extends NetworkNode{

  final Iterable<int> connectedNodes = const <int>[];

  final List<int> currentPackages = <int>[];

  @override
  // currently this has the possibilty of an infinite loop
  // I might try to fix this but might not because this method is not practical
  void recieveMessage(Message message) {
    switch (message.code) {
      case MessageCodes.broadcastingPackage:
        DataPackage dataPackage = message.data;
        if(!currentPackages.contains(dataPackage.id)){
          if(dataPackage.destination == this.id){
            broadcast(MessageType.cancleBroadcast, dataPackage.id);
          }else{
            broadcast(message.type, dataPackage);
            currentPackages.add(dataPackage.id);
          }
        }
        break;
      case MessageCodes.cancleBroadcast:
        if(currentPackages.remove(message.data)){
          broadcast(message.type, message.data);
        }
    }
  }

  @override
  void sendMessage<T>(int recieverId, T data){
    broadcast<DataPackage<T>>(
      MessageType.broadcastingPackage,
      DataPackage<T>(
        data: data,
        destination: recieverId
      )
    );
  }

  @override
  void updateConnections() {}
  
}
