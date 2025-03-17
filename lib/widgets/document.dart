import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sourcemanv3/2d_scroll_area.dart';
import 'package:sourcemanv3/config.dart';
import 'package:sourcemanv3/datatype.dart';
import 'package:sourcemanv3/event.dart';
import 'package:sourcemanv3/managers/cursor_manager.dart';
import 'package:sourcemanv3/managers/doc_manager.dart';
import 'package:sourcemanv3/managers/env_var_manager.dart';
import 'package:sourcemanv3/managers/profile_manager.dart';
import 'package:flutter/material.dart';
import 'package:sourcemanv3/widgets/line.dart';


class DocumentWidget extends StatefulWidget {
  final String documentPath;
  final EnvVarManager envVarManager;
  final ProfileManager profileManager;
  final CursorManager cursorManager;
  final EventManager eventManager;
  const DocumentWidget({
    super.key,
    required this.documentPath,
    required this.envVarManager,
    required this.profileManager,
    required this.cursorManager,
    required this.eventManager,
  });

  @override
  State<StatefulWidget> createState() => _DocumentWidgetState();
}

class _DocumentWidgetState extends State<DocumentWidget> {
  DocManager docManager = DocManager();
  Doc document = Doc(path: "", lines: []);
  bool loading = true;
  List<LineController> lineControllers = [];
  Set<int> highlightedLines = {};
  final GlobalKey _columnKey = GlobalKey();
  late FocusNode focusNode;
  final ScrollController scroll1 = ScrollController();
  final ScrollController scroll2 = ScrollController();
  List<Widget> lines = [];
  var scrollAreaControl = ScrollAreaControl();

  @override
  void initState() {

    super.initState();

    docManager.loadDocFromPath(widget.profileManager, widget.envVarManager).then((doc) {
      print("load ${widget.documentPath}");
      if (!mounted) {
        return;
      }
      setState(() {
        loading = false;
        if (doc != null) {
          document = doc;
        }
      });
    });
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: Icon(Icons.pending_actions));
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              supportedDevices: const {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              child: MouseRegion(
                cursor: WidgetStateMouseCursor.textable,
                child: Focus(
                  focusNode: focusNode,
                  autofocus: true,
                  child: TwoDiScrollAreaWidget(
                    doc: document, 
                    envVarManager: widget.envVarManager, 
                    eventManager: widget.eventManager,
                    controller: scrollAreaControl,
                  ),
                  onKeyEvent: (FocusNode node, KeyEvent event) {
                    if (event.runtimeType == KeyDownEvent) {
                      _handleKeyDownEvent(event);
                    } else if (event.runtimeType == KeyRepeatEvent) {
                      _handleKeyDownEvent(event);
                    } else if (event.runtimeType == KeyUpEvent) {
                      
                    }
                    return KeyEventResult.handled;
                  },
                ),
              ),
              onPanUpdate: (DragUpdateDetails details) {
                if (widget.cursorManager.dragging) {
                  displayCursor(details.localPosition);
                  widget.cursorManager.setSelectEnd();
                  highlightSelections();
                }
              },
              onPanDown: (DragDownDetails details) {
                widget.cursorManager.dragging = true;
                displayCursor(details.localPosition);
                widget.cursorManager.setSelectStart();
              },
              onPanEnd: (DragEndDetails details) {
                widget.cursorManager.dragging = false;
              },
              onTapDown:(TapDownDetails details) {
                focusNode.requestFocus();
              },
              onTapUp: (TapUpDetails details) {
                widget.cursorManager.dragging = false;
                resetSelections();
              },
            )
          ),
        ),
      ]
    
    );
  }


  void highlightSelections() {
    resetSelections();
    int startLine = widget.cursorManager.selectStartLine;
    int endLine = widget.cursorManager.selectEndLine;
    
    int startIdx = widget.cursorManager.selectStart;
    int endIdx = widget.cursorManager.selectEnd;
    if (startLine > endLine) {
      startLine = endLine;
      endLine = widget.cursorManager.selectStartLine;
      startIdx = endIdx;
      endIdx = widget.cursorManager.selectStart;
    }
    if (endLine == startLine && endLine < document.lines.length) {
      if (startIdx > endIdx) {
        startIdx = endIdx;
        endIdx = widget.cursorManager.selectStart;
      }
      scrollAreaControl.setHighlight(startLine, startIdx, endIdx);
      highlightedLines.add(startLine);
    } else {
      for (int i = startLine; i <= endLine; i++) {
        if (i == startLine && startLine < document.lines.length) {
          scrollAreaControl.setHighlight(i, startIdx, -1);
          highlightedLines.add(i);
        } else if (i == endLine && endLine < document.lines.length) {
          scrollAreaControl.setHighlight(i, 0, -1);
          highlightedLines.add(i);
        } else if (i < document.lines.length){
          scrollAreaControl.setHighlight(i, 0, -1);
          highlightedLines.add(i);
        }
      }
    }
  }

  void resetSelections() {
    for (int i in highlightedLines) {
      if (i < document.lines.length) {
        scrollAreaControl.setHighlight(i, 0, 0);
      }
    }
  }

  void displayCursor(Offset localPosition) {
    int lineIdx = scrollAreaControl.mapCursorToLineIndex(localPosition.dy);
    if (lineIdx < document.lines.length) {
      int runeIdx = scrollAreaControl.displayCursor(lineIdx, localPosition.dx, null);
      widget.cursorManager.lineIndex = lineIdx;
      widget.cursorManager.runeIndex = runeIdx;
    } else {
      int runeIdx = scrollAreaControl.displayCursor(lineIdx, localPosition.dx, null);
      widget.cursorManager.lineIndex = lineIdx;
      widget.cursorManager.runeIndex = runeIdx;
    }
  }

  void _handleKeyDownEvent(KeyEvent event) {
    String key = event.logicalKey.keyLabel;
    switch(key) {
      case 'Backspace':
        int cursorX = widget.cursorManager.runeIndex;
        int cursorY = widget.cursorManager.lineIndex;
        if (cursorX > 0) {
          scrollAreaControl.removeChar(cursorY, cursorX);
          widget.cursorManager.runeIndex -= 1;
          scrollAreaControl.displayCursorAt(cursorY, widget.cursorManager.runeIndex);
          List<Rune> runes = scrollAreaControl.getRunes(cursorY, 0, lineControllers[cursorY].getRunesLength());
          var strBuffer = StringBuffer();
          for (var rune in runes) {
            if (rune.isVar) {
              strBuffer.write(rune.varKey);
            } else {
              strBuffer.write(rune.ch);
            }
          }
        }
        break;
      case 'Home':
        // TODO pressing home should jump to first none space character
        int cursorY = widget.cursorManager.lineIndex;
        scrollAreaControl.displayCursor(cursorY, 0, false);
        widget.cursorManager.runeIndex = 0;
        resetSelections(); // TODO this reset selection hides cursor as well...
        break;
      case 'End':
        int cursorY = widget.cursorManager.lineIndex;
        int index = scrollAreaControl.displayCursor(cursorY, 0, true);
        widget.cursorManager.runeIndex = index - 1;
        resetSelections();
        break;
      case 'Enter':
        int cursorY = widget.cursorManager.lineIndex;
        int cursorX = widget.cursorManager.runeIndex;
        // List<Rune> runes = lineControllers[cursorY].getRunes(0, lineControllers[cursorY].getRunesLength());
        List<Rune> runes = scrollAreaControl.getRunes(cursorY, 0, scrollAreaControl.getRunesLength(cursorY));
        List<Rune> firstPart = runes.sublist(0, cursorX);
        List<Rune> secondPart = runes.sublist(cursorX, runes.length);
        var strBuffer = StringBuffer();
        for (var rune in firstPart) {
          if (rune.isVar) {
            strBuffer.write(rune.varKey);
          } else {
            strBuffer.write(rune.ch);
          }
        }
        document.lines[cursorY] = strBuffer.toString();
        strBuffer.clear();
        for (var rune in secondPart) {
          if (rune.isVar) {
            strBuffer.write(rune.varKey);
          } else {
            strBuffer.write(rune.ch);
          }
        }
        document.lines.insert(cursorY + 1, strBuffer.toString());
        scrollAreaControl.refreshAll();
        scrollAreaControl.displayCursorAt(cursorY + 1, 0);
        break;
      default:
        // int keyId = event.logicalKey.keyId;
        if (event.character != null) {
          int cursorX = widget.cursorManager.runeIndex;
          int cursorY = widget.cursorManager.lineIndex;
          print('line: $cursorY col: $cursorX');
          scrollAreaControl.insertChar(cursorY, cursorX, event.character);
          List<Rune> runes = scrollAreaControl.getRunes(cursorY, 0, lineControllers[cursorY].getRunesLength());
          var strBuffer = StringBuffer();
          for (var rune in runes) {
            if (rune.isVar) {
              strBuffer.write(rune.varKey);
            } else {
              strBuffer.write(rune.ch);
            }
          }
          document.lines[cursorY] = strBuffer.toString();
          widget.cursorManager.runeIndex += 1;
          
        }
        break;
    }
    scrollAreaControl.displayCursorAt(widget.cursorManager.lineIndex, widget.cursorManager.runeIndex);
  }

}