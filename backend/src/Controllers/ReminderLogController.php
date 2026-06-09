<?php
namespace App\Controllers;

use App\Core\BaseController;
use App\Middleware\AuthMiddleware;
use App\Models\ReminderLog;
use App\Models\User;

class ReminderLogController extends BaseController
{
    private ReminderLog $log;
    private User        $user;

    public function __construct()
    {
        $this->log  = new ReminderLog();
        $this->user = new User();
    }

    /** GET /api/logs?elderly_id=&date= */
    public function today(): void
    {
        $payload   = AuthMiddleware::handle();
        $elderlyId = $this->resolveElderlyId($payload);
        $this->success($this->log->todayLogs($elderlyId));
    }

    /** GET /api/logs/history?elderly_id=&date=&page= */
    public function history(): void
    {
        $payload   = AuthMiddleware::handle();
        $elderlyId = $this->resolveElderlyId($payload);
        $date      = $_GET['date'] ?? '';
        $page      = max(1, (int)($_GET['page'] ?? 1));
        $per       = 20;

        $data  = $this->log->history($elderlyId, $date, $page, $per);
        $total = $this->log->historyCount($elderlyId, $date);

        $this->success([
            'items'        => $data,
            'total'        => $total,
            'current_page' => $page,
            'last_page'    => (int) ceil($total / $per),
        ]);
    }

    /** GET /api/logs/stats?elderly_id= */
    public function stats(): void
    {
        $payload   = AuthMiddleware::handle();
        $elderlyId = $this->resolveElderlyId($payload);
        $this->success([
            'weekly'  => $this->log->weeklyStats($elderlyId),
            'monthly' => $this->log->monthlySummary($elderlyId),
        ]);
    }

    /** POST /api/logs/{id}/confirm */
    public function confirm(string $id): void
    {
        $payload = AuthMiddleware::handle();
        $logRow  = $this->log->findById((int)$id);

        if (!$logRow) $this->error('Log tidak ditemukan', 404);
        if ($logRow['status'] !== 'pending') {
            $this->error('Log sudah dikonfirmasi atau terlewat', 400);
        }

        $this->log->update((int)$id, [
            'status'       => 'confirmed',
            'confirmed_at' => date('Y-m-d H:i:s'),
        ]);

        // broadcast WebSocket jika tersedia
        $this->broadcastConfirm($logRow);

        $this->success($this->log->findById((int)$id), 'Konfirmasi berhasil');
    }

    // ── private helpers ───────────────────────────────────────

    private function resolveElderlyId(array $payload): int
    {
        if ($payload['role'] === 'elderly') {
            return $payload['sub'];
        }
        // family: harus kirim elderly_id
        $id = (int)($_GET['elderly_id'] ?? 0);
        if (!$id) $this->error('elderly_id wajib diisi', 400);
        return $id;
    }

    private function broadcastConfirm(array $logRow): void
    {
        // POST ke WebSocket HTTP bridge (opsional)
        $url = 'http://127.0.0.1:8181/broadcast';
        $data = json_encode([
            'type'       => 'log_confirmed',
            'elderly_id' => $logRow['elderly_id'],
            'log'        => $logRow,
        ]);
        @file_get_contents($url, false, stream_context_create([
            'http' => [
                'method'  => 'POST',
                'header'  => 'Content-Type: application/json',
                'content' => $data,
                'timeout' => 1,
            ],
        ]));
    }
}
