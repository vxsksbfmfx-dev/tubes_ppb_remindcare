<?php
use App\Controllers\AuthController;
use App\Controllers\MedicineController;

// ── Auth ──────────────────────────────────────────────────
$router->post('/api/auth/register', [AuthController::class, 'register']);
$router->post('/api/auth/login',    [AuthController::class, 'login']);
$router->get('/api/auth/me',        [AuthController::class, 'me']);
$router->post('/api/auth/refresh',  [AuthController::class, 'refresh']);
$router->post('/api/auth/logout',   [AuthController::class, 'logout']);

// ── Medicines ─────────────────────────────────────────────
$router->get('/api/medicines',         [MedicineController::class, 'index']);
$router->get('/api/medicines/{id}',    [MedicineController::class, 'show']);
$router->post('/api/medicines',        [MedicineController::class, 'store']);
$router->put('/api/medicines/{id}',    [MedicineController::class, 'update']);
$router->delete('/api/medicines/{id}', [MedicineController::class, 'destroy']);
