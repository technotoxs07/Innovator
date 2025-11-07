
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:innovator/Innovator/screens/Shop/Cart_List/api_services.dart';
import 'package:innovator/Innovator/models/Shop_cart_model.dart';
import 'package:path/path.dart' as path;


class DottedLine extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DottedLine({
    Key? key,
    required this.height,
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedLinePainter(
        height: height,
        color: color,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  _DottedLinePainter({
    required this.height,
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = height
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
  late PageController _pageController;
  int _currentStep = 0;

  late TabController _qrTabController;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _paymentScreenshot;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  bool _isProcessing = false;
  bool _isPaymentVerified = false;

  final String _merchantName = "Innovator Store";
  final String _merchantUPI = "Innovator@esewa";
  final String _merchantPhone = "+977-9803661701";

  final Color _primaryColor = const Color.fromRGBO(244, 135, 6, 1);
  final Color _accentColor = Colors.green;
  final Color _backgroundColor = Colors.grey.shade50;
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.blueGrey.shade800;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _qrTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _qrTabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      final form = _formKey.currentState;
      if (form == null || !form.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_currentStep == 2) {
      _submitOrder();
      return;
    }

    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
        final extension = path.extension(image.path).toLowerCase();
        if (!_isValidImageExtension(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid image file (JPEG, PNG, GIF, WebP)'), backgroundColor: Colors.red),
          );
          return;
        }

        final file = File(image.path);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size too large. Maximum 5MB allowed.'), backgroundColor: Colors.red),
          );
          return;
        }

        setState(() => _paymentScreenshot = file);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Flexible(child: Text('Payment screenshot uploaded successfully')),
            ]),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _takePaymentScreenshot() async {
    try {
      final XFile? image =  await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final extension = path.extension(image.path).toLowerCase();
        if (!_isValidImageExtension(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid file type. Please try again.'), backgroundColor: Colors.red),
          );
          return;
        }

        final file = File(image.path);
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image too large. Try lower quality.'), backgroundColor: Colors.red),
          );
          return;
        }

        setState(() => _paymentScreenshot = file);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.camera_alt, color: Colors.white),
              SizedBox(width: 12),
              Text('Payment screenshot captured successfully'),
            ]),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  bool _isValidImageExtension(String ext) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: const [
          Icon(Icons.copy, color: Colors.white),
          SizedBox(width: 12),
          Text('Copied to clipboard'),
        ]),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Future<void> _submitOrder() async {
  //   if (!_formKey.currentState!.validate()) {
  //     _currentStep = 0;
  //     _pageController.jumpToPage(0);
  //     return;
  //   }

  //   if (_paymentScreenshot == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please attach payment screenshot first'), backgroundColor: Colors.orange),
  //     );
  //     _currentStep = 2;
  //     _pageController.jumpToPage(2);
  //     return;
  //   }

  //   if (!await _paymentScreenshot!.exists()) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('File missing. Please upload again.'), backgroundColor: Colors.red),
  //     );
  //     setState(() => _paymentScreenshot = null);
  //     return;
  //   }

  //   setState(() => _isProcessing = true);

  //   try {
  //     final customerInfo = CustomerInfo(
  //       name: _nameController.text.trim(),
  //       phone: _phoneController.text.trim(),
  //       address: _addressController.text.trim(),
  //     );

  //     final response = await _apiService.checkout(
  //       customerInfo: customerInfo,
  //       paidAmount: widget.totalAmount,
  //       paymentProof: _paymentScreenshot!,
  //       notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
  //     );

  //     setState(() {
  //       _isProcessing = false;
  //       _isPaymentVerified = true;
  //     });

  //     _showOrderSuccessDialog(response);
  //   } catch (e) {
  //     setState(() => _isProcessing = false);
  //     String msg = e.toString();
  //     if (msg.contains('Exception:')) msg = msg.split('Exception:').last.trim();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Order failed: $msg'),
  //         backgroundColor: Colors.red,
  //         action: SnackBarAction(label: 'RETRY', textColor: Colors.white, onPressed: _submitOrder),
  //       ),
  //     );
  //   }
  // }
   void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }


 Future<void> _submitOrder() async {
    if (_paymentScreenshot == null) {
      _showSnackBar('Please upload payment proof', Colors.orange);
      return;
    }

    if (!await _paymentScreenshot!.exists()) {
      _showSnackBar('File missing. Re-upload.', Colors.red);
      setState(() => _paymentScreenshot = null);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final customerInfo = CustomerInfo(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      final response = await _apiService.checkout(
        customerInfo: customerInfo,
        paidAmount: widget.totalAmount,
        paymentProof: _paymentScreenshot!,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      setState(() => _isProcessing = false);
      _showOrderSuccessDialog(response);
    } catch (e) {
      setState(() => _isProcessing = false);
      String msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      _showSnackBar('Order failed: $msg', Colors.red);
    }
  }

  void _showOrderSuccessDialog(CheckoutResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _accentColor.withAlpha(10), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            const Text('Order Placed Successfully!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(response.data?.message ?? 'Your order is being processed.', textAlign: TextAlign.center),
            if (response.data?.orders.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _primaryColor.withAlpha(10), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    const Text('Order Numbers:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...response.data!.orders.map((o) => Text(o.orderNumber, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.only(right: 15,left:15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildOrderSummary(),
            const SizedBox(height: 16),
            _buildStepper(),
            const SizedBox(height: 16),       
                   const Text('Customer Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
        
                  _buildCustomerInfoTab(),
                  _buildQRPaymentTab(),
                  _buildUploadProofTab(),
                ],
              ),
            ),

            SizedBox(height: 10,),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }


  Widget _buildStepper() {
    final steps = [
      {'icon': Icons.person, 'label': 'Customer Info'},
      {'icon': Icons.qr_code, 'label': 'QR Payment'},
      {'icon': Icons.upload_file, 'label': 'Upload Proof'},
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index == _currentStep;
        final isDone = index < _currentStep;
    
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? _primaryColor : (isDone ? _accentColor : Colors.grey.shade300),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Icon(
                      isDone ? Icons.check : step['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? _primaryColor : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (index < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? _accentColor : Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }


  Widget _buildOrderSummary() {
    return Column(
      children: [
        _buildSummaryRow('Total Items', '${widget.itemCount}'),
        _buildSummaryRow('Sub-Total', 'NPR ${widget.totalAmount.toStringAsFixed(2)}'),
        _buildSummaryRow('Shipping', 'NPR 0.00'),
         Container(
      width: double.infinity,
      height: 10,
      child: const DottedLine(
        height: 2,
        color: Colors.grey,
        dashWidth: 6,
        dashSpace: 10,
      ),
    ),
        _buildSummaryRow('Total Amount', 'NPR ${widget.totalAmount.toStringAsFixed(2)}', isTotal: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, color: isTotal ? _textColor : Colors.grey.shade600, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, color: isTotal ? _primaryColor : _textColor)),
        ],
      ),
    );
  }


  Widget _buildBottomNavigation() {
    final isLastStep = _currentStep == 2;
    final isQRStep = _currentStep == 1;
    final buttonText = isLastStep ? 'SUBMIT ORDER' : (isQRStep ? 'PAY THE AMOUNT' : 'NEXT');

    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: _cardColor, boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(foregroundColor: _primaryColor, side: BorderSide(color: _primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep > 0 ? 2 : 1,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _nextStep,
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoTab() {
    return SingleChildScrollView(
   
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            _buildTextField('Full Name *',_nameController, 'Full Name *', Icons.person, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            _buildTextField('Phone Number *',_phoneController, 'Phone Number *', Icons.phone, keyboardType: TextInputType.phone, validator: (v) => v!.length < 10 ? 'Invalid phone' : null),
            const SizedBox(height: 16),
            _buildTextField('Delivery Address *',_addressController, 'Delivery Address *', Icons.location_on, maxLines: 3, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            _buildTextField('Notes(Optional)',_notesController, 'Order Notes (Optional)', Icons.note, maxLines: 2),
            const SizedBox(height: 20),
             
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String info ,TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int? maxLines, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info,style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500
        ),),
        SizedBox(height: 5,),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          
          decoration: InputDecoration(
                                  
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontFamily: 'InterThin',
                                    ),
                                    
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Color.fromRGBO(244, 135, 6, 1),
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                  ),
          validator: validator,
        ),
      ],
    );
  }


  Widget _buildQRPaymentTab() {
    return SingleChildScrollView(
   
      child: Column(
        children: [
          Column(
            children: [
              Container(
                // margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, 
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8)),
                child: TabBar(
                  controller: _qrTabController,
                  indicatorSize: TabBarIndicatorSize.tab,
          
                  indicator: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))]),
                  labelColor: _textColor,
                  unselectedLabelColor: _textColor.withAlpha(60),
                  tabs:  [
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.account_balance_wallet, size: 18), SizedBox(width: 8), Text('eSewa')])),
                    Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.payment, size: 18), SizedBox(width: 8), Text('Laxmi Bank')])),
                  ],
                ),
              ),
               SizedBox(height: 300, child: TabBarView(controller: _qrTabController, children: [_buildEsewaQRTab(), _buildLaxmiQRTab()])),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentDetailsCard(),
          const SizedBox(height: 16),
          _buildInstructionsCard(),
        ],
      ),
    );
  }

  Widget _buildEsewaQRTab() => _buildQRTabContent('eSewa Payment', 'assets/images/qr_code.jpeg', Colors.green);
  Widget _buildLaxmiQRTab() => _buildQRTabContent('Laxmi Bank Payment', 'assets/images/laxmi_sunrise.jpeg', Colors.purple);

  Widget _buildQRTabContent(String title, String asset, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(30), width: 2)),
            child: Column(
              children: [
                Image.asset(asset, width: 140, height: 140, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 35)),
                const SizedBox(height: 10),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withAlpha(10), borderRadius: BorderRadius.circular(15)), child: Text('Scan with App', style: TextStyle(fontSize: 11, color: Colors.green.shade700))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manual Payment Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildDetailRow('Merchant:', _merchantName),
          _buildDetailRow('UPI ID:', _merchantUPI),
          _buildDetailRow('Phone:', _merchantPhone),
          _buildDetailRow('Amount:', 'NPR ${widget.totalAmount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _textColor.withAlpha(70), fontSize: 13)),
        GestureDetector(
          onTap: () => _copyToClipboard(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _primaryColor.withAlpha(10), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(value, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(Icons.copy, size: 14, color: Colors.orange),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [Icon(Icons.info, color: Colors.blue), SizedBox(width: 8), Text('Payment Instructions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))]),
        const SizedBox(height: 12),
        Text('1. Choose payment method\n2. Scan QR code\n3. Enter NPR ${widget.totalAmount.toStringAsFixed(2)}\n4. Complete payment\n5. Take screenshot\n6. Upload in next step', style: const TextStyle(fontSize: 13, height: 1.5)),
      ],
    );
  }


  Widget _buildUploadProofTab() {
    return SingleChildScrollView(

      child: Column(
        children: [
          Column(
            children: [
              const Text('Upload Payment Screenshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (_paymentScreenshot != null) ...[
                Container(height: 200, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: _accentColor, width: 2)), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_paymentScreenshot!, fit: BoxFit.cover))),
                const SizedBox(height: 16),
                Row(children: const [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                TextButton.icon(onPressed: () => setState(() => _paymentScreenshot = null), icon: const Icon(Icons.delete, color: Colors.red), label: const Text('Remove', style: TextStyle(color: Colors.red))),
              ] else
                GestureDetector(
                  
                  onTap: () => showAdaptiveDialog(
                    
                    context: context, 
                    
                    builder: (context){
                  
                 
                     return AlertDialog(
                      backgroundColor: Colors.white,
                      title: Text('Choose Image Source'),
                      content:               Row(
                children: [
                  ElevatedButton.icon(
                    
                    onPressed: (){
                         _pickPaymentScreenshot();
                           Navigator.pop(context);
                    }
                  
               , icon: const Icon(Icons.photo_library), label: const Text('Gallery'), 
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor)),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed:(){
                      _takePaymentScreenshot();
                       Navigator.pop(context);
                    } , icon: const Icon(Icons.camera_alt), label: const Text('Camera'), style: ElevatedButton.styleFrom(backgroundColor: _accentColor)),
                ],
              ),
              
                     );
                     
                    
                  }
                 
                  ),
                    
                  
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(color: _primaryColor.withAlpha(2), borderRadius: BorderRadius.circular(12), border: Border.all(color: _primaryColor.withAlpha(30), width: 2)),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload, size: 48, color: Colors.orange), SizedBox(height: 16), Text('Upload Screenshot', style: TextStyle(fontWeight: FontWeight.w500)), Text('PNG, JPG up to 5MB', style: TextStyle(color: Colors.grey))]),
                  ),
                ),
              

            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.white,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:  [
                  Row(children: [Icon(Icons.warning, color: Colors.orange), SizedBox(width: 8), Text('Important Notes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))]),
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
          ),
        ],
      ),
    );
  }
}
