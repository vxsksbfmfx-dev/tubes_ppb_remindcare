<?php
namespace App\Core;

use PDO;

abstract class Model
{
    protected PDO    $db;
    protected string $table  = '';
    protected string $pk     = 'id';

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    public function findAll(string $where = '', array $params = [], string $order = 'id DESC'): array
    {
        $sql = "SELECT * FROM {$this->table}";
        if ($where) $sql .= " WHERE $where";
        $sql .= " ORDER BY $order";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    public function findOne(string $where, array $params): ?array
    {
        $sql  = "SELECT * FROM {$this->table} WHERE $where LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $row  = $stmt->fetch();
        return $row ?: null;
    }

    public function findById(int $id): ?array
    {
        return $this->findOne("{$this->pk} = ?", [$id]);
    }

    public function insert(array $data): int
    {
        $data['created_at'] = $data['updated_at'] = date('Y-m-d H:i:s');
        $cols   = implode(', ', array_keys($data));
        $places = implode(', ', array_fill(0, count($data), '?'));
        $stmt   = $this->db->prepare("INSERT INTO {$this->table} ($cols) VALUES ($places)");
        $stmt->execute(array_values($data));
        return (int) $this->db->lastInsertId();
    }

    public function update(int $id, array $data): bool
    {
        $data['updated_at'] = date('Y-m-d H:i:s');
        $sets = implode(', ', array_map(fn($k) => "$k = ?", array_keys($data)));
        $stmt = $this->db->prepare("UPDATE {$this->table} SET $sets WHERE {$this->pk} = ?");
        return $stmt->execute([...array_values($data), $id]);
    }

    public function delete(int $id): bool
    {
        $stmt = $this->db->prepare("DELETE FROM {$this->table} WHERE {$this->pk} = ?");
        return $stmt->execute([$id]);
    }

    public function count(string $where = '', array $params = []): int
    {
        $sql = "SELECT COUNT(*) FROM {$this->table}";
        if ($where) $sql .= " WHERE $where";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        return (int) $stmt->fetchColumn();
    }
}
