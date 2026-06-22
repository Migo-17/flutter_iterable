import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iterable_sdk/iterable_sdk.dart';

/// Replace with your own Iterable mobile API key.
const String kApiKey = 'YOUR_ITERABLE_MOBILE_API_KEY';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<String> _log = <String>[];
  final TextEditingController _emailController = TextEditingController(text: 'user@example.com');
  bool _initialized = false;
  StreamSubscription<Map<String, dynamic>>? _pushSub;
  StreamSubscription<IterableInAppMessage>? _inAppSub;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    _inAppSub?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final IterableConfig config = IterableConfig(
      autoPushRegistration: true,
      logLevel: IterableLogLevel.debug,
      enableEmbeddedMessaging: true,
      urlHandler: (String url, IterableActionContext context) {
        _addLog('urlHandler: $url');
        return true;
      },
      customActionHandler: (IterableAction action, IterableActionContext context) {
        _addLog('customAction: ${action.type}');
        return true;
      },
      authHandler: (IterableAuthRequest request) async {
        _addLog('authHandler requested for ${request.email ?? request.userId}');
        // Return your signed JWT here.
        return null;
      },
    );

    final bool ok = await IterableAPI.initialize(kApiKey, config);
    _pushSub = IterableAPI.onPushOpened.listen((Map<String, dynamic> payload) {
      _addLog('push opened: $payload');
    });
    _inAppSub = IterableAPI.onInAppReceived.listen((IterableInAppMessage m) {
      _addLog('in-app received: ${m.messageId}');
    });
    setState(() => _initialized = ok);
    _addLog('initialized: $ok');
  }

  void _addLog(String message) {
    setState(() => _log.insert(0, message));
  }

  Future<void> _setEmail() async {
    await IterableAPI.setEmail(_emailController.text);
    _addLog('setEmail: ${_emailController.text}');
  }

  Future<void> _trackEvent() async {
    await IterableAPI.trackEvent('button_clicked', dataFields: <String, dynamic>{'screen': 'home'});
    _addLog('trackEvent: button_clicked');
  }

  Future<void> _trackPurchase() async {
    await IterableAPI.trackPurchase(42.0, <IterableCommerceItem>[
      IterableCommerceItem(id: 'sku-1', name: 'Coffee', price: 42.0, quantity: 1),
    ]);
    _addLog('trackPurchase: 42.0');
  }

  Future<void> _showInApp() async {
    final List<IterableInAppMessage> messages = await IterableAPI.inAppManager.getMessages();
    _addLog('in-app messages: ${messages.length}');
    if (messages.isNotEmpty) {
      await IterableAPI.inAppManager.showMessage(messages.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Iterable SDK example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Initialized: $_initialized'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ElevatedButton(onPressed: _setEmail, child: const Text('Set email')),
                  ElevatedButton(onPressed: _trackEvent, child: const Text('Track event')),
                  ElevatedButton(onPressed: _trackPurchase, child: const Text('Track purchase')),
                  ElevatedButton(onPressed: IterableAPI.registerForPush, child: const Text('Register push')),
                  ElevatedButton(onPressed: _showInApp, child: const Text('Show in-app')),
                  ElevatedButton(onPressed: IterableAPI.logout, child: const Text('Logout')),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (BuildContext context, int index) => Text(_log[index], style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
