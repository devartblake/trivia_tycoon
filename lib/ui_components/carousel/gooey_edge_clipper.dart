import 'package:flutter/material.dart';
import 'gooey_edge.dart';

class GooeyEdgeClipper extends CustomClipper<Path> {
  GooeyEdge edge;
  double margin;

  // Store a flag to track if the clipper needs to be updated
  bool _needsReclip = true;

  GooeyEdgeClipper(this.edge, {this.margin = 0.0}) : super();

  @override
  Path getClip(Size size) {
    _needsReclip = false; // Reset flag when the clip is requested
    return edge.buildPath(size, margin: margin);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    // Check if the `GooeyEdge` object has changed
    if (_needsReclip) {
      return true;
    }

    // For further optimization, compare the relevant properties of the edge
    GooeyEdgeClipper old = oldClipper as GooeyEdgeClipper;

    // Check for any changes in the edge or margin (you can add more conditions as needed)
    if (edge != old.edge || margin != old.margin) {
      return true;
    }
    return false; // No changes, so don't reclip
  }
}
