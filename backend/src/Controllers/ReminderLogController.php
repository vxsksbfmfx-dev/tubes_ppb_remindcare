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
        if (!$ok) {
            $this->error('Log tidak ditemukan atau sudah dikonfirmasi', 409);
        }

        // Broadcast via WebSocket (fire-and-forget, tidak blocking)
        $row       = $this->log->findOne('id = ?', [(int)$id]);
        $elderlyId = $row['elderly_user_id'] ?? 0;
        if ($elderlyId) {
            $this->broadcastWs($elderlyId, 'log_confirmed', $row);
        }

        $this->success(null, 'Berhasil dikonfirmasi');
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

    /**
     * Kirim event ke WebSocket server via HTTP internal (port 8090).
     * WS server menerima pesan auth dulu, tapi ini adalah broadcast langsung
     * melalui internal socket (simplified).
     */
    private function broadcastWs(int $elderlyId, string $event, ?array $data): void
    {
        // Simple non-blocking socket write ke WebSocket server
        $payload = json_encode([
            'type'       => 'broadcast',
            'event'      => $event,
            'elderly_id' => $elderlyId,
            'data'       => $data,
            'token'      => INTERNAL_BROADCAST_TOKEN,
        ]);

        $ctx = stream_context_create(['http' => [
            'method'  => 'POST',
            'header'  => "Content-Type: application/json\r\n",
            'content' => $payload,
            'timeout' => 1,
        ]]);
        // Gunakan internal HTTP endpoint jika tersedia
        @file_get_contents('http://127.0.0.1:8091/broadcast', false, $ctx);
    }
}
