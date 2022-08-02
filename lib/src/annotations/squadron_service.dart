class SquadronService {
  const SquadronService(
      {this.pool = true, this.vm = true, this.web = true, this.baseUrl = ''});

  final bool pool;
  final bool vm;
  final bool web;
  final String baseUrl;
}
