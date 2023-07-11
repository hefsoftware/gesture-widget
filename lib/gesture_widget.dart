library gesture_widget;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';

//import 'package:test_drag/HFGesture.dart';
// kPressTimeout and other constants useful
// https://www.kodeco.com/29002200-creating-custom-gestures-in-flutter
// See for example implementation: ScaleGestureRecognizer
//      final VelocityTracker tracker = _velocityTrackers[event.pointer]!;
//

class GestureAvatar {
  GestureAvatar.absolute(Widget widget, Offset position): _widget=widget, _position=position, _relative=false;
  GestureAvatar.relative(Widget widget, Offset position): _widget=widget, _position=position, _relative=true;
  final Widget _widget;
  final Offset _position;
  final bool _relative;
}

// A widget that is shown in consequence of a gesture
class GestureRawAvatar {
  const GestureRawAvatar(this.widget, this.position);
  final Widget widget;
  final Offset position;
  final bool ignoreFeedbackPointer=true;
  final bool ignoreFeedbackSemantics=true;
}

class GestureAvatarManager {
  GestureAvatarManager(this._recognizer, GestureRawAvatar? avatar) { setAvatar(avatar); }
  //OverlayEntry _createEntry() {
  Widget _build(BuildContext context) { 
    if(avatar!=null) {
      final RenderBox box = _recognizer._overlayState().context.findRenderObject()! as RenderBox;
      final Offset overlayTopLeft = box.localToGlobal(Offset.zero);
      return Positioned(
        left: avatar!.position.dx - overlayTopLeft.dx,
        top: avatar!.position.dy - overlayTopLeft.dy,
        child: IgnorePointer(
          ignoring: avatar!.ignoreFeedbackPointer,
          ignoringSemantics: avatar!.ignoreFeedbackSemantics,
          child: avatar!.widget,
        ),
      );
    }
    else { 
      return const SizedBox.shrink();
    }
  }
  void setAvatar(GestureRawAvatar? newAvatar) {
    if(!identical(avatar, newAvatar)) {
      if(newAvatar==null) {
        clear();
      }
      else if(_overlayEntry==null) {
        _recognizer._overlayState().insert(_overlayEntry=OverlayEntry(builder: _build));
      }
      else {
        _overlayEntry!.markNeedsBuild();
      }
    }
    avatar=newAvatar;
  }
  void clear() {
    if(_overlayEntry!=null) {
      print("CLEAR!");
      _overlayEntry!.remove();
      _overlayEntry=null;
    }
    avatar=null;
  }
  final _GestureRecognizer _recognizer;
  GestureRawAvatar? avatar;
  OverlayEntry? _overlayEntry;
}
/// A callback that will be called when a cursor is added. Callback may return true if interested in updates about this cursor.
/// If the callback return false no further events of this cursor will be returned.
/// We don't know yet if it will be a drag or a tap. 
/// Depending on what happens the following functions may be called afterwards:
/// - HFCursorCancelCallback
/// - HFLongTapCallback
/// - HFTapEndCallback
/// - HFStartDragEvent
mixin EventAvatar {
  void clearAvatar() { _setAvatar(null); }
  void setAvatarRelative(Widget widget, Offset offset) { _setAvatar(GestureAvatar.relative(widget, offset)); }
  void setAvatarAbsolute(Widget widget, Offset offset) { _setAvatar(GestureAvatar.absolute(widget, offset)); }
  void _setAvatar(GestureAvatar? avatar);
}
class PointerStartEvent with EventAvatar {
  PointerStartEvent(this.event); //, this._recognizer);
  int get pointer { return event.pointer; }
  Offset get position { return event.position; }
  Offset get localPosition { return event.localPosition; }
  final PointerDownEvent event;
  GestureAvatar? _avatar;
  @override
  void _setAvatar(GestureAvatar? avatar) { _avatar=avatar; }
  bool _accepted=false;
  Object? _data;
  void accept(Object? data) {  
    _data=data;
    _accepted=true;
  }
}
class _RecognizerEventCore {
  _RecognizerEventCore._(_GestureRecognizerCursor recognizer): _recognizer=recognizer;
  int get pointer { return _recognizer._pointer; } 
  Object? get data { return _recognizer._data; }
  final _GestureRecognizerCursor _recognizer;
}
class _RecognizerEvent extends _RecognizerEventCore {
  _RecognizerEvent._(_GestureRecognizerCursor recognizer): super._(recognizer);
  Offset get position { return _recognizer._startPosition; }
  Offset get localPosition { return _recognizer._startLocalPosition; }
  
}
class TapEndEvent extends _RecognizerEvent {
  TapEndEvent._(_GestureRecognizerCursor recognizer): super._(recognizer);
}
class LongTapEvent extends _RecognizerEvent with EventAvatar {
  LongTapEvent._(_GestureRecognizerCursor recognizer): super._(recognizer);
  @override
  void _setAvatar(GestureAvatar? avatar) { _recognizer._recognizerAvatar=avatar; _recognizer._updateAvatar(_recognizer._lastPosition); }
  void cancel() { _canceled=true; }
  bool _canceled=false;
}
class StartDragEvent extends _RecognizerEvent with EventAvatar {
  StartDragEvent._(_GestureRecognizerCursor recognizer): super._(recognizer);
  @override
  void _setAvatar(GestureAvatar? avatar) { _recognizer._recognizerAvatar=avatar; }
  void accept() {
    _accepted=true;
  }
  void acceptWith(Object? data) {
    _accepted=true;
    _recognizer._data=data;
  }
  bool get accepted { return _accepted; } 
  bool _accepted=false;
}
class DragEvent {
  DragEvent._(_GestureRecognizerCursor recognizer): _recognizer=recognizer;
  int get pointer { return _recognizer._pointer; } 
  Object? get data { return _recognizer._data; }
  Offset get startPosition { return _recognizer._startPosition; }
  Offset get startLocalPosition { return _recognizer._startLocalPosition; }
  Offset get position { return _recognizer._dragPosition!; }
  final _GestureRecognizerCursor _recognizer;
}
class DragUpdateEvent extends DragEvent with EventAvatar {
  DragUpdateEvent._(_GestureRecognizerCursor recognizer, {required this.changedTarget, required this.changedTargetData}): super._(recognizer);
  @override
  void _setAvatar(GestureAvatar? avatar) { _recognizer._recognizerAvatar=avatar; }

  Offset get localPosition { return _recognizer._dragRecognizerPosition!; }
  Offset? get targetPosition { return _recognizer._dragTargetPosition; } 
  Object? get targetData { return _recognizer._targetData; }
  final bool changedTarget;
  final bool changedTargetData;
}
class HFDropEvent extends DragEvent {
  HFDropEvent._(_GestureRecognizerCursor recognizer): super._(recognizer);
  Offset get localPosition { return _recognizer._dragRecognizerPosition!; }
  Offset? get targetPosition { return _recognizer._dragTargetPosition; } 
  Object? get targetData { return _recognizer._targetData; }
}
class HFFlickEvent extends DragEvent {
  HFFlickEvent._(_GestureRecognizerCursor recognizer, this.direction): super._(recognizer);
  Offset get localPosition { return _recognizer._dragRecognizerPosition!; }
  final double direction;
}

class TargetEnterEvent extends DragEvent with EventAvatar {
  TargetEnterEvent._(_GestureRecognizerCursor recognizer): super._(recognizer);
  @override
  void _setAvatar(GestureAvatar? avatar) { _avatar=avatar; }

  void accept() {
    _accepted=true;
  }
  void acceptWith(Object data) { 
    _targetData=data;
    _accepted=true;
  }
  bool _accepted=false;
  Object? _targetData;
  GestureAvatar? _avatar;
}

class TargetUpdateEvent extends DragEvent with EventAvatar {
  TargetUpdateEvent._(_GestureRecognizerCursor recognizer, Object? targetData, this.localPosition): _targetData=targetData, super._(recognizer);
  Offset get recognizerPosition { return _recognizer._dragRecognizerPosition!; }
  Object? get targetData { return _targetData; } 
  @override
  void _setAvatar(GestureAvatar? avatar) { _recognizer._targetAvatar=avatar; }
  void setTargetData(Object? data) { _targetData=data; }
  void cancel() { _canceled=true; }
  bool _canceled=false;
  Object? _targetData;  
  final Offset localPosition;
}

class TargetExitEvent extends _RecognizerEventCore {
  TargetExitEvent._(_GestureRecognizerCursor recognizer, Object? targetData): super._(recognizer);
  Object? get targetData { return _targetData; } 
  Object? _targetData;
}
class TargetDropEvent extends DragEvent {
  TargetDropEvent._(_GestureRecognizerCursor recognizer, Object? targetData): _targetData=targetData, super._(recognizer);
  Object? _targetData;  

  Offset get recognizerPosition { return _recognizer._dragRecognizerPosition!; }
  Offset get localPosition { return _recognizer._dragTargetPosition!; }
  Object? get targetData { return _targetData; } 
  void setTargetData(Object? data) { _targetData=data; }
}

typedef PointerStartCallback = void Function(PointerStartEvent event);
typedef TapEndCallback = void Function(TapEndEvent event);
typedef LongTapCallback = void Function(LongTapEvent event);
typedef StartDragCallback = void Function(StartDragEvent event);
typedef DragUpdateCallback = void Function(DragUpdateEvent event);
typedef DropCallback = void Function(HFDropEvent event);
typedef FlickCallback = void Function(HFFlickEvent event);

typedef TargetEnterCallback = void Function(TargetEnterEvent event);
typedef TargetUpdateCallback = void Function(TargetUpdateEvent event);
typedef TargetDropCallback = void Function(TargetDropEvent event);
typedef TargetExitCallback = void Function(TargetExitEvent event);

/// A cursor got cancelled callback
typedef CursorCancelCallback = void Function(int cursor);
class _GestureRecognizerCursor {
  _GestureRecognizerCursor(this.recognizer, PointerDownEvent event): 
    avatar=GestureAvatarManager(recognizer, null),
    _velocityTracker=VelocityTracker.withKind(event.kind), 
    _lastPosition=event.position,
    _pointer=event.pointer, 
    _startPosition=event.position,
    _startLocalPosition=event.localPosition, 
    _startButtons=event.buttons 
  {
    _longPressTimer = Timer(kLongPressTimeout, () => _onLongPressTimerExpired());
    //avatar.setAvatar(HFGestureRawAvatar(Text("Hello world"), event.position));
  }
  final _GestureRecognizer recognizer;
  final GestureAvatarManager avatar;
  // Timer used to check for a long press
  Timer? _longPressTimer; 
  final VelocityTracker _velocityTracker;
  final int _pointer;
  final Offset _startPosition;
  final Offset _startLocalPosition;
  final int _startButtons;
  Offset _lastPosition;
  Object? _data; // The data that was provided when accepting the pointer down event
  GestureAvatar? _recognizerAvatar; // The avatar for the drag set by the recognizer
  bool _isActive=true; // Keeps track if event is still considered as "alive"
  bool _isDrag=false;
  Offset? _dragPosition; // Will alway be non-null iif _isDrag is true
  GestureTarget? _target; // May be non-null only iif _isDrag is true
  Offset? _dragRecognizerPosition; // Local position in recognizer. Non nulliif _isDrag is true
  Offset? _dragTargetPosition; // Will be always non-null iif _target is not null
  Object? _targetData; // May be be non-null iif _target is not null
  GestureAvatar? _targetAvatar; // The avatar for the drag set by the target
  void _updateAvatar(Offset cursorPos) {
    GestureRawAvatar? raw;
    if(_isActive) {
      GestureAvatar? curTarget;
      if(_targetAvatar!=null){
        print("Getting avatar from target");
        curTarget=_targetAvatar;
      }
      else if(_recognizerAvatar!=null) {
        curTarget=_recognizerAvatar;
      }
      if(curTarget!=null) {
        if(curTarget._relative) {
          raw=GestureRawAvatar(curTarget._widget, curTarget._position+cursorPos);
        }
        else {
          raw=GestureRawAvatar(curTarget._widget, curTarget._position);
        }
      }
    }
    avatar.setAvatar(raw);
  }
  void _stopLongPressTimer() {
    if (_longPressTimer != null) {
      _longPressTimer!.cancel();
      _longPressTimer = null;
    }
  }
  void _onLongPressTimerExpired() {
    _stopLongPressTimer();
    if(!_isDrag && _isActive && recognizer.onLongTap!=null) {
      final ev=LongTapEvent._(this);
      recognizer.onLongTap!(ev);
      if(ev._canceled) { // Callback cancelled.
        _end(triggersEvent: false);
      }
    } 
  }

  void _end({bool triggersEvent=true}) {
    if(_isActive) {
      avatar.clear();
      _stopLongPressTimer();
      _isActive=false;
      if(triggersEvent) {
        if(_isDrag) {
          final endVelocity=_velocityTracker.getVelocity().pixelsPerSecond;
          if(endVelocity.distance>1000 && recognizer.onFlick!=null) { // kMinFlingVelocity is too low triggers the flick even when actually dragging
            if(_target!=null && _target!.onTargetExit!=null) {
              _target!.onTargetExit!(TargetExitEvent._(this, _targetData)); // If we had entered a target notify a fake exit from it
            }
            final ev=HFFlickEvent._(this, endVelocity.direction);
            recognizer.onFlick!(ev);
          }
          else {
            if(_target!=null && _target!.onTargetExit!=null) {
              final ev=TargetDropEvent._(this, _targetData);
              _target!.onTargetDrop!(ev); // Notify the target of the drop
              _targetData=ev._targetData; // Updates the target data (if needed)
            }
            if(recognizer.onDrop!=null) {
              final ev=HFDropEvent._(this);
              recognizer.onDrop!(ev);
            }
          }
        }
        else {
          if(recognizer.onTapEnd!=null) {
            final ev=TapEndEvent._(this);
            recognizer.onTapEnd!(ev);
          }
        }
      }
    }
  }

  void _updateDrag(PointerEvent event) {
    final HitTestResult result = HitTestResult();
    _dragPosition=event.position;
    _dragRecognizerPosition=event.localPosition;
    WidgetsBinding.instance.hitTest(result, event.position);
    GestureTarget? newTarget;
    Object? newTargetData;
    Offset? newTargetPos;
    final currentTargetAvatar=_targetAvatar;
    // Should call old target onTargetExit if target is changed. True in any case except when the old target's update calls cancel() on event
    print("Update drag $_targetAvatar");
    bool callOldTargetExit=true; 
    for (final HitTestEntry entry in result.path) {
      final HitTestTarget target = entry.target;
      if(target is RenderMetaData) {
        final dynamic metaData = target.metaData;
        if (metaData is GestureTarget) {
          final localPos=target.globalToLocal(event.position);
          if(identical(metaData, _target)) {
            print("Update...");
            final ev=TargetUpdateEvent._(this, _targetData, localPos);
            if(metaData.onTargetUpdate!=null) {
              metaData.onTargetUpdate!(ev);
              if(ev._canceled) { // If callback cancelled keep searching for a target
                callOldTargetExit=false;
                continue;
              }
            }
            newTarget=metaData;
            newTargetData=ev._targetData;
            newTargetPos=localPos;
            break;
          }
          else {
            var ev=TargetEnterEvent._(this);
            if(metaData.onTargetEnter!=null) {
              metaData.onTargetEnter!(ev);
            }
            else {
              ev.accept();
            }
            if(ev._accepted) {
              _targetAvatar=ev._avatar; // Replace target avatar, we will restore it if onTargetUpdate will cancel
              print("New target avatar $_targetAvatar");
              if(metaData.onTargetUpdate!=null) { // If target accepted the drag we directly call update
                print("New target avatar2 $_targetAvatar");
                final ev2=TargetUpdateEvent._(this, ev._targetData, localPos);
                metaData.onTargetUpdate!(ev2);
                print("New target avatar3 $_targetAvatar");
                if(ev2._canceled) {
                  _targetAvatar=currentTargetAvatar;
                  print("Cancelled after enter's update");
                }
                else {
                  newTarget=metaData;
                  newTargetData=ev2._targetData;
                  newTargetPos=localPos;
                  print("New target avatar4 $_targetAvatar");
                  print("Accepted after enter's update $newTarget");
                  break;
                }
              }
              else {
                print("Accepted");
                //_replaceCurrentDragTarget(metaData);
                newTarget=metaData;
                newTargetData=ev._targetData;
                newTargetPos=localPos;
                break;
              }
            }
          }
        }
      }
    }
    print("New target avatar5 $_targetAvatar $newTarget");
    bool changedTarget=false, changedTargetData=false;
    if(!identical(_target, newTarget)) {
      changedTarget=changedTargetData=true;
      if(_target!=null && _target!.onTargetExit!=null && callOldTargetExit) {
        _target!.onTargetExit!(TargetExitEvent._(this, _targetData));
      }
    }
    _target=newTarget;
    if(newTargetData!=_targetData) {
      changedTargetData=true;
    }
    _targetData=newTargetData;
    _dragTargetPosition=newTargetPos;
    if(_target==null) {
      print("Clearing target avatar");
      _targetAvatar=null;
    }
    if(recognizer.onDragUpdate!=null) {
      recognizer.onDragUpdate!(DragUpdateEvent._(this, changedTarget: changedTarget, changedTargetData: changedTargetData));
      //avatar.setAvatar(HFGestureRawAvatar(Text("Hello world"), event.position));
    }
  }
  void handleEvent(PointerEvent event) {
    _lastPosition=event.position;
    if (!event.synthesized && _isActive) {
      if (event is PointerMoveEvent) {
        _velocityTracker.addPosition(event.timeStamp, event.position);
        if(event.buttons!=_startButtons) {
          _end();
        }
        else if(_isDrag) {
          _updateDrag(event);
        }
        else {
          final slop=computeHitSlop(event.kind, null);
          var delta=event.position-_startPosition;
          if(delta.distance>slop) {
            _stopLongPressTimer();
            final ev=StartDragEvent._(this);
            if(recognizer.onStartDrag!=null) {
              recognizer.onStartDrag!(ev);
            }
            else {
              ev.accept();
            }
            if(ev.accepted) {
              _isDrag=true;
              _updateDrag(event);
            }
            else {
              _end(triggersEvent: false); // Event was not accepted
            }
          }
        }
      }
      else if (event is PointerUpEvent) {
        _velocityTracker.addPosition(event.timeStamp, event.position);
        if(_isDrag) {
          _updateDrag(event); //Performs a last update (maybe position was changed)
        }
        _end(); // Finalizes the event
      }      
    }
    _updateAvatar(event.position);
  }
}

class _GestureRecognizer extends OneSequenceGestureRecognizer {
  _GestureRecognizer(this._getOverlayState, {
    this.onCursorDown,
    this.onTapEnd,
    this.onLongTap,
    this.onStartDrag,
    this.onDragUpdate,
    this.onDrop,
    this.onFlick
  });
  final OverlayState Function() _getOverlayState;
  final PointerStartCallback? onCursorDown;
  final TapEndCallback? onTapEnd;
  final LongTapCallback? onLongTap;
  final StartDragCallback? onStartDrag;
  final DragUpdateCallback? onDragUpdate;
  final DropCallback? onDrop;
  final FlickCallback? onFlick;
  final Map<int, _GestureRecognizerCursor> _cursors = <int, _GestureRecognizerCursor>{};
  OverlayState? _overlayStateValue;
  OverlayState _overlayState() { 
    _overlayStateValue??=_getOverlayState();
    return _overlayStateValue!;
  }
  //_HFGesture2RecognizerCursor _getOrCreateCursor(PointerDownEvent event) {
  //  _HFGesture2RecognizerCursor? cursor;
  //  if(_cursors.containsKey(event.pointer)) {
  //    cursor=_cursors[event.pointer];
  //  }
  //  else {
  //    cursor=_HFGesture2RecognizerCursor(this, event);
  //    _cursors[event.pointer] = cursor;
  //  }
  //  return cursor!;
  //}


  @override
  void addAllowedPointer(PointerDownEvent event) {
    print("Event");
    final ev=PointerStartEvent(event);
    if(onCursorDown!=null) {
      print("Got on cursor down");
      onCursorDown!(ev);
    }
    else {

    }
    if(ev._accepted) {
      final cursor=_GestureRecognizerCursor(this, event);
      _cursors[event.pointer] = cursor;
      //_acceptPointer(event);
      //final cursor=_recognizer._acceptPointer(event);
      cursor._data=ev._data;
      cursor._recognizerAvatar=ev._avatar;
      cursor._updateAvatar(event.position);
      print("Accepted pointer ${event.pointer}");
      super.addAllowedPointer(event);
      resolvePointer(event.pointer, GestureDisposition.accepted);
    }
  }

  @override
  void acceptGesture(int pointer) {
    //print("Recognizer accept gesture ${pointer}");
    print("Accept gesture ${pointer}");
  }

  @override dispose() {
    if(_cursors.isNotEmpty)
      print("Disposing a recognizer with non-empty events");
    // Clears the active cursors
    for(var cursor in _cursors.values) {
      cursor._end();
    }
    _cursors.clear();
    super.dispose();
  }

  @override
  String get debugDescription {
    return "HFGesture2Recognizer";
  }

  @override
  void rejectGesture(int pointer) {
    // TODO ACTUALLY AN ACCEPTED POINTER SHOULD NEVER BE REJECTED. BUT WHATEVER.
    print("Reject gesture ${pointer}");
    _removePointer(pointer);
  }

  void _removePointer(int pointer) {
    if(_cursors.containsKey(pointer)) {
      final cursor=_cursors[pointer]!;
      cursor._end();
      _cursors.remove(pointer);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if(_cursors.containsKey(event.pointer)) {
      //print("Event of managed cursor");
      final cursor=_cursors[event.pointer]!;
      if(cursor._isActive) { // Cursor may have been deactivated elsewhere (e.g. long press timer)
        cursor.handleEvent(event);
      }
      if(!cursor._isActive) {
        print("Event is not any more active ${event.pointer}");
        _cursors.remove(event.pointer);
      }
    }
  }
  
  @override
  void didStopTrackingLastPointer(int pointer) {
    print("Did stop tracking last pointer");
  }
}

class GestureTarget extends StatefulWidget {
  const GestureTarget({super.key, required this.child, this.onTargetEnter, this.onTargetExit, this.onTargetUpdate, this.onTargetDrop});
  final Widget? child;
  final TargetEnterCallback? onTargetEnter;
  final TargetUpdateCallback? onTargetUpdate;
  final TargetExitCallback? onTargetExit;
  final TargetDropCallback? onTargetDrop;
  @override
  State<GestureTarget> createState() => _GestureTargetState();
}

class _GestureTargetState extends State<GestureTarget> {
  @override
  Widget build(BuildContext context) {
    print("Build: metadata is ${widget}");
    return MetaData(metaData: widget, child:widget.child);    
  }
}


class GestureWidget extends StatefulWidget {
  const GestureWidget({super.key, required this.child, this.onCursorDown, this.onTapEnd, this.onLongTap, this.onStartDrag, this.onDragUpdate, this.onDrop, this.onFlick, this.rootOverlay=false});
  final Widget? child;
  final PointerStartCallback? onCursorDown;
  final TapEndCallback? onTapEnd;
  final LongTapCallback? onLongTap;
  final StartDragCallback? onStartDrag;
  final DragUpdateCallback? onDragUpdate;
  final DropCallback? onDrop;
  final FlickCallback? onFlick;
  final bool rootOverlay;
  @override
  State<GestureWidget> createState() => _GestureWidgetState();
}

class _GestureWidgetState extends State<GestureWidget> {
  //OverlayState? _overlayState;
  Widget build(BuildContext context) {
    ScaleGestureRecognizer;
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        _GestureRecognizer: GestureRecognizerFactoryWithHandlers<_GestureRecognizer>(
          () => _GestureRecognizer(
            () { return Overlay.of(context, debugRequiredFor: widget, rootOverlay: widget.rootOverlay); },
            onCursorDown: widget.onCursorDown,
            onTapEnd: widget.onTapEnd,
            onLongTap: widget.onLongTap,
            onStartDrag: widget.onStartDrag,
            onDragUpdate: widget.onDragUpdate,
            onDrop: widget.onDrop,
            onFlick: widget.onFlick

          ),
          (instance) {},
        )
      },
      child: widget.child,
    );
  }
}

