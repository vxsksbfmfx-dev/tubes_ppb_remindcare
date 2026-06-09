<?php
namespace App\Models;

use App\Core\Model;
use PDO;

class ReminderLog extends Model
{
    protected string $table = 'reminder_logs';

    /** Log hari ini milik elderly */
    public function todayLogs(int $elderlyId): array
    {
        $today = date('Y-m-d');
        return $this->findAll(
            'elderly_id = ? AND DATE(scheduled_at) = ?',
            [$elderlyId, $today],
            'scheduled_at ASC'
        );
    }

    /** History dengan pagination & filter tanggal */
    public function history(int $elderlyId, string $date = '', int $page = 1, int $per = 20): array
    {
        $offset = ($page - 1) * $per;
        $where  = 'rl.elderly_id = ?';
        $params = [$elderlyId];

        if ($date) {
            $where  .= ' AND DATE(rl.scheduled_at) = ?';
            $params[] = $date;
        }

        $sql = "SELECT rl.*, m.name AS medicine_name, m.brand_name,
                       s.dosage, s.notes
                FROM reminder_logs rl
                LEFT JOIN schedules  s ON s.id = rl.schedule_id
                LEFT JOIN medicines  m ON m.id = s.medicine_id
                WHERE $where
                ORDER BY rl.scheduled_at DESC
                LIMIT $per OFFSET $offset";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    /** Total halaman untuk history */
    public function historyCount(int $elderlyId, string $date = ''): int
    {
        $where  = 'elderly_id = ?';
        $params = [$elderlyId];
        if ($date) { $where .= ' AND DATE(scheduled_at) = ?'; $params[] = $date; }
        return $this->count($where, $params);
    }

    /** Statistik kepatuhan 7 hari terakhir */
    public function weeklyStats(int $elderlyId): array
    {
        $sql = "SELECT
                    DATE(scheduled_at) AS tanggal,
                    COUNT(*) AS total,
                    SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) AS diminum,
                    SUM(CASE WHEN status = 'missed'    THEN 1 ELSE 0 END) AS terlewat
                FROM reminder_logs
                WHERE elderly_id = ?
                  AND scheduled_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
                GROUP BY DATE(scheduled_at)
                ORDER BY tanggal ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$elderlyId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /** Statistik ringkasan bulan ini */
    public function monthlySummary(int $elderlyId): array
    {
        $sql = "SELECT
                    COUNT(*) AS total,
                    SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) AS diminum,
                    SUM(CASE WHEN status = 'missed'    THEN 1 ELSE 0 END) AS terlewat,
                    SUM(CASE WHEN status = 'pending'   THEN 1 ELSE 0 END) AS menunggu,
                    ROUND(
                        SUM(CASE WHEN status='confirmed' THEN 1 ELSE 0 END) * 100.0
                        / NULLIF(COUNT(*), 0), 1
                    ) AS persentase_kepatuhan
                FROM reminder_logs
                WHERE elderly_id = ?
                  AND MONTH(scheduled_at) = MONTH(CURDATE())
                  AND YEAR(scheduled_at)  = YEAR(CURDATE())";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$elderlyId]);
        return $stmt->fetch(\PDO::FETCH_ASSOC) ?: [];
    }
}
