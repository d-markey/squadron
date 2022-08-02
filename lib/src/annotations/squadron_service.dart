class SquadronService {
  const SquadronService({this.web = true, this.vm = true, this.pool = true});

  final bool web;
  final bool vm;
  final bool pool;
}
