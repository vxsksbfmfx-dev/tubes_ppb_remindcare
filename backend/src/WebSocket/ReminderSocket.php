<?php
namespace App\WebSocket;

use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;
use App\Helpers\JwtHelper;

/**
 * WebSocket handler untuk real-time reminder RemindCare.
 *
 * Protocol pesan (JSON):
 *   Client → Server : { "type":"auth", "token":"..." }
 *   Client → Server : { "type":"subscribe", "elderly_id": 5 }
 *   Server → Client : { "type":"log_confirmed", "log": {...} }
 *   Server → Client : { "type":"reminder", "log": {...} }
 *   Server → Client : { "type":"error", "message":"..." }
 */
class ReminderSocket implements MessageComponentInterface
{
    /** @var \SplObjectStorage<ConnectionInterface, array> */
    private \SplObjectStorage $clients;

    /** @var array<int, array<ConnectionInterface>> indexed by elderly_id */
    private array $rooms = [];

    public function __construct()
    {
        $this->clients = new \SplObjectStorage();
        echo "RemindCare WebSocket Server started\n";
    }

    public function onOpen(ConnectionInterface $conn): void
    {
        $this->clients->attach($conn, ['user' => null, 'rooms' => []]);
        echo "New connection: #{$conn->resourceId}\n";
    }

    public function onMessage(ConnectionInterface $from, $msg): void
    {
        $data = json_decode($msg, true);
        if (!$data || !isset($data['type'])) {
            $from->send(json_encode(['type' => 'error', 'message' => 'Format pesan tidak valid']));
            return;
        }

        match ($data['type']) {
            'auth'      => $this->handleAuth($from, $data),
            'subscribe' => $this->handleSubscribe($from, $data),
            'broadcast' => $this->handleBroadcast($from, $data),
            default     => $from->send(json_encode(['type' => 'error', 'message' => 'Tipe tidak dikenal'])),
        };
    }

    private function handleAuth(ConnectionInterface $conn, array $data): void
    {
        $token   = $data['token'] ?? '';
        $payload = JwtHelper::verify($token);
        if (!$payload) {
            $conn->send(json_encode(['type' => 'error', 'message' => 'Token tidak valid']));
            $conn->close();
            return;
        }
        $meta = $this->clients[$conn];
        $meta['user'] = $payload;
        $this->clients[$conn] = $meta;
        $conn->send(json_encode(['type' => 'auth_ok', 'user_id' => $payload['sub']]));
        echo "Authenticated #{$conn->resourceId} as user {$payload['sub']}\n";
    }

    private function handleSubscribe(ConnectionInterface $conn, array $data): void
    {
        $meta = $this->clients[$conn];
        if (!$meta['user']) {
            $conn->send(json_encode(['type' => 'error', 'message' => 'Belum autentikasi']));
            return;
        }
        $elderlyId = (int) ($data['elderly_id'] ?? $meta['user']['sub']);
        if (!isset($this->rooms[$elderlyId])) {
            $this->rooms[$elderlyId] = [];
        }
        $this->rooms[$elderlyId][$conn->resourceId] = $conn;
        $meta['rooms'][] = $elderlyId;
        $this->clients[$conn] = $meta;
        $conn->send(json_encode(['type' => 'subscribed', 'elderly_id' => $elderlyId]));
        echo "Connection #{$conn->resourceId} subscribed to elderly:$elderlyId\n";
    }

    private function handleBroadcast(ConnectionInterface $from, array $data): void
    {
        $meta = $this->clients[$from];
        if (!$meta['user']) return;

        $elderlyId = (int) ($data['elderly_id'] ?? 0);
        if (!$elderlyId || !isset($this->rooms[$elderlyId])) return;

        $payload = json_encode([
            'type'      => $data['event'] ?? 'update',
            'elderly_id'=> $elderlyId,
            'data'      => $data['data'] ?? null,
        ]);

        foreach ($this->rooms[$elderlyId] as $rid => $conn) {
            if ($conn !== $from) {
                $conn->send($payload);
            }
        }
        echo "Broadcast to elderly:$elderlyId room\n";
    }

    public function onClose(ConnectionInterface $conn): void
    {
        $meta = $this->clients[$conn];
        foreach ($meta['rooms'] ?? [] as $elderlyId) {
            unset($this->rooms[$elderlyId][$conn->resourceId]);
        }
        $this->clients->detach($conn);
        echo "Connection #{$conn->resourceId} closed\n";
    }

    public function onError(ConnectionInterface $conn, \Exception $e): void
    {
        echo "Error on #{$conn->resourceId}: {$e->getMessage()}\n";
        $conn->close();
    }
}
