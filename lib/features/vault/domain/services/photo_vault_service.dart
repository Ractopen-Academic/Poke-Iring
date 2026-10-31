import '../entities/vault_photo_entry.dart';

abstract class PhotoVaultService {
  Stream<List<VaultPhotoEntry>> watchVault(String userId);
  Future<List<VaultPhotoEntry>> getVault(String userId);

  Future<VaultPhotoEntry> archivePhoto(VaultPhotoEntry photo);
  Future<void> removePhoto(String userId, String photoId);
  Future<int> getTotalVaultBytes(String userId);
}
