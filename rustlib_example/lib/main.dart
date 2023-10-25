import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'dart:ffi' as ffi;

import 'package:images_picker/images_picker.dart';

typedef CRustCompress = ffi.Bool Function(
  ffi.Pointer<ffi.Int8> inputPath,
  ffi.Pointer<ffi.Int8> outputPath,
);

typedef DartRustCompress = bool Function(
  ffi.Pointer<ffi.Int8> inputPath,
  ffi.Pointer<ffi.Int8> outputPath,
);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title = ''}) : super(key: key);
  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {

  late String path;
  late ffi.DynamicLibrary dylib;
  late Function myFuncCompress;

  @override
  void initState() {
    // Open the dynamic library
    path = 'libcomp.so';
    dylib = Platform.isIOS ? ffi.DynamicLibrary.process() : ffi.DynamicLibrary.open(path);

    // Look up the Rust/C function
    myFuncCompress =
        dylib.lookup<ffi.NativeFunction<CRustCompress>>('rust_fn_compress').asFunction<DartRustCompress>();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Press compress button to compress image',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _compress,
        tooltip: 'Compress',
        child: const Icon(Icons.compress),
      ),
    );
  }

  Future<Media?> _pickImage() async {
    List<Media>? res = await ImagesPicker.pick(
      count: 1,
      pickType: PickType.image,
    );

    return res?.firstOrNull;
  }

  Future<void> _compress() async {
    _pickImage().then((media) {
      String imagePath = media?.path ?? '';
      if (imagePath.isEmpty) return;

      var pathParts = imagePath.split('/');

      pathParts = pathParts.sublist(0, pathParts.length - 1);
      pathParts.add("result.jpg");
      String outputPath = pathParts.join('/');

      final isCompressOK =
          myFuncCompress(imagePath.toNativeUtf8().cast<ffi.Int8>(), outputPath.toNativeUtf8().cast<ffi.Int8>());

      print("$isCompressOK");
    });
  }
}
