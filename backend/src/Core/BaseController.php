<?php
namespace App\Core;

class BaseController
{
    protected function json(mixed $data, int $status = 200): void
    {
        http_response_code($status);
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    protected function success(mixed $data, string $message = 'OK', int $status = 200): void
    {
        $this->json(['success' => true, 'message' => $message, 'data' => $data], $status);
    }

    protected function error(string $message, int $status = 400, mixed $errors = null): void
    {
        $payload = ['success' => false, 'message' => $message];
        if ($errors !== null) $payload['errors'] = $errors;
        $this->json($payload, $status);
    }

    protected function body(): array
    {
        $raw = file_get_contents('php://input');
        return json_decode($raw, true) ?? $_POST;
    }

    protected function validate(array $data, array $rules): array
    {
        $errors = [];
        foreach ($rules as $field => $rule) {
            $parts = explode('|', $rule);
            foreach ($parts as $part) {
                if ($part === 'required' && empty($data[$field])) {
                    $errors[$field][] = "$field wajib diisi";
                }
                if (str_starts_with($part, 'min:')) {
                    $min = (int) substr($part, 4);
                    if (isset($data[$field]) && strlen((string)$data[$field]) < $min) {
                        $errors[$field][] = "$field minimal $min karakter";
                    }
                }
                if ($part === 'email' && isset($data[$field])
                    && !filter_var($data[$field], FILTER_VALIDATE_EMAIL)) {
                    $errors[$field][] = "$field harus berupa email valid";
                }
            }
        }
        return $errors;
    }
}
