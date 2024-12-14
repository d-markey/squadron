import 'dart:js_interop';

import 'package:web/web.dart';

final origin = window.location.origin.toJS;

extension DocumentExt on Document {
  T? findById<T extends Element>(String id) => find<T>('#$id');

  T? find<T extends Element>(String selectors) =>
      this.querySelector(selectors) as T?;

  HTMLAnchorElement createAnchor({
    String? id,
    String? text,
    String? href,
    void Function(MouseEvent)? onClick,
  }) {
    final anchor = document.createElement('a') as HTMLAnchorElement;
    if (id != null) anchor.id = id;
    if (text != null) anchor.text = text;
    if (href != null) anchor.href = href;
    if (onClick != null) anchor.onClick.listen(onClick);
    return anchor;
  }

  HTMLButtonElement createButton({
    String? id,
    String? label,
    void Function(MouseEvent)? onClick,
  }) {
    final button = document.createElement('button') as HTMLButtonElement;
    if (id != null) button.id = id;
    if (label != null) button.text = label;
    if (onClick != null) button.onClick.listen(onClick);
    return button;
  }

  HTMLInputElement createCheckbox({
    String? id,
    bool? checked,
  }) {
    final checkbox = document.createElement('input') as HTMLInputElement;
    checkbox.type = 'checkbox';
    if (id != null) checkbox.id = id;
    if (checked != null) checkbox.checked = checked;
    return checkbox;
  }

  HTMLLabelElement createLabel({
    String? id,
    String? text,
    String? forId,
    Element? target, // overrides forId if target has an id
  }) {
    final label = document.createElement('label') as HTMLLabelElement;
    if (id != null) label.id = id;
    if (text != null) label.text = text;
    if (target != null && target.id.isNotEmpty) forId = target.id;
    if (forId != null) label.htmlFor = forId;
    return label;
  }

  HTMLSpanElement createSpan({
    String? id,
    String? label,
  }) {
    final span = document.createElement('span') as HTMLSpanElement;
    if (id != null) span.id = id;
    if (label != null) span.text = label;
    return span;
  }
}

extension ElementExt on Element {
  T? findById<T extends Element>(String id) => find<T>('#$id');

  T? find<T extends Element>(String selectors) =>
      this.querySelector(selectors) as T?;

  HTMLAnchorElement appendAnchor({
    String? id,
    String? text,
    String? href,
    void Function(MouseEvent)? onClick,
  }) {
    final anchor = document.createAnchor(
      id: id,
      text: text,
      href: href,
      onClick: onClick,
    );
    appendChild(anchor);
    return anchor;
  }

  HTMLButtonElement appendButton({
    String? id,
    String? label,
    void Function(MouseEvent)? onClick,
  }) {
    final button = document.createButton(
      id: id,
      label: label,
      onClick: onClick,
    );
    appendChild(button);
    return button;
  }

  HTMLInputElement appendCheckbox({
    String? id,
    bool? checked,
  }) {
    final checkbox = document.createCheckbox(
      id: id,
      checked: checked,
    );
    appendChild(checkbox);
    return checkbox;
  }

  HTMLLabelElement appendLabel({
    String? id,
    String? text,
    String? forId,
    Element? target,
  }) {
    final label = document.createLabel(
      id: id,
      text: text,
      forId: forId,
      target: target,
    );
    appendChild(label);
    return label;
  }

  HTMLSpanElement appendSpan({
    String? id,
    String? text,
  }) {
    final span = document.createSpan(
      id: id,
      label: text,
    );
    appendChild(span);
    return span;
  }

  void removeLastChild() {
    final len = children.length;
    if (len > 0) {
      children.item(len - 1)!.remove();
    }
  }
}

extension NotifyExt on HTMLIFrameElement {
  void notify(JSAny? message) => contentWindow?.postMessage(message, origin);
}
