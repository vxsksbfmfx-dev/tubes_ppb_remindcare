<?php
namespace App\Controllers;

use App\Core\BaseController;
use App\Helpers\FileUploadHelper;
use App\Middleware\AuthMiddleware;
use App\Models\User;

class UserController extends BaseController
{
    private User $model;

    public function __construct()
    {
        $this->model = new User();
    }

    /** GET /api/users/me */
    public function me(): void
    {
        $payload = AuthMiddleware::handle();
        $row     = $this->model->findById($payload['sub']);
        if (!$row) $this->error('User tidak ditemukan', 404);
        $this->success($this->model->safeData($row));
    }

    /** PUT /api/users/me */
    public function update(): void
    {
        $payload = AuthMiddleware::handle();
        $data    = $this->body();

        $errors = $this->validate($data, [
            'name' => 'required',
        ]);
        if ($errors) $this->error('Validasi gagal', 422, $errors);

        // field yang boleh di-update
        $fields = array_filter([
            'name'  => $data['name']  ?? null,
            'phone' => $data['phone'] ?? null,
            'age'   => isset($data['age']) ? (int)$data['age'] : null,
        ], fn($v) => $v !== null);

        $this->model->update($payload['sub'], $fields);
        $row = $this->model->safeData($this->model->findById($payload['sub']));
        $this->success($row, 'Profil berhasil diperbarui');
    }

    /** POST /api/users/me/avatar  (multipart/form-data) */
    public function uploadAvatar(): void
    {
        $payload = AuthMiddleware::handle();
        $row     = $this->model->findById($payload['sub']);
        if (!$row) $this->error('User tidak ditemukan', 404);

        if (empty($_FILES['avatar'])) {
            $this->error('File avatar wajib dikirim', 400);
        }

        try {
            // Hapus avatar lama jika ada
            if (!empty($row['avatar'])) {
                FileUploadHelper::deleteFile($row['avatar']);
            }
            $path = FileUploadHelper::uploadAvatar($_FILES['avatar'], $payload['sub']);
            $this->model->update($payload['sub'], ['avatar' => $path]);
            $updated = $this->model->safeData($this->model->findById($payload['sub']));
            $this->success($updated, 'Avatar berhasil diperbarui');
        } catch (\RuntimeException $e) {
            $this->error($e->getMessage(), 400);
        }
    }

    /** GET /api/users/{id}  (lihat profil orang lain, hanya untuk keluarga) */
    public function show(string $id): void
    {
        AuthMiddleware::handle();
        $row = $this->model->findById((int)$id);
        if (!$row) $this->error('User tidak ditemukan', 404);
        $this->success($this->model->safeData($row));
    }
}
