<?php
namespace App\Controllers;

use App\Core\BaseController;
use App\Middleware\AuthMiddleware;
use App\Models\ReminderLog;
use App\Models\Schedule;
use App\Models\User;

class DashboardController extends BaseController
{
    private ReminderLog $log;
    private Schedule    $schedule;
    private User        $user;

    public function __construct()
    {
        $this->log      = new ReminderLog();
        $this->schedule = new Schedule();
        $this->user     = new User();
    }

    /**
     * GET /api/dashboard
     * Ringkasan hari ini: jadwal, log, persentase kepatuhan,
     * obat berikutnya yang harus diminum.
     */
    public function index(): void
    {
        $payload   = AuthMiddleware::handle();
        $elderlyId = $this->resolveElderlyId($payload);

        // Log hari ini
        $todayLogs = $this->log->todayLogs($elderlyId);
        $total     = count($todayLogs);
        $diminum   = count(array_filter($todayLogs, fn($l) => $l['status'] === 'confirmed'));
        $terlewat  = count(array_filter($todayLogs, fn($l) => $l['status'] === 'missed'));
        $menunggu  = count(array_filter($todayLogs, fn($l) => $l['status'] === 'pending'));
        $persen    = $total > 0 ? round($diminum / $total * 100, 1) : 0;

        // Jadwal berikutnya
        $now  = date('H:i:s');
        $next = null;
        foreach ($todayLogs as $log) {
            if ($log['status'] === 'pending') {
                $waktu = date('H:i:s', strtotime($log['scheduled_at']));
                if ($waktu >= $now) {
                    $next = $log;
                    break;
                }
            }
        }

        // Statistik mingguan ringkas
        $weekly = $this->log->weeklyStats($elderlyId);

        $this->success([
            'today' => [
                'total'     => $total,
                'diminum'   => $diminum,
                'terlewat'  => $terlewat,
                'menunggu'  => $menunggu,
                'persen'    => $persen,
            ],
            'next_schedule' => $next,
            'today_logs'    => $todayLogs,
            'weekly_stats'  => $weekly,
            'user'          => $this->user->safeData(
                $this->user->findById($payload['sub'])
            ),
        ]);
    }

    private function resolveElderlyId(array $payload): int
    {
        if ($payload['role'] === 'elderly') return $payload['sub'];
        $id = (int)($_GET['elderly_id'] ?? 0);
        if (!$id) $this->error('elderly_id wajib diisi', 400);
        return $id;
    }
}
