import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/user_profile_service.dart';
import 'customer_home_screen.dart';

class AddressFormScreen extends StatefulWidget {
  final UserAddress? address; // null for new address
  final bool isFirstAddress;

  const AddressFormScreen({
    super.key,
    this.address,
    this.isFirstAddress = false,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;

  final List<String> _addressLabels = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadExistingAddress();
  }

  void _loadExistingAddress() {
    if (widget.address != null) {
      final address = widget.address!;
      setState(() {
        _fullNameController.text = address.fullName;
        _phoneController.text = address.phoneNumber;
        _addressLine1Controller.text = address.addressLine1;
        _addressLine2Controller.text = address.addressLine2;
        _cityController.text = address.city;
        _stateController.text = address.state;
        _pincodeController.text = address.pincode;
        _selectedLabel = address.label;
        _isDefault = address.isDefault;
      });
    } else if (widget.isFirstAddress) {
      // For first address, make it default
      setState(() {
        _isDefault = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isFirstAddress) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Your First Address',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'This will be used for your orders and deliveries.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address Label
                  const Text(
                    'Address Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _addressLabels.map((label) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _selectedLabel == label,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedLabel = label;
                                });
                              }
                            },
                            selectedColor: Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color: _selectedLabel == label
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Full Name
                  _buildTextField(
                    label: 'Full Name *',
                    controller: _fullNameController,
                    hint: 'Enter full name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone Number
                  _buildTextField(
                    label: 'Phone Number *',
                    controller: _phoneController,
                    hint: 'Enter phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      if (value.length < 10) {
                        return 'Phone number should be at least 10 digits';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Address Line 1
                  _buildTextField(
                    label: 'Address Line 1 *',
                    controller: _addressLine1Controller,
                    hint: 'House number, building name, street',
                    icon: Icons.home_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Address line 1 is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Address Line 2
                  _buildTextField(
                    label: 'Address Line 2',
                    controller: _addressLine2Controller,
                    hint: 'Area, landmark (optional)',
                    icon: Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 16),

                  // City and State
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'City *',
                          controller: _cityController,
                          hint: 'Enter city',
                          icon: Icons.location_city_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'City is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          label: 'State *',
                          controller: _stateController,
                          hint: 'Enter state',
                          icon: Icons.map_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'State is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Pincode
                  _buildTextField(
                    label: 'Pincode *',
                    controller: _pincodeController,
                    hint: 'Enter pincode',
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Pincode is required';
                      }
                      if (value.length != 6) {
                        return 'Pincode should be 6 digits';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Default Address Checkbox
                  if (!widget.isFirstAddress)
                    CheckboxListTile(
                      title: const Text('Set as default address'),
                      subtitle: const Text('This address will be used for new orders'),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue.shade600,
                    ),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Address' : 'Save Address',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final address = UserAddress(
        id: widget.address?.id ?? '',
        label: _selectedLabel,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.address != null) {
        // Update existing address
        success = await UserProfileService.updateAddress(address);
      } else {
        // Add new address
        final addressId = await UserProfileService.addAddress(address);
        success = addressId != null;
      }

      if (success) {
        // If this is the first address, mark profile as completed
        if (widget.isFirstAddress) {
          await UserProfileService.markProfileCompleted();
          
          // Navigate to home screen
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
              (route) => false,
            );
          }
        } else {
          // Go back to previous screen
          if (mounted) {
            Navigator.pop(context, true); // Pass true to indicate success
          }
        }
      } else {
        _showErrorSnackBar('Failed to save address. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
}
