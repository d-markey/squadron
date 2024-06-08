import 'dart:html';

// this is a regular Web Worker

void main() {
  final scope = DedicatedWorkerGlobalScope.instance;
  scope.onMessage.listen((MessageEvent e) {
    try {
      scope.postMessage('ECHO "${e.data}"');
    } catch (error) {
      scope.postMessage('Error in Web Worker main program: $error');
    }
  });
  // post a message indicating that the Web worker is up and running
  scope.postMessage({"ready": true});
}
