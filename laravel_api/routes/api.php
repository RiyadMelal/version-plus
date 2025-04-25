<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClassController;
use App\Http\Controllers\GroupController;
use App\Http\Controllers\SessionController;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\AttendanceController;

Route::middleware('api')->group(function () {
    ////////////////////////classes./////////////////////
    Route::get('/classes', [ClassController::class, 'index']);
    Route::post('/classes', [ClassController::class, 'store']);
    Route::put('/classes/{id}', [ClassController::class, 'update']);
    Route::delete('/classes/{id}', [ClassController::class, 'destroy']);

    ///////////////groups////////////////////////
    Route::get('/groups', [GroupController::class, 'allGroups']);
    Route::get('/classes/{classId}/groups', [GroupController::class, 'index']);
    Route::post('/classes/{classId}/groups', [GroupController::class, 'store']);
    Route::put('/classes/{classId}/groups/{groupId}', [GroupController::class, 'update']);
    Route::delete('/classes/{classId}/groups/{groupId}', [GroupController::class, 'destroy']);

    ////////////////////students/////////////////
    // Global routes for students
 //  Route::get('/student', [StudentController::class, 'index']);
  //  Route::post('/student', [StudentController::class, 'store']);
  // Route::post('/student/import', [StudentController::class, 'import']);
    
    // Nested routes for students under groups
    Route::get('/students', [StudentController::class, 'allStudents']);
    Route::get('/groups/{groupId}/students', [StudentController::class, 'index']);
    Route::post('/groups/{groupId}/students', [StudentController::class, 'store']);
    Route::put('/groups/{groupId}/students/{id}', [StudentController::class, 'update']);
   // Route::delete('/groups/{groupId}/students/{id}', [StudentController::class, 'destroy']);
    Route::delete('/students/{id}', [StudentController::class, 'destroy']);
    ///////////session///////////////
    Route::get('/session', [SessionController::class, 'allSessions']);
    Route::get('/groups/{groupId}/session', [SessionController::class, 'index']);
    Route::post('/groups/{groupId}/session', [SessionController::class, 'store']);
    Route::put('/groups/{groupId}/session/{id}', [SessionController::class, 'update']);
   // Route::delete('/groups/{groupId}/session/{id}', [SessionController::class, 'destroy']);
    Route::delete('/session/{id}', [SessionController::class, 'destroy']);
    ////////////////////attendance/////////////////////////////////////////////////
    
    Route::get('/session/{sessionId}/attendances', [AttendanceController::class, 'index']);
    Route::post('/session/{sessionId}/attendances', [AttendanceController::class, 'store']);
    Route::put('/session/{sessionId}/attendances/{attendanceId}', [AttendanceController::class, 'update']);
    Route::delete('/session/{sessionId}/attendances/{attendanceId}', [AttendanceController::class, 'destroy']);
});