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
    try {
      query = context.req.payload ?? '{}';
    } catch (e) {}

    return context.res.json({
      'req': context.req.toString(),
      'query': query,
    });
  }

  if (context.req.method == 'GET' &&
      context.req.path == "/getGithubContributions") {
    // final token = _getToken(context);
    try {
      //     final username = context.req.query['username'];
      //     final query = '''
      //   query {
      //     user(login: "$username") {
      //       contributionsCollection {
      //         contributionCalendar {
      //           totalContributions
      //           weeks {
      //             contributionDays {
      //               date
      //               contributionCount
      //             }
      //           }
      //         }
      //       }
      //     }
      //   }
      // ''';

      //     final response = await dio.postUri(
      //       Uri.parse(UrlHelper.githubApiUrl),
      //       options: Options(
      //         contentType: 'application/json',
      //         headers: {
      //           HttpHeaders.authorizationHeader: 'Bearer $token',
      //         },
      //       ),
      //       data: jsonEncode({'query': query}),
      //     );
      //     if (response.statusCode == 200) {
      //       var data = response.data;
      //       if (data is String) {
      //         data = jsonDecode(response.data);
      //       }
      //       return context.res.json({
      //         'request': context.req.toString(),
      //         'query': context.req.query,
      //         'data': data
      //       });
      //     } else {
      //       return context.res.json({
      //         'statusMessage': response.statusMessage,
      //         'statusCode': response.statusCode,
      //       });
      //     }
      return context.res.json({
        'users': users,
        // 'token': token,
        'query': context.req.toString(),
      });
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
  return context.req.headers['authorization'].split(' ')[1];
}
