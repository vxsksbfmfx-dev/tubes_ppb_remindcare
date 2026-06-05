<?php
namespace App\Controllers;

use App\Core\BaseController;
use App\Helpers\JwtHelper;
use App\Models\User;

class AuthController extends BaseController
{
    private User $user;

    public function __construct()
    {
        $this->user = new User();
    }

    /** POST /api/auth/register */
    public function register(): void
    {
        $data   = $this->body();
        $errors = $this->validate($data, [
            'name'     => 'required',
            'email'    => 'required|email',
            'password' => 'required|min:6',
        ]);
        if ($errors) $this->error('Validasi gagal', 422, $errors);

        if ($this->user->findByEmail($data['email'])) {
            $this->error('Email sudah terdaftar', 409);
        }

        $id  = $this->user->createUser($data);
        $row = $this->user->safeData($this->user->findById($id));
        $token = JwtHelper::generate(['sub' => $id, 'role' => $row['role']]);

        $this->success(['user' => $row, 'token' => $token], 'Registrasi berhasil', 201);
    }

    /** POST /api/auth/login */
    public function login(): void
    {
        $data   = $this->body();
        $errors = $this->validate($data, [
            'email'    => 'required|email',
            'password' => 'required',
        ]);
        if ($errors) $this->error('Validasi gagal', 422, $errors);

        $row = $this->user->findByEmail($data['email']);
        if (!$row || !password_verify($data['password'], $row['password'])) {
            $this->error('Email atau password salah', 401);
        }

        $safe  = $this->user->safeData($row);
        $token = JwtHelper::generate(['sub' => $row['id'], 'role' => $row['role']]);
        $this->success(['user' => $safe, 'token' => $token], 'Login berhasil');
    }

    /** GET /api/auth/me  (butuh token) */
    public function me(): void
    {
        $payload = $this->requireAuth();
        $row     = $this->user->findById($payload['sub']);
        if (!$row) $this->error('User tidak ditemukan', 404);
        $this->success($this->user->safeData($row));
    }

    /** Helper: ambil JWT dari header */
    protected function requireAuth(): array
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        $token  = str_replace('Bearer ', '', $header);
        $payload = \App\Helpers\JwtHelper::verify($token);
        if (!$payload) $this->error('Unauthorized', 401);
        return $payload;
    }
}
