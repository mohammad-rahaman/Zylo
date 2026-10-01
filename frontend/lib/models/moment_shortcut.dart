import 'user.dart';

class MomentShortcut {
  final String id;
  final String name;
  final String emoji;
  final List<String> contactIds;
  final List<User> contacts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MomentShortcut({
    required this.id,
    required this.name,
    required this.emoji,
    required this.contactIds,
    required this.contacts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MomentShortcut.fromJson(Map<String, dynamic> json) {
    final contactsList = (json['contacts'] as List<dynamic>?)
            ?.map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final idsList = (json['contactIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        contactsList.map((c) => c.id).toList();

    return MomentShortcut(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '✨',
      contactIds: idsList,
      contacts: contactsList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'contactIds': contactIds,
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MomentShortcut copyWith({
    String? id,
    String? name,
    String? emoji,
    List<String>? contactIds,
    List<User>? contacts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MomentShortcut(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      contactIds: contactIds ?? this.contactIds,
      contacts: contacts ?? this.contacts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
