<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Session extends Model
{  
    protected $table = 'session';
   protected $fillable = [
        's_date',
        'end_date',
        'comment',
        'group_id',
    ];


    public function groups()
    {
        return $this->belongTo(Group::class);
    }
    
    protected function casts(): array
    {
        return [
            's_date' => 'datetime',
            'end_date' => 'datetime',
        ];
    }
}
