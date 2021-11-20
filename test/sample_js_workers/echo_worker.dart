import 'dart:html';

// this is a regular Web worker

void main() {
  final scope = DedicatedWorkerGlobalScope.instance;
  scope.onMessage.listen((MessageEvent e) {
    try {
      scope.postMessage('ECHO "${e.data}"');
    } catch (error) {
      scope.postMessage('Error in Web Worker main program: $error');
    }
  });
}
