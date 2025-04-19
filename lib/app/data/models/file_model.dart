class FileModel {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final DateTime? createdAt;
  final String? downloadUrl;

  const FileModel({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.createdAt,
    this.downloadUrl,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAtDate;
    if (json['created_at'] != null && json['created_at'] is String) {
      String dateString = json['created_at'];
      // 1. Try parsing as standard ISO 8601
      createdAtDate = DateTime.tryParse(dateString);

      // 2. If failed, try handling potential DB format (YYYY-MM-DDTHH:mm:ss.SSSSSS)
      if (createdAtDate == null) {
        try {
          // Check if it looks like the DB format
          if (dateString.length > 19 &&
              dateString[10] == 'T' &&
              dateString[19] == '.') {
            // Assume it's UTC, take only up to milliseconds and add 'Z'
            if (dateString.length >= 23) {
              dateString = dateString.substring(0, 23) + 'Z';
            } else {
              // Handle cases with less precision if needed, e.g., pad with zeros
              dateString = dateString.padRight(23, '0') + 'Z';
            }
            createdAtDate = DateTime.tryParse(dateString);
          }
          // Add more specific format handling here if necessary
        } catch (e) {
          // Log or handle parsing error if needed, createdAtDate remains null
          print(
            "Could not parse file createdAt string: ${json['created_at']} - Error: $e",
          );
        }
      }
    }

    return FileModel(
      id: json['id'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      createdAt: createdAtDate,
      downloadUrl: json['download_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt?.toIso8601String(),
      'download_url': downloadUrl,
    };
  }
}
