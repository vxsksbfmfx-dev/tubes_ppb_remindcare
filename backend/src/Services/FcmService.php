<?php
namespace App\Services;

/**
 * FcmService — kirim push notification via FCM HTTP v1 API
 *
 * Cara setup:
 *  1. Firebase Console → Project Settings → Service Accounts
 *  2. "Generate new private key" → simpan sebagai
 *     backend/storage/firebase-service-account.json
 *  3. Set FCM_PROJECT_ID di config.php
 */
class FcmService
{
    private string $projectId;
    private string $serviceAccountPath;

    public function __construct()
    {
        $this->projectId          = FCM_PROJECT_ID;
        $this->serviceAccountPath = FCM_SERVICE_ACCOUNT;
    }

    /**
     * Kirim notifikasi ke satu device via FCM token.
     *
     * @param string $fcmToken   FCM registration token milik device tujuan
     * @param string $title      Judul notifikasi
     * @param string $body       Isi pesan notifikasi
     * @param array  $data       Data tambahan (key-value string)
     */
    public function sendToToken(
        string $fcmToken,
        string $title,
        string $body,
        array  $data = []
    ): bool {
        $accessToken = $this->getAccessToken();
        if (!$accessToken) return false;

        $url     = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";
        $payload = [
            'message' => [
                'token'        => $fcmToken,
                'notification' => ['title' => $title, 'body'  => $body],
                'data'         => array_map('strval', $data), // FCM butuh value string
                'android'      => [
                    'priority' => 'high',
                    'notification' => [
                        'channel_id' => 'remindcare_reminder',
                        'sound'      => 'default',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    ],
                ],
                'apns' => [
                    'payload' => ['aps' => ['sound' => 'default', 'badge' => 1]],
                ],
            ],
        ];

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $accessToken,
            ],
            CURLOPT_TIMEOUT        => 10,
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $result = json_decode($response, true);
        if ($httpCode !== 200 || !isset($result['name'])) {
            error_log('[FCM] Error: ' . $response);
            return false;
        }

        return true;
    }

    /**
     * Kirim notifikasi ke banyak token sekaligus (multicast).
     * Karena FCM v1 tidak support multicast langsung,
     * kita loop satu per satu (max 500 token disarankan).
     */
    public function sendToMultiple(array $tokens, string $title, string $body, array $data = []): array
    {
        $results = ['success' => 0, 'failure' => 0];
        foreach ($tokens as $token) {
            if ($this->sendToToken($token, $title, $body, $data)) {
                $results['success']++;
            } else {
                $results['failure']++;
            }
        }
        return $results;
    }

    // ── OAuth2 Access Token dari Service Account ──────────────
    private function getAccessToken(): ?string
    {
        if (!file_exists($this->serviceAccountPath)) {
            error_log('[FCM] Service account file tidak ditemukan: ' . $this->serviceAccountPath);
            return null;
        }

        $sa   = json_decode(file_get_contents($this->serviceAccountPath), true);
        $now  = time();
        $exp  = $now + 3600;

        // ── Buat JWT untuk service account ───────────────────
        $header  = $this->b64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $claims  = $this->b64url(json_encode([
            'iss'   => $sa['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud'   => 'https://oauth2.googleapis.com/token',
            'exp'   => $exp,
            'iat'   => $now,
        ]));
        $sigInput = "$header.$claims";

        openssl_sign($sigInput, $sig, $sa['private_key'], 'SHA256');
        $jwt = "$sigInput." . $this->b64url($sig);

        // ── Tukar JWT dengan Access Token ─────────────────────
        $ch = curl_init('https://oauth2.googleapis.com/token');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]),
            CURLOPT_TIMEOUT        => 10,
        ]);
        $resp = curl_exec($ch);
        curl_close($ch);

        $data = json_decode($resp, true);
        return $data['access_token'] ?? null;
    }

    private function b64url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
