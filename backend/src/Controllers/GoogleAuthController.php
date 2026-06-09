<?php
namespace App\Controllers;

use App\Core\BaseController;
use App\Helpers\JwtHelper;
use App\Models\User;

class GoogleAuthController extends BaseController
{
    private User $user;

    public function __construct()
    {
        $this->user = new User();
    }

    public function login(): void
    {
        $data = $this->body();

        if (empty($data['id_token'])) {
            $this->error('id_token wajib dikirim', 400);
        }

        $googleUser = $this->verifyGoogleToken($data['id_token']);
        if (!$googleUser) {
            $this->error('Google token tidak valid', 401);
        }

        $user = $this->user->findByEmail($googleUser['email']);

        if (!$user) {
            $id   = $this->user->insertGoogleUser([
                'name'          => $googleUser['name']    ?? 'User',
                'email'         => $googleUser['email'],
                'google_id'     => $googleUser['sub'],
                'avatar'        => $googleUser['picture'] ?? null,
                'email_verified'=> 1,
            ]);
            $user = $this->user->findById($id);
        } else {
            $this->user->update($user['id'], [
                'google_id' => $googleUser['sub'],
                'avatar'    => $user['avatar'] ?? $googleUser['picture'] ?? null,
            ]);
            $user = $this->user->findById($user['id']);
        }

        $safe  = $this->user->safeData($user);
        $token = JwtHelper::generate(['sub' => $user['id'], 'role' => $user['role']]);

        $this->success([
            'user'  => $safe,
            'token' => $token,
        ], 'Login Google berhasil');
    }

    private function verifyGoogleToken(string $idToken): ?array
    {
        $url = 'https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode($idToken);
        $ctx = stream_context_create(['http' => ['timeout' => 10, 'ignore_errors' => true]]);
        $raw = @file_get_contents($url, false, $ctx);
        if (!$raw) return null;
        $data = json_decode($raw, true);
        if (!$data || isset($data['error'])) return null;
        if (($data['aud'] ?? '') !== GOOGLE_CLIENT_ID) return null;
        return $data;
    }
}
