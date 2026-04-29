import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quick_reply_app/providers/auth_provider.dart';
import 'package:quick_reply_app/providers/message_provider.dart';
import 'package:quick_reply_app/providers/customer_provider.dart';
import 'package:quick_reply_app/screens/home_screen.dart';
import 'package:quick_reply_app/screens/search_screen.dart';
import 'package:quick_reply_app/screens/send_screen.dart';
import 'package:quick_reply_app/screens/profile_screen.dart';
import 'package:quick_reply_app/screens/customer_list_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuickReplyApp());
}


class QuickReplyApp extends StatefulWidget {
  const QuickReplyApp({super.key});

  @override
  State<QuickReplyApp> createState() => _QuickReplyAppState();
}

class _QuickReplyAppState extends State<QuickReplyApp> {
  static const _channel = MethodChannel('app.quickreply/overlay');

  @override
  void initState() {
    super.initState();
    _setupMethodChannelHandler();
  }

  void _setupMethodChannelHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pickAndShareImage') {
        await _pickAndShareImage();
      } else if (call.method == 'pickAndShareFile') {
        await _pickAndShareFile();
      }
    });
  }

  Future<void> _pickAndShareImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await Share.shareXFiles([image], text: '');
      }
    } catch (e) {
      debugPrint('Error picking/sharing image: $e');
    }
  }

  Future<void> _pickAndShareFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await Share.shareXFiles([XFile(file.path!)], text: '');
        }
      }
    } catch (e) {
      debugPrint('Error picking/sharing file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: MaterialApp(
        title: '蹇洖澶?,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1E293B),
            elevation: 0,
          ),
        ),
        home: MainScreen(key: MainScreen.mainKey),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  // 鍏ㄥ眬key锛岀敤浜庡瓙椤甸潰鍒囨崲tab
  static final GlobalKey<_MainScreenState> mainKey = GlobalKey<_MainScreenState>();

  /// 鍒囨崲鍒版寚瀹歵ab锛堜緵瀛愰〉闈㈣皟鐢級
  static void goToTab(int index) {
    mainKey.currentState?._switchToTab(index);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 澶勭悊浠庡師鐢熸偓娴獥浼犲叆鐨勫弬鏁?    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleIntent();
    });
  }

  void _handleIntent() {
    // 杩欓噷鍙互娣诲姞澶勭悊鍘熺敓Intent鐨勯€昏緫
    // 渚嬪锛氭娴嬩粠鍘熺敓绔紶鍏ョ殑route鍙傛暟锛岀劧鍚庢墽琛岀浉搴旀搷浣?    // 鐢变簬Flutter灞傛棤娉曠洿鎺ヨ闂甀ntent锛岃繖涓€昏緫闇€瑕佸湪鍘熺敓灞傞€氳繃MethodChannel璋冪敤
  }

  void _switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const CustomerListScreen(),
    const SendScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: '璇濇湳搴?,
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '鎼滅储',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '瀹㈡埛鐢诲儚',
          ),
          NavigationDestination(
            icon: Icon(Icons.flash_on_outlined),
            selectedIcon: Icon(Icons.flash_on),
            label: '蹇嵎鍙戦€?,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: '鎴戠殑',
          ),
        ],
      ),
    );
  }
}
