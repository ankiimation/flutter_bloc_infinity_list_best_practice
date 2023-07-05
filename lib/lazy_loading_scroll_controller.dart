import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LazyLoadingScrollController extends ScrollController {
  final double threshold;
  final VoidCallback onLoadmore;

  LazyLoadingScrollController({
    this.threshold = 500.0,
    required this.onLoadmore,
  });

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    position.addListener(_scrollListener);
    // onLoadmore();
    _scrollListener();
  }

  @override
  void detach(ScrollPosition position) {
    position.removeListener(_scrollListener);
    super.detach(position);
  }

  void _scrollListener() {
    try {
      if (positions.isEmpty) {
        onLoadmore();
        return;
      }
      if (!position.hasPixels) {
        onLoadmore();
        return;
      }
      if (position.userScrollDirection == ScrollDirection.reverse &&
          position.maxScrollExtent - position.pixels <= threshold) {
        onLoadmore();
      }
    } catch (e) {
      log('LazyLoadingScrollController $e');
      onLoadmore();
      return;
    }
  }
}
