<?php
namespace App\Models;

use App\Core\Model;

class ReminderLog extends Model
{
    protected string $table = 'reminder_logs';

    public function findByDate(int $elderlyId, string $date): array
    {
        $sql = "SELECT rl.*, m.name AS medicine_name, m.generic_name,
                       s.dose, s.dose_unit, s.times
                FROM reminder_logs rl
                JOIN schedules s ON s.id = rl.schedule_id
                JOIN medicines m ON m.id = s.medicine_id
                WHERE rl.elderly_user_id = ?
                  AND DATE(rl.scheduled_at) = ?
                ORDER BY rl.scheduled_at ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$elderlyId, $date]);
        return $stmt->fetchAll();
    }

    public function confirm(int $logId, string $confirmedBy): bool
    {
        $stmt = $this->db->prepare(
            "UPDATE reminder_logs SET status='taken', taken_at=NOW(),
             confirmed_by=?, updated_at=NOW() WHERE id=? AND status='pending'"
        );
        $stmt->execute([$confirmedBy, $logId]);
        return $stmt->rowCount() > 0;
    }

    public function weeklyReport(int $elderlyId): array
    {
        $sql = "SELECT DATE(scheduled_at) AS date,
                       COUNT(*) AS total,
                       SUM(status='taken') AS taken,
                       SUM(status='missed') AS missed,
                       SUM(status='pending') AS pending
                FROM reminder_logs
                WHERE elderly_user_id=?
                  AND scheduled_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
                GROUP BY DATE(scheduled_at)
                ORDER BY date ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$elderlyId]);
        return $stmt->fetchAll();
    }
}
