

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'network/network_node.dart';

class NetworkDisplay extends MultiChildRenderObjectWidget{
  final Network network;

  NetworkDisplay(this.network): super(
    children: network.nodes.map<Widget>((element){
      return NodeWidget(node: element);
    }).toList()
  );



  @override
  RenderObject createRenderObject(BuildContext context) => RenderNetworkDisplay();
}

class NodeParentData extends ContainerBoxParentData<RenderBox>{
  Offset nodePosition;
}

class RenderNetworkDisplay extends RenderBox 
      with ContainerRenderObjectMixin<RenderBox, NodeParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, NodeParentData> {

  // this is here so that if I want to make the screen dragable or something like that I easily can
  Matrix4 transform = Matrix4.identity();


  @override
  void setupParentData(RenderObject child) {
    if(child.parentData is! NodeParentData){
      child.parentData = NodeParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    RenderBox child = firstChild;

    while(child != null){
      NodeParentData parentData = child.parentData;
      child.layout(constraints, parentUsesSize: true);
      parentData.offset = parentData.nodePosition - Offset(
        child.size.width * 0.5, 
        child.size.height * 0.5
      );
      child = parentData.nextSibling;
    }

  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return result.addWithPaintTransform(
      transform: transform, 
      position: position, 
      hitTest: (result, position) => defaultHitTestChildren(result, position: position)
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    Offset origin = MatrixUtils.transformPoint(transform, offset);
    defaultPaint(context, origin);
  }


}

