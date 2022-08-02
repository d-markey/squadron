class SquadronService {
  const SquadronService({this.pool = true, this.web = true, this.vm = true});

  final bool pool;
  final bool web;
  final bool vm;
}
