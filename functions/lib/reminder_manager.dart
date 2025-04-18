import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:starter_template/core/url_helper.dart';
import 'package:starter_template/main.dart';
import 'package:starter_template/user_manager.dart';

Future<dynamic> handleRemindersOnNewSession(context, Dio dio) async {
  String token = '';
  try {
    token = getToken(context);
  } catch (e) {
    return context.res.text(
      'Unauthorized',
      401,
    );
  }
  context.log('token: $token');
  try {
    context.log(
        'calling api: ${UrlHelper.reminderManagerUrl}setRemindersForNewSession');
    final response = await dio.postUri(
      Uri.parse('${UrlHelper.reminderManagerUrl}setRemindersForNewSession'),
      options: Options(
        contentType: 'application/json',
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
      ),
      data: context.req.bodyText,
    );
    context.log('api response data: ${response.data}');
    if (response.statusCode == 200) {
      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(response.data);
        } catch (e) {
          return context.res.text(response.data, response.statusCode);
        }
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
