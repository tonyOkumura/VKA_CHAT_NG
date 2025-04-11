class FileModel {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String createdAt;
  final String? downloadUrl;

  FileModel({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
    this.downloadUrl,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      createdAt: json['created_at'],
      downloadUrl: json['download_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt,
      'download_url': downloadUrl,
    };
  }
}
