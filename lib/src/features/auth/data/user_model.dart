class UserModel {
  final int? id;
  final String role;
  final String salutation;
  final String name;
  final String email;
  final String password;

  // ---------- STUDENT ----------
  final String? studentClass;
  final String? studentSection;

  // ---------- TEACHER ----------
  final List<String>? classesHandled;
  final List<String>? subjectsHandled;
  final bool? isClassTeacher;
  final String? classTeacherClass;
  final String? classTeacherSection;

  // ---------- PARENT ----------
  final List<Map<String, String>>? children;

  UserModel({
    this.id,
    required this.role,
    required this.salutation,
    required this.name,
    required this.email,
    required this.password,
    this.studentClass,
    this.studentSection,
    this.classesHandled,
    this.subjectsHandled,
    this.isClassTeacher,
    this.classTeacherClass,
    this.classTeacherSection,
    this.children,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'salutation': salutation,
      'name': name,
      'email': email,
      'password': password,

      // stored as JSON / CSV
      'studentClass': studentClass,
      'studentSection': studentSection,
      'classesHandled': classesHandled?.join(','),
      'subjectsHandled': subjectsHandled?.join(','),
      'isClassTeacher': isClassTeacher == true ? 1 : 0,
      'classTeacherClass': classTeacherClass,
      'classTeacherSection': classTeacherSection,
      'children': children == null ? null : _encodeChildren(children!),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      role: map['role'],
      salutation: map['salutation'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      studentClass: map['studentClass'],
      studentSection: map['studentSection'],
      classesHandled: map['classesHandled'] == null
          ? null
          : map['classesHandled'].toString().split(','),
      subjectsHandled: map['subjectsHandled'] == null
          ? null
          : map['subjectsHandled'].toString().split(','),
      isClassTeacher: map['isClassTeacher'] == 1,
      classTeacherClass: map['classTeacherClass'],
      classTeacherSection: map['classTeacherSection'],
      children:
          map['children'] == null ? null : _decodeChildren(map['children']),
    );
  }

  static String _encodeChildren(List<Map<String, String>> children) {
    return children
        .map((c) =>
            '${c['name']}|${c['class']}|${c['section']}|${c['studentEmail']}')
        .join('~');
  }

  static List<Map<String, String>> _decodeChildren(String raw) {
    return raw.split('~').map((e) {
      final p = e.split('|');
      return {
        'name': p[0],
        'class': p[1],
        'section': p[2],
        'studentEmail': p[3],
      };
    }).toList();
  }
}
