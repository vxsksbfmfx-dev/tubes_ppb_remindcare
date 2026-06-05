<?php
namespace App\Core;

class Autoloader
{
    public static function register(): void
    {
        spl_autoload_register(function (string $class): void {
            // Namespace "App\" → BASE_PATH/src/
            $relative = str_replace(['App\\', '\\'], ['', '/'], $class);
            $file = BASE_PATH . '/src/' . $relative . '.php';
            if (file_exists($file)) {
                require_once $file;
            }
        });
    }
}
