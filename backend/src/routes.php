<?php
use App\Controllers\AuthController;
use App\Controllers\MedicineController;
use App\Controllers\NotificationController;
use App\Controllers\ScheduleController;
use App\Controllers\ReminderLogController;
use App\Controllers\UserController;

// ── Auth ─────────────────────────────────────────────────
$router->post('/api/auth/register', [AuthController::class, 'register']);
$router->post('/api/auth/login',    [AuthController::class, 'login']);
$router->get('/api/auth/me',        [AuthController::class, 'me']);
$router->post('/api/auth/refresh',  [AuthController::class, 'refresh']);
$router->post('/api/auth/logout',   [AuthController::class, 'logout']);
$router->post('/api/auth/google',   [AuthController::class, 'googleLogin']);

// ── Users / Profile ───────────────────────────────────────
$router->get('/api/users/me',              [UserController::class, 'me']);
$router->put('/api/users/me',              [UserController::class, 'update']);
$router->post('/api/users/me/avatar',      [UserController::class, 'uploadAvatar']);
$router->get('/api/users/{id}',            [UserController::class, 'show']);

// ── Medicines ─────────────────────────────────────────────
$router->get('/api/medicines',             [MedicineController::class, 'index']);
$router->get('/api/medicines/{id}',        [MedicineController::class, 'show']);
$router->post('/api/medicines',            [MedicineController::class, 'store']);
$router->put('/api/medicines/{id}',        [MedicineController::class, 'update']);
$router->delete('/api/medicines/{id}',     [MedicineController::class, 'destroy']);

// ── Schedules ─────────────────────────────────────────────
$router->get('/api/schedules',             [ScheduleController::class, 'index']);
$router->post('/api/schedules',            [ScheduleController::class, 'store']);
$router->put('/api/schedules/{id}',        [ScheduleController::class, 'update']);
$router->delete('/api/schedules/{id}',     [ScheduleController::class, 'destroy']);

// ── Reminder Logs ─────────────────────────────────────────
$router->get('/api/logs',                  [ReminderLogController::class, 'today']);
$router->post('/api/logs/{id}/confirm',    [ReminderLogController::class, 'confirm']);

// ── Notifications ─────────────────────────────────────────
$router->post('/api/fcm-token',            [NotificationController::class, 'saveToken']);
$router->post('/api/notifications/test',   [NotificationController::class, 'sendTest']);
$router->post('/api/notifications/remind', [NotificationController::class, 'sendReminder']);
