export 'native_storage_service_stub.dart'
    if (dart.library.io) 'native_storage_service_io.dart'
    if (dart.library.html) 'native_storage_service_web.dart';
