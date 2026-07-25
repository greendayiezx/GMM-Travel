<?php

namespace App\Repositories\Contracts;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Collection;

interface BaseRepositoryInterface
{
    public function all(): Collection;

    public function find(string $id): ?Model;

    public function create(array $attributes): Model;

    public function update(string $id, array $attributes): bool;

    public function delete(string $id): bool;
}
