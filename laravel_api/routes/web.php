<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClassController;
use App\Http\Controllers\GroupController;

Route::middleware('api')->group(function () {
    Route::get('/classes', [ClassController::class, 'index']);
    Route::post('/classes', [ClassController::class, 'store']);
    Route::put('/classes/{id}', [ClassController::class, 'update']);
    Route::delete('/classes/{id}', [ClassController::class, 'destroy']);

    Route::get('/groups', [GroupController::class, 'allGroups']);
    Route::get('/classes/{classId}/groups', [GroupController::class, 'index']);
    Route::post('/classes/{classId}/groups', [GroupController::class, 'store']);
    Route::put('/classes/{classId}/groups/{groupId}', [GroupController::class, 'update']);
    Route::delete('/classes/{classId}/groups/{groupId}', [GroupController::class, 'destroy']);
});

