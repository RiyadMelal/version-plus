<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;
    protected $name = 'students';
    // If your table is named something other than 'students', uncomment below:
    // protected $table = 'students';

    protected $fillable = [
        'fname',
        'name',
        'email',
        'group_id'
        // add other columns here
    ];

   



    // Optional: Relationship to Group model
    public function group()
    {
        return $this->belongsTo(Group::class);
    }
}
