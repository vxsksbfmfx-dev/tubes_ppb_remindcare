<?php
namespace App\Controllers;

use App\Core\BaseController;
use App\Models\User;
use App\Services\FcmService;

class NotificationController extends BaseController
{
    private User       $user;
    private FcmService $fcm;

    public function __construct()
    {
        $this->user = new User();
        $this->fcm  = new FcmService();
    }

    /**
     * POST /api/notifications/token
     * Body: { "fcm_token": "..." }
     * Simpan/update FCM token milik user yang sedang login.
     */
    public function saveToken(): void
    {
        $payload = $this->requireAuth();
        $data    = $this->body();

        if (empty($data['fcm_token'])) {
            $this->error('fcm_token wajib diisi', 400);
        }

        $this->user->update($payload['sub'], ['fcm_token' => $data['fcm_token']]);
        $this->success(null, 'FCM token berhasil disimpan');
    }

    /**
     * POST /api/notifications/test
     * Body: { "title": "...", "body": "...", "data": {} }
     * Kirim notif ke diri sendiri — untuk testing.
     */
    public function test(): void
    {
        $payload = $this->requireAuth();
        $user    = $this->user->findById($payload['sub']);

        if (empty($user['fcm_token'])) {
            $this->error('FCM token belum tersimpan untuk akun ini', 400);
        }

        $data  = $this->body();
        $title = $data['title'] ?? 'RemindCare';
        $body  = $data['body']  ?? 'Test notifikasi';
        $extra = $data['data']  ?? [];

        $ok = $this->fcm->sendToToken($user['fcm_token'], $title, $body, $extra);
        if ($ok) {
            $this->success(null, 'Notifikasi berhasil dikirim');
        } else {
            $this->error('Gagal mengirim notifikasi — cek FCM config', 500);
        }
    }

    /**
     * POST /api/notifications/reminder/{scheduleId}
     * Dipanggil internal (mis. dari cron job atau saat konfirmasi terlambat).
     * Kirim pengingat minum obat ke user pemilik jadwal.
     */
    public function sendReminder(string $scheduleId): void
    {
        // Ambil data jadwal + user
        $db       = \App\Core\Database::getInstance();
        $stmt     = $db->prepare(
            'SELECT s.*, u.fcm_token, u.name as user_name, m.name as medicine_name
             FROM schedules s
             JOIN users u ON u.id = s.user_id
             JOIN medicines m ON m.id = s.medicine_id
             WHERE s.id = ?'
        );
        $stmt->execute([(int)$scheduleId]);
        $schedule = $stmt->fetch();

        if (!$schedule) {
            $this->error('Jadwal tidak ditemukan', 404);
        }

        if (empty($schedule['fcm_token'])) {
            $this->error('User tidak memiliki FCM token', 400);
        }

        $ok = $this->fcm->sendToToken(
            $schedule['fcm_token'],
            '⏰ Waktunya Minum Obat!',
            "Hei {$schedule['user_name']}, saatnya minum {$schedule['medicine_name']}",
            [
                'type'        => 'reminder',
                'schedule_id' => (string)$scheduleId,
                'medicine'    => $schedule['medicine_name'],
            ]
        );

        $ok
          ? $this->success(null, 'Pengingat berhasil dikirim')
          : $this->error('Gagal mengirim pengingat', 500);
    }
}
