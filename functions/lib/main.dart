import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:starter_template/core/url_helper.dart';

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
    return await _getGithubContributes(context, dio);
  }

  if (context.req.method == 'GET' && context.req.path == "/getUserInfo") {
    return await _getUserInfo(context, dio);
  }

  return context.res.json({
    'motto': 'Build like a team of hundreds_',
    'learn': 'https://appwrite.io/docs',
    'connect': 'https://appwrite.io/discord',
    'getInspired': 'https://builtwith.appwrite.io',
  });
}

Future<dynamic> _getUserInfo(context, Dio dio) async {
  String token = '';

  try {
    token = _getToken(context);
  } catch (e) {
    return context.res.text(
      'Unauthorized',
      401,
    );
  }

  try {
    final query = '''
       query {
        viewer {
          login
          name
          avatarUrl
          bio
          location
        }
      }
    ''';

    final response = await dio.postUri(
      Uri.parse(UrlHelper.githubApiUrl),
      options: Options(
        contentType: 'application/json',
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
      ),
      data: jsonEncode({'query': query}),
    );
    if (response.statusCode == 200) {
      var data = response.data;
      if (data is String) {
        data = jsonDecode(response.data);
      }
      return context.res.json(data);
    } else {
      return context.res.text(
        response.statusMessage,
        response.statusCode,
      );
    }
  } on DioException catch (e) {
    context.log(e.toString());
    return dioError(context, e, token);
  } catch (e) {
    context.log(e.toString());
    return context.res.text(e.toString(), 500);
  }
}

Future<dynamic> _getGithubContributes(context, Dio dio) async {
  String token = '';
  String username = '';
  try {
    token = _getToken(context);
  } catch (e) {
    return context.res.text(
      'Unauthorized',
      401,
    );
  }

  try {
    username = _getQuery(context, key: 'username') ?? '';
    if (username.isEmpty) {
      username = await _loadUsername(context, dio);
    }
  } catch (e) {
    return context.res.text('username error!', 400);
  }
  try {
    final query = '''
      query {
        user(login: "$username") {
          contributionsCollection {
            contributionCalendar {
              totalContributions
              weeks {
                contributionDays {
                  date
                  contributionCount
                }
              }
            }
          }
        }
      }
    ''';

    final response = await dio.postUri(
      Uri.parse(UrlHelper.githubApiUrl),
      options: Options(
        contentType: 'application/json',
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
      ),
      data: jsonEncode({'query': query}),
    );
    if (response.statusCode == 200) {
      var data = response.data;
      if (data is String) {
        data = jsonDecode(response.data);
      }
      return context.res.json(data);
    } else {
      return context.res.text(
        response.statusMessage,
        response.statusCode,
      );
    }
  } on DioException catch (e) {
    context.log(e.toString());
    return dioError(context, e, token);
  } catch (e) {
    context.log(e.toString());
    return context.res.json(e.toString(), 500);
  }
}

Future<String> _loadUsername(context, Dio dio) async {
  var user = await _getUserInfo(context, dio);
  context.log(user.toString() + user.runtimeType.toString());
  if (user is String) {
    user = jsonDecode(user);
  }
  final username = user['data']['viewer']['login'];
  if (username is String) {
    return username;
  }
  throw Exception('username not found: $user');
}

String _getToken(dynamic context) {
  try {
    final token = context.req.headers['token'].split(' ')[1].split(',')[0];
    if (token.isNotEmpty) return token;
    return context.req.headers[HttpHeaders.authorizationHeader]
        .split(' ')[1]
        .split(',')[0];
  } catch (e) {
    context.log(e.toString());
    try {
      return context.req.headers[HttpHeaders.authorizationHeader]
          .split(' ')[1]
          .split(',')[0];
    } catch (e) {
      context.log(e.toString());
      return '';
    }
  }
}

String? _getQuery(dynamic context, {required String key}) {
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
