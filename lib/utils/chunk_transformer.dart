import 'dart:async';
import 'dart:typed_data';

class ChunkTransformer extends StreamTransformerBase<List<int>, Uint8List> {
  final int chunkSize;

  ChunkTransformer(this.chunkSize);

  @override
  Stream<Uint8List> bind(Stream<List<int>> stream) {
    List<int> buffer = [];

    return stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          buffer.addAll(data);
          while (buffer.length >= chunkSize) {
            sink.add(Uint8List.fromList(buffer.sublist(0, chunkSize)));
            buffer = buffer.sublist(chunkSize);
          }
        },
        handleError: (error, stackTrace, sink) {
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) {
          if (buffer.isNotEmpty) {
            sink.add(Uint8List.fromList(buffer));
          }
          sink.close();
        },
      ),
    );
  }
}
