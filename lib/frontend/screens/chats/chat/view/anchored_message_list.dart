import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'message_list_decorations.dart';

class AnchoredMessageList extends StatelessWidget {
  static const Key centerKey = ValueKey('anchored-message-list-center');

  const AnchoredMessageList({
    super.key,
    required this.controller,
    required this.cacheExtent,
    required this.padding,
    required this.epoch,
    required this.itemCount,
    required this.anchorIndex,
    required this.itemBuilder,
    required this.bottomSpacer,
    this.loadingOlder = false,
    this.loadingNewer = false,
    this.physics,
    this.findItemIndex,
  });

  final ScrollController controller;
  final double cacheExtent;
  final EdgeInsets padding;
  final int epoch;
  final int itemCount;
  final int? anchorIndex;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget bottomSpacer;
  final bool loadingOlder;
  final bool loadingNewer;
  final ScrollPhysics? physics;
  final int? Function(Key key)? findItemIndex;

  ChildIndexGetter? _lookup(int? Function(int itemIndex) toChildIndex) {
    final find = findItemIndex;
    if (find == null) return null;
    return (key) {
      final itemIndex = find(key);
      return itemIndex == null ? null : toChildIndex(itemIndex);
    };
  }

  static double anchoredPixels({
    required double alignment,
    required double viewport,
    required double anchorHeight,
  }) => alignment * viewport - viewport + anchorHeight;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      reverse: true,
      physics: physics,
      center: centerKey,
      scrollCacheExtent: ScrollCacheExtent.pixels(cacheExtent),
      slivers: _slivers(),
    );
  }

  List<Widget> _slivers() {
    final anchor = anchorIndex;
    if (anchor == null || anchor < 0 || anchor >= itemCount) {
      return [
        SliverPadding(
          key: centerKey,
          padding: padding,
          sliver: SliverList(
            key: ValueKey(('bottom', epoch)),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) return bottomSpacer;
                if (index > itemCount) {
                  return const MessageListLoadMoreIndicator();
                }
                return itemBuilder(context, itemCount - index);
              },
              childCount: itemCount + 1 + (loadingOlder ? 1 : 0),
              findChildIndexCallback: _lookup((item) => itemCount - item),
            ),
          ),
        ),
      ];
    }

    final newerCount = itemCount - anchor - 1;
    return [
      SliverPadding(
        padding: padding.copyWith(top: 0),
        sliver: SliverList(
          key: ValueKey(('newer', epoch)),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < newerCount) {
                return itemBuilder(context, anchor + 1 + index);
              }
              if (loadingNewer && index == newerCount) {
                return const MessageListLoadMoreIndicator();
              }
              return bottomSpacer;
            },
            childCount: newerCount + (loadingNewer ? 1 : 0) + 1,
            findChildIndexCallback: _lookup(
              (item) => item > anchor ? item - anchor - 1 : null,
            ),
          ),
        ),
      ),
      SliverPadding(
        key: centerKey,
        padding: padding.copyWith(bottom: 0),
        sliver: SliverList(
          key: ValueKey(('older', epoch)),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index > anchor) return const MessageListLoadMoreIndicator();
              return itemBuilder(context, anchor - index);
            },
            childCount: anchor + 1 + (loadingOlder ? 1 : 0),
            findChildIndexCallback: _lookup(
              (item) => item <= anchor ? anchor - item : null,
            ),
          ),
        ),
      ),
    ];
  }
}
