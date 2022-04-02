import 'bitcoin_worker.dart' as bitcoin_isolate;
import 'cache_worker.dart' as cache_isolate;
import 'pi_digits_worker.dart' as pi_digits_isolate;
import 'prime_worker.dart' as prime_isolate;
import 'rogue_worker.dart' as rogue_isolate;
import 'sample_worker.dart' as sample_isolate;
import 'failing_worker.dart' as failing_isolate;
import 'invalid_worker.dart' as invalid_isolate;
import 'local_client_worker.dart' as local_client_isolate;

Map<String, dynamic> get entryPoints => {
      'bitcoin': bitcoin_isolate.start,
      'cache': cache_isolate.start,
      'failing': failing_isolate.start,
      'failing_missing_command': failing_isolate.startWithMissingCommand,
      'invalid': invalid_isolate.start,
      'local': local_client_isolate.start,
      'pi_digits': pi_digits_isolate.start,
      'prime': prime_isolate.start,
      'rogue': rogue_isolate.start,
      'sample': sample_isolate.start,
    };
