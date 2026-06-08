<?php
// ── Public routes ──────────────────────────────────────────
$router->post('/api/auth/register', [\App\Controllers\AuthController::class, 'register']);
$router->post('/api/auth/login',    [\App\Controllers\AuthController::class, 'login']);

// ── Protected routes ───────────────────────────────────────
$router->get( '/api/auth/me',      [\App\Controllers\AuthController::class, 'me']);
$router->get( '/api/auth/refresh', [\App\Controllers\AuthController::class, 'refresh']);

// Medicines
$router->get(   '/api/medicines',      [\App\Controllers\MedicineController::class, 'index']);
$router->post(  '/api/medicines',      [\App\Controllers\MedicineController::class, 'store']);
$router->get(   '/api/medicines/{id}', [\App\Controllers\MedicineController::class, 'show']);
$router->put(   '/api/medicines/{id}', [\App\Controllers\MedicineController::class, 'update']);
$router->delete('/api/medicines/{id}', [\App\Controllers\MedicineController::class, 'destroy']);

// Schedules
$router->get(   '/api/schedules',      [\App\Controllers\ScheduleController::class, 'index']);
$router->post(  '/api/schedules',      [\App\Controllers\ScheduleController::class, 'store']);
$router->put(   '/api/schedules/{id}', [\App\Controllers\ScheduleController::class, 'update']);
$router->delete('/api/schedules/{id}', [\App\Controllers\ScheduleController::class, 'destroy']);

// Reminder Logs
$router->get( '/api/logs',                    [\App\Controllers\ReminderLogController::class, 'index']);
$router->post('/api/logs/{id}/confirm',        [\App\Controllers\ReminderLogController::class, 'confirm']);
$router->get( '/api/logs/weekly-report',       [\App\Controllers\ReminderLogController::class, 'weeklyReport']);
