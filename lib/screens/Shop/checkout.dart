import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  final int itemCount;
  final List<dynamic> cartItems;

  const CheckoutScreen({
    Key? key,
    required this.totalAmount,
    required this.itemCount,
    required this.cartItems,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _qrTabController;

  File? _paymentScreenshot;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  bool _isPaymentVerified = false;

  // Payment details
  final String _qrPaymentData = "upi://pay?pa=merchant@upi&pn=MerchantName&am=";
  final String _merchantName = "Innovator Store";
  final String _merchantUPI = "Innovator@esewa";
  final String _merchantPhone = "+977-9803661701";

  // Colors
  final Color _primaryColor = Color.fromRGBO(244, 135, 6, 1);
  final Color _accentColor = Colors.green;
  final Color _backgroundColor = Colors.grey.shade50;
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.blueGrey.shade800;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
      _qrTabController = TabController(length: 2, vsync: this); // Add this line

  }

  @override
  void dispose() {
    _tabController.dispose();
      _qrTabController.dispose(); // Add this line

    super.dispose();
  }

  Future<void> _pickPaymentScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _paymentScreenshot = File(image.path);
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Payment screenshot uploaded successfully'),
              ],
            ),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePaymentScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _paymentScreenshot = File(image.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.white),
                SizedBox(width: 12),
                Text('Payment screenshot captured successfully'),
              ],
            ),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.copy, color: Colors.white),
            SizedBox(width: 12),
            Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_paymentScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please attach payment screenshot first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
      _isPaymentVerified = true;
    });

    // Show success dialog
    _showOrderSuccessDialog();
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: _accentColor,
                  size: 60,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Your order has been received and is being processed.',
                style: TextStyle(
                  fontSize: 14,
                  color: _textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                child: Text('Continue Shopping'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(Icons.qr_code),
              text: 'QR Payment',
            ),
            Tab(
              icon: Icon(Icons.upload_file),
              text: 'Upload Proof',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Order summary
          _buildOrderSummary(),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQRPaymentTab(),
                _buildUploadProofTab(),
              ],
            ),
          ),
          // Submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.itemCount} items',
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 16,
                  color: _textColor,
                ),
              ),
              Text(
                'NPR ${widget.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRPaymentTab() {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        // QR Payment Method Tabs
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Tab Bar for QR Methods
              Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _qrTabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: _textColor,
                  unselectedLabelColor: _textColor.withOpacity(0.6),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet, size: 18),
                          SizedBox(width: 8),
                          Text('eSewa'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, size: 18),
                          SizedBox(width: 8),
                          Text('Laxmi Bank'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tab Content with proper height constraint
              SizedBox(
                height: 300, // Fixed height for TabBarView
                child: TabBarView(
                  controller: _qrTabController,
                  children: [
                    _buildEsewaQRTab(),
                    _buildKhaltiQRTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Payment Details
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Manual Payment Details:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              _buildPaymentDetailRow('Merchant:', _merchantName),
              _buildPaymentDetailRow('UPI ID:', _merchantUPI),
              _buildPaymentDetailRow('Phone:', _merchantPhone),
              _buildPaymentDetailRow('Amount:', 'NPR ${widget.totalAmount.toStringAsFixed(2)}'),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Instructions
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Payment Instructions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '1. Choose your preferred payment method (eSewa or Khalti)\n'
                '2. Scan the QR code using your mobile app\n'
                '3. Enter the exact amount: NPR ${widget.totalAmount.toStringAsFixed(2)}\n'
                '4. Complete the payment\n'
                '5. Take a screenshot of the payment confirmation\n'
                '6. Upload the screenshot in the "Upload Proof" tab',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


Widget _buildEsewaQRTab() {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'eSewa Payment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/images/qr_code.jpeg',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code,
                          size: 35,
                          color: Colors.green.withOpacity(0.5),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'eSewa QR Code',
                          style: TextStyle(
                            color: Colors.green.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Scan with eSewa App',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
// Khalti QR Tab Content
Widget _buildKhaltiQRTab() {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Laxmi Payment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/images/khalti_qr.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code,
                          size: 35,
                          color: Colors.purple.withOpacity(0.5),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Khalti QR Code',
                          style: TextStyle(
                            color: Colors.purple.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Scan with Khalti App',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildPaymentDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _textColor.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          GestureDetector(
            onTap: () => _copyToClipboard(value),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.copy,
                    size: 14,
                    color: _primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProofTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Upload section
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Upload Payment Screenshot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 20),
                if (_paymentScreenshot != null) ...[
                  // Show uploaded image
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _accentColor,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _paymentScreenshot!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: _accentColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment screenshot uploaded successfully',
                          style: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _paymentScreenshot = null;
                      });
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      'Remove Screenshot',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ] else ...[
                  // Upload placeholder
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CustomPaint(
                      painter: DashedBorderPainter(
                        color: _primaryColor.withOpacity(0.5),
                        strokeWidth: 2,
                        dashPattern: [8, 4],
                      ),
                      child: Container(
                        margin: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 48,
                              color: _primaryColor.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Upload Payment Screenshot',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _textColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'PNG, JPG up to 5MB',
                              style: TextStyle(
                                color: _textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 24),
                // Upload buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickPaymentScreenshot,
                        icon: Icon(Icons.photo_library),
                        label: Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _takePaymentScreenshot,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Important notes
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Important Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '• Please ensure the screenshot clearly shows the payment amount\n'
                  '• Payment amount should match: NPR ${widget.totalAmount.toStringAsFixed(2)}\n'
                  '• Screenshot should include transaction ID and timestamp\n'
                  '• Your order will be processed after payment verification',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _submitOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Processing Order...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'SUBMIT ORDER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(12),
      ));

    _drawDashedPath(canvas, path, paint, dashPattern);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, List<double> dashPattern) {
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < pathMetric.length) {
        final double length = dashPattern[draw ? 0 : 1];
        if (draw) {
          canvas.drawPath(
            pathMetric.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}