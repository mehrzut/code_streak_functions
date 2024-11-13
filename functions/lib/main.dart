import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:starter_template/core/url_helper.dart';

// This Appwrite function will be executed every time your function is triggered
Future<dynamic> main(final context) async {
  final Dio dio = Dio();
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

  if (context.req.path == "/test") {
    String query = '';
    String queryString = '';

    try {
      query = context.req.query.toString();
    } catch (e) {}

    try {
      queryString = context.req.queryString ?? '{}';
    } catch (e) {}

    return context.res.json({
      'req': context.req.toString(),
      'context': context.toString(),
      'url': context.req.url.toString(),
      'urlType': context.req.url.runtimeType.toString(),
      'query': query,
      'queryString': queryString,
    });
  }

  if (context.req.method == 'GET' &&
      context.req.path == "/getGithubContributions") {
    Map<String, dynamic> queryParams = {};
    String token = '';
    String username = '';
    try {
      token = _getToken(context);
    } catch (e) {
      return context.res.json({
        'message': 'token error!',
      });
    }
    try {
      queryParams = Uri.parse(context.req.url).queryParameters;
    } catch (e) {
      return context.res.json({
        'message': 'query error!',
      });
    }
    try {
      username = queryParams['username'].toString();
    } catch (e) {
      return context.res.json({
        'message': 'username error!',
      });
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
        return context.res.json({
          'request': context.req.toString(),
          'query': context.req.query,
          'data': data
        });
      } else {
        return context.res.json({
          'statusMessage': response.statusMessage,
          'statusCode': response.statusCode,
        });
      }
    } on DioException catch (e) {
      return context.res.json({
        'error': e.error,
        'message': e.message,
        'users': users,
        // 'token': token,
        'query': context.req.toString(),
      });
    } on Exception catch (e) {
      return context.res.json({
        'error': e.toString(),
      });
    }
  }

  return context.res.json({
    'motto': 'Build like a team of hundreds_',
    'learn': 'https://appwrite.io/docs',
    'connect': 'https://appwrite.io/discord',
    'getInspired': 'https://builtwith.appwrite.io',
  });
}

String _getToken(dynamic context) {
  try {
    return context.req.headers['authorization'].split(' ')[1];
  } catch (e) {
    return '';
  }
}
