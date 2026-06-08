<?php
namespace App\Models;

use App\Core\Model;

class Schedule extends Model
{
    protected string $table = 'schedules';

    public function findByElderly(int $elderlyId): array
    {
        return $this->findAll(
            'elderly_user_id = ? AND is_active = 1 AND deleted_at IS NULL',
            [$elderlyId],
            'created_at DESC'
        );
    }

    public function create(array $data): int
    {
        $sql = "INSERT INTO schedules
                (elderly_user_id, created_by, medicine_id, dose, dose_unit,
                 times, days, start_date, end_date, notes, is_active, created_at, updated_at)
                VALUES (?,?,?,?,?,?,?,?,?,?,1,NOW(),NOW())";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            $data['elderly_user_id'],
            $data['created_by'],
            $data['medicine_id'],
            $data['dose'],
            $data['dose_unit'] ?? 'tablet',
            json_encode($data['times']),
            isset($data['days']) ? json_encode($data['days']) : null,
            $data['start_date'],
            $data['end_date'] ?? null,
            $data['notes'] ?? null,
        ]);
        return (int) $this->db->lastInsertId();
    }

    public function update(int $id, array $data): void
    {
        $fields = [];
        $params = [];
        $allowed = ['dose','dose_unit','times','days','start_date','end_date','notes','is_active'];
        foreach ($allowed as $k) {
            if (array_key_exists($k, $data)) {
                $fields[] = "$k = ?";
                $val = in_array($k, ['times','days']) ? json_encode($data[$k]) : $data[$k];
                $params[] = $val;
            }
        }
        if (empty($fields)) return;
        $params[] = $id;
        $sql = "UPDATE schedules SET " . implode(', ', $fields) . ", updated_at=NOW() WHERE id = ?";
        $this->db->prepare($sql)->execute($params);
    }

    public function softDelete(int $id): void
    {
        $this->db->prepare("UPDATE schedules SET deleted_at=NOW() WHERE id=?")->execute([$id]);
    }
}
