<?php

namespace App\Http\Controllers;

use App\Models\Student;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Log;

class StudentController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index($groupId)
    {
        return Student::where('group_id', $groupId)->get();
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request, $groupId)
    {
        $validated = $request->validate([
            'fname' => 'required|string|max:255',
            'name' => 'required|string|max:255',
            'email' => 'string|max:255',
        ]);

        $students = new Student($validated);
        $students->group_id = $groupId;
        $students->save();

        return response()->json($students, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Student $student)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Student $student)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $groupId, $id)
    {
        $student = Student::where('group_id', $groupId)->findOrFail($id);

        $student->update($request->only('fname', 'name', 'email','group_id'));

        return response()->json($student);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy($id)
    {
        $student = Student::where('id', $id)->findOrFail($id);
        $student->delete();

        return response()->json(null, 204);
    }

    /**
     * Import students from a file.
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|file|mimes:xls,xlsx,csv'
        ]);

        $filePath = $request->file('file')->getRealPath();
        $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($filePath);
        $sheet = $spreadsheet->getActiveSheet();
        $rows = $sheet->toArray();

        $header = array_map('strtolower', $rows[0]);
        unset($rows[0]);

        foreach ($rows as $row) {
            $data = array_combine($header, $row);
            Student::create([
                'fname' => $data['family name'] ?? '',
                'name'  => $data['name'] ?? '',
                'email'  => $data['email'] ?? '',
                'group_id' => $data['group id'] ?? null,
            ]);
        }

        return response()->json(['message' => 'Students imported successfully']);
    }

    function allStudents()
    {
        $students = Student::all();
        return response()->json(['data' => $students]);
    }

    /**
     * Get students by group.
     */
    public function getByGroup($groupId)
    {
        $students = Student::where('group_id', $groupId)->get();
        return response()->json($students);
    }
}