<?php
namespace App\Controllers;

use App\Core\BaseController;
use App\Middleware\AuthMiddleware;
use App\Models\ReminderLog;

class ReminderLogController extends BaseController
{
    private ReminderLog $log;
    private array       $user;

    public function __construct()
    {
        $this->user = AuthMiddleware::handle();
        $this->log  = new ReminderLog();
    }

    /** GET /api/logs?date=YYYY-MM-DD */
    public function index(): void
    {
        $date      = $_GET['date'] ?? date('Y-m-d');
        $elderlyId = $this->user['role'] === 'elderly'
            ? $this->user['sub']
            : (int)($_GET['elderly_id'] ?? $this->user['sub']);
        $rows = $this->log->findByDate($elderlyId, $date);
        $this->success($rows);
    }

    /** POST /api/logs/{id}/confirm */
    public function confirm(string $id): void
    {
        $ok = $this->log->confirm((int)$id, 'user:' . $this->user['sub']);
        if ($ok) {
            $this->success(null, 'Berhasil dikonfirmasi');
        } else {
            $this->error('Log tidak ditemukan atau sudah dikonfirmasi', 409);
        }
    }

    /** GET /api/logs/weekly-report */
    public function weeklyReport(): void
    {
        $elderlyId = $this->user['role'] === 'elderly'
            ? $this->user['sub']
            : (int)($_GET['elderly_id'] ?? $this->user['sub']);
        $data = $this->log->weeklyReport($elderlyId);
        $this->success($data);
    }
}
