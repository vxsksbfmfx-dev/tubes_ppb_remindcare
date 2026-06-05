<?php
namespace App\Models;

use App\Core\Model;

class Medicine extends Model
{
    protected string $table = 'medicines';

    public function search(string $q, int $limit = 20): array
    {
        $like = "%$q%";
        return $this->findAll(
            'name LIKE ? OR generic_name LIKE ? OR brand_name LIKE ?',
            [$like, $like, $like],
            'name ASC'
        );
    }
}
