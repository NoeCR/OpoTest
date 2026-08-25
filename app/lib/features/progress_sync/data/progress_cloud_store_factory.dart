import '../domain/progress_cloud_store.dart';
import 'unsupported_progress_cloud_store.dart'
    if (dart.library.io) 'google_drive_progress_store.dart';

ProgressCloudStore createProgressCloudStore() => createStore();
