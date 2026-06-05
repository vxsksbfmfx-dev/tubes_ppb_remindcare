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

    public function createUser(array $data): int
    {
        return $this->insert([
            'name'       => $data['name'],
            'email'      => $data['email'],
            'password'   => password_hash($data['password'], PASSWORD_BCRYPT),
            'phone'      => $data['phone'] ?? null,
            'role'       => $data['role']  ?? 'family',
        ]);
    }

    public function safeData(array $user): array
    {
        unset($user['password']);
        return $user;
    }
}
