<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Group;

class GroupController extends Controller
{
    // Get all groups for a specific class
    public function index($classId)
    {
        $groups = Group::where('class_id', $classId)->get();
        return response()->json(['data' => $groups]);
    }

    // Create a group under a specific class
    public function store(Request $request, $classId)
    {
        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|string|max:255',
        ]);

        $group = new Group();
        $group->name = $validatedData['name'];
        $group->type = $validatedData['type'];
        $group->class_id = $classId;
        $group->save();
        return response()->json(['data' => $group], 201);
    }

    // Show a specific group by ID and class ID
    public function show($classId, $groupId)
    {
        $group = Group::where('class_id', $classId)
                      ->where('id', $groupId)
                      ->firstOrFail();

        return response()->json(['data' => $group]);
    }

    // Update a group
    public function update(Request $request, $classId, $groupId)
    {
        $validatedData = $request->validate([
            'name' => 'string|max:255',
            'type' => 'string|max:255',
        ]);

        $group = Group::where('class_id', $classId)
                      ->where('id', $groupId)
                      ->firstOrFail();

        $group->update($validatedData);

        return response()->json(['data' => $group]);
    }

    // Delete a group
    public function destroy($classId, $groupId)
    {
        $group = Group::where('class_id', $classId)
                      ->where('id', $groupId)
                      ->firstOrFail();

        $group->delete();

        return response()->json(null, 204);
    }

    // Get all groups (admin/global view)
    public function allGroups()
    {
        $groups = Group::all();
        return response()->json(['data' => $groups]);
    }
    
}
