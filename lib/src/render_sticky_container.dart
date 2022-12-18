// Copyright (c) 2022, crasowas.
//
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'sticky_header_controller.dart';
import 'sticky_header_info.dart';

// The number which the getOffsetToReveal re-calculates until
// the cached value should be settled. This is used if
// [cacheUntilSettle] is true.
const kCalculateCacheUntilSettleCount = 5;

/// RenderObject for StickyContainer widget.
///
/// When the page is scrolled, the [StickyHeaderController] will get the header
/// widget information through callback.
class RenderStickyContainer extends RenderProxyBox {
  StickyHeaderController? _controller;
  double? _pixelsCache;

  int index;
  bool visible;
  double? pixels;
  bool performancePriority;
  int? parentIndex;
  bool overlapParent;
  double? offset;
  bool cacheUntilSettle;
  Widget widget;

  int _cacheCalculatedCount = 0;

  RenderStickyContainer({
    required StickyHeaderController? controller,
    required this.index,
    required this.visible,
    this.pixels,
    required this.performancePriority,
    this.parentIndex,
    required this.overlapParent,
    this.offset,
    required this.cacheUntilSettle,
    required this.widget,
  }) : _controller = controller;

  set controller(StickyHeaderController? newController) {
    if (newController != null && _controller != newController) {
      StickyHeaderController? oldController = _controller;
      _controller = newController;
      oldController?.removeCallback(_callback);
      newController.addCallback(_callback);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller?.addCallback(_callback);
  }

  @override
  void detach() {
    _controller?.removeCallback(_callback);
    super.detach();
  }

  @override
  void performLayout() {
    // Layout header widget.
    final childConstraints = constraints.loosen();
    child?.layout(childConstraints, parentUsesSize: true);
    size = child?.size ?? Size.zero;
  }

  double get _pixels {
    if (pixels != null) {
      return pixels ?? 0.0;
    } else {
      if (_pixelsCache == null ||
          !performancePriority ||
          (cacheUntilSettle &&
              _cacheCalculatedCount <= kCalculateCacheUntilSettleCount)) {
        _cacheCalculatedCount++;
        _pixelsCache = RenderAbstractViewport.of(this)
                .getOffsetToReveal(
                  this,
                  0.0,
                  rect: Rect.fromCenter(
                    center: Offset.zero,
                    width: 1,
                    height: 1,
                  ),
                )
                .offset -
            (offset ?? 0);
      }
      return _pixelsCache ?? 0.0;
    }
  }

  Offset get _offset {
    var controller = _controller;
    if (controller != null) {
      var d = _pixels - controller.currentPixels;
      return controller.isHorizontalAxis ? Offset(d, 0.0) : Offset(0.0, d);
    }
    return Offset.zero;
  }

  int? get _parentIndex =>
      (parentIndex != null && (parentIndex ?? 0) < index) ? parentIndex : null;

  StickyHeaderInfo _callback() => StickyHeaderInfo(
        index: index,
        visible: visible,
        size: size,
        pixels: _pixels,
        offset: _offset,
        parentIndex: _parentIndex,
        overlapParent: overlapParent,
        widget: widget,
      );
}
