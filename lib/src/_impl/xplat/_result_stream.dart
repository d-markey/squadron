import 'dart:async';

import '../../channel.dart';
import '../../exceptions/squadron_error.dart';
import '../../exceptions/squadron_exception.dart';
import '../../worker/worker_request.dart';
import '../../worker/worker_response.dart';
import '_forward_stream_controller.dart';

class ResultStream {
  ResultStream(
    Channel channel,
    WorkerRequest req,
    Stream<WorkerResponse> Function() sendRequest,
    bool streaming,
  ) {
    final streamIdCompleter = streaming ? Completer<int?>() : null;
    final command = req.command, token = req.cancelToken;

    void $decodeStreamOfResponses(WorkerResponse res) {
      if (!res.unwrapInPlace(channel)) return;

      final hasStreamId = streamIdCompleter!.isCompleted;
      if (res.endOfStream) {
        // handle endofStream
        if (!hasStreamId) {
          streamIdCompleter.complete(null);
          channel.logger
              ?.e('Invalid state: unexpected endOfStream for command $command');
          _controller.addError(SquadronErrorImpl.create(
            'Invalid state: unexpected endOfStream',
            null,
            command,
          ));
        }
        _controller.close();
        return;
      }

      final error = res.error;
      if (error == null && !hasStreamId) {
        // the first result from a streaming operation is the stream ID
        streamIdCompleter.complete((res.result as num).toInt());
      } else if (error != null) {
        _controller.addError(error);
        if (!hasStreamId) {
          // if any error comes before the stream ID, somethind bad happened
          streamIdCompleter.complete(null);
          _controller.close();
          return;
        }
      } else {
        try {
          _controller.add(res.result);
        } catch (ex, st) {
          _controller.addError(SquadronException.from(ex, st, command));
        }
      }

      final canceled = token?.exception;
      if (canceled != null) {
        _controller.addError(canceled);
        _controller.close();
      }
    }

    void $decodeSingleResponse(WorkerResponse res) {
      if (!res.unwrapInPlace(channel)) return;

      final error = res.error;
      if (error != null) {
        _controller.addError(error);
      } else {
        try {
          _controller.add(res.result);
        } catch (ex, st) {
          _controller.addError(SquadronException.from(ex, st, command));
        }
      }

      _controller.close();
    }

    Future<int?> $getStreamId(StreamSubscription sub) async {
      streamIdCompleter as Completer<int?>;
      var count = 0;
      if (sub.isPaused && !streamIdCompleter.isCompleted) {
        // if the subscription was paused and the streamId is not available,
        // resume to have the streamId eventually come through.
        while (sub.isPaused) {
          count++;
          sub.resume();
        }
      }
      // wait for the streamId...
      final streamId = await streamIdCompleter.future;
      // restore subscription pause
      while (count > 0) {
        count--;
        sub.pause();
      }
      return streamId;
    }

    Future<void> $onCancel() async {
      final sub = _controller.subscription;
      if (streamIdCompleter != null && sub != null) {
        // this is a streaming operation and the subscription is active, so
        // we need to inform the worker that the stream has been canceled
        final streamId = await $getStreamId(sub);
        if (streamId != null) {
          channel.cancelStream(streamId);
        }
        await sub.cancel();
      }
    }

    void $closeWithError(Object error, [StackTrace? st]) {
      _controller.addError(SquadronException.from(error, st, command));
      _controller.close();
    }

    void $onListen() {
      try {
        // do not send the request if the token is already canceled
        token?.throwIfCanceled();
        // send the request and start decoding responses
        _controller.attachSubscription(sendRequest().listen(
          streaming ? $decodeStreamOfResponses : $decodeSingleResponse,
          onError: $closeWithError,
          onDone: _controller.close,
          cancelOnError: false,
        ));
      } catch (ex, st) {
        $closeWithError(ex, st);
      }
    }

    _controller = ForwardStreamController<dynamic>(
      onListen: $onListen,
      onCancel: $onCancel,
    );
  }

  late final ForwardStreamController<dynamic> _controller;

  Stream<dynamic> get stream => _controller.stream;

  Future<void> get done => _controller.done;
}
