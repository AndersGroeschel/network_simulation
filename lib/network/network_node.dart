import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../draw_network.dart';
import 'messages.dart';

class Network{
  final Map<int, NetworkNode> _nodes;

  Network():
    _nodes = <int, NetworkNode>{};


  void add(NetworkNode node){
    _nodes[node.id] = node;
    node._network = this;
  }

  Iterable<NetworkNode> get nodes => _nodes.values;

  NetworkNode operator [] (int id) => _nodes[id];

  void _broadcastMessage(NetworkNode device, Message message){
    double signalSquared = device.signalRange * device.signalRange;

    for(NetworkNode reciever in _nodes.values){
      if(reciever.id == device.id ){
        continue;
      }

      Offset dist = device._positionProvider.position - reciever._positionProvider.position;
      if(dist.distanceSquared < signalSquared){
        Duration travelTime = device.broadcastDuration * (dist.distance/device.signalRange);
        Timer(travelTime, (){
          reciever.recieveMessage(message);
        });
      }
    }
  }

  void _sendLocalMessage(NetworkNode device, int recievingDevice, Message message){
    NetworkNode reciever = _nodes[recievingDevice];
    reciever.recieveMessage(message);
  }


}




class PositionProvider{
  Offset position;
  NetworkNode node;
  VoidCallback markNetworkNeedsLayout;

  PositionProvider({
    this.position = Offset.zero
  });

  void initialize(){}

  TickerProvider get vsync => node._vsync;

  void updateRenderer(){
    markNetworkNeedsLayout?.call();
    node.updateMessagePainter?.call();
  }


}

class _LocalMessageData{
  final Color color;
  final Offset endpoint;

  _LocalMessageData(this.color, this.endpoint);
}

abstract class NetworkNode{

  static int _count = 0;

  static int get count => _count;

  static int get newId=> _count++;

  Network _network;

  TickerProvider _vsync;

  final Map<AnimationController, Color> _currentBroadcasts;
  VoidCallback updateBroadcastPainter;
  final Map<AnimationController, _LocalMessageData> _currentMessages;
  VoidCallback updateMessagePainter;

  final PositionProvider _positionProvider;
  final int id;

  final Duration broadcastDuration;
  final Duration messageDuration;

  final Widget _build;
  final double signalRange;

  NetworkNode({
    Widget build,
    PositionProvider positionProvider,
    this.broadcastDuration = const Duration(milliseconds: 750),
    this.messageDuration = const Duration(milliseconds: 500),
    this.signalRange = 64
  }): id = newId,
      _build = build?? Container(
        height: 12,
        width: 12,
        decoration: ShapeDecoration(
          shape: CircleBorder(),
          color: Colors.white
        )
      ),
      _positionProvider = positionProvider,
      _currentBroadcasts = <AnimationController, Color>{},
      _currentMessages = <AnimationController, _LocalMessageData>{}{
        this._positionProvider?.node = this;
      }

  Iterable<int> get connectedNodes;


  void broadcast<T>(MessageType type, [T data]) async {
    final Message<T> message = Message<T>(
      type: type,
      senderId: this.id,
      data: data
    );
    final AnimationController broadcast = AnimationController(vsync: _vsync, duration: broadcastDuration);
    _currentBroadcasts[broadcast] = message.type.color;
    updateBroadcastPainter?.call();
    
    _network._broadcastMessage(this, message);
    await broadcast.forward(from: 0);
    _currentBroadcasts.remove(broadcast);
    updateBroadcastPainter?.call();
    broadcast.dispose();
  }

  void sendLocalMessage<T>(int deviceId, MessageType type, [T data]) async {
    Offset pos = _network[deviceId]._positionProvider.position;
    final Offset diff = pos - _positionProvider.position;
    final double dist = diff.distance;
    bool send = true;
    double mult = dist/signalRange;

    final Message<T> message = Message<T>(
      senderId: this.id,
      data: data,
      type: type
    );

    if(dist > signalRange){
      send = false;
      pos = _positionProvider.position + diff/mult;
      mult = 1;
    }
    

    AnimationController messageController = AnimationController(vsync: _vsync, duration: messageDuration * mult);

    final _LocalMessageData messageData = _LocalMessageData(
      type.color,
      pos
    );
    _currentMessages[messageController] = messageData;
    updateMessagePainter?.call();

    await messageController.forward(from: 0);
    if(send){
      _network._sendLocalMessage(this, deviceId, message);
    }
    _currentMessages.remove(messageController);
    updateMessagePainter?.call();
    messageController.dispose();
  }

  void recieveMessage(Message message);

  void updateConnections();

  void sendMessage<T>(int recieverId, T data);

  Widget get build => _NodeBuild(
    node: this,
    network: _network,
    child: _build
  );

}




// the remainder of this document has to deal with rendering connections and messages



class NodeWidget extends ParentDataWidget<NodeParentData>{

  final NetworkNode node;

  NodeWidget({
    @required this.node, 
  }): super(child: node.build);

  

  @override
  void applyParentData(RenderObject renderObject) {
    ParentData data = renderObject.parentData;
    if(data is NodeParentData){
      data.nodePosition = node._positionProvider.position; 
      node._positionProvider?.markNetworkNeedsLayout = (renderObject.parent as RenderBox).markNeedsLayout;
    }
  }
  

  @override
  Type get debugTypicalAncestorWidgetClass => RenderNetworkDisplay;
  
}



class _NodeBuild extends StatefulWidget{

  final NetworkNode node;
  final Network network;
  final Widget child;

  const _NodeBuild({
    Key key, 
    this.node, 
    this.network,
    this.child
  }) : super(key: key);

  

  @override
  State<StatefulWidget> createState() => _NodeBuildState();
  
}

class _NodeBuildState extends State<_NodeBuild> with TickerProviderStateMixin{
  @override
  void initState() {
    widget.node._vsync = this;
    widget.node._positionProvider.initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _BroadcastWave(
      node: widget.node,
      child: _MessageChannels(
        network: widget.network,
        node: widget.node,
        child: widget.child
      ),
    );
  }
}



class _BroadcastWave extends StatefulWidget{

  final NetworkNode node;
  final Widget child;

  const _BroadcastWave({
    Key key, 
    this.node, 
    this.child
  }) : super(key: key);

  @override
  _BroadcastWaveState createState() => _BroadcastWaveState();
}

class _BroadcastWaveState extends State<_BroadcastWave> {

  @override
  void initState() {
    widget.node.updateBroadcastPainter = () => setState((){});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for(MapEntry<AnimationController, Color> controller in widget.node._currentBroadcasts.entries)
          CustomPaint(
            size: Size.fromRadius(widget.node.signalRange),
            painter: BroadcastPainter(
              controller.key,
              controller.value
            ),
          ),
        widget.child
      ]
    );
  }
}

class BroadcastPainter extends CustomPainter{

  final Animation<double> animation;
  final Color color;
  final Paint p;

  BroadcastPainter(
    this.animation, 
    this.color
  ):
    p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
    super(repaint: animation);


  @override
  void paint(Canvas canvas, Size size) {
    double rad = size.shortestSide *0.5 * animation.value;
    p.color = color.withAlpha((255 - 255 * animation.value).toInt());

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), rad, p);

  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
  
}



class _MessageChannels extends StatefulWidget{
  final NetworkNode node;
  final Network network;
  final Widget child;

  const _MessageChannels({
    Key key, 
    this.node, 
    this.network,
    this.child
  }) : super(key: key);

  @override
  _MessageChannelsState createState() => _MessageChannelsState();
}

class _MessageChannelsState extends State<_MessageChannels> {

  double signalRangeSquared = 0;

  @override
  void initState() {
    widget.node.updateMessagePainter = () => setState((){});
    widget.node.updateConnections();
    super.initState();
  }

  Offset calcEndpoint(Offset devicePosition){

    Offset endpoint = devicePosition - widget.node._positionProvider.position;

    if(endpoint.distanceSquared > signalRangeSquared){
      endpoint = (endpoint/endpoint.distance) * widget.node.signalRange;
    }
    return endpoint;
  }

  @override
  Widget build(BuildContext context) {
    signalRangeSquared = widget.node.signalRange;
    signalRangeSquared *= signalRangeSquared;

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size.fromRadius(widget.node.signalRange),
          painter: ChannelPainter(widget.node.connectedNodes.map((id) => widget.network[id]._positionProvider.position), widget.node._positionProvider.position),
        ),
        for(MapEntry<AnimationController, _LocalMessageData> controller in widget.node._currentMessages.entries)
          CustomPaint(
            size: Size.fromRadius(widget.node.signalRange),
            painter: MessagePainter(
              animation: CurvedAnimation(
                parent: controller.key, 
                curve: Curves.easeInOut
              ),
              endPoint: calcEndpoint(controller.value.endpoint),
              paint: Paint()
                ..color = controller.value.color
            )
          ),
        
        widget.child

      ]
    );
  }
}

class ChannelPainter extends CustomPainter{

  final Iterable<Offset> points;
  final Offset start;

  ChannelPainter(this.points, this.start);

  @override
  void paint(Canvas canvas, Size size) {
    Offset c = Offset(size.width * 0.5, size.height * 0.5);
    Iterable<Offset> ends = points.map<Offset>((e) => e + c - start);

    Paint paint = Paint()
      ..color = Color.fromARGB(150, 255, 255, 255)
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke;

    for(Offset endPoint in ends){
      canvas.drawLine(c, endPoint, paint);
    }
  }
  
  @override
  bool shouldRepaint(ChannelPainter oldDelegate){
    if(oldDelegate.start != start){
      return true;
    }
    
    if(points != oldDelegate.points){
      return true;
    }

    return false;
  }
  
}

class MessagePainter extends CustomPainter{
  final Animation<double> animation;
  final Offset endPoint;
  final Paint p;

  MessagePainter({
    this.animation,
    this.endPoint,
    Paint paint
  }): 
    this.p = paint?? Paint()
      ..color = Colors.amber,
    super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(
      size.width* 0.5, 
      size.height * 0.5
    );
    Offset move = endPoint;

    Offset point = center + move*animation.value;

    canvas.drawCircle(point, 4, p);

  }
  
  @override
  bool shouldRepaint(MessagePainter oldDelegate) => false;

}




