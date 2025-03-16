import 'dart:js_interop';

import 'package:web/web.dart';

final origin = window.location.origin.toJS;

typedef ClickHandler = void Function(MouseEvent);

extension DocumentExt on Document {
  T? findById<T extends Element>(String id) => find<T>('#$id');

  T? find<T extends Element>(String selectors) =>
      this.querySelector(selectors) as T?;

  HTMLButtonElement button(String id) => findById(id)!;
  HTMLDivElement div(String id) => findById(id)!;
  HTMLIFrameElement iframe(String id) => findById(id)!;
  HTMLInputElement input(String id) => findById(id)!;
  HTMLSpanElement span(String id) => findById(id)!;

  HTMLInputElement createCheckbox({String? id, bool? checked}) {
    final checkbox = document.createElement('input') as HTMLInputElement;
    checkbox.type = 'checkbox';
    if (id != null) checkbox.id = id;
    if (checked != null) checkbox.checked = checked;
    return checkbox;
  }

  HTMLDivElement createDiv({String? id, String? text, String? html}) {
    final div = document.createElement('div') as HTMLDivElement;
    if (id != null) div.id = id;
    if (html != null) {
      div.innerHTML = html.toJS;
    } else if (text != null) {
      div.innerText = text;
    }
    return div;
  }

  HTMLLabelElement createLabel({String? id, String? text, Element? target}) {
    final label = document.createElement('label') as HTMLLabelElement;
    if (id != null) label.id = id;
    if (text != null) label.textContent = text;
    if (target != null && target.id.isNotEmpty) label.htmlFor = target.id;
    return label;
  }

  HTMLSpanElement createSpan({String? id, String? text}) {
    final span = document.createElement('span') as HTMLSpanElement;
    if (id != null) span.id = id;
    if (text != null) span.textContent = text;
    return span;
  }
}

extension ElementExt on Element {
  T? findById<T extends Element>(String id) => find<T>('#$id');

  T? find<T extends Element>(String selectors) =>
      this.querySelector(selectors) as T?;

  HTMLDivElement appendDiv({String? id, String? text, String? html}) {
    final div = document.createDiv(id: id, text: text, html: html);
    appendChild(div);
    return div;
  }

  HTMLInputElement appendCheckbox({String? id, bool? checked}) {
    final checkbox = document.createCheckbox(id: id, checked: checked);
    appendChild(checkbox);
    return checkbox;
  }

  HTMLLabelElement appendLabel({String? id, String? text, Element? target}) {
    final label = document.createLabel(id: id, text: text, target: target);
    appendChild(label);
    return label;
  }

  HTMLSpanElement appendSpan({String? id, String? text}) {
    final span = document.createSpan(id: id, text: text);
    appendChild(span);
    return span;
  }
}

extension NotifyChildExt on HTMLIFrameElement {
  void notify(JSAny? message) {
    if (message.toString().startsWith('No tests ran')) {
      // ignore this message (eg. discovery mode)
      return;
    }
    contentWindow?.postMessage(message, origin);
  }
}

extension NotifyParentExt on Window {
  void notify(JSAny? message) {
    parent?.postMessage(message, origin);
  }
}
