# Network Simulation Project
This is a project I'm doing to experiment with the basics of networks. The end goal 
is to have nodes that are moving around, updating the network, and able to send 
messages effieciently to other nodes. In order to better see what I'm doing I've set
up a visual system that shows valid connections between nodes and messages being sent.
In order for this to be a good learning expierence I've also set myself a few
constraints when it comes to using nodes and I've tried to reflect that in the code.

# Node Constraints
- Nodes don't have any information about the network as a whole. They only have information about themsleves
- Nodes only have a certain range in which they can send a message
    - a Node can attempt to send a message outside of their range but will fail if a third Node isn't used a bridge
- While nodes do provide a position for rendering purposes they do not know thier own position

# Network Constraints
- The network structure is not automatically known, it needs to be built
- The network is dynamic not only can it change but it is expected to



