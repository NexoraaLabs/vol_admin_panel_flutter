// Admin response shapes from packages/api-client/src/types.ts. Dates arrive as ISO strings.

import 'paged.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

List<Map<String, dynamic>> _maps(Object? v) => (v as List? ?? const []).cast<Map<String, dynamic>>();

class Person {
  const Person({required this.id, required this.name, this.avatarUrl});

  final String id;
  final String name;
  final String? avatarUrl;

  factory Person.fromJson(Map<String, dynamic> json) =>
      Person(id: json['id'] as String, name: json['name'] as String? ?? '', avatarUrl: json['avatarUrl'] as String?);

  static Person? maybe(Object? json) => json == null ? null : Person.fromJson(json as Map<String, dynamic>);
}

/// "ACTIVE" | "SUSPENDED" | "BANNED"
typedef AccountStatus = String;

/// "OPEN" | "IN_REVIEW" | "RESOLVED" | "DISMISSED"
typedef CaseStatus = String;

class AdminUserRow {
  const AdminUserRow({
    required this.id,
    required this.displayId,
    required this.name,
    required this.email,
    required this.accountType,
    required this.status,
    required this.emailVerified,
    required this.reports,
    required this.joinedAt,
    required this.visibility,
    this.username,
    this.avatarUrl,
    this.lastActiveAt,
    this.phone,
    this.country,
    this.city,
    this.businessVerification,
  });

  final String id;
  final String displayId;
  final String name;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String accountType;
  final AccountStatus status;
  final bool emailVerified;
  final int reports;
  final DateTime? lastActiveAt;
  final String? phone;
  final String? country;
  final String? city;
  final DateTime joinedAt;
  final String visibility;
  final String? businessVerification;

  factory AdminUserRow.fromJson(Map<String, dynamic> json) => AdminUserRow(
    id: json['id'] as String,
    displayId: json['displayId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    username: json['username'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    accountType: json['accountType'] as String? ?? 'INDIVIDUAL',
    status: json['status'] as String? ?? 'ACTIVE',
    emailVerified: json['emailVerified'] as bool? ?? false,
    reports: _int(json['reports']),
    lastActiveAt: _date(json['lastActiveAt']),
    phone: json['phone'] as String?,
    country: json['country'] as String?,
    city: json['city'] as String?,
    joinedAt: _date(json['joinedAt']) ?? DateTime.now(),
    visibility: json['visibility'] as String? ?? 'PUBLIC',
    businessVerification: (json['business'] as Map<String, dynamic>?)?['verification'] as String?,
  );
}

class ModerationEntry {
  const ModerationEntry({required this.id, required this.type, required this.reason, required this.actor, required this.createdAt});

  final String id;
  final String type;
  final String reason;
  final Person actor;
  final DateTime createdAt;

  factory ModerationEntry.fromJson(Map<String, dynamic> json) => ModerationEntry(
    id: json['id'] as String,
    type: json['type'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    actor: Person.fromJson(json['actor'] as Map<String, dynamic>),
    createdAt: _date(json['createdAt'])!,
  );
}

class UserWorkspace {
  const UserWorkspace({
    required this.id,
    required this.name,
    required this.role,
    required this.members,
    required this.canvases,
    required this.visibility,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String role;
  final int members;
  final int canvases;
  final String visibility;
  final DateTime updatedAt;

  factory UserWorkspace.fromJson(Map<String, dynamic> json) => UserWorkspace(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    role: json['role'] as String? ?? '',
    members: _int(json['members']),
    canvases: _int(json['canvases']),
    visibility: json['visibility'] as String? ?? '',
    updatedAt: _date(json['updatedAt'])!,
  );
}

class UserClassroom {
  const UserClassroom({required this.id, required this.title, required this.role, required this.status, this.progress});

  final String id;
  final String title;
  final String role;
  final int? progress;
  final String status;

  factory UserClassroom.fromJson(Map<String, dynamic> json) => UserClassroom(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    role: json['role'] as String? ?? '',
    progress: (json['progress'] as num?)?.toInt(),
    status: json['status'] as String? ?? '',
  );
}

class AdminUserDetail {
  const AdminUserDetail({required this.user, required this.workspaces, required this.classrooms, required this.history});

  final AdminUserRow user;
  final List<UserWorkspace> workspaces;
  final List<UserClassroom> classrooms;
  final List<ModerationEntry> history;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) => AdminUserDetail(
    user: AdminUserRow.fromJson(json),
    workspaces: _maps(json['workspaces']).map(UserWorkspace.fromJson).toList(),
    classrooms: _maps(json['classrooms']).map(UserClassroom.fromJson).toList(),
    history: _maps(json['history']).map(ModerationEntry.fromJson).toList(),
  );
}

class AdminCase {
  const AdminCase({
    required this.id,
    required this.displayId,
    required this.title,
    required this.violation,
    required this.status,
    required this.reportedUser,
    required this.reportCount,
    required this.evidence,
    required this.escalatedAt,
    required this.createdAt,
    this.reporter,
    this.assignee,
    this.recommendation,
    this.resolvedAt,
  });

  final String id;
  final String displayId;
  final String title;
  final String violation;
  final CaseStatus status;
  final Person reportedUser;
  final Person? reporter;
  final Person? assignee;
  final int reportCount;
  final String? recommendation;
  final List<String> evidence;
  final DateTime escalatedAt;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  bool get closed => status == 'RESOLVED' || status == 'DISMISSED';

  factory AdminCase.fromJson(Map<String, dynamic> json) => AdminCase(
    id: json['id'] as String,
    displayId: json['displayId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    violation: json['violation'] as String? ?? '',
    status: json['status'] as String? ?? 'OPEN',
    reportedUser: Person.fromJson(json['reportedUser'] as Map<String, dynamic>),
    reporter: Person.maybe(json['reporter']),
    assignee: Person.maybe(json['assignee']),
    reportCount: _int(json['reportCount']),
    recommendation: json['recommendation'] as String?,
    evidence: (json['evidence'] as List? ?? const []).cast<String>(),
    escalatedAt: _date(json['escalatedAt'])!,
    resolvedAt: _date(json['resolvedAt']),
    createdAt: _date(json['createdAt'])!,
  );
}

class CaseReport {
  const CaseReport({
    required this.id,
    required this.targetType,
    required this.reason,
    required this.reporter,
    required this.createdAt,
    this.details,
  });

  final String id;
  final String targetType;
  final String reason;
  final String? details;
  final Person reporter;
  final DateTime createdAt;

  factory CaseReport.fromJson(Map<String, dynamic> json) => CaseReport(
    id: json['id'] as String,
    targetType: json['targetType'] as String? ?? '',
    reason: json['reason'] as String? ?? '',
    details: json['details'] as String?,
    reporter: Person.fromJson(json['reporter'] as Map<String, dynamic>),
    createdAt: _date(json['createdAt'])!,
  );
}

class AdminCaseDetail {
  const AdminCaseDetail({required this.info, required this.reports, required this.actions});

  final AdminCase info;
  final List<CaseReport> reports;
  final List<ModerationEntry> actions;

  factory AdminCaseDetail.fromJson(Map<String, dynamic> json) => AdminCaseDetail(
    info: AdminCase.fromJson(json),
    reports: _maps(json['reports']).map(CaseReport.fromJson).toList(),
    actions: _maps(json['actions']).map(ModerationEntry.fromJson).toList(),
  );
}

class CaseStats {
  const CaseStats({required this.open, required this.inReview, required this.reopenedThisMonth});

  final int open;
  final int inReview;
  final int reopenedThisMonth;

  factory CaseStats.fromJson(Map<String, dynamic> json) =>
      CaseStats(open: _int(json['open']), inReview: _int(json['inReview']), reopenedThisMonth: _int(json['reopenedThisMonth']));
}

class AdminCaseList {
  const AdminCaseList({required this.page, required this.stats});

  final Paged<AdminCase> page;
  final CaseStats stats;

  factory AdminCaseList.fromJson(Map<String, dynamic> json) =>
      AdminCaseList(page: Paged.fromJson(json, AdminCase.fromJson), stats: CaseStats.fromJson(json['stats'] as Map<String, dynamic>));
}

class DashStat {
  const DashStat({required this.value, this.delta, this.thisWeek});

  final int value;
  final String? delta;
  final int? thisWeek;

  factory DashStat.fromJson(Object? json) {
    final m = json as Map<String, dynamic>? ?? const {};
    return DashStat(value: _int(m['value']), delta: m['delta'] as String?, thisWeek: (m['thisWeek'] as num?)?.toInt());
  }
}

/// One x-axis point of a chart: its label and a number per series key.
class ChartPoint {
  const ChartPoint(this.label, this.values);

  final String label;
  final Map<String, num> values;

  num operator [](String key) => values[key] ?? 0;

  factory ChartPoint.fromJson(Map<String, dynamic> json) => ChartPoint(json['label'] as String? ?? '', {
    for (final e in json.entries)
      if (e.value is num) e.key: e.value as num,
  });

  static List<ChartPoint> list(Object? json) => _maps(json).map(ChartPoint.fromJson).toList();
}

class PlatformHealth {
  const PlatformHealth({required this.openCriticalCases, required this.securityAlerts24h, required this.failedAdminLogins24h});

  final int openCriticalCases;
  final int securityAlerts24h;
  final int failedAdminLogins24h;

  factory PlatformHealth.fromJson(Map<String, dynamic> json) => PlatformHealth(
    openCriticalCases: _int(json['openCriticalCases']),
    securityAlerts24h: _int(json['securityAlerts24h']),
    failedAdminLogins24h: _int(json['failedAdminLogins24h']),
  );
}

class AdminDashboard {
  const AdminDashboard({
    required this.stats,
    required this.userGrowth,
    required this.businessGrowth,
    required this.activityByWeek,
    required this.health,
  });

  final Map<String, DashStat> stats;
  final List<ChartPoint> userGrowth;
  final List<ChartPoint> businessGrowth;
  final List<ChartPoint> activityByWeek;
  final PlatformHealth health;

  DashStat stat(String key) => stats[key] ?? const DashStat(value: 0);

  factory AdminDashboard.fromJson(Map<String, dynamic> json) => AdminDashboard(
    stats: {for (final e in (json['stats'] as Map<String, dynamic>).entries) e.key: DashStat.fromJson(e.value)},
    userGrowth: ChartPoint.list(json['userGrowth']),
    businessGrowth: ChartPoint.list(json['businessGrowth']),
    activityByWeek: ChartPoint.list(json['activityByWeek']),
    health: PlatformHealth.fromJson(json['health'] as Map<String, dynamic>),
  );
}

class ShareSlice {
  const ShareSlice(this.name, this.value);

  final String name;
  final num value;
}

class AdminAnalytics {
  const AdminAnalytics({
    required this.totalUsers,
    required this.activeWorkspaces,
    required this.classroomsRunning,
    required this.products,
    required this.growth,
    required this.accountShare,
  });

  final int totalUsers;
  final int activeWorkspaces;
  final int classroomsRunning;
  final int products;
  final List<ChartPoint> growth;
  final List<ShareSlice> accountShare;

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>;
    return AdminAnalytics(
      totalUsers: _int(stats['totalUsers']),
      activeWorkspaces: _int(stats['activeWorkspaces']),
      classroomsRunning: _int(stats['classroomsRunning']),
      products: _int(stats['products']),
      growth: ChartPoint.list(json['growth']),
      accountShare: [for (final s in _maps(json['accountShare'])) ShareSlice(s['name'] as String? ?? '', s['value'] as num? ?? 0)],
    );
  }
}

/// One editable platform setting. [value] is a String, num or bool depending on [kind].
class SettingField {
  const SettingField({required this.key, required this.label, required this.kind, required this.value, this.options = const []});

  final String key;
  final String label;

  /// "text" | "number" | "toggle" | "select"
  final String kind;
  final Object value;
  final List<String> options;

  factory SettingField.fromJson(Map<String, dynamic> json) => SettingField(
    key: json['key'] as String,
    label: json['label'] as String? ?? '',
    kind: json['kind'] as String? ?? 'text',
    value: json['value'] ?? '',
    options: (json['options'] as List? ?? const []).map((o) => '$o').toList(),
  );
}

class SettingsCard {
  const SettingsCard(this.title, this.fields);

  final String title;
  final List<SettingField> fields;
}

class SettingsTab {
  const SettingsTab({required this.value, required this.label, required this.cards});

  final String value;
  final String label;
  final List<SettingsCard> cards;

  factory SettingsTab.fromJson(Map<String, dynamic> json) => SettingsTab(
    value: json['value'] as String,
    label: json['label'] as String? ?? '',
    cards: [
      for (final c in _maps(json['cards']))
        SettingsCard(c['title'] as String? ?? '', _maps(c['fields']).map(SettingField.fromJson).toList()),
    ],
  );
}

class SecurityPolicy {
  const SecurityPolicy({required this.key, required this.label, required this.value, this.hint});

  final String key;
  final String label;
  final String? hint;
  final bool value;

  factory SecurityPolicy.fromJson(Map<String, dynamic> json) => SecurityPolicy(
    key: json['key'] as String,
    label: json['label'] as String? ?? '',
    hint: json['hint'] as String?,
    value: json['value'] as bool? ?? false,
  );
}

class SecurityOverview {
  const SecurityOverview({required this.policies, required this.health});

  final List<SecurityPolicy> policies;
  final PlatformHealth health;

  factory SecurityOverview.fromJson(Map<String, dynamic> json) => SecurityOverview(
    policies: _maps(json['policies']).map(SecurityPolicy.fromJson).toList(),
    health: PlatformHealth.fromJson(json['health'] as Map<String, dynamic>),
  );
}

class Policy {
  const Policy({required this.version, required this.content, required this.publishedAt});

  final int version;
  final String content;
  final DateTime publishedAt;

  factory Policy.fromJson(Map<String, dynamic> json) =>
      Policy(version: _int(json['version']), content: json['content'] as String? ?? '', publishedAt: _date(json['publishedAt'])!);
}

// Labels the Figma tables use (lib/admin.ts).
const accountStatusLabel = {'ACTIVE': 'Active', 'SUSPENDED': 'Suspended', 'BANNED': 'Ban'};

const caseStatusLabel = {'OPEN': 'Open', 'IN_REVIEW': 'In review', 'RESOLVED': 'Resolved', 'DISMISSED': 'Dismissed'};

String accountTypeLabel(String type) => type == 'BUSINESS' ? 'Business' : 'Individual';
