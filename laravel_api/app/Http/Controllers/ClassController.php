<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Classes;
use Illuminate\Support\Facades\Log;

class ClassController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {   
        $classes= Classes::all();
        return response()->json($classes);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    { // validation here dont forget !!!!!! 
    $class = new Classes();
    $class->name = $request->input('name');
    $class->speciality = $request->input('speciality');
    $class->level = $request->input('level');
    $class->year = $request->input('year');
    $class->semester = $request->input('semester');
    
    $class->save();

    return response()->json($class, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $class = Classes::findOrFail($id);
        $class->update($request->all());
        return response()->json($class);
    }

    /**
     * Remove the specified resource from storage.
     */
    // Your backend delete method in the controller
public function destroy(int $id)
{
    Classes::destroy($id);  // Ensure the type here is an integer
    return response()->json(null, 204);
}

}
