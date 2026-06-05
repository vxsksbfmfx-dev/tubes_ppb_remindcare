<?php
declare(strict_types=1);

define('BASE_PATH', dirname(__DIR__));

require_once BASE_PATH . '/src/Core/Autoloader.php';
\App\Core\Autoloader::register();

require_once BASE_PATH . '/src/Config/config.php';

$router = new \App\Core\Router();
require_once BASE_PATH . '/src/routes.php';
$router->dispatch();
