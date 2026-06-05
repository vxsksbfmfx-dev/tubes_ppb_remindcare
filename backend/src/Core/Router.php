<?php
namespace App\Core;

class Router
{
    private array $routes = [];

    public function add(string $method, string $pattern, array $handler): void
    {
        $this->routes[] = [
            'method'  => strtoupper($method),
            'pattern' => $this->toRegex($pattern),
            'handler' => $handler,
        ];
    }

    public function get(string $p, array $h):  void { $this->add('GET',    $p, $h); }
    public function post(string $p, array $h): void { $this->add('POST',   $p, $h); }
    public function put(string $p, array $h):  void { $this->add('PUT',    $p, $h); }
    public function delete(string $p, array $h): void { $this->add('DELETE', $p, $h); }

    public function dispatch(): void
    {
        // CORS
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');
        header('Content-Type: application/json; charset=utf-8');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            http_response_code(200);
            exit;
        }

        $method = $_SERVER['REQUEST_METHOD'];
        // Support PUT/DELETE via _method override
        if ($method === 'POST') {
            $body = $this->getBody();
            if (isset($body['_method'])) {
                $method = strtoupper($body['_method']);
            }
        }

        $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        // Strip base path jika jalan di subdirectory
        $base = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/');
        $uri  = '/' . ltrim(substr($uri, strlen($base)), '/');

        foreach ($this->routes as $route) {
            if ($route['method'] !== $method) continue;
            if (preg_match($route['pattern'], $uri, $matches)) {
                array_shift($matches);
                [$class, $method_name] = $route['handler'];
                $controller = new $class();
                $controller->$method_name(...$matches);
                return;
            }
        }

        http_response_code(404);
        echo json_encode(['error' => 'Route tidak ditemukan', 'uri' => $uri]);
    }

    private function toRegex(string $pattern): string
    {
        $regex = preg_replace('/\{(\w+)\}/', '([^/]+)', $pattern);
        return '#^' . $regex . '$#';
    }

    public function getBody(): array
    {
        $raw = file_get_contents('php://input');
        return json_decode($raw, true) ?? $_POST;
    }
}
