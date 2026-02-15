abstract class Job {
  Future<String> step1(int id);
  Future<String> step2(int id);
  Future<String> step3(int id);
}
