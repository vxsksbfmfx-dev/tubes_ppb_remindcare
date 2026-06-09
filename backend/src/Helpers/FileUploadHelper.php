<?php
namespace App\Helpers;

class FileUploadHelper
{
    private static array $allowedMime = [
        'image/jpeg', 'image/png', 'image/webp',
    ];
    private static int $maxSize = 2 * 1024 * 1024; // 2 MB

    /**
     * Upload file avatar, kembalikan path relatif
     * @throws \RuntimeException
     */
    public static function uploadAvatar(array $file, int $userId): string
    {
        if ($file['error'] !== UPLOAD_ERR_OK) {
            throw new \RuntimeException('Upload gagal: error code ' . $file['error']);
        }
        if ($file['size'] > self::$maxSize) {
            throw new \RuntimeException('File terlalu besar (maks 2 MB)');
        }

        $mime = mime_content_type($file['tmp_name']);
        if (!in_array($mime, self::$allowedMime, true)) {
            throw new \RuntimeException('Tipe file tidak didukung (jpeg/png/webp)');
        }

        $ext      = pathinfo($file['name'], PATHINFO_EXTENSION) ?: 'jpg';
        $filename = "user_{$userId}_" . time() . ".$ext";
        $dest     = BASE_PATH . '/storage/avatars/' . $filename;

        if (!move_uploaded_file($file['tmp_name'], $dest)) {
            throw new \RuntimeException('Gagal menyimpan file');
        }

        return '/storage/avatars/' . $filename;
    }

    public static function deleteFile(string $relativePath): void
    {
        $full = BASE_PATH . $relativePath;
        if (file_exists($full)) {
            @unlink($full);
        }
    }
}
