<?php
use App\Controllers\MedicineController;

// Medicines CRUD
$router->get('/api/medicines',         [MedicineController::class, 'index']);
$router->get('/api/medicines/{id}',    [MedicineController::class, 'show']);
$router->post('/api/medicines',        [MedicineController::class, 'store']);
$router->put('/api/medicines/{id}',    [MedicineController::class, 'update']);
$router->delete('/api/medicines/{id}', [MedicineController::class, 'destroy']);
