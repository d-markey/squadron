import 'package:logger/web.dart';

import '../../exceptions/squadron_error.dart';
import '../../typedefs.dart';
import '../../worker/worker_channel.dart';

WorkerChannel? deserialize(PlatformChannel? channelInfo, [Logger? logger]) =>
    throw SquadronErrorImpl.create('Platform not supported');
