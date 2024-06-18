import 'dart:async';

class ChunkTransformer extends StreamTransformerBase<List<int>, List<int>> {
  final int chunkSize;

  ChunkTransformer(this.chunkSize);

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    StreamController<List<int>>? controller;
    StreamSubscription<List<int>>? subscription;

    controller = StreamController<List<int>>(
      onListen: () {
        List<int> buffer = [];

        void handleData(List<int> data) {
          buffer.addAll(data);
          while (buffer.length >= chunkSize) {
            controller!.add(buffer.sublist(0, chunkSize));
            buffer = buffer.sublist(chunkSize);
          }
        }

        void handleError(Object error, StackTrace stackTrace) {
          controller!.addError(error, stackTrace);
        }

        void handleDone() {
          if (buffer.isNotEmpty) {
            controller!.add(buffer);
          }
          controller!.close();
        }

        subscription = stream.listen(handleData,
            onError: handleError, onDone: handleDone, cancelOnError: false);
      },
      onPause: ([Future<dynamic>? resumeSignal]) {
        subscription!.pause(resumeSignal);
      },
      onResume: () {
        subscription!.resume();
      },
      onCancel: () {
        return subscription!.cancel();
      },
    );

    return controller.stream;
  }
}