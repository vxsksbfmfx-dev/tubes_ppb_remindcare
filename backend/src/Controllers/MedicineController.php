<?php
namespace App\Controllers;

use App\Core\BaseController;
use App\Models\Medicine;

class MedicineController extends BaseController
{
    private Medicine $model;

    public function __construct()
    {
        $this->model = new Medicine();
    }

    /** GET /api/medicines?search= */
    public function index(): void
    {
        $q    = $_GET['search'] ?? '';
        $list = $this->model->search($q);
        $this->success($list);
    }

    /** GET /api/medicines/{id} */
    public function show(string $id): void
    {
        $row = $this->model->findById((int)$id);
        if (!$row) $this->error('Obat tidak ditemukan', 404);
        $this->success($row);
    }

    /** POST /api/medicines */
    public function store(): void
    {
        $data   = $this->body();
        $errors = $this->validate($data, ['name' => 'required']);
        if ($errors) $this->error('Validasi gagal', 422, $errors);

        $id  = $this->model->insert([
            'name'         => $data['name'],
            'generic_name' => $data['generic_name'] ?? null,
            'brand_name'   => $data['brand_name']   ?? null,
            'description'  => $data['description']  ?? null,
        ]);
        $this->success($this->model->findById($id), 'Obat berhasil ditambahkan', 201);
    }

    /** PUT /api/medicines/{id} */
    public function update(string $id): void
    {
        $row = $this->model->findById((int)$id);
        if (!$row) $this->error('Obat tidak ditemukan', 404);

        $data = $this->body();
        $this->model->update((int)$id, array_filter([
            'name'         => $data['name']         ?? null,
            'generic_name' => $data['generic_name'] ?? null,
            'brand_name'   => $data['brand_name']   ?? null,
            'description'  => $data['description']  ?? null,
        ], fn($v) => $v !== null));

        $this->success($this->model->findById((int)$id), 'Obat berhasil diperbarui');
    }

    /** DELETE /api/medicines/{id} */
    public function destroy(string $id): void
    {
        $row = $this->model->findById((int)$id);
        if (!$row) $this->error('Obat tidak ditemukan', 404);
        $this->model->delete((int)$id);
        $this->success(null, 'Obat berhasil dihapus');
    }
}
