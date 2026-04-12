import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background isolate
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  log("Handling a background message: ${message.messageId}");
  // Persist to Firestore even in background
  await NotificationService._saveNotificationToFirestore(message);
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications() async {
    // 1. Request Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else {
      log('User declined or has not accepted permission');
    }

    // 2. Setup Local Notifications for Foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        log("Notification tapped: ${details.payload}");
      },
    );

    // 3. Create High Importance Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message, channel);
      }
      
      // Save to history
      _saveNotificationToFirestore(message);
    });

    // 6. Listen for when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('App opened from notification!');
      // Navigation could be handled here if needed
    });

    // 7. Initial Token Setup
    await _updateToken();

    // 8. Listen for Token Tresh
    _messaging.onTokenRefresh.listen((token) {
      _saveTokenToFirestore(token);
    });
  }

  static Future<void> _updateToken() async {
    String? token = await _messaging.getToken();
    if (token != null) {
      log("FCM Token: $token");
      await _saveTokenToFirestore(token);
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Persist UID locally for background handler use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', user.uid);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> _showLocalNotification(
      RemoteMessage message, AndroidNotificationChannel channel) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
            importance: channel.importance,
            priority: Priority.high,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  static Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    String? uid;
    
    // 1. Try to get UID from FirebaseAuth (Foreground)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
    } else {
      // 2. Try to get UID from SharedPreferences (Background)
      final prefs = await SharedPreferences.getInstance();
      uid = prefs.getString('user_uid');
    }

    if (uid == null) {
       log("No UID found, skipping persistence.");
       return;
    }

    final notification = message.notification;
    if (notification == null) return;

    // Use messageId as doc ID to prevent duplicates
    final docId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    try {
      await FirebaseFirestore.instance.collection('notifications').doc(docId).set({
        'recipientId': uid,
        'title': notification.title,
        'body': notification.body,
        'timestamp': FieldValue.serverTimestamp(),
        'type': message.data['type'] ?? 'system',
        'data': message.data,
      });
      log("Notification saved to history: $docId");
    } catch (e) {
      log("Error saving notification: $e");
    }
  }
}
