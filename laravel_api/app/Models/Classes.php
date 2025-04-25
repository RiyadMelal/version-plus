<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;


class Classes extends Model
{
    protected $fillable = [
        'name',
        'speciality',
        'level',
        'year',
        'semester'
    ];

    public function groups()
{
    return $this->hasMany(Group::class);
}

}
