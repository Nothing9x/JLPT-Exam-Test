import 'dart:convert';

/// Model for Grammar data from the database
class GrammarModel {
  final int id;
  final String structure;
  final String? detail;
  final String level;
  final String? structureVi;
  final bool favorite;
  final bool remember;
  final String? category;

  const GrammarModel({
    required this.id,
    required this.structure,
    this.detail,
    required this.level,
    this.structureVi,
    this.favorite = false,
    this.remember = false,
    this.category,
  });

  factory GrammarModel.fromMap(Map<String, dynamic> map) {
    return GrammarModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      structure: map['struct']?.toString() ?? '',
      detail: _parseDetail(map['detail']),
      level: map['level']?.toString() ?? 'N5',
      structureVi: map['struct_vi']?.toString(),
      favorite: (map['favorite'] is int) ? map['favorite'] == 1 : false,
      remember: (map['remember'] is int) ? map['remember'] == 1 : false,
      category: map['category']?.toString(),
    );
  }

  /// Parse the detail JSON to extract the explanation
  static String? _parseDetail(dynamic detailData) {
    if (detailData == null) return null;
    if (detailData is! String) return detailData.toString();
    if (detailData.isEmpty) return null;
    try {
      final List<dynamic> decoded = json.decode(detailData);
      if (decoded.isNotEmpty && decoded[0] is Map) {
        final firstItem = decoded[0] as Map<String, dynamic>;
        final explain = firstItem['explain']?.toString();
        final mean = firstItem['mean']?.toString();
        if (mean != null && mean.isNotEmpty) {
          return mean;
        }
        return explain;
      }
      return null;
    } catch (e) {
      return detailData;
    }
  }

  /// Get the display meaning (either structureVi or parsed from detail)
  String get displayMeaning {
    if (structureVi != null && structureVi!.isNotEmpty) {
      return structureVi!;
    }
    return detail ?? '';
  }
}
