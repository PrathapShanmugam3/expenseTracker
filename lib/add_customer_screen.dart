import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'expense_calculator/utils/app_config.dart';
import 'customer_model.dart';


class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer; // Null for Add, Non-null for Edit

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  TimeOfDay? _selectedTime;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _areaController.text = widget.customer!.area;
      if (widget.customer!.callTime.isNotEmpty) {
        // Parse "HH:mm" to TimeOfDay
        final parts = widget.customer!.callTime.split(":");
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);

      try {
        final String callTimeStr = _selectedTime != null
            ? "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}"
            : "";

        final Map<String, dynamic> body = {
          "name": _nameController.text,
          "phone": _phoneController.text,
          "area": _areaController.text,
          "call_time": callTimeStr,
        };

        http.Response response;
        if (widget.customer == null) {
          // Add
          response = await http.post(
            Uri.parse('${AppConfig.baseUrl}/customers'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          );
        } else {
          // Edit
          response = await http.put(
            Uri.parse('${AppConfig.baseUrl}/customers/${widget.customer!.id}'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          );
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Notification scheduling removed as per user request

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Customer Saved Successfully!")),
            );
            Navigator.pop(context, true); // Return true to trigger refresh
          }
        } else {
          throw Exception('Failed to save customer');
        }
      } catch (e) {
        debugPrint("Error saving customer: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error saving customer")),
          );
        }
      } finally {
        if (mounted) setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? "Add Customer" : "Edit Customer"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) => value!.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  hintText: "+919876543210",
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? "Enter phone" : null,
              ),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: "Area"),
              ),
              const SizedBox(height: 20),
              isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: saveCustomer,
                      child: Text(widget.customer == null ? "Add Customer" : "Update Customer"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
