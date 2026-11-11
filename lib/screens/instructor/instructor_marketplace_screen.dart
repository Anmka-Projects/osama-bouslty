import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/bookings/booking_error_mapper.dart';
import '../../core/bookings/marketplace_copy.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../core/categories/category_utils.dart';
import '../../services/courses_service.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../services/upload_service.dart';

class InstructorMarketplaceScreen extends StatefulWidget {
  const InstructorMarketplaceScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<InstructorMarketplaceScreen> createState() =>
      _InstructorMarketplaceScreenState();
}

class _InstructorMarketplaceScreenState
    extends State<InstructorMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    return Scaffold(
      backgroundColor: AppColors.brandSand,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceRaised,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(copy.trainerProfile,
            style: GoogleFonts.readexPro(
                fontWeight: FontWeight.w800, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.brandTeal,
              unselectedLabelColor: AppColors.inkMuted,
              indicatorColor: AppColors.brandTeal,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.readexPro(
                  fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.readexPro(
                  fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'الملف'),
                Tab(text: 'الباقات'),
                Tab(text: 'المواعيد'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ProfileTab(),
          _OfferingsTab(),
          _AvailabilityTab(),
        ],
      ),
    );
  }
}

InputDecoration _mktFieldDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: true,
    filled: true,
    fillColor: AppColors.surfaceRaised,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: GoogleFonts.readexPro(
        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
    hintStyle: GoogleFonts.readexPro(fontSize: 13, color: AppColors.inkSubtle),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.brandTeal, width: 1.6),
    ),
  );
}

TextStyle get _mktInputStyle => GoogleFonts.readexPro(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.45);

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _name = TextEditingController();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _video = TextEditingController();
  final _join = TextEditingController();
  List<Map<String, dynamic>> _categories = const [];
  String? _categoryId;
  String? _subcategoryId;
  final Set<String> _subjectIds = {};
  String _priceHint = '';
  String? _avatarUrl;
  bool _loading = true;
  bool _uploadingAvatar = false;
  bool _accepting = true;
  String _provider = 'custom_web';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
    _bio.dispose();
    _video.dispose();
    _join.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        TrainerMarketplaceService.instance.myTrainerProfile(),
        CoursesService.instance.getCategories(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final categories = results[1] as List<Map<String, dynamic>>;
      if (!mounted) return;
      _name.text = data['display_name']?.toString() ?? '';
      _headline.text = data['headline']?.toString() ?? '';
      _bio.text = data['bio']?.toString() ?? '';
      _video.text = data['intro_video_url']?.toString() ?? '';
      _join.text = data['default_join_url']?.toString() ?? '';
      _provider = data['default_meeting_provider']?.toString() ?? 'custom_web';
      setState(() {
        _categories = categories;
        _categoryId = data['category_id']?.toString();
        _subcategoryId = data['subcategory_id']?.toString();
        _subjectIds
          ..clear()
          ..addAll(((data['subjects'] as List?) ?? const [])
              .map((item) => item is Map ? item['id']?.toString() ?? '' : '')
              .where((id) => id.isNotEmpty));
        final range = data['price_range_usd'];
        if (range is Map) {
          _priceHint =
              'سعر الساعة بالدولار من ${range['min']} إلى ${range['max']}';
        }
        _avatarUrl =
            data['avatar_url']?.toString() ?? data['avatar']?.toString();
        _accepting = data['is_accepting_bookings'] == true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final url = await UploadService.instance.uploadImage(File(picked.path));
      await TrainerMarketplaceService.instance
          .updateTrainerProfile({'avatar_url': url});
      if (!mounted) return;
      setState(() => _avatarUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم تحديث الصورة', style: GoogleFonts.readexPro())));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (_categoryId == null || _categoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر المجال الرئيسي')),
      );
      return;
    }
    try {
      final saved =
          await TrainerMarketplaceService.instance.updateTrainerProfile({
        'display_name': _name.text,
        'headline': _headline.text,
        'bio': _bio.text,
        'intro_video_url': _video.text,
        'category_id': _categoryId,
        'subcategory_id': _subcategoryId,
        'subject_ids': _subjectIds.toList(),
        'is_accepting_bookings': _accepting,
        'default_meeting_provider': _provider,
        'default_join_url': _join.text.trim(),
        if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
          'avatar_url': _avatarUrl,
        'languages': ['ar'],
      });
      if (!mounted) return;
      final note = saved['review_message']?.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(note != null && note.isNotEmpty
              ? note
              : MarketplaceCopy.of(context).save)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  Widget _avatarPicker() {
    final url = (_avatarUrl ?? '').trim();
    return Center(
      child: Column(
        children: [
          InkWell(
            onTap: _uploadingAvatar ? null : _pickAvatar,
            borderRadius: BorderRadius.circular(48),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.primarySoft,
                  backgroundImage: url.isNotEmpty
                      ? NetworkImage(ApiEndpoints.getImageUrl(url))
                      : null,
                  child: url.isEmpty
                      ? Icon(Icons.person_rounded,
                          size: 42, color: AppColors.brandTeal)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.brandTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: _uploadingAvatar
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.photo_camera_outlined,
                            size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _uploadingAvatar ? null : _pickAvatar,
            child: Text('اختيار صورة شخصية',
                style: GoogleFonts.readexPro(
                    fontWeight: FontWeight.w700, color: AppColors.brandTeal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final roots = CategoryUtils.topLevel(_categories);
    Map<String, dynamic>? selectedCategory;
    for (final item in roots) {
      if (item['id']?.toString() == _categoryId) selectedCategory = item;
    }
    final children = selectedCategory == null
        ? <Map<String, dynamic>>[]
        : CategoryUtils.resolveChildren(selectedCategory, _categories);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          'حدّث بياناتك عشان ملفك يظهر بشكل احترافي للطلاب',
          style: GoogleFonts.readexPro(fontSize: 13, color: AppColors.inkMuted),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 14),
        _avatarPicker(),
        const SizedBox(height: 14),
        TextField(
          controller: _name,
          style: _mktInputStyle,
          textAlignVertical: TextAlignVertical.center,
          decoration: _mktFieldDecoration('الاسم الظاهر'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _headline,
          style: _mktInputStyle,
          textAlignVertical: TextAlignVertical.center,
          decoration: _mktFieldDecoration('المسمى التعريفي'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bio,
          style: _mktInputStyle,
          maxLines: 4,
          minLines: 3,
          textAlignVertical: TextAlignVertical.top,
          decoration: _mktFieldDecoration('نبذة عنك'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _video,
          style: _mktInputStyle,
          textAlignVertical: TextAlignVertical.center,
          decoration:
              _mktFieldDecoration('رابط الفيديو التعريفي', hint: 'https://...'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue:
              roots.any((item) => item['id']?.toString() == _categoryId)
                  ? _categoryId
                  : null,
          decoration: _mktFieldDecoration('المجال الرئيسي'),
          style: _mktInputStyle,
          items: roots
              .map((item) => DropdownMenuItem(
                    value: item['id']?.toString(),
                    child: Text(CategoryUtils.displayName(item, arabic: true)),
                  ))
              .toList(),
          onChanged: (value) => setState(() {
            _categoryId = value;
            _subcategoryId = null;
            _subjectIds.clear();
          }),
        ),
        if (children.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_categoryId),
            initialValue:
                children.any((item) => item['id']?.toString() == _subcategoryId)
                    ? _subcategoryId
                    : null,
            decoration: _mktFieldDecoration('التخصص الفرعي'),
            style: _mktInputStyle,
            items: children
                .map((item) => DropdownMenuItem(
                      value: item['id']?.toString(),
                      child:
                          Text(CategoryUtils.displayName(item, arabic: true)),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              _subcategoryId = value;
              _subjectIds.clear();
            }),
          ),
        ],
        if (_priceHint.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_priceHint,
              textAlign: TextAlign.right,
              style: GoogleFonts.readexPro(
                  fontSize: 12, color: AppColors.inkMuted)),
        ],
        const SizedBox(height: 12),
        Text('المواد (تقدر تختار أكتر من مادة)',
            textAlign: TextAlign.right,
            style: GoogleFonts.readexPro(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          Map<String, dynamic>? selectedSubcategory;
          for (final item in children) {
            if (item['id']?.toString() == _subcategoryId) {
              selectedSubcategory = item;
              break;
            }
          }
          final subjects = selectedSubcategory == null
              ? <Map<String, dynamic>>[]
              : CategoryUtils.resolveChildren(selectedSubcategory, _categories);
          if (_subcategoryId == null) {
            return Text('اختار التخصص الفرعي الأول',
                textAlign: TextAlign.right,
                style: GoogleFonts.readexPro(
                    fontSize: 12, color: AppColors.inkMuted));
          }
          if (subjects.isEmpty) {
            return Text('الأدمن لسه مضفش مواد للتخصص ده',
                textAlign: TextAlign.right,
                style: GoogleFonts.readexPro(
                    fontSize: 12, color: AppColors.inkMuted));
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final subject in subjects)
                FilterChip(
                  label: Text(CategoryUtils.displayName(subject, arabic: true)),
                  selected: _subjectIds.contains(subject['id']?.toString()),
                  onSelected: (selected) {
                    final id = subject['id']?.toString() ?? '';
                    setState(() {
                      if (selected) {
                        _subjectIds.add(id);
                      } else {
                        _subjectIds.remove(id);
                      }
                    });
                  },
                ),
            ],
          );
        }),
        const SizedBox(height: 12),
        TextField(
          controller: _join,
          style: _mktInputStyle,
          textAlignVertical: TextAlignVertical.center,
          decoration: _mktFieldDecoration(copy.meetingLink),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _provider,
          decoration: _mktFieldDecoration('منصة الجلسة'),
          style: _mktInputStyle,
          items: const ['custom_web', 'teams', 'zoom', 'jitsi']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) =>
              setState(() => _provider = value ?? 'custom_web'),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: SwitchListTile(
            tileColor: Colors.transparent,
            value: _accepting,
            onChanged: (value) => setState(() => _accepting = value),
            activeThumbColor: AppColors.brandTeal,
            title: Text(copy.bookNow,
                style: GoogleFonts.readexPro(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _save,
            child: Text(copy.save,
                style: GoogleFonts.readexPro(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _OfferingsTab extends StatefulWidget {
  const _OfferingsTab();

  @override
  State<_OfferingsTab> createState() => _OfferingsTabState();
}

class _OfferingsTabState extends State<_OfferingsTab> {
  bool _loading = true;
  bool _saving = false;
  final List<Map<String, dynamic>> _items = [];
  final Set<String> _deletedIds = {};
  List<String> _priceOptionsUsd = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await TrainerMarketplaceService.instance.myTrainerProfile();
      final rows = (data['offerings'] as List?) ?? const [];
      final rawOptions = (data['price_options_usd'] as List?) ?? const [];
      final options = rawOptions
          .map((value) => double.tryParse('$value'))
          .whereType<double>()
          .where((value) => value > 0)
          .toSet()
          .toList()
        ..sort();
      _priceOptionsUsd =
          options.map((value) => value.toStringAsFixed(2)).toList();
      _items
        ..clear()
        ..addAll(rows.whereType<Map>().map((item) {
          final type = item['type']?.toString() == 'package'
              ? 'package'
              : 'single_session';
          return {
            'id': item['id'],
            'type': type,
            'title': item['title']?.toString() ?? '',
            'description': item['description']?.toString() ?? '',
            'session_count': item['session_count'] ?? 1,
            'duration_minutes': item['duration_minutes'] ?? 60,
            'price': item['price']?.toString() ?? '',
            'discount_price': item['discount_price']?.toString() ?? '',
            'is_active': item['is_active'] != false,
          };
        }));
      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  void _add(String type) {
    if (_priceOptionsUsd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الأدمن لسه مضفش أسعار متاحة للجلسات')));
      return;
    }
    setState(() {
      _items.add({
        'type': type,
        'title': type == 'package' ? 'باقة جلسات' : 'جلسة فردية',
        'description': '',
        'session_count': type == 'package' ? 4 : 1,
        'duration_minutes': 60,
        'price': _priceOptionsUsd.first,
        'discount_price': '',
        'is_active': true,
      });
    });
  }

  Future<void> _save() async {
    for (final item in _items) {
      final title = '${item['title'] ?? ''}'.trim();
      final price = double.tryParse('${item['price'] ?? ''}');
      final discount = double.tryParse('${item['discount_price'] ?? ''}');
      final sessions = int.tryParse('${item['session_count'] ?? ''}') ?? 0;
      if (title.isEmpty || price == null || price <= 0 || sessions < 1) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('أكمل اسم الباقة والسعر وعدد الجلسات بشكل صحيح')));
        return;
      }
      final allowedPrice =
          _priceOptionsUsd.any((option) => double.tryParse(option) == price);
      final allowedDiscount = discount == null ||
          _priceOptionsUsd.any((option) => double.tryParse(option) == discount);
      if (!allowedPrice || !allowedDiscount) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('اختار السعر من قائمة الأسعار اللي حددها الأدمن')));
        return;
      }
      if (discount != null && discount >= price) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('السعر بعد الخصم يجب أن يكون أقل من السعر الأصلي')));
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await TrainerMarketplaceService.instance.updateTrainerProfile({
        'deleted_offering_ids': _deletedIds.toList(),
        'offerings': _items.map((item) {
          final discount = '${item['discount_price'] ?? ''}'.trim();
          return {
            if (item['id'] != null) 'id': item['id'],
            'type': item['type'],
            'title': item['title'],
            'description': item['description'],
            'session_count': int.tryParse('${item['session_count']}') ?? 1,
            'duration_minutes':
                int.tryParse('${item['duration_minutes']}') ?? 60,
            'price': item['price'],
            'discount_price': discount.isEmpty ? null : discount,
            'is_active': item['is_active'] != false,
            'currency': 'USD',
          };
        }).toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الجلسات والباقات')));
      _deletedIds.clear();
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _matchingPrice(dynamic raw) {
    final value = double.tryParse('$raw');
    if (value == null) return null;
    for (final option in _priceOptionsUsd) {
      if (double.tryParse(option) == value) return option;
    }
    return null;
  }

  List<String> _discountOptions(Map<String, dynamic> item) {
    final price = double.tryParse('${item['price'] ?? ''}');
    if (price == null) return const [];
    return _priceOptionsUsd
        .where((option) => (double.tryParse(option) ?? price) < price)
        .toList();
  }

  String _matchingDiscount(Map<String, dynamic> item) {
    final value = double.tryParse('${item['discount_price'] ?? ''}');
    if (value == null) return '';
    for (final option in _discountOptions(item)) {
      if (double.tryParse(option) == value) return option;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          _priceOptionsUsd.isEmpty
              ? 'لا توجد أسعار متاحة حاليًا. تواصل مع الأدمن لإضافة الأسعار.'
              : 'اختار سعر الجلسة أو الباقة من الأسعار اللي حددها الأدمن.',
          style: GoogleFonts.readexPro(fontSize: 13, color: AppColors.inkMuted),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 14),
        ..._items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14083B41),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    tooltip: 'إخفاء الباقة من الطلاب',
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.destructive),
                    onPressed: () => setState(() {
                      final id = item['id']?.toString();
                      if (id != null && id.isNotEmpty) _deletedIds.add(id);
                      _items.remove(item);
                    }),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: item['type']?.toString() ?? 'single_session',
                  decoration: _mktFieldDecoration('النوع'),
                  style: _mktInputStyle,
                  items: const [
                    DropdownMenuItem(
                        value: 'single_session', child: Text('جلسة فردية')),
                    DropdownMenuItem(
                        value: 'package', child: Text('باقة جلسات')),
                  ],
                  onChanged: (value) =>
                      item['type'] = value ?? 'single_session',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: '${item['title']}',
                  style: _mktInputStyle,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: _mktFieldDecoration('الاسم'),
                  onChanged: (value) => item['title'] = value,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: '${item['description'] ?? ''}',
                  style: _mktInputStyle,
                  maxLines: 3,
                  minLines: 2,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: _mktFieldDecoration('الوصف'),
                  onChanged: (value) => item['description'] = value,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: '${item['session_count']}',
                  style: _mktInputStyle,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: _mktFieldDecoration('عدد الجلسات'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => item['session_count'] = value,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: '${item['duration_minutes']}',
                  style: _mktInputStyle,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: _mktFieldDecoration('مدة الجلسة بالدقائق'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => item['duration_minutes'] = value,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _matchingPrice(item['price']),
                  decoration: _mktFieldDecoration('السعر بالدولار'),
                  style: _mktInputStyle,
                  items: _priceOptionsUsd
                      .map((value) => DropdownMenuItem(
                          value: value, child: Text('$value USD')))
                      .toList(),
                  onChanged: (value) => setState(() {
                    item['price'] = value ?? '';
                    final discount =
                        double.tryParse('${item['discount_price'] ?? ''}');
                    final price = double.tryParse('${item['price']}');
                    if (discount != null &&
                        price != null &&
                        discount >= price) {
                      item['discount_price'] = '';
                    }
                  }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _matchingDiscount(item),
                  decoration: _mktFieldDecoration('السعر بعد الخصم'),
                  style: _mktInputStyle,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('بدون خصم')),
                    ..._discountOptions(item).map((value) => DropdownMenuItem(
                        value: value, child: Text('$value USD'))),
                  ],
                  onChanged: (value) =>
                      setState(() => item['discount_price'] = value ?? ''),
                ),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    tileColor: Colors.transparent,
                    value: item['is_active'] == true,
                    activeThumbColor: AppColors.brandTeal,
                    title: Text('ظاهرة للطلاب',
                        style: GoogleFonts.readexPro(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    onChanged: (value) =>
                        setState(() => item['is_active'] = value),
                  ),
                ),
              ],
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _priceOptionsUsd.isEmpty
                    ? null
                    : () => _add('single_session'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandTeal,
                  side: const BorderSide(color: AppColors.brandTeal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('جلسة جديدة',
                    style: GoogleFonts.readexPro(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _priceOptionsUsd.isEmpty ? null : () => _add('package'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandTeal,
                  side: const BorderSide(color: AppColors.brandTeal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('باقة جديدة',
                    style: GoogleFonts.readexPro(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'جارٍ الحفظ...' : MarketplaceCopy.of(context).save,
              style: GoogleFonts.readexPro(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvailabilityTab extends StatefulWidget {
  const _AvailabilityTab();

  @override
  State<_AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends State<_AvailabilityTab> {
  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _rules = [];

  static const _days = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await TrainerMarketplaceService.instance.myAvailability();
    final rules = (data['rules'] as List?) ?? const [];
    if (!mounted) return;
    setState(() {
      _rules =
          rules.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      _loading = false;
    });
  }

  Map<String, dynamic>? _ruleFor(int day) {
    for (final rule in _rules) {
      if (rule['weekday'] == day) return rule;
    }
    return null;
  }

  String _formatMinute(int minute) {
    final h = (minute ~/ 60).clamp(0, 23);
    final m = (minute % 60).clamp(0, 59);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(int day, {required bool isStart}) async {
    final rule = _ruleFor(day);
    if (rule == null) return;
    final current = isStart
        ? int.tryParse('${rule['start_minute']}') ?? 16 * 60
        : int.tryParse('${rule['end_minute']}') ?? 21 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: isStart ? 'وقت البداية' : 'وقت النهاية',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.brandTeal,
                  onPrimary: Colors.white,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) return;
    final value = picked.hour * 60 + picked.minute;
    final start =
        isStart ? value : int.tryParse('${rule['start_minute']}') ?? 16 * 60;
    final end =
        isStart ? int.tryParse('${rule['end_minute']}') ?? 21 * 60 : value;
    if (end <= start) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('وقت النهاية لازم يكون بعد وقت البداية',
              style: GoogleFonts.readexPro())));
      return;
    }
    setState(() {
      rule['start_minute'] = start;
      rule['end_minute'] = end;
    });
  }

  void _toggleDay(int day, bool enabled) {
    setState(() {
      _rules.removeWhere((rule) => rule['weekday'] == day);
      if (enabled) {
        _rules.add({
          'weekday': day,
          'start_minute': 16 * 60,
          'end_minute': 21 * 60,
        });
      }
    });
  }

  Future<void> _save() async {
    for (final rule in _rules) {
      final start = int.tryParse('${rule['start_minute']}') ?? 0;
      final end = int.tryParse('${rule['end_minute']}') ?? 0;
      if (end <= start) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('راجع أوقات ${_days[rule['weekday'] as int]}',
                style: GoogleFonts.readexPro())));
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await TrainerMarketplaceService.instance.saveAvailability({
        'timezone': 'Africa/Cairo',
        'slot_duration_minutes': 60,
        'buffer_minutes': 10,
        'rules': _rules
            .map((rule) => {
                  'weekday': rule['weekday'],
                  'start_minute': rule['start_minute'],
                  'end_minute': rule['end_minute'],
                })
            .toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(MarketplaceCopy.of(context).save)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _timeButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.brandSand,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.readexPro(
                      fontSize: 11, color: AppColors.inkMuted)),
              const SizedBox(height: 4),
              Text(value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.readexPro(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${copy.timezoneLabel}: Africa/Cairo',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandTeal)),
              const SizedBox(height: 4),
              Text(
                  'فعّل اليوم واختار من ساعة كام لساعة كام تقدر تستقبل حجوزات.',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.readexPro(
                      fontSize: 12, color: AppColors.inkMuted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(7, (day) {
          final rule = _ruleFor(day);
          final enabled = rule != null;
          final start = int.tryParse('${rule?['start_minute']}') ?? 16 * 60;
          final end = int.tryParse('${rule?['end_minute']}') ?? 21 * 60;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Switch(
                      value: enabled,
                      activeThumbColor: AppColors.brandTeal,
                      onChanged: (value) => _toggleDay(day, value),
                    ),
                    Expanded(
                      child: Text(_days[day],
                          textAlign: TextAlign.right,
                          style: GoogleFonts.readexPro(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                if (enabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _timeButton(
                        label: 'من',
                        value: _formatMinute(start),
                        onTap: () => _pickTime(day, isStart: true),
                      ),
                      const SizedBox(width: 8),
                      _timeButton(
                        label: 'إلى',
                        value: _formatMinute(end),
                        onTap: () => _pickTime(day, isStart: false),
                      ),
                    ],
                  ),
                ] else
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text('غير متاح',
                        style: GoogleFonts.readexPro(
                            fontSize: 12, color: AppColors.inkMuted)),
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'جارٍ الحفظ...' : copy.save,
                style: GoogleFonts.readexPro(fontWeight: FontWeight.w700)),
          ),
        ),
        TextButton(
          onPressed: () => context.push(RouteNames.myBookings),
          child: Text(copy.myBookings,
              style: GoogleFonts.readexPro(color: AppColors.brandTeal)),
        ),
      ],
    );
  }
}
