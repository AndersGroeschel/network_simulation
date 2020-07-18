import 'package:flutter/material.dart';

abstract class MessageCodes{
  static const int allGood = 0;

  static const int connections = 100;
  static const int requestingConnection = 101;
  static const int connectionAccepted = 102;
  static const int shouldUpdateConnections = 103;

  static const int dataPackage = 200;
  static const int broadcastingPackage = 201;
  static const int cancleBroadcast = 202;

}

class MessageType{

  static const MessageType allGood = MessageType(code: MessageCodes.allGood, color: Colors.white);

  static const MessageType requestingConnection = MessageType(code: MessageCodes.requestingConnection, color: Colors.yellow);
  static const MessageType connectionAccepted = MessageType(code: MessageCodes.connectionAccepted, color: Colors.amber);
  static const MessageType shouldUpdateConnections = MessageType(code: MessageCodes.shouldUpdateConnections, color: Colors.teal);

  static const MessageType dataPackage = MessageType(code: MessageCodes.dataPackage, color: Colors.blue);
  static const MessageType broadcastingPackage = MessageType(code: MessageCodes.broadcastingPackage, color: Colors.blue);
  static const MessageType cancleBroadcast = MessageType(code: MessageCodes.cancleBroadcast, color: Colors.red);
  
  final Color color;
  final int code;

  const MessageType({
    this.code,
    this.color
  });
  
}

class Message<T>{

  final T data;
  final MessageType type;
  final int senderId;

  const Message({
    this.senderId,
    this.data, 
    this.type,
  });

  int get code => type.code;

}

