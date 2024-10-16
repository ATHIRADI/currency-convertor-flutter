import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fromCurrency = "INR";
  String forCurrency = "USD";
  double rate = 0.0;
  double total = 0.0;
  bool isLoading = false;
  String? errorMessage;
  TextEditingController amountController = TextEditingController();
  List<String> currencies = [];

  @override
  void initState() {
    super.initState();
    getCurrencies();
  }

  Future<void> getCurrencies() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      var response = await http
          .get(Uri.parse("https://api.exchangerate-api.com/v4/latest/USD"));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          currencies = (data['rates'] as Map<String, dynamic>).keys.toList();
          rate = data['rates'][fromCurrency];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load currencies. Try again later.";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "An error occurred. Check your internet connection.";
        isLoading = false;
      });
    }
  }

  Future<void> getRate() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      var response = await http.get(Uri.parse(
          "https://api.exchangerate-api.com/v4/latest/$fromCurrency"));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          rate = data['rates'][forCurrency];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load exchange rate.";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "An error occurred. Check your internet connection.";
        isLoading = false;
      });
    }
  }

  void swapCurrencies() {
    setState(() {
      String temp = fromCurrency;
      fromCurrency = forCurrency;
      forCurrency = temp;
      getRate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              )
            else ...[
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      double amount = double.parse(value);
                      total = amount * rate;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCurrencyDropdown(fromCurrency, (newValue) {
                    setState(() {
                      fromCurrency = newValue!;
                      getRate();
                    });
                  }),
                  IconButton(
                    onPressed: swapCurrencies,
                    icon: const Icon(Icons.swap_horiz, size: 30),
                  ),
                  _buildCurrencyDropdown(forCurrency, (newValue) {
                    setState(() {
                      forCurrency = newValue!;
                      getRate();
                    });
                  }),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Rate: $rate",
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                total.toStringAsFixed(3),
                style: const TextStyle(fontSize: 30, color: Colors.blueAccent),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown(
      String selectedCurrency, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 100,
      child: DropdownButton<String>(
        value: selectedCurrency,
        isExpanded: true,
        onChanged: onChanged,
        items: currencies.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
}
