// lib/screens/passport_screen.dart (fixed overflow and text decoration)
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../models/passport_session.dart';
import '../models/drink.dart';
import '../services/passport_service.dart';
import '../services/custom_drinks_service.dart';
import '../utils/theme.dart';
import '../widgets/common/fun_card.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/common/confetti_overlay.dart';

class PassportScreen extends StatefulWidget {
  final DateTime date;

  const PassportScreen({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> with SingleTickerProviderStateMixin {
  final PassportService _passportService = PassportService();
  final CustomDrinksService _customDrinksService = CustomDrinksService();
  final GlobalKey _passportKey = GlobalKey();

  PassportSession? _session;
  bool _isLoading = true;
  bool _showCreateUI = false;
  bool _isSharingMode = false;
  bool _showConfetti = false;
  final TextEditingController _sessionNameController = TextEditingController();

  // For photo
  final ImagePicker _picker = ImagePicker();
  String? _tempPhotoPath;

  // For animations
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadPassport();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPassport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check for existing passport on this date
      final sessions = await _passportService.getPassportSessions();

      // Find a session for this date
      PassportSession? existingSession;
      for (var session in sessions) {
        // Check if this session is for the selected date
        if (session.startTime.year == widget.date.year &&
            session.startTime.month == widget.date.month &&
            session.startTime.day == widget.date.day) {
          existingSession = session;
          break;
        }
      }

      if (existingSession != null) {
        setState(() {
          _session = existingSession;
          _showCreateUI = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _session = null;
          _showCreateUI = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading passport: $e');
      setState(() {
        _isLoading = false;
        _showCreateUI = true;
      });
    }
  }

  Future<void> _createPassport() async {
    if (_sessionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for this session'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final session = await _passportService.generatePassportForDate(
        widget.date,
        _sessionNameController.text,
      );

      setState(() {
        _session = session;
        _showCreateUI = false;
        _isLoading = false;

        if (session != null) {
          _showConfetti = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showConfetti = false;
              });
            }
          });
        }
      });

      if (session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No drinks found for this date'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error creating passport: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create passport'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _tempPhotoPath = pickedFile.path;
        });

        if (_session != null) {
          await _passportService.updatePassportSession(
            _session!.id,
            photoPath: pickedFile.path,
          );
          _loadPassport();
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _captureAndSharePassport() async {
    setState(() {
      _isSharingMode = true;
    });

    try {
      // let the frame rebuild into “sharing” mode
      await Future.delayed(const Duration(milliseconds: 100));

      // capture the widget as an image
      RenderRepaintBoundary boundary =
      _passportKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // write it out to a temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/boozebuddy_passport.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        // wrap it in XFile and share via the new SharePlus API
        final params = ShareParams(
          text: 'Here’s my BoozeBuddy passport!',
          files: [XFile(file.path)],
        );

        final result = await SharePlus.instance.share(params);
        if (result.status != ShareResultStatus.success) {
          // user dismissed or some error
          print('Share cancelled or failed: ${result.raw}');
        }
      }
    } catch (e) {
      print('Error capturing passport: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error sharing passport'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSharingMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      navigationBar: _isSharingMode ? null : CupertinoNavigationBar(
        backgroundColor: AppTheme.cardColor,
        middle: const Text('Drink Passport'),
        trailing: _session != null ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
              onPressed: _refreshPassport,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.share),
              onPressed: _captureAndSharePassport,
            ),
          ],
        ) : null,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _showCreateUI
                ? SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom
              ),
              child: _buildCreateUI(),
            )
                : _buildPassportView(),

            if (_showConfetti)
              ConfettiOverlay(
                onAnimationComplete: () {
                  setState(() {
                    _showConfetti = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateUI() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.boozeBuddyGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🍻',
                  style: TextStyle(fontSize: 60, decoration: TextDecoration.none),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Create Your Drink Passport',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Turn your night out into a shareable memory',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            FunCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Name this night:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _sessionNameController,
                    placeholder: 'e.g. Saturday Night Out',
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    cursorColor: AppTheme.primaryColor,
                    style: const TextStyle(color: Colors.white, decoration: TextDecoration.none),
                    placeholderStyle: TextStyle(color: Colors.grey[600], decoration: TextDecoration.none),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    text: 'Create Passport',
                    emoji: '✈️',
                    onPressed: _createPassport,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePhoto() async {
    if (_session != null) {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Remove Photo'),
          content: const Text('Are you sure you want to remove this photo?'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Remove'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ?? false;

      if (confirmed) {
        await _passportService.removePassportPhoto(_session!.id);
        setState(() {
          _tempPhotoPath = null;
        });
        _loadPassport();
      }
    }
  }

  Future<void> _refreshPassport() async {
    if (_session == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final refreshedSession = await _passportService.refreshPassportDrinks(_session!.id);

      if (refreshedSession != null) {
        setState(() {
          _session = refreshedSession;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passport updated with latest drinks'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error refreshing passport: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editPassportName() async {
    if (_session == null) return;

    final TextEditingController nameController = TextEditingController(text: _session!.sessionName);

    final newName = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Edit Passport Name'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: 'Enter new name',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Save'),
            onPressed: () => Navigator.pop(context, nameController.text),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _session!.sessionName) {
      await _passportService.updatePassportName(_session!.id, newName);
      _loadPassport();
    }
  }

  Widget _buildPassportView() {
    if (_session == null) {
      return const Center(
        child: Text(
          'No passport available',
          style: TextStyle(color: Colors.white, decoration: TextDecoration.none),
        ),
      );
    }

    return _isSharingMode
        ? Center(
      child: RepaintBoundary(
        key: _passportKey,
        child: _buildShareablePassport(_session!),
      ),
    )
        : SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Preview of shareable passport
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildShareablePassport(_session!),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons - Photo management
          Row(
            children: [
              if (_session!.photoPath == null || _session!.photoPath!.isEmpty)
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.camera,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Add Photo',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onPressed: _pickImage,
                  ),
                )
              else ...[
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.camera_rotate,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Change Photo',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onPressed: _pickImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.delete,
                            color: Colors.red.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remove Photo',
                            style: TextStyle(
                              color: Colors.red.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onPressed: _removePhoto,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Second row - Edit name and Share
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.pencil,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Edit Name',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onPressed: _editPassportName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  text: 'Share',
                  icon: CupertinoIcons.share,
                  onPressed: _captureAndSharePassport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareablePassport(PassportSession session) {
  final photoPath = _tempPhotoPath ?? session.photoPath;

  // Get drink type breakdown
  Map<DrinkType, int> drinkTypeCount = {};
  for (var drink in session.drinks) {
    drinkTypeCount[drink.type] = (drinkTypeCount[drink.type] ?? 0) + 1;
  }

  return Container(
    width: 400, // Instagram-friendly square aspect ratio
    height: 500, // Slightly taller for better content fit
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF1A1A2E), // Dark blue
          Color(0xFF16213E), // Darker blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      children: [
        // Background pattern
        Positioned.fill(
          child: CustomPaint(
            painter: _PassportBackgroundPainter(),
          ),
        ),

        // Content
        Column(
          children: [
            // Header - made more compact
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  const Text(
                    '🍻',
                    style: TextStyle(fontSize: 28, decoration: TextDecoration.none),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'BOOZEBUDDY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PASSPORT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Photo section (if available) - slightly smaller
            if (photoPath != null)
              Container(
                height: 160,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(photoPath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            if (photoPath != null)
              const SizedBox(height: 16),

            // Session info
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  children: [
                    // Session name and date
                    Text(
                      session.sessionName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE • MMM d, yyyy').format(session.startTime).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.5,
                        decoration: TextDecoration.none,
                      ),
                    ),

                    const Spacer(),

                    // Drink types breakdown - NEW FOCUS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'DRINK JOURNEY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Drink type icons
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: drinkTypeCount.entries.map((entry) {
                              final emoji = Drink.getEmojiForType(entry.key);
                              final count = entry.value;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    emoji,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary stats - more compact
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Total drinks
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🍹',
                                style: TextStyle(fontSize: 16, decoration: TextDecoration.none),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${session.drinks.length} DRINKS',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (session.uniqueLocations > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.location_solid,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${session.uniqueLocations} SPOTS',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),

                    // if (session.stamps.isNotEmpty)
                    //   Container(
                    //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //     decoration: BoxDecoration(
                    //       color: Colors.white.withOpacity(0.05),
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         ...session.stamps.take(4).map((stamp) =>
                    //             Padding(
                    //               padding: const EdgeInsets.symmetric(horizontal: 3),
                    //               child: Text(
                    //                 stamp.emoji,
                    //                 style: const TextStyle(fontSize: 16, decoration: TextDecoration.none),
                    //               ),
                    //             ),
                    //         ),
                    //         if (session.stamps.length > 4)
                    //           Text(
                    //             ' +${session.stamps.length - 4}',
                    //             style: TextStyle(
                    //               fontSize: 12,
                    //               color: Colors.white.withOpacity(0.7),
                    //               fontWeight: FontWeight.bold,
                    //               decoration: TextDecoration.none,
                    //             ),
                    //           ),
                    //       ],
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24, decoration: TextDecoration.none),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

// Custom painter for background pattern
class _PassportBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw diagonal lines pattern
    for (double i = -size.width; i < size.width * 2; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BubblePainter extends CustomPainter {
  final int bubbleCount;
  _BubblePainter({this.bubbleCount = 30});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05);
    final rng = math.Random();

    for (int i = 0; i < bubbleCount; i++) {
      final radius = rng.nextDouble() * 20 + 5;                // 5–25px
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      old.bubbleCount != bubbleCount;
}
