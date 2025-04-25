<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Group extends Model
{
    protected $fillable = [
        'name',
        'type',
        'class_id'
    ];


    public function classes()
{
    return $this->belongsTo(Classes::class);
}

}
