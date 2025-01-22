import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:starter_template/core/url_helper.dart';
import 'package:starter_template/main.dart';

Future<dynamic> getUserInfo(context, Dio dio) async {
  String token = '';

  try {
    token = getToken(context);
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

Future<dynamic> getGithubContributes(context, Dio dio) async {
  String token = '';
  String username = '';
  String from = '';
  String until = '';
  try {
    token = getToken(context);
  } catch (e) {
    return context.res.text(
      'Unauthorized',
      401,
    );
  }

  try {
    username = getQuery(context, key: 'username') ?? '';
    if (username.isEmpty) {
      username = await loadUsername(context, dio);
    }
  } catch (e) {
    return context.res.text('username error!', 400);
  }
  final now = DateTime.now();
  try {
    from = getQuery(context, key: 'from') ?? '';
    if (from.isEmpty) {
      from = now.subtract(Duration(days: 364)).toIso8601String();
    }
  } catch (e) {
    from = now.subtract(Duration(days: 364)).toIso8601String();
  }
  try {
    until = getQuery(context, key: 'until') ?? '';
    if (until.isEmpty) {
      until = now.toIso8601String();
    }
  } catch (e) {
    until = now.toIso8601String();
  }
  try {
    final query = '''
      query {
        user(login: \"$username\") {
          contributionsCollection(from: \"$from\", to: \"$until\") {
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

Future<String> loadUsername(context, Dio dio) async {
  var user = await getUserInfo(context, dio);
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

String getToken(dynamic context) {
  try {
    final rawToken = context.req.headers['token'] ?? '';
    final token = rawToken.split(' ')[1].split(',')[0];
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
