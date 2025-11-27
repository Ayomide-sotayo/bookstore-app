// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';
import '../logic/book_admin_controller.dart';

class BookForm extends StatefulWidget {
  final BookModel? book;
  final VoidCallback onBookAdded;

  const BookForm({super.key, this.book, required this.onBookAdded});

  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final controller = BookAdminController();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isSubmitting = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _authorController = TextEditingController(text: widget.book?.author ?? '');
    _priceController = TextEditingController(
      text: widget.book?.price.toString() ?? '',
    );
    _descController = TextEditingController(
      text: widget.book?.description ?? '',
    );
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFE57373),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF66BB6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar("Error picking image: $e");
    }
  }

  // Replace your _uploadImage method with this (everything else stays the same!)
  Future<String?> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      // 1. Verify file exists
      if (!await imageFile.exists()) {
        throw Exception("Selected image file does not exist");
      }

      print("📁 File exists: ${imageFile.path}");
      print("📏 File size: ${await imageFile.length()} bytes");

      // 2. Create safe filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = imageFile.path.split('/').last;
      final extension =
          fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final safeFilename = 'book_${timestamp}.${extension}';

      print("🔗 Upload filename: $safeFilename");

      // 3. Upload to Supabase Storage
      final supabase = Supabase.instance.client;

      final uploadResponse = await supabase.storage
          .from('book_images')
          .upload(
            safeFilename,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      print("✅ Upload successful: $uploadResponse");

      // 4. Get public URL
      final publicUrl = supabase.storage
          .from('book_images')
          .getPublicUrl(safeFilename);

      print("🔗 Public URL: $publicUrl");

      // 5. Verify URL is not empty
      if (publicUrl.isEmpty) {
        throw Exception("Failed to get public URL");
      }

      return publicUrl;
    } on StorageException catch (e) {
      print("🔥 SUPABASE STORAGE ERROR: ${e.message}");

      String userMessage;
      if (e.message.contains('already exists')) {
        userMessage = "File already exists. Please try again.";
      } else if (e.message.contains('exceeds')) {
        userMessage = "File too large. Please select a smaller image.";
      } else if (e.message.contains('not allowed')) {
        userMessage = "File type not supported. Please select a JPG or PNG.";
      } else {
        userMessage = "Upload failed: ${e.message}";
      }

      _showErrorSnackBar(userMessage);
      return null;
    } catch (e) {
      print("🚨 GENERAL ERROR: $e");
      _showErrorSnackBar("Image upload failed: ${e.toString()}");
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // 1. Handle new books requiring an image
      if (widget.book == null && _selectedImage == null) {
        setState(() => _isSubmitting = false);
        _showErrorSnackBar("Please select an image for the book");
        return;
      }

      String imageUrl = widget.book?.imageUrl ?? '';

      // 2. Upload new image if selected
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImage(_selectedImage!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          // 3. Special handling for new books when upload fails
          if (widget.book == null) {
            setState(() => _isSubmitting = false);
            _showErrorSnackBar("Image upload failed, book not created");
            return;
          }
          // For existing books, keep existing image
          _showErrorSnackBar("Image upload failed, keeping existing image");
        }
      }

      try {
        final book = BookModel(
          id:
              widget.book?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          price: double.tryParse(_priceController.text.trim()) ?? 0.0,
          description: _descController.text.trim(),
          imageUrl: imageUrl, // Could be empty for new books if upload failed!
        );

        // 4. Add debug output
        print("Saving book with image: ${book.imageUrl}");

        if (widget.book == null) {
          await controller.addBook(book);
          _showSuccessSnackBar("Book added successfully!");
        } else {
          await controller.updateBook(book);
          _showSuccessSnackBar("Book updated successfully!");
        }

        widget.onBookAdded();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar("Error saving book: $e");
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()}, ADMIN',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.book == null
                                    ? 'Add New Book'
                                    : 'Edit Book',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Form Content
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Upload Section
                        _buildImageUploadSection(),

                        const SizedBox(height: 32),

                        // Form Fields
                        _buildFormFields(),

                        const SizedBox(height: 32),

                        // Submit Button
                        _buildSubmitButton(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Cover',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      _selectedImage != null ||
                              (widget.book?.imageUrl.isNotEmpty ?? false)
                          ? const Color(0xFF4FC3F7).withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child:
                  _isUploading ? _buildUploadingState() : _buildImageDisplay(),
            ),
          ),

          if (!_isUploading) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _selectedImage != null ||
                        (widget.book?.imageUrl.isNotEmpty ?? false)
                    ? 'Tap to change image'
                    : 'Tap to select book cover',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: Color(0xFF4FC3F7),
          strokeWidth: 3,
        ),
        const SizedBox(height: 16),
        Text(
          'Uploading image...',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImageDisplay() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (widget.book != null && widget.book!.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          widget.book!.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF4FC3F7),
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
          },
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF4FC3F7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4FC3F7).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.add_photo_alternate_rounded,
            size: 30,
            color: Color(0xFF4FC3F7),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Select Book Cover',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload an image for your book',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: "Book Title",
          hint: "Enter the book title",
          icon: Icons.menu_book_rounded,
          validator: (value) => value!.isEmpty ? "Title is required" : null,
        ),

        const SizedBox(height: 20),

        _buildTextField(
          controller: _authorController,
          label: "Author",
          hint: "Enter the author's name",
          icon: Icons.person_rounded,
          validator: (value) => value!.isEmpty ? "Author is required" : null,
        ),

        const SizedBox(height: 20),

        _buildTextField(
          controller: _priceController,
          label: "Price (₦)",
          hint: "Enter the book price",
          icon: Icons.attach_money_rounded,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value!.isEmpty) return "Price is required";
            if (double.tryParse(value) == null) return "Enter a valid price";
            if (double.parse(value) <= 0) return "Price must be greater than 0";
            return null;
          },
        ),

        const SizedBox(height: 20),

        _buildTextField(
          controller: _descController,
          label: "Description",
          hint: "Enter a detailed description of the book",
          icon: Icons.description_rounded,
          maxLines: 4,
          validator:
              (value) => value!.isEmpty ? "Description is required" : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF4FC3F7)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isLoading = _isSubmitting || _isUploading;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient:
            isLoading
                ? null
                : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                ),
        color: isLoading ? Colors.white.withOpacity(0.1) : null,
        boxShadow:
            isLoading
                ? null
                : [
                  BoxShadow(
                    color: const Color(0xFF4FC3F7).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _submit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child:
                isLoading
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isUploading ? 'Uploading...' : 'Saving...',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                    : Text(
                      widget.book == null ? 'Add Book' : 'Update Book',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
