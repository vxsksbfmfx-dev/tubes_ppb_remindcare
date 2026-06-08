<?php
namespace App\Controllers;

use App\Core\BaseController;
use App\Middleware\AuthMiddleware;
use App\Models\Schedule;

class ScheduleController extends BaseController
{
    private Schedule $schedule;
    private array    $user;

    public function __construct()
    {
        $this->user     = AuthMiddleware::handle();
        $this->schedule = new Schedule();
    }

    /** GET /api/schedules */
    public function index(): void
    {
        $elderlyId = $this->user['role'] === 'elderly'
            ? $this->user['sub']
            : (int)($_GET['elderly_id'] ?? $this->user['sub']);

        $rows = $this->schedule->findByElderly($elderlyId);
        $rows = array_map(function ($r) {
            $r['times'] = json_decode($r['times'], true);
            $r['days']  = $r['days'] ? json_decode($r['days'], true) : null;
            return $r;
        }, $rows);

        $this->success($rows);
    }

    /** POST /api/schedules */
    public function store(): void
    {
        $data   = $this->body();
        $errors = $this->validate($data, [
            'medicine_id' => 'required',
            'dose'        => 'required',
            'times'       => 'required',
            'start_date'  => 'required',
        ]);
        if ($errors) $this->error('Validasi gagal', 422, $errors);

        $data['created_by']     = $this->user['sub'];
        $data['elderly_user_id'] = $data['elderly_user_id'] ?? $this->user['sub'];
        $id = $this->schedule->create($data);
        $this->success(['id' => $id], 'Jadwal ditambahkan', 201);
    }

    /** PUT /api/schedules/{id} */
    public function update(string $id): void
    {
        $data = $this->body();
        $this->schedule->update((int)$id, $data);
        $this->success(null, 'Jadwal diperbarui');
    }

    /** DELETE /api/schedules/{id} */
    public function destroy(string $id): void
    {
        $this->schedule->softDelete((int)$id);
        $this->success(null, 'Jadwal dihapus');
    }
}
