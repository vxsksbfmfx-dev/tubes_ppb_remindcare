<?php
namespace App\Models;

use App\Core\Model;

class User extends Model
{
    protected string $table = 'users';

    public function findByEmail(string $email): ?array
    {
        return $this->findOne('email = ?', [$email]);
    }

    public function findByGoogleId(string $googleId): ?array
    {
        return $this->findOne('google_id = ?', [$googleId]);
    }

    public function createUser(array $data): int
    {
        return $this->insert([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => password_hash($data['password'], PASSWORD_BCRYPT),
            'phone'    => $data['phone'] ?? null,
            'role'     => $data['role']  ?? 'family',
        ]);
    }

    public function insertGoogleUser(array $data): int
    {
        return $this->insert([
            'name'           => $data['name'],
            'email'          => $data['email'],
            'password'       => password_hash(bin2hex(random_bytes(16)), PASSWORD_BCRYPT),
            'google_id'      => $data['google_id'],
            'avatar'         => $data['avatar']        ?? null,
            'email_verified' => $data['email_verified'] ?? 0,
            'role'           => 'family',
        ]);
    }

    public function safeData(array $user): array
    {
        unset($user['password']);
        return $user;
    }
}
