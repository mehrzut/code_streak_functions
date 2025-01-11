import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:starter_template/reminder_manager.dart';
import 'package:starter_template/user_manager.dart';

// This Appwrite function will be executed every time your function is triggered
Future<dynamic> main(final context) async {
  final Dio dio = Dio(BaseOptions(validateStatus: (status) {
    return (status ?? 400) < 500;
  }));
  // You can use the Appwrite SDK to interact with other services
  // For this example, we're using the Users service
  final client = Client()
      .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ?? '')
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey(context.req.headers['x-appwrite-key'] ?? '');
  final users = Users(client);
  final messaging = Messaging(client);

  try {
    final response = await users.list();
    // Log messages and errors to the Appwrite Console
    // These logs won't be seen by your end users
    context.log('Total users: ' + response.total.toString());
  } catch (e) {
    context.error('Could not list users: ' + e.toString());
  }

  // The req object contains the request data
  if (context.req.path == "/ping") {
    // Use res object to respond with text(), json(), or binary()
    // Don't forget to return a response!
    return context.res.text('Pong');
  }

  if (context.req.path == "/tic") {
    return context.res.json({"tac": "Toe"});
  }
  if (context.req.path == "/showHeaders") {
    return context.res.json(context.req.headers);
  }

  if (context.req.method == 'GET' &&
      context.req.path == "/getGithubContributions") {
    return await getGithubContributes(context, dio);
  }

  if (context.req.method == 'GET' && context.req.path == "/getUserInfo") {
    return await getUserInfo(context, dio);
  }

  if (context.req.method == 'POST' &&
      context.req.path == "/setRemindersForNewSession") {
    return await handleRemindersOnNewSession(context, users);
  }

  return context.res.json({
    'motto': 'Build like a team of hundreds_',
    'learn': 'https://appwrite.io/docs',
    'connect': 'https://appwrite.io/discord',
    'getInspired': 'https://builtwith.appwrite.io',
  });
}

String? getQuery(dynamic context, {required String key}) {
  final queryParams = Uri.parse(context.req.url).queryParameters;
  if (queryParams.containsKey(key)) {
    return queryParams[key].toString();
  } else {
    return null;
  }
}

dynamic dioError(dynamic context, DioException e, String token) {
  return context.res.text(e.message, e.response?.statusCode);
}
