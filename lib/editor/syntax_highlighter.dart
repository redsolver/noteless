import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rich_code_editor/exports.dart';

class NotelessSyntaxHighlighter implements SyntaxHighlighterBase {
  Color accentColor;

  Map styles;

  init(Color accentColor) {
    this.accentColor = accentColor;
    styles = {
      '1': TextStyle(
        fontStyle: FontStyle.italic,
      ),
      '2': TextStyle(fontWeight: FontWeight.bold),
      '3': TextStyle(
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      ),
      '4': TextStyle(
        color: Colors.blue,
      ),
      '5': TextStyle(
        color: Colors.purple,
      ),
      '6': TextStyle(
        decoration: TextDecoration.lineThrough,
      ),
      '7': TextStyle(
        color: accentColor,
        fontWeight: FontWeight.bold,
      ),
    };
  }

  NotelessSyntaxHighlighter({this.accentColor});

  @override
  TextEditingValue addTextRemotely(TextEditingValue oldValue, String newText) {
    return null;
  }

  @override
  TextEditingValue onBackSpacePress(
      TextEditingValue oldValue, TextSpan currentSpan) {
    return null;
  }

  @override
  TextEditingValue onEnterPress(TextEditingValue oldValue) {
    int oldStart = oldValue.selection.start;

    final bef = oldValue.text.substring(0, oldStart - 1);

    String befLine = bef.split('\n').last;

    int trimSpace = befLine.length;

    befLine = befLine.trimLeft();

    trimSpace = trimSpace - befLine.length;

    if (befLine.startsWith('- ') || befLine.startsWith('* ')) {
      if (befLine.length <= 2) {
        if (trimSpace == 0) {
          var newValue = oldValue.copyWith(
            text: bef.substring(0, oldStart - 3) +
                '\n\n' +
                oldValue.text.substring(oldStart + 1),
            composing: TextRange(start: -1, end: -1),
            selection: TextSelection.fromPosition(
              TextPosition(
                  affinity: TextAffinity.upstream, offset: bef.length - 1),
            ),
          );

          return newValue;
        } else {
          var newValue = oldValue.copyWith(
            text: oldValue.text.substring(0, oldStart - 1 - 4) +
                oldValue.text.substring(oldStart - 3, oldStart) +
                oldValue.text.substring(oldStart + 1),
            composing: TextRange(start: -1, end: -1),
            selection: TextSelection.fromPosition(
              TextPosition(
                  affinity: TextAffinity.upstream, offset: bef.length - 2),
            ),
          );

          return newValue;
        }
      }

      String sym = befLine.startsWith('* ') ? '*' : '-';

      for (int i = 0; i < trimSpace; i++) {
        sym = ' ' + sym;
      }

      var newValue = oldValue.copyWith(
        text: bef + '\n$sym \n' + oldValue.text.substring(oldStart + 1),
        composing: TextRange(start: -1, end: -1),
        selection: TextSelection.fromPosition(
          TextPosition(
              affinity: TextAffinity.upstream,
              offset: bef.length + 3 + trimSpace),
        ),
      );

      return newValue;
    }

    return null;

    int start = oldStart;

    int breakCount = 0;

    while (start > 0) {
      start--;
      if (oldValue.text[start] == '\n') {
        if (breakCount >= 1) break;
        breakCount++;
      }
    }
    if (start != 0) start++;

    String startOfLine = oldValue.text.substring(
      start,
    );
    final before = oldValue.text.substring(0, oldStart);

    print(startOfLine.substring(0, 10));

    if (startOfLine.startsWith('- ')) {
      int length = 1;

      if (startOfLine.startsWith('- ')) length++;
/*       _rec.text = before + startOfLine.substring(1).trimLeft();
      _rec.selection = TextSelection(
          baseOffset: oldStart - length, extentOffset: oldStart - length); */
      var newValue = oldValue.copyWith(
        text: before + '- \n' + oldValue.text,
        composing: TextRange(start: -1, end: -1),
        selection: TextSelection.fromPosition(
          TextPosition(
              affinity: TextAffinity.upstream, offset: before.length + 2),
        ),
      );

      return newValue;
    } else {}
    return oldValue;
  }

  @override
  List<TextSpan> parseText(TextEditingValue tev) {
    var texts = tev.text.split('\n');

    var lsSpans = List<TextSpan>();

    bool inCodeBlock = false;

    int i = 0;
    texts.forEach((text) {
      i++;
      // print('"$text"');

      if (text.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        lsSpans.add(TextSpan(text: text, style: styles['4']));
        /*   if (text.endsWith(' ')) {
          lsSpans.add(TextSpan(text: ' '));
        } */
        lsSpans.add(TextSpan(text: '\n'));
        return;
      }

      if (inCodeBlock) {
        lsSpans.add(TextSpan(text: text));
        /*      if (text.endsWith(' ')) {
          lsSpans.add(TextSpan(text: ' '));
        } */
        lsSpans.add(TextSpan(text: '\n'));

        return;
      }

      int lengthDiff = text.length;

      text = text.trimLeft();

      lengthDiff = lengthDiff - text.length;

      String lineStart = '';

      for (int i = 0; i < lengthDiff; i++) {
        lineStart += ' ';
      }

      if (lineStart != null)
        lsSpans.add(
          TextSpan(
            text: lineStart,
          ),
        );

      addPrefix(String prefix) {
        lsSpans.add(
          TextSpan(
            text: prefix,
            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
          ),
        );
      }

      if (text.startsWith('# ')) {
        addPrefix('# ');
        text = text.substring(2);
      } else if (text.startsWith('## ')) {
        addPrefix('## ');
        text = text.substring(3);
      } else if (text.startsWith('### ')) {
        addPrefix('### ');
        text = text.substring(4);
      } else if (text.startsWith('#### ')) {
        addPrefix('#### ');
        text = text.substring(5);
      } else if (text.startsWith('##### ')) {
        addPrefix('##### ');
        text = text.substring(6);
      } else if (text.startsWith('###### ')) {
        addPrefix('###### ');
        text = text.substring(7);
      } else if (text.startsWith('- ')) {
        addPrefix('- ');
        text = text.substring(2);
      } else if (text.startsWith('> ')) {
        while (text.startsWith('> ')) {
          addPrefix('> ');
          text = text.substring(2);
        }
      } else if (text.startsWith('* ')) {
        addPrefix('* ');
        text = text.substring(2);
      } else {}

      /*   String str = ''; */

      // Star

      String s = text.replaceAllMapped(
          RegExp(r'(?<![\w\*])\*[^\*]+\*(?![\w\*])'),
          (match) =>
              '<nless-format-tmp>1' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      s = s.replaceAllMapped(
          RegExp(r'(?<!\*)\*\*[^\*]+\*\*(?!\*)'),
          (match) =>
              '<nless-format-tmp>2' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      s = s.replaceAllMapped(
          RegExp(r'(?<!\*)\*\*\*[^\*]+\*\*\*(?!\*)'),
          (match) =>
              '<nless-format-tmp>3' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      // Underscore

      s = s.replaceAllMapped(
          RegExp(r'(?<![\w_])_[^_]+_(?![\w_])'),
          (match) =>
              '<nless-format-tmp>1' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      s = s.replaceAllMapped(
          RegExp(r'(?<!_)__[^_]+__(?!_)'),
          (match) =>
              '<nless-format-tmp>2' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      s = s.replaceAllMapped(
          RegExp(r'(?<!_)___[^_]+___(?!_)'),
          (match) =>
              '<nless-format-tmp>3' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      // Strikethrough

      s = s.replaceAllMapped(
          RegExp(r'~~[^~]+~~'),
          (match) =>
              '<nless-format-tmp>6' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      // Inline Code

      s = s.replaceAllMapped(
          RegExp(r'\`[^\`]+\`'),
          (match) =>
              '<nless-format-tmp>4' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      // Divider ---

      s = s.replaceAllMapped(
          RegExp(r'^---$'),
          (match) =>
              '<nless-format-tmp>7' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      s = s.replaceAllMapped(
          RegExp(r'^\*\*\*$'),
          (match) =>
              '<nless-format-tmp>7' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      // KaTeX

      s = s.replaceAllMapped(
          RegExp(r'(?<![\w\$])\$[^\$]+\$(?![\w\$])'),
          (match) =>
              '<nless-format-tmp>4' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      s = s.replaceAllMapped(
          RegExp(r'\$\$[^\$]+\$\$'),
          (match) =>
              '<nless-format-tmp>4' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      // AsciiMath

      s = s.replaceAllMapped(
          RegExp(r'(?<![\w&])&[^&]+&(?![\w&])'),
          (match) =>
              '<nless-format-tmp>4' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      s = s.replaceAllMapped(
          RegExp(r'&&[^&]+&&'),
          (match) =>
              '<nless-format-tmp>4' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      // Wiki-Style note links like [[Note]]

      s = s.replaceAllMapped(RegExp(r'\[\[[^\]]+\]\]'), (match) {
        var str = match.input.substring(match.start, match.end);

        String title = str.substring(2).split(']').first;

        return '<nless-format-tmp>7[[<nless-format-tmp>0$title<nless-format-tmp>7]]<nless-format-tmp>0';
      });

      // Emojis

      s = s.replaceAllMapped(
          RegExp(r'(?<![\w:]):[^:]+:(?![\w:])'),
          (match) =>
              '<nless-format-tmp>4' +
              match.input.substring(match.start, match.end) +
              '<nless-format-tmp>0');

      // Links

      s = s.replaceAllMapped(RegExp(r'(!)?\[[^\]]*\]\([^\)]+\)'), (match) {
        var str = match.input.substring(match.start, match.end);
        String out = '';
        if (str.startsWith('!')) {
          str = str.substring(1);
          out += '<nless-format-tmp>4!';
        }
        String title = str.substring(1).split(']').first;

        out +=
            '<nless-format-tmp>7[<nless-format-tmp>0$title<nless-format-tmp>7]';

        str = str.substring(title.length + 2);

        out += '<nless-format-tmp>4' + str + '<nless-format-tmp>0';

        return out;
      });

      s = '0$s';

      for (var part in s.split('<nless-format-tmp>')) {
        TextStyle style = styles[part[0]];

        lsSpans.add(TextSpan(
          text: part.substring(1),
          style: style,
        ));
        /*     if (part == '*') {
          lsSpans.add(TextSpan(
              text: str, style: TextStyle(fontWeight: FontWeight.bold)));
          str = '';
        } */
      }


      if (i < texts.length) {
        lsSpans.add(TextSpan(text: '\n'));
      }
    });
    return lsSpans;
  }
}
