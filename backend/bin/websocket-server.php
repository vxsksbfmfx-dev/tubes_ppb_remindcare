<?php
declare(strict_types=1);

define('BASE_PATH', dirname(__DIR__));
require_once BASE_PATH . '/src/Core/Autoloader.php';
\App\Core\Autoloader::register();
require_once BASE_PATH . '/src/Config/config.php';

use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use App\WebSocket\ReminderSocket;

$port   = 8090;
$server = IoServer::factory(
    new HttpServer(
        new WsServer(
            new ReminderSocket()
        )
    ),
    $port
);

echo "╔══════════════════════════════════════════╗\n";
echo "║  RemindCare WebSocket Server             ║\n";
echo "║  Listening on ws://0.0.0.0:$port         ║\n";
echo "╚══════════════════════════════════════════╝\n";

$server->run();
