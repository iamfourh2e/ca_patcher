class BuildVersionModel {
  final int buildVersion;
  final String sha;
  final AgentModel agent;
  BuildVersionModel({
    required this.buildVersion,
    required this.sha,
    required this.agent,
  });

  factory BuildVersionModel.fromJson(Map<String, dynamic> json) {
    return BuildVersionModel(
      buildVersion: json['buildVersion'],
      sha: json['sha'],
      agent: AgentModel.fromJson(json['agentDoc']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buildVersion': buildVersion,
      'sha': sha,
      'agent': agent.toJson(),
    };
  }
}



class AgentModel {
  String id;
  String module;
  String authority;
  String sha;
  String days;
  String enviroment;
  String createdBy;

  AgentModel({
    required this.id,
    required this.module,
    required this.authority,
    required this.sha,
    required this.days,
    required this.enviroment,
    required this.createdBy,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) => AgentModel(
        id: json["id"],
        module: json["module"],
        authority: json["authority"],
        sha: json["sha"],
        days: json["days"],
        enviroment: json["enviroment"],
        createdBy: json["createdBy"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "module": module,
        "authority": authority,
        "sha": sha,
        "days": days,
        "enviroment": enviroment,
        "createdBy": createdBy,
      };
}