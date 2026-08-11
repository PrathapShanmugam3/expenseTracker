import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'expense_calculator/utils/app_config.dart';
import 'customer_model.dart';

class OrderEntryScreen extends StatefulWidget {
  final Customer customer;
  const OrderEntryScreen({super.key, required this.customer});

  @override
  State<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool isSubmitting = false;

  Future<void> submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);
      
      try {
        final response = await http.post(
          Uri.parse('${AppConfig.baseUrl}/orders'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "customerId": widget.customer.id,
            "product": _productController.text,
            "quantity": int.parse(_quantityController.text),
            "price": double.parse(_priceController.text),
          }),
        );

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Order Saved Successfully!")),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('Failed to save order');
        }
      } catch (e) {
        debugPrint("Error saving order: $e");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error saving order (Check backend connection)")),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("New Order", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Customer: ${widget.customer.name}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _productController,
                decoration: InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) => value!.isEmpty ? "Enter product" : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? "Enter quantity" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: "Price",
                        prefixText: "₹ ",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? "Enter price" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Text("Save Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
