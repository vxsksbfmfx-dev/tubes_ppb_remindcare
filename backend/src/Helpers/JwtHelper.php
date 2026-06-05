<?php
namespace App\Helpers;

class JwtHelper
{
    private static function base64url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64urlDecode(string $data): string
    {
        return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', 3 - (3 + strlen($data)) % 4));
    }

    public static function generate(array $payload): string
    {
        $header  = self::base64url(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $payload['iat'] = time();
        $payload['exp'] = time() + JWT_EXPIRE;
        $claims  = self::base64url(json_encode($payload));
        $sig     = self::base64url(hash_hmac('sha256', "$header.$claims", JWT_SECRET, true));
        return "$header.$claims.$sig";
    }

    public static function verify(string $token): ?array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) return null;
        [$header, $claims, $sig] = $parts;
        $expected = self::base64url(hash_hmac('sha256', "$header.$claims", JWT_SECRET, true));
        if (!hash_equals($expected, $sig)) return null;
        $payload = json_decode(self::base64urlDecode($claims), true);
        if (!$payload || $payload['exp'] < time()) return null;
        return $payload;
    }
}
