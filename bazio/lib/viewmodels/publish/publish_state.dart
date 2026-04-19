import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

enum ImageUploadStatus { pending, uploading, done }

class ImageUploadItem {
  final XFile file;
  final ImageUploadStatus status;

  const ImageUploadItem({
    required this.file,
    this.status = ImageUploadStatus.pending,
  });

  ImageUploadItem copyWith({ImageUploadStatus? status}) {
    return ImageUploadItem(file: file, status: status ?? this.status);
  }
}

class PublishState {
  final List<ImageUploadItem> imageItems;
  final bool isLoading;
  final bool isUploading;
  final bool isLocating;
  final Position? position;
  final String? city;
  final String? editingListingId;
  final List<String> existingImageUrls;

  const PublishState({
    this.imageItems = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.isLocating = false,
    this.position,
    this.city,
    this.editingListingId,
    this.existingImageUrls = const [],
  });

  bool get isEditing => editingListingId != null;
  List<XFile> get images => imageItems.map((e) => e.file).toList();

  PublishState copyWith({
    List<ImageUploadItem>? imageItems,
    bool? isLoading,
    bool? isUploading,
    bool? isLocating,
    Position? position,
    String? city,
    String? editingListingId,
    List<String>? existingImageUrls,
    bool clearPosition = false,
    bool clearCity = false,
  }) {
    return PublishState(
      imageItems: imageItems ?? this.imageItems,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      isLocating: isLocating ?? this.isLocating,
      position: clearPosition ? null : position ?? this.position,
      city: clearCity ? null : city ?? this.city,
      editingListingId: editingListingId ?? this.editingListingId,
      existingImageUrls: existingImageUrls ?? this.existingImageUrls,
    );
  }
}
