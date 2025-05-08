import 'package:flutter/material.dart';
import 'package:firebase_backend/models/task.dart';
import 'package:firebase_backend/services/api_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  Task? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() {
      _isLoading = true;
    });

    final task = await ApiService.getTask(widget.taskId);
    setState(() {
      _task = task;
      _isLoading = false;
    });

    if (task == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _task == null
          ? const Center(child: Text('Task not found'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _task!.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Task ID: ${_task!.taskId}'),
            Text('Status: ${_task!.status}'),
            Text('Created: ${_task!.createdAt.toIso8601String().substring(0, 16)}'),
            Text('Assigned to: ${_task!.userId}'),
          ],
        ),
      ),
    );
  }
}