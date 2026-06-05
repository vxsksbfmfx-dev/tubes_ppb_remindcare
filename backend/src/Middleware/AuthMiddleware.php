<?php
namespace App\Middleware;

use App\Helpers\JwtHelper;

class AuthMiddleware
{
    public static function handle(): array
    {
        $header  = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        $token   = str_replace('Bearer ', '', $header);
        $payload = JwtHelper::verify($token);

        if (!$payload) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Unauthorized']);
            exit;
        }
        return $payload;
    }
}
